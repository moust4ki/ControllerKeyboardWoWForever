local _, CK = ...
local L = CK.L

---------------------------------------------------------------------------
-- Fonts (Blizzard fonts shipped with the game)
---------------------------------------------------------------------------
CK.FONTS = {
    { key = "friz", name = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
    { key = "morpheus", name = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
    { key = "skurri", name = "Skurri", path = "Fonts\\SKURRI.TTF" },
    { key = "arialn", name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
    { key = "chat", name = L.FONT_CHAT },
}

function CK:GetFontPath()
    local key = self.db and self.db.settings.font
    for _, font in ipairs(CK.FONTS) do
        if font.key == key then
            if font.key == "chat" then
                return (ChatFontNormal and ChatFontNormal:GetFont()) or STANDARD_TEXT_FONT
            end
            return font.path
        end
    end
    return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

---------------------------------------------------------------------------
-- The configuration panel's General and Keyboard tabs (ConfigWindow.lua
-- draws them): one row per setting
---------------------------------------------------------------------------
local GLYPH_STYLES = {
    { key = "xbox", name = "Xbox (A B X Y)" },
    { key = "playstation", name = "PlayStation" },
}

local function indexOf(list, key)
    for i, item in ipairs(list) do
        if item.key == key then return i end
    end
    return 1
end

-- Row builders
local function list()
    local rows = {}
    local b = {}
    function b.header(text) rows[#rows + 1] = { kind = "header", text = text } end
    function b.info(text) rows[#rows + 1] = { kind = "info", text = text } end
    function b.check(text, get, set, indent, tip)
        rows[#rows + 1] = { kind = "check", text = text, get = get, set = set, indent = indent, tip = tip }
    end
    function b.choice(text, get, step, indent)
        rows[#rows + 1] = { kind = "choice", text = text, get = get, step = step, indent = indent }
    end
    -- A choice among { key, name } items stored in settings[field]
    function b.pick(text, items, s, field, after, indent)
        b.choice(text, function() return items[indexOf(items, s[field])].name end, function(d)
            local i = (indexOf(items, s[field]) - 1 + d) % #items + 1
            s[field] = items[i].key
            if after then after() end
        end, indent)
    end
    function b.button(text, func, indent)
        rows[#rows + 1] = { kind = "button", text = text, func = func, indent = indent }
    end
    -- A box with a choice beside it, and a test (A; X for the box)
    function b.toggle(text, get, set, value, step, test, tip)
        rows[#rows + 1] = { kind = "toggle", text = text, get = get, set = set, value = value, step = step,
            test = test, tip = tip }
    end
    return rows, b
end

local function generalRows()
    local s = CK.db.settings
    local f, mods = s.features, s.modules
    local rows, b = list()

    b.header(L.CFG_H_FEATURES)
    b.check(L.MOD_KEYBOARD, function() return mods.keyboard end, function(v)
        mods.keyboard = v
        if not v then CK:Close("keyboard module off") end
    end)
    if mods.keyboard then
        b.check(L.OPT_AUTO, function() return s.autoOpen end, function(v) s.autoOpen = v end, true)
        b.check(L.OPT_PAD_ONLY, function() return s.onlyWithGamepad end, function(v) s.onlyWithGamepad = v end, true)
        b.check(L.MOD_QUEST_LINKS, function() return mods.questLinks end, function(v)
            mods.questLinks = v
            CK:Layout()
        end, true)
        b.check(L.FEAT_LINKS, function() return f.linkCapture end, function(v) f.linkCapture = v end, true)
        b.check(L.FEAT_DRAFTS, function() return f.drafts end, function(v) f.drafts = v end, true)
        b.check(L.OPT_STICKY, function() return s.stickyChannel end, function(v) s.stickyChannel = v end, true)
    end
    b.check(L.MOD_QUEST_ITEMS, function() return mods.questItems end, function(v) mods.questItems = v end)
    if mods.questItems then
        b.check(L.FEAT_QUEST_TOOLTIP, function() return f.questTooltip end, function(v) f.questTooltip = v end, true)
        b.check(L.FEAT_QUEST_GLOW, function() return f.questGlow end, function(v)
            f.questGlow = v
            CK.QuestItems:RefreshBorders()
        end, true)
        b.check(L.FEAT_QUEST_SELL, function() return f.questSellAlert end, function(v) f.questSellAlert = v end, true)
        b.check(L.FEAT_QUEST_HOVER, function() return f.questHoverAlert end, function(v) f.questHoverAlert = v end, true)
    end
    b.check(L.MOD_MAPPING, function() return mods.mapping end, function(v)
        mods.mapping = v
        CK.Mapping:Apply()
        CK.Paddles:Apply()
    end)
    if mods.mapping then
        b.check(L.FEAT_EXTRA_DISPLAY, function() return f.extraDisplay end, function(v)
            f.extraDisplay = v
            CK.Paddles:Apply()
        end, true)
        b.check(L.FEAT_SHOW_STICKS, function() return f.showSticks end, function(v)
            f.showSticks = v
            CK.Paddles:Apply()
        end, true)
        -- "R4" on the extra buttons: where, or hidden
        local places = {}
        for _, key in ipairs(CK.Paddles.BADGE_PLACES) do
            places[#places + 1] = { key = key, name = L["BADGE_" .. key:upper()] }
        end
        b.pick(L.OPT_BADGE, places, s, "badgePlace", function() CK.Paddles:Apply() end, true)
        -- RT as a modifier: the RT and LT + RT layers for the extra buttons
        if CK.Mapping:CanBeModifier("PADRTRIGGER") then
            b.check(L.FEAT_RT_MODIFIER, function() return CK.Mapping:TriggerModifier("PADRTRIGGER") ~= nil end,
                function(v) CK.Mapping:SetTriggerModifier("PADRTRIGGER", v) end, true, L.FEAT_RT_MODIFIER_TIP)
        end
    end
    local M = CK.Mapping
    b.check(L.FEAT_SHORTCUT, function() return f.configShortcut end, function(v) f.configShortcut = v end)
    if f.configShortcut then
        -- A, then hold a button and press a second one
        local text = CK.Config:IsCapturingChord() and L.CFG_SHORTCUT_PRESS
            or format(L.CFG_SHORTCUT_KEY, M:ChordLabel(s.shortcut))
        b.button(text, function()
            CK.Config:CaptureChord(function(chord)
                if chord then s.shortcut = chord end
                if CK.Config:IsOpen() then
                    CK.Config:Page():Show()
                    CK.Config:Render()
                end
            end)
        end, true)
        local default = CK.DEFAULT_SHORTCUT
        if s.shortcut.hold ~= default.hold or s.shortcut.press ~= default.press then
            b.button(format(L.CFG_SHORTCUT_RESET, M:ChordLabel(default)), function()
                s.shortcut = { hold = default.hold, press = default.press }
            end, true)
        end
    end

    b.header(L.OPT_LOOK)
    b.pick(L.OPT_GLYPHS, GLYPH_STYLES, s, "glyphStyle", function() CK:UpdateGlyphs() end)
    b.check(L.OPT_GAME_GLYPHS, function() return s.gameGlyphs end, function(v)
        s.gameGlyphs = v
        CK:UpdateGlyphs()
    end)
    b.pick(L.OPT_FONT, CK.FONTS, s, "font", function()
        CK:ApplyFont()
        CK:UpdateMethod()
    end)
    return rows
end

local SIZES = {
    { scale = 0.8, name = L.SIZE_SMALL }, { scale = 1, name = L.SIZE_NORMAL },
    { scale = 1.25, name = L.SIZE_LARGE }, { scale = 1.5, name = L.SIZE_XL },
}

local function keyboardRows()
    local s = CK.db.settings
    local rows, b = list()

    b.header(L.OPT_KEYBOARD)
    -- 4 preset sizes (/ec scale still sets any value)
    local function sizeIndex()
        local best, bestD = 2, math.huge
        for i, size in ipairs(SIZES) do
            local d = math.abs(size.scale - s.scale)
            if d < bestD then best, bestD = i, d end
        end
        return best, bestD < 0.01
    end
    b.choice(L.OPT_SCALE, function()
        local i, exact = sizeIndex()
        if exact then return format("%s (%d %%)", SIZES[i].name, SIZES[i].scale * 100 + 0.5) end
        return format("%d %%", s.scale * 100 + 0.5)
    end, function(d)
        local i, exact = sizeIndex()
        -- From a custom value, the first step lands on the nearest preset
        if exact then i = math.min(#SIZES, math.max(1, i + d)) end
        s.scale = SIZES[i].scale
        if CK.frame then
            CK.frame:SetScale(s.scale)
            CK:PositionSendButton()
        end
    end)
    b.check(L.OPT_LOCK, function() return s.locked end, function(v)
        s.locked = v
        CK:UpdateLock()
    end)
    b.button(L.OPT_RESET_POS, function()
        CK.db.pos = nil
        if CK.frame then CK:RestorePosition() end
    end)
    b.check(L.OPT_INVERT, function() return s.invertY end, function(v) s.invertY = v end)
    b.check(L.OPT_ACTIONS, function() return s.showActions end, function(v)
        s.showActions = v
        CK:ApplyLayout()
    end)

    b.header(L.OPT_INPUT)
    local methods = { { key = "wheel", name = L.METHOD_WHEEL }, { key = "stick", name = L.METHOD_STICK } }
    b.choice(L.OPT_METHOD, function() return methods[indexOf(methods, s.inputMethod)].name end, function(d)
        local i = (indexOf(methods, s.inputMethod) - 1 + d) % #methods + 1
        CK:SetInputMethod(methods[i].key)
    end)
    b.pick(L.OPT_LAYOUT, {
        { key = "azerty", name = "AZERTY" }, { key = "qwerty", name = "QWERTY" },
        { key = "qwertz", name = "QWERTZ" }, { key = "qwerty_es", name = "QWERTY (español)" },
        { key = "qwerty_it", name = "QWERTY (italiano)" },
    }, s, "kbLayout", function() CK:UpdateMethod() end)
    b.choice(L.OPT_DEADZONE, function() return format("%d %%", s.deadzone * 100 + 0.5) end, function(d)
        s.deadzone = math.min(0.40, math.max(0.05, math.floor((s.deadzone + d * 0.05) * 100 + 0.5) / 100))
    end)
    b.pick(L.OPT_CURVE, {
        { key = "linear", name = L.CURVE_LINEAR }, { key = "gentle", name = L.CURVE_GENTLE },
        { key = "fast", name = L.CURVE_FAST },
    }, s, "stickCurve")
    b.pick(L.OPT_MAGNET, {
        { key = "none", name = L.MAGNET_NONE }, { key = "weak", name = L.MAGNET_WEAK },
        { key = "medium", name = L.MAGNET_MEDIUM }, { key = "strong", name = L.MAGNET_STRONG },
    }, s, "magnet")
    b.check(L.OPT_LINE, function() return s.showLine end, function(v)
        s.showLine = v
        CK:UpdateMethod()
    end)

    b.header(L.OPT_PREDICTION)
    b.choice(L.OPT_LANG, function() return CK:GetLanguage().name end, function(d)
        local i = (indexOf(CK.LANGUAGES, s.lang) - 1 + d) % #CK.LANGUAGES + 1
        CK:SetLanguage(CK.LANGUAGES[i].key)
    end)
    b.check(L.OPT_LEARN, function() return s.learn end, function(v) s.learn = v end)
    -- Two presses to forget (no confirmation popup, see the keyboard)
    local forget = CK.forgetArmed
    b.button(forget and L.OPT_FORGET_CONFIRM or L.OPT_FORGET, function()
        if CK.forgetArmed then
            CK.forgetArmed = false
            CK.Predict:Forget()
            CK:Print(L.FORGOT)
        else
            CK.forgetArmed = true
            C_Timer.After(4, function()
                CK.forgetArmed = false
                if CK.Config:IsOpen() then CK.Config:Render() end
            end)
        end
    end)
    b.info(format(L.STATS, CK.Predict:NumLearned(), CK.Predict:NumEntries()))
    return rows
end

-- Vibrations: one switch and intensity, then each event with its pattern
local function vibrationRows()
    local V = CK.Vibration
    local s = V:Settings()
    local rows, b = list()

    b.header(L.CFG_TAB_VIBRATION)
    b.check(L.VIB_ENABLE, function() return s.enabled end, function(v)
        s.enabled = v
        if v then V:Play("pulse") else V:Stop() end
        V:UpdateHeart()
    end)
    if not s.enabled then
        b.info(L.VIB_OFF_INFO)
        return rows
    end
    b.choice(L.VIB_INTENSITY, function() return format("%d %%", s.intensity * 100 + 0.5) end, function(d)
        s.intensity = math.min(1, math.max(0.2, math.floor((s.intensity + d * 0.1) * 10 + 0.5) / 10))
        V:Play("pulse")
    end, true)
    b.info(L.VIB_INFO)
    for _, group in ipairs(V.GROUPS) do
        local events = V:GroupEvents(group)
        if #events > 0 then
            b.header(L["VIB_H_" .. group:upper()])
            for _, e in ipairs(events) do
                local cfg = s.events[e.key]
                local text = L["VIB_E_" .. e.key:upper()]
                local tip
                if V:IsUnavailable(e.key) then
                    text = text .. " |cff9d9a8c(" .. L.VIB_UNAVAILABLE .. ")|r"
                    tip = L.VIB_UNAVAILABLE_TIP
                end
                b.toggle(text, function() return cfg.on end, function(v)
                    cfg.on = v
                    if v then V:Play(cfg.pattern) end
                    if e.key == "lowHealth" then V:UpdateHeart() end
                end, function() return L["VIB_P_" .. cfg.pattern:upper()] end, function(d)
                    cfg.pattern = V:NextPattern(cfg.pattern, d)
                    V:Play(cfg.pattern)
                end, function() V:Play(cfg.pattern) end, tip)
            end
        end
    end
    return rows
end

CK.Config.pages.general = CK.Config.NewListPage(generalRows)
CK.Config.pages.keyboard = CK.Config.NewListPage(keyboardRows)
CK.Config.pages.vibration = CK.Config.NewListPage(vibrationRows)

---------------------------------------------------------------------------
-- The game's settings panel (Escape > Options > AddOns > Controller
-- Keyboard) only points to the addon's own panel. Plain buttons: no
-- dropdowns or StaticPopups, which go through WoW Forever's gamepad UI.
---------------------------------------------------------------------------
function CK:RegisterOptions()
    if self.optionsPanel then return end
    local panel = CK.NewFrame("Frame")
    panel.name = "Easy Controller - Forever"
    panel:Hide()
    self.optionsPanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Easy Controller - Forever")
    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", 16, -40)
    sub:SetText(L.OPT_SUBTITLE)
    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hint:SetPoint("TOPLEFT", 16, -70)
    hint:SetWidth(560)
    hint:SetJustifyH("LEFT")
    hint:SetText(L.CFG_SETTINGS_HINT)
    local open = CK.NewFrame("Button", nil, panel, "UIPanelButtonTemplate")
    open:SetSize(240, 26)
    open:SetPoint("TOPLEFT", 16, -120)
    open:SetText(L.CFG_OPEN)
    open:SetScript("OnClick", function() CK.Config:OpenWhenFree() end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end
