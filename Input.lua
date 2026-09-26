local _, CK = ...

-- Left stick picks a petal, right stick flicks toward the letter to type.
-- With the left stick centered, the right stick drives the suggestions.
--
-- A (send), B (back), X (chat channels), Y (tab settings), Start and Select
-- belong to the game's own gamepad chat UI and are never bound here. It also
-- avoids closing the chat from addon code, which WoW Forever's gamepad UI
-- forbids (SetPreferredGamepadInteractTarget).
local BUTTON_ACTIONS = {
    PADLSHOULDER = "Backspace",
    PADRSHOULDER = "Space",
    PADLTRIGGER = "ToggleShift",
    PADRTRIGGER = "ToggleSymbols",
    PADDLEFT = "PrevSuggestion",
    PADDRIGHT = "NextSuggestion",
    PADDUP = "AcceptSuggestion",
    PADDDOWN = "DeleteWord",
    PADLSTICK = "ToggleSymbols",
    PADRSTICK = "AcceptSuggestion",
}

-- Right stick directions -> petal slot (1 left, 2 up, 3 right, 4 down)
local SLOT_BY_SECTOR = { [0] = 2, [1] = 3, [2] = 4, [3] = 1 }
-- Right stick with no petal selected
local NEUTRAL_FLICK = { "PrevSuggestion", "AcceptSuggestion", "NextSuggestion", "Backspace" }

-- Actions repeated while the button (or stick) is held
local REPEATABLE = { Backspace = true, PrevSuggestion = true, NextSuggestion = true }
local REPEAT_DELAY, REPEAT_RATE = 0.45, 0.08

local LEFT_IN, LEFT_OUT = 0.5, 0.35      -- petal selection deadzone (with hysteresis)
local RIGHT_AIM, RIGHT_FIRE, RIGHT_RESET = 0.3, 0.75, 0.4

local function sector(x, y, count)
    local fromNorth = (90 - math.deg(math.atan2(y, x))) % 360
    local size = 360 / count
    return math.floor((fromNorth + size / 2) / size) % count
end

function CK:SetLeftStick(x, y)
    if self.db.settings.invertY then y = -y end
    local len = math.sqrt(x * x + y * y)
    local petal
    if len >= LEFT_IN or (self.state.petal and len >= LEFT_OUT) then
        petal = sector(x, y, 8) + 1
    end
    if petal ~= self.state.petal then
        self.state.petal = petal
        self:UpdateWheel()
    end
end

function CK:SetRightStick(x, y)
    if self.db.settings.invertY then y = -y end
    local state = self.state
    local len = math.sqrt(x * x + y * y)

    local aim
    if len >= RIGHT_AIM then
        aim = SLOT_BY_SECTOR[sector(x, y, 4)]
    end
    if aim ~= state.aim then
        state.aim = aim
        self:UpdateWheel()
    end

    if self.rightFired then
        if len < RIGHT_RESET then
            self.rightFired = false
            if self.repeatButton == "RIGHTSTICK" then self.repeatFn = nil end
        end
    elseif aim and len >= RIGHT_FIRE then
        self.rightFired = true
        if state.petal then
            self:TypeSlot(state.petal, aim)
        else
            self:RunAction(NEUTRAL_FLICK[aim], "RIGHTSTICK")
        end
    end
end

function CK:RunAction(action, button)
    self[action](self)
    if REPEATABLE[action] then
        self.repeatFn = action
        self.repeatButton = button
        self.repeatAt = GetTime() + REPEAT_DELAY
    end
end

function CK:OnPadButton(button)
    if self.db.settings.debug then
        self:Print("button %s", tostring(button))
    end
    local action = BUTTON_ACTIONS[button]
    if action then
        self:RunAction(action, button)
    end
end

function CK:OnPadButtonUp(button)
    if button == self.repeatButton then
        self.repeatFn = nil
    end
end

function CK:OnUpdate()
    local now = GetTime()
    if self.moving then return end

    -- Safety net: the chat lost the focus without any event we hooked
    if not (self.editBox and self.editBox:HasFocus()) then
        self:Close("focus lost (OnUpdate)")
        return
    end

    -- Fallback when OnGamePadStick never fires: poll the device state
    if not self.stickEvents and C_GamePad and C_GamePad.GetDeviceMappedState then
        local id = C_GamePad.GetActiveDeviceID and C_GamePad.GetActiveDeviceID()
        local st = id and C_GamePad.GetDeviceMappedState(id)
        local sticks = st and st.sticks
        if sticks then
            if sticks[1] then self:SetLeftStick(sticks[1].x or 0, sticks[1].y or 0) end
            if sticks[2] then self:SetRightStick(sticks[2].x or 0, sticks[2].y or 0) end
        end
    end

    if self.repeatFn and now >= self.repeatAt then
        self[self.repeatFn](self)
        self.repeatAt = now + REPEAT_RATE
    end
end

---------------------------------------------------------------------------
-- Frames
--
-- WoW Forever's gamepad smart navigation hooks the global CreateFrame and
-- refreshes its button groups from the caller's (tainted) context. Creating
-- frames without a parent and calling SetParent afterwards is not watched.
---------------------------------------------------------------------------
function CK.NewFrame(frameType, name, parent, template)
    local f = CreateFrame(frameType, name, nil, template)
    if parent then f:SetParent(parent) end
    return f
end

---------------------------------------------------------------------------
-- Buttons
--
-- While the keyboard is open, each pad button is bound (override binding)
-- to "click" a hidden button. Pad buttons keep working while the chat edit
-- box has the focus, and A clicks a secure macro button that sends the text
-- with "/s ...", "/p ..." etc.: the game itself sends the message.
-- In combat bindings and attributes are locked: they stay as set on open.
---------------------------------------------------------------------------
local function bindingButtonName(key)
    return "ControllerKeyboardPad" .. key
end

local SEND_BUTTON = "ControllerKeyboardSendButton"

function CK:CreateButtons()
    for key in pairs(BUTTON_ACTIONS) do
        local b = CK.NewFrame("Button", bindingButtonName(key))
        b:SetSize(1, 1)
        b:RegisterForClicks("AnyDown", "AnyUp")
        b:SetScript("OnClick", function(_, _, down)
            if down == false then
                CK:OnPadButtonUp(key)
            else
                CK:OnPadButton(key)
            end
        end)
    end

    -- Secure macro button laid over the "Send" button for the mouse
    -- (the pad sends with A through the game's own chat UI)
    local s = CK.NewFrame("Button", SEND_BUTTON, nil, "SecureActionButtonTemplate")
    s:SetAttribute("type", "macro")
    s:SetAttribute("macrotext", "")
    s:RegisterForClicks("AnyDown", "AnyUp")
    s:SetFrameStrata("FULLSCREEN_DIALOG")
    s:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    s:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.12)
    s:SetScript("PreClick", function() CK:PrepareSend() end)
    s:SetScript("PostClick", function(_, _, down) CK:FinishSend(down) end)
    s:Hide()
    self.sendButton = s
end

-- Runs before the secure click: put the current message in the macro
function CK:PrepareSend()
    self.justSent = false
    if InCombatLockdown() then return end
    self.sendButton:SetAttribute("macrotext", self:BuildMacroText() or "")
end

-- Runs after the secure click: once the game sent the message, clear it
-- (the chat stays open for the next message; B closes it)
function CK:FinishSend(down)
    local eb = self.editBox
    if not eb then return end
    local text = eb:GetText() or ""
    local slashCommand = text:sub(1, 1) == "/" and down ~= true
    if self.justSent or slashCommand then
        self.justSent = false
        if eb.AddHistoryLine then eb:AddHistoryLine(text) end
        if not InCombatLockdown() then
            self.sendButton:SetAttribute("macrotext", "")
        end
        self:SetText("")
    end
end

function CK:EnableButtons()
    local f = self.frame
    if InCombatLockdown() then return end
    for key in pairs(BUTTON_ACTIONS) do
        SetOverrideBindingClick(f, true, key, bindingButtonName(key))
    end
    self.bindingsActive = true
    self.clearPending = false

    local s = self.sendButton
    s:ClearAllPoints()
    s:SetAllPoints(f.actions.Send)
    s:Show()
end

function CK:DisableButtons()
    if not self.bindingsActive then return end
    if InCombatLockdown() then
        self.clearPending = true
        return
    end
    ClearOverrideBindings(self.frame)
    self.sendButton:Hide()
    self.sendButton:SetAttribute("macrotext", "")
    self.bindingsActive = false
    self.clearPending = false
end

function CK:OnCombatEnded()
    if self.clearPending and not self:IsOpen() then
        self:DisableButtons()
    end
end

---------------------------------------------------------------------------
-- Sticks
---------------------------------------------------------------------------
local LEFT_STICKS = { Left = true, Movement = true }
local RIGHT_STICKS = { Right = true, Camera = true }

function CK:SetupInput(f)
    self:CreateButtons()
    if f.EnableGamePadStick then
        f:EnableGamePadStick(true)
        f:SetScript("OnGamePadStick", function(_, stick, x, y)
            if CK.db.settings.debug then
                CK.seenSticks = CK.seenSticks or {}
                if not CK.seenSticks[stick] then
                    CK.seenSticks[stick] = true
                    CK:Print("stick %s", tostring(stick))
                end
            end
            if LEFT_STICKS[stick] then
                CK.stickEvents = true
                CK:SetLeftStick(x or 0, y or 0)
            elseif RIGHT_STICKS[stick] then
                CK.stickEvents = true
                CK:SetRightStick(x or 0, y or 0)
            end
        end)
    end
    f:SetScript("OnUpdate", function() CK:OnUpdate() end)
end
