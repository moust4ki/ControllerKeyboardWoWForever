local _, CK = ...
local L = CK.L

-- Input method "split keyboard" (settings key "stick"): a full AZERTY / QWERTY
-- keyboard cut in two halves. The left stick moves a cursor on the left half
-- (columns 1-5), the right stick on the right half (columns 6-10); each
-- stick's tilt is its cursor's ABSOLUTE position around the center of its
-- half (released = center). LT types the left cursor's key, RT the right one.
CK.Methods = CK.Methods or {}
local M = { key = "stick", width = 460, areaWidth = 444 }
CK.Methods.stick = M

M.buttons = {
    PADLTRIGGER = "TypeLeft",
    PADRTRIGGER = "TypeRight",
    PADLSHOULDER = "Backspace",
    PADRSHOULDER = "Space",
    PADLSTICK = "ToggleSymbols",
}

function M:Help()
    return {
        { "LS", L.HELP_CURSOR_L }, { "RS", L.HELP_CURSOR_R }, { "LT", L.HELP_TYPE_L }, { "RT", L.HELP_TYPE_R },
        { "LB", L.BACKSPACE }, { "RB", L.SPACE },
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

local GRID_W, GRID_H = 10 * UNIT - GAP, 4 * KEY_H + 3 * GAP
local MID_X = PAD + GRID_W / 2                     -- border between the halves
local CENTER_Y = PAD + GRID_H / 2
-- Each half's center, and the cursor's reach around it. Full tilt puts the
-- cursor EDGE_IN px inside the half's edge keys, so an imperfect push still
-- reaches them.
local EDGE_IN = 6
local HALVES = {
    left = { cx = PAD + GRID_W / 4 },
    right = { cx = MID_X + GRID_W / 4 },
}
local REACH_X, REACH_Y = GRID_W / 4 - EDGE_IN, GRID_H / 2 - EDGE_IN
-- Sticks rarely report a full 1.0, least of all diagonally: from this tilt on
-- the stick counts as pushed all the way
local SATURATION = 0.8

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
    -- Halves the key belongs to: a key straddling the middle (Space) is in both
    b.inHalf = { left = x < MID_X - 1, right = x + w > MID_X + 1 }
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

    -- One cursor per half, with a line from the half's center, above the keys
    local over = CK.NewFrame("Frame", nil, area)
    over:SetAllPoints()
    over:SetFrameLevel(area:GetFrameLevel() + 30)
    self.over = over
    self.cursors = {}
    for side, half in pairs(HALVES) do
        local c = { side = side, homeX = half.cx }
        -- The line is optional: the keyboard works without it on a client lacking lines
        local line = over.CreateLine and over:CreateLine(nil, "OVERLAY")
        if line then
            line:SetThickness(2)
            line:SetColorTexture(K.C.gold[1], K.C.gold[2], K.C.gold[3], 0.55)
            c.line = line
        end
        c.hub = K.texture(over, "ck_hl_hover", "OVERLAY")
        c.hub:SetSize(12, 12)
        c.hub:SetPoint("CENTER", over, "TOPLEFT", half.cx, -CENTER_Y)
        c.hub:SetAlpha(0.6)
        c.dot = K.texture(over, "ck_hl", "OVERLAY", 1)
        c.dot:SetSize(16, 16)
        self.cursors[side] = c
    end
    self:Reset()
end

---------------------------------------------------------------------------
-- Cursors
---------------------------------------------------------------------------
-- Disc -> square (inverse elliptical grid mapping): lets the round stick
-- reach the corners of the rectangular half
local SQ2 = 2 * math.sqrt(2)
local function discToSquare(u, v)
    local u2, v2 = u * u, v * v
    local x = 0.5 * math.sqrt(math.max(0, 2 + u2 - v2 + SQ2 * u)) - 0.5 * math.sqrt(math.max(0, 2 + u2 - v2 - SQ2 * u))
    local y = 0.5 * math.sqrt(math.max(0, 2 - u2 + v2 + SQ2 * v)) - 0.5 * math.sqrt(math.max(0, 2 - u2 + v2 - SQ2 * v))
    return math.max(-1, math.min(1, x)), math.max(-1, math.min(1, y))
end
M.discToSquare = discToSquare

function M:MoveCursor(side, x, y)
    local c = self.cursors and self.cursors[side]
    if not c then return end
    local dead = CK.db.settings.deadzone
    local len = math.sqrt(x * x + y * y)
    if CK.db.settings.debug and len > (c.maxLen or 0) then
        c.maxLen = len
        CK:Print("%s stick x=%.2f y=%.2f len=%.2f (max so far)", side, x, y, len)
    end
    local u, v = 0, 0
    if len > dead then
        local scale = (math.min(len, SATURATION) - dead) / (SATURATION - dead) / len
        u, v = x * scale, y * scale
    end
    local sx, sy = discToSquare(u, v)
    c.cx, c.cy = c.homeX + sx * REACH_X, CENTER_Y - sy * REACH_Y
    self:Update()
end

function M:OnLeftStick(x, y) self:MoveCursor("left", x, y) end
function M:OnRightStick(x, y) self:MoveCursor("right", x, y) end

local function rectDistance(key, x, y)
    local dx = math.max(math.abs(x - key.cx) - key.w / 2, 0)
    local dy = math.max(math.abs(y - key.cy) - key.h / 2, 0)
    return math.sqrt(dx * dx + dy * dy), math.abs(x - key.cx) + math.abs(y - key.cy)
end

-- Nearest key of the cursor's half, with a magnet: the highlighted key only
-- changes when another one is clearly closer, so it does not flicker
function M:PickKey(set, c)
    local best, bestD, bestTie
    for _, key in ipairs(set.keys) do
        if key.inHalf[c.side] then
            local d, tie = rectDistance(key, c.cx, c.cy)
            if not best or d < bestD or (d == bestD and tie < bestTie) then
                best, bestD, bestTie = key, d, tie
            end
        end
    end
    local current = c.selected
    if current and current:GetParent() == set and current.inHalf[c.side] and best ~= current then
        local magnet = MAGNET_PX[CK.db.settings.magnet] or 8
        if rectDistance(current, c.cx, c.cy) <= bestD + magnet then return current end
    end
    return best
end

function M:ActiveSet()
    if CK.state.layer == "symbols" then return self.sets.symbols end
    return self.sets[CK.db.settings.kbLayout] or self.sets.azerty
end

function M:Reset()
    if not self.cursors then return end
    for _, c in pairs(self.cursors) do
        c.cx, c.cy, c.selected = c.homeX, CENTER_Y, nil
    end
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

-- LT / RT: the binding gives one press per pull of the trigger, so one letter
function CK:TypeLeft()
    if self:GetMethod() == M and M.cursors then M:Press(M.cursors.left.selected) end
end

function CK:TypeRight()
    if self:GetMethod() == M and M.cursors then M:Press(M.cursors.right.selected) end
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

    local left, right = self.cursors.left, self.cursors.right
    left.selected = self:PickKey(set, left)
    right.selected = self:PickKey(set, right)
    local shiftOn = state.shift or state.caps

    for _, key in ipairs(set.keys) do
        local selected = key == left.selected or key == right.selected
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

    local showLine = CK.db.settings.showLine
    for _, c in pairs(self.cursors) do
        c.dot:ClearAllPoints()
        c.dot:SetPoint("CENTER", self.over, "TOPLEFT", c.cx, -c.cy)
        if c.line then
            c.line:SetShown(showLine)
            c.line:SetStartPoint("TOPLEFT", self.over, c.homeX, -CENTER_Y)
            c.line:SetEndPoint("TOPLEFT", self.over, c.cx, -c.cy)
        end
        c.hub:SetShown(showLine)
    end
end
