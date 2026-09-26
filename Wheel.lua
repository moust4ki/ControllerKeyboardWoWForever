local _, CK = ...
local L = CK.L

-- 8 petals, clockwise from the top. Each petal holds 4 characters placed
-- left, top, right, bottom: the right stick flicks toward the one to type.
-- The frames are built in UI.lua.
local LAYOUTS = {
    letters = {
        { "a", "b", "c", "d" },
        { "e", "f", "g", "h" },
        { "i", "j", "k", "l" },
        { "m", "n", "o", "p" },
        { "q", "r", "s", "t" },
        { "u", "v", "w", "x" },
        { "y", "z", "'", "-" },
        { ".", ",", "?", "!" },
    },
    symbols = {
        { "1", "2", "3", "4" },
        { "5", "6", "7", "8" },
        { "9", "0", "+", "=" },
        { "é", "è", "ê", "à" },
        { "ç", "ù", "â", "ô" },
        { "î", "û", "ë", "ï" },
        { ":", ";", "(", ")" },
        { "/", "@", "\"", "%" },
    },
}
CK.LAYOUTS = LAYOUTS

CK.state = {
    layer = "letters",
    shift = false,
    caps = false,
    petal = nil,
    aim = nil,
    suggestions = {},
    selected = 1,
    lastShift = 0,
}

---------------------------------------------------------------------------
-- Text and channel source
--
-- The message lives in the keyboard's own buffer and is sent with the secure
-- macro button. The addon never writes to the chat edit box: text set by an
-- addon is tainted, and when WoW Forever's gamepad UI reads it back
-- (ChatFrame1EditBox:GetText()) its own code gets tainted, which is blocked
-- in combat again and again until the client freezes. The edit box is only
-- read: its channel, and what is typed on a physical keyboard.
-- "standalone": a mouse click made the game close the chat, the keyboard
-- stays open on its own.
---------------------------------------------------------------------------
function CK:GetText()
    return self.buffer or ""
end

-- Channel: the chat's own while it is open, a snapshot once it is closed
function CK:GetChatAttr(key)
    if self.chatAttrs then return self.chatAttrs[key] end
    return self.editBox and self.editBox:GetAttribute(key)
end

local function snapshotAttrs(eb)
    if not eb then return { chatType = "SAY" } end
    return {
        chatType = eb:GetAttribute("chatType") or "SAY",
        tellTarget = eb:GetAttribute("tellTarget"),
        channelTarget = eb:GetAttribute("channelTarget"),
    }
end

function CK:SetChatAttr(key, value)
    self.chatAttrs = self.chatAttrs or snapshotAttrs(self.editBox)
    self.chatAttrs[key] = value
end

-- Text typed on a physical keyboard, or cleared by the game after sending
function CK:OnChatTextChanged(eb)
    if eb ~= self.editBox then return end
    self.buffer = eb:GetText() or ""
    self:Refresh()
end

-- True while a mouse button is held over the keyboard (not just hovering:
-- sending with A while the cursor rests on the wheel must still close it)
function CK:IsClickingWheel()
    return self.frame and self.frame:IsMouseOver()
        and (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton"))
end

-- Keyboard without the chat (after /ck lock, to place it): A sends with the
-- secure macro button, B closes
function CK:OpenStandalone()
    if self:BlockedByCombat() then return end
    if not self.frame then self:BuildUI() end
    if self:IsOpen() then return end
    self.standalone = true
    self.buffer = ""
    self.chatAttrs = { chatType = "SAY" }
    self.editBox = nil
    local state = self.state
    state.layer, state.shift, state.caps, state.petal, state.aim = "letters", false, false, nil, nil
    self.frame:Show()
    self:EnableButtons()
    self:UpdateWheel()
    self:Refresh()
end

function CK:EnterStandalone()
    if self.standalone then return end
    self.standalone = true
    self.chatAttrs = self.chatAttrs or snapshotAttrs(self.editBox)
    self.editBox = nil
    if self.db.settings.debug then self:Print("standalone mode") end
    self:EnableButtons()
    self:Refresh()
end

function CK:GetChannelLabel()
    local chatType = self:GetChatAttr("chatType") or "SAY"
    local label
    if chatType == "WHISPER" or chatType == "BN_WHISPER" then
        label = format(CHAT_WHISPER_SEND or "To %s: ", self:GetChatAttr("tellTarget") or "?")
    elseif chatType == "CHANNEL" then
        local target = self:GetChatAttr("channelTarget")
        local _, name = GetChannelName(target or 0)
        label = (name or tostring(target or "")) .. ": "
    else
        label = _G["CHAT_" .. chatType .. "_SEND"] or (chatType .. ": ")
    end
    local info = ChatTypeInfo and ChatTypeInfo[chatType]
    if info then
        label = format("|cff%02x%02x%02x%s|r", info.r * 255, info.g * 255, info.b * 255, label)
    end
    return label
end

-- Keep the end of long messages visible
local MAX_PREVIEW = 80
local function previewTail(text)
    if #text <= MAX_PREVIEW then return text end
    local start = #text - MAX_PREVIEW + 1
    while start <= #text do
        local b = text:byte(start)
        if b < 128 or b >= 192 then break end
        start = start + 1
    end
    return "..." .. text:sub(start)
end

local WORD_TAIL = "(" .. CK.WORD_CHARS .. "*)$"

function CK:Refresh()
    local f = self.frame
    if not (f and f:IsShown()) then return end
    if not (self.standalone or self.editBox) then return end

    local text = self:GetText()
    self.previewBody = self:GetChannelLabel() .. previewTail(text)
    self:UpdatePreview()

    -- "/re" -> /reload, "/ck l" -> /ck lock: command and at most one argument
    local n = self.db.settings.numSuggestions
    local _, spaces = text:gsub(" ", "")
    self.state.commandMode = text:sub(1, 1) == "/" and spaces <= 1
    if self.state.commandMode then
        self.state.suggestions = CK.Predict:QueryCommands(text, n)
    else
        local prefix = text:match(WORD_TAIL) or ""
        local ctx = CK.Predict:Context(text:sub(1, #text - #prefix))
        self.state.suggestions = CK.Predict:Query(prefix, ctx, n)
    end
    self.state.selected = 1
    self:UpdateSuggestions()
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------
function CK:SetText(text)
    self.buffer = text
    self:Refresh()
end

function CK:InsertText(text)
    self:SetText(self:GetText() .. text)
end

function CK:TypeSlot(petal, slot)
    local ch = LAYOUTS[self.state.layer][petal][slot]
    if not ch then return end
    self:InsertText(self:DisplayChar(ch))
    if self.state.shift and not self.state.caps then
        self.state.shift = false
        self:UpdateWheel()
    end
end

function CK:Space()
    self:InsertText(" ")
end

function CK:Backspace()
    self:SetText(CK.DropLastChar(self:GetText()))
end

function CK:DeleteWord()
    local text = self:GetText():gsub("%s+$", "")
    text = text:gsub("[^%s]+$", "")
    self:SetText(text)
end

function CK:AcceptSuggestion(index)
    local word = self.state.suggestions[index or self.state.selected]
    if not word then return false end
    if self.state.commandMode then
        self:SetText(word .. " ")
        return true
    end
    local text = self:GetText()
    local prefix = text:match(WORD_TAIL) or ""
    -- No space after an elision: "j'" + "ai"
    local sep = word:sub(-1) == "'" and "" or " "
    self:SetText(text:sub(1, #text - #prefix) .. word .. sep)
    return true
end

function CK:SelectSuggestion(delta)
    local n = #self.state.suggestions
    if n == 0 then return end
    self.state.selected = (self.state.selected - 1 + delta) % n + 1
    self:UpdateSuggestions()
end

function CK:NextSuggestion() self:SelectSuggestion(1) end
function CK:PrevSuggestion() self:SelectSuggestion(-1) end

-- Tap: one capital letter. Double tap: caps lock. Tap again: off.
function CK:ToggleShift()
    local state = self.state
    local now = GetTime()
    if state.caps then
        state.caps, state.shift = false, false
    elseif state.shift and now - state.lastShift < 0.4 then
        state.caps = true
    else
        state.shift = not state.shift
    end
    state.lastShift = now
    self:UpdateWheel()
end

function CK:ToggleSymbols()
    self.state.layer = self.state.layer == "letters" and "symbols" or "letters"
    self:UpdateWheel()
end

local CHANNELS = { "SAY", "PARTY", "RAID", "GUILD", "WHISPER", "YELL" }

local function lastTellTarget()
    return ChatEdit_GetLastTellTarget and ChatEdit_GetLastTellTarget() or nil
end

local function channelAvailable(chatType)
    if chatType == "WHISPER" then
        local target = lastTellTarget()
        return target ~= nil and target ~= ""
    elseif chatType == "PARTY" then
        if IsInGroup then return IsInGroup() end
        return (GetNumPartyMembers and GetNumPartyMembers() or 0) > 0
    elseif chatType == "RAID" then
        if IsInRaid then return IsInRaid() end
        return (GetNumRaidMembers and GetNumRaidMembers() or 0) > 0
    elseif chatType == "GUILD" then
        return IsInGuild()
    end
    return true
end

-- delta: 1 = next channel, -1 = previous. Whisper replies to the last whisper.
function CK:CycleChannel(delta)
    if not (self.standalone or self.editBox) then return end
    delta = delta or 1
    local n = #CHANNELS
    local current = self:GetChatAttr("chatType")
    local index = delta > 0 and 0 or n + 1
    for i, t in ipairs(CHANNELS) do
        if t == current then index = i end
    end
    for step = 1, n do
        local t = CHANNELS[(index - 1 + step * delta) % n + 1]
        if channelAvailable(t) then
            if t == "WHISPER" then
                self:SetChatAttr("tellTarget", lastTellTarget())
            end
            self:SetChatAttr("chatType", t)
            break
        end
    end
    self:Refresh()
end

function CK:NextChannel() self:CycleChannel(1) end
function CK:PrevChannel() self:CycleChannel(-1) end

-- The message is sent by the secure macro button (see Input.lua): calling the
-- chat functions from addon code gets blocked by WoW Forever's gamepad UI.
local SLASH = {
    SAY = "/s", YELL = "/y", PARTY = "/p", RAID = "/ra", GUILD = "/g",
    OFFICER = "/o", INSTANCE_CHAT = "/i", RAID_WARNING = "/rw", EMOTE = "/e",
}

function CK:BuildMacroText()
    if not (self.standalone or self.editBox) then return end
    local text = self:GetText():gsub("[\r\n]", " ")
    if text:match("^%s*$") then return end
    if text:sub(1, 1) == "/" then return text end

    local chatType = self:GetChatAttr("chatType") or "SAY"
    if chatType == "WHISPER" then
        local target = self:GetChatAttr("tellTarget")
        return target and ("/w " .. target .. " " .. text)
    elseif chatType == "CHANNEL" then
        local target = self:GetChatAttr("channelTarget")
        return target and ("/" .. target .. " " .. text)
    end
    local cmd = SLASH[chatType]
    return cmd and (cmd .. " " .. text)
end

-- Only reached when the secure button is not over the "Send" button (the
-- keyboard was opened in combat): press Enter instead.
function CK:Send()
    self:Print(L.SEND_COMBAT)
end

---------------------------------------------------------------------------
-- Open / close
---------------------------------------------------------------------------
-- The keyboard is not available in combat: sending from the chat while in
-- combat got blocked by the game. It reopens after combat if the chat is open.
function CK:BlockedByCombat()
    if not InCombatLockdown() then return false end
    -- Red message in the middle of the screen, like the game's own errors
    if UIErrorsFrame then
        UIErrorsFrame:AddMessage(CK.L.COMBAT_UNAVAILABLE, 1, 0.1, 0.1, 1)
    else
        self:Print(CK.L.COMBAT_UNAVAILABLE)
    end
    return true
end

function CK:Open(eb)
    if self:BlockedByCombat() then return end
    if not self.frame then self:BuildUI() end
    -- Keep a message typed with the mouse when the chat is reopened;
    -- otherwise start from what the chat holds (physical keyboard)
    if not (self.standalone and self.buffer and self.buffer ~= "") then
        self.buffer = eb:GetText() or ""
    end
    self.standalone = false
    self.chatAttrs = nil
    self.editBox = eb
    local state = self.state
    state.layer, state.shift, state.caps, state.petal, state.aim = "letters", false, false, nil, nil
    self.frame:Show()
    self:EnableButtons()
    self:UpdateWheel()
    self:Refresh()
end

function CK:Close(reason)
    if self.db.settings.debug and self:IsOpen() then
        self:Print("close: %s", tostring(reason or "button"))
    end
    self.closing = true
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
        self:DisableButtons()
    end
    self.closing = false
    self.standalone = false
    self.buffer = nil
    self.chatAttrs = nil
    self.editBox = nil
    self.state.petal = nil
    self.state.aim = nil
    self.repeatFn = nil
end

function CK:IsOpen()
    return self.frame and self.frame:IsShown()
end
