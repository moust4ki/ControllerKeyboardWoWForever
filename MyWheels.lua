local _, CK = ...
local L = CK.L

-- Module "my wheels": wheels of the player's own, drawn and handled like the
-- consumables wheel (ConsumableWheel.lua shows them all): 8 slots each, the
-- spells, items and macros the player picks, up to 8 wheels. Each has a key
-- of its own: the Gamepad tab's Items list (any button), or the game's Key
-- Bindings ("CLICK ControllerKeyboardMyWheelN"). Made, named and filled in
-- the Wheels tab, with the gamepad; names typed with the addon's keyboard or
-- a physical one.
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
-- The Wheels tab: the list of wheels, one open below its name (rename, its
-- 8 slots, delete), a slot's list open below it (Spells / Items / Macros)
---------------------------------------------------------------------------
local function iconMarkup(icon)
    if type(icon) == "table" then
        return icon.atlas and format("|A:%s:16:16|a ", icon.atlas) or ""
    end
    return format("|T%s:16:16|t ", tostring(icon or 134400))
end

function MW:AddRows(b)
    local list = self:List()
    b.header(L.MYWHEEL_H)
    b.info(L.MYWHEEL_INFO)
    for _, w in ipairs(list) do
        local open = self.editing == w.id
        b.button(format("%s %s  |cff9d9a8c(%d/%d)|r", open and "-" or "+", w.name, self:Count(w), SLOTS), function()
            self.editing = not open and w.id or nil
            self.picking, self.deleting = nil, nil
        end, nil, "wheel" .. w.id)
        if open then self:EditorRows(b, w) end
    end
    if #list < CK.ConsumableWheel.MY_MAX then
        b.button("+ " .. L.MYWHEEL_NEW, function()
            self.editing = self:Create()
            self.picking, self.deleting = nil, nil
            CK.Config:Page().selectKey = "rename"
        end)
    end
end

function MW:EditorRows(b, w)
    b.button(L.MYWHEEL_RENAME, function() self:StartRename(w.id) end, true, "rename")
    local positions = { strsplit(",", L.MYWHEEL_POS) }
    for i = 1, SLOTS do
        local action = w.slots[i]
        local text = action and (iconMarkup(CK.Mapping:ActionIcon(action)) .. (CK.Mapping:ActionName(action) or action))
            or ("|cff9d9a8c" .. L.MYWHEEL_EMPTY .. "|r")
        b.button(format("%s :  %s", positions[i] or i, text), function()
            if self.picking and self.picking.slot == i then
                self.picking = nil
            else
                self.picking = { slot = i, tab = self.picking and self.picking.tab or 1 }
                CK.Config:Page().selectKey = "list"
            end
        end, true, "slot" .. i)
        if self.picking and self.picking.slot == i then self:PickerRows(b, w, i) end
    end
    b.button(self.deleting == w.id and L.MYWHEEL_DELETE_CONFIRM or L.MYWHEEL_DELETE, function()
        if self.deleting == w.id then
            self.editing, self.deleting = nil, nil
            self:Delete(w.id)
        else
            self.deleting = w.id
        end
    end, true, "delete")
end

function MW:PickerRows(b, w, slot)
    local picking = self.picking
    b.choice(L.MYWHEEL_LIST, function() return L["MAP_TAB_" .. TABS[picking.tab]:upper()] end, function(d)
        picking.tab = (picking.tab - 1 + d) % #TABS + 1
    end, true, "list")
    if w.slots[slot] then
        b.button(L.MYWHEEL_CLEAR, function()
            self.picking = nil
            self:SetSlot(w.id, slot, nil)
            CK.Config:Page().selectKey = "slot" .. slot
        end, true)
    end
    local entries = CK.Mapping:Catalog(TABS[picking.tab], true)
    if #entries == 0 then b.info(L.MAP_NOTHING) end
    for _, e in ipairs(entries) do
        if e.header then
            b.info("|cffffd100" .. e.header .. "|r")
        else
            b.button(iconMarkup(e.icon) .. e.name, function()
                self.picking = nil
                self:SetSlot(w.id, slot, e.action)
                CK.Config:Page().selectKey = "slot" .. slot
            end, true)
        end
    end
end

-- The pad on the Wheels tab, before the list's own handling: B closes a
-- slot's list, then the open wheel; LB / RB change a slot's list
function MW:PagePress(page, name)
    if self.renaming then
        if name == "A" then self:FinishRename(self.box.edit:GetText())
        elseif name == "B" then self:FinishRename(nil) end
        return true
    end
    if self.picking and (name == "LB" or name == "RB") then
        self.picking.tab = (self.picking.tab - 1 + (name == "LB" and -1 or 1)) % #TABS + 1
        page.selectKey = "list"
        page:Refresh()
        return true
    end
    if name == "B" and (self.picking or self.editing) then
        if self.picking then
            page.selectKey = "slot" .. self.picking.slot
            self.picking = nil
        else
            page.selectKey = "wheel" .. self.editing
            self.editing, self.deleting = nil, nil
        end
        page:Refresh()
        return true
    end
end

function MW:PageHelp(g)
    if self.renaming then
        return { g("A") .. " " .. L.MAP_P_CHOOSE, g("B") .. " " .. L.MAP_P_BACK }
    end
    if self.picking then
        return {
            g("DPAD_UP") .. " " .. L.MAP_P_MOVE, g("A") .. " " .. L.MAP_P_CHOOSE,
            g("LB") .. g("RB") .. " " .. L.MAP_P_LIST, g("B") .. " " .. L.MAP_P_BACK,
        }
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
        CK.Config:Page().selectKey = "rename"
        CK.Config:Page():Refresh()
    end
end

function MW:Init()
    self:UpdateBindingNames()
    -- The panel closed (B, combat) while a name was being typed: cancelled
    hooksecurefunc(CK.Config, "Close", function() MW:FinishRename(nil) end)
end
