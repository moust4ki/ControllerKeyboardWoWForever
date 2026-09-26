local _, CK = ...
local L = CK.L

-- Input method "one-stick keyboard": a full AZERTY / QWERTY keyboard. The left
-- stick's tilt is the cursor's ABSOLUTE position on the keyboard (released =
-- center), RT types the highlighted key, LT deletes.
CK.Methods = CK.Methods or {}
local M = { key = "stick", width = 460, areaWidth = 444 }
CK.Methods.stick = M

M.buttons = {
    PADRTRIGGER = "TypeHighlighted",
    PADLTRIGGER = "Backspace",
    PADRSHOULDER = "Space",
    PADLSHOULDER = "ToggleShift",
    PADLSTICK = "ToggleSymbols",
}

function M:Help()
    return {
        { "LS", L.HELP_CURSOR }, { "RT", L.HELP_TYPE }, { "LT", L.BACKSPACE }, { "RB", L.SPACE },
        { "LB", L.SHIFT }, { "RS", L.HELP_PICK },
    }
end

-- Keys: a character, or { k = special key, w = width in key units }
local function special(k, w) return { k = k, w = w } end
local SHIFT, BACK, LAYER, SPACE = special("SHIFT", 1.5), special("BACK", 1.5), special("LAYER", 1), special("SPACE", 4)

local LAYOUTS = {
    azerty = {
        { "a", "z", "e", "r", "t", "y", "u", "i", "o", "p" },
        { "q", "s", "d", "f", "g", "h", "j", "k", "l", "m" },
        { SHIFT, "w", "x", "c", "v", "b", "n", "'", BACK },
        { LAYER, ",", "-", SPACE, ".", "?", "!" },
    },
    qwerty = {
        { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p" },
        { "a", "s", "d", "f", "g", "h", "j", "k", "l", "'" },
        { SHIFT, "z", "x", "c", "v", "b", "n", "m", BACK },
        { LAYER, ",", "-", SPACE, ".", "?", "!" },
    },
    symbols = {
        { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" },
        { "é", "è", "ê", "à", "â", "ç", "ù", "û", "î", "ô" },
        { SHIFT, "ë", "ï", "œ", "@", "/", ":", ";", BACK },
        { LAYER, "(", ")", SPACE, "\"", "%", "+" },
    },
}

local PAD, GAP = 4, 4
local UNIT = (M.areaWidth - 2 * PAD + GAP) / 10   -- one key + one gap
local KEY_H, ROW_STEP = 38, 42
M.height = 2 * PAD + 4 * KEY_H + 3 * GAP

-- Cursor range: the centers of the corner keys
local GRID_W, GRID_H = 10 * UNIT - GAP, 4 * KEY_H + 3 * GAP
local CENTER_X, CENTER_Y = PAD + GRID_W / 2, PAD + GRID_H / 2
local HALF_X, HALF_Y = (GRID_W - (UNIT - GAP)) / 2, (GRID_H - KEY_H) / 2

local MAGNET_PX = { none = 0, weak = 4, medium = 8, strong = 14 }

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
local function buildKey(parent, def, x, y, w)
    local K = CK.UIKit
    local b = CK.NewFrame("Button", nil, parent)
    K.place(b, parent, x, y, w, KEY_H)
    b.base = K.nineSlice(b, "ck_btn_normal", 128, 32, 6, 6, "BORDER")
    b.select = K.nineSlice(b, "ck_select", 128, 32, 10, 10, "ARTWORK")
    b.select:SetShown(false)
    local isChar = type(def) == "string"
    b.label = K.text(b, isChar and 16 or 11)
    b.label:SetPoint("CENTER", 0, 1)
    b.char = isChar and def or nil
    b.special = not isChar and def.k or nil
    -- Center and size in area coordinates (y down), for the nearest-key search
    b.cx, b.cy, b.w, b.h = x + w / 2, y + KEY_H / 2, w, KEY_H
    b:SetScript("OnClick", function() M:Press(b) end)
    b:SetScript("OnEnter", function() M.hover = b; M:Update() end)
    b:SetScript("OnLeave", function() M.hover = nil; M:Update() end)
    return b
end

function M:Build(area)
    local K = CK.UIKit
    self.sets = {}
    for name, rows in pairs(LAYOUTS) do
        local set = CK.NewFrame("Frame", nil, area)
        set:SetAllPoints()
        set.keys = {}
        for r, row in ipairs(rows) do
            local x = PAD
            for _, def in ipairs(row) do
                local units = type(def) == "table" and def.w or 1
                local w = units * UNIT - GAP
                set.keys[#set.keys + 1] = buildKey(set, def, x, PAD + (r - 1) * ROW_STEP, w)
                x = x + units * UNIT
            end
        end
        set:Hide()
        self.sets[name] = set
    end

    -- Cursor and line from the center, above the keys
    local over = CK.NewFrame("Frame", nil, area)
    over:SetAllPoints()
    over:SetFrameLevel(area:GetFrameLevel() + 30)
    self.over = over
    -- The line is optional: the keyboard works without it on a client lacking lines
    local line = over.CreateLine and over:CreateLine(nil, "OVERLAY")
    if line then
        line:SetThickness(2)
        line:SetColorTexture(K.C.gold[1], K.C.gold[2], K.C.gold[3], 0.55)
        self.line = line
    end
    local hub = K.texture(over, "ck_hl_hover", "OVERLAY")
    hub:SetSize(12, 12)
    hub:SetPoint("CENTER", over, "TOPLEFT", CENTER_X, -CENTER_Y)
    hub:SetAlpha(0.6)
    self.hub = hub
    local cursor = K.texture(over, "ck_hl", "OVERLAY", 1)
    cursor:SetSize(16, 16)
    self.cursor = cursor

    self.cx, self.cy = CENTER_X, CENTER_Y
end

---------------------------------------------------------------------------
-- Cursor
---------------------------------------------------------------------------
-- Disc -> square (inverse elliptical grid mapping): lets the round stick
-- reach the corners of the rectangular keyboard
local SQ2 = 2 * math.sqrt(2)
local function discToSquare(u, v)
    local u2, v2 = u * u, v * v
    local x = 0.5 * math.sqrt(math.max(0, 2 + u2 - v2 + SQ2 * u)) - 0.5 * math.sqrt(math.max(0, 2 + u2 - v2 - SQ2 * u))
    local y = 0.5 * math.sqrt(math.max(0, 2 - u2 + v2 + SQ2 * v)) - 0.5 * math.sqrt(math.max(0, 2 - u2 + v2 - SQ2 * v))
    return math.max(-1, math.min(1, x)), math.max(-1, math.min(1, y))
end
M.discToSquare = discToSquare

function M:OnLeftStick(x, y)
    local dead = CK.db.settings.deadzone
    local len = math.sqrt(x * x + y * y)
    local u, v = 0, 0
    if len > dead then
        local scale = (math.min(len, 1) - dead) / (1 - dead) / len
        u, v = x * scale, y * scale
    end
    local sx, sy = discToSquare(u, v)
    self.cx, self.cy = CENTER_X + sx * HALF_X, CENTER_Y - sy * HALF_Y
    self:Update()
end

local function rectDistance(key, x, y)
    local dx = math.max(math.abs(x - key.cx) - key.w / 2, 0)
    local dy = math.max(math.abs(y - key.cy) - key.h / 2, 0)
    return math.sqrt(dx * dx + dy * dy), math.abs(x - key.cx) + math.abs(y - key.cy)
end

-- Nearest key, with a magnet: the highlighted key only changes when another
-- one is clearly closer, so it does not flicker between two neighbors
function M:PickKey(set)
    local x, y = self.cx, self.cy
    local best, bestD, bestTie
    for _, key in ipairs(set.keys) do
        local d, tie = rectDistance(key, x, y)
        if not best or d < bestD or (d == bestD and tie < bestTie) then
            best, bestD, bestTie = key, d, tie
        end
    end
    local current = self.selected
    if current and current:GetParent() == set and best ~= current then
        local magnet = MAGNET_PX[CK.db.settings.magnet] or 8
        if rectDistance(current, x, y) <= bestD + magnet then return current end
    end
    return best
end

function M:ActiveSet()
    if CK.state.layer == "symbols" then return self.sets.symbols end
    return self.sets[CK.db.settings.kbLayout] or self.sets.azerty
end

function M:Reset()
    self.cx, self.cy = CENTER_X, CENTER_Y
    self.selected = nil
end

---------------------------------------------------------------------------
-- Typing
---------------------------------------------------------------------------
function M:Press(key)
    if not key then return end
    if key.char then
        CK:TypeChar(key.char)
    elseif key.special == "SHIFT" then
        CK:ToggleShift()
    elseif key.special == "BACK" then
        CK:Backspace()
    elseif key.special == "LAYER" then
        CK:ToggleSymbols()
    elseif key.special == "SPACE" then
        CK:Space()
    end
end

-- RT: the binding gives one press per pull of the trigger, so one letter
function CK:TypeHighlighted()
    if self:GetMethod() ~= M then return end
    M:Press(M.selected)
end

---------------------------------------------------------------------------
-- Rendering
---------------------------------------------------------------------------
local SPECIAL_LABEL = { SHIFT = "SHIFT", BACK = "BACKSPACE", SPACE = "SPACE" }

function M:Update()
    if not self.sets then return end
    local K = CK.UIKit
    local state = CK.state
    local set = self:ActiveSet()
    for _, s in pairs(self.sets) do s:SetShown(s == set) end

    self.selected = self:PickKey(set)
    local shiftOn = state.shift or state.caps

    for _, key in ipairs(set.keys) do
        local selected = key == self.selected
        local active = key.special == "SHIFT" and shiftOn
        if key == self.hover then
            key.base:SetFile("ck_btn_hover")
        elseif active then
            key.base:SetFile("ck_btn_active")
        else
            key.base:SetFile("ck_btn_normal")
        end
        key.select:SetShown(selected)

        if key.char then
            key.label:SetText(CK:DisplayChar(key.char))
        elseif key.special == "LAYER" then
            key.label:SetText(state.layer == "symbols" and L.LETTERS or L.SYMBOLS)
        else
            key.label:SetText(L[SPECIAL_LABEL[key.special]])
        end
        if selected then
            key.label:SetTextColor(unpack(K.C.goldActive))
        elseif key == self.hover then
            key.label:SetTextColor(unpack(K.C.btnHover))
        elseif key.char then
            key.label:SetTextColor(unpack(K.C.gold))
        else
            key.label:SetTextColor(unpack(active and K.C.gold or K.C.btn))
        end
    end

    self.cursor:ClearAllPoints()
    self.cursor:SetPoint("CENTER", self.over, "TOPLEFT", self.cx, -self.cy)
    local showLine = CK.db.settings.showLine
    if self.line then
        self.line:SetShown(showLine)
        self.line:SetStartPoint("TOPLEFT", self.over, CENTER_X, -CENTER_Y)
        self.line:SetEndPoint("TOPLEFT", self.over, self.cx, -self.cy)
    end
    self.hub:SetShown(showLine)
end
