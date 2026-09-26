local ADDON, CK = ...
_G.ControllerKeyboard = CK

CK.ADDON = ADDON
CK.Dicts = CK.Dicts or {}

---------------------------------------------------------------------------
-- Localisation
---------------------------------------------------------------------------
local L = {}
CK.L = L

if GetLocale() == "frFR" then
    L.SHIFT = "Maj"
    L.SYMBOLS = "123"
    L.LETTERS = "abc"
    L.SPACE = "Espace"
    L.BACKSPACE = "Effacer"
    L.CHANNEL = "Canal"
    L.SEND = "Envoyer"
    L.CLOSE = "Fermer"
    L.HUB_UP = "Mot"
    L.HUB_DOWN = "Eff."
    L.CAPS = "MAJ"
    L.HINT = "Stick G : pétale   Stick D : lettre   LB : effacer   RB : espace\nLT : Maj   RT : 123   A : envoyer   B : fermer   Select : canal"
    L.LOADED = "v%s chargé. /ck pour l'aide."
    L.HELP = {
        "/ck - ouvrir le clavier",
        "/ck auto - ouverture automatique avec le chat (actuel : %s)",
        "/ck pad - n'ouvrir automatiquement que si la manette est active (actuel : %s)",
        "/ck learn - apprendre les mots de vos messages (actuel : %s)",
        "/ck lang fr|en|both - dictionnaires utilisés",
        "/ck scale 0.8 - taille du clavier",
        "/ck invert - inverser l'axe vertical du stick",
        "/ck reset - replacer le clavier",
        "/ck stats - statistiques d'apprentissage",
        "/ck forget - oublier tous les mots appris",
        "/ck debug - afficher les boutons reçus",
    }
    L.ON = "|cff40ff40oui|r"
    L.OFF = "|cffff4040non|r"
    L.STATS = "%d mots appris, %d mots dans le dictionnaire."
    L.FORGOT = "Mots appris effacés."
    L.FORGET_CONFIRM = "Tapez /ck forget confirm pour effacer tous les mots appris."
    L.NO_DICT = "Dictionnaire indisponible : %s"
else
    L.SHIFT = "Shift"
    L.SYMBOLS = "123"
    L.LETTERS = "abc"
    L.SPACE = "Space"
    L.BACKSPACE = "Delete"
    L.CHANNEL = "Channel"
    L.SEND = "Send"
    L.CLOSE = "Close"
    L.HUB_UP = "Word"
    L.HUB_DOWN = "Del"
    L.CAPS = "CAPS"
    L.HINT = "L stick: petal   R stick: letter   LB: delete   RB: space\nLT: Shift   RT: 123   A: send   B: close   Select: channel"
    L.LOADED = "v%s loaded. /ck for help."
    L.HELP = {
        "/ck - open the keyboard",
        "/ck auto - open automatically with the chat (current: %s)",
        "/ck pad - only auto-open when the gamepad is active (current: %s)",
        "/ck learn - learn words from your messages (current: %s)",
        "/ck lang fr|en|both - dictionaries in use",
        "/ck scale 0.8 - keyboard size",
        "/ck invert - invert the stick vertical axis",
        "/ck reset - reset keyboard position",
        "/ck stats - learning statistics",
        "/ck forget - forget all learned words",
        "/ck debug - print received buttons",
    }
    L.ON = "|cff40ff40on|r"
    L.OFF = "|cffff4040off|r"
    L.STATS = "%d learned words, %d dictionary words."
    L.FORGOT = "Learned words cleared."
    L.FORGET_CONFIRM = "Type /ck forget confirm to clear all learned words."
    L.NO_DICT = "Dictionary not available: %s"
end

BINDING_HEADER_CONTROLLERKEYBOARD = "Controller Keyboard"
BINDING_NAME_CONTROLLERKEYBOARD_TOGGLE = GetLocale() == "frFR" and "Ouvrir/fermer le clavier" or "Toggle keyboard"

---------------------------------------------------------------------------
-- Saved variables
---------------------------------------------------------------------------
local DEFAULTS = {
    autoOpen = true,
    onlyWithGamepad = false,
    learn = true,
    dicts = { frFR = true, enUS = false },
    maxWords = 8000,
    numSuggestions = 5,
    scale = 1,
    invertY = false,
    debug = false,
}

local function copyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            copyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function CK:InitDB()
    ControllerKeyboardDB = ControllerKeyboardDB or {}
    local db = ControllerKeyboardDB
    db.settings = db.settings or {}
    copyDefaults(DEFAULTS, db.settings)
    -- v2: auto-open no longer requires the gamepad to be the active input
    if (db.version or 1) < 2 then
        db.settings.onlyWithGamepad = false
        db.pos = nil
        db.version = 2
    end
    db.words = db.words or {}
    db.bigrams = db.bigrams or {}
    self.db = db
end

function CK:Print(msg, ...)
    if select("#", ...) > 0 then msg = format(msg, ...) end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffController Keyboard|r: " .. tostring(msg))
end

---------------------------------------------------------------------------
-- UTF-8 helpers (French accents)
---------------------------------------------------------------------------
local UTF8_2 = "[\195\197][\128-\191]"

local LOWER = {
    ["À"] = "à", ["Â"] = "â", ["Ä"] = "ä", ["Á"] = "á", ["Ç"] = "ç", ["É"] = "é", ["È"] = "è",
    ["Ê"] = "ê", ["Ë"] = "ë", ["Î"] = "î", ["Ï"] = "ï", ["Í"] = "í", ["Ô"] = "ô", ["Ö"] = "ö",
    ["Ó"] = "ó", ["Ù"] = "ù", ["Û"] = "û", ["Ü"] = "ü", ["Ú"] = "ú", ["Ÿ"] = "ÿ", ["Ñ"] = "ñ",
    ["Œ"] = "œ", ["Æ"] = "æ",
}
local UPPER = {}
for up, low in pairs(LOWER) do UPPER[low] = up end

local STRIP = {
    ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["á"] = "a", ["ç"] = "c", ["é"] = "e", ["è"] = "e",
    ["ê"] = "e", ["ë"] = "e", ["î"] = "i", ["ï"] = "i", ["í"] = "i", ["ô"] = "o", ["ö"] = "o",
    ["ó"] = "o", ["ù"] = "u", ["û"] = "u", ["ü"] = "u", ["ú"] = "u", ["ÿ"] = "y", ["ñ"] = "n",
    ["œ"] = "oe", ["æ"] = "ae",
}

-- string.lower/upper may touch UTF-8 bytes depending on the C locale: only map A-Z
local ASCII_LOWER, ASCII_UPPER = {}, {}
for b = 65, 90 do
    ASCII_LOWER[string.char(b)] = string.char(b + 32)
    ASCII_UPPER[string.char(b + 32)] = string.char(b)
end

function CK.Lower(s)
    return (s:gsub("[A-Z]", ASCII_LOWER):gsub(UTF8_2, LOWER))
end

function CK.Upper(s)
    return (s:gsub("[a-z]", ASCII_UPPER):gsub(UTF8_2, UPPER))
end

-- Lowercase and strip accents: "Été" -> "ete"
function CK.Normalize(s)
    return (CK.Lower(s):gsub(UTF8_2, STRIP))
end

function CK.FirstChar(s)
    return s:match("^[\192-\255][\128-\191]*") or s:sub(1, 1)
end

function CK.IsUpperInitial(s)
    local c = CK.FirstChar(s)
    return c ~= "" and c ~= CK.Lower(c)
end

function CK.Capitalize(s)
    local c = CK.FirstChar(s)
    return CK.Upper(c) .. s:sub(#c + 1)
end

-- Remove the last UTF-8 character of a string
function CK.DropLastChar(s)
    local i = #s
    while i > 1 do
        local b = s:byte(i)
        if b < 128 or b >= 192 then break end
        i = i - 1
    end
    return s:sub(1, i - 1)
end

-- Letters (ASCII + any UTF-8 byte) form words
CK.WORD_CHARS = "[%a\128-\255]"
