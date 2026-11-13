_G = _G or {}
local frames = {}
function CreateFrame()
    local frame = { scripts = {}, events = {} }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:SetScript(kind, fn) self.scripts[kind] = fn end
    frames[#frames + 1] = frame
    return frame
end
local timers = {}
C_Timer = { After = function(delay, fn) timers[#timers + 1] = fn end }
function UnitName() return "CAMWOW" end
function GetRealmName() return "Forever Realm" end
function time() return 123456 end
local ids = {}
for i = 1, 26 do ids[i] = i end
local infoCalls = {}
C_TradeSkillUI = {
    GetChildProfessionInfo = function() return { professionID = 185, professionName = "Cooking", skillLevel = 300, maxSkillLevel = 300 } end,
    GetBaseProfessionInfo = function() return nil end,
    GetAllRecipeIDs = function() return ids end,
    GetRecipeInfo = function(id)
        infoCalls[id] = (infoCalls[id] or 0) + 1
        if id == 6 and infoCalls[id] == 1 then return nil end
        return { name = "Recipe " .. id, learned = true, craftable = true }
    end,
    GetRecipeSchematic = function(id) return { name = "Recipe " .. id, outputItemID = 1000 + id, quantityMin = 1, quantityMax = 1, reagentSlotSchematics = {} } end,
    GetRecipeOutputItemData = function(id) return { itemID = 1000 + id } end,
}
local prints = {}
ModuloMarket = {
    db = { professionRecipesByCharacter = {
        ["Forever Realm:CAMWOW"] = {
            [185] = { professionID = 185, professionName = "Cooking", skillLevel = 5, maxSkillLevel = 75,
                recipeListSignature = table.concat((function() local t={} for i=1,26 do t[i]=tostring(i) end return t end)(), ","),
                recipes = { [1]={recipeID=1, learned=true}, [2]={recipeID=2, learned=true}, [3]={recipeID=3, learned=true}, [4]={recipeID=4, learned=true}, [5]={recipeID=5, learned=true} }, recipeCount=5, listComplete=true },
            _professionSnapshot = { authoritative=true, professions = { [185]={professionID=185, professionName="Cooking", skillLevel=5, skillSource="GetProfessions"}, [164]={professionID=164, professionName="Blacksmithing", skillLevel=225, skillSource="GetProfessions"} } },
        }
    } },
    Print = function(message) prints[#prints + 1] = message end,
    MarketUI = { SetStatus = function() end, OnRecipesUpdated = function() end },
}
dofile("AddOns/ModuloMarket/RecipeEngine.lua")
local eventFrame = frames[#frames]
assert(eventFrame.events.TRADE_SKILL_SHOW, "profession show event must be registered")
eventFrame.scripts.OnEvent(eventFrame, "TRADE_SKILL_SHOW")
assert(#timers == 1, "capture should be scheduled")
timers[1]()
local captureFrame = frames[1]
for _ = 1, 10 do
    if not captureFrame.scripts.OnUpdate then break end
    captureFrame.scripts.OnUpdate()
end
local store = ModuloMarket.db.professionRecipesByCharacter["Forever Realm:CAMWOW"]
assert(store[185].recipeCount == 26, "opening profession must replace stale partial recipe snapshot")
assert(store[185].captureComplete == true and store[185].unresolvedCount == 0, "only complete captures may be committed")
assert(store[185].snapshotSchemaVersion == 2 and store[185].snapshotGeneration == 1, "fresh capture must stamp schema and generation")
local currentRecipes = ModuloMarket.Recipes.GetAllRecipes("character")
assert(#currentRecipes == 26, "current character scope must expose only its schema-current learned recipes")
assert(infoCalls[6] == 2, "transiently missing recipe metadata must be retried")
assert(store._professionSnapshot.professions[185].skillLevel == 300, "active TradeSkillUI skill must override legacy 5/75")
assert(store._professionSnapshot.professions[185].maxSkillLevel == 300, "active max skill must be persisted")
assert(store._professionSnapshot.professions[164].skillLevel == 225, "other profession evidence must be preserved")
ModuloMarket.Recipes.SaveCharacterProfessionSnapshot({[185]=5,[164]=225}, {[185]="Cooking",[164]="Blacksmithing"}, true)
assert(store._professionSnapshot.professions[185].skillLevel == 300, "legacy profession refresh must not downgrade active skill")
assert(#prints == 1 and prints[1]:find("Saved Cooking snapshot: 26 known recipes, skill 300/300", 1, true), "successful snapshot must be confirmed in chat")
-- A permanently unavailable record must not replace the last complete snapshot.
ids[27] = 27
C_TradeSkillUI.GetAllRecipeIDs = function() return ids end
C_TradeSkillUI.GetRecipeInfo = function(id)
    if id == 27 then return nil end
    return { name = "Recipe " .. id, learned = true, craftable = true }
end
ModuloMarket.Recipes.CaptureCurrentProfession(true)
for _ = 1, 12 do
    if not captureFrame.scripts.OnUpdate then break end
    captureFrame.scripts.OnUpdate()
end
assert(store[185].recipeCount == 26, "incomplete refresh must preserve previous complete snapshot")
assert(ModuloMarket.Recipes.GetCaptureStatus().lastCaptureReason == "recipe-info-unavailable", "incomplete capture failure must be diagnosable")
print("ModuloMarket 0.7.8 profession capture harness PASS")
