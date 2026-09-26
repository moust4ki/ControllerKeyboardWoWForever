local ADDON, CK = ...
local L = CK.L

---------------------------------------------------------------------------
-- Chat integration
---------------------------------------------------------------------------
function CK:IsGamepadActive()
    if self.gamepadActive ~= nil then return self.gamepadActive end
    return C_GamePad ~= nil and C_GamePad.GetActiveDeviceID ~= nil
        and C_GamePad.GetActiveDeviceID() ~= nil
        and GetCVar("GamePadEnable") == "1"
end

-- With the "IM" chat style the edit box stays visible and is "activated"
-- without being typed in: only open when it really has the keyboard focus.
function CK:OnChatActivated(eb)
    local forced = self.forceOpen
    C_Timer.After(0, function()
        if not eb:HasFocus() then return end
        if CK:IsOpen() and CK.editBox == eb then return end
        local s = CK.db.settings
        if forced or (s.autoOpen and (not s.onlyWithGamepad or CK:IsGamepadActive())) then
            CK:Open(eb)
        end
    end)
end

function CK:OnChatDeactivated(eb)
    if eb ~= self.editBox then return end
    -- The game closes the chat on mouse clicks: keep typing in the wheel
    if self:IsClickingWheel() then
        self:EnterStandalone()
    else
        self:Close("chat deactivated")
    end
end

function CK:HookChat()
    if ChatEdit_ActivateChat then
        hooksecurefunc("ChatEdit_ActivateChat", function(eb) CK:OnChatActivated(eb) end)
    end
    if ChatEdit_DeactivateChat then
        hooksecurefunc("ChatEdit_DeactivateChat", function(eb) CK:OnChatDeactivated(eb) end)
    end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local eb = _G["ChatFrame" .. i .. "EditBox"]
        if eb then
            eb:HookScript("OnTextChanged", function(box)
                if box == CK.editBox then CK:Refresh() end
            end)
            eb:HookScript("OnEditFocusGained", function(box) CK:OnChatActivated(box) end)
            eb:HookScript("OnEditFocusLost", function(box) CK:OnChatDeactivated(box) end)
            eb:HookScript("OnHide", function(box) CK:OnChatDeactivated(box) end)
        end
    end

    -- Learn from every message the player sends (keyboard or controller)
    local function learn(msg)
        CK.justSent = true
        CK.Predict:LearnMessage(msg)
    end
    if SendChatMessage then hooksecurefunc("SendChatMessage", learn) end
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        hooksecurefunc(C_ChatInfo, "SendChatMessage", learn)
    end
end

-- Key binding / slash command: open the chat with the keyboard, or close it
function ControllerKeyboard_Toggle()
    if CK:IsOpen() then
        CK:Close("toggle")
        return
    end
    CK.forceOpen = true
    local active = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    if active and active:HasFocus() then
        CK:Open(active)
    else
        ChatFrame_OpenChat("")
    end
    CK.forceOpen = false
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local function onOff(v) return v and L.ON or L.OFF end

local function slash(msg)
    local s = CK.db.settings
    local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")

    if cmd == "" then
        -- The chat edit box is still sending this command: open once it is closed
        C_Timer.After(0, function()
            CK.forceOpen = true
            ChatFrame_OpenChat("")
            CK.forceOpen = false
        end)
    elseif cmd == "auto" then
        s.autoOpen = not s.autoOpen
        CK:Print("auto: %s", onOff(s.autoOpen))
    elseif cmd == "pad" then
        s.onlyWithGamepad = not s.onlyWithGamepad
        CK:Print("pad: %s", onOff(s.onlyWithGamepad))
    elseif cmd == "learn" then
        s.learn = not s.learn
        CK:Print("learn: %s", onOff(s.learn))
    elseif cmd == "lang" then
        s.dicts.frFR = arg == "fr" or arg == "both"
        s.dicts.enUS = arg == "en" or arg == "both"
        if not (s.dicts.frFR or s.dicts.enUS) then s.dicts.frFR = true end
        CK.Predict:Load()
        CK:Print("fr: %s  en: %s", onOff(s.dicts.frFR), onOff(s.dicts.enUS))
    elseif cmd == "scale" then
        local v = tonumber(arg)
        if v and v >= 0.4 and v <= 2 then
            s.scale = v
            if CK.frame then CK.frame:SetScale(v) end
        end
        CK:Print("scale: %.2f", s.scale)
    elseif cmd == "input" then
        s.inputMode = s.inputMode == "bind" and "frame" or "bind"
        CK:Close("input mode")
        CK:Print("input: %s", s.inputMode)
    elseif cmd == "invert" then
        s.invertY = not s.invertY
        CK:Print("invert: %s", onOff(s.invertY))
    elseif cmd == "move" then
        -- Wait for the chat that sent this command to close
        C_Timer.After(0, function() CK:ToggleMoveMode() end)
    elseif cmd == "reset" then
        CK.db.pos = nil
        s.scale = 1
        if CK.frame then CK:RestorePosition() end
    elseif cmd == "stats" then
        CK:Print(L.STATS, CK.Predict:NumLearned(), CK.Predict:NumEntries())
    elseif cmd == "forget" then
        if arg == "confirm" then
            CK.Predict:Forget()
            CK:Print(L.FORGOT)
        else
            CK:Print(L.FORGET_CONFIRM)
        end
    elseif cmd == "debug" then
        s.debug = not s.debug
        CK.seenSticks = nil
        CK:Print("debug: %s", onOff(s.debug))
    else
        local h = L.HELP
        for i, line in ipairs(h) do
            if i == 2 then line = format(line, onOff(s.autoOpen))
            elseif i == 3 then line = format(line, onOff(s.onlyWithGamepad))
            elseif i == 4 then line = format(line, onOff(s.learn)) end
            DEFAULT_CHAT_FRAME:AddMessage("  " .. line)
        end
    end
end

SLASH_CONTROLLERKEYBOARD1 = "/ck"
SLASH_CONTROLLERKEYBOARD2 = "/controllerkeyboard"
SlashCmdList.CONTROLLERKEYBOARD = slash

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("ADDON_ACTION_BLOCKED")
events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
pcall(events.RegisterEvent, events, "GAME_PAD_ACTIVE_CHANGED")

events:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        CK:InitDB()
    elseif event == "PLAYER_LOGIN" then
        CK.Predict:Load()
        CK:HookChat()
        -- Build the frames now, never while the chat is open (see Input.lua)
        if InCombatLockdown() then CK.buildPending = true else CK:BuildUI() end
        local version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON, "Version")
        CK:Print(L.LOADED, version or "?")
    elseif event == "PLAYER_LOGOUT" then
        CK.Predict:Prune()
    elseif event == "GAME_PAD_ACTIVE_CHANGED" then
        CK.gamepadActive = arg1
    elseif event == "PLAYER_REGEN_ENABLED" then
        if CK.buildPending then
            CK.buildPending = false
            CK:BuildUI()
        end
        CK:OnCombatEnded()
    elseif (event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN") and arg1 == ADDON then
        -- Release the pad at once so the game's popup can be answered safely
        CK:Close(event)
        CK:Print("|cffff4040%s|r: %s", event, tostring(arg2))
    end
end)
