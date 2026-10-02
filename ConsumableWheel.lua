local _, CK = ...
local L = CK.L

-- Module "consumables wheel": a key of its own (Gamepad tab, or the game's key
-- bindings) opens a wheel of consumables from the bags, drawn like the game's
-- own radial menu (its wheel, its highlight, its veil), the aimed item and the
-- help in its middle: 8 per page, LB / RB
-- turn the pages (up to 3). Food, drink,
-- health and mana potions, healthstone, mana gem, bandages, buff food,
-- elixirs and flasks, scrolls. Its key opens it, the left stick chooses (the
-- choice stays when it goes back to the middle; the right stick is the
-- game's, for its own wheels), A uses, B cancels; the D-pad and the
-- mouse work too. While it is open it takes the sticks, like the game's own
-- wheels: the camera and the character stay still. In the middle of the
-- screen (or placed with the mouse or the D-pad).
--
-- Secure code only acts on keys: A reads the left stick from the game's
-- gamepad state. The choice stays when the stick goes back to the middle:
-- noted by our drawing code out of combat, and in combat by the left
-- stick's direction keys, which the game sends while the wheel is open
-- (its GamePadStickAxisButtons setting, on only then).
--
-- It works in combat: the wheel, its slots and the keys it takes while open
-- are secure frames and snippets run by the game (its restricted
-- environment), so a press does what a click of the player's would. The
-- items in the slots can only change out of combat (a rule of the game): the
-- wheel is filled from the bags then. The pictures (icons, counts, cooldowns,
-- the selection ring) are ours, drawn over it.
local W = {}
CK.ConsumableWheel = W

local SEGMENTS, PAGES = 8, 3
local MAX = SEGMENTS * PAGES
local AIM = 0.5     -- the stick aims past half its course
-- The game's radial menu: its segments' centers (150 from the middle), the
-- icons drawn a little closer in, the names further out
local DISTANCE, ICON_RADIUS, SLOT = 150, 110, 46
-- The names, further out than the icons ({ distance from the middle, width }):
-- beside the icon for the left and right segments, above / below otherwise
local LABEL = {
    { 180, 70 }, { 178, 92 }, { 180, 112 }, { 178, 92 }, { 180, 70 }, { 178, 92 }, { 180, 112 }, { 178, 92 },
}
-- The banner under the wheel, sized for its two lines
local BANNER_W, BANNER_H = 360, 64
-- Our slots go clockwise from the top; the game numbers its segments
-- anticlockwise from the right (1 east, 3 north)
local function segmentOf(slot) return (3 - slot) % SEGMENTS + 1 end
local function angleOf(slot) return math.rad((segmentOf(slot) - 1) * 45) end

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
    local spell = C_Item.GetItemSpell and C_Item.GetItemSpell(id)
    local n = names()
    -- Bandages: by their First Aid spell, whatever class the client gives them
    if (spell and spell == n.firstAid) or (classID == 0 and subClassID == 7) then return "bandage" end
    if classID ~= 0 then return nil end
    if not spell then return nil end
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
    if subClassID == 1 or subClassID == 13 then return "elixir" end
end

-- Why an item of the bags is not in the wheel (for /ec wheel), or nil
function W.Reason(id)
    local cat = W.Category(id)
    if not cat then
        local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(id)
        local spell = C_Item.GetItemSpell and C_Item.GetItemSpell(id)
        return format("- (class %s/%s, use: %s)", tostring(classID), tostring(subClassID), tostring(spell))
    end
    if not settings().categories[cat] then return cat .. ": " .. L.WHEEL_DIAG_OFF end
    local get = C_Item.GetItemInfo or GetItemInfo
    local _, _, _, _, minLevel = get(id)
    if minLevel and minLevel > (UnitLevel("player") or 0) then return cat .. ": " .. format(L.WHEEL_DIAG_LEVEL, minLevel) end
    return nil, cat
end

---------------------------------------------------------------------------
-- The sticks while the wheel is open, and just after
---------------------------------------------------------------------------
function W:TakeSticks(frame, on)
    if frame.EnableGamePadStick then pcall(frame.EnableGamePadStick, frame, on) end
end

-- A plain frame that keeps the sticks after the wheel closes, until they
-- are back near the middle (at most 6 seconds)
function W:BuildHold()
    local hold = CK.NewFrame("Frame", nil, UIParent)
    hold:SetAllPoints(UIParent)
    hold:Hide()
    hold.lens, hold.elapsed = {}, 0
    hold:SetScript("OnGamePadStick", function(self, stick, x, y, len)
        self.lens[stick] = len or math.sqrt((x or 0) ^ 2 + (y or 0) ^ 2)
        local longest = 0
        for _, value in pairs(self.lens) do longest = math.max(longest, value) end
        if longest < 0.2 then self:Hide() end
    end)
    hold:SetScript("OnShow", function(self)
        self.lens, self.elapsed = {}, 0
        W:TakeSticks(self, true)
    end)
    hold:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed > 6 then self:Hide() end
    end)
    self.hold = hold
end

function W:HoldSticks()
    local state = C_GamePad and C_GamePad.GetDeviceMappedState and C_GamePad.GetDeviceMappedState()
    for _, stick in ipairs(state and state.sticks or {}) do
        if (stick.len or 0) >= 0.2 then
            self.hold:Show()
            return
        end
    end
end

-- What happened on the last openings and presses, for /ec wheel
local log = {}
function W:Log(what)
    local view, wheel = self.view, self.frame
    local state = C_GamePad and C_GamePad.GetDeviceMappedState and C_GamePad.GetDeviceMappedState()
    local stick = state and state.sticks and state.sticks[wheel and wheel:GetAttribute("ck-stick") or 1]
    local taken = view and view.IsGamePadStickEnabled and view:IsGamePadStickEnabled()
    log[#log + 1] = format("%s: %s, combat %s, sticks taken %s, left stick %.2f, A = %s, aimed %s",
        date("%H:%M:%S"), what, tostring(InCombatLockdown()), tostring(taken), stick and stick.len or 0,
        tostring(GetBindingAction("PAD1", true)), tostring(self.aimed))
    while #log > 8 do table.remove(log, 1) end
end

-- /ec wheel: what is in it, what is not and why
function W:Diagnose()
    local wheel = self.frame
    CK:Print(L.WHEEL_DIAG, wheel and wheel:GetAttribute("ck-total") or 0, wheel and wheel:GetAttribute("ck-pages") or 0,
        tostring(settings().enabled), tostring(InCombatLockdown()), tostring(self.pending or false))
    local seen = {}
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local id = C_Container.GetContainerItemID(bag, slot)
            if id and not seen[id] then
                seen[id] = true
                local why, cat = W.Reason(id)
                local name = C_Item.GetItemNameByID(id) or ("item:" .. id)
                if cat then
                    DEFAULT_CHAT_FRAME:AddMessage(format("  |cff40ff40+|r %s: %s", name, L["WHEEL_CAT_" .. cat:upper()]))
                elseif not why:find("^%- %(class 7") and not why:find("^%- %(class [1-9]%d*/") then
                    DEFAULT_CHAT_FRAME:AddMessage(format("  |cff9d9a8c-|r %s %s", name, why))
                end
            end
        end
    end
    for _, line in ipairs(log) do DEFAULT_CHAT_FRAME:AddMessage("  |cff9d9a8c" .. line .. "|r") end
end

-- The best first: required level, then item level
-- The best first: required level, then item level. Nil for an item above
-- the player's level (the game won't let it be used)
local function rank(id)
    local get = C_Item.GetItemInfo or GetItemInfo
    local _, _, _, itemLevel, minLevel = get(id)
    if minLevel and minLevel > (UnitLevel("player") or 0) then return nil end
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
                local value = cat and s.categories[cat] and rank(id)
                if value then
                    byKind[cat] = byKind[cat] or {}
                    table.insert(byKind[cat], { id = id, cat = cat, rank = value })
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
-- B, LB / RB, with every modifier a trigger may add); its snippets read the
-- left stick from the game's gamepad state when A is pressed. Each slot
-- direction is a unit vector ("ck-x3", "ck-y3"): the aimed slot is the
-- closest one. Nothing is remembered: the stick back in the middle aims at
-- nothing.
---------------------------------------------------------------------------
local PREFIXES = ",SHIFT-,CTRL-,ALT-,CTRL-SHIFT-,ALT-SHIFT-,ALT-CTRL-,ALT-CTRL-SHIFT-,"

-- A page's items into the 8 slots' buttons (from the wheel's attributes:
-- "ck-p2-5" is page 2, slot 5)
local APPLY_PAGE = [[
    local page = owner:GetAttribute("page") or 1
    owner:SetAttribute("count", owner:GetAttribute("ck-count-p" .. page) or 0)
    for i = 1, 8 do
        local b = owner:GetFrameRef("slot" .. i)
        local item = owner:GetAttribute("ck-p" .. page .. "-" .. i)
        b:SetAttribute("type", item and "item" or nil)
        b:SetAttribute("item", item)
        b:SetAttribute("unit", owner:GetAttribute("ck-u" .. page .. "-" .. i))
        if item then b:Show() else b:Hide() end
    end
]]

-- LB / RB: the previous or next page
local PAGE = [[
    if not down then return false end
    local pages = owner:GetAttribute("ck-pages") or 1
    if pages < 2 then return false end
    owner:SetAttribute("page", ((owner:GetAttribute("page") or 1) - 1 + (button == "LB" and -1 or 1)) % pages + 1)
    ]] .. APPLY_PAGE .. [[
    return false
]]

-- `slot`: the slot the left stick points at now (past half its course), else 0
local AIMED = [[
    local count = owner:GetAttribute("count") or 0
    local slot = 0
    local state = GetGamePadState()
    local stick = state and state.sticks and state.sticks[owner:GetAttribute("ck-stick") or 1]
    if stick and stick.len and stick.len > ]] .. AIM .. [[ then
        local bestDot = -2
        for i = 1, 8 do
            local dot = stick.x * (owner:GetAttribute("ck-x" .. i) or 0) + stick.y * (owner:GetAttribute("ck-y" .. i) or 0)
            if dot > bestDot then slot, bestDot = i, dot end
        end
    end
    if slot > count then slot = 0 end
]]

-- Opening: shown, the sticks taken from the camera and the character (like
-- the game's own wheels), the keys it uses taken while it is open
local SHOW = [[
    owner:SetAttribute("page", 1)
    ]] .. APPLY_PAGE .. [[
    owner:Show()
    for prefix in gmatch(owner:GetAttribute("ck-prefixes"), "([^,]*),") do
        owner:SetBindingClick(true, prefix .. "PAD1", "ControllerKeyboardWheelUse")
        owner:SetBindingClick(true, prefix .. "PAD2", "ControllerKeyboardWheelClose")
        owner:SetBindingClick(true, prefix .. "PADLSHOULDER", "ControllerKeyboardWheelPage", "LB")
        owner:SetBindingClick(true, prefix .. "PADRSHOULDER", "ControllerKeyboardWheelPage", "RB")
    end
    owner:SetBindingClick(true, "ESCAPE", "ControllerKeyboardWheelClose")
]]

local HIDE = [[
    owner:Hide()
    owner:ClearBindings()
]]

-- The wheel's key: opens or closes it, on its press (a key bound to it
-- sends a press and a release: the release is let pass; a shared paddle
-- key sends one click, no press: that click counts)
local TOGGLE = [[
    if not down and owner:GetAttribute("ck-down") then
        owner:SetAttribute("ck-down", false)
        return false
    end
    owner:SetAttribute("ck-down", down and true or false)
    if owner:IsShown() then
        ]] .. HIDE .. [[
    elseif (owner:GetAttribute("ck-total") or 0) > 0 then
        ]] .. SHOW .. [[
    end
    return false
]]

-- A: the item the left stick points at; the stick in the middle: nothing
local USE = [[
    if not down then return false end
    ]] .. AIMED .. [[
    if slot < 1 then return false end
    return "s" .. slot, true
]]

-- After a use (A, or a click on a slot): the wheel closes
local DONE = HIDE

local CLOSE = HIDE .. " return false"

-- A button for the wheel's keys: a secure action button, its OnClick
-- wrapped by the wheel
local function keyButton(name, wheel, pre, post, ...)
    local b = CK.NewFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    if ... then b:RegisterForClicks(...) else b:RegisterForClicks("AnyDown") end
    b:SetAttribute("useOnKeyDown", true)
    b:Hide()
    SecureHandlerWrapScript(b, "OnClick", wheel, pre, post)
    return b
end

local function atlas(texture, name, fallback)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) then
        texture:SetAtlas(name, true)
        return true
    end
    if fallback then fallback(texture) end
end

function W:Build()
    if self.frame then return end
    local wheel = CK.NewFrame("Frame", "ControllerKeyboardWheel", UIParent, "SecureHandlerBaseTemplate")
    wheel:SetSize(480, 600)
    wheel:SetFrameStrata("DIALOG")
    wheel:Hide()
    wheel:SetAttribute("count", 0)
    wheel:SetAttribute("ck-total", 0)
    wheel:SetAttribute("page", 1)
    wheel:SetMovable(true)
    wheel:SetClampedToScreen(true)
    wheel:EnableMouse(true)
    wheel:RegisterForDrag("LeftButton")
    wheel:SetScript("OnDragStart", function(self)
        if not settings().locked and not InCombatLockdown() then self:StartMoving() end
    end)
    wheel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        W:SavePosition()
    end)
    wheel:SetAttribute("ck-prefixes", PREFIXES)
    -- Each slot's direction, from the middle
    for i = 1, SEGMENTS do
        wheel:SetAttribute("ck-x" .. i, math.cos(angleOf(i)))
        wheel:SetAttribute("ck-y" .. i, math.sin(angleOf(i)))
    end
    self.frame = wheel
    self:Place()

    -- The wheel's key: its press (and a shared paddle key's single click)
    local toggle = keyButton("ControllerKeyboardWheelToggle", wheel, TOGGLE, nil, "AnyDown", "AnyUp")
    self.toggle = toggle
    local use = keyButton("ControllerKeyboardWheelUse", wheel, USE, DONE)
    use:SetAttribute("type", "click")
    use:HookScript("OnClick", function(_, _, down) if down ~= false then W:Log("A") end end)
    self.use = use
    keyButton("ControllerKeyboardWheelClose", wheel, CLOSE)
    -- The stick direction keys: their presses and releases move the choice

    keyButton("ControllerKeyboardWheelPage", wheel, PAGE)

    -- What is drawn: the game's radial menu art, under the slots' buttons
    local view = CK.NewFrame("Frame", nil, wheel)
    view:SetAllPoints()
    self.view = view
    -- The sticks: taken by this plain frame of ours while it shows (with the
    -- wheel), like the game's own wheels, so the character and the camera
    -- don't move (and food can be eaten: not while moving). Turned on each
    -- time it shows; its stick script is needed for the game to give it them.
    view:SetScript("OnGamePadStick", function() W:Track() end)
    local bg = view:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("CENTER")
    atlas(bg, "gamepad-radial-menu-wheelbg", function(t)
        t:SetSize(440, 440)
        t:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        t:SetVertexColor(0, 0, 0, 0.7)
    end)
    view.bg = bg
    -- The aimed segment
    view.highlight = view:CreateTexture(nil, "BORDER")
    atlas(view.highlight, "gamepad-radial-menu-selected", function(t)
        t:SetSize(SLOT * 1.6, SLOT * 1.6)
        t:SetTexture(CK.UIKit.TEX .. "ck_slot_glow")
        t:SetBlendMode("ADD")
    end)
    view.highlight:Hide()
    -- Under the wheel, the game's banner: the aimed item (or what to do);
    -- below it, the pages and the help
    view.bottom = view:CreateTexture(nil, "BACKGROUND")
    view.bottom:SetPoint("TOP", bg, "BOTTOM", 0, 8)
    atlas(view.bottom, "gamepad-radial-menu-bottomtext", function(t)
        t:SetColorTexture(0, 0, 0, 0.5)
    end)
    view.bottom:SetSize(BANNER_W, BANNER_H)
    view.name = view:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    view.name:SetPoint("TOP", view.bottom, "TOP", 0, -12)
    view.name:SetWidth(BANNER_W - 30)
    view.name:SetWordWrap(false)
    view.count = view:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    view.count:SetPoint("TOP", view.name, "BOTTOM", 0, -4)
    view.count:SetWidth(BANNER_W - 30)
    view.count:SetWordWrap(false)
    view.help = view:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.help:SetPoint("TOP", view.bottom, "BOTTOM", 0, -4)
    view.pages = view:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.pages:SetPoint("TOP", view.help, "BOTTOM", 0, -4)
    view:SetScript("OnUpdate", function() W:Track() end)
    view:SetScript("OnShow", function()
        W:TakeSticks(view, true)
        W.hold:Hide()
        W:Paint()
        W:Log("open")
    end)
    -- Closed with a stick still pushed: held until it is let go, so the
    -- character doesn't walk off (or stand up from eating)
    view:SetScript("OnHide", function() W:HoldSticks() end)
    self:BuildHold()

    self.segments, self.buttons = {}, {}
    for i = 1, SEGMENTS do
        local angle = angleOf(i)
        local cx, cy = DISTANCE * math.cos(angle), DISTANCE * math.sin(angle)
        local seg = {}
        -- The game's grey veil over a segment that can't be used
        seg.disabled = view:CreateTexture(nil, "ARTWORK", nil, 2)
        seg.disabled:SetPoint("CENTER", bg, "CENTER", cx, cy)
        atlas(seg.disabled, "gamepad-radial-menu-disabled")
        seg.disabled:SetRotation(angle - math.rad(270))
        seg.disabled:Hide()
        seg.highlightPoint = { cx, cy, angle - math.rad(270) }
        -- The item: a round slot of the gamepad bar's, its name further out
        local ix, iy = ICON_RADIUS * math.cos(angle), ICON_RADIUS * math.sin(angle)
        seg.slot = CK.Paddles:CreateSlot(view, SLOT)
        seg.slot:SetPoint("CENTER", bg, "CENTER", ix, iy)
        seg.slot:Hide()
        local label = LABEL[segmentOf(i)]
        seg.label = view:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        seg.label:SetSize(label[2], 36)
        seg.label:SetWordWrap(true)
        seg.label:SetPoint("CENTER", bg, "CENTER", label[1] * math.cos(angle), label[1] * math.sin(angle))
        self.segments[i] = seg
        -- The slot's own secure button: clicked by a stick, A, the key ("s3"),
        -- or the mouse
        local b = CK.NewFrame("Button", "ControllerKeyboardWheelSlot" .. i, wheel, "SecureActionButtonTemplate")
        b:SetSize(SLOT + 14, SLOT + 14)
        -- On the wheel frame (the background's center): a protected frame can't
        -- be anchored to a texture
        b:SetPoint("CENTER", wheel, "CENTER", ix, iy)
        b:RegisterForClicks("AnyUp")
        b:SetAttribute("useOnKeyDown", false)
        b:SetScript("OnEnter", function(self)
            local item = W:PageItems()[i]
            if not item then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(item.id)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        SecureHandlerWrapScript(b, "OnClick", wheel, "return nil, true", DONE)
        b:HookScript("OnClick", function() W:Log("use " .. i) end)
        b:Hide()
        SecureHandlerSetFrameRef(wheel, "slot" .. i, b)
        use:SetAttribute("*clickbutton-s" .. i, b)

        self.buttons[i] = b
    end
end

---------------------------------------------------------------------------
-- Filling it (out of combat only): the items by page, in the wheel's
-- attributes, and page 1 in the slots' buttons
---------------------------------------------------------------------------
-- The game names its sticks: "Movement" (left), "Camera" (right)
local function stickIndex(name, default)
    local state = C_GamePad and C_GamePad.GetDeviceMappedState and C_GamePad.GetDeviceMappedState()
    if state and C_GamePad.StickIndexToConfigName then
        for i = 1, state.stickCount or 0 do
            if C_GamePad.StickIndexToConfigName(i - 1) == name then return i end
        end
    end
    return default
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
    if wheel:IsShown() and #items == 0 then
        wheel:Hide()
        ClearOverrideBindings(wheel)
    end
    local pages = math.max(1, math.ceil(#items / SEGMENTS))
    self.pages = {}
    for page = 1, PAGES do
        local list = {}
        for i = 1, SEGMENTS do
            local item = page <= pages and items[(page - 1) * SEGMENTS + i] or nil
            list[i] = item
            wheel:SetAttribute("ck-p" .. page .. "-" .. i, item and ("item:" .. item.id) or nil)
            -- Bandages on yourself
            wheel:SetAttribute("ck-u" .. page .. "-" .. i, item and item.cat == "bandage" and "player" or nil)
        end
        wheel:SetAttribute("ck-count-p" .. page, math.max(0, math.min(SEGMENTS, #items - (page - 1) * SEGMENTS)))
        self.pages[page] = list
    end
    wheel:SetAttribute("ck-pages", pages)
    wheel:SetAttribute("ck-total", #items)
    wheel:SetAttribute("ck-stick", stickIndex("Movement", 1))
    if not wheel:IsShown() then
        -- Page 1 in the buttons, as the snippet does
        wheel:SetAttribute("page", 1)
        wheel:SetAttribute("count", wheel:GetAttribute("ck-count-p1"))
        for i, b in ipairs(self.buttons) do
            local item = wheel:GetAttribute("ck-p1-" .. i)
            b:SetAttribute("type", item and "item" or nil)
            b:SetAttribute("item", item)
            b:SetAttribute("unit", wheel:GetAttribute("ck-u1-" .. i))
            b:SetShown(item ~= nil)
        end
    end
    self.items = items
    self:Paint()
end

function W:PageItems()
    local page = self.frame and self.frame:GetAttribute("page") or 1
    return self.pages and self.pages[page] or {}
end

---------------------------------------------------------------------------
-- Drawing: the page's items (icons, names, counts, cooldowns, the veil on
-- what can't be used now), the pages' dots, the highlight on the aimed
-- segment (a stick, or the D-pad's choice), the aimed item's name
---------------------------------------------------------------------------
function W:Paint()
    if not (self.frame and self.pages) then return end
    local combat = InCombatLockdown()
    local page = self.frame:GetAttribute("page") or 1
    self.painted = page
    local list = self:PageItems()
    for i, seg in ipairs(self.segments) do
        local item = list[i]
        seg.slot:SetShown(item ~= nil)
        seg.label:SetShown(item ~= nil)
        if item then
            CK.Paddles.SetIcon(seg.slot.icon, C_Item.GetItemIconByID(item.id))
            local count = C_Item.GetItemCount and C_Item.GetItemCount(item.id) or 0
            seg.slot.count:SetText(count)
            seg.label:SetText(C_Item.GetItemNameByID(item.id) or "")
            local unusable = (combat and OUT_OF_COMBAT[item.cat]) or count == 0
            seg.slot.icon:SetDesaturated(unusable)
            seg.disabled:SetShown(unusable)
            pcall(function()
                local start, duration = C_Container.GetItemCooldown(item.id)
                if start and duration and duration > 0 then
                    seg.slot.cooldown:SetCooldown(start, duration)
                else
                    seg.slot.cooldown:Clear()
                end
            end)
        else
            seg.disabled:Hide()
        end
    end
    -- LB  o * o  RB, with more than one page
    local pages = self.frame:GetAttribute("ck-pages") or 1
    local g = function(key) return CK:GlyphMarkup(key, 14) end
    if pages > 1 then
        local dots = {}
        for p = 1, pages do
            dots[#dots + 1] = format("|A:gamepad-radialgamemenu-cursorbg-%s:11:11|a", p == page and "neutral" or "inactive")
        end
        self.view.pages:SetText(g("LB") .. " " .. table.concat(dots, " ") .. " " .. g("RB"))
    else
        self.view.pages:SetText("")
    end
    local h = function(key) return CK:GlyphMarkup(key, 14) end
    self.view.help:SetText(format("%s %s   %s %s   %s %s", h("LS"), L.WHEEL_AIM, h("A"), L.WHEEL_USE, h("B"), L.WHEEL_CLOSE))
    self.aimed = nil
    self:Track()
end

function W:Aimed()
    local wheel = self.frame
    local count = wheel:GetAttribute("count") or 0
    local state = C_GamePad and C_GamePad.GetDeviceMappedState and C_GamePad.GetDeviceMappedState()
    local stick = state and state.sticks and state.sticks[wheel:GetAttribute("ck-stick") or 1]
    if stick and stick.len and stick.len > AIM then
        local best, bestDot = nil, -2
        for i = 1, SEGMENTS do
            local dot = stick.x * wheel:GetAttribute("ck-x" .. i) + stick.y * wheel:GetAttribute("ck-y" .. i)
            if dot > bestDot then best, bestDot = i, dot end
        end
        return best and best <= count and best or nil
    end
end

function W:Track()
    if not self.frame then return end
    -- A page turned (LB / RB, secure): draw it
    if (self.frame:GetAttribute("page") or 1) ~= self.painted then return self:Paint() end
    local i = self:Aimed()
    if i == self.aimed then return end
    self.aimed = i
    local item = i and self:PageItems()[i]
    local view = self.view
    view.highlight:SetShown(item ~= nil)
    if not item then
        view.name:SetText(L.WHEEL_NOTHING)
        view.count:SetText(L.WHEEL_NOTHING_HINT)
        return
    end
    local point = self.segments[i].highlightPoint
    view.highlight:ClearAllPoints()
    view.highlight:SetPoint("CENTER", view.bg, "CENTER", point[1], point[2])
    view.highlight:SetRotation(point[3])
    view.name:SetText(C_Item.GetItemNameByID(item.id) or "")
    local count = C_Item.GetItemCount and C_Item.GetItemCount(item.id) or 0
    view.count:SetText(format("%s  -  %d", L["WHEEL_CAT_" .. item.cat:upper()], count))
    if CK.Vibration then CK.Vibration:Fire("wheelTick") end
end

---------------------------------------------------------------------------
-- Its place: the middle of the screen, or where it was put (the mouse while
-- unlocked, or the D-pad from the Wheel tab; out of combat)
---------------------------------------------------------------------------
function W:Place()
    local pos = settings().pos
    local wheel = self.frame
    wheel:ClearAllPoints()
    if type(pos) == "table" and pos.point then
        wheel:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    else
        wheel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function W:SavePosition()
    local point, _, _, x, y = self.frame:GetPoint(1)
    settings().pos = { point = point, x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
end

function W:ResetPosition()
    settings().pos = nil
    if self.frame and not InCombatLockdown() then self:Place() end
end

local MOVES = { UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 } }

function W:StartPlacement()
    if InCombatLockdown() then return end
    self:Build()
    self.moving = true
    if not self.banner then
        local banner = CK.NewFrame("Frame", nil, UIParent)
        banner:SetSize(560, 58)
        banner:SetPoint("TOP", 0, -90)
        banner:SetFrameStrata("FULLSCREEN_DIALOG")
        CK.Config.panel(banner)
        banner.title = CK.UIKit.text(banner, 14)
        banner.title:SetPoint("TOP", 0, -10)
        banner.title:SetTextColor(unpack(CK.UIKit.C.gold))
        banner.title:SetText(L.WHEEL_MOVE)
        banner.help = CK.UIKit.text(banner, 11)
        banner.help:SetPoint("BOTTOM", 0, 10)
        banner.help:SetTextColor(unpack(CK.UIKit.C.btn))
        self.banner = banner
    end
    local g = function(key) return CK:GlyphMarkup(key, 16) end
    self.banner.help:SetText(table.concat({
        g("DPAD_UP") .. " " .. L.MAP_P_MOVE, g("X") .. " " .. L.PLACE_P_RESET, g("A") .. g("B") .. " " .. L.PLACE_P_DONE,
    }, "    "))
    self.banner:Show()
    self.frame:Show()
end

function W:StopPlacement()
    if not self.moving then return end
    self.moving = false
    if self.banner then self.banner:Hide() end
    if not InCombatLockdown() then
        self.frame:Hide()
        ClearOverrideBindings(self.frame)
    end
end

function W:PlacementPress(name)
    if InCombatLockdown() then return end
    if MOVES[name] then
        local point, _, _, x, y = self.frame:GetPoint(1)
        self.frame:ClearAllPoints()
        self.frame:SetPoint(point, UIParent, point, x + MOVES[name][1] * 10, y + MOVES[name][2] * 10)
        self:SavePosition()
    elseif name == "X" then
        self:ResetPosition()
    elseif name == "A" or name == "B" then
        self:StopPlacement()
        CK.Config:EndPlacement()
    end
end

---------------------------------------------------------------------------
-- Game settings earlier versions changed, given back as they were: the
-- stick direction keys (GamePadStickAxisButtons: kept on, they broke the
-- game's own stick wheels) and the camera speeds
---------------------------------------------------------------------------
local function setCVar(name, value)
    local set = C_CVar and C_CVar.SetCVar or SetCVar
    return pcall(set, name, value)
end

function W:RestoreSettings()
    if InCombatLockdown() then return end
    local s = settings()
    if s.stickButtonsWas ~= nil then
        setCVar("GamePadStickAxisButtons", s.stickButtonsWas)
        s.stickButtonsWas = nil
    end
    if s.camera then
        for cvar, value in pairs(s.camera) do setCVar(cvar, value) end
        s.camera = nil
    end
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
    self:RestoreSettings()
    self:Build()
    local f = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "PLAYER_REGEN_ENABLED", "PLAYER_LEVEL_UP",
        "PLAYER_REGEN_DISABLED", "BAG_UPDATE_COOLDOWN", "GET_ITEM_INFO_RECEIVED" }) do
        pcall(f.RegisterEvent, f, event)
    end
    local queued
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" or event == "BAG_UPDATE_COOLDOWN" then
            W:Paint()
            return
        end
        if event == "PLAYER_REGEN_ENABLED" then W:RestoreSettings() end
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
