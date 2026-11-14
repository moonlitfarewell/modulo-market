local MM = _G.ModuloMarket
if not MM then return end

local Theme = {}
MM.Theme = Theme

local defaults = {
    theme = "blizzlike",
    modernPalette = "dark",
    customAccent = { r = 1.0, g = 0.19, b = 0.31 },
}

local function Clamp(value)
    value = tonumber(value) or 0
    return math.max(0, math.min(1, value))
end

local function CopyColor(color)
    return { r = Clamp(color and color.r), g = Clamp(color and color.g), b = Clamp(color and color.b) }
end

local function GetClassAccent()
    local classToken
    if type(_G.UnitClass) == "function" then
        local _, token = _G.UnitClass("player")
        classToken = token
    end
    local colors = _G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS
    local color = colors and classToken and colors[classToken]
    if color and color.r and color.g and color.b then
        return { r = Clamp(color.r), g = Clamp(color.g), b = Clamp(color.b) }
    end
    return { r = 0.25, g = 0.72, b = 1.0 }
end

function Theme.Initialize()
    if type(MM.db) ~= "table" then return end
    if MM.db.theme ~= "modern" then MM.db.theme = "blizzlike" end
    if MM.db.modernPalette ~= "class" and MM.db.modernPalette ~= "custom" then
        MM.db.modernPalette = "dark"
    end
    local color = MM.db.customAccent
    if type(color) ~= "table" then color = defaults.customAccent end
    MM.db.customAccent = CopyColor(color)
end

function Theme.GetTheme()
    return MM.db and MM.db.theme == "modern" and "modern" or "blizzlike"
end

function Theme.GetAccent()
    local mode = MM.db and MM.db.modernPalette or "dark"
    if mode == "class" then return GetClassAccent() end
    if mode == "custom" then return CopyColor(MM.db and MM.db.customAccent or defaults.customAccent) end
    return { r = 0.61, g = 0.65, b = 0.72 }
end

local function Mix(a, b, amount)
    return a + (b - a) * amount
end

function Theme.GetColor(role, fallback)
    if Theme.GetTheme() ~= "modern" then
        return fallback or { 1, 1, 1, 1 }
    end
    local accent = Theme.GetAccent()
    local r, g, b = accent.r, accent.g, accent.b
    local palette = {
        surface = { 0.025, 0.030, 0.043, 0.97 },
        surfaceAlt = { 0.050, 0.060, 0.080, 0.98 },
        surfaceRaised = { 0.085, 0.095, 0.125, 0.96 },
        panelHeader = { Mix(0.055, r, 0.17), Mix(0.060, g, 0.17), Mix(0.080, b, 0.17), 0.94 },
        border = { r, g, b, 0.42 },
        borderStrong = { r, g, b, 0.78 },
        accent = { r, g, b, 1 },
        accentSoft = { r, g, b, 0.48 },
        accentWash = { r, g, b, 0.17 },
        selected = { Mix(0.10, r, 0.46), Mix(0.045, g, 0.34), Mix(0.075, b, 0.40), 0.96 },
        selectedWash = { r, g, b, 0.25 },
        selectedEdge = { r, g, b, 1 },
        tabActive = { Mix(0.10, r, 0.38), Mix(0.055, g, 0.28), Mix(0.075, b, 0.32), 1 },
        tabInactive = { 0.035, 0.042, 0.058, 0.99 },
        textAccent = { r, g, b, 1 },
        textPrimary = { 0.91, 0.93, 0.97, 1 },
        textMuted = { 0.57, 0.61, 0.69, 1 },
        dropdown = { 0.035, 0.042, 0.058, 0.99 },
        control = { 0.045, 0.052, 0.070, 0.98 },
        controlHighlight = { r, g, b, 0.12 },
        divider = { r, g, b, 0.50 },
        historyBaseline = { r, g, b, 0.52 },
        historyBar = { r, g, b, 0.88 },
    }
    return palette[role] or fallback or { r, g, b, 1 }
end

local textures, fontStrings = {}, {}
local textureEntries, fontEntries = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
function Theme.SetTexture(texture, role, fallback)
    if not texture then return end
    local entry = textureEntries[texture]
    if not entry then
        entry = { object = texture }
        textureEntries[texture] = entry
        textures[#textures + 1] = entry
    end
    entry.role, entry.fallback = role, fallback
    local c = Theme.GetColor(role, fallback)
    texture:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
end

function Theme.SetFontColor(fontString, role, fallback)
    if not fontString or type(fontString.SetTextColor) ~= "function" then return end
    local entry = fontEntries[fontString]
    if not entry then
        entry = { object = fontString }
        fontEntries[fontString] = entry
        fontStrings[#fontStrings + 1] = entry
    end
    entry.role, entry.fallback = role, fallback
    local c = Theme.GetColor(role, fallback)
    fontString:SetTextColor(c[1], c[2], c[3], c[4] or 1)
end

function Theme.ApplyRegistered()
    for i = #textures, 1, -1 do
        local entry = textures[i]
        if not entry.object or (entry.object.IsObjectType and not entry.object:IsObjectType("Texture")) then
            table.remove(textures, i)
        else
            local c = Theme.GetColor(entry.role, entry.fallback)
            entry.object:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
        end
    end
    for i = #fontStrings, 1, -1 do
        local entry = fontStrings[i]
        if not entry.object then
            table.remove(fontStrings, i)
        else
            local c = Theme.GetColor(entry.role, entry.fallback)
            entry.object:SetTextColor(c[1], c[2], c[3], c[4] or 1)
        end
    end
end

function Theme.SetTheme(value)
    if not MM.db then return end
    MM.db.theme = value == "modern" and "modern" or "blizzlike"
    Theme.ApplyRegistered()
end

function Theme.SetPalette(value)
    if not MM.db then return end
    if value ~= "class" and value ~= "custom" then value = "dark" end
    MM.db.modernPalette = value
    Theme.ApplyRegistered()
end

function Theme.SetCustomAccent(r, g, b)
    if not MM.db then return end
    MM.db.customAccent = { r = Clamp(r), g = Clamp(g), b = Clamp(b) }
    Theme.ApplyRegistered()
end

local function MakeLabel(parent, text, x, y, width, template)
    local label = parent:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width or 500)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function MakeButton(parent, text, x, y, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 190, 26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function BuildDropdown(parent, labelText, x, y, width, options, getter, setter)
    MakeLabel(parent, labelText, x, y + 20, width)
    local button = MakeButton(parent, "", x, y - 5, width, nil)
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(200)
    popup:SetSize(width, #options * 25 + 8)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.035, 0.040, 0.055, 0.99)
    local border = popup:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT"); border:SetPoint("BOTTOMRIGHT")
    border:SetColorTexture(0.40, 0.43, 0.52, 0.9)
    popup.buttons = {}
    for i, option in ipairs(options) do
        local item = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
        item:SetSize(width - 8, 23)
        item:SetPoint("TOPLEFT", popup, "TOPLEFT", 4, -4 - ((i - 1) * 25))
        item:SetText(option.label)
        item:SetScript("OnClick", function()
            setter(option.value)
            popup:Hide()
        end)
        popup.buttons[#popup.buttons + 1] = item
    end
    popup:Hide()
    local function Refresh()
        local value = getter()
        for _, option in ipairs(options) do
            if option.value == value then button:SetText(option.label); return end
        end
        button:SetText(options[1].label)
    end
    button:SetScript("OnClick", function()
        if popup:IsShown() then popup:Hide() else
            popup:ClearAllPoints()
            popup:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
            popup:Show()
        end
    end)
    button:HookScript("OnHide", function() popup:Hide() end)
    Refresh()
    return button, Refresh, popup
end

local settingsPanel
local function OpenMarket()
    if InCombatLockdown and InCombatLockdown() then
        if MM.Print then MM.Print("Cannot open Modulo Market during combat.") end
        return
    end
    if MM.MarketUI and MM.MarketUI.Show then MM.MarketUI.Show() end
end

local function OpenColorPicker(swatch)
    if not _G.ColorPickerFrame then
        if MM.Print then MM.Print("The client colour picker is unavailable.") end
        return
    end
    local old = CopyColor(MM.db.customAccent or defaults.customAccent)
    local function ReadColor()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        Theme.SetCustomAccent(r, g, b)
        if swatch then
            local c = Theme.GetAccent()
            swatch:SetColorTexture(c.r, c.g, c.b, 1)
        end
    end
    local function Restore()
        Theme.SetCustomAccent(old.r, old.g, old.b)
        if swatch then swatch:SetColorTexture(old.r, old.g, old.b, 1) end
    end
    if type(ColorPickerFrame.SetupColorPickerAndShow) == "function" then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = old.r, g = old.g, b = old.b, hasOpacity = false,
            swatchFunc = ReadColor,
            cancelFunc = Restore,
        })
    else
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.func = ReadColor
        ColorPickerFrame.swatchFunc = ReadColor
        ColorPickerFrame.cancelFunc = Restore
        ColorPickerFrame:SetColorRGB(old.r, old.g, old.b)
        ColorPickerFrame:Show()
    end
end

local function RegisterSettingsPanel()
    if settingsPanel then return end
    settingsPanel = CreateFrame("Frame")
    settingsPanel.name = "Modulo Market"
    MakeLabel(settingsPanel, "Modulo Market Settings", 18, -18, 560, "GameFontNormalLarge")
    MakeLabel(settingsPanel, "Open the market window and choose its visual theme. These settings do not change market data or calculations.", 18, -48, 680, "GameFontHighlight")
    MakeButton(settingsPanel, "Open Modulo Market (/mm)", 18, -88, 220, OpenMarket)
    local refreshTheme
    local themeButton
    themeButton, refreshTheme = BuildDropdown(settingsPanel, "Market appearance", 18, -150, 240, {
        { label = "Blizz-like", value = "blizzlike" },
        { label = "Modern", value = "modern" },
    }, Theme.GetTheme, function(value) Theme.SetTheme(value); refreshTheme(); Theme.RefreshSettingsVisibility() end)
    Theme.themeDropdownRefresh = refreshTheme
    local modernHeader = MakeLabel(settingsPanel, "Modern appearance", 18, -220, 500, "GameFontNormalLarge")
    Theme.modernHeader = modernHeader
    Theme.paletteDescription = MakeLabel(settingsPanel, "Choose the accent colour system used by the Modern theme.", 18, -248, 600, "GameFontHighlight")
    local refreshPalette
    local paletteButton
    paletteButton, refreshPalette = BuildDropdown(settingsPanel, "Modern colour palette", 18, -292, 240, {
        { label = "Dark (grey tone)", value = "dark" },
        { label = "Class (WoW class colour)", value = "class" },
        { label = "Custom", value = "custom" },
    }, function() return MM.db.modernPalette end, function(value) Theme.SetPalette(value); refreshPalette(); Theme.RefreshSettingsVisibility() end)
    Theme.paletteDropdownRefresh = refreshPalette
    local swatch = settingsPanel:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(26, 26)
    swatch:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 280, -324)
    Theme.customSwatch = swatch
    local customButton = MakeButton(settingsPanel, "Choose custom colour…", 316, -324, 190, function() OpenColorPicker(swatch) end)
    Theme.customButton = customButton
    Theme.customDescription = MakeLabel(settingsPanel, "Custom accent is saved to ModuloMarketDB and applies only while Modern is selected.", 18, -374, 650, "GameFontDisableSmall")
    Theme.RefreshSettingsVisibility = function()
        local modern = Theme.GetTheme() == "modern"
        local custom = modern and MM.db.modernPalette == "custom"
        if Theme.modernHeader then if modern then Theme.modernHeader:Show() else Theme.modernHeader:Hide() end end
        if paletteButton then if modern then paletteButton:Show() else paletteButton:Hide() end end
        if Theme.paletteDescription then if modern then Theme.paletteDescription:Show() else Theme.paletteDescription:Hide() end end
        if Theme.customDescription then if custom then Theme.customDescription:Show() else Theme.customDescription:Hide() end end
        if swatch then
            if custom then
                local c = Theme.GetAccent(); swatch:SetColorTexture(c.r, c.g, c.b, 1); swatch:Show()
            else swatch:Hide() end
        end
        if customButton then if custom then customButton:Show() else customButton:Hide() end end
    end
    Theme.RefreshSettingsVisibility()
    settingsPanel:SetScript("OnShow", function()
        if Theme.themeDropdownRefresh then Theme.themeDropdownRefresh() end
        if Theme.paletteDropdownRefresh then Theme.paletteDropdownRefresh() end
        Theme.RefreshSettingsVisibility()
    end)
    if _G.Settings and type(Settings.RegisterCanvasLayoutCategory) == "function" and type(Settings.RegisterAddOnCategory) == "function" then
        local category = Settings.RegisterCanvasLayoutCategory(settingsPanel, settingsPanel.name)
        Settings.RegisterAddOnCategory(category)
        Theme.settingsCategory = category
    elseif type(_G.InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(settingsPanel)
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    RegisterSettingsPanel()
    loader:UnregisterEvent("PLAYER_LOGIN")
end)
