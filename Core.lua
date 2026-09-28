local ADDON, CK = ...
_G.ControllerKeyboard = CK

CK.ADDON = ADDON
CK.Dicts = CK.Dicts or {}

---------------------------------------------------------------------------
-- Localisation: English is the base, each client language overrides it
---------------------------------------------------------------------------
local L = {
    SHIFT = "Shift",
    SYMBOLS = "123",
    LETTERS = "abc",
    SPACE = "Space",
    BACKSPACE = "Delete",
    SEND = "Send",
    SEND_COMBAT = "Keyboard opened in combat: press Enter to send.",
    DRAG_HINT = "Drag to move the keyboard (/ck lock to lock)",
    LOCKED = "Position locked: %s",
    TEXTURES_MISSING = "|cffff4040Textures not found|r: quit and restart the game (/reload is not enough for new files).",
    COMBAT_UNAVAILABLE = "Not possible in combat",
    HELP_PETAL = "Petal",
    HELP_LETTER = "Letter",
    HELP_CHANNEL = "Channel",
    HELP_PICK = "Select",
    HELP_CURSOR_L = "Left cursor",
    HELP_CURSOR_R = "Right cursor",
    HELP_TYPE_L = "Type left",
    HELP_TYPE_R = "Type right",
    OPT_INPUT = "Input",
    OPT_METHOD = "Input method",
    METHOD_WHEEL = "Daisywheel",
    METHOD_STICK = "Split keyboard",
    OPT_LAYOUT = "Layout (split keyboard)",
    OPT_DEADZONE = "Stick dead zone",
    OPT_MAGNET = "Magnet",
    OPT_CURVE = "Stick response",
    CURVE_LINEAR = "Linear",
    CURVE_GENTLE = "Gentle (precise near the center)",
    CURVE_FAST = "Fast",
    MAGNET_NONE = "None",
    MAGNET_WEAK = "Weak",
    MAGNET_MEDIUM = "Medium",
    MAGNET_STRONG = "Strong",
    OPT_LINE = "Show the cursor line",
    MODE_SET = "Input method: %s",
    LAYOUT_SET = "Layout: %s",
    LANG_SET = "Language: %s",
    REPLY_TO = "Reply to %s: ",
    WHISPER_NAME = "Whisper to (name, then A): ",
    CHANNEL_NAMES = { "Say", "Yell", "Party", "Raid", "Guild", "General (/1)", "Whisper", "Reply" },
    CHANNEL_UNAVAILABLE = "unavailable",
    BADGE_SHIFT = "SHIFT",
    BADGE_CAPS = "CAPS",
    FONT_CHAT = "Chat font",
    GLYPHS_NONE = "No gamepad button atlas found: the addon's glyphs are used.",
    GLYPHS_FOUND = "%d gamepad button atlases found:",
    OPTIONS_WHERE = "Options: Escape > Options > AddOns > Controller Keyboard",
    OPT_SUBTITLE = "On-screen keyboard to type in chat with a gamepad or the mouse.",
    OPT_KEYBOARD = "Keyboard",
    OPT_LOCK = "Lock position",
    OPT_AUTO = "Open automatically with the chat",
    OPT_PAD_ONLY = "Only when the gamepad is active",
    OPT_INVERT = "Invert the sticks vertical axis",
    OPT_SCALE = "Keyboard size",
    SIZE_SMALL = "Small",
    SIZE_NORMAL = "Normal",
    SIZE_LARGE = "Large",
    SIZE_XL = "Extra large",
    OPT_ACTIONS = "Show the mouse buttons (Shift, 123, Space, Delete, Send, X)",
    OPT_STICKY = "The chosen channel becomes the chat's own (like typing /p in game)",
    OPT_LOOK = "Look",
    OPT_FONT = "Font",
    OPT_GLYPHS = "Button glyphs",
    OPT_GAME_GLYPHS = "Use the game's button icons when available",
    OPT_PREDICTION = "Prediction",
    OPT_LANG = "Suggestion language",
    OPT_LEARN = "Learn from my messages",
    OPT_RESET_POS = "Reset keyboard position",
    OPT_FORGET = "Forget learned words",
    OPT_FORGET_CONFIRM = "Click again to confirm",
    LOADED = "v%s loaded. /ck for help.",
    HELP = {
        "/ck - open the keyboard",
        "/ck auto - open automatically with the chat (current: %s)",
        "/ck pad - only auto-open when the gamepad is active (current: %s)",
        "/ck learn - learn words from your messages (current: %s)",
        "/ck lock - lock/unlock the position (current: %s)",
        "/ck mode wheel|stick - daisywheel or split keyboard",
        "/ck layout azerty|qwerty|qwertz|es|it - split keyboard layout",
        "/ck lang fr|en|de|es|it|both - suggestion and accent language",
        "/ck scale 0.8 - keyboard size",
        "/ck invert - invert the stick vertical axis",
        "/ck reset - reset keyboard position",
        "/ck stats - learning statistics",
        "/ck forget - forget all learned words",
        "/ck glyphs - list the game's gamepad button icons",
        "/ck debug - print received buttons",
        "Options: Escape > Options > AddOns > Controller Keyboard",
    },
    ON = "|cff40ff40on|r",
    OFF = "|cffff4040off|r",
    STATS = "%d learned words, %d dictionary words.",
    FORGOT = "Learned words cleared.",
    FORGET_CONFIRM = "Type /ck forget confirm to clear all learned words.",
    NO_DICT = "Dictionary not available: %s",
    BINDING_TOGGLE = "Toggle keyboard",
}
CK.L = L

local LOCALES = {}

LOCALES.frFR = {
    SHIFT = "Maj",
    SPACE = "Espace",
    BACKSPACE = "Effacer",
    SEND = "Envoyer",
    SEND_COMBAT = "Clavier ouvert en combat : appuyez sur Entrée pour envoyer.",
    DRAG_HINT = "Glisser pour déplacer le clavier (/ck lock pour verrouiller)",
    LOCKED = "Position verrouillée : %s",
    TEXTURES_MISSING = "|cffff4040Textures introuvables|r : quittez et relancez le jeu (un /reload ne suffit pas pour de nouveaux fichiers).",
    COMBAT_UNAVAILABLE = "Impossible en combat",
    HELP_PETAL = "Pétale",
    HELP_LETTER = "Lettre",
    HELP_CHANNEL = "Canal",
    HELP_PICK = "Choisir",
    HELP_CURSOR_L = "Curseur G",
    HELP_CURSOR_R = "Curseur D",
    HELP_TYPE_L = "Taper G",
    HELP_TYPE_R = "Taper D",
    OPT_INPUT = "Saisie",
    OPT_METHOD = "Méthode de saisie",
    METHOD_STICK = "Clavier 2 sticks",
    OPT_LAYOUT = "Disposition (clavier 2 sticks)",
    OPT_DEADZONE = "Zone morte du stick",
    OPT_MAGNET = "Effet aimant",
    OPT_CURVE = "Réponse du stick",
    CURVE_LINEAR = "Linéaire",
    CURVE_GENTLE = "Douce (précise au centre)",
    CURVE_FAST = "Rapide",
    MAGNET_NONE = "Aucun",
    MAGNET_WEAK = "Faible",
    MAGNET_MEDIUM = "Moyen",
    MAGNET_STRONG = "Fort",
    OPT_LINE = "Afficher la ligne du curseur",
    MODE_SET = "Méthode de saisie : %s",
    LAYOUT_SET = "Disposition : %s",
    LANG_SET = "Langue : %s",
    REPLY_TO = "Répondre à %s : ",
    WHISPER_NAME = "Chuchoter à (nom, puis A) : ",
    CHANNEL_NAMES = { "Dire", "Crier", "Groupe", "Raid", "Guilde", "Général (/1)", "Chuchoter", "Répondre" },
    CHANNEL_UNAVAILABLE = "indisponible",
    BADGE_SHIFT = "MAJ",
    BADGE_CAPS = "VERR. MAJ",
    FONT_CHAT = "Police du chat",
    GLYPHS_NONE = "Aucun atlas de boutons manette trouvé : les glyphes de l'addon sont utilisés.",
    GLYPHS_FOUND = "%d atlas de boutons manette trouvés :",
    OPTIONS_WHERE = "Options : Échap > Options > AddOns > Controller Keyboard",
    OPT_SUBTITLE = "Clavier à l'écran pour écrire dans le chat à la manette ou à la souris.",
    OPT_KEYBOARD = "Clavier",
    OPT_LOCK = "Verrouiller la position",
    OPT_AUTO = "Ouvrir automatiquement avec le chat",
    OPT_PAD_ONLY = "Seulement quand la manette est active",
    OPT_INVERT = "Inverser l'axe vertical des sticks",
    OPT_SCALE = "Taille du clavier",
    SIZE_SMALL = "Petite",
    SIZE_NORMAL = "Normale",
    SIZE_LARGE = "Grande",
    SIZE_XL = "Très grande",
    OPT_ACTIONS = "Afficher les boutons souris (Maj, 123, Espace, Effacer, Envoyer, X)",
    OPT_STICKY = "Le canal choisi devient celui du chat (comme taper /p en jeu)",
    OPT_LOOK = "Apparence",
    OPT_FONT = "Police",
    OPT_GLYPHS = "Boutons affichés",
    OPT_GAME_GLYPHS = "Utiliser les icônes de boutons du jeu si disponibles",
    OPT_PREDICTION = "Prédiction",
    OPT_LANG = "Langue des suggestions",
    OPT_LEARN = "Apprendre de mes messages",
    OPT_RESET_POS = "Replacer le clavier",
    OPT_FORGET = "Oublier les mots appris",
    OPT_FORGET_CONFIRM = "Cliquer pour confirmer",
    LOADED = "v%s chargé. /ck pour l'aide.",
    HELP = {
        "/ck - ouvrir le clavier",
        "/ck auto - ouverture automatique avec le chat (actuel : %s)",
        "/ck pad - n'ouvrir automatiquement que si la manette est active (actuel : %s)",
        "/ck learn - apprendre les mots de vos messages (actuel : %s)",
        "/ck lock - verrouiller/déverrouiller la position (actuel : %s)",
        "/ck mode wheel|stick - daisywheel ou clavier 2 sticks",
        "/ck layout azerty|qwerty|qwertz|es|it - disposition du clavier 2 sticks",
        "/ck lang fr|en|de|es|it|both - langue des suggestions et des accents",
        "/ck scale 0.8 - taille du clavier",
        "/ck invert - inverser l'axe vertical du stick",
        "/ck reset - replacer le clavier",
        "/ck stats - statistiques d'apprentissage",
        "/ck forget - oublier tous les mots appris",
        "/ck glyphs - lister les icônes de boutons manette du jeu",
        "/ck debug - afficher les boutons reçus",
        "Options : Échap > Options > AddOns > Controller Keyboard",
    },
    ON = "|cff40ff40oui|r",
    OFF = "|cffff4040non|r",
    STATS = "%d mots appris, %d mots dans le dictionnaire.",
    FORGOT = "Mots appris effacés.",
    FORGET_CONFIRM = "Tapez /ck forget confirm pour effacer tous les mots appris.",
    NO_DICT = "Dictionnaire indisponible : %s",
    BINDING_TOGGLE = "Ouvrir/fermer le clavier",
}

LOCALES.deDE = {
    SHIFT = "Umschalt",
    SPACE = "Leertaste",
    BACKSPACE = "Löschen",
    SEND = "Senden",
    SEND_COMBAT = "Tastatur im Kampf geöffnet: zum Senden Enter drücken.",
    DRAG_HINT = "Ziehen, um die Tastatur zu verschieben (/ck lock zum Sperren)",
    LOCKED = "Position gesperrt: %s",
    TEXTURES_MISSING = "|cffff4040Texturen nicht gefunden|r: Spiel beenden und neu starten (/reload reicht für neue Dateien nicht).",
    COMBAT_UNAVAILABLE = "Im Kampf nicht möglich",
    HELP_PETAL = "Blatt",
    HELP_LETTER = "Buchstabe",
    HELP_CHANNEL = "Kanal",
    HELP_PICK = "Auswählen",
    HELP_CURSOR_L = "Cursor links",
    HELP_CURSOR_R = "Cursor rechts",
    HELP_TYPE_L = "Tippen links",
    HELP_TYPE_R = "Tippen rechts",
    OPT_INPUT = "Eingabe",
    OPT_METHOD = "Eingabemethode",
    METHOD_STICK = "Geteilte Tastatur",
    OPT_LAYOUT = "Layout (geteilte Tastatur)",
    OPT_DEADZONE = "Totzone des Sticks",
    OPT_MAGNET = "Magnetwirkung",
    OPT_CURVE = "Stick-Reaktion",
    CURVE_LINEAR = "Linear",
    CURVE_GENTLE = "Sanft (präzise in der Mitte)",
    CURVE_FAST = "Schnell",
    MAGNET_NONE = "Keine",
    MAGNET_WEAK = "Schwach",
    MAGNET_MEDIUM = "Mittel",
    MAGNET_STRONG = "Stark",
    OPT_LINE = "Cursorlinie anzeigen",
    MODE_SET = "Eingabemethode: %s",
    LAYOUT_SET = "Layout: %s",
    LANG_SET = "Sprache: %s",
    REPLY_TO = "Antwort an %s: ",
    WHISPER_NAME = "Flüstern an (Name, dann A): ",
    CHANNEL_NAMES = { "Sagen", "Schreien", "Gruppe", "Schlachtzug", "Gilde", "Allgemein (/1)", "Flüstern", "Antworten" },
    CHANNEL_UNAVAILABLE = "nicht verfügbar",
    BADGE_SHIFT = "UMSCH",
    BADGE_CAPS = "FESTSTELL",
    FONT_CHAT = "Chat-Schriftart",
    GLYPHS_NONE = "Keine Gamepad-Tastensymbole gefunden: die Symbole des Addons werden verwendet.",
    GLYPHS_FOUND = "%d Gamepad-Tastensymbole gefunden:",
    OPTIONS_WHERE = "Optionen: Esc > Optionen > AddOns > Controller Keyboard",
    OPT_SUBTITLE = "Bildschirmtastatur, um mit dem Gamepad oder der Maus im Chat zu schreiben.",
    OPT_KEYBOARD = "Tastatur",
    OPT_LOCK = "Position sperren",
    OPT_AUTO = "Automatisch mit dem Chat öffnen",
    OPT_PAD_ONLY = "Nur wenn das Gamepad aktiv ist",
    OPT_INVERT = "Vertikale Stick-Achse umkehren",
    OPT_SCALE = "Tastaturgröße",
    SIZE_SMALL = "Klein",
    SIZE_NORMAL = "Normal",
    SIZE_LARGE = "Groß",
    SIZE_XL = "Sehr groß",
    OPT_ACTIONS = "Maustasten anzeigen (Umschalt, 123, Leertaste, Löschen, Senden, X)",
    OPT_STICKY = "Der gewählte Kanal wird zum Chatkanal (wie /p im Spiel)",
    OPT_LOOK = "Aussehen",
    OPT_FONT = "Schriftart",
    OPT_GLYPHS = "Tastensymbole",
    OPT_GAME_GLYPHS = "Tastensymbole des Spiels verwenden, falls verfügbar",
    OPT_PREDICTION = "Vorhersage",
    OPT_LANG = "Sprache der Vorschläge",
    OPT_LEARN = "Aus meinen Nachrichten lernen",
    OPT_RESET_POS = "Tastatur zurücksetzen",
    OPT_FORGET = "Gelernte Wörter vergessen",
    OPT_FORGET_CONFIRM = "Zum Bestätigen erneut klicken",
    LOADED = "v%s geladen. /ck für Hilfe.",
    HELP = {
        "/ck - Tastatur öffnen",
        "/ck auto - automatisch mit dem Chat öffnen (aktuell: %s)",
        "/ck pad - nur automatisch öffnen, wenn das Gamepad aktiv ist (aktuell: %s)",
        "/ck learn - Wörter aus deinen Nachrichten lernen (aktuell: %s)",
        "/ck lock - Position sperren/entsperren (aktuell: %s)",
        "/ck mode wheel|stick - Daisywheel oder geteilte Tastatur",
        "/ck layout azerty|qwerty|qwertz|es|it - Layout der geteilten Tastatur",
        "/ck lang fr|en|de|es|it|both - Sprache der Vorschläge und Akzente",
        "/ck scale 0.8 - Tastaturgröße",
        "/ck invert - vertikale Stick-Achse umkehren",
        "/ck reset - Tastatur zurücksetzen",
        "/ck stats - Lernstatistik",
        "/ck forget - alle gelernten Wörter vergessen",
        "/ck glyphs - Gamepad-Tastensymbole des Spiels auflisten",
        "/ck debug - empfangene Tasten anzeigen",
        "Optionen: Esc > Optionen > AddOns > Controller Keyboard",
    },
    ON = "|cff40ff40an|r",
    OFF = "|cffff4040aus|r",
    STATS = "%d gelernte Wörter, %d Wörter im Wörterbuch.",
    FORGOT = "Gelernte Wörter gelöscht.",
    FORGET_CONFIRM = "Gib /ck forget confirm ein, um alle gelernten Wörter zu löschen.",
    NO_DICT = "Wörterbuch nicht verfügbar: %s",
    BINDING_TOGGLE = "Tastatur ein-/ausblenden",
}

LOCALES.esES = {
    SHIFT = "Mayús",
    SPACE = "Espacio",
    BACKSPACE = "Borrar",
    SEND = "Enviar",
    SEND_COMBAT = "Teclado abierto en combate: pulsa Intro para enviar.",
    DRAG_HINT = "Arrastra para mover el teclado (/ck lock para bloquearlo)",
    LOCKED = "Posición bloqueada: %s",
    TEXTURES_MISSING = "|cffff4040Texturas no encontradas|r: cierra y reinicia el juego (/reload no basta para archivos nuevos).",
    COMBAT_UNAVAILABLE = "No es posible en combate",
    HELP_PETAL = "Pétalo",
    HELP_LETTER = "Letra",
    HELP_CHANNEL = "Canal",
    HELP_PICK = "Elegir",
    HELP_CURSOR_L = "Cursor izq.",
    HELP_CURSOR_R = "Cursor der.",
    HELP_TYPE_L = "Escribir izq.",
    HELP_TYPE_R = "Escribir der.",
    OPT_INPUT = "Escritura",
    OPT_METHOD = "Método de escritura",
    METHOD_STICK = "Teclado dividido",
    OPT_LAYOUT = "Distribución (teclado dividido)",
    OPT_DEADZONE = "Zona muerta del stick",
    OPT_MAGNET = "Efecto imán",
    OPT_CURVE = "Respuesta del stick",
    CURVE_LINEAR = "Lineal",
    CURVE_GENTLE = "Suave (precisa en el centro)",
    CURVE_FAST = "Rápida",
    MAGNET_NONE = "Ninguno",
    MAGNET_WEAK = "Débil",
    MAGNET_MEDIUM = "Medio",
    MAGNET_STRONG = "Fuerte",
    OPT_LINE = "Mostrar la línea del cursor",
    MODE_SET = "Método de escritura: %s",
    LAYOUT_SET = "Distribución: %s",
    LANG_SET = "Idioma: %s",
    REPLY_TO = "Responder a %s: ",
    WHISPER_NAME = "Susurrar a (nombre, luego A): ",
    CHANNEL_NAMES = { "Decir", "Gritar", "Grupo", "Banda", "Hermandad", "General (/1)", "Susurrar", "Responder" },
    CHANNEL_UNAVAILABLE = "no disponible",
    BADGE_SHIFT = "MAYÚS",
    BADGE_CAPS = "BLOQ MAYÚS",
    FONT_CHAT = "Fuente del chat",
    GLYPHS_NONE = "No se encontraron iconos de botones del mando: se usan los del addon.",
    GLYPHS_FOUND = "%d iconos de botones del mando encontrados:",
    OPTIONS_WHERE = "Opciones: Esc > Opciones > AddOns > Controller Keyboard",
    OPT_SUBTITLE = "Teclado en pantalla para escribir en el chat con el mando o el ratón.",
    OPT_KEYBOARD = "Teclado",
    OPT_LOCK = "Bloquear la posición",
    OPT_AUTO = "Abrir automáticamente con el chat",
    OPT_PAD_ONLY = "Solo cuando el mando está activo",
    OPT_INVERT = "Invertir el eje vertical de los sticks",
    OPT_SCALE = "Tamaño del teclado",
    SIZE_SMALL = "Pequeño",
    SIZE_NORMAL = "Normal",
    SIZE_LARGE = "Grande",
    SIZE_XL = "Muy grande",
    OPT_ACTIONS = "Mostrar los botones del ratón (Mayús, 123, Espacio, Borrar, Enviar, X)",
    OPT_STICKY = "El canal elegido pasa a ser el del chat (como escribir /p en el juego)",
    OPT_LOOK = "Apariencia",
    OPT_FONT = "Fuente",
    OPT_GLYPHS = "Iconos de botones",
    OPT_GAME_GLYPHS = "Usar los iconos de botones del juego si están disponibles",
    OPT_PREDICTION = "Predicción",
    OPT_LANG = "Idioma de las sugerencias",
    OPT_LEARN = "Aprender de mis mensajes",
    OPT_RESET_POS = "Recolocar el teclado",
    OPT_FORGET = "Olvidar las palabras aprendidas",
    OPT_FORGET_CONFIRM = "Pulsa otra vez para confirmar",
    LOADED = "v%s cargado. /ck para la ayuda.",
    HELP = {
        "/ck - abrir el teclado",
        "/ck auto - abrir automáticamente con el chat (actual: %s)",
        "/ck pad - abrir automáticamente solo si el mando está activo (actual: %s)",
        "/ck learn - aprender las palabras de tus mensajes (actual: %s)",
        "/ck lock - bloquear/desbloquear la posición (actual: %s)",
        "/ck mode wheel|stick - daisywheel o teclado dividido",
        "/ck layout azerty|qwerty|qwertz|es|it - distribución del teclado dividido",
        "/ck lang fr|en|de|es|it|both - idioma de las sugerencias y de los acentos",
        "/ck scale 0.8 - tamaño del teclado",
        "/ck invert - invertir el eje vertical del stick",
        "/ck reset - recolocar el teclado",
        "/ck stats - estadísticas de aprendizaje",
        "/ck forget - olvidar todas las palabras aprendidas",
        "/ck glyphs - listar los iconos de botones del mando del juego",
        "/ck debug - mostrar los botones recibidos",
        "Opciones: Esc > Opciones > AddOns > Controller Keyboard",
    },
    ON = "|cff40ff40sí|r",
    OFF = "|cffff4040no|r",
    STATS = "%d palabras aprendidas, %d palabras en el diccionario.",
    FORGOT = "Palabras aprendidas borradas.",
    FORGET_CONFIRM = "Escribe /ck forget confirm para borrar todas las palabras aprendidas.",
    NO_DICT = "Diccionario no disponible: %s",
    BINDING_TOGGLE = "Mostrar/ocultar el teclado",
}
LOCALES.esMX = LOCALES.esES

LOCALES.itIT = {
    SHIFT = "Maiusc",
    SPACE = "Spazio",
    BACKSPACE = "Cancella",
    SEND = "Invia",
    SEND_COMBAT = "Tastiera aperta in combattimento: premi Invio per inviare.",
    DRAG_HINT = "Trascina per spostare la tastiera (/ck lock per bloccarla)",
    LOCKED = "Posizione bloccata: %s",
    TEXTURES_MISSING = "|cffff4040Texture non trovate|r: chiudi e riavvia il gioco (/reload non basta per i nuovi file).",
    COMBAT_UNAVAILABLE = "Impossibile in combattimento",
    HELP_PETAL = "Petalo",
    HELP_LETTER = "Lettera",
    HELP_CHANNEL = "Canale",
    HELP_PICK = "Scegli",
    HELP_CURSOR_L = "Cursore sx",
    HELP_CURSOR_R = "Cursore dx",
    HELP_TYPE_L = "Scrivi sx",
    HELP_TYPE_R = "Scrivi dx",
    OPT_INPUT = "Scrittura",
    OPT_METHOD = "Metodo di scrittura",
    METHOD_STICK = "Tastiera divisa",
    OPT_LAYOUT = "Layout (tastiera divisa)",
    OPT_DEADZONE = "Zona morta dello stick",
    OPT_MAGNET = "Effetto calamita",
    OPT_CURVE = "Risposta dello stick",
    CURVE_LINEAR = "Lineare",
    CURVE_GENTLE = "Morbida (precisa al centro)",
    CURVE_FAST = "Rapida",
    MAGNET_NONE = "Nessuno",
    MAGNET_WEAK = "Debole",
    MAGNET_MEDIUM = "Medio",
    MAGNET_STRONG = "Forte",
    OPT_LINE = "Mostra la linea del cursore",
    MODE_SET = "Metodo di scrittura: %s",
    LAYOUT_SET = "Layout: %s",
    LANG_SET = "Lingua: %s",
    REPLY_TO = "Rispondi a %s: ",
    WHISPER_NAME = "Sussurra a (nome, poi A): ",
    CHANNEL_NAMES = { "Parla", "Urla", "Gruppo", "Incursione", "Gilda", "Generale (/1)", "Sussurra", "Rispondi" },
    CHANNEL_UNAVAILABLE = "non disponibile",
    BADGE_SHIFT = "MAIUSC",
    BADGE_CAPS = "BLOC MAIUSC",
    FONT_CHAT = "Carattere della chat",
    GLYPHS_NONE = "Nessuna icona dei pulsanti del controller trovata: vengono usate quelle dell'addon.",
    GLYPHS_FOUND = "%d icone dei pulsanti del controller trovate:",
    OPTIONS_WHERE = "Opzioni: Esc > Opzioni > AddOns > Controller Keyboard",
    OPT_SUBTITLE = "Tastiera su schermo per scrivere in chat con il controller o il mouse.",
    OPT_KEYBOARD = "Tastiera",
    OPT_LOCK = "Blocca la posizione",
    OPT_AUTO = "Apri automaticamente con la chat",
    OPT_PAD_ONLY = "Solo quando il controller è attivo",
    OPT_INVERT = "Inverti l'asse verticale degli stick",
    OPT_SCALE = "Dimensione della tastiera",
    SIZE_SMALL = "Piccola",
    SIZE_NORMAL = "Normale",
    SIZE_LARGE = "Grande",
    SIZE_XL = "Molto grande",
    OPT_ACTIONS = "Mostra i pulsanti del mouse (Maiusc, 123, Spazio, Cancella, Invia, X)",
    OPT_STICKY = "Il canale scelto diventa quello della chat (come scrivere /p nel gioco)",
    OPT_LOOK = "Aspetto",
    OPT_FONT = "Carattere",
    OPT_GLYPHS = "Icone dei pulsanti",
    OPT_GAME_GLYPHS = "Usa le icone dei pulsanti del gioco se disponibili",
    OPT_PREDICTION = "Previsione",
    OPT_LANG = "Lingua dei suggerimenti",
    OPT_LEARN = "Impara dai miei messaggi",
    OPT_RESET_POS = "Riposiziona la tastiera",
    OPT_FORGET = "Dimentica le parole apprese",
    OPT_FORGET_CONFIRM = "Clicca di nuovo per confermare",
    LOADED = "v%s caricato. /ck per l'aiuto.",
    HELP = {
        "/ck - apri la tastiera",
        "/ck auto - apri automaticamente con la chat (attuale: %s)",
        "/ck pad - apri automaticamente solo se il controller è attivo (attuale: %s)",
        "/ck learn - impara le parole dai tuoi messaggi (attuale: %s)",
        "/ck lock - blocca/sblocca la posizione (attuale: %s)",
        "/ck mode wheel|stick - daisywheel o tastiera divisa",
        "/ck layout azerty|qwerty|qwertz|es|it - layout della tastiera divisa",
        "/ck lang fr|en|de|es|it|both - lingua dei suggerimenti e degli accenti",
        "/ck scale 0.8 - dimensione della tastiera",
        "/ck invert - inverti l'asse verticale dello stick",
        "/ck reset - riposiziona la tastiera",
        "/ck stats - statistiche di apprendimento",
        "/ck forget - dimentica tutte le parole apprese",
        "/ck glyphs - elenca le icone dei pulsanti del controller del gioco",
        "/ck debug - mostra i pulsanti ricevuti",
        "Opzioni: Esc > Opzioni > AddOns > Controller Keyboard",
    },
    ON = "|cff40ff40sì|r",
    OFF = "|cffff4040no|r",
    STATS = "%d parole apprese, %d parole nel dizionario.",
    FORGOT = "Parole apprese cancellate.",
    FORGET_CONFIRM = "Scrivi /ck forget confirm per cancellare tutte le parole apprese.",
    NO_DICT = "Dizionario non disponibile: %s",
    BINDING_TOGGLE = "Mostra/nascondi la tastiera",
}

for key, value in pairs(LOCALES[GetLocale()] or {}) do
    L[key] = value
end

BINDING_HEADER_CONTROLLERKEYBOARD = "Controller Keyboard"
BINDING_NAME_CONTROLLERKEYBOARD_TOGGLE = L.BINDING_TOGGLE

---------------------------------------------------------------------------
-- Saved variables
---------------------------------------------------------------------------
local DEFAULTS = {
    autoOpen = true,
    onlyWithGamepad = false,
    learn = true,
    -- Suggestions and keyboard layout follow the client's language by default
    lang = ({ frFR = "fr", deDE = "de", esES = "es", esMX = "es", itIT = "it" })[GetLocale()] or "en",
    maxWords = 8000,
    numSuggestions = 5,
    scale = 1,
    invertY = false,
    locked = true,
    inputMethod = "wheel",   -- "wheel" (daisywheel) or "stick" (split keyboard)
    kbLayout = ({ frFR = "azerty", deDE = "qwertz", esES = "qwerty_es", esMX = "qwerty_es",
        itIT = "qwerty_it" })[GetLocale()] or "qwerty",
    deadzone = 0.15,         -- split keyboard: sticks dead zone
    stickCurve = "linear",   -- split keyboard: linear / gentle / fast
    magnet = "medium",       -- split keyboard: none / weak / medium / strong
    showLine = true,         -- split keyboard: lines from the centers to the cursors
    showActions = true,
    stickyChannel = true,    -- the channel row also sets the chat's own sticky channel
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
    -- Before 0.4.2: dicts = { frFR = bool, enUS = bool } instead of a language
    if db.settings.lang == nil and type(db.settings.dicts) == "table" then
        local d = db.settings.dicts
        db.settings.lang = (d.frFR and d.enUS) and "fren" or (d.enUS and "en") or "fr"
    end
    copyDefaults(DEFAULTS, db.settings)
    -- v2: auto-open no longer requires the gamepad to be the active input
    if (db.version or 1) < 2 then
        db.settings.onlyWithGamepad = false
        db.pos = nil
        db.version = 2
    end
    self.db = db
    self:ApplyLanguage()
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
    ["Ó"] = "ó", ["Ò"] = "ò", ["Ì"] = "ì", ["Ù"] = "ù", ["Û"] = "û", ["Ü"] = "ü", ["Ú"] = "ú", ["Ÿ"] = "ÿ", ["Ñ"] = "ñ",
    ["Œ"] = "œ", ["Æ"] = "æ",
}
local UPPER = {}
for up, low in pairs(LOWER) do UPPER[low] = up end

local STRIP = {
    ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["á"] = "a", ["ç"] = "c", ["é"] = "e", ["è"] = "e",
    ["ê"] = "e", ["ë"] = "e", ["î"] = "i", ["ï"] = "i", ["í"] = "i", ["ô"] = "o", ["ö"] = "o",
    ["ó"] = "o", ["ò"] = "o", ["ì"] = "i", ["ß"] = "ss", ["ù"] = "u", ["û"] = "u", ["ü"] = "u", ["ú"] = "u", ["ÿ"] = "y", ["ñ"] = "n",
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

---------------------------------------------------------------------------
-- Languages: dictionaries, and the accents of the 123 layer
---------------------------------------------------------------------------
CK.LANGUAGES = {
    { key = "fr", name = "Français", dicts = { "frFR" }, accents = "fr" },
    { key = "en", name = "English", dicts = { "enUS" }, accents = "en" },
    { key = "de", name = "Deutsch", dicts = { "deDE" }, accents = "de" },
    { key = "es", name = "Español", dicts = { "esES" }, accents = "es" },
    { key = "it", name = "Italiano", dicts = { "itIT" }, accents = "it" },
    { key = "fren", name = "Français + English", dicts = { "frFR", "enUS" }, accents = "fr" },
}

-- 12 characters per language: the accents first, then useful punctuation
CK.ACCENTS = {
    fr = { "é", "è", "ê", "à", "â", "ç", "ù", "û", "î", "ô", "ë", "ï" },
    en = { "é", "è", "à", "ç", "'", "?", "!", "-", "&", "$", "ë", "ï" },
    de = { "ä", "ö", "ü", "ß", "?", "!", "'", "-", "€", "&", "§", "_" },
    es = { "á", "é", "í", "ó", "ú", "ñ", "ü", "¿", "¡", "'", "-", "ç" },
    it = { "à", "è", "é", "ì", "ò", "ù", "ó", "í", "ú", "'", "?", "!" },
}

function CK:GetLanguage()
    local key = self.db and self.db.settings.lang
    for _, lang in ipairs(CK.LANGUAGES) do
        if lang.key == key then return lang end
    end
    return CK.LANGUAGES[2]
end

function CK:Accents()
    return CK.ACCENTS[self:GetLanguage().accents] or CK.ACCENTS.fr
end

-- The dictionaries in use come from the language
function CK:ApplyLanguage()
    local dicts = {}
    for _, key in ipairs(self:GetLanguage().dicts) do dicts[key] = true end
    self.db.settings.dicts = dicts
end

function CK:SetLanguage(key)
    self.db.settings.lang = key
    self:ApplyLanguage()
    CK.Predict:Load()
    if self.frame then self:UpdateMethod() end
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
