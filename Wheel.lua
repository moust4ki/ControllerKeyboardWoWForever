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
-- Normally the wheel types into the chat edit box. WoW Forever's gamepad UI
-- closes the chat on any mouse click: the wheel then keeps the message in its
-- own buffer ("standalone") and sends it with the secure macro button.
---------------------------------------------------------------------------
function CK:GetText()
    if self.standalone then return self.buffer or "" end
    return self.editBox and self.editBox:GetText() or ""
end

function CK:GetChatAttr(key)
    if self.standalone then return self.chatAttrs[key] end
    return self.editBox and self.editBox:GetAttribute(key)
end

function CK:SetChatAttr(key, value)
    if self.standalone then
        self.chatAttrs[key] = value
    elseif self.editBox then
        self.editBox:SetAttribute(key, value)
    end
end

-- Remember the chat state so it survives the chat being closed by a click
function CK:SnapshotChat()
    local eb = self.editBox
    if not eb then return end
    self.lastText = eb:GetText() or ""
    self.lastAttrs = {
        chatType = eb:GetAttribute("chatType"),
        tellTarget = eb:GetAttribute("tellTarget"),
        channelTarget = eb:GetAttribute("channelTarget"),
    }
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
    if not self.frame then
        if InCombatLockdown() then return end
        self:BuildUI()
    end
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
    self.buffer = self.lastText or ""
    self.chatAttrs = self.lastAttrs or { chatType = "SAY" }
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
    if not self.standalone then self:SnapshotChat() end

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
    if self.standalone then
        self.buffer = text
    elseif self.editBox then
        self.editBox:SetText(text)
        self.editBox:SetCursorPosition(#text)
    else
        return
    end
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
            if self.editBox and ChatEdit_UpdateHeader then ChatEdit_UpdateHeader(self.editBox) end
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
function CK:Open(eb)
    if not self.frame then
        -- Secure buttons can't be created in combat: wait for PLAYER_REGEN_ENABLED
        if InCombatLockdown() then return end
        self:BuildUI()
    end
    -- Carry a message typed with the mouse back into the reopened chat
    local carried = self.standalone and self.buffer or nil
    local carriedAttrs = self.standalone and self.chatAttrs or nil
    self.standalone = false
    self.editBox = eb
    if carried and carried ~= "" then
        eb:SetText(carried)
        for k, v in pairs(carriedAttrs) do eb:SetAttribute(k, v) end
        if ChatEdit_UpdateHeader then ChatEdit_UpdateHeader(eb) end
    end
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
    self.editBox = nil
    self.state.petal = nil
    self.state.aim = nil
    self.repeatFn = nil
end

function CK:IsOpen()
    return self.frame and self.frame:IsShown()
end
