local _, CK = ...
local L = CK.L

-- Layout from the Claude Design spec (Controller Keyboard.dc.html):
-- 340 x 456 panel, coordinates in px from its top-left corner (y goes down).
local TEX = "Interface\\AddOns\\ControllerKeyboard\\textures\\"
local W, H = 340, 456
local WHEEL_X, WHEEL_Y, WHEEL_SIZE = 30, 92, 280
local PETAL_R, PETAL_SIZE, PETAL_SEL = 96, 76, 81
local HUB_SIZE = 92
-- Character offsets in a petal: left, top, right, bottom (y down)
local CHAR_OFF = { { -20, 0 }, { 0, -20 }, { 20, 0 }, { 0, 20 } }

local function rgb(hex)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local C = {
    gold = { rgb("FFD100") },
    goldActive = { rgb("FFF1B8") },
    suggSel = { rgb("FFF4C2") },
    sugg = { rgb("C8B88A") },
    btn = { rgb("E8D7A8") },
    btnHover = { rgb("FFE45C") },
    gesture = { rgb("D9C9A0") },
    dark = { rgb("1A1206") },
    capsFill = { rgb("E0B400") },
    border = { rgb("8A7045") },
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function texture(parent, file, layer, sub)
    local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
    if file then t:SetTexture(TEX .. file) end
    return t
end

-- Place `region` at panel-style coordinates inside `parent`
local function place(region, parent, x, y, w, h)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    if w then region:SetSize(w, h) end
end

-- Every font string goes through here so the font can be changed live
local fontStrings = {}
local function text(parent, size, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFont(CK:GetFontPath(), size, "")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 0.9)
    fontStrings[#fontStrings + 1] = { fs = fs, size = size }
    return fs
end

function CK:ApplyFont()
    local path = self:GetFontPath()
    for _, entry in ipairs(fontStrings) do
        entry.fs:SetFont(path, entry.size, "")
    end
end

-- 9-slice: the `texCorner` px corners of a texW x texH texture are drawn at
-- `corner` px; edges and center stretch. Returns an object with :SetFile().
local function nineSlice(frame, file, texW, texH, texCorner, corner, layer)
    local u, v = texCorner / texW, texCorner / texH
    local cols = { { 0, u }, { u, 1 - u }, { 1 - u, 1 } }
    local rows = { { 0, v }, { v, 1 - v }, { 1 - v, 1 } }
    local parts = {}
    for r = 1, 3 do
        for c = 1, 3 do
            local t = texture(frame, nil, layer)
            t.coords = { cols[c][1], cols[c][2], rows[r][1], rows[r][2] }
            parts[#parts + 1] = t
        end
    end
    local tl, t, tr, l, m, r, bl, b, br = unpack(parts)
    tl:SetPoint("TOPLEFT"); tl:SetSize(corner, corner)
    tr:SetPoint("TOPRIGHT"); tr:SetSize(corner, corner)
    bl:SetPoint("BOTTOMLEFT"); bl:SetSize(corner, corner)
    br:SetPoint("BOTTOMRIGHT"); br:SetSize(corner, corner)
    t:SetPoint("TOPLEFT", tl, "TOPRIGHT"); t:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT")
    b:SetPoint("TOPLEFT", bl, "TOPRIGHT"); b:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
    l:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); l:SetPoint("BOTTOMRIGHT", bl, "TOPRIGHT")
    r:SetPoint("TOPLEFT", tr, "BOTTOMLEFT"); r:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
    m:SetPoint("TOPLEFT", tl, "BOTTOMRIGHT"); m:SetPoint("BOTTOMRIGHT", br, "TOPLEFT")

    local slice = { parts = parts }
    function slice:SetFile(name)
        for _, p in ipairs(self.parts) do
            p:SetTexture(TEX .. name)
            p:SetTexCoord(unpack(p.coords))
        end
    end
    function slice:SetShown(shown)
        for _, p in ipairs(self.parts) do p:SetShown(shown) end
    end
    slice:SetFile(file)
    return slice
end

local function solid(parent, layer, r, g, b, a)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetColorTexture(r, g, b, a)
    return t
end

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
local function buildButton(parent, x, y, w, h, label, onClick)
    local b = CK.NewFrame("Button", nil, parent)
    place(b, parent, x, y, w, h)
    b.slice = nineSlice(b, "ck_btn_normal", 128, 32, 6, 6, "ARTWORK")
    b.label = text(b, 11)
    b.label:SetPoint("CENTER", 0, 0)
    b.label:SetText(label)
    b:SetScript("OnClick", onClick)
    function b:Render()
        if self.hover then
            self.slice:SetFile("ck_btn_hover")
            self.label:SetTextColor(unpack(C.btnHover))
        elseif self.active then
            self.slice:SetFile("ck_btn_active")
            self.label:SetTextColor(unpack(C.gold))
        else
            self.slice:SetFile("ck_btn_normal")
            self.label:SetTextColor(unpack(C.btn))
        end
    end
    function b:SetActive(active)
        self.active = active
        self:Render()
    end
    b:SetScript("OnEnter", function(s) s.hover = true; s:Render() end)
    b:SetScript("OnLeave", function(s) s.hover = false; s:Render() end)
    b:Render()
    return b
end

function CK:BuildUI()
    if self.frame then return end

    local f = CK.NewFrame("Frame", "ControllerKeyboardFrame", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:Hide()
    self.frame = f
    self:MakeDragHandle(f)

    -- Background: tiled stone/leather, 1 px bronze outline
    local bg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetTexture(TEX .. "ck_panel_bg", "REPEAT", "REPEAT")
    bg:SetHorizTile(true)
    bg:SetVertTile(true)
    bg:SetAllPoints()
    bg:SetVertexColor(1, 1, 1, 0.82)
    local br, bgc, bb = unpack(C.border)
    local edges = {
        { "TOPLEFT", "TOPRIGHT", nil, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
        { "TOPLEFT", "BOTTOMLEFT", 1, nil }, { "TOPRIGHT", "BOTTOMRIGHT", 1, nil },
    }
    for _, e in ipairs(edges) do
        local t = solid(f, "BORDER", br, bgc, bb, 0.55)
        t:SetPoint(e[1]); t:SetPoint(e[2])
        if e[3] then t:SetWidth(e[3]) else t:SetHeight(e[4]) end
    end

    -- Input bar: channel + text + blinking cursor, mode badge, move grip
    local bar = CK.NewFrame("Frame", nil, f)
    place(bar, f, 8, 8, 324, 44)
    nineSlice(bar, "ck_bar", 256, 64, 8, 8, "BORDER")

    f.preview = text(f, 13)
    place(f.preview, f, 16, 14, 218, 32)
    f.preview:SetJustifyH("LEFT")
    f.preview:SetJustifyV("TOP")
    f.preview:SetWordWrap(true)
    if f.preview.SetMaxLines then f.preview:SetMaxLines(2) end

    local badge = CK.NewFrame("Frame", nil, f)
    place(badge, f, 240, 21, 58, 18)
    badge.outline = nineSlice(badge, "ck_btn_normal", 128, 32, 6, 5, "ARTWORK")
    badge.fill = solid(badge, "ARTWORK", C.capsFill[1], C.capsFill[2], C.capsFill[3], 1)
    badge.fill:SetAllPoints()
    badge.label = text(badge, 10)
    badge.label:SetPoint("CENTER")
    badge:Hide()
    f.badge = badge

    local grip = CK.NewFrame("Button", nil, f)
    place(grip, f, 302, 17, 26, 26)
    grip.icon = texture(grip, "ck_move", "ARTWORK")
    grip.icon:SetSize(24, 24)
    grip.icon:SetPoint("CENTER")
    grip:SetScript("OnEnter", function(s) s.icon:SetVertexColor(1, 0.9, 0.55) end)
    grip:SetScript("OnLeave", function(s) s.icon:SetVertexColor(1, 1, 1) end)
    self:MakeDragHandle(grip)
    f.grip = grip

    -- Suggestions bar
    local sbar = CK.NewFrame("Frame", nil, f)
    place(sbar, f, 8, 58, 324, 28)
    nineSlice(sbar, "ck_bar", 256, 64, 8, 8, "BORDER")
    local lb = texture(f, nil, "ARTWORK")
    place(lb, f, 12, 61, 22, 22)
    self:SetGlyph(lb, "LB")
    local rb = texture(f, nil, "ARTWORK")
    place(rb, f, 306, 61, 22, 22)
    self:SetGlyph(rb, "RB")

    f.sugg = {}
    for n = 0, 4 do
        local b = CK.NewFrame("Button", nil, f)
        place(b, f, 38 + 54 * n, 59, 50, 26)
        b.select = nineSlice(b, "ck_select", 128, 32, 10, 10, "ARTWORK")
        b.label = text(b, 12)
        b.label:SetPoint("LEFT", 2, 0)
        b.label:SetPoint("RIGHT", -2, 0)
        b.label:SetWordWrap(false)
        b:SetScript("OnClick", function() CK:AcceptSuggestion(n + 1) end)
        b:Hide()
        f.sugg[n + 1] = b
    end

    -- Wheel
    local wheel = CK.NewFrame("Frame", nil, f)
    place(wheel, f, WHEEL_X, WHEEL_Y, WHEEL_SIZE, WHEEL_SIZE)
    local disc = texture(wheel, "ck_disc", "BACKGROUND")
    disc:SetAllPoints()
    f.wheel = wheel

    f.petals = {}
    for i = 1, 8 do
        local a = (i - 1) * math.pi / 4
        local px, py = 140 + PETAL_R * math.sin(a), 140 - PETAL_R * math.cos(a)
        local p = CK.NewFrame("Frame", nil, wheel)
        p:SetPoint("CENTER", wheel, "TOPLEFT", px, -py)
        p:SetSize(PETAL_SIZE, PETAL_SIZE)
        p.slot = texture(p, "ck_slot", "BORDER")
        p.slot:SetAllPoints()
        p.glow = texture(p, "ck_slot_glow", "ARTWORK")
        p.glow:SetAllPoints()
        p.glow:Hide()
        p.keys = {}
        for j = 1, 4 do
            local k = CK.NewFrame("Button", nil, p)
            k:SetSize(26, 26)
            k.hl = texture(k, "ck_hl", "ARTWORK")
            k.hl:SetSize(32, 32)
            k.hl:SetPoint("CENTER")
            k.hl:Hide()
            k.hover = texture(k, "ck_hl_hover", "ARTWORK")
            k.hover:SetSize(32, 32)
            k.hover:SetPoint("CENTER")
            k.hover:Hide()
            k.label = text(k, 16)
            k.label:SetPoint("CENTER", 0, 1)
            k:SetScript("OnClick", function() CK:TypeSlot(i, j) end)
            k:SetScript("OnEnter", function()
                CK.state.hoverPetal, CK.state.hoverChar = i, j
                CK:UpdateWheel()
            end)
            k:SetScript("OnLeave", function()
                CK.state.hoverPetal, CK.state.hoverChar = nil, nil
                CK:UpdateWheel()
            end)
            p.keys[j] = k
        end
        f.petals[i] = p
    end

    -- Hub: right stick gestures, or the aimed letter
    local hub = CK.NewFrame("Frame", nil, wheel)
    hub:SetSize(HUB_SIZE, HUB_SIZE)
    hub:SetPoint("CENTER", wheel, "TOPLEFT", 140, -140)
    hub:SetFrameLevel(wheel:GetFrameLevel() + 20)
    local hubTex = texture(hub, "ck_hub", "BORDER")
    hubTex:SetAllPoints()
    f.gestures = {}
    local gold = "|cffffd100"
    local lines = {
        gold .. "^|r " .. L.GESTURE_INSERT,
        gold .. "<|r " .. L.GESTURE_WORD .. " " .. gold .. ">|r",
        gold .. "v|r " .. L.GESTURE_DELETE,
    }
    for n, line in ipairs(lines) do
        local g = text(hub, 11)
        g:SetPoint("CENTER", hub, "CENTER", 0, 18 - (n - 1) * 18)
        g:SetText(line)
        g:SetTextColor(unpack(C.gesture))
        f.gestures[n] = g
    end
    f.aimed = text(hub, 32)
    f.aimed:SetPoint("CENTER")
    f.aimed:SetTextColor(unpack(C.gold))
    f.aimed:SetShadowColor(0, 0, 0, 1)

    -- Mouse / Steam Controller actions
    local actions = {
        { "ToggleShift", L.SHIFT, 8, 36 },
        { "ToggleSymbols", L.SYMBOLS, 47, 36 },
        { "Space", L.SPACE, 86, 58 },
        { "Backspace", L.BACKSPACE, 147, 52 },
        { "CycleChannel", L.CHANNEL, 202, 44 },
        { "Send", L.SEND, 249, 54 },
        { "Close", "X", 306, 26 },
    }
    f.actions = {}
    for _, a in ipairs(actions) do
        local method = a[1]
        f.actions[method] = buildButton(f, a[3], 378, a[4], 26, a[2], function() CK[method](CK) end)
    end

    -- Help band: gamepad glyphs (A/B/X/Y belong to the game's chat UI)
    local band = solid(f, "BACKGROUND", 0, 0, 0, 0.35)
    place(band, f, 0, 410, W, 40)
    local filet1 = texture(f, "ck_filet", "BORDER")
    place(filet1, f, 0, 406, W, 8)
    local filet2 = texture(f, "ck_filet", "BORDER")
    place(filet2, f, 0, 446, W, 8)
    local help = {
        { "LS", L.HELP_PETAL }, { "RS", L.HELP_LETTER }, { "LB", L.BACKSPACE }, { "RB", L.SPACE },
        { "LT", L.SHIFT }, { "RT", L.SYMBOLS }, { "DPAD_LR", L.HELP_SUGGESTION }, { "DPAD_UP", L.GESTURE_INSERT },
    }
    f.helpGlyphs = {}
    for n, h in ipairs(help) do
        local col, row = (n - 1) % 4, math.floor((n - 1) / 4)
        local x, y = 10 + col * 80, 414 + row * 17
        local g = texture(f, nil, "ARTWORK")
        place(g, f, x, y, 16, 16)
        self:SetGlyph(g, h[1])
        f.helpGlyphs[#f.helpGlyphs + 1] = { tex = g, key = h[1] }
        local label = text(f, 11)
        label:SetPoint("LEFT", g, "RIGHT", 3, 0)
        label:SetText(h[2])
        label:SetTextColor(unpack(C.gold))
    end
    f.lbGlyph, f.rbGlyph = lb, rb

    -- Blinking cursor (0.53 s on / off)
    f:HookScript("OnShow", function()
        CK.cursorOn, CK.cursorTime = true, GetTime()
    end)

    self:SetupInput(f)
    f:HookScript("OnUpdate", function()
        local now = GetTime()
        if now - (CK.cursorTime or 0) >= 0.53 then
            CK.cursorTime = now
            CK.cursorOn = not CK.cursorOn
            CK:UpdatePreview()
        end
    end)
    self:RestorePosition()
    self:UpdateLock()

    -- Debug: report when something else than CK:Close hides the keyboard
    f:HookScript("OnHide", function()
        if CK.db.settings.debug and not CK.closing then
            CK:Print("hidden by: %s", debugstack(3, 4, 0) or "?")
        end
    end)
end

-- Refresh the gamepad glyphs (after changing the glyph style)
function CK:UpdateGlyphs()
    local f = self.frame
    if not f then return end
    self:SetGlyph(f.lbGlyph, "LB")
    self:SetGlyph(f.rbGlyph, "RB")
    for _, g in ipairs(f.helpGlyphs) do self:SetGlyph(g.tex, g.key) end
end

---------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------
-- Dragging `handle` moves the whole keyboard (only while unlocked)
function CK:MakeDragHandle(handle)
    local f = self.frame
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        if not CK.db.settings.locked then f:StartMoving() end
    end)
    handle:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        CK:SavePosition()
    end)
    if handle ~= f then
        handle:HookScript("OnEnter", function(h)
            if CK.db.settings.locked then return end
            GameTooltip:SetOwner(h, "ANCHOR_TOP")
            GameTooltip:SetText(L.DRAG_HINT, 1, 1, 1)
            GameTooltip:Show()
        end)
        handle:HookScript("OnLeave", function() GameTooltip:Hide() end)
    end
end

-- The move grip is only shown while the position is unlocked (/ck lock)
function CK:UpdateLock()
    if self.frame then
        self.frame.grip:SetShown(not self.db.settings.locked)
    end
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

function CK:UpdatePreview()
    local f = self.frame
    if not (f and f:IsShown()) then return end
    local cursor = self.cursorOn and "|cffffd100||r" or " "
    f.preview:SetText((self.previewBody or "") .. cursor)
end

function CK:UpdateWheel()
    local f = self.frame
    if not f then return end
    local state = self.state
    local layout = CK.LAYOUTS[state.layer]
    local baseLevel = f.wheel:GetFrameLevel() + 1

    for i, p in ipairs(f.petals) do
        local selected = state.petal == i
        local hovered = state.hoverPetal == i
        local dimmed = state.petal and not selected
        local size = selected and PETAL_SEL or PETAL_SIZE
        local scale = selected and 1.06 or 1
        p:SetSize(size, size)
        p:SetFrameLevel(baseLevel + (selected and 10 or (hovered and 5 or 0)))
        local shade = dimmed and 0.45 or 1
        p.slot:SetVertexColor(shade, shade, shade, 1)
        p.glow:SetShown(selected or hovered)
        p.glow:SetAlpha(selected and 1 or 0.5)

        for j, k in ipairs(p.keys) do
            k:ClearAllPoints()
            k:SetPoint("CENTER", p, "CENTER", CHAR_OFF[j][1] * scale, -CHAR_OFF[j][2] * scale)
            k:SetAlpha(dimmed and 0.45 or 1)
            local aimed = selected and state.aim == j
            local mouse = hovered and state.hoverChar == j
            k.hl:SetShown(aimed)
            k.hover:SetShown(mouse and not aimed)
            k.label:SetFont(CK:GetFontPath(), selected and 17 or 16, "")
            k.label:SetText(self:DisplayChar(layout[i][j]))
            if aimed then
                k.label:SetTextColor(unpack(C.dark))
                k.label:SetShadowColor(0, 0, 0, 0)
            else
                k.label:SetShadowColor(0, 0, 0, 0.9)
                if mouse then
                    k.label:SetTextColor(1, 1, 1)
                elseif selected then
                    k.label:SetTextColor(unpack(C.goldActive))
                else
                    k.label:SetTextColor(unpack(C.gold))
                end
            end
        end
    end

    -- Hub: gestures when no petal is picked, else the aimed letter
    local aimedChar = state.petal and state.aim and layout[state.petal][state.aim]
    for _, g in ipairs(f.gestures) do g:SetShown(not state.petal) end
    f.aimed:SetShown(aimedChar ~= nil)
    if aimedChar then f.aimed:SetText(self:DisplayChar(aimedChar)) end

    -- Mode badge: MAJ / 123 outlined, caps lock filled
    local badge = f.badge
    local label
    if state.caps then
        label = L.BADGE_CAPS
    elseif state.shift then
        label = L.BADGE_SHIFT
    elseif state.layer == "symbols" then
        label = L.SYMBOLS
    end
    badge:SetShown(label ~= nil)
    if label then
        badge.label:SetText(label)
        badge.outline:SetShown(not state.caps)
        badge.fill:SetShown(state.caps)
        if state.caps then
            badge.label:SetTextColor(unpack(C.dark))
            badge.label:SetShadowColor(0, 0, 0, 0)
        else
            badge.label:SetTextColor(unpack(C.gold))
            badge.label:SetShadowColor(0, 0, 0, 0.9)
        end
    end

    local symbols = f.actions.ToggleSymbols
    symbols.label:SetText(state.layer == "symbols" and L.LETTERS or L.SYMBOLS)
    symbols:SetActive(state.layer == "symbols")
    f.actions.ToggleShift:SetActive(state.shift or state.caps)
end

function CK:UpdateSuggestions()
    local f = self.frame
    local list = self.state.suggestions
    for i, b in ipairs(f.sugg) do
        local word = list[i]
        if word then
            local selected = i == self.state.selected
            b.label:SetText(word)
            b.select:SetShown(selected)
            b.label:SetTextColor(unpack(selected and C.suggSel or C.sugg))
            b:Show()
        else
            b:Hide()
        end
    end
end
