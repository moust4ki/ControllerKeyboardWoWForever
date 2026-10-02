local _, CK = ...
local L = CK.L

-- Module "quest links" (part of the keyboard): insert real quest links in the
-- message without leaving the keyboard, and catch the links the game inserts
-- with Shift+click (quest, item, spell...).
--
-- The channel row ends with a "Quests" chip. Selecting it turns the
-- suggestions row into the list of the quests in progress: D-pad / right
-- stick move, right stick click (or A on the chip) inserts the link.

local function enabled()
    return CK.db and CK.db.settings.modules.questLinks
end

---------------------------------------------------------------------------
-- Quest log
---------------------------------------------------------------------------
-- GetQuestLink takes a quest ID (never a quest log index)
local function questLink(questID)
    if not questID or questID == 0 then return end
    if GetQuestLink then
        local link = GetQuestLink(questID)
        if link then return link end
    end
    if C_QuestLog and C_QuestLog.GetQuestLink then return C_QuestLog.GetQuestLink(questID) end
end

-- { { title = "...", link = "|cff...|Hquest:...|h[...]|h|r" }, ... }
function CK:QuestList()
    local list = {}
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and not info.isHidden and info.questID then
                local link = questLink(info.questID)
                if link then list[#list + 1] = { title = info.title, link = link } end
            end
        end
    elseif GetNumQuestLogEntries and GetQuestLogTitle then
        for i = 1, GetNumQuestLogEntries() do
            local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
            if title and not isHeader then
                local link = questLink(questID)
                if link then list[#list + 1] = { title = title, link = link } end
            end
        end
    end
    return list
end

---------------------------------------------------------------------------
-- The quest list in the suggestions row
---------------------------------------------------------------------------
function CK:OpenQuestList()
    if not enabled() then return end
    local list = self:QuestList()
    if #list == 0 then
        if UIErrorsFrame then UIErrorsFrame:AddMessage(L.NO_QUESTS, 1, 0.82, 0, 1) end
        return
    end
    self.state.questList = list
    self.state.questIndex = 1
    self.state.activeRow = "suggestions"
    self:Refresh()
end

function CK:CloseQuestList()
    if not self.state.questList then return end
    self.state.questList = nil
    self:Refresh()
end

function CK:InQuestList()
    return self.state.questList ~= nil
end

-- Show 5 titles around the selected quest; `selected` points at it
function CK:QuestListSuggestions(n)
    local list, index = self.state.questList, self.state.questIndex
    local first = math.max(1, math.min(index - math.floor(n / 2), #list - n + 1))
    local out = {}
    for i = first, math.min(#list, first + n - 1) do out[#out + 1] = list[i].title end
    self.state.selected = index - first + 1
    return out
end

function CK:MoveInQuestList(delta)
    local list = self.state.questList
    self.state.questIndex = (self.state.questIndex - 1 + delta) % #list + 1
    self:Refresh()
end

function CK:InsertQuestLink(index)
    local list = self.state.questList
    local quest = list and list[index or self.state.questIndex]
    if not quest then return end
    self.state.questList = nil
    local text = self:GetText()
    local sep = (text == "" or text:sub(-1) == " ") and "" or " "
    self:SetText(text .. sep .. quest.link .. " ")
end

---------------------------------------------------------------------------
-- Links in the message
---------------------------------------------------------------------------
-- A link at the very end of the text (deleted as a whole by Backspace)
function CK.TrailingLink(text)
    return text:match("(|c%x%x%x%x%x%x%x%x|H[^|]+|h[^|]*|h|r)$") or text:match("(|H[^|]+|h[^|]*|h)$")
end

-- Readable text for the preview: links shown as [Title] in gold
function CK.DisplayText(text)
    return (text:gsub("|c%x%x%x%x%x%x%x%x|H[^|]+|h([^|]*)|h|r", "|cffffd100%1|r")
        :gsub("|H[^|]+|h([^|]*)|h", "|cffffd100%1|r"))
end

-- Shift+click (and the game's own "Share in chat") inserts a link through
-- ChatFrameUtil.InsertLink: add it to the keyboard's message too (the chat's
-- own text is never copied back). When no chat is open the game opens one
-- with the link as its text: the keyboard reads it on opening, after the
-- draft kept from before (see CK:Open).
function CK:HookLinks()
    local function onLink(link)
        if not (CK.db.settings.features.linkCapture and CK:IsOpen()
            and type(link) == "string" and link:find("|H", 1, true)) then return end
        local text = CK:GetText()
        local sep = (text == "" or text:sub(-1) == " ") and "" or " "
        CK:SetText(text .. sep .. link .. " ")
    end
    -- ChatEdit_InsertLink is a deprecated alias of the same function: when
    -- both exist each one is hooked, a call goes through only one of them
    if ChatFrameUtil and ChatFrameUtil.InsertLink then
        hooksecurefunc(ChatFrameUtil, "InsertLink", onLink)
    end
    if ChatEdit_InsertLink then
        hooksecurefunc("ChatEdit_InsertLink", onLink)
    end
end
