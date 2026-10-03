local _, CK = ...
local L = CK.L

-- Configuration, Gamepad tab (2.0, Claude Design handoff, "Écran Gamepad"):
-- the controller drawn over an Xbox controller's silhouette, each button
-- with what it does in the layer shown (alone, LT, RT, LT + RT), in five
-- states: the game's function, a slot of the game's gamepad bar, yours
-- (added, or replacing the game's), free, unavailable. A on a button opens
-- the lists picker on the right. Under the controller: identify the back
-- paddles, place the bar, the Display options (a sub-screen), every
-- replaced button given back to the game.
local W = {}
CK.MapPage = W
CK.Config.pages.gamepad = W

local M, P, C = CK.Mapping, CK.Paddles, CK.Config
local K = CK.ConfigKit
local KC = K.C

local ZONE_W, PANEL_W, BODY_H = 480, 292, 424
local PAD_TOP, PAD_H = 40, 344
local SLOT, ICON, GLYPH = 44, 32, 20

-- Each button's centre on the silhouette, and the side of its glyph
local NODES = {
    { "LT", 40, 30 }, { "LB", 150, 30 }, { "RB", 320, 30 }, { "RT", 446, 30 },
    { "L3", 110, 100 }, { "SELECT", 206, 92 }, { "START", 274, 92 },
    { "Y", 380, 64 }, { "X", 328, 124 }, { "B", 432, 124 }, { "A", 380, 172 },
    { "UP", 182, 152 }, { "LEFT", 134, 200 }, { "RIGHT", 230, 200 }, { "DOWN", 182, 252 },
    { "R3", 312, 212 },
    { "L4", 34, 300 }, { "L5", 112, 300 }, { "R5", 376, 300 }, { "R4", 452, 300 },
}
-- The D-pad's four sit on the drawn cross: no glyph of their own; square,
-- like the game's gamepad bar draws them
local NO_GLYPH = { UP = true, DOWN = true, LEFT = true, RIGHT = true }
local SQUARE = NO_GLYPH
-- Select and Start are close: narrower names
local LABEL_W = { SELECT = 64, START = 64 }
local GLYPH_SIDE = {
    SELECT = "top", START = "top", Y = "top", B = "top", L4 = "top", L5 = "top", R4 = "top", R5 = "top",
    X = "right", A = "right", RIGHT = "right",
}
local POS = {}
for _, n in ipairs(NODES) do POS[n[1]] = n end

local LAYER_KEYS = { [""] = {}, LT = { "LT" }, RT = { "RT" }, LTRT = { "LT", "+", "RT" } }
local SLOT_KINDS = { spell = true, item = true, macro = true }

local function settings() return CK.db.settings end

local function keyText(key)
    return key and (GetBindingText and GetBindingText(key) or key) or ""
end

---------------------------------------------------------------------------
-- What a button is in a layer: { state = "native" | "slot" | "yours" |
-- "free" | "off", name, icon, empty, slot, action, replaced, rep, why }
---------------------------------------------------------------------------
function W:Cell(input, layer)
    -- The triggers: their bars' (alone), held in their own layers
    if input.layer then
        if layer == "" then
            local name, icon = M:NativeInfo(input, layer)
            return { state = "native", name = name, icon = icon }
        end
        return { state = "off", name = L.LBL_HELD, why = L.MAP_KEPT_TRIGGER }
    end
    -- LB / RB with a trigger: the game's class and pet actions
    if (input.id == "LB" or input.id == "RB") and layer ~= "" then
        return { state = "off", name = L.MAP_GAME, why = L.MAP_KEPT_CLASS }
    end
    local state = M:State(input, layer)
    -- A button of the game's, replaced
    local replaced = M:Replaceable(input, layer) and M:GetReplaced(input.id, layer)
    if replaced then
        local rep = M:NativeInfo(input, layer)
        local cell = { name = M:ActionName(replaced), icon = M:ActionIcon(replaced), action = replaced,
            replaced = true, rep = rep or L.MAP_GAME }
        if M:OwnKeys() then
            cell.state = "yours"
        else
            cell.state, cell.why = "off", L.MAP_REPLACED_INACTIVE
        end
        return cell
    end
    if state == "locked" then
        if input.paddle and not M:InputKey(input) then
            return { state = "off", name = L.LBL_NO_KEY, why = L.MAP_PADDLE_NO_KEY }
        end
        if input.paddle then
            -- A shared key a game function takes
            local base = M:SharedLayers(layer)[1]
            local shown = M:EffectiveAction(input, layer)
            return { state = "off", name = M:ActionName(shown) or L.MAP_GAME,
                why = format(L.MAP_SHARED_LOCKED, K.ComboMarkup(input.id, base, 14), M:ActionName(M:Get(input.id, base)) or "") }
        end
        return { state = "off", name = L.MAP_GAME, why = L.MAP_LOCKED }
    end
    if state == "slot" then
        local slot = M:NativeSlot(input, layer)
        local name, icon = M:NativeInfo(input, layer)
        local empty = not P.SlotTexture(slot)
        return { state = "slot", name = empty and L.LBL_EMPTY or name, icon = icon, empty = empty, slot = slot }
    end
    if state == "native" then
        local name, icon = M:NativeInfo(input, layer)
        return { state = "native", name = name or L.MAP_GAME, icon = icon }
    end
    -- Free: the player's own, if any
    local action = M:Get(input.id, layer)
    if not settings().modules.mapping then
        return { state = "off", name = action and M:ActionName(action) or L.MAP_FREE, why = L.MAP_MODULE_OFF, action = action }
    end
    -- A game function left on a layer sharing the paddle's key: a spell, an
    -- item or a macro can take its place
    if action and M:Inactive(input, layer) then
        return { state = "off", name = M:ActionName(action), why = L.MAP_SHARED_INACTIVE, action = action, pick = true }
    end
    if action then
        return { state = "yours", name = M:ActionName(action), icon = M:ActionIcon(action), action = action }
    end
    return { state = "free", name = L.MAP_FREE }
end

-- The layer on screen: the triggers held, else the one picked
function W:ViewLayer()
    return self.heldLayer ~= "" and self.heldLayer or self.layer or ""
end

function W:Focused()
    return M.BY_ID[self.node]
end

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
local function legendSwatch(parent, fill, ring, hatch)
    local s = CK.NewFrame("Frame", nil, parent)
    s:SetSize(12, 12)
    if hatch then
        local t = s:CreateTexture(nil, "ARTWORK")
        t:SetTexture(K.TEX .. "ck_hatch")
        t:SetAllPoints()
        t:SetAlpha(0.6)
        return s
    end
    local outer = s:CreateTexture(nil, "ARTWORK", nil, 0)
    outer:SetTexture(K.TEX .. "ck_dot")
    outer:SetAllPoints()
    outer:SetVertexColor(ring[1], ring[2], ring[3])
    local inner = s:CreateTexture(nil, "ARTWORK", nil, 1)
    inner:SetTexture(K.TEX .. "ck_dot")
    inner:SetSize(8, 8)
    inner:SetPoint("CENTER")
    local c = fill or KC.boxBg
    inner:SetVertexColor(c[1], c[2], c[3])
    if not fill then
        local plus = K.ChatText(s, 10, KC.dimGold)
        plus:SetPoint("CENTER", 0, 0)
        plus:SetText("+")
    end
    return s
end

-- The five states, at the bottom of the detail panel
local function buildLegend(detail)
    local g = CK.NewFrame("Frame", nil, detail)
    g:SetPoint("BOTTOMLEFT", 14, 14)
    g:SetPoint("BOTTOMRIGHT", -14, 14)
    g:SetHeight(64)
    local line = K.Solid(g, KC.line3, 1, "BORDER")
    line:SetPoint("TOPLEFT")
    line:SetPoint("TOPRIGHT")
    line:SetHeight(1)
    local items = {
        { L.TAG_GAME_FUNCTION, KC.legendGame, KC.legendRing },
        { L.TAG_GAME_SLOT, KC.legendSlot, KC.slot },
        { L.TAG_YOURS, KC.legendYours, KC.yours },
        { L.TAG_FREE, nil, KC.legendFree },
        { L.TAG_UNAVAILABLE, nil, nil, true },
    }
    local colW = (PANEL_W - 28 - 10) / 2
    for i, item in ipairs(items) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        local sw = legendSwatch(g, item[2], item[3], item[4])
        sw:SetPoint("TOPLEFT", col * (colW + 10), -10 - row * 20)
        local label = K.ChatText(g, 12, KC.help)
        label:SetPoint("LEFT", sw, "RIGHT", 6, 0)
        label:SetWidth(colW - 18)
        label:SetWordWrap(false)
        label:SetText(item[1])
    end
    g:Hide()
    detail.legend = g
end

function W:BuildNode(area, n)
    local id, x, y = n[1], n[2], n[3]
    local node = CK.NewFrame("Frame", nil, area)
    node:SetSize(SLOT, SLOT)
    node:SetPoint("CENTER", area, "TOPLEFT", x, -y)
    node.input = M.BY_ID[id]
    node.slot = K.Slot(node, SLOT, ICON, SQUARE[id])
    node.slot:SetAllPoints()
    -- Its glyph, beside it (just over the slot's edge)
    node.glyph = K.Glyph(node, GLYPH)
    node.glyph:SetFrameLevel(node.slot:GetFrameLevel() + 3)
    node.glyph.none = NO_GLYPH[id]
    local side = GLYPH_SIDE[id] or "left"
    if side == "top" then
        node.glyph:SetPoint("BOTTOM", node, "TOP", 0, -2)
    elseif side == "right" then
        node.glyph:SetPoint("LEFT", node, "RIGHT", -3, 0)
    else
        node.glyph:SetPoint("RIGHT", node, "LEFT", 3, 0)
    end
    -- What it does, under it
    node.label = K.Text(area, 12, KC.cream)
    node.label:SetPoint("TOP", node, "BOTTOM", 0, -2)
    node.label:SetWidth(LABEL_W[id] or 76)
    node.label:SetJustifyH("CENTER")
    if node.label.SetMaxLines then node.label:SetMaxLines(1) end
    node.slot:SetScript("OnClick", function(_, button)
        if W.wizard or P:IsCapturing() then return end
        C:Disarm()
        W.zone, W.node = "pad", id
        if button == "RightButton" then
            W:Clear()
        elseif W.assign then
            W:AssignWheel()
        else
            W:Choose()
        end
    end)
    node.slot:SetScript("OnEnter", function(self)
        local cell = node.cell
        if cell and cell.state == "slot" and not cell.empty and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetAction(cell.slot)
            GameTooltip:Show()
        end
    end)
    node.slot:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    return node
end

function W:Build(parent)
    local f = CK.NewFrame("Frame", nil, parent)
    f:SetAllPoints()
    f:Hide()
    self.frame = f

    -- Left: the layers, the controller, the actions
    local zone = CK.NewFrame("Frame", nil, f)
    zone:SetPoint("TOPLEFT")
    zone:SetSize(ZONE_W, BODY_H)
    f.zone = zone

    local layersRow = CK.NewFrame("Frame", nil, zone)
    layersRow:SetPoint("TOPLEFT")
    layersRow:SetSize(ZONE_W, 32)
    f.layers = {}
    for i, layer in ipairs(M.LAYERS) do
        local b = K.Button(layersRow, 15)
        b.layer = layer
        if layer == "" then
            b.label:SetText(L.MAP_ALONE)
        else
            b.glyphs = K.GlyphRow(b, 28)
            b.glyphs:SetFrameLevel(b:GetFrameLevel() + 2)
        end
        b.focusBox = K.Box(b, 4, 2, "OVERLAY")
        b.focusBox:SetPoints(b, -3)
        b.focusBox:SetColors(nil, nil, KC.focus, 1)
        b.focusBox:SetShown(false)
        b:SetScript("OnClick", function()
            if W.wizard or P:IsCapturing() then return end
            C:Disarm()
            W.layer, W.zone = layer, "layers"
            C:Render()
        end)
        f.layers[i] = b
    end
    K.LayoutRow(layersRow, f.layers, { 1, 1, 1, 1 }, 6)

    -- The controller's silhouette (Claude Design, drawn at 2x: 960 x 688 of 1024)
    local area = CK.NewFrame("Frame", nil, zone)
    area:SetPoint("TOPLEFT", 0, -PAD_TOP)
    area:SetSize(ZONE_W, PAD_H)
    f.area = area
    local pad = area:CreateTexture(nil, "BACKGROUND")
    pad:SetTexture(K.TEX .. "ck_pad")
    pad:SetTexCoord(0, 960 / 1024, 0, 688 / 1024)
    pad:SetAllPoints()
    local back = K.Text(area, 13, KC.rail)
    back:SetPoint("TOP", area, "TOPLEFT", 240, -316)
    back:SetWidth(120)
    back:SetJustifyH("CENTER")
    back:SetText(L.MAP_BACK_ROW)
    f.nodes = {}
    for _, n in ipairs(NODES) do f.nodes[n[1]] = self:BuildNode(area, n) end

    -- Under it: identify the paddles, place the bar, display, restore
    local actionsRow = CK.NewFrame("Frame", nil, zone)
    actionsRow:SetPoint("TOPLEFT", 0, -(PAD_TOP + PAD_H + 8))
    actionsRow:SetSize(ZONE_W, 32)
    f.actions = {}
    for i = 1, 4 do
        local b = K.Button(actionsRow, 13)
        b:SetScript("OnClick", function()
            if W.wizard or P:IsCapturing() then return end
            if i ~= 4 then C:Disarm() end
            W.zone, W.act = "actions", i
            W:Act(i)
        end)
        f.actions[i] = b
    end
    K.LayoutRow(actionsRow, f.actions, { 1.2, 1, 0.9, 1 }, 6)

    -- Right: the detail panel, the picker or the paddles wizard in its place
    self.detail = K.Detail(f, PANEL_W, 26)
    self.detail:SetPoint("TOPRIGHT")
    self.detail:SetHeight(BODY_H)
    buildLegend(self.detail)
    self.picker = K.Picker(f, PANEL_W)
    self.picker:SetPoint("TOPRIGHT")
    self.picker:SetHeight(BODY_H)
    self:BuildWizard(f)

    -- Display, a sub-screen of its own
    self.display:Build(parent)
end

-- Identify the back paddles: one step after the other, in the right panel
function W:BuildWizard(f)
    local w = CK.NewFrame("Frame", nil, f)
    w:SetPoint("TOPRIGHT")
    w:SetSize(PANEL_W, BODY_H)
    w.box = K.Box(w, 4, 1, "BACKGROUND", 1)
    w.box:SetPoints(w)
    w.box:SetColors(KC.black, 0.72, KC.line1, 1)
    w.title = K.Text(w, 19, KC.title)
    w.title:SetPoint("TOPLEFT", 16, -16)
    w.title:SetWidth(PANEL_W - 32)
    w.title:SetWordWrap(true)
    w.stepsRow = CK.NewFrame("Frame", nil, w)
    w.stepsRow:SetPoint("TOPLEFT", w.title, "BOTTOMLEFT", 0, -14)
    w.stepsRow:SetSize(PANEL_W - 32, 30)
    w.steps = {}
    for i = 1, #P.ORDER do
        local s = CK.NewFrame("Frame", nil, w.stepsRow)
        s.box = K.Box(s, 4, 1, "ARTWORK")
        s.box:SetPoints(s)
        s.label = K.ChatText(s, 13, KC.cream)
        s.label:SetPoint("CENTER", 0, 0)
        w.steps[i] = s
    end
    K.LayoutRow(w.stepsRow, w.steps, { 1, 1, 1, 1 }, 8)
    w.text = K.Text(w, 22, KC.focusText)
    w.text:SetPoint("TOPLEFT", w.stepsRow, "BOTTOMLEFT", 0, -14)
    w.text:SetWidth(PANEL_W - 32)
    w.text:SetWordWrap(true)
    w.text:SetSpacing(8)
    w.hint = K.ChatText(w, 14, KC.cream2)
    w.hint:SetPoint("TOPLEFT", w.text, "BOTTOMLEFT", 0, -14)
    w.hint:SetWidth(PANEL_W - 32)
    w.hint:SetWordWrap(true)
    w.hint:SetSpacing(6)
    w:Hide()
    self.wizardFrame = w
end

local slotEvents = CreateFrame("Frame")
slotEvents:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
slotEvents:SetScript("OnEvent", function() W.slotsChanged = true end)

-- Opened on A, alone; back from placing the bar (resume), as it was
function W:Show(resume)
    if not resume then
        self.zone, self.node, self.layer, self.act = "pad", "A", "", 1
        self.sub, self.wizard, self.assign = nil, nil, nil
        if P:IsCapturing() then P:StopCapture(nil) end
        self.picker:Close()
    end
    self.heldLayer = ""
    if self.sub == "display" then
        self.frame:Hide()
        self.display:Show()
    else
        self.display:Hide()
        self.frame:Show()
    end
end

function W:Hide()
    self.wizard = nil
    if P:IsCapturing() then P:StopCapture(nil) end
    self.picker:Close()
    self.display:Hide()
    self.frame:Hide()
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------
local TAGS = {
    native = { "TAG_GAME_FUNCTION", "gameFn" }, slot = { "TAG_GAME_SLOT", "slot" }, yours = { "TAG_YOURS", "yours" },
    free = { "TAG_FREE", "grey" }, off = { "TAG_UNAVAILABLE", "off" },
}

function W:RenderNode(node, layer)
    local input = node.input
    local cell = self:Cell(input, layer)
    node.cell = cell
    local st = cell.state
    local focus = self.zone == "pad" and self.node == input.id
    if self.wizard then focus = input.id == P.ORDER[self.wizard.step] end
    local look = { glow = focus }
    if st == "native" then
        -- No picture of its own: the button's glyph, if it has one
        local glyph = K.INPUT_GLYPH[input.id] or input.id
        look.icon = cell.icon or (K.IMAGE[glyph] and { glyph = glyph }) or nil
        look.discColor = KC.iconBg
    elseif st == "slot" then
        look.ring = KC.slot
        if cell.empty then
            look.plus = true
        else
            look.icon, look.discColor = cell.icon, KC.iconBg
        end
    elseif st == "yours" then
        look.icon, look.discColor = cell.icon, KC.iconBg
        look.ring, look.ringOut, look.mark = KC.yours, true, true
    elseif st == "free" then
        look.plus = true
    else
        look.hatch = true
    end
    node.slot:SetLook(look)
    node:SetAlpha(st == "off" and 0.45 or 1)
    node.label:SetAlpha(st == "off" and 0.45 or 1)
    if node.glyph.none then
        node.glyph:Hide()
    else
        node.glyph:Set(K.INPUT_GLYPH[input.id] or input.id)
    end
    node.label:SetText(cell.name or "")
    local color = focus and KC.focusText or ((st == "free" or cell.empty) and KC.grey)
        or (st == "native" and KC.help) or KC.cream
    node.label:SetTextColor(color[1], color[2], color[3])
end

function W:ActionLabels()
    local n = M:ReplacedCount()
    return { L.LBL_IDENTIFY, L.LBL_PLACE_BAR, L.SEC_DISPLAY,
        C:IsArmed("restore") and L.LBL_PRESS_AGAIN or (n > 0 and format(L.LBL_RESTORE_N, n) or L.LBL_RESTORE) }
end

function W:Render()
    if self.sub == "display" then
        self.frame:Hide()
        self.display.frame:Show()
        return self.display:Render()
    end
    self.display.frame:Hide()
    self.frame:Show()
    local f = self.frame
    local layer = self:ViewLayer()
    for _, b in ipairs(f.layers) do
        local active = b.layer == layer
        b:SetState({ active = active })
        b.focusBox:SetShown(self.zone == "layers" and active and not self.picker:IsOpen())
        if b.glyphs then
            b.glyphs:Set(LAYER_KEYS[b.layer])
            b.glyphs:ClearAllPoints()
            b.glyphs:SetPoint("CENTER", b, "CENTER", 0, 0)
        end
    end
    for _, node in pairs(f.nodes) do self:RenderNode(node, layer) end
    local labels = self:ActionLabels()
    local none = M:ReplacedCount() == 0
    for i, b in ipairs(f.actions) do
        b.label:SetText(labels[i])
        b:SetState({ focus = self.zone == "actions" and self.act == i and not self.picker:IsOpen(),
            armed = i == 4 and C:IsArmed("restore"), disabled = i == 4 and none })
    end
    -- The right panel
    local w = self.wizardFrame
    w:SetShown(self.wizard ~= nil)
    if self.wizard then
        self.detail:Hide()
        self.picker:Hide()
        self:RenderWizard()
    elseif self.picker:IsOpen() then
        self.detail:Hide()
        self.picker:Show()
        self.picker:Render()
    else
        self.detail:Show()
        self.detail:Set(self:Detail(layer))
    end
end

function W:RenderWizard()
    local w, step = self.wizardFrame, self.wizard.step
    w.title:SetText(L.MAP_IDENTIFY)
    for i, s in ipairs(w.steps) do
        local done, now = i < step, i == step
        s.box:SetColors(done and KC.doneBg or (now and KC.nowBg or KC.controlBg), 1,
            done and KC.done or (now and KC.focus or KC.line2), 1)
        s.label:SetText(P.ORDER[i])
        local c = (done or now) and KC.focusText or KC.eventOff
        s.label:SetTextColor(c[1], c[2], c[3])
    end
    w.text:SetText(format(L.MAP_WIZARD, P.ORDER[step] or ""))
    w.hint:SetText(L.MAP_IDENTIFY_HINT)
end

function W:Detail(layer)
    if self.zone == "layers" then return { title = L.LBL_LAYERS, body = L.TIP_LAYERS } end
    if self.zone == "actions" then
        local n = M:ReplacedCount()
        local list = {
            { title = L.MAP_IDENTIFY, body = L.MAP_IDENTIFY_HINT },
            { title = L.MAP_PLACE, body = L.MAP_PLACE_HINT },
            { title = L.SEC_DISPLAY, body = L.TIP_ACT_DISPLAY },
            { title = n > 0 and format(L.MAP_RESTORE, n) or L.MAP_RESTORE_NONE, body = L.TIP_RESTORE },
        }
        return list[self.act]
    end
    local input = self:Focused()
    if not input then return {} end
    local cell = self:Cell(input, layer)
    local st = cell.state
    local tag = TAGS[st]
    local title = cell.name
    if st == "free" then title = L.MAP_FREE end
    if st == "off" then title = L.TAG_UNAVAILABLE end
    if st == "slot" and cell.empty then title = L.LBL_EMPTY_SLOT end
    local body
    local replaceable = M:Replaceable(input, layer)
    local replaceHint = replaceable and (M:CanOwnKeys() and L.MAP_REPLACE_HINT or L.MAP_REPLACE_NO_MOD)
    if st == "native" then
        body = replaceHint or L.MAP_NATIVE_HINT
    elseif st == "slot" then
        local kept = M:SlotKept(cell.slot)
        body = kept and (kept .. (replaceHint and ("\n\n" .. replaceHint) or ""))
            or (replaceable and M:CanOwnKeys() and L.MAP_SLOT_REPLACE_HINT) or replaceHint or L.MAP_SLOT_HINT
    elseif st == "yours" then
        body = cell.replaced and format(L.MAP_REPLACES, cell.rep) or L.MAP_ASSIGNED_HINT
    elseif st == "free" then
        body = L.MAP_FREE_HINT
    else
        body = cell.why
    end
    -- A shared key (the trigger no modifier): spells, items and macros
    if input.paddle and (st == "free" or st == "yours") and M:PaddleTabs(input, layer) == M.SLOT_TABS then
        body = body .. "\n\n" .. L.MAP_SHARED_HINT
    end
    local extra
    if input.paddle then
        if P:IsCapturing(input.id) then
            extra = L.MAP_PADDLE_PRESS
        elseif M:InputKey(input) then
            extra = format(L.MAP_PADDLE_KEY, keyText(M:InputKey(input)))
        end
    end
    return { combo = K.ComboKeys(input.id, layer), title = title, tag = L[tag[1]], tagColor = KC[tag[2]],
        body = body, extra = extra, legend = true }
end

function W:Crumb()
    if self.sub == "display" then return self.display:Crumb() end
    if self.assign then return format(L.CRUMB_ASSIGN, CK.MyWheels:Name(self.assign) or "") end
    local layer = self:ViewLayer()
    local name = layer == "" and L.MAP_ALONE
        or format(L.CRUMB_LAYER, (K.ComboMarkup("", layer, 14):gsub(" %+ $", "")))
    return L.TAB_GAMEPAD .. " › " .. name
end

function W:Help()
    if self.sub == "display" then return self.display:Help() end
    local H = K.H
    if self.wizard then return { H({ "X" }, L.V_SKIP, "X"), H({ "B" }, L.V_CANCEL, "B") } end
    if P:IsCapturing() then return { H({ "B" }, L.V_CANCEL, "B") } end
    if self.picker:IsOpen() then return self.picker:Hints() end
    local tab = H({ "LB", "RB" }, L.V_TAB, "RB")
    if self.assign then
        return { H({ "DPAD" }, L.V_MOVE), H({ "A" }, L.V_ASSIGN_HERE, "A"), H({ "B" }, L.V_CANCEL, "B") }
    end
    if self.zone == "layers" then
        return { H({ "DPAD_LR" }, L.V_LAYER, "RIGHT"), H({ "DPAD" }, L.V_BUTTONS, "DOWN"), tab, H({ "B" }, L.V_CLOSE, "B") }
    end
    if self.zone == "actions" then
        return { H({ "DPAD" }, L.V_MOVE), H({ "A" }, L.V_SELECT, "A"), tab, H({ "B" }, L.V_BACK, "B") }
    end
    local input = self:Focused()
    local cell = input and self:Cell(input, self:ViewLayer()) or { state = "off" }
    local hints = { H({ "DPAD" }, L.V_MOVE) }
    if cell.state ~= "off" or cell.pick then
        hints[#hints + 1] = H({ "A" }, cell.state == "free" and L.V_ASSIGN or L.V_CHANGE, "A")
    end
    if cell.replaced then
        hints[#hints + 1] = H({ "X" }, L.V_GIVE_BACK, "X")
    elseif cell.state == "slot" and not cell.empty then
        hints[#hints + 1] = H({ "X" }, L.V_EMPTY, "X")
    elseif cell.action then
        hints[#hints + 1] = H({ "X" }, L.V_REMOVE, "X")
    end
    if input and input.paddle then hints[#hints + 1] = H({ "Y" }, L.V_KEY, "Y") end
    hints[#hints + 1] = tab
    hints[#hints + 1] = H({ "B" }, L.V_CLOSE, "B")
    return hints
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------
-- The nearest button that way: the main axis counts, the gap across it
-- twice (a cone of about 65 degrees)
function W:Nearest(from, dir)
    local f = POS[from]
    if not f then return end
    local best, bestScore
    for _, n in ipairs(NODES) do
        if n[1] ~= from then
            local dx, dy = n[2] - f[2], n[3] - f[3]
            local main, cross
            if dir == "UP" then
                main, cross = -dy, dx
            elseif dir == "DOWN" then
                main, cross = dy, dx
            elseif dir == "LEFT" then
                main, cross = -dx, dy
            else
                main, cross = dx, dy
            end
            if main > 6 and math.abs(cross) <= main * 2.2 then
                local score = main + math.abs(cross) * 2
                if not bestScore or score < bestScore then best, bestScore = n[1], score end
            end
        end
    end
    return best
end

-- What a choice does: a spell, an item or a macro goes in a slot of the
-- game's bar (like the game's own editor); anything else replaces the
-- game's button; a free button takes it
function W:Put(input, layer, action)
    local state = M:State(input, layer)
    local kind = action:match("^(%a+):")
    if state == "slot" then
        local slot = M:NativeSlot(input, layer)
        if SLOT_KINDS[kind] and not M:SlotKept(slot) then
            if not M:PlaceInSlot(slot, action) then return false end
            if M:GetReplaced(input.id, layer) then M:SetReplaced(input.id, layer, nil) end
            return true
        end
    end
    if state == "slot" or state == "native" then
        if not (M:Replaceable(input, layer) and M:CanOwnKeys()) then return false end
        M:SetReplaced(input.id, layer, action)
        return true
    end
    if state == "free" then
        M:Set(input.id, layer, action)
        return true
    end
    return false
end

function W:Choose()
    local input = self:Focused()
    if not input then return end
    local layer = self:ViewLayer()
    local cell = self:Cell(input, layer)
    if cell.state == "off" and not cell.pick then return end
    local state = M:State(input, layer)
    local replace = M:Replaceable(input, layer) and M:CanOwnKeys()
    local tabs, forSlot, slot
    if state == "slot" then
        slot = M:NativeSlot(input, layer)
        local kept = M:SlotKept(slot)
        if kept and not replace then
            if UIErrorsFrame then UIErrorsFrame:AddMessage(kept, 1, 0.1, 0.1) end
            return
        end
        tabs, forSlot = replace and M.TABS or M.SLOT_TABS, not replace
    elseif state == "free" then
        tabs = input.paddle and M:PaddleTabs(input, layer) or M.TABS
    elseif replace then
        tabs = M.TABS
    else
        -- The game's, and no free modifier to replace it
        if UIErrorsFrame and M:Replaceable(input, layer) then UIErrorsFrame:AddMessage(L.MAP_REPLACE_NO_MOD, 1, 0.1, 0.1) end
        return
    end
    local current = (replace and M:GetReplaced(input.id, layer)) or (slot and M:SlotAction(slot)) or M:Get(input.id, layer)
    local lists = {}
    for _, tab in ipairs(tabs) do
        lists[#lists + 1] = { key = tab, label = L["MAP_TAB_" .. tab:upper()], entries = function() return M:Catalog(tab, forSlot) end }
    end
    local name = cell.name or L.MAP_FREE
    self.picker:Open({
        kicker = L.KICK_ASSIGN_TO,
        title = function() return K.ComboMarkup(input.id, layer, 16) .. " · " .. name end,
        lists = lists, current = current, rows = 10,
        onChoose = function(e)
            self.picker:Close()
            if self:Put(input, layer, e.action) then
                C:Toast(format(L.TOAST_PAIR, K.ComboMarkup(input.id, layer, 14), e.name or ""))
            end
            C:Render()
        end,
        onBack = function()
            self.picker:Close()
            C:Render()
        end,
    })
    C:Render()
    if UIFrameFadeIn then UIFrameFadeIn(self.picker, 0.15, 0, 1) end
end

-- X: the button given back to the game, the slot emptied, or ours removed
function W:Clear()
    local input = self:Focused()
    if not input or CK:BlockedByCombat() then return end
    local layer = self:ViewLayer()
    local cell = self:Cell(input, layer)
    if cell.replaced then
        M:SetReplaced(input.id, layer, nil)
        C:Toast(L.TOAST_GIVEN_BACK)
    elseif cell.state == "slot" and not cell.empty then
        local kept = M:SlotKept(cell.slot)
        M:ClearSlot(cell.slot)
        if not kept then C:Toast(L.TOAST_SLOT_EMPTIED) end
    elseif cell.action then
        M:Set(input.id, layer, nil)
        C:Toast(L.TOAST_FN_REMOVED)
    end
    C:Render()
end

-- Y on a back paddle: learn its key again
function W:LearnKey()
    local input = self:Focused()
    if not (input and input.paddle) then return end
    P:Capture(input.id, function(key)
        if key then C:Toast(format(L.TOAST_PAIR, input.id, keyText(key))) end
        if C:IsOpen() then C:Render() end
    end)
    C:Render()
end

-- Identify the back paddles: each one pressed in turn (X skips one)
function W:Identify()
    self.picker:Close()
    self.wizard = { step = 1 }
    self:WizardStep()
end

function W:WizardStep()
    local wizard = self.wizard
    if not wizard then return end
    local id = P.ORDER[wizard.step]
    if not id then
        self.wizard = nil
        C:Toast(L.MAP_WIZARD_DONE)
        C:Render()
        return
    end
    self.node = id
    P:Capture(id, function(key)
        if W.wizard ~= wizard then return end
        if key then C:Toast(format(L.TOAST_PAIR, id, keyText(key))) end
        wizard.step = wizard.step + 1
        W:WizardStep()
    end)
    C:Render()
end

function W:Act(i)
    if i == 1 then
        self:Identify()
    elseif i == 2 then
        self.picker:Close()
        C:BeginPlacement()
        P:StartPlacement()
    elseif i == 3 then
        self:OpenDisplay()
    elseif i == 4 then
        if M:ReplacedCount() == 0 or CK:BlockedByCombat() then return end
        if C:IsArmed("restore") then
            C:Disarm()
            M:RestoreGameButtons()
            C:Toast(L.TOAST_RESTORED)
        else
            C:Arm("restore")
        end
        C:Render()
        if C:IsArmed("restore") and UIFrameFadeIn then UIFrameFadeIn(self.frame.actions[4], 0.15, 0.3, 1) end
    end
end

-- From a wheel's editor: the next button chosen takes the wheel
function W:StartAssign(id)
    C:SetTab("gamepad")
    self.assign = id
    self.zone = "pad"
    C:Render()
end

function W:AssignWheel()
    local input = self:Focused()
    local id = self.assign
    if not (input and id) then return end
    local layer = self:ViewLayer()
    local cell = self:Cell(input, layer)
    if cell.state == "off" and not cell.pick then
        if cell.why and UIErrorsFrame then UIErrorsFrame:AddMessage(cell.why, 1, 0.1, 0.1) end
        return
    end
    if self:Put(input, layer, "wheel:" .. id) then
        self.assign = nil
        C:Toast(format(L.TOAST_ON, CK.MyWheels:Name(id) or "", K.ComboMarkup(input.id, layer, 14)))
    elseif UIErrorsFrame then
        UIErrorsFrame:AddMessage(M:Enabled() and L.MAP_REPLACE_NO_MOD or L.MAP_MODULE_OFF, 1, 0.1, 0.1)
    end
    C:Render()
end

function W:OpenDisplay()
    self.picker:Close()
    self.sub = "display"
    self.frame:Hide()
    self.display:Show()
    C:Render()
end

function W:CloseDisplay()
    self.sub = nil
    self.display:Hide()
    self.zone, self.act = "actions", 3
    C:Render()
end

---------------------------------------------------------------------------
-- The pad (the panel handles LB / RB and B when we don't)
---------------------------------------------------------------------------
local DIRS = { UP = true, DOWN = true, LEFT = true, RIGHT = true }

function W:Press(name)
    if self.sub == "display" then return self.display:Press(name) end
    -- Identifying the paddles: X skips one, B stops
    if self.wizard then
        if name == "X" then
            P:StopCapture(nil)
        elseif name == "B" then
            self.wizard = nil
            P:StopCapture(nil)
            C:Render()
        end
        return true
    end
    -- Learning one paddle's key: B cancels
    if P:IsCapturing() then
        if name == "B" then P:StopCapture(nil) end
        C:Render()
        return true
    end
    if self.picker:IsOpen() then
        self.picker:Press(name)
        C:Render()
        return true
    end
    if name == "LB" or name == "RB" then return false end
    if self.zone == "layers" then
        if name == "LEFT" or name == "RIGHT" then
            local index = 1
            for i, layer in ipairs(M.LAYERS) do
                if layer == self.layer then index = i end
            end
            index = math.max(1, math.min(#M.LAYERS, index + (name == "LEFT" and -1 or 1)))
            self.layer = M.LAYERS[index]
        elseif name == "DOWN" or name == "A" then
            self.zone = "pad"
        elseif name == "B" then
            if self.assign then
                self.assign = nil
            else
                return false
            end
        end
        C:Render()
        return true
    end
    if self.zone == "actions" then
        if name == "LEFT" or name == "RIGHT" then
            self.act = math.max(1, math.min(4, self.act + (name == "LEFT" and -1 or 1)))
        elseif name == "UP" or name == "B" then
            self.zone = "pad"
        elseif name == "A" then
            self:Act(self.act)
            return true
        end
        C:Render()
        return true
    end
    if DIRS[name] then
        local to = self:Nearest(self.node, name)
        if to then
            self.node = to
        elseif name == "UP" then
            self.zone = "layers"
        elseif name == "DOWN" and not self.assign then
            self.zone = "actions"
        end
        C:Render()
        return true
    end
    if self.assign then
        if name == "A" then
            self:AssignWheel()
        elseif name == "B" then
            self.assign = nil
            C:Render()
        end
        return true
    end
    if name == "A" then
        self:Choose()
    elseif name == "X" then
        self:Clear()
    elseif name == "Y" then
        self:LearnKey()
    elseif name == "B" then
        return false
    end
    return true
end

function W:OnUpdate()
    if self.sub == "display" then return end
    -- A slot changed (placed from here, or by the game): drawn again
    if self.slotsChanged then
        self.slotsChanged = false
        C:Render()
    end
    -- Holding LT / RT shows their layer
    local held = P.HeldLayer()
    if held ~= self.heldLayer then
        self.heldLayer = held
        C:Render()
    end
end

---------------------------------------------------------------------------
-- Display: what shows next to the game's gamepad bar, RT as a modifier
---------------------------------------------------------------------------
local function displayRows(b)
    local s = settings()
    local f = s.features
    b.header(L.HDR_NEXT_TO_BAR)
    b.check({ id = "d_extra", label = L.LBL_EXTRA_BUTTONS, tip = L.FEAT_EXTRA_DISPLAY,
        get = function() return f.extraDisplay end,
        set = function(v)
            f.extraDisplay = v
            P:Apply()
        end })
    b.check({ id = "d_sticks", label = L.LBL_L3_R3, indent = true, disabled = not f.extraDisplay, tip = L.FEAT_SHOW_STICKS,
        get = function() return f.showSticks end,
        set = function(v)
            f.showSticks = v
            P:Apply()
        end })
    b.choice({ id = "d_badge", label = L.LBL_BUTTON_NAMES, indent = true, disabled = not f.extraDisplay, tip = L.OPT_BADGE,
        text = function() return L["BADGE_" .. (s.badgePlace or "outer"):upper()] end,
        step = function(d)
            local list, index = P.BADGE_PLACES, 1
            for i, key in ipairs(list) do
                if key == s.badgePlace then index = i end
            end
            s.badgePlace = list[(index - 1 + d) % #list + 1]
            P:Apply()
        end })
    if M:CanBeModifier("PADRTRIGGER") then
        b.header(L.HDR_LAYERS)
        b.check({ id = "d_rt", label = L.LBL_RT_MODIFIER, tip = L.FEAT_RT_MODIFIER_TIP,
            get = function() return M:TriggerModifier("PADRTRIGGER") ~= nil end,
            set = function(v) M:SetTriggerModifier("PADRTRIGGER", v) end })
    end
end

W.display = C.NewRailPage({
    key = "gpdisplay", crumb = L.TAB_GAMEPAD,
    onBack = function() W:CloseDisplay() end,
    sections = { { key = "display", label = L.SEC_DISPLAY, tip = L.TIP_SEC_DISPLAY, rows = displayRows } },
})
