local _, CK = ...
local L = CK.L

-- Input method "daisywheel": the left stick picks one of 8 petals, the right
-- stick flicks toward one of its 4 characters (left, top, right, bottom).
CK.Methods = CK.Methods or {}
local M = { key = "wheel", width = 340, areaWidth = 280, height = 280 }
CK.Methods.wheel = M

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

-- Petals 4 to 6 of the 123 layer hold the accents of the language
local accentLayouts = {}
local function layoutFor(layer)
    if layer ~= "symbols" then return LAYOUTS.letters end
    local accents = CK:Accents()
    local layout = accentLayouts[accents]
    if not layout then
        layout = {}
        for i, petal in ipairs(LAYOUTS.symbols) do layout[i] = petal end
        for p = 0, 2 do
            layout[4 + p] = { accents[p * 4 + 1], accents[p * 4 + 2], accents[p * 4 + 3], accents[p * 4 + 4] }
        end
        accentLayouts[accents] = layout
    end
    return layout
end

-- Pad buttons of this method (D-pad, A, B and right stick click are common)
M.buttons = {
    PADLSHOULDER = "Backspace",
    PADRSHOULDER = "Space",
    PADLTRIGGER = "ToggleShift",
    PADRTRIGGER = "ToggleSymbols",
    PADLSTICK = "ToggleSymbols",
}

function M:Help()
    return {
        { "LS", L.HELP_PETAL }, { "RS", L.HELP_LETTER }, { "LB", L.BACKSPACE }, { "RB", L.SPACE },
        { "LT", L.SHIFT }, { "RT", L.SYMBOLS },
    }
end

local PETAL_R, PETAL_SIZE, PETAL_SEL = 96, 76, 81
local HUB_SIZE = 92
-- Character offsets in a petal: left, top, right, bottom (y down)
local CHAR_OFF = { { -20, 0 }, { 0, -20 }, { 20, 0 }, { 0, 20 } }
local LEFT_IN, LEFT_OUT = 0.5, 0.35      -- petal selection deadzone (with hysteresis)

local function sector(x, y, count)
    local fromNorth = (90 - math.deg(math.atan2(y, x))) % 360
    local size = 360 / count
    return math.floor((fromNorth + size / 2) / size) % count
end

function M:Build(area)
    local K = CK.UIKit
    local disc = K.texture(area, "ck_disc", "BACKGROUND")
    -- New texture files are only seen after restarting the game (not /reload)
    if disc:SetTexture(K.TEX .. "ck_disc") == false then
        C_Timer.After(2, function() CK:Print(L.TEXTURES_MISSING) end)
    end
    disc:SetAllPoints()

    self.petals = {}
    for i = 1, 8 do
        local a = (i - 1) * math.pi / 4
        local px, py = 140 + PETAL_R * math.sin(a), 140 - PETAL_R * math.cos(a)
        local p = CK.NewFrame("Frame", nil, area)
        p:SetPoint("CENTER", area, "TOPLEFT", px, -py)
        p:SetSize(PETAL_SIZE, PETAL_SIZE)
        p.slot = K.texture(p, "ck_slot", "BORDER")
        p.slot:SetAllPoints()
        p.glow = K.texture(p, "ck_slot_glow", "ARTWORK")
        p.glow:SetAllPoints()
        p.glow:Hide()
        p.keys = {}
        for j = 1, 4 do
            local k = CK.NewFrame("Button", nil, p)
            k:SetSize(26, 26)
            k.hl = K.texture(k, "ck_hl", "ARTWORK")
            k.hl:SetSize(32, 32)
            k.hl:SetPoint("CENTER")
            k.hl:Hide()
            k.hover = K.texture(k, "ck_hl_hover", "ARTWORK")
            k.hover:SetSize(32, 32)
            k.hover:SetPoint("CENTER")
            k.hover:Hide()
            k.label = K.text(k, 16)
            k.label:SetPoint("CENTER", 0, 1)
            k:SetScript("OnClick", function() CK:TypeSlot(i, j) end)
            k:SetScript("OnEnter", function()
                M.hoverPetal, M.hoverChar = i, j
                M:Update()
            end)
            k:SetScript("OnLeave", function()
                M.hoverPetal, M.hoverChar = nil, nil
                M:Update()
            end)
            p.keys[j] = k
        end
        self.petals[i] = p
    end

    -- Hub: shows the letter aimed with the right stick
    local hub = CK.NewFrame("Frame", nil, area)
    hub:SetSize(HUB_SIZE, HUB_SIZE)
    hub:SetPoint("CENTER", area, "TOPLEFT", 140, -140)
    hub:SetFrameLevel(area:GetFrameLevel() + 20)
    local hubTex = K.texture(hub, "ck_hub", "BORDER")
    hubTex:SetAllPoints()
    self.aimed = K.text(hub, 32)
    self.aimed:SetPoint("CENTER")
    self.aimed:SetTextColor(unpack(K.C.gold))
    self.aimed:SetShadowColor(0, 0, 0, 1)
end

function M:Reset()
    self.petal = nil
end

function CK:TypeSlot(petal, slot)
    self:TypeChar(layoutFor(self.state.layer)[petal][slot])
end

function M:OnLeftStick(x, y)
    local len = math.sqrt(x * x + y * y)
    local petal
    if len >= LEFT_IN or (self.petal and len >= LEFT_OUT) then
        petal = sector(x, y, 8) + 1
    end
    if petal ~= self.petal then
        self.petal = petal
        self:Update()
    end
end

-- Right stick flick: the aimed character when a petal is picked, otherwise
-- the common navigation (see CK:SetRightStick)
function M:OnFlick(aim)
    if not self.petal then return false end
    CK:TypeSlot(self.petal, aim)
    return true
end

function M:Update()
    if not self.petals then return end
    local K = CK.UIKit
    local state = CK.state
    local layout = layoutFor(state.layer)
    local baseLevel = self.area:GetFrameLevel() + 1

    for i, p in ipairs(self.petals) do
        local selected = self.petal == i
        local hovered = self.hoverPetal == i
        local dimmed = self.petal and not selected
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
            local mouse = hovered and self.hoverChar == j
            k.hl:SetShown(aimed)
            k.hover:SetShown(mouse and not aimed)
            k.label:SetFont(CK:GetFontPath(), selected and 17 or 16, "")
            k.label:SetText(CK:DisplayChar(layout[i][j]))
            if aimed then
                k.label:SetTextColor(unpack(K.C.dark))
                k.label:SetShadowColor(0, 0, 0, 0)
            else
                k.label:SetShadowColor(0, 0, 0, 0.9)
                if mouse then
                    k.label:SetTextColor(1, 1, 1)
                elseif selected then
                    k.label:SetTextColor(unpack(K.C.goldActive))
                else
                    k.label:SetTextColor(unpack(K.C.gold))
                end
            end
        end
    end

    local aimedChar = self.petal and state.aim and layout[self.petal][state.aim]
    self.aimed:SetShown(aimedChar ~= nil)
    if aimedChar then self.aimed:SetText(CK:DisplayChar(aimedChar)) end
end
