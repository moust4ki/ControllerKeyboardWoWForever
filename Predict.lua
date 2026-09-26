local _, CK = ...

local P = {}
CK.Predict = P

local USER_WEIGHT = 12     -- score per time the player used a word
local BIGRAM_WEIGHT = 25   -- score per time the word followed the previous word
local WOW_SCORE = 36       -- score of the WoW chat vocabulary (~ rank 250)

local entries = {}         -- word -> { word, norm, dict }
local buckets = {}         -- first normalized byte -> array of entries
local numEntries = 0

local function rankScore(rank)
    -- rank 1 -> 60, 10 -> 50, 100 -> 40, 1000 -> 30, 10000 -> 20
    return 60 - 10 * math.log10(rank)
end

local function addEntry(word, dictScore)
    local e = entries[word]
    if e then
        if dictScore and dictScore > e.dict then e.dict = dictScore end
        return e
    end
    local norm = CK.Normalize(word)
    if norm == "" then return end
    e = { word = word, norm = norm, dict = dictScore or 0 }
    entries[word] = e
    numEntries = numEntries + 1
    local key = norm:sub(1, 1)
    local bucket = buckets[key]
    if not bucket then
        bucket = {}
        buckets[key] = bucket
    end
    bucket[#bucket + 1] = e
    return e
end

function P:Load()
    wipe(entries)
    wipe(buckets)
    numEntries = 0

    for lang, enabled in pairs(CK.db.settings.dicts) do
        if enabled then
            local list = CK.Dicts[lang]
            if list then
                local rank = 0
                for word in list:gmatch("%S+") do
                    rank = rank + 1
                    addEntry(word, rankScore(rank))
                end
            else
                CK:Print(CK.L.NO_DICT, lang)
            end
        end
    end
    if CK.Dicts.wow then
        for word in CK.Dicts.wow:gmatch("%S+") do
            addEntry(word, WOW_SCORE)
        end
    end
    for word in pairs(CK.db.words) do
        addEntry(word)
    end
end

function P:NumEntries()
    return numEntries
end

-- Keep the best `n` words in `out` (sorted by descending score)
local function consider(out, scores, n, word, score)
    local count = #out
    if count >= n and score <= scores[count] then return end
    local pos = count + 1
    while pos > 1 and scores[pos - 1] < score do
        pos = pos - 1
    end
    table.insert(out, pos, word)
    table.insert(scores, pos, score)
    if #out > n then
        out[n + 1] = nil
        scores[n + 1] = nil
    end
end

local function applyCase(word, prefix)
    if not CK.IsUpperInitial(prefix) then return word end
    if #prefix > 1 and prefix == CK.Upper(prefix) then
        return CK.Upper(word)
    end
    return CK.Capitalize(word)
end

-- prefix: the word being typed (may be ""), prev: the word before it (may be nil)
function P:Query(prefix, prev, n)
    local out, scores = {}, {}
    local words = CK.db.words
    local bigrams = prev and CK.db.bigrams[CK.Lower(prev)]

    if prefix == "" then
        -- Next-word prediction from what the player usually writes
        if bigrams then
            for word, count in pairs(bigrams) do
                consider(out, scores, n, word, count)
            end
        end
        return out
    end

    local norm = CK.Normalize(prefix)
    local lower = CK.Lower(prefix)
    local bucket = buckets[norm:sub(1, 1)]
    if not bucket then return out end

    local len = #norm
    for i = 1, #bucket do
        local e = bucket[i]
        if e.word ~= lower and e.norm:sub(1, len) == norm then
            local score = e.dict + USER_WEIGHT * (words[e.word] or 0)
            if bigrams and bigrams[e.word] then
                score = score + BIGRAM_WEIGHT * bigrams[e.word]
            end
            consider(out, scores, n, e.word, score)
        end
    end

    for i = 1, #out do
        out[i] = applyCase(out[i], prefix)
    end
    return out
end

---------------------------------------------------------------------------
-- Learning
---------------------------------------------------------------------------
local lastMsg, lastTime

local function cleanToken(token)
    token = token:gsub("['%-]+$", "")
    -- elisions: j'ai -> ai, qu'il -> il, l'autre -> autre
    token = token:gsub("^%a%a?'", "")
    return token
end

function P:LearnMessage(msg)
    local db = CK.db
    if not (db and db.settings.learn) or type(msg) ~= "string" then return end

    -- SendChatMessage and C_ChatInfo.SendChatMessage may both be hooked
    local now = GetTime()
    if msg == lastMsg and now == lastTime then return end
    lastMsg, lastTime = msg, now

    msg = msg:gsub("|H.-|h.-|h", " "):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

    local words, bigrams = db.words, db.bigrams
    for sentence in msg:gmatch("[^%.!%?]+") do
        local prev
        for token in sentence:gmatch("[%a\128-\255][%a\128-\255'%-]*") do
            token = CK.Lower(cleanToken(token))
            if #token >= 2 and #token <= 30 then
                words[token] = (words[token] or 0) + 1
                addEntry(token)
                if prev then
                    local t = bigrams[prev]
                    if not t then
                        t = {}
                        bigrams[prev] = t
                    end
                    t[token] = (t[token] or 0) + 1
                end
                prev = token
            end
        end
    end
end

function P:NumLearned()
    local n = 0
    for _ in pairs(CK.db.words) do n = n + 1 end
    return n
end

-- Drop the least used words when the table grows too big
function P:Prune()
    local words, bigrams = CK.db.words, CK.db.bigrams
    local max = CK.db.settings.maxWords
    local n = self:NumLearned()
    local threshold = 1
    while n > max and threshold < 1000 do
        for word, count in pairs(words) do
            if count <= threshold then
                words[word] = nil
                bigrams[word] = nil
                n = n - 1
            end
        end
        threshold = threshold + 1
    end
    for prev, t in pairs(bigrams) do
        if not words[prev] then
            bigrams[prev] = nil
        else
            for word in pairs(t) do
                if not words[word] then t[word] = nil end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
-- Suggested after /reload and the player's own commands (most used first)
local BUILTIN_COMMANDS = {
    "/ck", "/ck lock", "/s", "/p", "/g", "/ra", "/w", "/r", "/y", "/e", "/inv",
    "/roll", "/afk", "/dnd", "/who", "/dance", "/sit", "/played", "/follow",
    "/assist", "/target", "/logout", "/camp", "/ck debug", "/ck auto",
    "/ck learn", "/ck lang", "/ck scale", "/ck reset", "/ck stats", "/ck invert",
    "/ck pad", "/ck forget",
}

-- Commands followed by a message: never learn their argument
local CHAT_COMMANDS = {
    ["/s"] = true, ["/say"] = true, ["/p"] = true, ["/party"] = true, ["/g"] = true,
    ["/guild"] = true, ["/o"] = true, ["/w"] = true, ["/whisper"] = true, ["/t"] = true,
    ["/tell"] = true, ["/r"] = true, ["/reply"] = true, ["/y"] = true, ["/yell"] = true,
    ["/e"] = true, ["/me"] = true, ["/emote"] = true, ["/ra"] = true, ["/raid"] = true,
    ["/rw"] = true, ["/i"] = true, ["/bg"] = true,
}

function P:LearnCommand(text)
    local db = CK.db
    if not (db and db.settings.learn) then return end
    local cmd, rest = text:match("^(/%S+)%s*(.-)%s*$")
    if not cmd or #cmd > 30 then return end
    cmd = CK.Lower(cmd)
    local commands = db.commands
    commands[cmd] = (commands[cmd] or 0) + 1
    -- "/ck lock": remember a single short argument, not chat messages
    local arg = rest:match("^(%S+)$")
    if arg and #arg <= 15 and not CHAT_COMMANDS[cmd] and not cmd:match("^/%d+$") then
        local full = cmd .. " " .. CK.Lower(arg)
        commands[full] = (commands[full] or 0) + 1
    end
end

-- /reload always first, then learned commands by use, then common ones
function P:QueryCommands(text, n)
    local lower = CK.Lower(text)
    local out, seen = {}, {}
    local function add(cmd)
        if #out < n and not seen[cmd] and cmd ~= lower and cmd:sub(1, #lower) == lower then
            seen[cmd] = true
            out[#out + 1] = cmd
        end
    end
    add("/reload")
    local commands = CK.db.commands
    local learned = {}
    for cmd in pairs(commands) do learned[#learned + 1] = cmd end
    table.sort(learned, function(a, b) return commands[a] > commands[b] end)
    for _, cmd in ipairs(learned) do add(cmd) end
    for _, cmd in ipairs(BUILTIN_COMMANDS) do add(cmd) end
    return out
end

function P:Forget()
    wipe(CK.db.words)
    wipe(CK.db.bigrams)
    wipe(CK.db.commands)
    self:Load()
end
