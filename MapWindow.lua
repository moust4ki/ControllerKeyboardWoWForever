local _, CK = ...
local L = CK.L

-- Configuration, Gamepad tab: the whole controller in four trigger layers.
-- The game's own buttons are shown with what they do (read only, with their
-- icon); the free ones and the extra buttons get a game function, a spell, an
-- item, a macro or a gamepad bar button from the list on the right. Below:
-- identify the back paddles, place the extra buttons on the HUD.
local W = {}
CK.MapPage = W
CK.Config.pages.gamepad = W

local M = CK.Mapping
local P = CK.Paddles
local kit

local SLOT = 40
local ROWS = 14
local ROW_H = 24

local GLYPH = {
    LT = "LT", RT = "RT", LB = "LB", RB = "RB", A = "A", B = "B", X = "X", Y = "Y",
    UP = "DPAD_UP", DOWN = "DPAD_DOWN", LEFT = "DPAD_LEFT", RIGHT = "DPAD_RIGHT",
    L3 = "LS", R3 = "RS",
}

local function inputLabel(input)
    local glyph = GLYPH[input.id]
    if glyph then return CK:GlyphMarkup(glyph, 16) end
    if input.id == "START" then return "Start" end
    if input.id == "SELECT" then return "Select" end
    return input.id
end

-- "LT + A"
local function comboLabel(input, layer)
    if layer == "" then return inputLabel(input) end
    return P:LayerLabel(layer, 16) .. " + " .. inputLabel(input)
end

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
function W:BuildSlot(area, input)
    local b = P:CreateSlot(area, SLOT)
    b.input = input
    b:SetPoint("CENTER", area, "TOPLEFT", input.x, -input.y)
    b.plus = b.over:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    b.plus:SetPoint("CENTER", 0, 1)
    b.plus:SetText("+")
    b.select = b.over:CreateTexture(nil, "OVERLAY")
    b.select:SetPoint("TOPLEFT", -5, 5)
    b.select:SetPoint("BOTTOMRIGHT", 5, -5)
    P.atlasOr(b.select, "gamepad-actionbar-circleslot-border-selected", "Interface\\Minimap\\MiniMap-TrackingBorder")
    b.select:SetVertexColor(1, 0.85, 0.3)
    b.select:Hide()
    -- What it does, under the inputs outside the D-pad and face diamonds
    -- (those show their icon; details on the right and in the tooltip)
    b.name = kit.text(area, 10)
    b.name:SetPoint("TOP", b, "BOTTOM", 0, -2)
    b.name:SetWidth(72)
    b.name:SetWordWrap(true)
    if b.name.SetMaxLines then b.name:SetMaxLines(2) end
    b.name:SetShown(not input.bar)
    b.key = kit.text(b.over, 11)
    b.key:SetPoint("BOTTOM", b, "TOP", 0, 1)
    b.key:SetText(inputLabel(input))
    b:EnableMouse(true)
    b:SetScript("OnEnter", function(self)
        W:Select(self.input.id)
        local layer = W:ViewLayer()
        local native = M:NativeBarButton(self.input, layer)
        local slot = native and native.action
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if slot and P.SlotTexture(slot) then
            GameTooltip:SetAction(slot)
        else
            GameTooltip:SetText(comboLabel(self.input, layer), 1, 1, 1)
            GameTooltip:AddLine(W:SlotText(self.input, layer), 1, 0.82, 0, true)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnMouseUp", function(self, button)
        W:Select(self.input.id)
        if button == "RightButton" then W:Clear() else W:Choose() end
    end)
    return b
end

function W:Build(parent)
    kit = CK.UIKit
    local f = CK.NewFrame("Frame", nil, parent)
    f:SetAllPoints()
    f:Hide()
    self.frame = f

    -- The controller
    local area = CK.NewFrame("Frame", nil, f)
    -- Below the layer tabs: the LB / RB labels never meet them
    area:SetPoint("TOPLEFT", 0, -30)
    area:SetSize(470, 450)
    f.area = area
    -- Layer tabs, for the mouse (on the pad: hold LT / RT)
    f.layerTabs = {}
    for i, layer in ipairs(M.LAYERS) do
        local t = kit.buildButton(f, P:LayerLabel(layer, 14), function() W:SetLayer(layer) end)
        t:SetSize(70, 22)
        t:SetPoint("TOPLEFT", f, "TOPLEFT", 86 + (i - 1) * 76, 0)
        t.layer = layer
        f.layerTabs[i] = t
    end
    local back = kit.text(area, 11)
    back:SetPoint("TOP", area, "TOPLEFT", 235, -336)
    back:SetTextColor(unpack(kit.C.sugg))
    back:SetText(L.MAP_BACK_ROW)
    f.slots = {}
    for _, input in ipairs(M.INPUTS) do f.slots[input.id] = self:BuildSlot(area, input) end

    -- Below: identify the paddles, place the extra buttons
    f.actions = {}
    for i, action in ipairs({ { "Identify", L.MAP_IDENTIFY }, { "Place", L.MAP_PLACE } }) do
        local b = kit.buildButton(f, action[2], function()
            W.focusAction = i
            W[action[1]](W)
        end)
        b:SetSize(210, 26)
        b:SetPoint("TOPLEFT", area, "TOPLEFT", 20 + (i - 1) * 222, -422)
        f.actions[i] = b
    end

    -- Right panel: details, then the list of functions
    local side = CK.NewFrame("Frame", nil, f)
    side:SetPoint("TOPLEFT", 480, -30)
    side:SetSize(282, 450)
    kit.nineSlice(side, "ck_bar", 256, 64, 8, 8, "BORDER")
    f.side = side
    side.title = kit.text(side, 14)
    side.title:SetPoint("TOPLEFT", 12, -10)
    side.title:SetTextColor(unpack(kit.C.gold))
    side.status = kit.text(side, 11)
    side.status:SetPoint("TOPLEFT", 12, -32)
    side.status:SetWidth(258)
    side.status:SetJustifyH("LEFT")
    side.status:SetWordWrap(true)

    side.ptabs = {}
    for i, tab in ipairs(M.TABS) do
        local t = kit.buildButton(side, L["MAP_TAB_" .. tab:upper()], function() W:SetTab(i) end)
        t:SetSize(52, 20)
        t:SetPoint("TOPLEFT", 8 + (i - 1) * 54, -70)
        side.ptabs[i] = t
    end
    side.rows = {}
    for i = 1, ROWS do
        local r = CK.NewFrame("Button", nil, side)
        r:SetSize(266, ROW_H - 2)
        r:SetPoint("TOPLEFT", 8, -96 - (i - 1) * ROW_H)
        r.select = kit.nineSlice(r, "ck_select", 128, 32, 10, 10, "ARTWORK")
        r.icon = r:CreateTexture(nil, "ARTWORK", nil, 1)
        r.icon:SetSize(18, 18)
        r.icon:SetPoint("LEFT", 4, 0)
        r.label = kit.text(r, 11)
        r.label:SetJustifyH("LEFT")
        r.label:SetWordWrap(false)
        r:SetScript("OnClick", function(self)
            if self.index then
                W.picker.index = self.index
                W:Assign()
            end
        end)
        r:SetScript("OnEnter", function(self)
            if self.index and W.picker.index ~= self.index then
                W.picker.index = self.index
                CK.Config:Render()
            end
        end)
        side.rows[i] = r
    end
    side:EnableMouseWheel(true)
    side:SetScript("OnMouseWheel", function(_, delta) if W.picker then W:MoveInList(-delta * 3) end end)
end

local slotEvents = CreateFrame("Frame")
slotEvents:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
slotEvents:SetScript("OnEvent", function() W.slotsChanged = true end)

function W:Show()
    -- Snapshot of what the game binds (taken by the panel when it opened)
    self.selected = self.selected or "L4"
    self.layer = self.layer or ""
    self.heldLayer = ""
    self.picker = nil
    self.focusAction = nil
    self.focusLayers = false
    self.frame:Show()
end

function W:Hide()
    self.wizard = nil
    self.picker = nil
    self.frame:Hide()
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
-- The layer on screen: the triggers held, else the tab picked
function W:ViewLayer()
    return self.heldLayer ~= "" and self.heldLayer or self.layer or ""
end

function W:SetLayer(layer)
    self.layer = layer
    CK.Config:Render()
end

function W:Select(id)
    if self.picker or self.wizard or self.selected == id then return end
    self.selected = id
    self.focusAction = nil
    CK.Config:Render()
end

function W:SelectedInput()
    return M.BY_ID[self.selected]
end

-- What an input does in a layer, as text
function W:SlotText(input, layer)
    local state = M:State(input, layer)
    -- A paddle's shared key, taken by a game function
    if state == "locked" and input.paddle then return M:ActionName(M:EffectiveAction(input, layer)) or L.MAP_LOCKED end
    -- No layer of its own: the game gets the button as without the trigger
    if state == "locked" then return M:NativeInfo(input, "") or L.MAP_LOCKED end
    if state == "native" then return M:NativeInfo(input, layer) or L.MAP_GAME end
    local action = M:Get(input.id, layer)
    return action and M:ActionName(action) or L.MAP_FREE
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------
local GREY, GREEN, GOLD = { 0.62, 0.6, 0.55 }, { 0.55, 0.9, 0.45 }, { 1, 0.82, 0 }

function W:RenderSlot(b, layer)
    local input = b.input
    local state = M:State(input, layer)
    local action = M:Get(input.id, layer)
    local wizard = self.wizard and self.wizard.order[self.wizard.step]
    b.select:SetShown(input.id == (wizard or (not self.focusAction and not self.focusLayers and self.selected)))
    b.plus:Hide()
    b.icon:SetDesaturated(false)
    b.icon:SetAlpha(1)
    b:SetAlpha(1)
    if state == "locked" and input.paddle then
        -- A shared key a game function takes: that function, faded
        local shown = M:EffectiveAction(input, layer)
        P.SetIcon(b.icon, M:ActionIcon(shown) or { glyph = GLYPH[input.id] })
        b.icon:SetAlpha(0.5)
        b.name:SetText(M:ActionName(shown) or "—")
        b.name:SetTextColor(unpack(GREY))
        b:SetAlpha(0.6)
    elseif state == "locked" then
        -- No layer of its own: what the button does without the trigger
        local name, icon = M:NativeInfo(input, "")
        P.SetIcon(b.icon, icon or { glyph = GLYPH[input.id] })
        b.icon:SetAlpha(0.5)
        b.name:SetText(name or "—")
        b.name:SetTextColor(unpack(GREY))
        b:SetAlpha(0.6)
    elseif state == "slot" then
        -- The game's bar slot: what it holds, else the button, faded
        local name, icon = M:NativeInfo(input, layer)
        P.SetIcon(b.icon, icon or { glyph = GLYPH[input.id] })
        b.icon:SetAlpha(icon and 1 or 0.4)
        b.name:SetText(name or L.MAP_EMPTY_SLOT)
        b.name:SetTextColor(unpack(icon and GOLD or GREY))
    elseif state == "native" then
        -- The game's own: its function's icon, else the button itself
        local name, icon = M:NativeInfo(input, layer)
        P.SetIcon(b.icon, icon or { glyph = GLYPH[input.id] })
        b.icon:SetAlpha(icon and 0.9 or 0.5)
        b.name:SetText(name or L.MAP_GAME)
        b.name:SetTextColor(unpack(GREY))
    elseif action then
        P.SetIcon(b.icon, M:ActionIcon(action))
        b.name:SetText(M:ActionName(action))
        local inactive = M:Inactive(input, layer)
        b.icon:SetDesaturated(inactive)
        b.name:SetTextColor(unpack(inactive and GREY or GOLD))
    else
        P.SetIcon(b.icon, nil)
        b.plus:Show()
        b.name:SetText(L.MAP_FREE)
        b.name:SetTextColor(unpack(GREEN))
    end
end

function W:Render()
    local f = self.frame
    local layer = self:ViewLayer()
    for _, t in ipairs(f.layerTabs) do
        t:SetActive(t.layer == layer)
        t.hover = self.focusLayers and t.layer == layer or nil
        t:Render()
    end
    for _, b in pairs(f.slots) do self:RenderSlot(b, layer) end
    for i, b in ipairs(f.actions) do b:SetActive(self.focusAction == i) end
    self:RenderSide(layer)
end

function W:RenderSide(layer)
    local side = self.frame.side
    local picker = self.picker
    local input = self:SelectedInput()
    layer = picker and picker.layer or layer
    local status
    if self.wizard then
        local id = self.wizard.order[self.wizard.step]
        side.title:SetText(L.MAP_IDENTIFY)
        status = format(L.MAP_WIZARD, id)
    elseif self.focusAction then
        side.title:SetText(self.focusAction == 1 and L.MAP_IDENTIFY or L.MAP_PLACE)
        status = self.focusAction == 1 and L.MAP_IDENTIFY_HINT or L.MAP_PLACE_HINT
    elseif input then
        side.title:SetText(comboLabel(input, layer))
        local state = M:State(input, layer)
        local action = M:Get(input.id, layer)
        if P:IsCapturing(input.id) then
            status = L.MAP_PADDLE_PRESS
        elseif state == "locked" and input.paddle then
            local base = M:SharedLayers(layer)[1]
            status = format(L.MAP_SHARED_LOCKED, comboLabel(input, base), M:ActionName(M:Get(input.id, base)) or "")
        elseif state == "locked" then
            local name = M:NativeInfo(input, "")
            status = (name and (name .. "\n") or "") .. "|cff9d9a8c" .. L.MAP_LOCKED .. "|r"
        elseif state == "slot" then
            -- The game keeps some actions on its bars (hunter aspects...)
            local kept = M:SlotKept(M:NativeSlot(input, layer))
            status = "|cffffd100" .. (M:NativeInfo(input, layer) or L.MAP_EMPTY_SLOT) .. "|r\n|cff9d9a8c" .. (kept or L.MAP_SLOT_HINT) .. "|r"
        elseif state == "native" then
            status = (M:NativeInfo(input, layer) or L.MAP_GAME) .. "\n|cff9d9a8c" .. L.MAP_NATIVE_HINT .. "|r"
        elseif action and M:Inactive(input, layer) then
            status = "|cff9d9a8c" .. (M:ActionName(action) or "") .. "|r\n" .. L.MAP_SHARED_INACTIVE
        elseif action then
            status = "|cffffd100" .. (M:ActionName(action) or "") .. "|r\n|cff9d9a8c" .. L.MAP_ASSIGNED_HINT .. "|r"
        else
            status = L.MAP_FREE_HINT
        end
        -- A shared key: spells, items and macros only
        if input.paddle and state == "free" and M:PaddleTabs(input, layer) == M.SLOT_TABS and not M:Inactive(input, layer) then
            status = status .. "\n|cff9d9a8c" .. L.MAP_SHARED_HINT .. "|r"
        end
        if input.paddle and not P:IsCapturing(input.id) then
            local key = M:InputKey(input)
            status = status .. "\n" .. format(L.MAP_PADDLE_KEY, GetBindingText and GetBindingText(key) or key)
        end
    else
        side.title:SetText("")
        status = ""
    end
    -- The list starts under two lines: while it is open, only what the
    -- input holds now
    if picker and input then
        local name
        if picker.slot then
            -- Whatever the slot holds (spell, flyout, mount...)
            name = P.SlotTexture(picker.slot) and (P.SlotName(picker.slot) or L.MAP_GAME)
        else
            local current = M:Get(input.id, layer)
            name = current and M:ActionName(current)
        end
        status = name and ("|cffffd100" .. name .. "|r")
            or ("|cff9d9a8c" .. (picker.slot and L.MAP_EMPTY_SLOT or L.MAP_FREE) .. "|r")
    end
    side.status:SetMaxLines(picker and 2 or 0)
    side.status:SetText(status)

    -- The tab buttons show this picker's own tabs
    local x = 8
    for i, t in ipairs(side.ptabs) do
        local tab = picker and picker.tabs[i]
        t:SetShown(tab ~= nil)
        if tab then
            t.label:SetText(L["MAP_TAB_" .. tab:upper()])
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", x, -70)
            x = x + 54
            t:SetActive(picker.tab == i)
        end
    end
    for i, r in ipairs(side.rows) do
        local entry = picker and picker.list[picker.offset + i]
        r.index = entry and not entry.header and (picker.offset + i) or nil
        r:SetShown(entry ~= nil)
        if entry then
            P.SetIcon(r.icon, entry.icon)
            r.label:SetText(entry.header or entry.name)
            r.label:ClearAllPoints()
            r.label:SetPoint("LEFT", entry.header and 4 or 26, 0)
            r.label:SetPoint("RIGHT", -4, 0)
            r.label:SetTextColor(unpack(entry.header and kit.C.gold or kit.C.btn))
            r.select:SetShown(picker.offset + i == picker.index)
        end
    end
    if picker and #picker.list == 0 then
        local r = side.rows[1]
        r:Show()
        r.index = nil
        r.icon:Hide()
        r.select:SetShown(false)
        r.label:SetText(L.MAP_NOTHING)
        r.label:SetTextColor(unpack(GREY))
    end
end

function W:Help(g)
    if self.wizard then
        return { g("B") .. " " .. L.MAP_P_SKIP }
    elseif self.focusLayers then
        return {
            g("DPAD_LEFT") .. " " .. L.MAP_P_LAYER, g("A") .. g("DPAD_DOWN") .. " " .. L.MAP_P_CONFIRM,
            g("LB") .. g("RB") .. " " .. L.MAP_P_TAB, g("B") .. " " .. L.MAP_P_CLOSE,
        }
    elseif self.picker then
        return {
            g("DPAD_UP") .. " " .. L.MAP_P_MOVE, g("DPAD_LEFT") .. " " .. L.MAP_P_SECTION,
            g("A") .. " " .. L.MAP_P_CHOOSE, g("LB") .. g("RB") .. " " .. L.MAP_P_LIST, g("B") .. " " .. L.MAP_P_BACK,
        }
    end
    return {
        g("DPAD_UP") .. " " .. L.MAP_P_MOVE, g("A") .. " " .. L.MAP_P_CHOOSE,
        g("X") .. " " .. L.MAP_P_CLEAR, g("Y") .. " " .. L.MAP_P_KEY,
        g("DPAD_UP") .. "/" .. g("LT") .. g("RT") .. " " .. L.MAP_P_LAYER, g("LB") .. g("RB") .. " " .. L.MAP_P_TAB,
        g("B") .. " " .. L.MAP_P_CLOSE,
    }
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------
-- D-pad on the controller: the nearest input in that direction; below the
-- back paddles, the two action buttons
local DIRS = { UP = { 0, -1 }, DOWN = { 0, 1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 } }

function W:Move(dir)
    -- On the layer row: left / right pick the layer, down goes back
    if self.focusLayers then
        if dir == "DOWN" then
            self.focusLayers = false
        elseif dir == "LEFT" or dir == "RIGHT" then
            local index = 1
            for i, layer in ipairs(M.LAYERS) do
                if layer == (self.layer or "") then index = i end
            end
            index = math.max(1, math.min(#M.LAYERS, index + (dir == "LEFT" and -1 or 1)))
            self.layer = M.LAYERS[index]
        end
        CK.Config:Render()
        return
    end
    if self.focusAction then
        if dir == "UP" then
            self.focusAction = nil
        elseif dir == "LEFT" or dir == "RIGHT" then
            self.focusAction = dir == "LEFT" and 1 or 2
        end
        CK.Config:Render()
        return
    end
    local from = self:SelectedInput()
    if not from then return end
    local dx, dy = DIRS[dir][1], DIRS[dir][2]
    local best, bestScore
    for _, input in ipairs(M.INPUTS) do
        if input ~= from then
            local vx, vy = input.x - from.x, input.y - from.y
            local along = vx * dx + vy * dy
            local across = math.abs(vx * dy - vy * dx)
            if along > 0 and across <= along * 1.8 + 20 then
                local score = along + across * 2
                if not bestScore or score < bestScore then best, bestScore = input, score end
            end
        end
    end
    if best then
        self.selected = best.id
    elseif dir == "DOWN" then
        self.focusAction = from.x < 235 and 1 or 2
    elseif dir == "UP" then
        self.focusLayers = true
    end
    CK.Config:Render()
end

function W:Choose()
    if self.focusLayers then
        self.focusLayers = false
        CK.Config:Render()
        return
    end
    if self.focusAction then
        if self.focusAction == 1 then self:Identify() else self:Place() end
        return
    end
    local input = self:SelectedInput()
    if not input then return end
    local layer = self:ViewLayer()
    local state = M:State(input, layer)
    if state == "slot" then
        local slot = M:NativeSlot(input, layer)
        local kept = M:SlotKept(slot)
        if kept then
            if UIErrorsFrame then UIErrorsFrame:AddMessage(kept, 1, 0.1, 0.1) end
            return
        end
        self.picker = { layer = layer, tab = 1, tabs = M.SLOT_TABS, slot = slot }
    elseif state == "free" then
        self.picker = { layer = layer, tab = 1, tabs = input.paddle and M:PaddleTabs(input, layer) or M.TABS }
    else
        return
    end
    self:LoadTab()
end

function W:SetTab(i)
    if not self.picker then return end
    self.picker.tab = (i - 1) % #self.picker.tabs + 1
    self:LoadTab()
end

function W:LoadTab()
    local picker = self.picker
    picker.list = M:Catalog(picker.tabs[picker.tab], picker.slot ~= nil)
    picker.offset, picker.index = 0, nil
    -- Start on the current function when it is in this list
    local current = picker.slot and M:SlotAction(picker.slot) or M:Get(self.selected, picker.layer)
    for i, entry in ipairs(picker.list) do
        if not entry.header and (entry.action == current or not picker.index) then
            picker.index = i
            if entry.action == current then break end
        end
    end
    self:MoveInList(0)
end

function W:MoveInList(delta)
    local picker = self.picker
    if not (picker and picker.index) then
        CK.Config:Render()
        return
    end
    local list, i = picker.list, picker.index
    local step = delta < 0 and -1 or 1
    for _ = 1, math.abs(delta) do
        local j = i + step
        while list[j] and list[j].header do j = j + step end
        if list[j] then i = j end
    end
    picker.index = i
    -- Keep the selection (and its section title) in view
    local top = i
    if list[i - 1] and list[i - 1].header then top = i - 1 end
    if top <= picker.offset then picker.offset = math.max(0, top - 1) end
    if i > picker.offset + ROWS then picker.offset = i - ROWS end
    CK.Config:Render()
end

-- D-pad left / right in the list: previous / next section (a page when the
-- list has no sections)
function W:JumpSection(step)
    local picker = self.picker
    if not (picker and picker.index) then return end
    local list, headers = picker.list, {}
    for i, entry in ipairs(list) do
        if entry.header then headers[#headers + 1] = i end
    end
    if #headers < 2 then return self:MoveInList(step * ROWS) end
    local current = 0
    for n, h in ipairs(headers) do
        if h < picker.index then current = n end
    end
    local target = headers[current + step]
    if not target then return end
    local j = target + 1
    while list[j] and list[j].header do j = j + 1 end
    if list[j] then
        picker.index = j
        self:MoveInList(0)
    end
end

function W:Assign()
    local picker = self.picker
    local entry = picker and picker.index and picker.list[picker.index]
    if not entry or entry.header then return end
    if picker.slot then
        M:PlaceInSlot(picker.slot, entry.action)
    else
        M:Set(self.selected, picker.layer, entry.action)
    end
    self.picker = nil
    CK.Config:Render()
end

function W:Clear()
    if self.picker or self.focusAction or self.focusLayers then return end
    local input = self:SelectedInput()
    if not input then return end
    local layer = self:ViewLayer()
    local slot = M:State(input, layer) == "slot" and M:NativeSlot(input, layer)
    if slot then
        M:ClearSlot(slot)
    elseif M:Get(input.id, layer) then
        M:Set(input.id, layer, nil)
    end
    CK.Config:Render()
end

function W:LearnKey()
    local input = self:SelectedInput()
    if not (input and input.paddle) or self.picker or self.focusAction or self.focusLayers then return end
    P:Capture(input.id, function() if CK.Config:IsOpen() then CK.Config:Render() end end)
    CK.Config:Render()
end

-- Identify the back paddles: press each one in turn (B skips one)
function W:Identify()
    self.picker = nil
    self.wizard = { order = P.ORDER, step = 1 }
    self:WizardStep()
end

function W:WizardStep()
    local wizard = self.wizard
    if not wizard then return end
    local id = wizard.order[wizard.step]
    if not id then
        self.wizard = nil
        CK:Print(L.MAP_WIZARD_DONE)
        CK.Config:Render()
        return
    end
    self.selected = id
    P:Capture(id, function()
        if W.wizard then
            W.wizard.step = W.wizard.step + 1
            W:WizardStep()
        end
    end)
    CK.Config:Render()
end

function W:Place()
    self.picker = nil
    CK.Config:BeginPlacement()
    P:StartPlacement()
end

---------------------------------------------------------------------------
-- Pad buttons (the panel handles LB / RB and B when we don't)
---------------------------------------------------------------------------
function W:Press(name)
    -- Waiting for a paddle: B skips (wizard) or cancels
    if P:IsCapturing() then
        if name == "B" then P:StopCapture(nil) end
        if not self.wizard then CK.Config:Render() end
        return true
    end
    local picker = self.picker
    if name == "UP" or name == "DOWN" then
        if picker then self:MoveInList(name == "UP" and -1 or 1) else self:Move(name) end
    elseif name == "LEFT" or name == "RIGHT" then
        if picker then self:JumpSection(name == "LEFT" and -1 or 1) else self:Move(name) end
    elseif name == "A" then
        if picker then self:Assign() else self:Choose() end
    elseif name == "B" and picker then
        self.picker = nil
        CK.Config:Render()
    elseif name == "X" then
        self:Clear()
    elseif name == "Y" then
        self:LearnKey()
    elseif (name == "LB" or name == "RB") and picker then
        self:SetTab(picker.tab + (name == "LB" and -1 or 1))
    else
        return false
    end
    return true
end

function W:OnUpdate()
    -- A slot changed (placed from here, or by the game): drawn again
    if self.slotsChanged then
        self.slotsChanged = false
        if not self.picker then CK.Config:Render() end
    end
    -- Holding LT / RT shows their layer
    local held = P.HeldLayer()
    if held ~= self.heldLayer then
        self.heldLayer = held
        if not self.picker then CK.Config:Render() end
    end
end
