local themePath = arg[1]
local registered = { dropdowns = {}, sliders = {}, initializers = {}, settings = {} }
local layout = {
    AddInitializer = function(self, initializer)
        registered.initializers[#registered.initializers + 1] = initializer
    end,
}
local category = { GetID = function() return 4242 end }
_G.ModuloMarket = {
    version = "0.12.12",
    db = {
        marketAppearance = "blizzlike", theme = "blizzlike",
        blizzlikeStyle = "custom", modernPalette = "custom",
        blizzlikeCustomAccent = { r = 0.2, g = 0.3, b = 0.4 },
        customAccent = { r = 0.5, g = 0.6, b = 0.7 },
    },
    MarketUI = {
        ApplyCheckboxContrast = function() end,
        SwitchPresentation = function() end,
        ResetWindowPosition = function() end,
    },
    ModernUI = { ApplyTheme = function() end, ResetWindowPosition = function() end },
    Scanner = { Toggle = function() registered.scannerOpened = true end },
    Print = function() end,
}
_G.Settings = {
    RegisterVerticalLayoutCategory = function(name)
        registered.categoryName = name
        return category, layout
    end,
    RegisterAddOnCategory = function(value) registered.addedCategory = value end,
    RegisterProxySetting = function(cat, variable, valueType, title, default, getter, setter)
        local setting = { variable = variable, valueType = valueType, title = title, default = default,
            getter = getter, setter = setter }
        registered.settings[variable] = setting
        return setting
    end,
    CreateControlTextContainer = function()
        local values = {}
        return {
            Add = function(self, value, label) values[#values + 1] = { value = value, label = label } end,
            GetData = function() return values end,
        }
    end,
    CreateDropdown = function(cat, setting, getOptions, tooltip)
        local control = { setting = setting, options = getOptions(), tooltip = tooltip }
        function control:SetParentInitializer(parent, predicate)
            self.parent = parent
            self.predicate = predicate
        end
        registered.dropdowns[#registered.dropdowns + 1] = control
        return control
    end,
}
_G.CreateSettingsListSectionHeaderInitializer = function(title) return { kind = "header", title = title } end
_G.CreateSettingsButtonInitializer = function(name, label, callback, tooltip)
    local control = { kind = "button", name = name, label = label, callback = callback, tooltip = tooltip }
    function control:SetParentInitializer(parent, predicate)
        self.parent = parent
        self.predicate = predicate
    end
    return control
end
_G.MinimalSliderWithSteppersMixin = { Label = { Right = "RIGHT" } }
local loader
_G.CreateFrame = function()
    local frame = {
        RegisterEvent = function(self, event) self.event = event end,
        SetScript = function(self, event, callback) self.callback = callback end,
        UnregisterEvent = function() end,
    }
    loader = frame
    return frame
end
_G.InCombatLockdown = function() return false end
_G.InterfaceOptions_AddCategory = function() error("legacy canvas registration should not be used") end

assert(loadfile(themePath))()
local T = ModuloMarket.Theme
assert(T and type(T.Initialize) == "function")
T.Initialize()
assert(loader and loader.callback)
loader.callback(loader, "PLAYER_LOGIN")

assert(registered.categoryName == "Modulo Market")
assert(registered.addedCategory == category)
assert(T.settingsCategory == category)
assert(#registered.dropdowns == 3, "expected appearance, Blizz-like style, and Modern palette dropdowns")
assert(#registered.sliders == 0, "custom accents use Blizzard's colour picker, not custom sliders")
assert(#registered.initializers == 9, "expected four section headers and five native action buttons")

local appearance = registered.settings.MODULO_MARKET_APPEARANCE
assert(appearance and appearance.getter() == "blizzlike")
appearance.setter("modern")
assert(ModuloMarket.db.marketAppearance == "modern")
local style = registered.settings.MODULO_MARKET_BLIZZLIKE_STYLE
style.setter("dark")
assert(ModuloMarket.db.blizzlikeStyle == "dark")
local appearanceControl = registered.dropdowns[1]
local blizzControl = registered.dropdowns[2]
local modernControl = registered.dropdowns[3]
assert(blizzControl.parent == appearanceControl and blizzControl.predicate() == false)
assert(modernControl.parent == appearanceControl and modernControl.predicate() == true)
appearance.setter("blizzlike")
assert(blizzControl.predicate() == true and modernControl.predicate() == false)
appearance.setter("modern")
assert(blizzControl.predicate() == false and modernControl.predicate() == true)
local pickerConfig
_G.ColorPickerFrame = {
    SetupColorPickerAndShow = function(self, config) pickerConfig = config end,
    GetColorRGB = function() return 0.4, 0.5, 0.6 end,
}
local blizzPicker, modernPicker, browseButton
for _, initializer in ipairs(registered.initializers) do
    if initializer.kind == "button" and initializer.name == "Blizz-like custom colour" then blizzPicker = initializer end
    if initializer.kind == "button" and initializer.name == "Modern custom colour" then modernPicker = initializer end
end
assert(blizzPicker and modernPicker)
assert(blizzPicker.parent == blizzControl and blizzPicker.predicate() == false)
assert(modernPicker.parent == modernControl and modernPicker.predicate() == true)
style.setter("custom")
assert(blizzPicker.predicate() == true)
blizzPicker.callback()
assert(pickerConfig and pickerConfig.hasOpacity == false)
pickerConfig.swatchFunc()
assert(math.abs(ModuloMarket.db.blizzlikeCustomAccent.r - 0.4) < 0.0001)
pickerConfig.cancelFunc()
assert(math.abs(ModuloMarket.db.blizzlikeCustomAccent.r - 0.2) < 0.0001)
modernPicker.callback()
pickerConfig.swatchFunc()
assert(math.abs(ModuloMarket.db.customAccent.g - 0.5) < 0.0001)

for _, initializer in ipairs(registered.initializers) do
    if initializer.kind == "button" and initializer.name == "Browse Scan and Snapshot Debug" then
        browseButton = initializer
    end
end
assert(browseButton and type(browseButton.callback) == "function")
browseButton.callback()
assert(registered.scannerOpened == true)

print("native settings appearance harness: 20 checks passed")
