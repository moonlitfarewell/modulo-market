local frames = {}
function CreateFrame()
    local frame = { scripts = {}, events = {} }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:SetScript(name, fn) self.scripts[name] = fn end
    frames[#frames + 1] = frame
    return frame
end
function UnitName() return "Tester" end
function GetRealmName() return "ForeverRealm" end
function time() return 123456 end

ModuloMarket = { db = {} }
local recipes = {
    [100] = {
        name = "Bolt of Test Cloth", learned = true, craftable = true,
    },
    [101] = {
        name = "Test Bag", learned = true, craftable = true,
    },
    [102] = {
        name = "Unlearned Test Recipe", learned = false, craftable = false,
    },
    [103] = {
        name = "Unknown Output Recipe", learned = true, craftable = true,
    },
}
local schematics = {
    [100] = {
        outputItemID = 200, quantityMin = 2, quantityMax = 2,
        reagentSlotSchematics = {
            { required = true, quantityRequired = 3, reagents = { { itemID = 300, name = "Test Cloth" } } },
        },
    },
    [101] = {
        outputItemID = 201, quantityMin = 1, quantityMax = 1,
        reagentSlotSchematics = {
            { required = true, quantityRequired = 2, reagents = {
                { itemID = 301, name = "Cheap Thread" },
                { itemID = 302, name = "Expensive Thread" },
            } },
            { required = false, quantityRequired = 1, reagents = { { itemID = 303, name = "Optional Dye" } } },
        },
    },
    [103] = {
        outputItemID = 203, quantityMin = 1, quantityMax = 1,
        reagentSlotSchematics = {
            { required = true, quantityRequired = 2, reagents = { { itemID = 399, name = "Missing Mat" } } },
        },
    },
}
C_TradeSkillUI = {
    GetChildProfessionInfo = function()
        return { professionID = 197, parentProfessionID = 197, professionName = "Tailoring", skillLevel = 225, maxSkillLevel = 300 }
    end,
    GetBaseProfessionInfo = function()
        return { professionID = 197, professionName = "Tailoring", skillLevel = 225, maxSkillLevel = 300 }
    end,
    GetAllRecipeIDs = function() return { 100, 101, 102, 103 } end,
    GetRecipeInfo = function(id) return recipes[id] end,
    GetRecipeSchematic = function(id) return schematics[id] end,
    GetRecipeOutputItemData = function(id)
        local s = schematics[id]
        return s and { itemID = s.outputItemID } or nil
    end,
}
dofile(arg[1])
assert(ModuloMarket.Recipes ~= nil, "Recipe engine did not load")
local ok, err = ModuloMarket.Recipes.CaptureCurrentProfession()
assert(ok, "Capture failed: " .. tostring(err))
local captureFrame = frames[1]
assert(captureFrame and captureFrame.scripts.OnUpdate, "Capture did not start")
while captureFrame.scripts.OnUpdate do
    captureFrame.scripts.OnUpdate(captureFrame, 0.016)
end

local summary = ModuloMarket.Recipes.GetProfessionSummary()
assert(summary.recipeCount == 3, "Only learned recipes should be captured")
assert(#summary.professions == 1 and summary.professions[1].name == "Tailoring", "Profession identity mismatch")
assert(summary.professions[1].skill == 225 and summary.professions[1].maxSkill == 300, "Profession skill mismatch")
assert(summary.professions[1].listComplete == true, "GetAllRecipeIDs should mark complete list")

local all = ModuloMarket.Recipes.GetAllRecipes()
assert(#all == 3, "Known recipe count mismatch")
local byID = {}
for _, recipe in ipairs(all) do byID[recipe.recipeID] = recipe end
assert(byID[100] and byID[101] and byID[103], "Learned recipe missing")
assert(not byID[102], "Unlearned recipe was included")

local prices = {
    [200] = { itemName = "Bolt of Test Cloth", minPriceCopper = 500, totalQuantity = 10 },
    [201] = { itemName = "Test Bag", minPriceCopper = 250, totalQuantity = 5 },
    [203] = { itemName = "Unknown Output", minPriceCopper = 100, totalQuantity = 1 },
    [300] = { itemName = "Test Cloth", minPriceCopper = 100, totalQuantity = 20 },
    [301] = { itemName = "Cheap Thread", minPriceCopper = 150, totalQuantity = 20 },
    [302] = { itemName = "Expensive Thread", minPriceCopper = 300, totalQuantity = 20 },
}
local function lookup(id) return prices[id] end
local bolt = ModuloMarket.Recipes.BuildEconomics(byID[100], lookup, 5)
assert(bolt.professionID == 197, "Economics rows must retain profession ID for profession filtering")
assert(bolt.materialCostCopper == 300, "Reagent cost should be 3 x 100 copper")
assert(bolt.outputQuantity == 2 and bolt.grossSaleCopper == 1000, "Output quantity/sale value mismatch")
assert(bolt.netSaleCopper == 950 and bolt.profitCopper == 650, "AH cut/profit calculation mismatch")

local bag = ModuloMarket.Recipes.BuildEconomics(byID[101], lookup, 5)
assert(bag.materialCostCopper == 300, "Cheapest known reagent choice should be selected")
assert(#bag.reagentLines == 1, "Optional reagent slots must not be charged")
assert(bag.profitCopper == -63, "Loss-making craft calculation mismatch")

local unknown = ModuloMarket.Recipes.BuildEconomics(byID[103], lookup, 5)
assert(unknown.materialCostCopper == nil, "Missing reagent price must not be treated as zero")
assert(unknown.profitCopper == nil, "Profit must remain unknown when reagent price is missing")

print("recipe_engine_0_3_0_harness: PASS")
