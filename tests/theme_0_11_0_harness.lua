local themePath = arg[1]
_G.ModuloMarket = { db = {} }
_G.CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function() end, UnregisterEvent = function() end }
end
_G.RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.72, b = 1.0 } }
_G.UnitClass = function() return "Mage", "MAGE" end
assert(loadfile(themePath))()
local T = ModuloMarket.Theme
assert(T and type(T.Initialize) == "function")
T.Initialize()
assert(T.GetTheme() == "blizzlike")
local fallback = { 0.1, 0.2, 0.3, 0.4 }
local c = T.GetColor("surface", fallback)
assert(c[1] == 0.1 and c[2] == 0.2 and c[3] == 0.3 and c[4] == 0.4)
T.SetTheme("modern")
assert(T.GetTheme() == "modern")
T.SetPalette("dark")
local dark = T.GetColor("accent")
assert(dark[1] > 0 and math.abs(dark[1] - dark[3]) < 0.15)
T.SetPalette("class")
local class = T.GetColor("accent")
assert(math.abs(class[1] - 0.25) < 0.0001 and math.abs(class[2] - 0.72) < 0.0001)
T.SetPalette("custom")
T.SetCustomAccent(0.9, 0.1, 0.4)
local custom = T.GetColor("accent")
assert(math.abs(custom[1] - 0.9) < 0.0001 and math.abs(custom[2] - 0.1) < 0.0001)
local tex = { IsObjectType = function() return true end, SetColorTexture = function(self, r, g, b, a) self.color = {r,g,b,a} end }
T.SetTexture(tex, "accent", fallback)
T.SetCustomAccent(0.2, 0.3, 0.4)
T.ApplyRegistered()
assert(math.abs(tex.color[1] - 0.2) < 0.0001 and math.abs(tex.color[3] - 0.4) < 0.0001)
local fs = { SetTextColor = function(self, r, g, b, a) self.color = {r,g,b,a} end }
T.SetFontColor(fs, "textAccent", {1,1,1,1})
T.SetCustomAccent(0.7, 0.6, 0.5)
T.ApplyRegistered()
assert(math.abs(fs.color[1] - 0.7) < 0.0001 and math.abs(fs.color[2] - 0.6) < 0.0001)
T.SetTheme("blizzlike")
assert(T.GetTheme() == "blizzlike")
print("theme 0.11.0 harness: 12 checks passed")
