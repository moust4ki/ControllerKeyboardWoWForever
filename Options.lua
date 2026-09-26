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
-- Settings panel (Escape > Options > AddOns > Controller Keyboard)
--
-- Only plain check buttons, "< value >" selectors and buttons: no dropdowns or
-- StaticPopups, which go through WoW Forever's gamepad UI and can be blocked.
---------------------------------------------------------------------------
local LANGS = {
    { key = "fr", name = "Français" },
    { key = "en", name = "English" },
    { key = "both", name = L.LANG_BOTH },
}
local GLYPH_STYLES = {
    { key = "xbox", name = "Xbox (A B X Y)" },
    { key = "playstation", name = "PlayStation" },
}

local function currentLang(s)
    if s.dicts.frFR and s.dicts.enUS then return "both" end
    return s.dicts.enUS and "en" or "fr"
end

local function indexOf(list, key)
    for i, item in ipairs(list) do
        if item.key == key then return i end
    end
    return 1
end

function CK:RegisterOptions()
    if self.optionsPanel then return end
    local s = self.db.settings
    local panel = CK.NewFrame("Frame")
    panel.name = "Controller Keyboard"
    panel:Hide()
    self.optionsPanel = panel

    -- The options don't fit on one screen: scroll with the mouse wheel
    local scroll = CK.NewFrame("ScrollFrame", nil, panel)
    scroll:SetAllPoints()
    local content = CK.NewFrame("Frame", nil, scroll)
    content:SetSize(640, 900)
    scroll:SetScrollChild(content)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(sf, delta)
        local max = math.max(0, content:GetHeight() - sf:GetHeight())
        sf:SetVerticalScroll(math.min(max, math.max(0, sf:GetVerticalScroll() - delta * 40)))
    end)
    panel:SetScript("OnSizeChanged", function(_, w) if w and w > 0 then content:SetWidth(w) end end)

    local refreshers = {}
    local y = -16

    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, y)
    title:SetText("Controller Keyboard")
    y = y - 24
    local sub = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", 16, y)
    sub:SetText(L.OPT_SUBTITLE)
    y = y - 30

    local function header(label)
        local h = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        h:SetPoint("TOPLEFT", 16, y)
        h:SetText(label)
        y = y - 24
    end

    local function check(label, get, set)
        local cb = CK.NewFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        cb:SetSize(26, 26)
        cb:SetPoint("TOPLEFT", 20, y)
        local text = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("LEFT", cb, "RIGHT", 4, 1)
        text:SetText(label)
        cb:SetScript("OnClick", function(b) set(b:GetChecked() and true or false) end)
        refreshers[#refreshers + 1] = function() cb:SetChecked(get()) end
        y = y - 28
    end

    -- "Label   [<]  value  [>]"
    local function selector(label, count, getText, step)
        local text = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 24, y - 4)
        text:SetText(label)
        local prev = CK.NewFrame("Button", nil, content, "UIPanelButtonTemplate")
        prev:SetSize(26, 22)
        prev:SetPoint("TOPLEFT", 220, y)
        prev:SetText("<")
        local value = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        value:SetPoint("LEFT", prev, "RIGHT", 6, 0)
        value:SetWidth(150)
        local nextB = CK.NewFrame("Button", nil, content, "UIPanelButtonTemplate")
        nextB:SetSize(26, 22)
        nextB:SetPoint("LEFT", value, "RIGHT", 6, 0)
        nextB:SetText(">")
        local function refresh() value:SetText(getText()) end
        prev:SetScript("OnClick", function() step(-1); refresh() end)
        nextB:SetScript("OnClick", function() step(1); refresh() end)
        refreshers[#refreshers + 1] = refresh
        y = y - 30
    end

    local function button(label, x, onClick)
        local b = CK.NewFrame("Button", nil, content, "UIPanelButtonTemplate")
        b:SetSize(190, 24)
        b:SetPoint("TOPLEFT", x, y)
        b:SetText(label)
        b:SetScript("OnClick", onClick)
        return b
    end

    -- Keyboard
    header(L.OPT_KEYBOARD)
    check(L.OPT_LOCK, function() return s.locked end, function(v)
        s.locked = v
        CK:UpdateLock()
    end)
    check(L.OPT_AUTO, function() return s.autoOpen end, function(v) s.autoOpen = v end)
    check(L.OPT_PAD_ONLY, function() return s.onlyWithGamepad end, function(v) s.onlyWithGamepad = v end)
    check(L.OPT_INVERT, function() return s.invertY end, function(v) s.invertY = v end)
    check(L.OPT_ACTIONS, function() return s.showActions end, function(v)
        s.showActions = v
        CK:ApplyLayout()
    end)
    selector(L.OPT_SCALE, nil, function() return format("%d %%", s.scale * 100 + 0.5) end, function(d)
        s.scale = math.min(1.5, math.max(0.5, math.floor((s.scale + d * 0.05) * 100 + 0.5) / 100))
        if CK.frame then
            CK.frame:SetScale(s.scale)
            CK:PositionSendButton()
        end
    end)

    -- Input method
    y = y - 6
    header(L.OPT_INPUT)
    local METHODS = {
        { key = "wheel", name = L.METHOD_WHEEL },
        { key = "stick", name = L.METHOD_STICK },
    }
    selector(L.OPT_METHOD, #METHODS, function() return METHODS[indexOf(METHODS, s.inputMethod)].name end, function(d)
        local i = (indexOf(METHODS, s.inputMethod) - 1 + d) % #METHODS + 1
        CK:SetInputMethod(METHODS[i].key)
    end)
    local LAYOUTS = { { key = "azerty", name = "AZERTY" }, { key = "qwerty", name = "QWERTY" } }
    selector(L.OPT_LAYOUT, #LAYOUTS, function() return LAYOUTS[indexOf(LAYOUTS, s.kbLayout)].name end, function(d)
        local i = (indexOf(LAYOUTS, s.kbLayout) - 1 + d) % #LAYOUTS + 1
        s.kbLayout = LAYOUTS[i].key
        CK:UpdateMethod()
    end)
    selector(L.OPT_DEADZONE, nil, function() return format("%d %%", s.deadzone * 100 + 0.5) end, function(d)
        s.deadzone = math.min(0.40, math.max(0.05, math.floor((s.deadzone + d * 0.05) * 100 + 0.5) / 100))
    end)
    local MAGNETS = {
        { key = "none", name = L.MAGNET_NONE }, { key = "weak", name = L.MAGNET_WEAK },
        { key = "medium", name = L.MAGNET_MEDIUM }, { key = "strong", name = L.MAGNET_STRONG },
    }
    selector(L.OPT_MAGNET, #MAGNETS, function() return MAGNETS[indexOf(MAGNETS, s.magnet)].name end, function(d)
        local i = (indexOf(MAGNETS, s.magnet) - 1 + d) % #MAGNETS + 1
        s.magnet = MAGNETS[i].key
    end)
    check(L.OPT_LINE, function() return s.showLine end, function(v)
        s.showLine = v
        CK:UpdateMethod()
    end)

    -- Look
    y = y - 6
    header(L.OPT_LOOK)
    selector(L.OPT_FONT, #CK.FONTS, function() return CK.FONTS[indexOf(CK.FONTS, s.font)].name end, function(d)
        local i = (indexOf(CK.FONTS, s.font) - 1 + d) % #CK.FONTS + 1
        s.font = CK.FONTS[i].key
        CK:ApplyFont()
        CK:UpdateMethod()
    end)
    selector(L.OPT_GLYPHS, #GLYPH_STYLES, function() return GLYPH_STYLES[indexOf(GLYPH_STYLES, s.glyphStyle)].name end, function(d)
        local i = (indexOf(GLYPH_STYLES, s.glyphStyle) - 1 + d) % #GLYPH_STYLES + 1
        s.glyphStyle = GLYPH_STYLES[i].key
        CK:UpdateGlyphs()
    end)
    check(L.OPT_GAME_GLYPHS, function() return s.gameGlyphs end, function(v)
        s.gameGlyphs = v
        CK:UpdateGlyphs()
    end)

    -- Prediction
    y = y - 6
    header(L.OPT_PREDICTION)
    selector(L.OPT_LANG, #LANGS, function() return LANGS[indexOf(LANGS, currentLang(s))].name end, function(d)
        local i = (indexOf(LANGS, currentLang(s)) - 1 + d) % #LANGS + 1
        local key = LANGS[i].key
        s.dicts.frFR = key == "fr" or key == "both"
        s.dicts.enUS = key == "en" or key == "both"
        CK.Predict:Load()
    end)
    check(L.OPT_LEARN, function() return s.learn end, function(v) s.learn = v end)

    -- Actions
    y = y - 10
    button(L.OPT_RESET_POS, 20, function()
        CK.db.pos = nil
        if CK.frame then CK:RestorePosition() end
    end)
    -- Two clicks to forget (no confirmation popup, see above)
    local forget
    forget = button(L.OPT_FORGET, 220, function()
        if forget.armed then
            forget.armed = false
            forget:SetText(L.OPT_FORGET)
            CK.Predict:Forget()
            CK:Print(L.FORGOT)
        else
            forget.armed = true
            forget:SetText(L.OPT_FORGET_CONFIRM)
            C_Timer.After(4, function()
                forget.armed = false
                forget:SetText(L.OPT_FORGET)
            end)
        end
    end)
    y = y - 34
    local stats = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    stats:SetPoint("TOPLEFT", 24, y)
    refreshers[#refreshers + 1] = function()
        stats:SetText(format(L.STATS, CK.Predict:NumLearned(), CK.Predict:NumEntries()))
    end
    content:SetHeight(-y + 40)

    panel:SetScript("OnShow", function()
        for _, refresh in ipairs(refreshers) do refresh() end
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end
