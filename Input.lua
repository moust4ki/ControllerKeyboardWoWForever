local _, CK = ...

-- Left stick picks a petal, right stick flicks toward the letter to type.
-- With the left stick centered, the right stick drives the suggestions.
local BUTTON_ACTIONS = {
    PAD1 = "AcceptSuggestion",      -- A / Cross
    PAD2 = "Cancel",                -- B / Circle
    PAD3 = "Backspace",             -- X / Square
    PAD4 = "Space",                 -- Y / Triangle
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
    PADFORWARD = "Send",
    PADBACK = "CycleChannel",
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

    -- Safety net: the chat lost the focus without any event we hooked
    if not (self.editBox and self.editBox:HasFocus()) then
        self:Close()
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

local LEFT_STICKS = { Left = true, Movement = true }
local RIGHT_STICKS = { Right = true, Camera = true }

function CK:SetupInput(f)
    if f.EnableGamePadButton then
        f:EnableGamePadButton(true)
        f:SetScript("OnGamePadButtonDown", function(_, button) CK:OnPadButton(button) end)
        f:SetScript("OnGamePadButtonUp", function(_, button) CK:OnPadButtonUp(button) end)
    end
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
