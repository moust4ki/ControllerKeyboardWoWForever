local _, CK = ...
local L = CK.L

-- Module "consumables wheel": a key of its own (Gamepad tab, or the game's key
-- bindings) opens a wheel of up to 12 consumables from the bags: food, drink,
-- health and mana potions, healthstone, mana gem, bandages, buff food,
-- elixirs and flasks, scrolls. The right stick aims (or the D-pad turns the
-- selection), A uses, B closes; the mouse clicks a slot.
--
-- It works in combat: the wheel, its slots and the keys it takes while open
-- are secure frames and snippets run by the game (its restricted
-- environment), so a press does what a click of the player's would. The
-- items in the slots can only change out of combat (a rule of the game): the
-- wheel is filled from the bags then. The pictures (icons, counts, cooldowns,
-- the selection ring) are ours, drawn over it.
local W = {}
CK.ConsumableWheel = W

local MAX = 12
local RADIUS, SLOT = 132, 52
local AIM = 0.5     -- the stick aims past half its course

-- The wheel's kinds, in its order
W.CATEGORIES = { "food", "drink", "healthPotion", "manaPotion", "healthstone", "manaGem", "bandage",
    "buffFood", "elixir", "scroll" }
local CATEGORY_INDEX = {}
for i, c in ipairs(W.CATEGORIES) do CATEGORY_INDEX[c] = i end
-- Not usable in combat (the game's rule): greyed there
local OUT_OF_COMBAT = { food = true, drink = true, buffFood = true }

local HEALTHSTONES = {}
for _, id in ipairs({ 5512, 19004, 19005, 5511, 19006, 19007, 5509, 19008, 19009, 5510, 19010, 19011, 9421, 19012, 19013 }) do
    HEALTHSTONES[id] = true
end
local MANA_GEMS = { [5514] = true, [5513] = true, [8007] = true, [8008] = true }
-- The game's own spells, by ID: their names are in the client's language
local SPELL_FOOD, SPELL_DRINK, SPELL_WELL_FED, SPELL_FIRST_AID = 433, 430, 19705, 746

local function settings() return CK.db.settings.wheel end

---------------------------------------------------------------------------
-- What goes in the wheel
---------------------------------------------------------------------------
local spellNames
local function names()
    if not spellNames then
        local get = C_Spell and C_Spell.GetSpellName or function(id) return (GetSpellInfo(id)) end
        spellNames = { food = get(SPELL_FOOD), drink = get(SPELL_DRINK), wellFed = get(SPELL_WELL_FED),
            firstAid = get(SPELL_FIRST_AID) }
    end
    return spellNames
end

local function secret(v) return issecretvalue ~= nil and issecretvalue(v) or false end

local function tooltipText(id)
    if not (C_TooltipInfo and C_TooltipInfo.GetItemByID) then return "" end
    local ok, data = pcall(C_TooltipInfo.GetItemByID, id)
    local parts = {}
    if ok and type(data) == "table" and data.lines then
        for _, line in ipairs(data.lines) do
            local text = line.leftText
            if type(text) == "string" and not secret(text) then parts[#parts + 1] = text end
        end
    end
    return table.concat(parts, "\n"):lower()
end

-- The kind of an item, or nil (not for the wheel)
function W.Category(id)
    if HEALTHSTONES[id] then return "healthstone" end
    if MANA_GEMS[id] then return "manaGem" end
    local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(id)
    if classID ~= 0 then return nil end
    local spell = C_Item.GetItemSpell and C_Item.GetItemSpell(id)
    if not spell then return nil end
    local n = names()
    if subClassID == 7 or spell == n.firstAid then return "bandage" end
    if subClassID == 4 then return "scroll" end
    if subClassID == 2 or subClassID == 3 then return "elixir" end
    if subClassID == 5 or spell == n.food or spell == n.drink then
        if spell == n.drink then return "drink" end
        local text = tooltipText(id)
        if n.wellFed and text:find(n.wellFed:lower(), 1, true) then return "buffFood" end
        return "food"
    end
    local text = tooltipText(id)
    if text:find((MANA or "mana"):lower(), 1, true) then return "manaPotion" end
    if text:find((HEALTH or "health"):lower(), 1, true) then return "healthPotion" end
    if subClassID == 1 then return "elixir" end
end

-- The best first: required level, then item level
local function rank(id)
    local get = C_Item.GetItemInfo or GetItemInfo
    local _, _, _, itemLevel, minLevel = get(id)
    return (minLevel or 0) * 1000 + (itemLevel or 0)
end

-- { id, cat }: the best of each kind, then the other variants (an option),
-- at most 12, each next to its kind
function W:Scan()
    local s = settings()
    local byKind, seen = {}, {}
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local id = C_Container.GetContainerItemID(bag, slot)
            if id and not seen[id] then
                seen[id] = true
                local cat = W.Category(id)
                if cat and s.categories[cat] then
                    byKind[cat] = byKind[cat] or {}
                    table.insert(byKind[cat], { id = id, cat = cat, rank = rank(id) })
                end
            end
        end
    end
    local items = {}
    for _, cat in ipairs(W.CATEGORIES) do
        local list = byKind[cat]
        if list then
            table.sort(list, function(a, b) return a.rank > b.rank end)
            if #items < MAX then items[#items + 1] = list[1] end
        end
    end
    if s.variants then
        for _, cat in ipairs(W.CATEGORIES) do
            for i = 2, #(byKind[cat] or {}) do
                if #items < MAX then items[#items + 1] = byKind[cat][i] end
            end
        end
    end
    table.sort(items, function(a, b)
        if a.cat ~= b.cat then return CATEGORY_INDEX[a.cat] < CATEGORY_INDEX[b.cat] end
        return a.rank > b.rank
    end)
    return items
end

---------------------------------------------------------------------------
-- The secure part. The wheel frame owns the keys it takes while open (A,
-- B, the D-pad, with every modifier a trigger may add); its snippets read
-- the right stick from the game's gamepad state. Each slot direction is a
-- unit vector ("ck-x3", "ck-y3"): the aimed slot is the closest one.
---------------------------------------------------------------------------
local PREFIXES = ",SHIFT-,CTRL-,ALT-,CTRL-SHIFT-,ALT-SHIFT-,ALT-CTRL-,ALT-CTRL-SHIFT-,"

local OPEN = [[
    if owner:IsShown() then
        owner:Hide()
        owner:ClearBindings()
        return false
    end
    if (owner:GetAttribute("count") or 0) == 0 then return false end
    owner:Show()
    for prefix in gmatch(owner:GetAttribute("ck-prefixes"), "([^,]*),") do
        owner:SetBindingClick(true, prefix .. "PAD1", "ControllerKeyboardWheelUse")
        owner:SetBindingClick(true, prefix .. "PAD2", "ControllerKeyboardWheelClose")
        owner:SetBindingClick(true, prefix .. "PADDLEFT", "ControllerKeyboardWheelPrev")
        owner:SetBindingClick(true, prefix .. "PADDUP", "ControllerKeyboardWheelPrev")
        owner:SetBindingClick(true, prefix .. "PADDRIGHT", "ControllerKeyboardWheelNext")
        owner:SetBindingClick(true, prefix .. "PADDDOWN", "ControllerKeyboardWheelNext")
    end
    owner:SetBindingClick(true, "ESCAPE", "ControllerKeyboardWheelClose")
    return false
]]

local USE = [[
    if not down then return false end
    local count = owner:GetAttribute("count") or 0
    local slot = owner:GetAttribute("selected") or 1
    local state = GetGamePadState()
    local stick = state and state.sticks and state.sticks[owner:GetAttribute("ck-stick") or 2]
    if stick and stick.len and stick.len > ]] .. AIM .. [[ then
        local best, bestDot = nil, -2
        for i = 1, count do
            local dot = stick.x * (owner:GetAttribute("ck-x" .. i) or 0) + stick.y * (owner:GetAttribute("ck-y" .. i) or 0)
            if dot > bestDot then best, bestDot = i, dot end
        end
        slot = best or slot
    end
    if slot < 1 or slot > count then return false end
    owner:SetAttribute("selected", slot)
    return "s" .. slot, true
]]

-- After a use (A, or a click on a slot): the wheel closes
local DONE = [[
    owner:Hide()
    owner:ClearBindings()
]]

local CLOSE = DONE .. " return false"

local function turn(delta)
    return [[
        if not down then return false end
        local count = owner:GetAttribute("count") or 0
        if count == 0 then return false end
        owner:SetAttribute("selected", ((owner:GetAttribute("selected") or 1) - 1 + ]] .. delta .. [[) % count + 1)
        return false
    ]]
end

-- A button for the wheel's keys: a secure action button that does nothing
-- itself, its OnClick wrapped by the wheel
local function keyButton(name, wheel, pre, post, clicks)
    local b = CK.NewFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:RegisterForClicks(clicks or "AnyDown")
    b:SetAttribute("useOnKeyDown", true)
    b:Hide()
    SecureHandlerWrapScript(b, "OnClick", wheel, pre, post)
    return b
end

function W:Build()
    if self.frame then return end
    local wheel = CK.NewFrame("Frame", "ControllerKeyboardWheel", UIParent, "SecureHandlerBaseTemplate")
    wheel:SetSize((RADIUS + SLOT) * 2, (RADIUS + SLOT) * 2)
    wheel:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    wheel:SetFrameStrata("DIALOG")
    wheel:Hide()
    wheel:SetAttribute("count", 0)
    wheel:SetAttribute("selected", 1)
    wheel:SetAttribute("ck-prefixes", PREFIXES)
    self.frame = wheel

    -- The key that opens and closes it: acts on its release (a press on a
    -- shared paddle key comes as a click from the paddle's own button)
    self.toggle = keyButton("ControllerKeyboardWheelToggle", wheel, OPEN, nil, "AnyUp")
    local use = keyButton("ControllerKeyboardWheelUse", wheel, USE, DONE)
    use:SetAttribute("type", "click")
    self.use = use
    keyButton("ControllerKeyboardWheelClose", wheel, CLOSE)
    keyButton("ControllerKeyboardWheelPrev", wheel, turn(-1))
    keyButton("ControllerKeyboardWheelNext", wheel, turn(1))

    -- What is drawn: ours, under the slots' secure buttons
    local view = CK.NewFrame("Frame", nil, wheel)
    view:SetAllPoints()
    local bg = view:CreateTexture(nil, "BACKGROUND", nil, -6)
    bg:SetPoint("CENTER")
    bg:SetSize((RADIUS + SLOT * 0.75) * 2, (RADIUS + SLOT * 0.75) * 2)
    bg:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    bg:SetVertexColor(0, 0, 0, 0.55)
    view.ring = view:CreateTexture(nil, "OVERLAY", nil, 2)
    view.ring:SetSize(SLOT * 1.35, SLOT * 1.35)
    view.ring:SetTexture(CK.UIKit.TEX .. "ck_slot_glow")
    view.ring:SetBlendMode("ADD")
    view.ring:SetVertexColor(1, 0.82, 0.2)
    view.name = CK.UIKit.text(view, 15)
    view.name:SetPoint("CENTER", 0, 12)
    view.name:SetWidth(RADIUS * 1.5)
    view.name:SetTextColor(unpack(CK.UIKit.C.gold))
    view.count = CK.UIKit.text(view, 12)
    view.count:SetPoint("TOP", view.name, "BOTTOM", 0, -4)
    view.help = CK.UIKit.text(view, 11)
    view.help:SetPoint("TOP", view.count, "BOTTOM", 0, -10)
    view.help:SetTextColor(unpack(CK.UIKit.C.btn))
    view:SetScript("OnUpdate", function() W:Track() end)
    view:SetScript("OnShow", function() W:Paint() end)
    self.view = view

    self.slots, self.buttons = {}, {}
    for i = 1, MAX do
        local slot = CK.Paddles:CreateSlot(view, SLOT)
        slot:Hide()
        self.slots[i] = slot
        -- The slot's own secure button: clicked by A ("s3"), or by the mouse
        local b = CK.NewFrame("Button", "ControllerKeyboardWheelSlot" .. i, wheel, "SecureActionButtonTemplate")
        b:SetSize(SLOT, SLOT)
        b:RegisterForClicks("AnyUp")
        b:SetAttribute("useOnKeyDown", false)
        b:SetScript("OnEnter", function(self)
            local item = W.items and W.items[i]
            if not item then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(item.id)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        SecureHandlerWrapScript(b, "OnClick", wheel, "return nil, true", DONE)
        b:Hide()
        use:SetAttribute("*clickbutton-s" .. i, b)
        self.buttons[i] = b
    end
end

---------------------------------------------------------------------------
-- Filling it (out of combat only)
---------------------------------------------------------------------------
-- The right stick: the game names it "Camera"
local function cameraStick()
    local state = C_GamePad and C_GamePad.GetDeviceMappedState and C_GamePad.GetDeviceMappedState()
    if state and C_GamePad.StickIndexToConfigName then
        for i = 1, state.stickCount or 0 do
            if C_GamePad.StickIndexToConfigName(i - 1) == "Camera" then return i end
        end
    end
    return 2
end

function W:Fill()
    if not CK.db then return end
    if InCombatLockdown() then
        self.pending = true
        return
    end
    self.pending = nil
    self:Build()
    local s = settings()
    local items = s.enabled and self:Scan() or {}
    local wheel = self.frame
    local count = #items
    if wheel:IsShown() and count == 0 then
        wheel:Hide()
        ClearOverrideBindings(wheel)
    end
    for i = 1, MAX do
        local b, slot, item = self.buttons[i], self.slots[i], items[i]
        if item then
            local angle = (i - 1) * 2 * math.pi / count
            local x, y = math.sin(angle), math.cos(angle)
            b:ClearAllPoints()
            b:SetPoint("CENTER", wheel, "CENTER", x * RADIUS, y * RADIUS)
            slot:ClearAllPoints()
            slot:SetPoint("CENTER", wheel, "CENTER", x * RADIUS, y * RADIUS)
            wheel:SetAttribute("ck-x" .. i, x)
            wheel:SetAttribute("ck-y" .. i, y)
            b:SetAttribute("type", "item")
            b:SetAttribute("item", "item:" .. item.id)
            -- Bandages on yourself
            b:SetAttribute("unit", item.cat == "bandage" and "player" or nil)
            b:Show()
            slot:Show()
        else
            b:SetAttribute("type", nil)
            b:Hide()
            slot:Hide()
        end
    end
    wheel:SetAttribute("count", count)
    wheel:SetAttribute("ck-stick", cameraStick())
    if (wheel:GetAttribute("selected") or 1) > count then wheel:SetAttribute("selected", 1) end
    self.items = items
    self:Paint()
end

---------------------------------------------------------------------------
-- Drawing: icons, counts, cooldowns, greyed in combat; the ring on the
-- aimed slot (the stick) or the selected one (the D-pad)
---------------------------------------------------------------------------
function W:Paint()
    if not (self.frame and self.items) then return end
    local combat = InCombatLockdown()
    for i, item in ipairs(self.items) do
        local slot = self.slots[i]
        CK.Paddles.SetIcon(slot.icon, C_Item.GetItemIconByID(item.id))
        local count = C_Item.GetItemCount and C_Item.GetItemCount(item.id) or 0
        slot.count:SetText(count)
        slot.icon:SetDesaturated((combat and OUT_OF_COMBAT[item.cat]) or count == 0)
        pcall(function()
            local start, duration = C_Container.GetItemCooldown(item.id)
            if start and duration and duration > 0 then slot.cooldown:SetCooldown(start, duration) else slot.cooldown:Clear() end
        end)
    end
    local g = function(key) return CK:GlyphMarkup(key, 14) end
    self.view.help:SetText(format("%s %s   %s %s   %s %s", g("RS"), L.WHEEL_AIM, g("A"), L.WHEEL_USE, g("B"), L.WHEEL_CLOSE))
    self.aimed = nil
    self:Track()
end

function W:Aimed()
    local wheel = self.frame
    local count = #(self.items or {})
    local state = C_GamePad and C_GamePad.GetDeviceMappedState and C_GamePad.GetDeviceMappedState()
    local stick = state and state.sticks and state.sticks[wheel:GetAttribute("ck-stick") or 2]
    if stick and stick.len and stick.len > AIM and count > 0 then
        local best, bestDot = nil, -2
        for i = 1, count do
            local dot = stick.x * wheel:GetAttribute("ck-x" .. i) + stick.y * wheel:GetAttribute("ck-y" .. i)
            if dot > bestDot then best, bestDot = i, dot end
        end
        return best
    end
    return wheel:GetAttribute("selected") or 1
end

function W:Track()
    local i = self:Aimed()
    if i == self.aimed then return end
    self.aimed = i
    local item = self.items and self.items[i]
    local view = self.view
    view.ring:SetShown(item ~= nil)
    if not item then return end
    view.ring:ClearAllPoints()
    view.ring:SetPoint("CENTER", self.slots[i], "CENTER")
    view.name:SetText(C_Item.GetItemNameByID(item.id) or "")
    view.count:SetText(L["WHEEL_CAT_" .. item.cat:upper()])
    if CK.Vibration then CK.Vibration:Fire("wheelTick") end
end

-- The action the Gamepad tab puts on an input: its key opens the wheel
function W:Toggle()
    self:Build()
    return self.toggle
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
function W:Init()
    self:Build()
    local f = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "PLAYER_REGEN_ENABLED",
        "PLAYER_REGEN_DISABLED", "BAG_UPDATE_COOLDOWN", "GET_ITEM_INFO_RECEIVED" }) do
        pcall(f.RegisterEvent, f, event)
    end
    local queued
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" or event == "BAG_UPDATE_COOLDOWN" then
            W:Paint()
            return
        end
        if event == "PLAYER_REGEN_ENABLED" and not W.pending then
            W:Paint()
            return
        end
        if queued then return end
        queued = true
        C_Timer.After(0.2, function()
            queued = false
            if InCombatLockdown() then
                W.pending = true
                W:Paint()
            else
                W:Fill()
            end
        end)
    end)
    self:Fill()
end
