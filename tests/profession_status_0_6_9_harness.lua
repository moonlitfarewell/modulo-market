local futureRows = {
    { professionID = 164, recipeID = 9002, entry = {
        name = "Skill-gated Blacksmithing recipe", craftedItemId = 99002, requiredSkill = 225,
        reagents = { [100] = 1 },
    } },
    { professionID = 171, recipeID = 9003, entry = {
        name = "Alchemy recipe", craftedItemId = 99003, requiredSkill = 1,
        reagents = { [101] = 1 },
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
            if row.professionID == professionID then return row.professionID, row.recipeID, row.entry end
        end
    end
end
function db:IsHiddenRecipe() return false end
function db:IsAutoTaughtRecipe() return false end
function db:GetRecipeSources() return { trainer = { { name = "Trainer" } } } end
function db:IsBorrowed() return false end
LibStub = function(name) if name == "LibProfessionDB-1.0" then return db end end

GetProfessions = function() return 1, nil, nil, nil, nil end
GetProfessionInfo = function(index)
    assert(index == 1)
    return "Blacksmithing", nil, 200, 300, 0, 0, 164, 0
end

ModuloMarket = {
    Recipes = {
        GetAllRecipes = function() return {} end,
        GetProfessionSummary = function() return { professions = {} } end,
    },
}
dofile("AddOns/ModuloMarket/GatheringItems.lua")
dofile("AddOns/ModuloMarket/ProfessionData.lua")
local data = ModuloMarket.ProfessionData
assert(data.HasAuthoritativeProfessionList(), "native profession API should establish an authoritative list")
local recipes = data.GetAllFutureRecipes()
assert(#recipes == 2, "both unlearned recipes should be retained")
local blacksmithing, alchemy = recipes[1], recipes[2]
assert(blacksmithing.learningStatus == "learnable", "owned profession recipe should be learnable")
assert(blacksmithing.currentProfessionSkill == 200 and blacksmithing.requiredSkill == 225,
    "current skill and required skill should remain distinct")
assert(blacksmithing.canLearnNow == false, "below-threshold recipe should not be marked ready to learn")
assert(alchemy.learningStatus == "unlearnable", "missing profession should be explicitly unlearnable")
assert(data.Matches(99002, 0, "learnable"), "learnable output filter should match")
assert(data.Matches(99003, 0, "unlearnable"), "unlearnable output filter should match")
local alchemyTags = data.GetItemTags(99003)
assert(alchemyTags and alchemyTags[1] == "unlearnable", "unlearnable output should carry red-status role")

GetProfessions = nil
GetProfessionInfo = nil
data.Refresh()
assert(not data.HasAuthoritativeProfessionList(), "missing native APIs must not imply an authoritative empty list")
local unknownStatus = data.GetRecipeLearningStatus(data.GetAllFutureRecipes()[2])
assert(unknownStatus == "unknown", "missing profession API must preserve unknown, not assert unlearnable")
print("ModuloMarket 0.6.9 profession status harness PASS")
