local _, CK = ...
local L = CK.L

-- The addon's own configuration panel (RB + D-pad down, /ec config): every
-- setting, in tabs (General, Keyboard, Gamepad), driven with the pad or the
-- mouse. Like the keyboard it is our own frame, never a game panel: while it
-- is open the pad is bound to hidden buttons of ours, out of combat only, and
-- released when it closes.
local C = {}
CK.Config = C

local WIDTH, HEIGHT = 820, 580
local kit

C.TABS = { "general", "keyboard", "gamepad", "vibration" }
C.pages = {}

function C:IsOpen()
    return (self.frame and self.frame:IsShown()) or self.placing or false
end

function C:Page()
    return self.pages[self.tab]
end

---------------------------------------------------------------------------
-- Option lists (General, Keyboard...): rows from Options.lua. Kinds:
-- header, info, check, choice (< value >), button, toggle (on / off and a
-- choice, shown in the value; an optional test: A or its button; X switches)
---------------------------------------------------------------------------
local ListPage = {}
ListPage.__index = ListPage
local ROW_H, ROWS = 28, 16

function C.NewListPage(rows)
    return setmetatable({ rows = rows, offset = 0 }, ListPage)
end

local function selectable(row)
    return row and row.kind ~= "header" and row.kind ~= "info"
end

function ListPage:Build(parent)
    local f = CK.NewFrame("Frame", nil, parent)
    f:SetAllPoints()
    self.frame = f
    self.widgets = {}
    local page = self
    for i = 1, ROWS do
        local r = CK.NewFrame("Button", nil, f)
        r:SetSize(770, ROW_H - 2)
        r:SetPoint("TOPLEFT", 10, -(i - 1) * ROW_H)
        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        r.select = kit.nineSlice(r, "ck_select", 128, 32, 10, 10, "ARTWORK")
        r.box = r:CreateTexture(nil, "OVERLAY")
        r.box:SetSize(22, 22)
        r.box:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
        r.tick = r:CreateTexture(nil, "OVERLAY", nil, 1)
        r.tick:SetAllPoints(r.box)
        r.tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        r.label = kit.text(r, 13)
        r.label:SetJustifyH("LEFT")
        r.label:SetWordWrap(false)
        r.value = kit.text(r, 13)
        r.value:SetJustifyH("CENTER")
        r.value:SetWidth(220)
        r.value:SetPoint("RIGHT", -40, 0)
        r.value:SetWordWrap(false)
        r.prev = kit.buildButton(r, "<", function() page:Step(r.index, -1) end)
        r.prev:SetSize(24, 20)
        r.prev:SetPoint("RIGHT", r.value, "LEFT", -6, 0)
        r.next = kit.buildButton(r, ">", function() page:Step(r.index, 1) end)
        r.next:SetSize(24, 20)
        r.next:SetPoint("LEFT", r.value, "RIGHT", 6, 0)
        r.test = kit.buildButton(r, L.CFG_TEST, function()
            local row = r.index and page.list[r.index]
            if row and row.test then row.test() end
        end)
        r.test:SetSize(78, 20)
        r.test:SetPoint("RIGHT", r.prev, "LEFT", -14, 0)
        r:SetScript("OnClick", function(self, button)
            if self.index then
                page.index = self.index
                if page.list[self.index].kind == "choice" then
                    page:Step(self.index, button == "RightButton" and -1 or 1)
                else
                    page:Activate()
                end
            end
        end)
        r:SetScript("OnEnter", function(self)
            if self.index and page.index ~= self.index then
                page.index = self.index
                C:Render()
            end
            local row = self.index and page.list[self.index]
            if row and row.tip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(row.text, 1, 1, 1)
                GameTooltip:AddLine(row.tip, 1, 0.82, 0, true)
                GameTooltip:Show()
            end
        end)
        r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.widgets[i] = r
    end
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(_, delta) page:Scroll(-delta * 3) end)
    f:Hide()
end

function ListPage:Show()
    self.list = self.rows()
    if not selectable(self.list[self.index or 0]) then
        self.index = nil
        for i, row in ipairs(self.list) do
            if selectable(row) then self.index = i break end
        end
    end
    self.frame:Show()
end

function ListPage:Hide() self.frame:Hide() end

function ListPage:Scroll(delta)
    self.offset = math.max(0, math.min(#self.list - ROWS, self.offset + delta))
    C:Render()
end

function ListPage:Move(delta)
    local i = self.index or 0
    repeat i = i + delta until not self.list[i] or selectable(self.list[i])
    if self.list[i] then self.index = i end
    -- Keep the selection and its section title in view
    local top = self.index
    while self.list[top - 1] and not selectable(self.list[top - 1]) do top = top - 1 end
    if top <= self.offset then self.offset = math.max(0, top - 1) end
    if self.index > self.offset + ROWS then self.offset = self.index - ROWS end
    C:Render()
end

function ListPage:Step(index, delta)
    local row = self.list[index]
    if row and (row.kind == "choice" or row.kind == "toggle") then
        row.step(delta)
        self.list = self.rows()
        C:Render()
    end
end

function ListPage:Activate()
    local row = self.list[self.index or 0]
    if not row then return end
    if row.kind == "check" or row.kind == "toggle" then
        row.set(not row.get())
    elseif row.kind == "choice" then
        row.step(1)
    elseif row.kind == "button" then
        row.func()
    end
    -- Rows can depend on others (indented options)
    self.list = self.rows()
    C:Render()
end

function ListPage:Render()
    self.list = self.list or self.rows()
    for i, r in ipairs(self.widgets) do
        local index = self.offset + i
        local row = self.list[index]
        r.index = selectable(row) and index or nil
        r:SetShown(row ~= nil)
        if row then
            local indent = row.indent and 30 or 0
            local enabled = not row.disabled or not row.disabled()
            -- A toggle shows its state in its value ("Off" greyed): no box,
            -- its text where a box's would be
            local boxed = row.kind == "check"
            r.select:SetShown(index == self.index)
            r.box:SetShown(boxed)
            r.tick:SetShown(boxed and row.get() and true or false)
            r.box:ClearAllPoints()
            r.box:SetPoint("LEFT", 8 + indent, 0)
            r.label:ClearAllPoints()
            r.label:SetPoint("LEFT", ((boxed or row.kind == "toggle") and 36 or 10) + indent, 0)
            r.label:SetPoint("RIGHT", (row.kind == "toggle" and -400) or (row.kind == "choice" and -300) or -10, 0)
            r.label:SetText(row.kind == "button" and ("|cffffd100" .. row.text .. "|r") or row.text)
            if row.kind == "header" then
                r.label:SetTextColor(unpack(kit.C.gold))
                r.label:SetPoint("LEFT", 4, -4)
            elseif row.kind == "info" then
                r.label:SetTextColor(0.62, 0.6, 0.55)
            else
                r.label:SetTextColor(unpack(enabled and kit.C.btn or { 0.5, 0.48, 0.42 }))
            end
            local choice = row.kind == "choice" or row.kind == "toggle"
            r.value:SetShown(choice)
            r.prev:SetShown(choice)
            r.next:SetShown(choice)
            r.test:SetShown(row.test ~= nil)
            if row.kind == "toggle" then
                -- Its value is greyed while the box is off
                r.value:SetText(row.value())
                r.value:SetTextColor(unpack(row.get() and kit.C.btn or { 0.5, 0.48, 0.42 }))
            elseif choice then
                r.value:SetText(row.get())
                r.value:SetTextColor(unpack(kit.C.btn))
            end
        end
    end
end

function ListPage:Press(name)
    if name == "UP" or name == "DOWN" then
        self:Move(name == "UP" and -1 or 1)
    elseif name == "LEFT" or name == "RIGHT" then
        self:Step(self.index, name == "LEFT" and -1 or 1)
    elseif name == "A" then
        -- A row with a test (vibrations): A plays it, X turns it on or off
        local row = self.list[self.index or 0]
        if row and row.test then row.test() else self:Activate() end
    elseif name == "X" and self.list[self.index or 0] and self.list[self.index].test then
        self:Activate()
    else
        return false
    end
    return true
end

function ListPage:Help(g)
    local row = self.list and self.list[self.index or 0]
    local help = { g("DPAD_UP") .. " " .. L.MAP_P_MOVE }
    if row and row.test then
        help[#help + 1] = g("DPAD_LEFT") .. " " .. L.CFG_P_PATTERN
        help[#help + 1] = g("A") .. " " .. L.CFG_TEST
    else
        help[#help + 1] = g("DPAD_LEFT") .. " " .. L.CFG_P_CHANGE
        help[#help + 1] = g("A") .. " " .. L.MAP_P_CHOOSE
    end
    help[#help + 1] = g("LB") .. g("RB") .. " " .. L.MAP_P_TAB
    help[#help + 1] = g("B") .. " " .. L.MAP_P_CLOSE
    return help
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local function panel(f)
    local bg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetTexture(kit.TEX .. "ck_panel_bg", "REPEAT", "REPEAT")
    bg:SetHorizTile(true)
    bg:SetVertTile(true)
    bg:SetAllPoints()
    bg:SetVertexColor(1, 1, 1, 0.92)
    local r, g, b = unpack(kit.C.border)
    for _, e in ipairs({ { "TOPLEFT", "TOPRIGHT", nil, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
        { "TOPLEFT", "BOTTOMLEFT", 1, nil }, { "TOPRIGHT", "BOTTOMRIGHT", 1, nil } }) do
        local t = kit.solid(f, "BORDER", r, g, b, 0.7)
        t:SetPoint(e[1]); t:SetPoint(e[2])
        if e[3] then t:SetWidth(e[3]) else t:SetHeight(e[4]) end
    end
end
C.panel = function(f)
    kit = CK.UIKit
    panel(f)
end

function C:Build()
    if self.frame then return end
    kit = CK.UIKit
    local f = CK.NewFrame("Frame", "ControllerKeyboardConfigFrame", UIParent)
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint("CENTER", 0, 30)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:Hide()
    panel(f)
    self.frame = f

    local title = kit.text(f, 16)
    title:SetPoint("TOPLEFT", 16, -13)
    title:SetTextColor(unpack(kit.C.gold))
    title:SetText("Easy Controller")

    -- The tabs share the room between the title and the close button
    f.tabs = {}
    local left, right = 214, WIDTH - 70
    local step = math.floor((right - left) / #C.TABS)
    local lb = f:CreateTexture(nil, "OVERLAY")
    lb:SetSize(22, 22)
    lb:SetPoint("TOPRIGHT", f, "TOPLEFT", left - 4, -12)
    f.lbGlyph = lb
    for i, key in ipairs(C.TABS) do
        local t = kit.buildButton(f, L["CFG_TAB_" .. key:upper()], function() C:SetTab(key) end)
        t:SetSize(step - 6, 26)
        t:SetPoint("TOPLEFT", left + (i - 1) * step, -10)
        t.key = key
        f.tabs[i] = t
    end
    local rb = f:CreateTexture(nil, "OVERLAY")
    rb:SetSize(22, 22)
    rb:SetPoint("TOPLEFT", left + #C.TABS * step - 2, -12)
    f.rbGlyph = rb
    local close = kit.buildButton(f, "X", function() C:Close() end)
    close:SetSize(26, 24)
    close:SetPoint("TOPRIGHT", -10, -10)

    local content = CK.NewFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", 14, -48)
    content:SetPoint("BOTTOMRIGHT", -14, 36)
    f.content = content
    for _, key in ipairs(C.TABS) do
        local page = self.pages[key]
        if page then page:Build(content) end
    end

    f.help = kit.text(f, 11)
    f.help:SetPoint("BOTTOM", 0, 12)
    f.help:SetTextColor(unpack(kit.C.btn))

    f:SetScript("OnUpdate", function(_, elapsed) C:OnUpdate(elapsed) end)
    self:CreateInput()
end

function C:SetTab(key)
    if self.tab == key then return end
    local old = self:Page()
    if old then old:Hide() end
    self.tab = key
    self:Page():Show()
    self:Render()
end

function C:Render()
    local f = self.frame
    if not (f and f:IsShown()) then return end
    CK:SetGlyph(f.lbGlyph, "LB")
    CK:SetGlyph(f.rbGlyph, "RB")
    for _, t in ipairs(f.tabs) do t:SetActive(t.key == self.tab) end
    local page = self:Page()
    page:Render()
    local g = function(key) return CK:GlyphMarkup(key, 16) end
    f.help:SetText(table.concat(page:Help(g), "    "))
end

---------------------------------------------------------------------------
-- Pad input while open: hidden buttons bound with priority, like the keyboard
---------------------------------------------------------------------------
local NAV = {
    PADDUP = "UP", PADDDOWN = "DOWN", PADDLEFT = "LEFT", PADDRIGHT = "RIGHT",
    PAD1 = "A", PAD2 = "B", PAD3 = "X", PAD4 = "Y",
    PADLSHOULDER = "LB", PADRSHOULDER = "RB", ESCAPE = "B",
}
-- Held triggers may add modifiers to the keys
local PREFIXES = { "", "SHIFT-", "CTRL-", "ALT-", "CTRL-SHIFT-", "ALT-SHIFT-", "ALT-CTRL-", "ALT-CTRL-SHIFT-" }
local REPEAT = { UP = true, DOWN = true, LEFT = true, RIGHT = true }

function C:Press(name)
    -- Learning the shortcut: the presses are for it
    if self:IsCapturingChord() then return end
    -- Placing the extra buttons on the HUD
    if self.placing then
        CK.Paddles:PlacementPress(name)
        return
    end
    local page = self:Page()
    if page:Press(name) then return end
    if name == "LB" or name == "RB" then
        local index = 1
        for i, key in ipairs(C.TABS) do
            if key == self.tab then index = i end
        end
        self:SetTab(C.TABS[(index - 1 + (name == "LB" and -1 or 1)) % #C.TABS + 1])
    elseif name == "B" then
        self:Close()
    end
end

function C:CreateInput()
    for key, name in pairs(NAV) do
        local b = CK.NewFrame("Button", "ControllerKeyboardConfigPad" .. key)
        b:SetSize(1, 1)
        b:RegisterForClicks("AnyDown", "AnyUp")
        b:SetScript("OnClick", function(_, _, down)
            -- B acts on release: closing the panel on the press would leave
            -- the release to the game alone
            if name == "B" then
                if down == false then C:Press(name) end
                return
            end
            if down == false then
                if C.repeatName == name then C.repeatName = nil end
                return
            end
            C:Press(name)
            if REPEAT[name] then
                C.repeatName, C.repeatAt = name, GetTime() + 0.35
            end
        end)
    end
end

local function bindKey(f, key)
    local name = "ControllerKeyboardConfigPad" .. key
    if key == "ESCAPE" then
        SetOverrideBindingClick(f, true, key, name)
    else
        for _, prefix in ipairs(PREFIXES) do SetOverrideBindingClick(f, true, prefix .. key, name) end
    end
end

-- A button still held (RB of the RB + D-pad down shortcut...) is taken only
-- once released: its release belongs to the game, which saw it pressed (RB
-- held is the game's hostile targeting, until it is released)
function C:BindPad()
    if InCombatLockdown() or not self.frame then return end
    local f = self.frame
    ClearOverrideBindings(f)
    self.heldKeys = {}
    for key in pairs(NAV) do
        if key ~= "ESCAPE" and IsKeyDown and IsKeyDown(key) then
            self.heldKeys[key] = true
        else
            bindKey(f, key)
        end
    end
end

function C:BindReleasedKeys()
    if not self.heldKeys or not next(self.heldKeys) or InCombatLockdown() then return end
    for key in pairs(self.heldKeys) do
        if not IsKeyDown(key) then
            self.heldKeys[key] = nil
            bindKey(self.frame, key)
        end
    end
end

function C:UnbindPad()
    self.heldKeys = nil
    if self.frame and not InCombatLockdown() then ClearOverrideBindings(self.frame) end
end

function C:OnUpdate(elapsed)
    self:BindReleasedKeys()
    local page = self:Page()
    if page and page.OnUpdate then page:OnUpdate(elapsed) end
    if self.repeatName and GetTime() >= self.repeatAt then
        self.repeatAt = GetTime() + 0.08
        self:Press(self.repeatName)
    end
end

---------------------------------------------------------------------------
-- Open / close
---------------------------------------------------------------------------
function C:Open(tab)
    if CK:BlockedByCombat() then return end
    self:Build()
    if tab and self.pages[tab] then
        if self.frame:IsShown() then self:SetTab(tab) return end
        self.tab = tab
    end
    if self.frame:IsShown() then return end
    self.tab = self.tab or "general"
    -- What the game binds, before our own pad bindings hide it
    CK.Mapping:TakeSnapshot()
    self.frame:Show()
    self:Page():Show()
    self:BindPad()
    self:Render()
end

function C:Close()
    if not self:IsOpen() then return end
    if self.placing then CK.Paddles:StopPlacement() end
    CK.Paddles:StopCapture(nil)
    local page = self:Page()
    if page then page:Hide() end
    self:UnbindPad()
    self.frame:Hide()
    self.repeatName = nil
    CK.Mapping:DropSnapshot()
    CK.Mapping:Apply()
end

function C:Toggle(tab)
    if self.frame and self.frame:IsShown() then self:Close() else self:Open(tab) end
end

-- Placing the extra buttons happens on the HUD: the panel steps aside and
-- keeps the pad
function C:BeginPlacement()
    self.placing = true
    self.frame:Hide()
    self.repeatName = nil
end

function C:EndPlacement()
    self.placing = false
    self.frame:Show()
    self:Page():Show()
    self:Render()
end

-- Nothing of the game's has the pad: no settings, game menu, chat or other
-- gamepad window
function C:GameIsFree()
    if SettingsPanel and SettingsPanel:IsShown() then return false end
    if GameMenuFrame and GameMenuFrame:IsShown() then return false end
    local manager = GamepadMode and GamepadMode.FrameControlsManager
    if manager and manager.GetActiveFrame and manager:GetActiveFrame() then return false end
    local chat = CK.ActiveChatWindow and CK.ActiveChatWindow()
    return not (chat and chat:HasFocus())
end

-- From the game's options or the chat: those have the pad, and closing the
-- options brings back the game menu, whose B would close the panel too.
-- Open once the player is back in the game.
function C:OpenWhenFree(tab)
    if self:GameIsFree() then
        self:Open(tab)
        return
    end
    self.openLater = tab or self.tab or "general"
    if SettingsPanel and SettingsPanel:IsShown() then CK:Print(L.CFG_OPEN_LATER) end
    if self.laterTicker then return end
    local tries = 0
    self.laterTicker = C_Timer.NewTicker(0.25, function(ticker)
        tries = tries + 1
        local later = C.openLater
        if later and C:GameIsFree() and not InCombatLockdown() then
            C.openLater = nil
            C:Open(later)
        end
        -- Given up after two minutes
        if not C.openLater or tries > 480 then
            ticker:Cancel()
            C.laterTicker, C.openLater = nil, nil
        end
    end)
end

function C:Init()
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:SetScript("OnEvent", function() C:Close() end)
    -- A game window opened meanwhile (Start menu...) rebinds the pad when it
    -- closes: take the panel's keys back
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("Gamepad.RefreshFrameFocus", function()
            C_Timer.After(0, function()
                local manager = GamepadMode and GamepadMode.FrameControlsManager
                local focused = manager and manager.GetActiveFrame and manager:GetActiveFrame()
                if C:IsOpen() and not focused and not InCombatLockdown() then C:BindPad() end
            end)
        end, C)
    end
    -- The panel's shortcut: a button held, another pressed (RB + D-pad down
    -- by default: with RB held, the game's hostile targeting bar turns its
    -- D-pad off). Only watched, never bound: the game keeps whatever it does
    -- with them, and the game's own windows keep their buttons.
    local watch = CK.NewFrame("Frame", nil, UIParent)
    C.watch = watch
    local wasDown = false
    watch:SetScript("OnUpdate", function()
        local s = CK.db.settings
        local chord = s.shortcut
        if not (s.features.configShortcut and chord and IsKeyDown) then
            wasDown = false
            return
        end
        -- While the panel is open, and after it closes until the buttons
        -- are released, the combination does nothing
        if C:IsOpen() then
            wasDown = true
            return
        end
        local down = IsKeyDown(chord.hold) and IsKeyDown(chord.press) and true or false
        if down and not wasDown and not InCombatLockdown() and C:GameIsFree() then C:Open() end
        wasDown = down
    end)
end

---------------------------------------------------------------------------
-- Learning the panel's shortcut: hold a button, press a second one
---------------------------------------------------------------------------
function C:StopChordCapture(chord)
    local f = self.chordFrame
    if not (f and f:IsShown()) then return end
    f:Hide()
    if f.timer then f.timer:Cancel() end
    if not InCombatLockdown() then
        f:EnableKeyboard(false)
        if f.EnableGamePadButton then f:EnableGamePadButton(false) end
    end
    local onDone = f.onDone
    f.onDone, f.held = nil, nil
    if onDone then onDone(chord) end
end

function C:CaptureChord(onDone)
    if CK:BlockedByCombat() then return end
    local f = self.chordFrame
    if not f then
        f = CK.NewFrame("Frame", nil, UIParent)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetSize(1, 1)
        f:SetPoint("CENTER")
        f:SetScript("OnKeyDown", function(_, key)
            if key == "ESCAPE" then C:StopChordCapture(nil) end
        end)
        if f.EnableGamePadButton then
            f:SetScript("OnGamePadButtonDown", function(self, button)
                local held = self.held
                if held and held ~= button and IsKeyDown(held) then
                    C:StopChordCapture({ hold = held, press = button })
                else
                    self.held = button
                end
            end)
            -- B pressed and released alone cancels
            f:SetScript("OnGamePadButtonUp", function(self, button)
                if button == self.held then
                    if button == "PAD2" then
                        C:StopChordCapture(nil)
                    else
                        self.held = nil
                    end
                end
            end)
        end
        f:Hide()
        self.chordFrame = f
    end
    f.onDone, f.held = onDone, nil
    f:EnableKeyboard(true)
    f:SetPropagateKeyboardInput(false)
    if f.EnableGamePadButton then f:EnableGamePadButton(true) end
    f:Show()
    f.timer = C_Timer.NewTimer(10, function() C:StopChordCapture(nil) end)
end

function C:IsCapturingChord()
    return self.chordFrame and self.chordFrame:IsShown() or false
end

-- Key bindings
function ControllerKeyboard_OpenConfig()
    C:Toggle()
end

function ControllerKeyboard_OpenMap()
    C:Toggle("gamepad")
end
