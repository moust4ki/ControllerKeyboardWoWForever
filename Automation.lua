local _, CK = ...
local L = CK.L

-- Module "automation": at a merchant, the grey (poor quality) items of the
-- bags are sold by themselves, then the equipment is repaired (with the
-- guild's money first when the guild allows it and the player wants it).
-- Only the game's own merchant functions, out of combat; a line in the chat
-- says what it brought and what it cost.
local A = {}
CK.Automation = A

local POOR = Enum and Enum.ItemQuality and Enum.ItemQuality.Poor or 0
-- One sale at a time: the server takes them in turn
local SELL_GAP = 0.15

local function settings() return CK.db.settings end

local function money(amount)
    if GetCoinTextureString then return GetCoinTextureString(amount) end
    return format("%dg %ds %dc", math.floor(amount / 10000), math.floor(amount / 100) % 100, amount % 100)
end

local function itemPrice(item)
    local get = C_Item and C_Item.GetItemInfo or GetItemInfo
    return get and select(11, get(item)) or 0
end

-- The grey items of the bags a merchant buys: { bag, slot, link, value }
function A:Junk()
    local list = {}
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == POOR and not info.hasNoValue and not info.isLocked
                and not (CK.QuestItems and CK.QuestItems:IsQuestItem(info.itemID)) then
                list[#list + 1] = { bag = bag, slot = slot, link = info.hyperlink,
                    value = (itemPrice(info.hyperlink or info.itemID) or 0) * (info.stackCount or 1) }
            end
        end
    end
    return list
end

-- Sold one after the other; then onDone
function A:SellJunk(onDone)
    local list = self:Junk()
    if #list == 0 or self.selling then
        if onDone then onDone() end
        return
    end
    self.selling = true
    local sold, total, i = 0, 0, 0
    local function step()
        i = i + 1
        local item = list[i]
        if not item or not self.atMerchant or InCombatLockdown() then
            self.selling = false
            if sold > 0 then CK:Print(L.MSG_JUNK_SOLD, sold, money(total)) end
            if onDone and self.atMerchant then onDone() end
            return
        end
        -- Still that item there (nothing moved meanwhile)
        local info = C_Container.GetContainerItemInfo(item.bag, item.slot)
        if info and info.hyperlink == item.link and not info.isLocked then
            C_Container.UseContainerItem(item.bag, item.slot)
            sold, total = sold + 1, total + item.value
        end
        C_Timer.After(SELL_GAP, step)
    end
    step()
end

-- What the guild lets the player take for repairs (-1: no limit)
local function guildFunds()
    if not (CanGuildBankRepair and CanGuildBankRepair()) then return 0 end
    local allowed = GetGuildBankWithdrawMoney and GetGuildBankWithdrawMoney() or 0
    local bank = GetGuildBankMoney and GetGuildBankMoney() or 0
    if allowed == -1 then return bank end
    return math.min(allowed, bank)
end

function A:Repair()
    if not (CanMerchantRepair and CanMerchantRepair()) then return end
    local cost, canRepair = GetRepairAllCost()
    if not canRepair or not cost or cost <= 0 then return end
    if settings().automation.guildRepair and guildFunds() >= cost then
        RepairAllItems(true)
        CK:Print(L.MSG_REPAIRED_GUILD, money(cost))
    elseif GetMoney() >= cost then
        RepairAllItems()
        CK:Print(L.MSG_REPAIRED, money(cost))
    else
        CK:Print(L.MSG_REPAIR_SHORT, money(cost))
    end
end

function A:Init()
    local f = CreateFrame("Frame")
    f:RegisterEvent("MERCHANT_SHOW")
    f:RegisterEvent("MERCHANT_CLOSED")
    f:SetScript("OnEvent", function(_, event)
        if event == "MERCHANT_CLOSED" then
            A.atMerchant = false
            return
        end
        A.atMerchant = true
        if InCombatLockdown() then return end
        local mods = settings().modules
        -- The junk's money first: it can pay for the repair
        local function repair()
            if settings().modules.autoRepair then A:Repair() end
        end
        if mods.sellJunk then
            A:SellJunk(repair)
        else
            repair()
        end
    end)
end
