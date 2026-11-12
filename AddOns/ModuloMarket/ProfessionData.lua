local MM = _G.ModuloMarket
if not MM then return end

local Data = {}
MM.ProfessionData = Data

local PROFESSION_NAMES = {
    [129] = "First Aid",
    [164] = "Blacksmithing",
    [165] = "Leatherworking",
    [171] = "Alchemy",
    [182] = "Herbalism",
    [185] = "Cooking",
    [186] = "Mining",
    [197] = "Tailoring",
    [202] = "Engineering",
    [333] = "Enchanting",
    [356] = "Fishing",
    [393] = "Skinning",
    [755] = "Jewelcrafting",
    [773] = "Inscription",
}

local index = {}
local professions = {}
local allFutureRecipes = {}
local foreverRecipeDetails = {}
local futureProvider = {
    available = false,
    status = "LibProfessionDB is not installed",
    count = 0,
    unknownSourceCount = 0,
    borrowedSourceCount = 0,
}

-- Targeted review watch retained from the November 10, 2026 Forever hotfix report.
-- The 1.60.1.70888 ForeverDB capture now directly supplies Coarse Grinding Stone's
-- updated skill-up thresholds (recipe 3326), so that resolved watch was retired.
-- Remaining entries are unchanged in the new capture and stay advisory field-level flags.
local FOREVERDB_HOTFIX_WATCH = {
    [1283400] = { field = "placement requirement", note = "Journeyman Campfire placement requirement was reported changed; verify nearby/tool requirements." },
    [1245246] = { field = "sell price", note = "Minor Arcane Elixir sell price was reported changed; use current live item pricing." },
    [3962] = { field = "vendor price", note = "Iron Grenade vendor price was reported changed; verify vendor pricing before using it." },
}

local function EnsureItem(itemID)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then return nil end
    local entry = index[itemID]
    if not entry then
        entry = {
            itemID = itemID,
            professions = {},
            knownCrafts = {},
            futureCrafts = {},
            unknownFutureCrafts = {},
            gathering = {},
            materialForCraft = false,
            materialProfessions = {},
            itemName = nil,
        }
        index[itemID] = entry
    end
    return entry
end

local function AddProfession(itemID, professionID, professionName)
    local entry = EnsureItem(itemID)
    if not entry then return end
    professionID = tonumber(professionID)
    if not professionID then return end
    entry.professions[professionID] = professionName or PROFESSION_NAMES[professionID]
    if not professions[professionID] then
        professions[professionID] = professionName or PROFESSION_NAMES[professionID]
            or ("Profession " .. tostring(professionID))
    elseif professionName and professionName ~= "" then
        professions[professionID] = professionName
    end
end

local function HasSource(source)
    if type(source) ~= "table" then return false end
    return next(source) ~= nil
end

local function IsBorrowedValue(value)
    if value == true then return true end
    if type(value) == "string" then
        local normalized = string.lower(value)
        return normalized ~= "" and normalized ~= "false" and normalized ~= "none"
    end
    return false
end

local function SafeMethod(object, method, ...)
    if type(object) ~= "table" or type(object[method]) ~= "function" then return nil end
    local ok, a, b, c = pcall(object[method], object, ...)
    if ok then return a, b, c end
    return nil
end

local function GetProfessionDB()
    local stub = _G.LibStub
    if type(stub) ~= "table" and type(stub) ~= "function" then return nil end
    local ok, db = pcall(stub, "LibProfessionDB-1.0", true)
    if ok and type(db) == "table" then return db end
    return nil
end

local function AddGatheringItems(knownProfessions)
    local sources = MM.GatheringItems or {}
    for itemID, record in pairs(sources) do
        local professionID, requiredSkill
        if type(record) == "table" then
            professionID, requiredSkill = tonumber(record[1]), tonumber(record[2])
        else
            professionID, requiredSkill = tonumber(record), 1
        end
        if professionID and requiredSkill then
            -- Classification is independent of current skill. A resource remains
            -- a Mining/Herbalism/Fishing resource even when this character has not
            -- learned the profession or has not reached the node's skill threshold.
            local professionName = professions[professionID] or PROFESSION_NAMES[professionID]
            AddProfession(itemID, professionID, professionName)
            local entry = EnsureItem(itemID)
            local currentSkill = tonumber(knownProfessions[professionID])
            entry.gathering[professionID] = {
                requiredSkill = requiredSkill,
                currentSkill = currentSkill,
                canGatherNow = currentSkill ~= nil and currentSkill >= requiredSkill,
                skillKnown = currentSkill ~= nil,
            }
        end
    end
end

local function AddKnownRecipes()
    if not (MM.Recipes and type(MM.Recipes.GetAllRecipes) == "function") then return end
    local ok, recipes = pcall(MM.Recipes.GetAllRecipes)
    if not ok or type(recipes) ~= "table" then return end

    for _, recipe in ipairs(recipes) do
        local professionID = tonumber(recipe.professionID)
        local professionName = recipe.professionName
        if professionID then
            local outputID = tonumber(recipe.outputItemID)
            if outputID then
                AddProfession(outputID, professionID, professionName)
                local entry = EnsureItem(outputID)
                entry.knownCrafts[#entry.knownCrafts + 1] = {
                    recipeID = tonumber(recipe.recipeID),
                    recipeName = recipe.recipeName,
                    professionID = professionID,
                    professionName = professionName,
                }
            end
            for _, slot in ipairs(recipe.reagents or {}) do
                for _, choice in ipairs(slot.choices or {}) do
                    AddProfession(choice.itemID, professionID, professionName)
                    local material = EnsureItem(choice.itemID)
                    if material then
                        material.materialForCraft = true
                        material.materialProfessions[professionID] = professionName
                        if not material.itemName and type(choice.name) == "string" then
                            material.itemName = choice.name
                        end
                    end
                end
            end
        end
    end
end

local function NormalizeLibraryReagents(source)
    local result = {}
    if type(source) ~= "table" then return result, false end
    local totalEntries = 0
    local positionalArray = true
    for key in pairs(source) do
        totalEntries = totalEntries + 1
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            positionalArray = false
        end
    end
    if positionalArray then
        for i = 1, totalEntries do
            if source[i] == nil then positionalArray = false; break end
        end
    end
    for key, value in pairs(source) do
        totalEntries = totalEntries + 1
        local itemID, quantity, name
        if type(value) == "table" then
            local numericKey = tonumber(key)
            itemID = tonumber(value.itemID) or (numericKey and numericKey > 100 and numericKey or nil)
            quantity = tonumber(value.quantity or value.count or value.amount)
            name = value.name
        else
            local numericKey = tonumber(key)
            -- Scalar itemID->quantity maps may use low IDs; distinguish them from
            -- contiguous scalar arrays before accepting their numeric keys.
            itemID = not positionalArray and numericKey and numericKey > 0 and numericKey or nil
            quantity = tonumber(value)
        end
        -- Also accept array-shaped reagent records, while refusing to interpret
        -- an array index as an item ID when the record has no itemID.
        if itemID and itemID > 0 then
            result[#result + 1] = {
                quantity = quantity,
                choices = { { itemID = itemID, name = type(name) == "string" and name or nil } },
                variable = false,
            }
        end
    end
    table.sort(result, function(a, b)
        return (tonumber(a.choices[1].itemID) or 0) < (tonumber(b.choices[1].itemID) or 0)
    end)
    return result, totalEntries == 0 or #result == totalEntries
end


local function ComposeClientBuild(version, build)
    if type(version) ~= "string" or version == "" or build == nil then return nil end
    local suffix = "." .. tostring(build)
    if string.sub(version, -#suffix) == suffix then return version end
    return version .. suffix
end

local function CurrentClientBuild()
    if type(_G.GetBuildInfo) ~= "function" then return nil end
    local ok, version, build = pcall(_G.GetBuildInfo)
    if not ok then return nil end
    return ComposeClientBuild(version, build)
end

local function AddForeverDBRecipes()
    local dataset = MM.ForeverDBData
    if type(dataset) ~= "table" then return false end

    local meta = type(dataset.meta) == "table" and dataset.meta or {}
    local datasetBuild = type(meta.clientBuild) == "string" and meta.clientBuild or nil
    local currentBuild = CurrentClientBuild()
    futureProvider = {
        available = false,
        status = "ForeverDB data build could not be checked",
        count = 0,
        unknownSourceCount = 0,
        borrowedSourceCount = 0,
        recipeCount = 0,
        speculativeCount = 0,
        nonItemCount = 0,
        excludedKnownCount = 0,
        dataSource = "ForeverDB.net",
        datasetBuild = datasetBuild,
        currentBuild = currentBuild,
        dataBuildMatchesClient = datasetBuild ~= nil and currentBuild ~= nil and datasetBuild == currentBuild,
        reviewWatchCount = 0,
        baselineCount = 0,
    }
    if not currentBuild then
        futureProvider.status = "Cannot identify this client's build; ForeverDB baseline is not loaded"
        return true
    end
    if not datasetBuild then
        futureProvider.status = "ForeverDB dataset has no build provenance; recipes are not loaded"
        return true
    end

    local learned, learnedByOutput = {}, {}
    if MM.Recipes and type(MM.Recipes.GetAllRecipes) == "function" then
        local ok, recipes = pcall(MM.Recipes.GetAllRecipes)
        if ok and type(recipes) == "table" then
            for _, recipe in ipairs(recipes) do
                local pid, rid = tonumber(recipe.professionID), tonumber(recipe.recipeID)
                local outputID = tonumber(recipe.outputItemID)
                if pid and rid then
                    learned[pid] = learned[pid] or {}
                    learned[pid][rid] = true
                end
                if pid and outputID then
                    learnedByOutput[pid] = learnedByOutput[pid] or {}
                    learnedByOutput[pid][outputID] = learnedByOutput[pid][outputID] or {}
                    learnedByOutput[pid][outputID][#learnedByOutput[pid][outputID] + 1] = recipe.recipeName
                end
            end
        end
    end

    local function NormalizeName(value)
        if type(value) ~= "string" then return nil end
        value = string.lower(value):gsub("%s+", " ")
        value = value:gsub("^%s+", ""):gsub("%s+$", "")
        return value ~= "" and value or nil
    end

    local totalCount, speculativeCount, nonItemCount = 0, 0, 0
    local knownCount, borrowedCount, unknownCount, excludedKnownCount = 0, 0, 0, 0
    local providerProfessions = type(dataset.professions) == "table" and dataset.professions or {}
    for slug, profession in pairs(providerProfessions) do
        if type(profession) == "table" then
            local professionID = tonumber(profession.professionID)
            local professionName = type(profession.name) == "string" and profession.name
                or (professionID and PROFESSION_NAMES[professionID])
                or tostring(slug)
            if professionID then professions[professionID] = professionName end
            for _, sourceRecipe in ipairs(type(profession.recipes) == "table" and profession.recipes or {}) do
                if type(sourceRecipe) == "table" then
                    totalCount = totalCount + 1
                    if sourceRecipe.speculative == true then
                        speculativeCount = speculativeCount + 1
                    else
                        local recipeID = tonumber(sourceRecipe.recipeID or sourceRecipe.id)
                        local outputRows = type(sourceRecipe.outputs) == "table" and sourceRecipe.outputs or {}
                        local output = outputRows[1]
                        local outputID = type(output) == "table" and tonumber(output.itemID or output.id) or nil
                        local recipeName = type(sourceRecipe.recipeName or sourceRecipe.name) == "string"
                            and (sourceRecipe.recipeName or sourceRecipe.name) or "Unknown recipe"
                        local alreadyKnown = recipeID and learned[professionID]
                            and learned[professionID][recipeID] == true or false
                        if recipeID and outputID and sourceRecipe.kind ~= "enchantment"
                            and sourceRecipe.kind ~= "service" then
                            foreverRecipeDetails[tostring(professionID) .. ":" .. tostring(recipeID)] = {
                                acquisitionSources = type(sourceRecipe.acquisitionSources) == "table"
                                    and sourceRecipe.acquisitionSources or {},
                                automatic = sourceRecipe.automatic == true,
                                sourceKnown = sourceRecipe.sourceKnown == true,
                                borrowedSources = sourceRecipe.borrowedSources == true,
                                sourceUnknown = sourceRecipe.sourceUnknown == true,
                                trainerCostCopper = tonumber(sourceRecipe.trainerCostCopper),
                                trainerCostEvidence = sourceRecipe.trainerCostEvidence,
                                learnAtSkill = tonumber(sourceRecipe.learnAtSkill),
                                sourceProvider = "ForeverDB.net",
                                sourceBuild = datasetBuild,
                            }
                        end
                        if outputID and sourceRecipe.kind ~= "enchantment"
                            and sourceRecipe.kind ~= "service" then
                            local normalizedName = NormalizeName(recipeName)
                            if not alreadyKnown and learnedByOutput[professionID]
                                and learnedByOutput[professionID][outputID] and normalizedName then
                                for _, knownName in ipairs(learnedByOutput[professionID][outputID]) do
                                    if NormalizeName(knownName) == normalizedName then
                                        alreadyKnown = true
                                        break
                                    end
                                end
                            end
                            if alreadyKnown then
                                excludedKnownCount = excludedKnownCount + 1
                            else
                                local reagentSlots = {}
                                for _, group in ipairs(type(sourceRecipe.reagents) == "table" and sourceRecipe.reagents or {}) do
                                    if type(group) == "table" then
                                        local choices = {}
                                        for _, choice in ipairs(type(group.choices) == "table" and group.choices or {}) do
                                            local itemID = type(choice) == "table" and tonumber(choice.itemID or choice.id)
                                            if itemID and itemID > 0 then
                                                choices[#choices + 1] = {
                                                    itemID = itemID,
                                                    name = type(choice.name) == "string" and choice.name or nil,
                                                }
                                            end
                                        end
                                        local qmin, qmax = tonumber(group.quantityMin or group.min),
                                            tonumber(group.quantityMax or group.max)
                                        reagentSlots[#reagentSlots + 1] = {
                                            quantity = qmin,
                                            choices = choices,
                                            variable = qmin == nil or qmax == nil or qmax > qmin,
                                            required = group.required ~= false,
                                        }
                                    end
                                end
                                local outputMin = tonumber(output.quantityMin or output.min)
                                local outputMax = tonumber(output.quantityMax or output.max)
                                local sourceKnown = sourceRecipe.sourceKnown == true
                                local borrowedSources = sourceRecipe.borrowedSources == true and not sourceKnown
                                local sourceUnknown = not sourceKnown and not borrowedSources
                                local hotfixWatch = recipeID and FOREVERDB_HOTFIX_WATCH[recipeID] or nil
                                local future = {
                                    recipeID = recipeID,
                                    recipeName = recipeName,
                                    professionID = professionID,
                                    professionName = professionName,
                                    outputItemID = outputID,
                                    quantityMin = outputMin,
                                    quantityMax = outputMax,
                                    hasSingleItemOutput = outputMin == 1 and outputMax == 1,
                                    reagents = reagentSlots,
                                    reagentDataAvailable = sourceRecipe.reagentDataAvailable == true,
                                    learned = false,
                                    craftable = false,
                                    sourceKnown = sourceKnown,
                                    sourceUnknown = sourceUnknown,
                                    borrowedSources = borrowedSources,
                                    automatic = sourceRecipe.automatic == true,
                                    observedSourceTypes = sourceRecipe.observedSourceTypes or {},
                                    borrowedSourceTypes = sourceRecipe.borrowedSourceTypes or {},
                                    acquisitionSources = type(sourceRecipe.acquisitionSources) == "table"
                                        and sourceRecipe.acquisitionSources or {},
                                    trainerCostCopper = tonumber(sourceRecipe.trainerCostCopper),
                                    trainerCostEvidence = sourceRecipe.trainerCostEvidence,
                                    professionSkill = tonumber(sourceRecipe.learnAtSkill),
                                    skillThresholds = sourceRecipe.skill or {},
                                    newInForever = sourceRecipe.newInForever == true,
                                    changedFromClassic = sourceRecipe.changedFromClassic,
                                    sourceProvider = "ForeverDB.net",
                                    sourceBuild = datasetBuild,
                                    freshnessStatus = hotfixWatch and "review" or "baseline",
                                    freshnessField = hotfixWatch and hotfixWatch.field or nil,
                                    freshnessNote = hotfixWatch and hotfixWatch.note or nil,
                                }
                                allFutureRecipes[#allFutureRecipes + 1] = future
                                if hotfixWatch then
                                    futureProvider.reviewWatchCount = futureProvider.reviewWatchCount + 1
                                else
                                    futureProvider.baselineCount = futureProvider.baselineCount + 1
                                end
                                AddProfession(outputID, professionID, professionName)
                                local outputEntry = EnsureItem(outputID)
                                if outputEntry then
                                    if sourceUnknown then
                                        outputEntry.unknownFutureCrafts[#outputEntry.unknownFutureCrafts + 1] = future
                                    else
                                        outputEntry.futureCrafts[#outputEntry.futureCrafts + 1] = future
                                    end
                                    if not outputEntry.itemName and type(output.name) == "string" then
                                        outputEntry.itemName = output.name
                                    end
                                end
                                for _, slot in ipairs(reagentSlots) do
                                    for _, choice in ipairs(slot.choices) do
                                        AddProfession(choice.itemID, professionID, professionName)
                                        local material = EnsureItem(choice.itemID)
                                        if material then
                                            material.materialForCraft = true
                                            material.materialProfessions[professionID] = professionName
                                            if not material.itemName and type(choice.name) == "string" then
                                                material.itemName = choice.name
                                            end
                                        end
                                    end
                                end
                                if sourceKnown then knownCount = knownCount + 1
                                elseif borrowedSources then borrowedCount = borrowedCount + 1
                                else unknownCount = unknownCount + 1 end
                            end
                        else
                            nonItemCount = nonItemCount + 1
                        end
                    end
                end
            end
        end
    end

    futureProvider.available = true
    if futureProvider.dataBuildMatchesClient then
        futureProvider.status = "ForeverDB recipes loaded · matching build " .. datasetBuild
    else
        futureProvider.status = string.format(
            "ForeverDB baseline loaded · data %s on client %s · %d hotfix-linked records flagged for review",
            datasetBuild, currentBuild, futureProvider.reviewWatchCount)
    end
    futureProvider.count = knownCount
    futureProvider.borrowedSourceCount = borrowedCount
    futureProvider.unknownSourceCount = unknownCount
    futureProvider.recipeCount = totalCount
    futureProvider.speculativeCount = speculativeCount
    futureProvider.nonItemCount = nonItemCount
    futureProvider.excludedKnownCount = excludedKnownCount
    return true
end


local function AddFutureRecipes()
    local db = GetProfessionDB()
    if not db then
        futureProvider.available = false
        futureProvider.status = "Install LibProfessionDB 1.9.1 for unlearned recipe data"
        return
    end

    local ready = SafeMethod(db, "IsReady")
    local game = SafeMethod(db, "GetGameVersion")
    if ready ~= true then
        futureProvider.available = false
        futureProvider.status = "LibProfessionDB is present but its data is not ready"
        return
    end
    if game ~= "Forever" then
        futureProvider.available = false
        futureProvider.status = "LibProfessionDB data does not identify this client as Forever"
        return
    end
    if type(db.GetProfessions) ~= "function" or type(db.Iterate) ~= "function" then
        futureProvider.available = false
        futureProvider.status = "LibProfessionDB API is incomplete"
        return
    end

    local learned, learnedByOutput = {}, {}
    if MM.Recipes and type(MM.Recipes.GetAllRecipes) == "function" then
        local ok, recipes = pcall(MM.Recipes.GetAllRecipes)
        if ok and type(recipes) == "table" then
            for _, recipe in ipairs(recipes) do
                local pid, rid = tonumber(recipe.professionID), tonumber(recipe.recipeID)
                local outputID = tonumber(recipe.outputItemID)
                if pid and rid then
                    learned[pid] = learned[pid] or {}
                    learned[pid][rid] = true
                end
                if pid and outputID then
                    learnedByOutput[pid] = learnedByOutput[pid] or {}
                    learnedByOutput[pid][outputID] = learnedByOutput[pid][outputID] or {}
                    learnedByOutput[pid][outputID][#learnedByOutput[pid][outputID] + 1] = {
                        recipeID = rid,
                        recipeName = type(recipe.recipeName) == "string" and recipe.recipeName or nil,
                    }
                end
            end
        end
    end

    local function NormalizeRecipeName(name)
        if type(name) ~= "string" then return nil end
        name = string.lower(name)
        name = name:gsub("%s+", " ")
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        return name ~= "" and name or nil
    end

    local function IsAlreadyKnown(professionID, recipeID, outputID, recipeName)
        if learned[professionID] and learned[professionID][recipeID] then return true end
        local candidates = learnedByOutput[professionID] and learnedByOutput[professionID][outputID]
        local normalizedName = NormalizeRecipeName(recipeName)
        if not candidates or not normalizedName then return false end
        for _, known in ipairs(candidates) do
            if NormalizeRecipeName(known.recipeName) == normalizedName then return true end
        end
        return false
    end

    local ok, professionIDs = pcall(db.GetProfessions, db)
    if not ok or type(professionIDs) ~= "table" then
        futureProvider.available = false
        futureProvider.status = "LibProfessionDB profession list could not be read"
        return
    end

    local count, unknownCount, borrowedCount = 0, 0, 0
    for _, professionID in ipairs(professionIDs) do
        professionID = tonumber(professionID)
        if professionID then
            local professionName = PROFESSION_NAMES[professionID]
            local iteratorOK, iterator = pcall(db.Iterate, db, professionID)
            if iteratorOK and type(iterator) == "function" then
                while true do
                    local callOK, pid, recipeID, recipe = pcall(iterator)
                    if not callOK or pid == nil then break end
                    recipeID = tonumber(recipeID)
                    if recipeID and type(recipe) == "table" then
                        local outputID = tonumber(recipe.craftedItemId)
                        local isKnown = IsAlreadyKnown(professionID, recipeID, outputID, recipe.name)
                        local hidden = SafeMethod(db, "IsHiddenRecipe", recipeID) == true
                        if not hidden then
                            local reagents, reagentDataAvailable = NormalizeLibraryReagents(recipe.reagents)
                            local sources = SafeMethod(db, "GetRecipeSources", recipeID)
                            local autoTaught = SafeMethod(db, "IsAutoTaughtRecipe", recipeID) == true
                            local borrowedSources = IsBorrowedValue(
                                SafeMethod(db, "IsBorrowed", recipeID, "sources"))
                            local borrowedSkill = IsBorrowedValue(
                                SafeMethod(db, "IsBorrowed", recipeID, "requiredSkill"))
                            local hasSource = HasSource(sources) or autoTaught
                            local future = {
                                recipeID = recipeID,
                                recipeName = recipe.name or ("Recipe " .. tostring(recipeID)),
                                professionID = professionID,
                                professionName = professionName,
                                outputItemID = outputID,
                                quantityMin = tonumber(recipe.quantityMin or recipe.outputQuantityMin
                                    or recipe.craftedItemCount or recipe.outputCount),
                                quantityMax = tonumber(recipe.quantityMax or recipe.outputQuantityMax
                                    or recipe.craftedItemCount or recipe.outputCount),
                                reagents = reagents,
                                reagentDataAvailable = reagentDataAvailable,
                                requiredSkill = not borrowedSkill and tonumber(recipe.requiredSkill) or nil,
                                borrowedSkill = borrowedSkill,
                                borrowedSources = borrowedSources,
                                autoTaught = autoTaught,
                                sourceKnown = hasSource,
                                sourceUnknown = not hasSource,
                                learningSources = sources,
                            }
                            -- A known recipe must not also be indexed as a future
                            -- output. Some library revisions expose a different recipe
                            -- key for the same learned recipe; IsAlreadyKnown also checks
                            -- profession + output + normalized recipe name.
                            if outputID and not isKnown then
                                AddProfession(outputID, professionID, professionName)
                                local entry = EnsureItem(outputID)
                                if hasSource then
                                    entry.futureCrafts[#entry.futureCrafts + 1] = future
                                else
                                    entry.unknownFutureCrafts[#entry.unknownFutureCrafts + 1] = future
                                end
                                allFutureRecipes[#allFutureRecipes + 1] = future
                                if hasSource then
                                    count = count + 1
                                    if borrowedSources then borrowedCount = borrowedCount + 1 end
                                else
                                    unknownCount = unknownCount + 1
                                end

                                for _, slot in ipairs(reagents) do
                                    for _, choice in ipairs(slot.choices or {}) do
                                        AddProfession(choice.itemID, professionID, professionName)
                                        local material = EnsureItem(choice.itemID)
                                        if material then
                                            material.materialForCraft = true
                                            material.materialProfessions[professionID] = professionName
                                            if not material.itemName and type(choice.name) == "string" then
                                                material.itemName = choice.name
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    futureProvider.available = true
    futureProvider.status = "Forever recipe data loaded"
    futureProvider.count = count
    futureProvider.unknownSourceCount = unknownCount
    futureProvider.borrowedSourceCount = borrowedCount
end

function Data.Refresh()
    index = {}
    professions = {}
    allFutureRecipes = {}
    foreverRecipeDetails = {}
    futureProvider = {
        available = false,
        status = "Checking profession data…",
        count = 0,
        unknownSourceCount = 0,
        borrowedSourceCount = 0,
    }

    local summary = MM.Recipes and MM.Recipes.GetProfessionSummary and MM.Recipes.GetProfessionSummary()
    for _, profession in ipairs(summary and summary.professions or {}) do
        if profession.professionID then
            professions[tonumber(profession.professionID)] = profession.name
                or PROFESSION_NAMES[tonumber(profession.professionID)]
        end
    end

    local knownProfessions = {}
    for _, profession in ipairs(summary and summary.professions or {}) do
        local professionID = tonumber(profession.professionID)
        if professionID then knownProfessions[professionID] = tonumber(profession.skill) or 0 end
    end

    AddKnownRecipes()
    if not AddForeverDBRecipes() then
        AddFutureRecipes()
    end
    AddGatheringItems(knownProfessions)
end

function Data.GetItem(itemID)
    return index[tonumber(itemID)]
end

function Data.GetProfessions()
    local result = {}
    for id, name in pairs(professions) do
        result[#result + 1] = { id = id, name = name or PROFESSION_NAMES[id] or ("Profession " .. id) }
    end
    table.sort(result, function(a, b) return tostring(a.name) < tostring(b.name) end)
    return result
end

function Data.HasGatheringData()
    for _, entry in pairs(index) do
        if next(entry.gathering) then return true end
    end
    return false
end

function Data.GetGatheringInfo(itemID)
    local entry = Data.GetItem(itemID)
    return entry and entry.gathering or nil
end

function Data.GetAllFutureRecipes()
    return allFutureRecipes
end

function Data.GetForeverRecipeDetails(professionID, recipeID)
    if not professionID or not recipeID then return nil end
    return foreverRecipeDetails[tostring(tonumber(professionID)) .. ":" .. tostring(tonumber(recipeID))]
end

function Data.GetMaterialItems()
    local result = {}
    for itemID, entry in pairs(index) do
        if entry.materialForCraft then
            result[#result + 1] = {
                itemID = itemID,
                itemName = entry.itemName,
                professions = entry.professions,
            }
        end
    end
    table.sort(result, function(a, b) return a.itemID < b.itemID end)
    return result
end

function Data.IsMaterial(itemID)
    local entry = Data.GetItem(itemID)
    return entry ~= nil and entry.materialForCraft == true
end

function Data.IsGatherable(itemID)
    local entry = Data.GetItem(itemID)
    return entry ~= nil and next(entry.gathering) ~= nil
end

function Data.GetFutureProviderStatus()
    return {
        available = futureProvider.available,
        status = futureProvider.status,
        count = futureProvider.count,
        unknownSourceCount = futureProvider.unknownSourceCount,
        borrowedSourceCount = futureProvider.borrowedSourceCount,
        recipeCount = futureProvider.recipeCount,
        speculativeCount = futureProvider.speculativeCount,
        nonItemCount = futureProvider.nonItemCount,
        excludedKnownCount = futureProvider.excludedKnownCount,
        dataSource = futureProvider.dataSource,
        datasetBuild = futureProvider.datasetBuild,
        currentBuild = futureProvider.currentBuild,
        dataBuildMatchesClient = futureProvider.dataBuildMatchesClient,
        reviewWatchCount = futureProvider.reviewWatchCount,
        baselineCount = futureProvider.baselineCount,
    }
end

function Data.IsMarketSnapshotCompatible(snapshot)
    if futureProvider.dataSource ~= "ForeverDB.net" then return true, nil end
    if type(snapshot) ~= "table" then return false, nil end
    local version = type(snapshot.clientVersion) == "string" and snapshot.clientVersion or nil
    local build = snapshot.clientBuild
    if not version or version == "" or version == "unknown" or build == nil then return false, nil end
    build = tostring(build)
    if build == "" or build == "unknown" then return false, nil end
    local snapshotBuild = ComposeClientBuild(version, build)
    return snapshotBuild ~= nil and futureProvider.currentBuild ~= nil
        and snapshotBuild == futureProvider.currentBuild, snapshotBuild
end

function Data.Matches(itemID, professionID, role)
    local entry = Data.GetItem(itemID)
    if professionID and tonumber(professionID) and tonumber(professionID) ~= 0 then
        if not entry or not entry.professions[tonumber(professionID)] then return false end
    end
    if role == "known" then
        return entry ~= nil and #entry.knownCrafts > 0
    elseif role == "unlearned" then
        return entry ~= nil and #entry.knownCrafts == 0
            and (#entry.futureCrafts > 0 or #entry.unknownFutureCrafts > 0)
    elseif role == "gather" then
        return entry ~= nil and next(entry.gathering) ~= nil
    elseif role == "material" then
        return entry ~= nil and entry.materialForCraft == true
    end
    return true
end

function Data.GetItemTags(itemID)
    local entry = Data.GetItem(itemID)
    if not entry then return nil end
    local tags = {}
    local hasKnownCraft = #entry.knownCrafts > 0
    if hasKnownCraft then
        tags[#tags + 1] = "known"
    else
        local hasFuture, hasBorrowed = false, false
        for _, future in ipairs(entry.futureCrafts) do
            if future.borrowedSources then hasBorrowed = true else hasFuture = true end
        end
        if hasFuture then tags[#tags + 1] = "future" end
        if hasBorrowed then tags[#tags + 1] = "futureBorrowed" end
        if #entry.unknownFutureCrafts > 0 then tags[#tags + 1] = "futureUnknown" end
    end
    if next(entry.gathering) then tags[#tags + 1] = "gather" end
    if entry.materialForCraft then tags[#tags + 1] = "material" end
    return #tags > 0 and tags or nil
end

function Data.OnRecipesUpdated()
    Data.Refresh()
end

Data.Refresh()
