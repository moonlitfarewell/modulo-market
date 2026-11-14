local addon = arg[1]
_G.ModuloMarket = {
    db = { craftingScope = "character" },
    TurnInData = { crates = {
        { id=1, name="Waylaid Crate: Test Artisan", tier="Artisan", category="Fabrics",
          rewardFavor=nil, rewardCashCopper=nil, reputation=nil, bundles={} },
    } },
    WritData = nil,
    ProfessionData = {
        GetAllFutureRecipes = function()
            return {
                { recipeID=9964, professionID=164, professionName="Blacksmithing",
                  recipeName="Mithril Spurs", outputItemID=7969, reagentDataAvailable=true,
                  reagents={
                    { required=true, quantity=4, choices={{itemID=3860,name="Mithril Bar"}} },
                    { required=true, quantity=3, choices={{itemID=7966,name="Solid Grinding Stone"}} },
                  } },
            }
        end,
        GetItem = function() return nil end,
    },
    Recipes = { GetAllRecipes = function() return {} end },
}
local MM = _G.ModuloMarket
assert(loadfile(addon .. "/WritData.lua"))()
assert(loadfile(addon .. "/TurnInEngine.lua"))()
local E = MM.TurnInEngine
assert(#MM.WritData.writs == 150, "all 150 distinct writs are present")
assert(MM.WritData.rewardByTier.Journeyman == 75)
assert(MM.WritData.rewardByTier.Expert == 125)
assert(MM.WritData.rewardByTier.Artisan == 200)
assert(MM.TurnInData.crates[1].reputation == nil, "unknown Artisan crate rep is nil, not zero")

local catalog = {
    { itemID=900001, itemName="Craftsman's Writ: Mithril Spurs", minPriceCopper=1000, totalQuantity=4, minPriceQuantity=4 },
    { itemID=7969, itemName="Mithril Spurs", minPriceCopper=900, totalQuantity=3, minPriceQuantity=3 },
    { itemID=3860, itemName="Mithril Bar", minPriceCopper=100, totalQuantity=40, minPriceQuantity=40 },
    { itemID=7966, itemName="Solid Grinding Stone", minPriceCopper=50, totalQuantity=30, minPriceQuantity=30 },
}
local byID = {}
for _, item in ipairs(catalog) do byID[item.itemID] = item end
local rows = E.BuildRows(catalog, byID)
assert(#rows == 151, "one crate plus 150 writ rows")
assert(rows[1].turnInType == "crate", "Waylaid Crate rows have explicit crate type for filtering")
local mithril
for _, row in ipairs(rows) do if row.outputName == "Mithril Spurs" then mithril = row; break end end
assert(mithril, "Mithril Spurs writ is indexed")
assert(mithril.turnInType == "writ" and mithril.daily == true)
assert(mithril.reputation == 200 and mithril.rewardFavor == nil)
assert(mithril.writPriceCopper == 1000)
assert(#mithril.bundleAlternatives == 2, "craft and buy are separate completion options")
assert(mithril.bundleAlternatives[1].complete == true)
assert(mithril.bundleAlternatives[1].costCopper == 550, "craft route sums 4 bars and 3 grinding stones")
assert(mithril.bestBundle.kind == "craft", "cheapest complete route is selected")
assert(mithril.completionCostCopper == 1550, "completion includes one writ and one route")
assert(mithril.netCostPerReputationCopper == 7.75, "gross cost per rep excludes variable coin pouch")
assert(mithril.cashReturnCopper == nil and mithril.cashReturnText == "Variable pouch")
assert(E.FormatReward(mithril, true) == "200 Rep")

local unknown
for _, row in ipairs(rows) do if row.outputName == "Elixir of Ogre's Strength" then unknown = row; break end end
assert(unknown and unknown.completionCostCopper == nil, "unmatched recipe and absent writ listing remain incomplete")
assert(unknown.itemID ~= nil and unknown.iconItemID == nil, "unlisted/unmatched writ still has a stable selectable row identity")
assert(unknown.reputation == 75 and unknown.cashReturnCopper == nil)

-- Verify exact Writ output/profession matches against the bundled runtime Lua dataset.
dofile(addon .. "/ForeverDBData.lua")
local recipeIndex = {}
for _, profession in pairs(MM.ForeverDBData.professions or {}) do
    for _, recipe in ipairs(profession.recipes or {}) do
        local recipeName = recipe.recipeName or recipe.name
        if recipeName then
            local key = string.lower(recipeName)
            recipeIndex[key] = recipeIndex[key] or {}
            recipeIndex[key][#recipeIndex[key] + 1] = {
                profession = profession.name, reagents = recipe.reagents,
                reagentDataAvailable = recipe.reagentDataAvailable,
            }
        end
    end
end
local matched, missing = 0, {}
for _, writ in ipairs(MM.WritData.writs) do
    local candidates = recipeIndex[string.lower(writ.outputName)] or {}
    local found = false
    for _, candidate in ipairs(candidates) do
        for _, allowed in ipairs(writ.professions or {}) do
            if candidate.profession == allowed and candidate.reagentDataAvailable == true
                and type(candidate.reagents) == "table" and #candidate.reagents > 0 then
                found = true
            end
        end
    end
    if found then matched = matched + 1 else missing[#missing + 1] = writ.outputName end
end
assert(matched == 145 and #missing == 5, "145 exact output/profession matches, five fail closed")
assert(table.concat(missing, "|"):find("Elixir of Ogre's Strength", 1, true))
assert(table.concat(missing, "|"):find("Gnomish Alarm-O-Bot", 1, true))
assert(table.concat(missing, "|"):find("Gyromatic Micro-Adjuster", 1, true))
assert(table.concat(missing, "|"):find("Inlaid Mithril Cylinder", 1, true))
assert(table.concat(missing, "|"):find("Potion of Demonslaying", 1, true))

local depthCatalog = {
    { itemID=900002, itemName="Craftsman's Writ: Mithril Spurs", minPriceCopper=1000, totalQuantity=4, minPriceQuantity=4 },
    { itemID=3860, itemName="Mithril Bar", minPriceCopper=100, totalQuantity=40, minPriceQuantity=3 },
    { itemID=7966, itemName="Solid Grinding Stone", minPriceCopper=50, totalQuantity=30, minPriceQuantity=30 },
}
local depthByID = {}; for _, item in ipairs(depthCatalog) do depthByID[item.itemID] = item end
local depthRows = E.BuildRows(depthCatalog, depthByID)
local depthWrit
for _, row in ipairs(depthRows) do if row.outputName == "Mithril Spurs" then depthWrit = row; break end end
assert(depthWrit and depthWrit.completionCostCopper == nil, "insufficient cheapest-price depth fails closed")
assert(depthWrit.bundleAlternatives[1].complete == false)

local incompatibleRows = E.BuildRows(catalog, {})
local incompatibleWrit
for _, row in ipairs(incompatibleRows) do if row.outputName == "Mithril Spurs" then incompatibleWrit = row; break end end
assert(incompatibleWrit and incompatibleWrit.completionCostCopper == nil,
    "incompatible/empty exact-build price index cannot leak stale name-index prices")

print("11 Writ checks + explicit crate-type check passed; 145/150 exact recipe coverage verified against embedded ForeverDBData.lua")
