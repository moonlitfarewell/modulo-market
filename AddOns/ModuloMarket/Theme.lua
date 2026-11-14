local MM = _G.ModuloMarket
if not MM then return end

local Theme = {}
MM.Theme = Theme

local defaults = {
    marketAppearance = "blizzlike",
    blizzlikeStyle = "classic",
    modernPalette = "dark",
    blizzlikeCustomAccent = { r = 1.0, g = 0.19, b = 0.31 },
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
    -- 0.11.0's "Modern" was a colour treatment on the old Blizzard-style
    -- window. Preserve that exact choice as a Blizz-like style on upgrade;
    -- the new Modern value now selects a separate window implementation.
    if MM.db.marketAppearance ~= "modern" and MM.db.marketAppearance ~= "blizzlike" then
        MM.db.marketAppearance = "blizzlike"
        if MM.db.theme == "modern" then
            local oldPalette = MM.db.modernPalette
            MM.db.blizzlikeStyle = (oldPalette == "class" or oldPalette == "custom") and oldPalette or "dark"
            if oldPalette == "custom" and type(MM.db.blizzlikeCustomAccent) ~= "table" then
                MM.db.blizzlikeCustomAccent = CopyColor(MM.db.customAccent or defaults.customAccent)
            end
        elseif MM.db.blizzlikeStyle ~= "dark" and MM.db.blizzlikeStyle ~= "class"
            and MM.db.blizzlikeStyle ~= "custom" then
            MM.db.blizzlikeStyle = "classic"
        end
    end
    if MM.db.blizzlikeStyle ~= "dark" and MM.db.blizzlikeStyle ~= "class"
        and MM.db.blizzlikeStyle ~= "custom" then MM.db.blizzlikeStyle = "classic" end
    if MM.db.modernPalette ~= "class" and MM.db.modernPalette ~= "custom" then
        MM.db.modernPalette = "dark"
    end
    MM.db.blizzlikeCustomAccent = CopyColor(MM.db.blizzlikeCustomAccent or defaults.blizzlikeCustomAccent)
    MM.db.customAccent = CopyColor(MM.db.customAccent or defaults.customAccent)
    MM.db.theme = MM.db.marketAppearance
end

function Theme.GetTheme()
    return MM.db and MM.db.marketAppearance == "modern" and "modern" or "blizzlike"
end

function Theme.GetBlizzlikeStyle()
    local value = MM.db and MM.db.blizzlikeStyle
    if value == "dark" or value == "class" or value == "custom" then return value end
    return "classic"
end

function Theme.GetModernPalette()
    local value = MM.db and MM.db.modernPalette
    if value == "class" or value == "custom" then return value end
    return "dark"
end

function Theme.GetBlizzlikeAccent()
    local mode = Theme.GetBlizzlikeStyle()
    if mode == "class" then return GetClassAccent() end
    if mode == "custom" then return CopyColor(MM.db and MM.db.blizzlikeCustomAccent or defaults.blizzlikeCustomAccent) end
    if mode == "dark" then return { r = 0.61, g = 0.65, b = 0.72 } end
    return { r = 0.96, g = 0.72, b = 0.25 }
end

function Theme.GetModernAccent()
    local mode = Theme.GetModernPalette()
    if mode == "class" then return GetClassAccent() end
    if mode == "custom" then return CopyColor(MM.db and MM.db.customAccent or defaults.customAccent) end
    return { r = 0.61, g = 0.65, b = 0.72 }
end

-- Kept as a compatibility helper for the settings swatch and older callers.
function Theme.GetAccent()
    return Theme.GetTheme() == "modern" and Theme.GetModernAccent() or Theme.GetBlizzlikeAccent()
end

local function Mix(a, b, amount)
    return a + (b - a) * amount
end

local function BuildPalette(accent, modernBase)
    local r, g, b = accent.r, accent.g, accent.b
    local base = modernBase and { 0.025, 0.030, 0.043 } or { 0.035, 0.032, 0.028 }
    local raised = modernBase and { 0.085, 0.095, 0.125 } or { 0.075, 0.060, 0.040 }
    return {
        surface = { base[1], base[2], base[3], 0.97 },
        surfaceAlt = { 0.050, 0.060, 0.080, 0.98 },
        surfaceRaised = { raised[1], raised[2], raised[3], 0.96 },
        panelHeader = { Mix(base[1], r, 0.17), Mix(base[2], g, 0.17), Mix(base[3], b, 0.17), 0.94 },
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
end

function Theme.GetColor(role, fallback)
    if Theme.GetBlizzlikeStyle() == "classic" then return fallback or { 1, 1, 1, 1 } end
    local palette = BuildPalette(Theme.GetBlizzlikeAccent(), false)
    return palette[role] or fallback or { 1, 1, 1, 1 }
end

function Theme.GetModernColor(role, fallback)
    local palette = BuildPalette(Theme.GetModernAccent(), true)
    return palette[role] or fallback or { 1, 1, 1, 1 }
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
    local previous = Theme.GetTheme()
    MM.db.marketAppearance = value == "modern" and "modern" or "blizzlike"
    MM.db.theme = MM.db.marketAppearance
    Theme.ApplyRegistered()
    if previous ~= MM.db.marketAppearance and MM.MarketUI and MM.MarketUI.SwitchPresentation then
        MM.MarketUI.SwitchPresentation()
    end
end

function Theme.SetPalette(value)
    if not MM.db then return end
    if value ~= "class" and value ~= "custom" then value = "dark" end
    MM.db.modernPalette = value
    if MM.ModernUI and MM.ModernUI.ApplyTheme then MM.ModernUI.ApplyTheme() end
end

function Theme.SetBlizzlikeStyle(value)
    if not MM.db then return end
    if value ~= "dark" and value ~= "class" and value ~= "custom" then value = "classic" end
    MM.db.blizzlikeStyle = value
    Theme.ApplyRegistered()
end

function Theme.SetCustomAccent(r, g, b)
    if not MM.db then return end
    MM.db.customAccent = { r = Clamp(r), g = Clamp(g), b = Clamp(b) }
    if MM.ModernUI and MM.ModernUI.ApplyTheme then MM.ModernUI.ApplyTheme() end
end

function Theme.SetBlizzlikeCustomAccent(r, g, b)
    if not MM.db then return end
    MM.db.blizzlikeCustomAccent = { r = Clamp(r), g = Clamp(g), b = Clamp(b) }
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
    local sectionLabel = MakeLabel(parent, labelText, x, y + 20, width)
    local button = MakeButton(parent, "", x, y - 5, width, nil)
    button.sectionLabel = sectionLabel
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
    return button, Refresh
end

local settingsPanel
local function OpenMarket()
    if InCombatLockdown and InCombatLockdown() then
        if MM.Print then MM.Print("Cannot open Modulo Market during combat.") end
        return
    end
    if MM.MarketUI and MM.MarketUI.Show then MM.MarketUI.Show() end
end

local function OpenColorPicker(swatch, appearance)
    if not _G.ColorPickerFrame then
        if MM.Print then MM.Print("The client colour picker is unavailable.") end
        return
    end
    local source = appearance == "blizzlike" and MM.db.blizzlikeCustomAccent or MM.db.customAccent
    local old = CopyColor(source or (appearance == "blizzlike" and defaults.blizzlikeCustomAccent or defaults.customAccent))
    local function Set(r, g, b)
        if appearance == "blizzlike" then Theme.SetBlizzlikeCustomAccent(r, g, b)
        else Theme.SetCustomAccent(r, g, b) end
        local c = appearance == "blizzlike" and Theme.GetBlizzlikeAccent() or Theme.GetModernAccent()
        if swatch then swatch:SetColorTexture(c.r, c.g, c.b, 1) end
    end
    local function ReadColor()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        Set(r, g, b)
    end
    local function Restore() Set(old.r, old.g, old.b) end
    if type(ColorPickerFrame.SetupColorPickerAndShow) == "function" then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = old.r, g = old.g, b = old.b, hasOpacity = false,
            swatchFunc = ReadColor, cancelFunc = Restore,
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
    MakeLabel(settingsPanel, "Modulo Market Settings", 18, -18, 620, "GameFontNormalLarge")
    MakeLabel(settingsPanel, "Choose which Modulo Market window to open. Both appearances use the same market data and calculations.", 18, -48, 760, "GameFontHighlight")
    MakeButton(settingsPanel, "Open Modulo Market (/mm)", 18, -88, 220, OpenMarket)

    local refreshAppearance
    local appearanceButton
    appearanceButton, refreshAppearance = BuildDropdown(settingsPanel, "Market appearance", 18, -150, 260, {
        { label = "Blizz-like window", value = "blizzlike" },
        { label = "Modern window", value = "modern" },
    }, Theme.GetTheme, function(value)
        Theme.SetTheme(value)
        refreshAppearance()
        Theme.RefreshSettingsVisibility()
    end)
    Theme.appearanceDropdownRefresh = refreshAppearance

    local blizzHeading = MakeLabel(settingsPanel, "Blizz-like window styles", 18, -218, 540, "GameFontNormalLarge")
    local blizzDescription = MakeLabel(settingsPanel, "These retain the established WoW-style Modulo Market window and layout.", 18, -246, 700, "GameFontHighlight")
    local refreshBlizzlike
    local blizzlikeButton
    blizzlikeButton, refreshBlizzlike = BuildDropdown(settingsPanel, "Blizz-like appearance", 18, -290, 260, {
        { label = "Classic gold", value = "classic" },
        { label = "Dark grey", value = "dark" },
        { label = "Class colour", value = "class" },
        { label = "Custom colour", value = "custom" },
    }, Theme.GetBlizzlikeStyle, function(value)
        Theme.SetBlizzlikeStyle(value)
        refreshBlizzlike()
        Theme.RefreshSettingsVisibility()
    end)
    Theme.blizzlikeDropdownRefresh = refreshBlizzlike
    local blizzSwatch = settingsPanel:CreateTexture(nil, "ARTWORK")
    blizzSwatch:SetSize(26, 26)
    blizzSwatch:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 296, -322)
    Theme.blizzlikeSwatch = blizzSwatch
    local blizzCustomButton = MakeButton(settingsPanel, "Choose custom colour…", 332, -322, 190,
        function() OpenColorPicker(blizzSwatch, "blizzlike") end)
    Theme.blizzlikeCustomButton = blizzCustomButton

    local modernHeading = MakeLabel(settingsPanel, "Modern window colours", 18, -390, 540, "GameFontNormalLarge")
    local modernDescription = MakeLabel(settingsPanel, "Modern is a separate dashboard-style window with its own controls, borders and layout.", 18, -418, 760, "GameFontHighlight")
    local refreshModern
    local modernButton
    modernButton, refreshModern = BuildDropdown(settingsPanel, "Modern colour palette", 18, -462, 260, {
        { label = "Dark (grey tone)", value = "dark" },
        { label = "Class colour", value = "class" },
        { label = "Custom colour", value = "custom" },
    }, Theme.GetModernPalette, function(value)
        Theme.SetPalette(value)
        refreshModern()
        Theme.RefreshSettingsVisibility()
    end)
    Theme.modernDropdownRefresh = refreshModern
    local modernSwatch = settingsPanel:CreateTexture(nil, "ARTWORK")
    modernSwatch:SetSize(26, 26)
    modernSwatch:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 296, -494)
    Theme.modernSwatch = modernSwatch
    local modernCustomButton = MakeButton(settingsPanel, "Choose custom colour…", 332, -494, 190,
        function() OpenColorPicker(modernSwatch, "modern") end)
    Theme.modernCustomButton = modernCustomButton

    Theme.RefreshSettingsVisibility = function()
        local blizz = Theme.GetTheme() == "blizzlike"
        local modern = not blizz
        local blizzCustom = blizz and Theme.GetBlizzlikeStyle() == "custom"
        local modernCustom = modern and Theme.GetModernPalette() == "custom"
        for _, object in ipairs({ blizzSwatch, blizzCustomButton }) do
            if blizzCustom then object:Show() else object:Hide() end
        end
        for _, object in ipairs({ modernSwatch, modernCustomButton }) do
            if modernCustom then object:Show() else object:Hide() end
        end
        if blizz then
            local c = Theme.GetBlizzlikeAccent(); blizzSwatch:SetColorTexture(c.r, c.g, c.b, 1)
        else
            local c = Theme.GetModernAccent(); modernSwatch:SetColorTexture(c.r, c.g, c.b, 1)
        end
        -- Hide each section's labels and controls together with its selector.
        for _, object in ipairs({ blizzlikeButton, blizzlikeButton.sectionLabel }) do if blizz then object:Show() else object:Hide() end end
        for _, object in ipairs({ modernButton, modernButton.sectionLabel }) do if modern then object:Show() else object:Hide() end end
        if Theme.blizzlikeSectionLabels then
            for _, object in ipairs(Theme.blizzlikeSectionLabels) do if blizz then object:Show() else object:Hide() end end
        end
        if Theme.modernSectionLabels then
            for _, object in ipairs(Theme.modernSectionLabels) do if modern then object:Show() else object:Hide() end end
        end
    end
    Theme.blizzlikeSectionLabels = { blizzHeading, blizzDescription }
    Theme.modernSectionLabels = { modernHeading, modernDescription }

    Theme.RefreshSettingsVisibility()
    settingsPanel:SetScript("OnShow", function()
        if Theme.appearanceDropdownRefresh then Theme.appearanceDropdownRefresh() end
        if Theme.blizzlikeDropdownRefresh then Theme.blizzlikeDropdownRefresh() end
        if Theme.modernDropdownRefresh then Theme.modernDropdownRefresh() end
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
