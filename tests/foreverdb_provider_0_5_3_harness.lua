local dataPath = assert(arg[1], "ForeverDBData.lua path required")
local professionPath = assert(arg[2], "ProfessionData.lua path required")

_G.ModuloMarket = {
    Recipes = {
        GetAllRecipes = function() return {} end,
        GetProfessionSummary = function() return { professions = {} } end,
    },
    GatheringItems = {},
}
_G.GetBuildInfo = function() return "1.60.1", "70862", "test", 16001 end
_G.CreateFrame = function()
    return {
        RegisterEvent = function() end,
        SetScript = function() end,
    }
end

dofile(dataPath)
local sampleProfession = _G.ModuloMarket.ForeverDBData.professions.alchemy
local sampleRecipe = sampleProfession.recipes[1]
local sampleOutput = sampleRecipe.outputs[1]
_G.ModuloMarket.Recipes.GetAllRecipes = function()
    return {{
        recipeID = sampleRecipe.id,
        recipeName = sampleRecipe.name,
        professionID = sampleProfession.professionID,
        professionName = sampleProfession.name,
        outputItemID = sampleOutput.id,
        quantityMin = sampleOutput.min,
        quantityMax = sampleOutput.max,
        hasSingleItemOutput = sampleOutput.min == 1 and sampleOutput.max == 1,
        reagents = {},
        reagentDataAvailable = true,
        learned = true,
    }}
end
_G.ModuloMarket.Recipes.GetProfessionSummary = function()
    return { professions = {{
        professionID = sampleProfession.professionID,
        name = sampleProfession.name,
        skill = 1,
    }}}
end
dofile(professionPath)

local data = assert(_G.ModuloMarket.ProfessionData)
local status = data.GetFutureProviderStatus()
assert(status.available == true, "matching ForeverDB build should load")
assert(status.datasetBuild == "1.60.1.70862", "dataset build must be preserved")
assert(status.currentBuild == "1.60.1.70862", "client build must be composed exactly")
assert(data.IsMarketSnapshotCompatible({
    clientVersion = "1.60.1", clientBuild = "70862",
}) == true, "market snapshots from the exact client build should be compatible")
assert(data.IsMarketSnapshotCompatible({
    clientVersion = "1.60.1", clientBuild = "70755",
}) == false, "market snapshots from another build must be blocked for recipe economics")
assert(data.IsMarketSnapshotCompatible({
    clientVersion = "unknown", clientBuild = "unknown",
}) == false, "snapshots without verifiable build metadata must not be used for recipe economics")
assert(status.recipeCount == 2493, "all provider recipes must be counted")
assert(status.speculativeCount == 143, "speculative recipes must be counted separately")
assert(status.nonItemCount == 179, "non-item and unknown-output records must not become item crafts")
assert(status.excludedKnownCount == 1, "a recipe already learned by the character must not be duplicated")

local future = data.GetAllFutureRecipes()
assert(#future > 0, "unlearned item-output recipes should be indexed")
local observed, borrowed, unknown = false, false, false
for _, recipe in ipairs(future) do
    assert(recipe.outputItemID and recipe.outputItemID > 0, "only item-output records enter craft economics")
    assert(recipe.speculative ~= true, "speculative records must be excluded")
    assert(not (recipe.sourceKnown and recipe.sourceUnknown), "source status must be exclusive")
    if recipe.sourceKnown then observed = true end
    if recipe.borrowedSources then borrowed = true end
    if recipe.sourceUnknown then unknown = true end
end
assert(observed, "Forever-observed or automatic sources should be represented")
assert(borrowed, "Classic-borrowed sources should remain distinct")
assert(unknown, "unverified acquisition sources should remain distinct")

local roleChecks = { future = false, borrowed = false, unknown = false }
for _, recipe in ipairs(future) do
    local role = recipe.sourceKnown and "future" or (recipe.borrowedSources and "borrowed" or "unknown")
    if not roleChecks[role] then
        assert(data.Matches(recipe.outputItemID, recipe.professionID, role),
            "item relationship index must support the " .. role .. " filter")
        roleChecks[role] = true
    end
end
assert(roleChecks.future and roleChecks.borrowed and roleChecks.unknown,
    "all three source confidence filters must be populated")
assert(#data.GetMaterialItems() > 0, "ForeverDB reagent relationships must populate material index")

local professions = data.GetProfessions()
assert(#professions == 12, "all 12 professions should be exposed")
assert(data.GetFutureProviderStatus().dataSource == "ForeverDB.net", "provider identity should be exposed")

_G.GetBuildInfo = function() return "1.60.1", "70888", "test", 16001 end
data.Refresh()
local baseline = data.GetFutureProviderStatus()
assert(baseline.available == true, "older build dataset must remain available as a labelled baseline")
assert(baseline.datasetBuild == "1.60.1.70862", "baseline provenance must not be relabelled")
assert(baseline.currentBuild == "1.60.1.70888", "current client build must remain visible")
assert(baseline.dataBuildMatchesClient == false, "different build must be labelled as a baseline, not a match")
assert(baseline.reviewWatchCount == 4, "only the four hotfix-linked recipes should be flagged for review")
assert(#data.GetAllFutureRecipes() > 0, "baseline recipe candidates must remain available on a newer client")
local freshness = {}
for _, recipe in ipairs(data.GetAllFutureRecipes()) do
    freshness[recipe.recipeID] = recipe.freshnessStatus
    if recipe.recipeID == 3326 then
        assert(recipe.freshnessField == "skill-up range", "Blacksmithing hotfix must be scoped to its reported field")
    end
end
assert(freshness[3326] == "review", "Coarse Grinding Stone should be in the targeted review watch")
assert(freshness[1283400] == "review", "Journeyman Campfire should be in the targeted review watch")
assert(freshness[1245246] == "review", "Minor Arcane Elixir should be in the targeted review watch")
assert(freshness[3962] == "review", "Iron Grenade should be in the targeted review watch")
local hasUnrelatedBaseline = false
for _, recipe in ipairs(data.GetAllFutureRecipes()) do
    if recipe.freshnessStatus == "baseline" then hasUnrelatedBaseline = true; break end
end
assert(hasUnrelatedBaseline, "unrelated recipes must remain baseline rather than review/unknown")
assert(data.IsMarketSnapshotCompatible({
    clientVersion = "1.60.1", clientBuild = "70888",
}) == true, "market snapshots from the current client build should remain compatible")
assert(data.IsMarketSnapshotCompatible({
    clientVersion = "1.60.1", clientBuild = "70862",
}) == false, "old market snapshots must still be blocked for current-client recipe economics")

print("ModuloMarket baseline-plus-delta provider harness passed")
