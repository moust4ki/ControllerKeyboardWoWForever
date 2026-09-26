local _, CK = ...
local L = CK.L

-- 8 petals, clockwise from the top. Each petal holds 4 characters placed like
-- the face buttons: X (left), Y (top), B (right), A (bottom).
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

local SLOT_OFFSETS = { { -30, 0 }, { 0, 30 }, { 30, 0 }, { 0, -30 } }
local SLOT_COLORS = {
    { 0.35, 0.60, 1.00 }, -- X blue
    { 1.00, 0.85, 0.20 }, -- Y yellow
    { 1.00, 0.35, 0.35 }, -- B red
    { 0.40, 1.00, 0.40 }, -- A green
}

local CIRCLE = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local WHEEL_RADIUS = 140
local PETAL_SIZE = 104
local KEY_SIZE = 32
local FRAME_WIDTH, FRAME_HEIGHT = 460, 580

CK.state = {
    layer = "letters",
    shift = false,
    caps = false,
    petal = nil,
    suggestions = {},
    selected = 1,
    lastShift = 0,
}

---------------------------------------------------------------------------
-- UI construction
---------------------------------------------------------------------------
local function newButton(parent, text, width, height, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, height)
    b:SetText(text)
    b:SetNormalFontObject("GameFontNormalSmall")
    b:SetHighlightFontObject("GameFontHighlightSmall")
    b:SetScript("OnClick", onClick)
    return b
end

local function circle(parent, layer, size, r, g, b, a)
    local t = parent:CreateTexture(nil, layer)
    t:SetTexture(CIRCLE)
    t:SetSize(size, size)
    t:SetVertexColor(r, g, b, a)
    return t
end

function CK:BuildUI()
    if self.frame then return end

    local f = CreateFrame("Frame", "ControllerKeyboardFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(s)
        s:StopMovingOrSizing()
        CK:SavePosition()
    end)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.03, 0.03, 0.06, 0.92)
    f:SetBackdropBorderColor(0.6, 0.6, 0.65, 1)
    f:Hide()
    self.frame = f

    -- Header: channel, mode and a preview of the message
    f.channel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.channel:SetPoint("TOPLEFT", 16, -14)

    f.mode = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.mode:SetPoint("TOPRIGHT", -16, -15)

    f.preview = f:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
    f.preview:SetPoint("TOPLEFT", 16, -34)
    f.preview:SetSize(FRAME_WIDTH - 32, 36)
    f.preview:SetJustifyH("LEFT")
    f.preview:SetJustifyV("TOP")

    -- Suggestions
    f.sugg = {}
    local n = self.db.settings.numSuggestions
    local sw = math.floor((FRAME_WIDTH - 32 - (n - 1) * 2) / n)
    for i = 1, n do
        local b = newButton(f, "", sw, 24, function() CK:AcceptSuggestion(i) end)
        b:SetNormalFontObject("GameFontHighlight")
        b:SetPoint("TOPLEFT", 16 + (i - 1) * (sw + 2), -76)
        b:Hide()
        f.sugg[i] = b
    end

    -- Wheel
    local wheel = CreateFrame("Frame", nil, f)
    wheel:SetSize(400, 400)
    wheel:SetPoint("TOP", 0, -106)
    f.wheel = wheel

    local hub = circle(wheel, "BACKGROUND", 116, 0.15, 0.15, 0.2, 0.8)
    hub:SetPoint("CENTER")
    f.hubHints = {}
    local hubText = { L.HUB_X, L.HUB_Y, L.HUB_B, L.HUB_A }
    for s = 1, 4 do
        local t = wheel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("CENTER", wheel, "CENTER", SLOT_OFFSETS[s][1] * 1.2, SLOT_OFFSETS[s][2] * 1.2)
        t:SetText(hubText[s])
        t:SetTextColor(unpack(SLOT_COLORS[s]))
        f.hubHints[s] = t
    end

    f.petals = {}
    for i = 1, 8 do
        local angle = math.rad(90 - (i - 1) * 45)
        local p = CreateFrame("Frame", nil, wheel)
        p:SetSize(PETAL_SIZE, PETAL_SIZE)
        p:SetPoint("CENTER", wheel, "CENTER", math.cos(angle) * WHEEL_RADIUS, math.sin(angle) * WHEEL_RADIUS)
        p.bg = circle(p, "BACKGROUND", PETAL_SIZE, 0.25, 0.25, 0.3, 0.6)
        p.bg:SetPoint("CENTER")
        p.keys = {}
        for s = 1, 4 do
            local b = CreateFrame("Button", nil, p)
            b:SetSize(KEY_SIZE, KEY_SIZE)
            b:SetPoint("CENTER", p, "CENTER", SLOT_OFFSETS[s][1], SLOT_OFFSETS[s][2])
            b:SetHighlightTexture(CIRCLE)
            b:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.3)
            b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            b.text:SetPoint("CENTER", 0, 1)
            b:SetScript("OnClick", function() CK:TypeSlot(i, s) end)
            p.keys[s] = b
        end
        f.petals[i] = p
    end

    -- Bottom row (mouse / Steam Controller trackpad)
    local actions = {
        { L.SHIFT, "ToggleShift" },
        { L.SYMBOLS, "ToggleSymbols" },
        { L.SPACE, "Space" },
        { L.BACKSPACE, "Backspace" },
        { L.CHANNEL, "CycleChannel" },
        { L.SEND, "Send" },
        { L.CLOSE, "Cancel" },
    }
    local bw = math.floor((FRAME_WIDTH - 32 - (#actions - 1) * 2) / #actions)
    f.actions = {}
    for i, a in ipairs(actions) do
        local b = newButton(f, a[1], bw, 24, function() CK[a[2]](CK) end)
        b:SetPoint("TOPLEFT", 16 + (i - 1) * (bw + 2), -512)
        f.actions[a[2]] = b
    end

    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.hint:SetPoint("TOPLEFT", 16, -542)
    f.hint:SetSize(FRAME_WIDTH - 32, 26)
    f.hint:SetText(L.HINT)

    self:SetupInput(f)
    self:RestorePosition()
end

function CK:SavePosition()
    local point, _, relPoint, x, y = self.frame:GetPoint()
    self.db.pos = { point, relPoint, x, y }
end

function CK:RestorePosition()
    local f = self.frame
    f:ClearAllPoints()
    local pos = self.db.pos
    if pos then
        f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 160)
    end
    f:SetScale(self.db.settings.scale)
end

---------------------------------------------------------------------------
-- Rendering
---------------------------------------------------------------------------
function CK:DisplayChar(ch)
    if self.state.shift or self.state.caps then
        return CK.Upper(ch)
    end
    return ch
end

function CK:UpdateWheel()
    local f = self.frame
    if not f then return end
    local state = self.state
    local layout = LAYOUTS[state.layer]

    for i, p in ipairs(f.petals) do
        local selected = state.petal == i
        if selected then
            p.bg:SetVertexColor(0.85, 0.65, 0.15, 0.7)
            p:SetScale(1.08)
        else
            p.bg:SetVertexColor(0.25, 0.25, 0.3, 0.6)
            p:SetScale(1)
        end
        for s, b in ipairs(p.keys) do
            b.text:SetText(self:DisplayChar(layout[i][s]))
            if selected then
                b.text:SetTextColor(unpack(SLOT_COLORS[s]))
            else
                b.text:SetTextColor(0.92, 0.92, 0.92)
            end
        end
    end

    for _, t in ipairs(f.hubHints) do
        t:SetAlpha(state.petal and 0.25 or 1)
    end

    local mode = {}
    if state.caps then
        mode[#mode + 1] = L.CAPS
    elseif state.shift then
        mode[#mode + 1] = L.SHIFT
    end
    if state.layer == "symbols" then mode[#mode + 1] = L.SYMBOLS end
    f.mode:SetText(table.concat(mode, "  "))
    f.actions.ToggleSymbols:SetText(state.layer == "symbols" and L.LETTERS or L.SYMBOLS)
    if state.shift or state.caps then
        f.actions.ToggleShift:LockHighlight()
    else
        f.actions.ToggleShift:UnlockHighlight()
    end
end

function CK:UpdateSuggestions()
    local f = self.frame
    local list = self.state.suggestions
    for i, b in ipairs(f.sugg) do
        local word = list[i]
        if word then
            b:SetText(word)
            b:Show()
            if i == self.state.selected then b:LockHighlight() else b:UnlockHighlight() end
        else
            b:Hide()
        end
    end
end

function CK:GetChannelLabel(eb)
    local chatType = eb:GetAttribute("chatType") or "SAY"
    local label
    if chatType == "WHISPER" or chatType == "BN_WHISPER" then
        label = format(CHAT_WHISPER_SEND or "To %s: ", eb:GetAttribute("tellTarget") or "?")
    elseif chatType == "CHANNEL" then
        local target = eb:GetAttribute("channelTarget")
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

local WORD_TAIL = "(" .. CK.WORD_CHARS .. "*)$"
local PREV_WORD = "(" .. CK.WORD_CHARS .. "+)%s+$"

function CK:Refresh()
    local f = self.frame
    local eb = self.editBox
    if not (f and f:IsShown() and eb) then return end

    local text = eb:GetText() or ""
    f.channel:SetText(self:GetChannelLabel(eb))
    f.preview:SetText(text .. "|cffffd200_|r")

    local prefix = text:match(WORD_TAIL) or ""
    local prev = text:sub(1, #text - #prefix):match(PREV_WORD)
    self.state.suggestions = CK.Predict:Query(prefix, prev, self.db.settings.numSuggestions)
    self.state.selected = 1
    self:UpdateSuggestions()
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------
local function moveToEnd(eb)
    eb:SetCursorPosition(#(eb:GetText() or ""))
end

function CK:InsertText(text)
    local eb = self.editBox
    if not eb then return end
    moveToEnd(eb)
    eb:Insert(text)
    self:Refresh()
end

function CK:SetText(text)
    local eb = self.editBox
    if not eb then return end
    eb:SetText(text)
    moveToEnd(eb)
    self:Refresh()
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
    local eb = self.editBox
    if eb then self:SetText(CK.DropLastChar(eb:GetText() or "")) end
end

function CK:DeleteWord()
    local eb = self.editBox
    if not eb then return end
    local text = (eb:GetText() or ""):gsub("%s+$", "")
    text = text:gsub("[^%s]+$", "")
    self:SetText(text)
end

function CK:AcceptSuggestion(index)
    local eb = self.editBox
    local word = self.state.suggestions[index or self.state.selected]
    if not (eb and word) then return false end
    local text = eb:GetText() or ""
    local prefix = text:match(WORD_TAIL) or ""
    self:SetText(text:sub(1, #text - #prefix) .. word .. " ")
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

local CHANNELS = { "SAY", "PARTY", "RAID", "GUILD", "YELL" }

local function channelAvailable(chatType)
    if chatType == "PARTY" then
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

function CK:CycleChannel()
    local eb = self.editBox
    if not eb then return end
    local current = eb:GetAttribute("chatType")
    local index = 0
    for i, t in ipairs(CHANNELS) do
        if t == current then index = i end
    end
    for step = 1, #CHANNELS do
        local t = CHANNELS[(index + step - 1) % #CHANNELS + 1]
        if channelAvailable(t) then
            eb:SetAttribute("chatType", t)
            if ChatEdit_UpdateHeader then ChatEdit_UpdateHeader(eb) end
            break
        end
    end
    self:Refresh()
end

function CK:Send()
    local eb = self.editBox
    if not eb then return end
    if (eb:GetText() or ""):match("^%s*$") then
        return self:Cancel()
    end
    if ChatEdit_OnEnterPressed then
        ChatEdit_OnEnterPressed(eb)
    else
        ChatEdit_SendText(eb, 1)
        ChatEdit_DeactivateChat(eb)
    end
    self:Close()
end

function CK:Cancel()
    local eb = self.editBox
    self:Close()
    if not eb then return end
    if ChatEdit_OnEscapePressed then
        ChatEdit_OnEscapePressed(eb)
    else
        eb:SetText("")
        ChatEdit_DeactivateChat(eb)
    end
end

---------------------------------------------------------------------------
-- Open / close
---------------------------------------------------------------------------
function CK:Open(eb)
    self:BuildUI()
    self.editBox = eb
    local state = self.state
    state.layer, state.shift, state.caps, state.petal = "letters", false, false, nil
    self.frame:Show()
    self:UpdateWheel()
    self:Refresh()
end

function CK:Close()
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
    end
    self.state.petal = nil
    self.repeatFn = nil
end

function CK:IsOpen()
    return self.frame and self.frame:IsShown()
end
