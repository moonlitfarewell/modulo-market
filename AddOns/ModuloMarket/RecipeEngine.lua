local MM = _G.ModuloMarket
if not MM then return end

local Recipes = {}
MM.Recipes = Recipes

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
    return nil
end

local function CharacterKey()
    local name = type(_G.UnitName) == "function" and _G.UnitName("player") or nil
    local realm = type(_G.GetRealmName) == "function" and _G.GetRealmName() or nil
    if type(name) ~= "string" or name == "" then name = "Unknown" end
    if type(realm) ~= "string" or realm == "" then realm = "UnknownRealm" end
    return realm .. ":" .. name
end

local function SortedNumericKeys(source)
    local keys = {}
    for key in pairs(source or {}) do
        local number = tonumber(key)
        if number then keys[#keys + 1] = number end
    end
    table.sort(keys)
    return keys
end

local function NormalizeReagents(schematic)
    local result = {}
    local slots = schematic and schematic.reagentSlotSchematics
    if type(slots) ~= "table" then return result, false end
    for index = 1, #slots do
        local slot = slots[index]
        if type(slot) == "table" and slot.required ~= false then
            local choices = {}
            local sourceChoices = type(slot.reagents) == "table" and slot.reagents or {}
            for choiceIndex = 1, #sourceChoices do
                local reagent = sourceChoices[choiceIndex]
                if type(reagent) == "table" and tonumber(reagent.itemID) then
                    choices[#choices + 1] = {
                        itemID = tonumber(reagent.itemID),
                        name = type(reagent.name) == "string" and reagent.name or nil,
                    }
                end
            end
            local hasVariable = type(slot.variableQuantities) == "table"
                and next(slot.variableQuantities) ~= nil
            result[#result + 1] = {
                quantity = tonumber(slot.quantityRequired),
                choices = choices,
                variable = hasVariable,
                slotIndex = tonumber(slot.slotIndex) or index,
            }
        end
    end
    return result, true
end

local function CurrentProfessionInfo()
    local api = _G.C_TradeSkillUI
    if type(api) ~= "table" then return nil end
    local info = SafeCall(api.GetChildProfessionInfo)
    if type(info) ~= "table" or not tonumber(info.professionID) or info.professionID == 0 then
        info = SafeCall(api.GetBaseProfessionInfo)
    end
    if type(info) ~= "table" then return nil end
    local professionID = tonumber(info.parentProfessionID) or tonumber(info.professionID)
    if not professionID or professionID <= 0 then return nil end
    return {
        professionID = professionID,
        professionName = type(info.professionName) == "string" and info.professionName
            or ("Profession " .. tostring(professionID)),
        skillLevel = tonumber(info.skillLevel),
        maxSkillLevel = tonumber(info.maxSkillLevel),
        sourceCounter = tonumber(info.sourceCounter),
    }
end

local captureFrame = CreateFrame("Frame")
local captureState
local captureGeneration = 0
local captureScheduled = false
local skippedUnchangedCaptures = 0
local lastCaptureReason = "none"
local captureForceRequested = false
local captureQueuedForce = false

local function GetCharacterStore()
    if type(MM.db) ~= "table" then return nil end
    MM.db.professionRecipesByCharacter = MM.db.professionRecipesByCharacter or {}
    local key = CharacterKey()
    MM.db.professionRecipesByCharacter[key] = MM.db.professionRecipesByCharacter[key] or {}
    return MM.db.professionRecipesByCharacter[key], key
end

local function CaptureBatch()
    local state = captureState
    if not state then return end
    local api = _G.C_TradeSkillUI
    if type(api) ~= "table" then
        captureState = nil
        captureFrame:SetScript("OnUpdate", nil)
        return
    end

    local stop = math.min(#state.recipeIDs, state.index + 19)
    while state.index <= stop do
        local recipeID = tonumber(state.recipeIDs[state.index])
        state.index = state.index + 1
        if recipeID then
            local info = SafeCall(api.GetRecipeInfo, recipeID)
            if type(info) == "table" and info.learned == true then
                local schematic = SafeCall(api.GetRecipeSchematic, recipeID, false)
                local outputData = SafeCall(api.GetRecipeOutputItemData, recipeID)
                local outputItemID = type(schematic) == "table" and tonumber(schematic.outputItemID) or nil
                outputItemID = outputItemID or (type(outputData) == "table" and tonumber(outputData.itemID))
                local reagents, reagentDataAvailable = NormalizeReagents(schematic)
                local quantityMin = type(schematic) == "table" and tonumber(schematic.quantityMin) or nil
                local quantityMax = type(schematic) == "table" and tonumber(schematic.quantityMax) or nil
                if not quantityMin and type(schematic) == "table" and schematic.hasSingleItemOutput then
                    quantityMin, quantityMax = 1, 1
                end
                state.recipes[recipeID] = {
                    recipeID = recipeID,
                    recipeName = type(info.name) == "string" and info.name
                        or (type(schematic) == "table" and schematic.name) or ("Recipe " .. tostring(recipeID)),
                    learned = true,
                    craftable = info.craftable == true,
                    outputItemID = outputItemID,
                    quantityMin = quantityMin,
                    quantityMax = quantityMax,
                    hasSingleItemOutput = type(schematic) == "table" and schematic.hasSingleItemOutput == true,
                    reagents = reagents,
                    reagentDataAvailable = reagentDataAvailable,
                    capturedAt = state.capturedAt,
                }
            end
        end
    end

    if state.index <= #state.recipeIDs then
        if MM.MarketUI and MM.MarketUI.SetStatus then
            MM.MarketUI.SetStatus(string.format("Reading %s recipes: %d/%d",
                state.profession.professionName, math.min(state.index - 1, #state.recipeIDs), #state.recipeIDs))
        end
        return
    end

    local store = GetCharacterStore()
    if store then
        local previous = store[state.profession.professionID]
        local recipes = state.recipes
        if not state.listComplete and type(previous) == "table" and type(previous.recipes) == "table" then
            for id, oldRecipe in pairs(previous.recipes) do
                if recipes[id] == nil then recipes[id] = oldRecipe end
            end
        end
        store[state.profession.professionID] = {
            professionID = state.profession.professionID,
            professionName = state.profession.professionName,
            skillLevel = state.profession.skillLevel,
            maxSkillLevel = state.profession.maxSkillLevel,
            capturedAt = state.capturedAt,
            source = "C_TradeSkillUI",
            listComplete = state.listComplete,
            recipeListSignature = state.recipeListSignature,
            recipes = recipes,
            recipeCount = (function()
                local count = 0
                for _ in pairs(recipes) do count = count + 1 end
                return count
            end)(),
        }
    end

    captureState = nil
    captureFrame:SetScript("OnUpdate", nil)
    if MM.MarketUI and MM.MarketUI.OnRecipesUpdated then
        MM.MarketUI.OnRecipesUpdated()
    end
    lastCaptureReason = "recipe-list-changed"
    if MM.Print then
        MM.Print(string.format("Captured known %s recipes (%d).",
            state.profession.professionName, (function()
                local count = 0
                for _ in pairs(state.recipes) do count = count + 1 end
                return count
            end)()))
    end
    if captureQueuedForce then
        captureQueuedForce = false
        Recipes.ScheduleCapture(true)
    end
end

local function RecipeListSignature(recipeIDs)
    local ids = {}
    for _, value in ipairs(recipeIDs or {}) do
        local id = tonumber(value)
        if id then ids[#ids + 1] = id end
    end
    table.sort(ids)
    local parts = {}
    for i = 1, #ids do parts[i] = tostring(ids[i]) end
    return table.concat(parts, ","), #ids
end

function Recipes.CaptureCurrentProfession(force)
    local api = _G.C_TradeSkillUI
    if type(api) ~= "table" then return false, "TRADE_SKILL_API_UNAVAILABLE" end
    local profession = CurrentProfessionInfo()
    if not profession then return false, "NO_ACTIVE_PROFESSION" end

    local recipeIDs
    local listComplete = false
    if type(api.GetAllRecipeIDs) == "function" then
        recipeIDs = SafeCall(api.GetAllRecipeIDs)
        listComplete = type(recipeIDs) == "table"
    end
    if type(recipeIDs) ~= "table" and type(api.GetFilteredRecipeIDs) == "function" then
        recipeIDs = SafeCall(api.GetFilteredRecipeIDs)
        listComplete = false
    end
    if type(recipeIDs) ~= "table" or #recipeIDs == 0 then
        return false, "RECIPE_LIST_UNAVAILABLE"
    end

    local signature, signatureCount = RecipeListSignature(recipeIDs)
    if signatureCount == 0 then return false, "RECIPE_LIST_UNAVAILABLE" end
    local store = GetCharacterStore()
    local previous = store and store[profession.professionID]
    if captureState and captureState.profession.professionID == profession.professionID
        and captureState.recipeListSignature == signature then
        if force == true then captureQueuedForce = true end
        skippedUnchangedCaptures = skippedUnchangedCaptures + 1
        lastCaptureReason = "duplicate-event-during-capture"
        return false, "CAPTURE_ALREADY_RUNNING"
    end
    if force ~= true and type(previous) == "table" and previous.recipeListSignature == signature
        and type(previous.recipes) == "table" then
        skippedUnchangedCaptures = skippedUnchangedCaptures + 1
        lastCaptureReason = "recipe-list-unchanged"
        return false, "RECIPE_LIST_UNCHANGED"
    end

    captureGeneration = captureGeneration + 1
    captureState = {
        generation = captureGeneration,
        profession = profession,
        recipeIDs = recipeIDs,
        recipeListSignature = signature,
        listComplete = listComplete,
        index = 1,
        recipes = {},
        capturedAt = type(_G.time) == "function" and _G.time() or 0,
    }
    captureFrame:SetScript("OnUpdate", function()
        CaptureBatch()
    end)
    if MM.MarketUI and MM.MarketUI.SetStatus then
        MM.MarketUI.SetStatus("Reading known " .. profession.professionName .. " recipes…")
    end
    return true
end

function Recipes.ScheduleCapture(force)
    if force == true then captureForceRequested = true end
    if captureScheduled then return end
    captureScheduled = true
    local function run()
        captureScheduled = false
        local forceNow = captureForceRequested
        captureForceRequested = false
        Recipes.CaptureCurrentProfession(forceNow)
    end
    if _G.C_Timer and type(_G.C_Timer.After) == "function" then
        _G.C_Timer.After(0.50, run)
    else
        run()
    end
end

function Recipes.GetAllRecipes()
    local store = GetCharacterStore()
    local result = {}
    if not store then return result end
    for _, professionID in ipairs(SortedNumericKeys(store)) do
        local profession = store[professionID]
        for _, recipeID in ipairs(SortedNumericKeys(profession.recipes)) do
            local recipe = profession.recipes[recipeID]
            if type(recipe) == "table" and recipe.learned == true then
                local copy = {}
                for key, value in pairs(recipe) do copy[key] = value end
                copy.professionID = profession.professionID
                copy.professionName = profession.professionName
                copy.professionSkill = profession.skillLevel
                copy.professionMaxSkill = profession.maxSkillLevel
                copy.listComplete = profession.listComplete
                result[#result + 1] = copy
            end
        end
    end
    return result
end

function Recipes.GetProfessionSummary()
    local store = GetCharacterStore()
    local result = { character = CharacterKey(), professions = {}, recipeCount = 0 }
    if not store then return result end
    for _, professionID in ipairs(SortedNumericKeys(store)) do
        local profession = store[professionID]
        result.professions[#result.professions + 1] = {
            professionID = profession.professionID,
            name = profession.professionName,
            skill = profession.skillLevel,
            maxSkill = profession.maxSkillLevel,
            recipeCount = profession.recipeCount or 0,
            listComplete = profession.listComplete == true,
        }
        result.recipeCount = result.recipeCount + (profession.recipeCount or 0)
    end
    return result
end

local function CountChoices(choices)
    local count = 0
    for _ in pairs(choices or {}) do count = count + 1 end
    return count
end

function Recipes.BuildEconomics(recipe, priceLookup, cutPercent)
    if type(recipe) ~= "table" then return nil end
    local result = {
        recipeData = recipe,
        recipeID = recipe.recipeID,
        professionID = tonumber(recipe.professionID),
        itemID = tonumber(recipe.outputItemID),
        recipeName = recipe.recipeName,
        itemName = recipe.recipeName,
        professionName = recipe.professionName,
        professionSkill = recipe.professionSkill,
        minPriceCopper = nil,
        salePriceCopper = nil,
        materialCostCopper = nil,
        profitCopper = nil,
        reagentLines = {},
        costComplete = true,
        costStatus = "Complete",
        missing = {},
    }
    local output = result.itemID and type(priceLookup) == "function" and priceLookup(result.itemID) or nil
    if type(output) == "table" then
        result.itemName = type(output.itemName) == "string" and output.itemName or recipe.recipeName
        result.salePriceCopper = tonumber(output.minPriceCopper)
        result.minPriceCopper = result.salePriceCopper
        result.totalQuantity = tonumber(output.totalQuantity) or 0
        result.minPriceQuantity = tonumber(output.minPriceQuantity)
    else
        result.itemName = recipe.recipeName
        result.totalQuantity = 0
    end

    local outputMin = tonumber(recipe.quantityMin)
    local outputMax = tonumber(recipe.quantityMax)
    if not outputMin and recipe.hasSingleItemOutput then outputMin, outputMax = 1, 1 end
    if outputMin and outputMin > 0 then
        result.outputQuantity = outputMin
        result.variableYield = outputMax and outputMax > outputMin or false
    else
        result.missing[#result.missing + 1] = "output quantity"
    end

    local totalCost = 0
    if recipe.reagentDataAvailable ~= true then
        result.costComplete = false
        result.missing[#result.missing + 1] = "reagent data"
    end
    for _, slot in ipairs(recipe.reagents or {}) do
        local quantity = tonumber(slot.quantity)
        local choices = slot.choices or {}
        local bestPrice, bestChoice, bestMarketItem
        local everyChoicePriced = #choices > 0
        for _, choice in ipairs(choices) do
            local marketItem = type(priceLookup) == "function" and priceLookup(choice.itemID) or nil
            local price = type(marketItem) == "table" and tonumber(marketItem.minPriceCopper) or nil
            if not price or price <= 0 then
                everyChoicePriced = false
            elseif not bestPrice or price < bestPrice then
                bestPrice = price
                bestChoice = choice
                bestMarketItem = marketItem
            end
        end
        local line = {
            itemID = bestChoice and bestChoice.itemID or (#choices == 1 and choices[1].itemID),
            itemName = (bestChoice and bestChoice.name)
                or (bestMarketItem and bestMarketItem.itemName)
                or (#choices == 1 and choices[1].name)
                or (#choices == 1 and ("Item #" .. tostring(choices[1].itemID)))
                or "Reagent",
            quantity = quantity,
            unitPriceCopper = bestPrice,
            lineCostCopper = bestPrice and quantity and bestPrice * quantity or nil,
            choiceCount = #choices,
            variable = slot.variable == true,
            complete = bestPrice ~= nil and quantity ~= nil and quantity > 0 and everyChoicePriced and slot.variable ~= true,
        }
        result.reagentLines[#result.reagentLines + 1] = line
        if line.complete then
            totalCost = totalCost + line.lineCostCopper
        else
            result.costComplete = false
            if slot.variable then
                result.missing[#result.missing + 1] = "variable reagent quantity"
            elseif #choices == 0 then
                result.missing[#result.missing + 1] = "reagent choice"
            elseif not quantity or quantity <= 0 then
                result.missing[#result.missing + 1] = "reagent quantity"
            else
                result.missing[#result.missing + 1] = "reagent market price"
            end
        end
    end

    if result.costComplete then
        result.materialCostCopper = totalCost
    else
        result.costStatus = "Incomplete"
    end

    local cut = math.max(0, math.min(100, tonumber(cutPercent) or 5))
    if result.salePriceCopper and result.salePriceCopper > 0 and result.outputQuantity then
        result.grossSaleCopper = result.salePriceCopper * result.outputQuantity
        result.netSaleCopper = math.floor(result.grossSaleCopper * (1 - cut / 100))
        result.cutPercent = cut
        if result.costComplete then
            result.profitCopper = result.netSaleCopper - result.materialCostCopper
            result.estimatedProfitCopper = result.profitCopper
            result.estimatedMarginPercent = result.materialCostCopper > 0
                and (result.profitCopper / result.materialCostCopper * 100) or 0
        end
    else
        result.saleStatus = "No market sale price"
    end
    if result.variableYield then
        result.yieldNote = "Profit uses minimum output quantity."
    end
    return result
end

local events = CreateFrame("Frame")
local registered = false
Recipes.registeredEvents = {}
for _, event in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE",
    "TRADE_SKILL_DATA_SOURCE_CHANGED", "NEW_RECIPE_LEARNED" }) do
    local ok = pcall(events.RegisterEvent, events, event)
    Recipes.registeredEvents[event] = ok == true
    if ok then registered = true end
end

function Recipes.GetCaptureStatus()
    local state = captureState
    return {
        events = Recipes.registeredEvents,
        active = state ~= nil,
        professionName = state and state.profession.professionName or nil,
        processed = state and math.min(state.index - 1, #state.recipeIDs) or nil,
        total = state and #state.recipeIDs or nil,
        skippedUnchanged = skippedUnchangedCaptures,
        lastCaptureReason = lastCaptureReason,
    }
end
if registered then
    events:SetScript("OnEvent", function(_, event)
        if event == "NEW_RECIPE_LEARNED" then
            -- GetAllRecipeIDs includes learned and unlearned entries; the ID
            -- list itself may not change when an existing entry becomes learned.
            Recipes.ScheduleCapture(true)
        elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_LIST_UPDATE"
            or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" then
            Recipes.ScheduleCapture(false)
        end
    end)
end
