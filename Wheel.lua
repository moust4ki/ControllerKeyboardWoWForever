local _, CK = ...
local L = CK.L

-- 8 petals, clockwise from the top. Each petal holds 4 characters placed
-- left, top, right, bottom: the right stick flicks toward the one to type.
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

local CIRCLE = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local WHITE = "Interface\\Buttons\\WHITE8X8"

local WIDTH = 340
local WHEEL_SIZE = 290
local WHEEL_RADIUS = 104
local PETAL_SIZE = 82
local KEY_OFFSET = 23
local KEY_SIZE = 26
local HUB_SIZE = 70
local SLOT_OFFSETS = { { -KEY_OFFSET, 0 }, { 0, KEY_OFFSET }, { KEY_OFFSET, 0 }, { 0, -KEY_OFFSET } }

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
-- UI construction
---------------------------------------------------------------------------
local function circle(parent, layer, size, r, g, b, a)
    local t = parent:CreateTexture(nil, layer)
    t:SetTexture(CIRCLE)
    t:SetSize(size, size)
    t:SetVertexColor(r, g, b, a)
    return t
end

local function flatButton(parent, width, height, text, onClick)
    local b = CK.NewFrame("Button", nil, parent)
    b:SetSize(width, height)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetTexture(WHITE)
    b:SetHighlightTexture(WHITE)
    b:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.12)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", 3, 0)
    b.text:SetPoint("RIGHT", -3, 0)
    b.text:SetText(text)
    b:SetScript("OnClick", onClick)
    function b:SetActive(active)
        if active then
            self.bg:SetVertexColor(0.55, 0.4, 0.05, 0.9)
        else
            self.bg:SetVertexColor(0, 0, 0, 0.6)
        end
    end
    b:SetActive(false)
    return b
end

function CK:BuildUI()
    if self.frame then return end

    -- Invisible container: only the pieces below are drawn
    local f = CK.NewFrame("Frame", "ControllerKeyboardFrame", UIParent)
    f:SetSize(WIDTH, 440)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:Hide()
    self.frame = f

    -- Message preview (drag it to move the keyboard)
    local top = CK.NewFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
    top:SetSize(WIDTH, 44)
    top:SetPoint("TOP")
    top:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    top:SetBackdropColor(0, 0, 0, 0.75)
    top:SetBackdropBorderColor(0.5, 0.5, 0.55, 0.9)
    CK:MakeDragHandle(top)
    f.top = top

    -- Move grip (also shows that the keyboard can be dragged)
    local grip = top:CreateTexture(nil, "OVERLAY")
    grip:SetTexture("Interface\CURSOR\UI-Cursor-Move")
    grip:SetSize(18, 18)
    grip:SetPoint("TOPRIGHT", -6, -6)
    grip:SetAlpha(0.7)

    f.preview = top:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
    f.preview:SetPoint("TOPLEFT", 9, -7)
    f.preview:SetPoint("BOTTOMRIGHT", -44, 6)
    f.preview:SetJustifyH("LEFT")
    f.preview:SetJustifyV("TOP")

    f.mode = top:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.mode:SetPoint("TOPRIGHT", -28, -8)

    -- Suggestions
    f.sugg = {}
    local n = self.db.settings.numSuggestions
    local sw = (WIDTH - (n - 1) * 2) / n
    for i = 1, n do
        local b = flatButton(f, sw, 22, "", function() CK:AcceptSuggestion(i) end)
        b.text:SetFontObject("GameFontHighlight")
        b:SetPoint("TOPLEFT", (i - 1) * (sw + 2), -47)
        b:Hide()
        f.sugg[i] = b
    end

    -- Wheel
    local wheel = CK.NewFrame("Frame", nil, f)
    wheel:SetSize(WHEEL_SIZE, WHEEL_SIZE)
    wheel:SetPoint("TOP", 0, -72)
    f.wheel = wheel

    local hub = circle(wheel, "BACKGROUND", HUB_SIZE, 0, 0, 0, 0.6)
    hub:SetPoint("CENTER")
    local hubHandle = CK.NewFrame("Frame", nil, wheel)
    hubHandle:SetSize(HUB_SIZE, HUB_SIZE)
    hubHandle:SetPoint("CENTER")
    CK:MakeDragHandle(hubHandle)
    f.hubHints = {}
    local hubHints = {
        { "<", -20, 0 }, { L.HUB_UP, 0, 18 }, { ">", 20, 0 }, { L.HUB_DOWN, 0, -18 },
    }
    for i, h in ipairs(hubHints) do
        local t = wheel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("CENTER", wheel, "CENTER", h[2], h[3])
        t:SetText(h[1])
        f.hubHints[i] = t
    end

    f.petals = {}
    for i = 1, 8 do
        local angle = math.rad(90 - (i - 1) * 45)
        local p = CK.NewFrame("Frame", nil, wheel)
        p:SetSize(PETAL_SIZE, PETAL_SIZE)
        p:SetPoint("CENTER", wheel, "CENTER", math.cos(angle) * WHEEL_RADIUS, math.sin(angle) * WHEEL_RADIUS)
        p.bg = circle(p, "BACKGROUND", PETAL_SIZE, 0, 0, 0, 0.55)
        p.bg:SetPoint("CENTER")
        p.keys = {}
        for s = 1, 4 do
            local b = CK.NewFrame("Button", nil, p)
            b:SetSize(KEY_SIZE, KEY_SIZE)
            b:SetPoint("CENTER", p, "CENTER", SLOT_OFFSETS[s][1], SLOT_OFFSETS[s][2])
            b.aim = circle(b, "ARTWORK", KEY_SIZE + 4, 1, 0.8, 0.2, 0.9)
            b.aim:SetPoint("CENTER")
            b.aim:Hide()
            b:SetHighlightTexture(CIRCLE)
            b:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.3)
            b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            b.text:SetPoint("CENTER", 0, 1)
            b:SetScript("OnClick", function() CK:TypeSlot(i, s) end)
            p.keys[s] = b
        end
        f.petals[i] = p
    end

    -- Mouse / Steam Controller trackpad actions
    local actions = {
        { L.SHIFT, "ToggleShift" },
        { L.SYMBOLS, "ToggleSymbols" },
        { L.SPACE, "Space" },
        { L.BACKSPACE, "Backspace" },
        { L.CHANNEL, "CycleChannel" },
        { L.SEND, "Send" },
        { "X", "Close" },
    }
    local widths = { 1, 1, 1.3, 1.3, 1.1, 1.3, 0.6 }
    local total = 0
    for _, w in ipairs(widths) do total = total + w end
    local unit = (WIDTH - (#actions - 1) * 2) / total
    f.actions = {}
    local x = 0
    for i, a in ipairs(actions) do
        local b = flatButton(f, unit * widths[i], 20, a[1], function() CK[a[2]](CK) end)
        b:SetPoint("TOPLEFT", x, -72 - WHEEL_SIZE - 4)
        x = x + unit * widths[i] + 2
        f.actions[a[2]] = b
    end

    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.hint:SetPoint("TOP", 0, -72 - WHEEL_SIZE - 30)
    f.hint:SetWidth(WIDTH)
    f.hint:SetText(L.HINT)

    self:SetupInput(f)
    self:RestorePosition()

    -- Debug: report when something else than CK:Close hides the keyboard
    f:HookScript("OnHide", function()
        if CK.db.settings.debug and not CK.closing then
            CK:Print("hidden by: %s", debugstack(3, 4, 0) or "?")
        end
    end)
end

-- Dragging `handle` moves the whole keyboard
function CK:MakeDragHandle(handle)
    local f = self.frame
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function() f:StartMoving() end)
    handle:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        CK:SavePosition()
    end)
    handle:SetScript("OnEnter", function(h)
        GameTooltip:SetOwner(h, "ANCHOR_TOP")
        GameTooltip:SetText(L.DRAG_HINT, 1, 1, 1)
        GameTooltip:Show()
    end)
    handle:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Show the keyboard without the chat so it can be placed (/ck move)
function CK:ToggleMoveMode()
    if not self.frame then
        if InCombatLockdown() then return end
        self:BuildUI()
    end
    if self.moving then
        self.moving = false
        self.frame:Hide()
        return
    end
    if self:IsOpen() then return end
    self.moving = true
    self.editBox = nil
    self.frame:Show()
    self:UpdateWheel()
    self.frame.preview:SetText(L.MOVE_MODE)
    for _, b in ipairs(self.frame.sugg) do b:Hide() end
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
    elseif ChatFrame1 then
        f:SetPoint("BOTTOMLEFT", ChatFrame1, "BOTTOMRIGHT", 40, -30)
    else
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 140)
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
            p.bg:SetVertexColor(0.45, 0.33, 0.05, 0.85)
            p:SetScale(1.12)
        else
            p.bg:SetVertexColor(0, 0, 0, state.petal and 0.35 or 0.55)
            p:SetScale(1)
        end
        for s, b in ipairs(p.keys) do
            b.text:SetText(self:DisplayChar(layout[i][s]))
            local aimed = selected and state.aim == s
            b.aim:SetShown(aimed)
            if aimed then
                b.text:SetTextColor(0, 0, 0)
            elseif selected or not state.petal then
                b.text:SetTextColor(1, 1, 1)
            else
                b.text:SetTextColor(0.6, 0.6, 0.6)
            end
        end
    end

    for _, t in ipairs(f.hubHints) do
        t:SetShown(not state.petal)
    end

    if state.caps then
        f.mode:SetText(L.CAPS)
    elseif state.shift then
        f.mode:SetText(L.SHIFT)
    else
        f.mode:SetText(state.layer == "symbols" and L.SYMBOLS or "")
    end
    f.actions.ToggleSymbols.text:SetText(state.layer == "symbols" and L.LETTERS or L.SYMBOLS)
    f.actions.ToggleSymbols:SetActive(state.layer == "symbols")
    f.actions.ToggleShift:SetActive(state.shift or state.caps)
end

function CK:UpdateSuggestions()
    local f = self.frame
    local list = self.state.suggestions
    for i, b in ipairs(f.sugg) do
        local word = list[i]
        if word then
            b.text:SetText(word)
            b:SetActive(i == self.state.selected)
            b:Show()
        else
            b:Hide()
        end
    end
end

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
local PREV_WORD = "(" .. CK.WORD_CHARS .. "+)%s+$"

function CK:Refresh()
    local f = self.frame
    if not (f and f:IsShown()) or self.moving then return end
    if not (self.standalone or self.editBox) then return end
    if not self.standalone then self:SnapshotChat() end

    local text = self:GetText()
    f.preview:SetText(self:GetChannelLabel() .. previewTail(text) .. "|cffffd200_|r")

    local prefix = text:match(WORD_TAIL) or ""
    local prev = text:sub(1, #text - #prefix):match(PREV_WORD)
    self.state.suggestions = CK.Predict:Query(prefix, prev, self.db.settings.numSuggestions)
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
    local text = self:GetText()
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
    if self.moving then
        self.moving = false
        if self.frame then self.frame:Hide() end
    end
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
    self.moving = false
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
