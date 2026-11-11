local miningSkill = 1
local futureRows = {
    { professionID = 164, recipeID = 9001, entry = {
        name = "Smelt Future Alloy", craftedItemId = 999, requiredSkill = 225,
        reagents = { [100] = 2 },
    } },
    { professionID = 164, recipeID = 9002, entry = {
        name = "Unknown-source Alloy", craftedItemId = 998, requiredSkill = 250,
        reagents = { [200] = 1 },
    } },
    { professionID = 171, recipeID = 9003, entry = {
        name = "Borrowed-source Potion", craftedItemId = 997, requiredSkill = 175,
        reagents = { [100] = 1 },
    } },
    { professionID = 164, recipeID = 7001, entry = {
        name = "Already learned", craftedItemId = 100, requiredSkill = 1,
        reagents = { [200] = 1 },
    } },
    { professionID = 164, recipeID = 9004, entry = {
        name = "Never implemented", craftedItemId = 996, requiredSkill = 250,
        reagents = {},
    } },
    { professionID = 164, recipeID = 9005, entry = {
        name = "Positional Scalar Reagent Array", craftedItemId = 995, requiredSkill = 250,
        reagents = { 50001, 50002 },
    } },
}
local db = {}
function db:IsReady() return true end
function db:GetGameVersion() return "Forever" end
function db:GetProfessions() return { 164, 171 } end
function db:Iterate(professionID)
    local i = 0
    return function()
        while true do
            i = i + 1
            local row = futureRows[i]
            if not row then return nil end
            if row.professionID == professionID then
                return row.professionID, row.recipeID, row.entry
            end
        end
    end
end
function db:IsHiddenRecipe(recipeID) return recipeID == 9004 end
function db:IsAutoTaughtRecipe() return false end
function db:GetRecipeSources(recipeID)
    if recipeID == 9001 then return { trainer = { { id = 1, name = "Trainer" } } } end
    if recipeID == 9003 then return { vendor = { { id = 2, name = "Vendor" } } } end
    return nil
end
function db:IsBorrowed(recipeID, field)
    return recipeID == 9003 and field == "sources"
end
LibStub = function(name)
    if name == "LibProfessionDB-1.0" then return db end
end

ModuloMarket = {
    db = {},
    Recipes = {
        GetAllRecipes = function()
            return {
                {
                    recipeID = 7001, professionID = 164, professionName = "Blacksmithing",
                    outputItemID = 100, recipeName = "Known Item",
                    reagents = { { choices = { { itemID = 200 } } } },
                },
            }
        end,
        GetProfessionSummary = function()
            return { professions = {
                { professionID = 164, name = "Blacksmithing" },
                { professionID = 171, name = "Alchemy" },
                { professionID = 182, name = "Herbalism", skill = 300 },
                { professionID = 186, name = "Mining", skill = miningSkill },
                { professionID = 356, name = "Fishing", skill = 300 },
            } }
        end,
    },
}
dofile("AddOns/ModuloMarket/GatheringItems.lua")
dofile("AddOns/ModuloMarket/ProfessionData.lua")
local data = ModuloMarket.ProfessionData
local known = data.GetItem(100)
assert(known and #known.knownCrafts == 1, "learned output should be classified as a known craft")
assert(data.Matches(100, 164, "known"), "known craft filter should match learned output")
assert(data.Matches(100, 164, "all"), "profession filter should include learned output")
assert(data.Matches(100, 171, "all"), "profession filter should include known future-recipe reagents")
assert(not data.Matches(100, 185, "all"), "profession filter should exclude unrelated professions")
assert(data.HasGatheringData(), "known gathering professions should activate the gatherable filter")
assert(data.Matches(2770, 186, "gather"), "Copper Ore should be marked gatherable for Mining skill 1")
assert(data.Matches(2771, 186, "gather"), "Tin Ore should remain classified as a Mining resource below its skill threshold")
local tinGathering = data.GetGatheringInfo(2771)
assert(tinGathering and tinGathering[186].requiredSkill == 65
    and tinGathering[186].currentSkill == 1 and tinGathering[186].canGatherNow == false,
    "Tin Ore should preserve the 65 skill requirement and report current ineligibility separately")
assert(data.Matches(2447, 182, "gather"), "Peacebloom should be marked gatherable for Herbalism")
assert(data.Matches(4603, 356, "gather"), "Raw Spotted Yellowtail should be marked gatherable for Fishing")
assert(not data.Matches(2770, 182, "gather"), "gatherable item should be restricted to its gathering profession")
miningSkill = 65
data.Refresh()
assert(data.Matches(2771, 186, "gather"), "Tin Ore should become gatherable at Mining skill 65")
local copperGathering = data.GetGatheringInfo(2770)
assert(copperGathering[186].requiredSkill == 1 and copperGathering[186].currentSkill == 65,
    "gathering detail should preserve required and current skill levels")
local future = data.GetItem(999)
assert(future and #future.futureCrafts == 1, "source-backed unlearned output should be a future craft")
assert(future.futureCrafts[1].requiredSkill == 225, "verified skill requirement should be exposed")
assert(data.Matches(999, 164, "future"), "future craft filter should match source-backed unlearned output")
local unknown = data.GetItem(998)
assert(unknown and #unknown.unknownFutureCrafts == 1 and #unknown.futureCrafts == 0,
    "missing source data must remain unknown, not be labelled future")
local borrowed = data.GetItem(997)
assert(borrowed and borrowed.futureCrafts[1].borrowedSources == true,
    "borrowed Forever source data must be marked as unconfirmed")
local borrowedTags = data.GetItemTags(997)
assert(borrowedTags and borrowedTags[1] == "futureBorrowed",
    "borrowed future craft output should receive the uncertainty marker")
assert(data.GetItem(996) == nil, "never-implemented recipes must not appear as future crafts")
assert(data.GetItem(1) == nil and data.GetItem(2) == nil,
    "contiguous scalar arrays must not be mistaken for low item IDs")
local provider = data.GetFutureProviderStatus()
assert(provider.available and provider.count == 2 and provider.unknownSourceCount == 2
    and provider.borrowedSourceCount == 1, "provider coverage and uncertainty counts should be explicit")
print("Modulo Market 0.4.0 profession data + future craft provenance harness PASS")
