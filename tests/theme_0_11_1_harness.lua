local themePath = arg[1]
_G.ModuloMarket = {
    db = { theme = "modern", modernPalette = "class", customAccent = { r = 0.9, g = 0.1, b = 0.4 } }
}
_G.CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function() end, UnregisterEvent = function() end }
end
_G.RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.72, b = 1.0 } }
_G.UnitClass = function() return "Mage", "MAGE" end
assert(loadfile(themePath))()
local T = ModuloMarket.Theme
assert(T and type(T.Initialize) == "function")
T.Initialize()
-- Migrate the 0.11.0 colour-skinned old window into a Blizz-like style.
assert(T.GetTheme() == "blizzlike")
assert(T.GetBlizzlikeStyle() == "class")
assert(ModuloMarket.db.marketAppearance == "blizzlike")
local fallback = { 0.1, 0.2, 0.3, 0.4 }
local classicFallback = T.GetColor("surface", fallback)
assert(classicFallback[1] == 0.035 and classicFallback[2] == 0.032)
T.SetBlizzlikeStyle("class")
local classBlizz = T.GetColor("accent")
assert(math.abs(classBlizz[1] - 0.25) < 0.0001 and math.abs(classBlizz[2] - 0.72) < 0.0001)
T.SetTheme("modern")
assert(T.GetTheme() == "modern")
T.SetPalette("dark")
local modernDark = T.GetModernColor("accent")
assert(math.abs(modernDark[1] - 0.61) < 0.0001 and math.abs(modernDark[2] - 0.65) < 0.0001)
T.SetPalette("class")
local modernClass = T.GetModernColor("accent")
assert(math.abs(modernClass[1] - 0.25) < 0.0001 and math.abs(modernClass[2] - 0.72) < 0.0001)
T.SetPalette("custom")
T.SetCustomAccent(0.9, 0.1, 0.4)
local modernCustom = T.GetModernColor("accent")
assert(math.abs(modernCustom[1] - 0.9) < 0.0001 and math.abs(modernCustom[2] - 0.1) < 0.0001)
T.SetBlizzlikeStyle("custom")
T.SetBlizzlikeCustomAccent(0.2, 0.3, 0.4)
local blizzCustom = T.GetColor("accent")
assert(math.abs(blizzCustom[1] - 0.2) < 0.0001 and math.abs(blizzCustom[3] - 0.4) < 0.0001)
local tex = { IsObjectType = function() return true end, SetColorTexture = function(self, r, g, b, a) self.color = {r,g,b,a} end }
T.SetTexture(tex, "accent", fallback)
T.SetBlizzlikeCustomAccent(0.7, 0.6, 0.5)
T.ApplyRegistered()
assert(math.abs(tex.color[1] - 0.7) < 0.0001 and math.abs(tex.color[2] - 0.6) < 0.0001)
local fs = { SetTextColor = function(self, r, g, b, a) self.color = {r,g,b,a} end }
T.SetFontColor(fs, "textAccent", {1,1,1,1})
T.SetBlizzlikeCustomAccent(0.4, 0.5, 0.6)
T.ApplyRegistered()
assert(math.abs(fs.color[1] - 0.4) < 0.0001 and math.abs(fs.color[2] - 0.5) < 0.0001)
-- The old Custom colour is copied into the Blizz-like custom field on migration.
ModuloMarket.db.marketAppearance = nil
ModuloMarket.db.theme = "modern"
ModuloMarket.db.modernPalette = "custom"
ModuloMarket.db.customAccent = { r = 0.33, g = 0.44, b = 0.55 }
ModuloMarket.db.blizzlikeCustomAccent = nil
T.Initialize()
assert(T.GetBlizzlikeStyle() == "custom")
local migratedCustom = T.GetBlizzlikeAccent()
assert(math.abs(migratedCustom.r - 0.33) < 0.0001 and math.abs(migratedCustom.b - 0.55) < 0.0001)
T.SetTheme("blizzlike")
assert(T.GetTheme() == "blizzlike")
print("theme 0.11.1 harness: 18 checks passed")
