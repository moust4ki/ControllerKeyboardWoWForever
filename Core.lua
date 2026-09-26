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
    L.SEND_COMBAT = "Clavier ouvert en combat : appuyez sur Entrée pour envoyer."
    L.DRAG_HINT = "Glisser pour déplacer le clavier (/ck lock pour verrouiller)"
    L.LOCKED = "Position verrouillée : %s"
    L.TEXTURES_MISSING = "|cffff4040Textures introuvables|r : quittez et relancez le jeu (un /reload ne suffit pas pour de nouveaux fichiers)."
    L.COMBAT_UNAVAILABLE = "Impossible en combat"
    L.HELP_PETAL = "Pétale"
    L.HELP_LETTER = "Lettre"
    L.HELP_CHANNEL = "Canal"
    L.HELP_PICK = "Choisir"
    L.HELP_CURSOR_L = "Curseur G"
    L.HELP_CURSOR_R = "Curseur D"
    L.HELP_TYPE_L = "Taper G"
    L.HELP_TYPE_R = "Taper D"
    L.OPT_INPUT = "Saisie"
    L.OPT_METHOD = "Méthode de saisie"
    L.METHOD_WHEEL = "Daisywheel"
    L.METHOD_STICK = "Clavier 2 sticks"
    L.OPT_LAYOUT = "Disposition (clavier 2 sticks)"
    L.OPT_DEADZONE = "Zone morte du stick"
    L.OPT_MAGNET = "Effet aimant"
    L.MAGNET_NONE = "Aucun"
    L.MAGNET_WEAK = "Faible"
    L.MAGNET_MEDIUM = "Moyen"
    L.MAGNET_STRONG = "Fort"
    L.OPT_LINE = "Afficher la ligne du curseur"
    L.MODE_SET = "Méthode de saisie : %s"
    L.LAYOUT_SET = "Disposition : %s"
    L.REPLY_TO = "Répondre à %s : "
    L.WHISPER_NAME = "Chuchoter à (nom, puis A) : "
    L.CHANNEL_NAMES = { "Dire", "Crier", "Groupe", "Raid", "Guilde", "Général (/1)", "Chuchoter", "Répondre" }
    L.CHANNEL_UNAVAILABLE = "indisponible"
    L.BADGE_SHIFT = "MAJ"
    L.BADGE_CAPS = "VERR. MAJ"
    L.FONT_CHAT = "Police du chat"
    L.LANG_BOTH = "Les deux"
    L.GLYPHS_NONE = "Aucun atlas de boutons manette trouvé : les glyphes de l'addon sont utilisés."
    L.GLYPHS_FOUND = "%d atlas de boutons manette trouvés :"
    L.OPTIONS_WHERE = "Options : Échap > Options > AddOns > Controller Keyboard"
    L.OPT_SUBTITLE = "Clavier en roue pour écrire dans le chat à la manette ou à la souris."
    L.OPT_KEYBOARD = "Clavier"
    L.OPT_LOCK = "Verrouiller la position"
    L.OPT_AUTO = "Ouvrir automatiquement avec le chat"
    L.OPT_PAD_ONLY = "Seulement quand la manette est active"
    L.OPT_INVERT = "Inverser l'axe vertical des sticks"
    L.OPT_SCALE = "Taille du clavier"
    L.OPT_ACTIONS = "Afficher les boutons souris (Maj, 123, Espace, Effacer, Envoyer, X)"
    L.OPT_LOOK = "Apparence"
    L.OPT_FONT = "Police"
    L.OPT_GLYPHS = "Boutons affichés"
    L.OPT_GAME_GLYPHS = "Utiliser les icônes de boutons du jeu si disponibles"
    L.OPT_PREDICTION = "Prédiction"
    L.OPT_LANG = "Langue des suggestions"
    L.OPT_LEARN = "Apprendre de mes messages"
    L.OPT_RESET_POS = "Replacer le clavier"
    L.OPT_FORGET = "Oublier les mots appris"
    L.OPT_FORGET_CONFIRM = "Cliquer pour confirmer"
    L.HINT = "Stick G : pétale   Stick D : lettre   LB : effacer   RB : espace\nLT : Maj   RT : 123   Croix < > : suggestion   Croix ^ : insérer"
    L.LOADED = "v%s chargé. /ck pour l'aide."
    L.HELP = {
        "/ck - ouvrir le clavier",
        "/ck auto - ouverture automatique avec le chat (actuel : %s)",
        "/ck pad - n'ouvrir automatiquement que si la manette est active (actuel : %s)",
        "/ck learn - apprendre les mots de vos messages (actuel : %s)",
        "/ck lock - verrouiller/déverrouiller la position (actuel : %s)",
        "/ck mode wheel|stick - daisywheel ou clavier 2 sticks",
        "/ck layout azerty|qwerty - disposition du clavier 2 sticks",
        "/ck lang fr|en|both - dictionnaires utilisés",
        "/ck scale 0.8 - taille du clavier",
        "/ck invert - inverser l'axe vertical du stick",
        "/ck reset - replacer le clavier",
        "/ck stats - statistiques d'apprentissage",
        "/ck forget - oublier tous les mots appris",
        "/ck glyphs - lister les icônes de boutons manette du jeu",
        "/ck debug - afficher les boutons reçus",
        "Options : Échap > Options > AddOns > Controller Keyboard",
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
    L.SEND_COMBAT = "Keyboard opened in combat: press Enter to send."
    L.DRAG_HINT = "Drag to move the keyboard (/ck lock to lock)"
    L.LOCKED = "Position locked: %s"
    L.TEXTURES_MISSING = "|cffff4040Textures not found|r: quit and restart the game (/reload is not enough for new files)."
    L.COMBAT_UNAVAILABLE = "Not possible in combat"
    L.HELP_PETAL = "Petal"
    L.HELP_LETTER = "Letter"
    L.HELP_CHANNEL = "Channel"
    L.HELP_PICK = "Select"
    L.HELP_CURSOR_L = "Left cursor"
    L.HELP_CURSOR_R = "Right cursor"
    L.HELP_TYPE_L = "Type left"
    L.HELP_TYPE_R = "Type right"
    L.OPT_INPUT = "Input"
    L.OPT_METHOD = "Input method"
    L.METHOD_WHEEL = "Daisywheel"
    L.METHOD_STICK = "Split keyboard"
    L.OPT_LAYOUT = "Layout (split keyboard)"
    L.OPT_DEADZONE = "Stick dead zone"
    L.OPT_MAGNET = "Magnet"
    L.MAGNET_NONE = "None"
    L.MAGNET_WEAK = "Weak"
    L.MAGNET_MEDIUM = "Medium"
    L.MAGNET_STRONG = "Strong"
    L.OPT_LINE = "Show the cursor line"
    L.MODE_SET = "Input method: %s"
    L.LAYOUT_SET = "Layout: %s"
    L.REPLY_TO = "Reply to %s: "
    L.WHISPER_NAME = "Whisper to (name, then A): "
    L.CHANNEL_NAMES = { "Say", "Yell", "Party", "Raid", "Guild", "General (/1)", "Whisper", "Reply" }
    L.CHANNEL_UNAVAILABLE = "unavailable"
    L.BADGE_SHIFT = "SHIFT"
    L.BADGE_CAPS = "CAPS"
    L.FONT_CHAT = "Chat font"
    L.LANG_BOTH = "Both"
    L.GLYPHS_NONE = "No gamepad button atlas found: the addon's glyphs are used."
    L.GLYPHS_FOUND = "%d gamepad button atlases found:"
    L.OPTIONS_WHERE = "Options: Escape > Options > AddOns > Controller Keyboard"
    L.OPT_SUBTITLE = "Wheel keyboard to type in chat with a gamepad or the mouse."
    L.OPT_KEYBOARD = "Keyboard"
    L.OPT_LOCK = "Lock position"
    L.OPT_AUTO = "Open automatically with the chat"
    L.OPT_PAD_ONLY = "Only when the gamepad is active"
    L.OPT_INVERT = "Invert the sticks vertical axis"
    L.OPT_SCALE = "Keyboard size"
    L.OPT_ACTIONS = "Show the mouse buttons (Shift, 123, Space, Delete, Send, X)"
    L.OPT_LOOK = "Look"
    L.OPT_FONT = "Font"
    L.OPT_GLYPHS = "Button glyphs"
    L.OPT_GAME_GLYPHS = "Use the game's button icons when available"
    L.OPT_PREDICTION = "Prediction"
    L.OPT_LANG = "Suggestion language"
    L.OPT_LEARN = "Learn from my messages"
    L.OPT_RESET_POS = "Reset keyboard position"
    L.OPT_FORGET = "Forget learned words"
    L.OPT_FORGET_CONFIRM = "Click again to confirm"
    L.HINT = "L stick: petal   R stick: letter   LB: delete   RB: space\nLT: Shift   RT: 123   D-pad < >: suggestion   D-pad ^: insert"
    L.LOADED = "v%s loaded. /ck for help."
    L.HELP = {
        "/ck - open the keyboard",
        "/ck auto - open automatically with the chat (current: %s)",
        "/ck pad - only auto-open when the gamepad is active (current: %s)",
        "/ck learn - learn words from your messages (current: %s)",
        "/ck lock - lock/unlock the position (current: %s)",
        "/ck mode wheel|stick - daisywheel or split keyboard",
        "/ck layout azerty|qwerty - split keyboard layout",
        "/ck lang fr|en|both - dictionaries in use",
        "/ck scale 0.8 - keyboard size",
        "/ck invert - invert the stick vertical axis",
        "/ck reset - reset keyboard position",
        "/ck stats - learning statistics",
        "/ck forget - forget all learned words",
        "/ck glyphs - list the game's gamepad button icons",
        "/ck debug - print received buttons",
        "Options: Escape > Options > AddOns > Controller Keyboard",
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
    -- Suggestions in the client's language by default
    dicts = { frFR = GetLocale() == "frFR", enUS = GetLocale() ~= "frFR" },
    maxWords = 8000,
    numSuggestions = 5,
    scale = 1,
    invertY = false,
    locked = true,
    inputMethod = "wheel",   -- "wheel" (daisywheel) or "stick" (split keyboard)
    kbLayout = GetLocale() == "frFR" and "azerty" or "qwerty",
    deadzone = 0.15,         -- split keyboard: sticks dead zone
    magnet = "medium",       -- split keyboard: none / weak / medium / strong
    showLine = true,         -- split keyboard: lines from the centers to the cursors
    showActions = true,
    font = "friz",
    glyphStyle = "xbox",
    gameGlyphs = true,
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
    db.commands = db.commands or {}
    db.trigrams = db.trigrams or {}
    db.starts = db.starts or {}
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
