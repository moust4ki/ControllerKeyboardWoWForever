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

function CK:OnChatActivated(eb)
    if self:IsOpen() and self.editBox == eb then return end
    local s = self.db.settings
    if self.forceOpen or (s.autoOpen and (not s.onlyWithGamepad or self:IsGamepadActive())) then
        self:Open(eb)
    end
end

function CK:OnChatDeactivated(eb)
    if eb == self.editBox then
        self:Close()
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
            eb:HookScript("OnHide", function(box) CK:OnChatDeactivated(box) end)
        end
    end

    -- Learn from every message the player sends (keyboard or controller)
    local function learn(msg) CK.Predict:LearnMessage(msg) end
    if SendChatMessage then hooksecurefunc("SendChatMessage", learn) end
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        hooksecurefunc(C_ChatInfo, "SendChatMessage", learn)
    end
end

-- Key binding / slash command: open the chat with the keyboard, or close it
function ControllerKeyboard_Toggle()
    if CK:IsOpen() then
        CK:Close()
        return
    end
    CK.forceOpen = true
    local active = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    if active then
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
    elseif cmd == "invert" then
        s.invertY = not s.invertY
        CK:Print("invert: %s", onOff(s.invertY))
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
pcall(events.RegisterEvent, events, "GAME_PAD_ACTIVE_CHANGED")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        CK:InitDB()
    elseif event == "PLAYER_LOGIN" then
        CK.Predict:Load()
        CK:HookChat()
        local version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON, "Version")
        CK:Print(L.LOADED, version or "?")
    elseif event == "PLAYER_LOGOUT" then
        CK.Predict:Prune()
    elseif event == "GAME_PAD_ACTIVE_CHANGED" then
        CK.gamepadActive = arg1
    end
end)
