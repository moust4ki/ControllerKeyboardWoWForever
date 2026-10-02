local _, CK = ...

-- Gamepad button glyphs: the game's own atlases when this client has them,
-- otherwise the Claude Design textures shipped with the addon.
local TEX = "Interface\\AddOns\\EasyController\\textures\\"

local FALLBACK = {
    A = "ck_g_a", B = "ck_g_b", X = "ck_g_x", Y = "ck_g_y",
    LB = "ck_g_lb", RB = "ck_g_rb", LT = "ck_g_lt", RT = "ck_g_rt",
    LS = "ck_g_ls", RS = "ck_g_rs",
    DPAD = "ck_g_dpad", DPAD_LR = "ck_g_dpad_lr", DPAD_UP = "ck_g_dpad_up",
    DPAD_LEFT = "ck_g_dpad_lr", DPAD_RIGHT = "ck_g_dpad_lr", DPAD_DOWN = "ck_g_dpad",
}

-- Atlas names tried first, per glyph style. /ec glyphs lists the gamepad
-- atlases this client really has, to complete these lists.
local ATLAS = {
    xbox = {
        A = { "Gamepad_Ltr_A_64", "Gamepad_Ltr_A_32" },
        B = { "Gamepad_Ltr_B_64", "Gamepad_Ltr_B_32" },
        X = { "Gamepad_Ltr_X_64", "Gamepad_Ltr_X_32" },
        Y = { "Gamepad_Ltr_Y_64", "Gamepad_Ltr_Y_32" },
        LB = { "Gamepad_Ltr_LShoulder_64", "Gamepad_Gen_LShoulder_64" },
        RB = { "Gamepad_Ltr_RShoulder_64", "Gamepad_Gen_RShoulder_64" },
        LT = { "Gamepad_Ltr_LTrigger_64", "Gamepad_Gen_LTrigger_64" },
        RT = { "Gamepad_Ltr_RTrigger_64", "Gamepad_Gen_RTrigger_64" },
        LS = { "Gamepad_Gen_LStickIn_64", "Gamepad_Ltr_LStickIn_64" },
        RS = { "Gamepad_Gen_RStickIn_64", "Gamepad_Ltr_RStickIn_64" },
        DPAD_UP = { "Gamepad_Gen_Up_64", "Gamepad_Ltr_Up_64" },
        DPAD_LEFT = { "Gamepad_Gen_Left_64", "Gamepad_Ltr_Left_64" },
        DPAD_RIGHT = { "Gamepad_Gen_Right_64", "Gamepad_Ltr_Right_64" },
        DPAD_DOWN = { "Gamepad_Gen_Down_64", "Gamepad_Ltr_Down_64" },
    },
    playstation = {
        A = { "Gamepad_Shp_Cross_64", "Gamepad_Shp_Cross_32" },
        B = { "Gamepad_Shp_Circle_64", "Gamepad_Shp_Circle_32" },
        X = { "Gamepad_Shp_Square_64", "Gamepad_Shp_Square_32" },
        Y = { "Gamepad_Shp_Triangle_64", "Gamepad_Shp_Triangle_32" },
        LB = { "Gamepad_Shp_LShoulder_64", "Gamepad_Gen_LShoulder_64" },
        RB = { "Gamepad_Shp_RShoulder_64", "Gamepad_Gen_RShoulder_64" },
        LT = { "Gamepad_Shp_LTrigger_64", "Gamepad_Gen_LTrigger_64" },
        RT = { "Gamepad_Shp_RTrigger_64", "Gamepad_Gen_RTrigger_64" },
        LS = { "Gamepad_Gen_LStickIn_64", "Gamepad_Shp_LStickIn_64" },
        RS = { "Gamepad_Gen_RStickIn_64", "Gamepad_Shp_RStickIn_64" },
        DPAD_UP = { "Gamepad_Gen_Up_64", "Gamepad_Shp_Up_64" },
        DPAD_LEFT = { "Gamepad_Gen_Left_64", "Gamepad_Shp_Left_64" },
        DPAD_RIGHT = { "Gamepad_Gen_Right_64", "Gamepad_Shp_Right_64" },
        DPAD_DOWN = { "Gamepad_Gen_Down_64", "Gamepad_Shp_Down_64" },
    },
}

local function atlasExists(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

function CK:SetGlyph(tex, key)
    local style = self.db.settings.glyphStyle
    if self.db.settings.gameGlyphs then
        for _, name in ipairs((ATLAS[style] or ATLAS.xbox)[key] or {}) do
            if atlasExists(name) then
                tex:SetAtlas(name)
                return
            end
        end
    end
    tex:SetTexture(TEX .. (FALLBACK[key] or "ck_g_a"))
    tex:SetTexCoord(0, 1, 0, 1)
end

-- The same glyph inline in a text ("|A...|a" or "|T...|t")
function CK:GlyphMarkup(key, size)
    size = size or 16
    local style = self.db.settings.glyphStyle
    if self.db.settings.gameGlyphs then
        for _, name in ipairs((ATLAS[style] or ATLAS.xbox)[key] or {}) do
            if atlasExists(name) then return format("|A:%s:%d:%d|a", name, size, size) end
        end
    end
    return format("|T%s%s:%d:%d|t", TEX, FALLBACK[key] or "ck_g_a", size, size)
end

-- /ec glyphs: print the gamepad atlases found in this client
function CK:ListGlyphAtlases()
    local prefixes = { "Gamepad_Ltr_", "Gamepad_Shp_", "Gamepad_Gen_", "Gamepad_Rev_" }
    local names = {
        "A", "B", "X", "Y", "Cross", "Circle", "Square", "Triangle",
        "LShoulder", "RShoulder", "LTrigger", "RTrigger", "LStickIn", "RStickIn",
        "LStick", "RStick", "Up", "Down", "Left", "Right", "Menu", "View",
        "Share", "Options", "System", "Paddle1", "Paddle2",
    }
    local sizes = { "_64", "_32", "_16", "" }
    local found = {}
    for _, p in ipairs(prefixes) do
        for _, n in ipairs(names) do
            for _, s in ipairs(sizes) do
                local name = p .. n .. s
                if atlasExists(name) then
                    found[#found + 1] = name
                    break
                end
            end
        end
    end
    if #found == 0 then
        self:Print(CK.L.GLYPHS_NONE)
    else
        self:Print(CK.L.GLYPHS_FOUND, #found)
        for i = 1, #found, 4 do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. table.concat(found, "  ", i, math.min(i + 3, #found)))
        end
    end
end
