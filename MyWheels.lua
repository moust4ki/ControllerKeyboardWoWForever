local _, CK = ...
local L = CK.L

-- Module "my wheels": wheels of the player's own, drawn and handled like the
-- consumables wheel (ConsumableWheel.lua shows them all): 8 slots each, the
-- spells, items and macros the player picks, up to 8 wheels. Each has a key
-- of its own: the Gamepad tab's Items list (any button), or the game's Key
-- Bindings ("CLICK ControllerKeyboardMyWheelN"). Made, named and filled in
-- the Wheels tab: the list of wheels, and each wheel's editor (its slots
-- around it, what a slot can take beside them); names typed with the
-- addon's keyboard or a physical one.
local MW = {}
CK.MyWheels = MW

local SLOTS = 8
-- The lists a slot takes from (the Gamepad tab's)
local TABS = { "spells", "items", "macros" }

local function settings() return CK.db.settings.myWheels end

---------------------------------------------------------------------------
-- The wheels: settings.myWheels.list = { { id = 1-8, name, slots = { [1-8] = "spell:133" } } }
---------------------------------------------------------------------------
function MW:List()
    return settings().list
end

function MW:Get(id)
    for _, w in ipairs(self:List()) do
        if w.id == id then return w end
    end
end

function MW:Name(id)
    local w = self:Get(id)
    return w and w.name
end

function MW:Count(w)
    local n = 0
    for i = 1, SLOTS do
        if w.slots[i] then n = n + 1 end
    end
    return n
end

-- Its picture: its first slot's
function MW:Icon(id)
    local w = self:Get(id)
    for i = 1, SLOTS do
        local action = w and w.slots[i]
        local icon = action and CK.Mapping:ActionIcon(action)
        if icon then return icon end
    end
    return CK.Mapping.WHEEL_ICON
end

-- What ConsumableWheel.lua puts in it: { [slot] = entry }
function MW:Entries(id)
    local w = self:Get(id)
    local entries = {}
    for i = 1, SLOTS do
        local kind, value = ((w and w.slots[i]) or ""):match("^(%a+):(.+)$")
        if kind == "spell" or kind == "item" then
            entries[i] = { kind = kind, id = tonumber(value) }
        elseif kind == "macro" and GetMacroInfo(value) then
            entries[i] = { kind = "macro", name = value }
        end
    end
    return entries
end

local function changed()
    MW:UpdateBindingNames()
    CK.ConsumableWheel:Fill()
end

function MW:Create()
    local used = {}
    for _, w in ipairs(self:List()) do used[w.id] = true end
    for id = 1, CK.ConsumableWheel.MY_MAX do
        if not used[id] then
            table.insert(self:List(), { id = id, name = format(L.MYWHEEL_DEFAULT, id), slots = {} })
            changed()
            return id
        end
    end
end

-- Gone, and gone from every button it was on
function MW:Delete(id)
    local list = self:List()
    for i, w in ipairs(list) do
        if w.id == id then table.remove(list, i) break end
    end
    local action = "wheel:" .. id
    for _, assigned in ipairs({ CK.db.settings.mapping, CK.db.settings.replaced }) do
        for key, value in pairs(assigned) do
            if value == action then assigned[key] = nil end
        end
    end
    changed()
    CK.Mapping:Apply()
    CK.Paddles:Apply()
end

function MW:SetSlot(id, slot, action)
    local w = self:Get(id)
    if not w then return end
    w.slots[slot] = action
    changed()
end

function MW:Rename(id, name)
    local w = self:Get(id)
    name = name and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if not w or name == "" then return end
    w.name = name:sub(1, 40)
    changed()
end

-- The game's Key Bindings menu shows each wheel's name
function MW:UpdateBindingNames()
    for id = 1, CK.ConsumableWheel.MY_MAX do
        _G["BINDING_NAME_CLICK ControllerKeyboardMyWheel" .. id .. ":LeftButton"] =
            self:Name(id) or format(L.MYWHEEL_DEFAULT, id)
    end
end

---------------------------------------------------------------------------
-- The Wheels tab: the list of wheels (each opens its editor), "New wheel"
---------------------------------------------------------------------------
function MW:AddRows(b)
    local list = self:List()
    b.header(L.MYWHEEL_H)
    b.info(L.MYWHEEL_INFO)
    for _, w in ipairs(list) do
        b.button(format("%s  |cff9d9a8c(%d/%d)|r", w.name, self:Count(w), SLOTS), function()
            self:OpenEditor(w.id)
        end, nil, "wheel" .. w.id)
    end
    if #list < CK.ConsumableWheel.MY_MAX then
        b.button("+ " .. L.MYWHEEL_NEW, function()
            local id = self:Create()
            if id then self:OpenEditor(id) end
        end, nil, "new")
    end
end

-- The tab's page: the list, or a wheel's editor over it
function MW:TabPage(list)
    local editor = self.Editor
    local page = {}
    local function current() return MW.open and editor or list end
    function page:Build(parent)
        list:Build(parent)
        editor:Build(parent)
    end
    function page:Show() current():Show() end
    function page:Hide()
        list:Hide()
        editor:Hide()
    end
    function page:Render() current():Render() end
    function page:Press(name) return current():Press(name) end
    function page:Help(g) return current():Help(g) end
    -- What the list's rows set (selectKey...) goes to the list
    return setmetatable(page, {
        __index = function(_, key) return list[key] end,
        __newindex = function(_, key, value) list[key] = value end,
    }), list
end

function MW:OpenEditor(id)
    if not self:Get(id) then return end
    self.open = true
    local E = self.Editor
    E.id, E.slot, E.focus, E.picker, E.deleting = id, 1, nil, nil, false
    self.list:Hide()
    E:Show()
    CK.Config:Render()
end

function MW:CloseEditor()
    if not self.open then return end
    local id = self.Editor.id
    self.open = false
    self.Editor:Hide()
    self.list.selectKey = self:Get(id) and ("wheel" .. id) or "new"
    self.list:Show()
    self.list:Refresh()
end

---------------------------------------------------------------------------
-- A wheel's editor: the wheel as the game draws it, its 8 slots around it
-- (the D-pad or LB / RB go from one to the next), and on the right, for
-- the chosen slot, everything it can take (Spells / Items / Macros). A
-- choice fills the slot and goes on to the next one, the list still open.
---------------------------------------------------------------------------
local E = {}
MW.Editor = E

local SLOT_SIZE, RADIUS = 48, 122
local CX, CY = 235, -205        -- the wheel's middle, in its area
local ROWS, ROW_H = 15, 24
local GREY, GOLD = { 0.62, 0.6, 0.55 }, { 1, 0.82, 0 }
local kit

local function slotPoint(i)
    local angle = math.rad(90 - (i - 1) * 45)
    return RADIUS * math.cos(angle), RADIUS * math.sin(angle)
end

local function positions() return { strsplit(",", L.MYWHEEL_POS) } end

function E:Build(parent)
    kit = CK.UIKit
    local f = CK.NewFrame("Frame", nil, parent)
    f:SetAllPoints()
    f:Hide()
    self.frame = f

    -- The wheel, drawn with the game's art
    local area = CK.NewFrame("Frame", nil, f)
    area:SetPoint("TOPLEFT", 0, 0)
    area:SetSize(470, 470)
    local bg = area:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("CENTER", area, "TOPLEFT", CX, CY)
    bg:SetSize(380, 380)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("gamepad-radial-menu-wheelbg") then
        bg:SetAtlas("gamepad-radial-menu-wheelbg")
    else
        bg:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        bg:SetVertexColor(0, 0, 0, 0.7)
    end
    f.bg = bg
    f.name = kit.text(area, 15)
    f.name:SetPoint("CENTER", bg, "CENTER", 0, 10)
    f.name:SetWidth(150)
    f.name:SetTextColor(unpack(kit.C.gold))
    f.count = kit.text(area, 11)
    f.count:SetPoint("TOP", f.name, "BOTTOM", 0, -4)
    f.count:SetTextColor(unpack(GREY))

    f.slots = {}
    for i = 1, SLOTS do
        local x, y = slotPoint(i)
        local b = CK.Paddles:CreateSlot(area, SLOT_SIZE)
        b:SetPoint("CENTER", bg, "CENTER", x, y)
        b.select = b.over:CreateTexture(nil, "OVERLAY")
        b.select:SetPoint("TOPLEFT", -6, 6)
        b.select:SetPoint("BOTTOMRIGHT", 6, -6)
        if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("gamepad-actionbar-circleslot-border-selected") then
            b.select:SetAtlas("gamepad-actionbar-circleslot-border-selected")
        else
            b.select:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        end
        b.select:SetVertexColor(1, 0.85, 0.3)
        b.plus = b.over:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        b.plus:SetPoint("CENTER", 0, 1)
        b.plus:SetText("+")
        b.label = kit.text(area, 10)
        b.label:SetWidth(96)
        b.label:SetWordWrap(true)
        if b.label.SetMaxLines then b.label:SetMaxLines(2) end
        -- Outside the ring: beside the left and right slots, else above / below
        local lx, ly = x * 1.5, y * 1.38
        b.label:SetPoint("CENTER", bg, "CENTER", lx, ly)
        b:EnableMouse(true)
        b:SetScript("OnEnter", function()
            if E.picker or MW.renaming then return end
            E.slot, E.focus = i, nil
            CK.Config:Render()
        end)
        b:SetScript("OnMouseUp", function(_, button)
            if MW.renaming then return end
            E.slot, E.focus = i, nil
            if button == "RightButton" then E:ClearSlot() else E:OpenPicker() end
        end)
        f.slots[i] = b
    end

    -- Below: rename, delete
    f.actions = {}
    for i, action in ipairs({ "Rename", "Delete" }) do
        local b = kit.buildButton(f, "", function()
            E.focus = i
            E[action](E)
        end)
        b:SetSize(210, 26)
        b:SetPoint("TOPLEFT", area, "TOPLEFT", 20 + (i - 1) * 222, -436)
        f.actions[i] = b
    end

    -- Right: the chosen slot, and its lists
    local side = CK.NewFrame("Frame", nil, f)
    side:SetPoint("TOPLEFT", 480, 0)
    side:SetSize(300, 470)
    kit.nineSlice(side, "ck_bar", 256, 64, 8, 8, "BORDER")
    f.side = side
    side.title = kit.text(side, 14)
    side.title:SetPoint("TOPLEFT", 12, -10)
    side.title:SetTextColor(unpack(kit.C.gold))
    side.status = kit.text(side, 11)
    side.status:SetPoint("TOPLEFT", 12, -32)
    side.status:SetWidth(276)
    side.status:SetJustifyH("LEFT")
    side.status:SetWordWrap(true)
    side.tabs = {}
    for i, tab in ipairs(TABS) do
        local t = kit.buildButton(side, L["MAP_TAB_" .. tab:upper()], function() E:SetTab(i) end)
        t:SetSize(92, 20)
        t:SetPoint("TOPLEFT", 8 + (i - 1) * 96, -84)
        side.tabs[i] = t
    end
    side.rows = {}
    for i = 1, ROWS do
        local r = CK.NewFrame("Button", nil, side)
        r:SetSize(284, ROW_H - 2)
        r:SetPoint("TOPLEFT", 8, -110 - (i - 1) * ROW_H)
        r.select = kit.nineSlice(r, "ck_select", 128, 32, 10, 10, "ARTWORK")
        r.icon = r:CreateTexture(nil, "ARTWORK", nil, 1)
        r.icon:SetSize(18, 18)
        r.icon:SetPoint("LEFT", 4, 0)
        r.label = kit.text(r, 11)
        r.label:SetJustifyH("LEFT")
        r.label:SetWordWrap(false)
        r:SetScript("OnClick", function(self)
            if self.index then
                E.picker.index = self.index
                E:Assign()
            end
        end)
        r:SetScript("OnEnter", function(self)
            if self.index and E.picker and E.picker.index ~= self.index then
                E.picker.index = self.index
                CK.Config:Render()
            end
        end)
        side.rows[i] = r
    end
    side:EnableMouseWheel(true)
    side:SetScript("OnMouseWheel", function(_, delta) if E.picker then E:MoveInList(-delta * 3) end end)
end

function E:Show() self.frame:Show() end
function E:Hide() self.frame:Hide() end

function E:Wheel() return MW:Get(self.id) end

---------------------------------------------------------------------------
-- The list of a slot: what the Gamepad tab offers (spells, items, macros)
---------------------------------------------------------------------------
function E:OpenPicker()
    if not self:Wheel() then return end
    self.focus = nil
    self.picker = { tab = self.picker and self.picker.tab or 1 }
    self:LoadTab()
end

function E:SetTab(i)
    if not self.picker then self:OpenPicker() end
    self.picker.tab = (i - 1) % #TABS + 1
    self:LoadTab()
end

function E:LoadTab()
    local picker = self.picker
    picker.list = CK.Mapping:Catalog(TABS[picker.tab], true)
    picker.offset, picker.index = 0, nil
    -- On what the slot holds, when it is in this list
    local current = self:Wheel().slots[self.slot]
    for i, entry in ipairs(picker.list) do
        if not entry.header and (entry.action == current or not picker.index) then
            picker.index = i
            if entry.action == current then break end
        end
    end
    self:MoveInList(0)
end

function E:MoveInList(delta)
    local picker = self.picker
    if not (picker and picker.index) then return CK.Config:Render() end
    local list, i = picker.list, picker.index
    local step = delta < 0 and -1 or 1
    for _ = 1, math.abs(delta) do
        local j = i + step
        while list[j] and list[j].header do j = j + step end
        if list[j] then i = j end
    end
    picker.index = i
    local top = i
    if list[i - 1] and list[i - 1].header then top = i - 1 end
    if top <= picker.offset then picker.offset = math.max(0, top - 1) end
    if i > picker.offset + ROWS then picker.offset = i - ROWS end
    CK.Config:Render()
end

-- Previous / next section of the list (a page without sections)
function E:JumpSection(step)
    local picker = self.picker
    if not (picker and picker.index) then return end
    local headers = {}
    for i, entry in ipairs(picker.list) do
        if entry.header then headers[#headers + 1] = i end
    end
    if #headers < 2 then return self:MoveInList(step * ROWS) end
    local current = 0
    for n, h in ipairs(headers) do
        if h < picker.index then current = n end
    end
    local target = headers[current + step]
    if not target then return end
    picker.index = target
    self:MoveInList(1)
end

-- The chosen entry into the slot, then on to the next slot, the list open
function E:Assign()
    local picker = self.picker
    local entry = picker and picker.index and picker.list[picker.index]
    if not entry or entry.header then return end
    MW:SetSlot(self.id, self.slot, entry.action)
    self.slot = self.slot % SLOTS + 1
    self:LoadTab()
end

function E:ClearSlot()
    if self:Wheel() and self:Wheel().slots[self.slot] then MW:SetSlot(self.id, self.slot, nil) end
    CK.Config:Render()
end

function E:Rename()
    self.picker = nil
    MW:StartRename(self.id)
end

-- Asked once, done on the second press
function E:Delete()
    self.picker = nil
    if self.deleting then
        self.deleting = false
        MW:CloseEditor()
        MW:Delete(self.id)
        CK.Config:Page():Show()
        CK.Config:Render()
    else
        self.deleting = true
        CK.Config:Render()
    end
end

---------------------------------------------------------------------------
-- The pad
---------------------------------------------------------------------------
local DIRS = { UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 } }

-- Around the wheel: of the two slots beside the chosen one, the one the
-- direction leads to (none: the edge of the wheel that way)
local function nearest(from, dir)
    local fx, fy = slotPoint(from)
    local dx, dy = DIRS[dir][1], DIRS[dir][2]
    local best, bestAlong = nil, 1
    for _, i in ipairs({ (from - 2) % SLOTS + 1, from % SLOTS + 1 }) do
        local x, y = slotPoint(i)
        local along = (x - fx) * dx + (y - fy) * dy
        if along > bestAlong then best, bestAlong = i, along end
    end
    return best
end

function E:Press(name)
    if MW.renaming then
        if name == "A" then MW:FinishRename(MW.box.edit:GetText())
        elseif name == "B" then MW:FinishRename(nil) end
        return true
    end
    if name ~= "A" then self.deleting = false end
    local picker = self.picker
    if picker then
        if name == "UP" or name == "DOWN" then
            self:MoveInList(name == "UP" and -1 or 1)
        elseif name == "LEFT" or name == "RIGHT" then
            self:JumpSection(name == "LEFT" and -1 or 1)
        elseif name == "A" then
            self:Assign()
        elseif name == "X" then
            self:ClearSlot()
        elseif name == "LB" or name == "RB" then
            self:SetTab(picker.tab + (name == "LB" and -1 or 1))
        elseif name == "B" then
            self.picker = nil
            CK.Config:Render()
        end
        return true
    end
    if self.focus then
        -- The buttons under the wheel
        if name == "LEFT" or name == "RIGHT" then
            self.focus = name == "LEFT" and 1 or 2
        elseif name == "UP" then
            self.focus = nil
        elseif name == "A" then
            if self.focus == 1 then self:Rename() else self:Delete() end
            return true
        elseif name == "B" then
            self.focus = nil
            MW:CloseEditor()
            return true
        end
        CK.Config:Render()
        return true
    end
    if DIRS[name] then
        local to = nearest(self.slot, name)
        if to then
            self.slot = to
        elseif name == "DOWN" then
            self.focus = 1
        end
    elseif name == "LB" or name == "RB" then
        self.slot = (self.slot - 1 + (name == "LB" and -1 or 1)) % SLOTS + 1
    elseif name == "A" then
        return self:OpenPicker() or true
    elseif name == "X" then
        self:ClearSlot()
    elseif name == "Y" then
        self:Rename()
    elseif name == "B" then
        MW:CloseEditor()
        return true
    end
    CK.Config:Render()
    return true
end

function E:Help(g)
    if MW.renaming then
        return { g("A") .. " " .. L.MAP_P_CHOOSE, g("B") .. " " .. L.MAP_P_BACK }
    end
    if self.picker then
        return {
            g("DPAD_UP") .. " " .. L.MAP_P_MOVE, g("DPAD_LEFT") .. " " .. L.MAP_P_SECTION,
            g("A") .. " " .. L.MAP_P_CHOOSE, g("X") .. " " .. L.MAP_P_CLEAR,
            g("LB") .. g("RB") .. " " .. L.MAP_P_LIST, g("B") .. " " .. L.MAP_P_BACK,
        }
    end
    return {
        g("DPAD_UP") .. g("LB") .. g("RB") .. " " .. L.MYWHEEL_P_SLOT, g("A") .. " " .. L.MAP_P_CHOOSE,
        g("X") .. " " .. L.MAP_P_CLEAR, g("Y") .. " " .. L.MYWHEEL_RENAME, g("B") .. " " .. L.MAP_P_BACK,
    }
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------
function E:Render()
    local f, w = self.frame, self:Wheel()
    if not (f and w) then return end
    f.name:SetText(w.name)
    f.count:SetText(format("%d / %d", MW:Count(w), SLOTS))
    local pos = positions()
    for i, b in ipairs(f.slots) do
        local action = w.slots[i]
        local icon = action and CK.Mapping:ActionIcon(action)
        CK.Paddles.SetIcon(b.icon, icon)
        b.plus:SetShown(not action)
        b.select:SetShown(i == self.slot and not self.focus)
        b.label:SetText(action and (CK.Mapping:ActionName(action) or action) or pos[i])
        b.label:SetTextColor(unpack(action and kit.C.btn or GREY))
    end
    f.actions[1].label:SetText(L.MYWHEEL_RENAME)
    f.actions[2].label:SetText(self.deleting and L.MYWHEEL_DELETE_CONFIRM or L.MYWHEEL_DELETE)
    for i, b in ipairs(f.actions) do b:SetActive(self.focus == i) end

    local side, picker = f.side, self.picker
    local action = w.slots[self.slot]
    side.title:SetText(format("%s  |cff9d9a8c(%d)|r", pos[self.slot] or "", self.slot))
    local content = action and ("|cffffd100" .. (CK.Mapping:ActionName(action) or action) .. "|r")
        or ("|cff9d9a8c" .. L.MYWHEEL_EMPTY .. "|r")
    side.status:SetText(picker and content or (content .. "\n|cff9d9a8c" .. L.MYWHEEL_SLOT_HINT .. "|r"))
    for i, t in ipairs(side.tabs) do
        t:SetShown(picker ~= nil)
        t:SetActive(picker and picker.tab == i or false)
    end
    for i, r in ipairs(side.rows) do
        local entry = picker and picker.list[picker.offset + i]
        r.index = entry and not entry.header and (picker.offset + i) or nil
        r:SetShown(entry ~= nil)
        if entry then
            CK.Paddles.SetIcon(r.icon, entry.icon)
            r.icon:SetShown(entry.icon ~= nil and not entry.header)
            r.label:SetText(entry.header or entry.name)
            r.label:ClearAllPoints()
            r.label:SetPoint("LEFT", entry.header and 4 or 26, 0)
            r.label:SetPoint("RIGHT", -4, 0)
            r.label:SetTextColor(unpack(entry.header and GOLD or kit.C.btn))
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

---------------------------------------------------------------------------
-- Naming: a box of ours with a field for a physical keyboard, and the
-- addon's keyboard (A confirms, B cancels) when its module is on
---------------------------------------------------------------------------
function MW:RenameBox()
    if self.box then return self.box end
    local kit = CK.UIKit
    local box = CK.NewFrame("Frame", nil, UIParent)
    box:SetSize(440, 104)
    box:SetFrameStrata("FULLSCREEN_DIALOG")
    box:EnableMouse(true)
    CK.Config.panel(box)
    box.title = kit.text(box, 14)
    box.title:SetPoint("TOP", 0, -12)
    box.title:SetTextColor(unpack(kit.C.gold))
    box.title:SetText(L.MYWHEEL_NAME_PROMPT)
    local field = box:CreateTexture(nil, "ARTWORK")
    field:SetColorTexture(0, 0, 0, 0.6)
    field:SetSize(400, 26)
    field:SetPoint("TOP", 0, -38)
    local edit = CK.NewFrame("EditBox", nil, box)
    edit:SetAllPoints(field)
    edit:SetFontObject(ChatFontNormal)
    edit:SetTextInsets(8, 8, 0, 0)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(40)
    edit:SetScript("OnEnterPressed", function(self) MW:FinishRename(self:GetText()) end)
    edit:SetScript("OnEscapePressed", function() MW:FinishRename(nil) end)
    -- Typed on a physical keyboard: the addon's keyboard follows
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and CK.prompt and CK.prompt.box == self then
            CK.buffer = self:GetText()
            CK:Refresh()
        end
    end)
    box.edit = edit
    box.help = kit.text(box, 11)
    box.help:SetPoint("BOTTOM", 0, 10)
    box.help:SetWidth(420)
    box.help:SetTextColor(unpack(kit.C.btn))
    box.help:SetText(L.MYWHEEL_NAME_HELP)
    box:Hide()
    self.box = box
    return box
end

function MW:StartRename(id)
    local w = self:Get(id)
    if not w or CK:BlockedByCombat() then return end
    self.renaming = id
    local box = self:RenameBox()
    box:ClearAllPoints()
    local panel = CK.Config.frame
    if panel then box:SetPoint("TOP", panel, "TOP", 0, -60) else box:SetPoint("TOP", 0, -120) end
    box.edit:SetText(w.name)
    box:Show()
    box.edit:SetFocus()
    box.edit:HighlightText()
    -- The addon's keyboard takes the pad (the panel lets it go meanwhile)
    if CK.db.settings.modules.keyboard then
        CK.Config:UnbindPad()
        CK:OpenPrompt(L.MYWHEEL_NAME_PROMPT, w.name, function(text) MW:FinishRename(text) end, box.edit)
    end
    CK.Config:Render()
end

function MW:FinishRename(text)
    local id = self.renaming
    if not id then return end
    self.renaming = nil
    self.box.edit:ClearFocus()
    self.box:Hide()
    -- Confirmed with the field (Enter, A on the panel): the keyboard closes
    if CK.prompt then CK:FinishPrompt(false) end
    if text then self:Rename(id, text) end
    if CK.Config:IsOpen() then
        CK.Config:BindPad()
        CK.Config:Render()
    end
end

function MW:Init()
    self:UpdateBindingNames()
    -- The panel closed (B, combat) while a name was being typed: cancelled;
    -- it opens on the list of wheels next time
    hooksecurefunc(CK.Config, "Close", function()
        MW:FinishRename(nil)
        if MW.open then
            MW.open = false
            MW.Editor:Hide()
        end
    end)
end
