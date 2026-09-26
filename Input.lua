local _, CK = ...

-- Face buttons -> petal slot (X left, Y top, B right, A bottom).
-- PAD1..4 keep the same positions on PlayStation pads (Cross, Circle, Square, Triangle).
local SLOT_BY_BUTTON = { PAD3 = 1, PAD4 = 2, PAD2 = 3, PAD1 = 4 }

-- Face buttons when the stick is centered
local NEUTRAL_ACTIONS = { "Backspace", "Space", "Cancel", "AcceptSuggestion" }

local BUTTON_ACTIONS = {
    PADLSHOULDER = "PrevSuggestion",
    PADRSHOULDER = "NextSuggestion",
    PADDLEFT = "PrevSuggestion",
    PADDRIGHT = "NextSuggestion",
    PADDUP = "AcceptSuggestion",
    PADDDOWN = "DeleteWord",
    PADLTRIGGER = "ToggleShift",
    PADRTRIGGER = "ToggleSymbols",
    PADLSTICK = "ToggleSymbols",
    PADRSTICK = "AcceptSuggestion",
    PADFORWARD = "Send",
    PADBACK = "CycleChannel",
}

-- Actions repeated while the button is held
local REPEATABLE = { Backspace = true }
local REPEAT_DELAY, REPEAT_RATE = 0.45, 0.07

local DEADZONE_IN, DEADZONE_OUT = 0.5, 0.35

function CK:SetStick(x, y)
    if self.db.settings.invertY then y = -y end
    local len = math.sqrt(x * x + y * y)
    local petal
    if len >= DEADZONE_IN or (self.state.petal and len >= DEADZONE_OUT) then
        local fromNorth = (90 - math.deg(math.atan2(y, x))) % 360
        petal = math.floor((fromNorth + 22.5) / 45) % 8 + 1
    end
    if petal ~= self.state.petal then
        self.state.petal = petal
        self:UpdateWheel()
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
        self:Print("button %s (petal %s)", tostring(button), tostring(self.state.petal))
    end
    local slot = SLOT_BY_BUTTON[button]
    if slot then
        if self.state.petal then
            self:TypeSlot(self.state.petal, slot)
        else
            self:RunAction(NEUTRAL_ACTIONS[slot], button)
        end
        return
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

    -- Fallback when OnGamePadStick never fires: poll the device state
    if not self.stickEvents and C_GamePad and C_GamePad.GetDeviceMappedState then
        local id = C_GamePad.GetActiveDeviceID and C_GamePad.GetActiveDeviceID()
        local st = id and C_GamePad.GetDeviceMappedState(id)
        local stick = st and st.sticks and st.sticks[1]
        if stick then self:SetStick(stick.x or 0, stick.y or 0) end
    end

    if self.repeatFn and now >= self.repeatAt then
        self[self.repeatFn](self)
        self.repeatAt = now + REPEAT_RATE
    end
end

function CK:SetupInput(f)
    if f.EnableGamePadButton then
        f:EnableGamePadButton(true)
        f:SetScript("OnGamePadButtonDown", function(_, button) CK:OnPadButton(button) end)
        f:SetScript("OnGamePadButtonUp", function(_, button) CK:OnPadButtonUp(button) end)
    end
    if f.EnableGamePadStick then
        f:EnableGamePadStick(true)
        f:SetScript("OnGamePadStick", function(_, stick, x, y)
            if CK.db.settings.debug and not CK.seenSticks then
                CK.seenSticks = {}
            end
            if CK.seenSticks and not CK.seenSticks[stick] then
                CK.seenSticks[stick] = true
                CK:Print("stick %s", tostring(stick))
            end
            if stick == "Left" or stick == "Movement" then
                CK.stickEvents = true
                CK:SetStick(x or 0, y or 0)
            end
        end)
    end
    f:SetScript("OnUpdate", function() CK:OnUpdate() end)
end
