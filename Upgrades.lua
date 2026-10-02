local _, CK = ...

-- Module "better items": a green arrow at the bottom right of a bag item
-- that would be better than what is equipped in its slot. Better: a higher
-- item level, wearable by the character (no red line in its tooltip: armor
-- type, weapon skill, level, class), and of the class's main armor type, or
-- of the type already worn in that slot (no cloth for a warrior). Rings,
-- trinkets and one-hand weapons are compared with the weaker of the two.
-- A texture of ours on the bag buttons, like the quest items' border:
-- nothing written in the game's frames.
local U = {}
CK.Upgrades = U

local ARMOR = Enum and Enum.ItemClass and Enum.ItemClass.Armor or 4
local ARROW_ATLAS = "bags-greenarrow"

-- Where each kind of item goes (inventory slots)
local SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
    INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
    INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}
-- The slots where the armor type counts (a cloak is cloth for everyone)
local ARMOR_SLOTS = {
    INVTYPE_HEAD = true, INVTYPE_SHOULDER = true, INVTYPE_CHEST = true, INVTYPE_ROBE = true,
    INVTYPE_WAIST = true, INVTYPE_LEGS = true, INVTYPE_FEET = true, INVTYPE_WRIST = true, INVTYPE_HAND = true,
}
-- Each class's armor (cloth 1, leather 2, mail 3, plate 4): its first, then
-- from level 40 the heavier one it learns
local CLASS_ARMOR = {
    WARRIOR = { 3, 4 }, PALADIN = { 3, 4 }, HUNTER = { 2, 3 }, SHAMAN = { 2, 3 },
    ROGUE = { 2 }, DRUID = { 2 }, MONK = { 2 }, DEMONHUNTER = { 2 },
    MAGE = { 1 }, PRIEST = { 1 }, WARLOCK = { 1 }, DEATHKNIGHT = { 4 }, EVOKER = { 3 },
}

local function enabled()
    return CK.db and CK.db.settings.modules.upgrades
end

local function itemInfo(item)
    local get = C_Item and C_Item.GetItemInfo or GetItemInfo
    if get then return get(item) end
end

local function subclassOf(item)
    local get = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    return get and select(7, get(item))
end

local function itemLevel(link)
    if C_Item and C_Item.GetDetailedItemLevelInfo then
        local level = C_Item.GetDetailedItemLevelInfo(link)
        if level then return level end
    end
    return select(4, itemInfo(link)) or 0
end

local function mainArmor()
    local _, class = UnitClass("player")
    local list = CLASS_ARMOR[class]
    if not list then return nil end
    return (#list > 1 and (UnitLevel("player") or 1) >= 40) and list[2] or list[1]
end

local function isRed(r, g, b)
    return r and r > 0.9 and g < 0.2 and b < 0.2 or false
end

local function colorRed(color)
    if type(color) ~= "table" then return false end
    if color.GetRGB then return isRed(color:GetRGB()) end
    return isRed(color.r, color.g, color.b)
end

-- Wearable: the game writes in red what the character can't use
local scanner
local function wearable(bag, slot)
    if C_TooltipInfo and C_TooltipInfo.GetBagItem then
        local ok, data = pcall(C_TooltipInfo.GetBagItem, bag, slot)
        if ok and type(data) == "table" and data.lines then
            for _, line in ipairs(data.lines) do
                if colorRed(line.leftColor) or colorRed(line.rightColor) then return false end
            end
            return true
        end
    end
    -- An old client: a hidden tooltip of ours
    if not scanner then
        scanner = CreateFrame("GameTooltip", "ControllerKeyboardScanTooltip", nil, "GameTooltipTemplate")
    end
    scanner:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanner:ClearLines()
    scanner:SetBagItem(bag, slot)
    for i = 1, scanner:NumLines() or 0 do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G["ControllerKeyboardScanTooltip" .. side .. i]
            if fs and fs:IsShown() and fs:GetText() and isRed(fs:GetTextColor()) then return false end
        end
    end
    return true
end

-- Better than what is equipped there (and the item known: false, true when
-- the game hasn't sent its data yet)
function U:IsUpgrade(bag, slot, link)
    local name, _, _, _, reqLevel, _, _, _, equipLoc, _, _, classID, subclassID = itemInfo(link)
    if not name then return false, true end
    local slots = SLOTS[equipLoc]
    if not slots then return false end
    if (reqLevel or 0) > (UnitLevel("player") or 1) then return false end
    if equipLoc == "INVTYPE_WEAPON" and not (CanDualWield and CanDualWield()) then slots = { 16 } end
    -- The weaker of what is worn there (nothing: anything is better)
    local weakest, worn
    for _, s in ipairs(slots) do
        local equipped = GetInventoryItemLink("player", s)
        local level = equipped and itemLevel(equipped) or 0
        if not weakest or level < weakest then weakest, worn = level, equipped end
    end
    if classID == ARMOR and ARMOR_SLOTS[equipLoc] and subclassID and subclassID >= 1 and subclassID <= 4 then
        local wornType = worn and subclassOf(worn)
        if subclassID ~= mainArmor() and subclassID ~= wornType then return false end
    end
    if itemLevel(link) <= (weakest or 0) then return false end
    return wearable(bag, slot)
end

---------------------------------------------------------------------------
-- The arrows on the bag buttons
---------------------------------------------------------------------------
local arrows = setmetatable({}, { __mode = "k" })
U.arrows = arrows
local bagFrames = {}

local function arrowFor(button)
    local arrow = arrows[button]
    if not arrow then
        arrow = button:CreateTexture(nil, "OVERLAY", nil, 4)
        if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(ARROW_ATLAS) then
            arrow:SetAtlas(ARROW_ATLAS, true)
        else
            -- Our own triangle, pointing up, in green
            arrow:SetTexture("Interface\\AddOns\\EasyController\\textures\\ck_tri")
            arrow:SetTexCoord(0, 1, 1, 0)
            arrow:SetVertexColor(0.25, 1, 0.25)
            arrow:SetSize(14, 14)
        end
        arrow:SetPoint("BOTTOMRIGHT", -1, 1)
        arrows[button] = arrow
    end
    return arrow
end

function U:UpdateArrows(frame)
    if not (frame and frame.EnumerateValidItems and frame:IsShown()) then return end
    local on = enabled()
    local waiting = false
    for _, button in frame:EnumerateValidItems() do
        local bag, slot = button.GetBagID and button:GetBagID(), button:GetID()
        local link = on and bag and C_Container.GetContainerItemLink(bag, slot)
        local better, unknown = false, false
        if link then better, unknown = self:IsUpgrade(bag, slot, link) end
        waiting = waiting or unknown
        if better then
            arrowFor(button):Show()
        elseif arrows[button] then
            arrows[button]:Hide()
        end
    end
    self.waiting = waiting
end

function U:Refresh()
    for _, frame in ipairs(bagFrames) do self:UpdateArrows(frame) end
end

function U:HookBags()
    local frames = { ContainerFrameCombinedBags }
    for i = 1, NUM_TOTAL_BAG_FRAMES or 13 do frames[#frames + 1] = _G["ContainerFrame" .. i] end
    for _, frame in ipairs(frames) do
        if frame and frame.UpdateItems then
            bagFrames[#bagFrames + 1] = frame
            hooksecurefunc(frame, "UpdateItems", function(self) U:UpdateArrows(self) end)
        end
    end
end

function U:Init()
    self:HookBags()
    local f = CreateFrame("Frame")
    for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP",
        "GET_ITEM_INFO_RECEIVED", "SKILL_LINES_CHANGED" }) do
        pcall(f.RegisterEvent, f, event)
    end
    f:SetScript("OnEvent", function(_, event)
        -- An item's data arrived: only when one was missing
        if event == "GET_ITEM_INFO_RECEIVED" and not U.waiting then return end
        U:Refresh()
    end)
end
