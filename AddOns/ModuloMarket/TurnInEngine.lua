local MM = _G.ModuloMarket
if not MM then return end

local Engine = {}
MM.TurnInEngine = Engine

-- Favor and reputation are mutually exclusive in the compact reward cell.
-- Prefer Favor when reported; otherwise show reputation, preserving known zero.
function Engine.FormatReward(item, compact)
    if type(item) ~= "table" then return "?" end
    if item.rewardFavor ~= nil then
        return tostring(item.rewardFavor) .. (compact and " Fav" or " Favor")
    end
    if item.reputation ~= nil then
        return tostring(item.reputation) .. (compact and " Rep" or " Reputation")
    end
    return "?"
end

local function NormalizeName(value)
    value = string.lower(tostring(value or ""))
    value = value:gsub("['’]", "")
    value = value:gsub("[^%w]+", " ")
    return value:match("^%s*(.-)%s*$") or ""
end

local function BuildNameIndex(catalog)
    local byName = {}
    for _, item in ipairs(catalog or {}) do
        local key = NormalizeName(item.itemName)
        if key ~= "" then
            if byName[key] == nil then byName[key] = item
            elseif byName[key] ~= item then byName[key] = false end
        end
    end
    return byName
end

local function PriceFor(item, quantity)
    if type(item) ~= "table" then return nil, "No current Auction House listing" end
    local price = tonumber(item.minPriceCopper)
    if not price or price <= 0 then return nil, "No current buyout" end
    local total = tonumber(item.totalQuantity) or 0
    if total < quantity then return nil, string.format("Only %d of %d required units listed", total, quantity) end
    local depth = tonumber(item.minPriceQuantity)
    if not depth then return nil, "Cheapest-price quantity is unknown" end
    if depth < quantity then
        return nil, string.format("Only %d units are available at the cheapest price; deeper listing prices are not exposed by this snapshot", depth)
    end
    return price * quantity, nil
end

local function EvaluateBundle(bundle, byName)
    local total, lines, complete, reasons = 0, {}, true, {}
    for _, requirement in ipairs(bundle or {}) do
        local name, quantity = requirement[1], tonumber(requirement[2]) or 0
        local marketItem = byName[NormalizeName(name)]
        local lineCost, reason
        if marketItem == false then reason = "Ambiguous market item name"
        else lineCost, reason = PriceFor(marketItem, quantity) end
        if lineCost then total = total + lineCost else complete = false; reasons[#reasons + 1] = name .. ": " .. tostring(reason) end
        lines[#lines + 1] = {
            itemName = name, quantity = quantity,
            itemID = marketItem and tonumber(marketItem.itemID) or nil,
            unitPriceCopper = marketItem and tonumber(marketItem.minPriceCopper) or nil,
            cheapestDepth = marketItem and tonumber(marketItem.minPriceQuantity) or nil,
            listedQuantity = marketItem and tonumber(marketItem.totalQuantity) or 0,
            lineCostCopper = lineCost, status = lineCost and "priced" or "unknown", reason = reason,
        }
    end
    return { complete=complete, costCopper=complete and total or nil, lines=lines, reasons=reasons }
end

local function ProfessionAllowed(writ, professionName)
    for _, name in ipairs(writ.professions or {}) do
        if NormalizeName(name) == NormalizeName(professionName) then return true end
    end
    return false
end

local function GetWritRecipes()
    local recipes, seen = {}, {}
    local function add(recipe)
        if type(recipe) ~= "table" then return end
        local outputID = tonumber(recipe.outputItemID)
        local recipeName = recipe.recipeName or recipe.itemName
        if (not recipeName or recipeName == "") and outputID and MM.ProfessionData and MM.ProfessionData.GetItem then
            local item = MM.ProfessionData.GetItem(outputID)
            recipeName = item and item.itemName
        end
        local key = NormalizeName(recipeName)
        local professionName = recipe.professionName
        local identity = tostring(recipe.professionID or professionName or "") .. ":"
            .. tostring(recipe.recipeID or recipeName or "")
        if key ~= "" and outputID and not seen[identity] then
            seen[identity] = true
            recipes[key] = recipes[key] or {}
            recipes[key][#recipes[key] + 1] = recipe
        end
    end
    if MM.Recipes and type(MM.Recipes.GetAllRecipes) == "function" then
        local ok, learned = pcall(MM.Recipes.GetAllRecipes, MM.db and MM.db.craftingScope or "character")
        if ok and type(learned) == "table" then for _, recipe in ipairs(learned) do add(recipe) end end
    end
    if MM.ProfessionData and type(MM.ProfessionData.GetAllFutureRecipes) == "function" then
        local ok, future = pcall(MM.ProfessionData.GetAllFutureRecipes)
        if ok and type(future) == "table" then for _, recipe in ipairs(future) do add(recipe) end end
    end
    return recipes
end

local function EvaluateRecipe(recipe, catalogByID)
    local lines, total, complete = {}, 0, recipe.reagentDataAvailable == true
        and type(recipe.reagents) == "table" and #recipe.reagents > 0
    local recipeName = recipe.recipeName or "Craft route"
    for _, slot in ipairs(recipe.reagents or {}) do
        if slot.required ~= false then
            local quantity = tonumber(slot.quantity)
            local best, bestCost, bestReason
            for _, choice in ipairs(slot.choices or {}) do
                local marketItem = catalogByID and catalogByID[tonumber(choice.itemID)] or nil
                local lineCost, reason
                if not quantity or quantity <= 0 then reason = "Reagent quantity is unknown"
                else lineCost, reason = PriceFor(marketItem, quantity) end
                if lineCost and (not bestCost or lineCost < bestCost) then
                    best, bestCost, bestReason = choice, lineCost, nil
                elseif not bestReason then
                    bestReason = reason
                end
            end
            local variable = slot.variable == true
            if variable then bestCost = nil; bestReason = "Variable reagent quantity is not estimated" end
            if not bestCost then complete = false end
            total = total + (bestCost or 0)
            lines[#lines + 1] = {
                itemName = best and best.name or ((slot.choices or {})[1] and (slot.choices or {})[1].name) or "Unknown reagent",
                itemID = best and tonumber(best.itemID) or nil,
                quantity = quantity or 0,
                unitPriceCopper = bestCost and quantity and quantity > 0 and (bestCost / quantity) or nil,
                lineCostCopper = bestCost,
                status = bestCost and "priced" or "unknown",
                reason = bestReason or (not quantity and "Reagent quantity is unknown"
                    or (#(slot.choices or {}) == 0 and "No reagent choices are available" or nil)),
            }
        end
    end
    if recipe.reagentDataAvailable ~= true or type(recipe.reagents) ~= "table" or #recipe.reagents == 0 then
        complete = false
        if #lines == 0 then
            lines[#lines + 1] = { itemName = "Recipe material data", quantity = 1,
                status = "unknown", reason = "ForeverDB recipe data does not include a complete reagent list" }
        end
    end
    return {
        label = "CRAFT · " .. tostring(recipe.professionName or "Profession") .. " · " .. tostring(recipeName),
        kind = "craft", recipeID = tonumber(recipe.recipeID), outputItemID = tonumber(recipe.outputItemID),
        complete = complete, costCopper = complete and total or nil, lines = lines,
        reasons = complete and {} or { "Crafting material data or market depth is incomplete" },
    }
end

local function BuildWritRows(catalog, catalogByID, byName)
    local data = MM.WritData or {}
    local recipeIndex = GetWritRecipes()
    local rows = {}
    for writIndex, writ in ipairs(data.writs or {}) do
        local writMarket = byName[NormalizeName(writ.name)]
        if writMarket == false then writMarket = nil end
        local writCost, writReason = PriceFor(writMarket, 1)
        local alternatives, best = {}, nil
        for _, recipe in ipairs(recipeIndex[NormalizeName(writ.outputName)] or {}) do
            if ProfessionAllowed(writ, recipe.professionName) then
                local route = EvaluateRecipe(recipe, catalogByID)
                route.index = #alternatives + 1
                alternatives[#alternatives + 1] = route
                if route.complete and (not best or route.costCopper < best.costCopper) then best = route end
            end
        end
        -- Buying the requested crafted output is a valid alternative to crafting it.
        local outputMarketByName = byName[NormalizeName(writ.outputName)]
        if outputMarketByName == false then outputMarketByName = nil end
        local outputID = (outputMarketByName and tonumber(outputMarketByName.itemID))
            or (alternatives[1] and alternatives[1].outputItemID)
        if not outputID and MM.ProfessionData and MM.ProfessionData.GetAllFutureRecipes then
            for _, recipe in ipairs(MM.ProfessionData.GetAllFutureRecipes() or {}) do
                if NormalizeName(recipe.recipeName) == NormalizeName(writ.outputName)
                    and ProfessionAllowed(writ, recipe.professionName) then
                    outputID = tonumber(recipe.outputItemID); break
                end
            end
        end
        local outputMarket = (outputID and catalogByID and catalogByID[outputID]) or outputMarketByName
        local buyCost, buyReason = PriceFor(outputMarket, 1)
        if buyCost then
            local buy = { index = #alternatives + 1, label = "BUY · " .. tostring(writ.outputName),
                kind = "buy", complete = true, costCopper = buyCost,
                lines = {{ itemName = writ.outputName, itemID = outputID, quantity = 1,
                    unitPriceCopper = buyCost, lineCostCopper = buyCost, status = "priced" }} }
            alternatives[#alternatives + 1] = buy
            if not best or buyCost < best.costCopper then best = buy end
        elseif outputMarket or outputID then
            alternatives[#alternatives + 1] = { index = #alternatives + 1,
                label = "BUY · " .. tostring(writ.outputName), kind = "buy", complete = false,
                lines = {{ itemName = writ.outputName, itemID = outputID, quantity = 1,
                    status = "unknown", reason = buyReason or "No current buyout" }} }
        end
        local completion = writCost and best and (writCost + best.costCopper) or nil
        local reputation = tonumber(data.rewardByTier and data.rewardByTier[writ.tier])
        local professions = table.concat(writ.professions or {}, ", ")
        local iconID = (writMarket and tonumber(writMarket.itemID)) or outputID
        local stableRowID = iconID or (900000000 + writIndex)
        rows[#rows + 1] = {
            itemID = stableRowID, iconItemID = iconID,
            itemName = writ.name, name = writ.name, outputName = writ.outputName,
            turnIn = true, turnInType = "writ", daily = true,
            tier = writ.tier, category = professions, professions = writ.professions,
            profession = professions, handInNPC = writ.handInNPC, handInZone = writ.handInZone,
            writMarket = writMarket, writPriceCopper = writCost, writPriceReason = writReason,
            outputMarket = outputMarket, outputItemID = outputID,
            bundleAlternatives = alternatives, bestBundle = best,
            bundleCostCopper = best and best.costCopper or nil,
            completionCostCopper = completion,
            cashReturnCopper = nil, cashReturnText = "Variable pouch",
            cashReturnNote = data.cashRewardNotes and data.cashRewardNotes[writ.tier] or "Variable coin pouch",
            rewardFavor = nil, reputation = reputation,
            netCostPerReputationCopper = completion and reputation and reputation > 0
                and (completion / reputation) or nil,
            netCostPerRewardCopper = completion and reputation and reputation > 0
                and (completion / reputation) or nil,
            completionStatus = completion and "complete" or (writCost and "materials-incomplete" or "writ-price-incomplete"),
            rewardStatus = reputation and "reported" or "unknown",
            recipeStatus = #alternatives > 0 and "matched" or "recipe-data-unavailable",
            variants = {},
        }
    end
    return rows
end

function Engine.BuildRows(catalog, catalogByID)
    local data = MM.TurnInData or {}
    -- An empty exact-build price index means the snapshot is incompatible; keep names but fail all prices closed.
    local pricingEnabled = type(catalogByID) == "table" and next(catalogByID) ~= nil
    local byName = pricingEnabled and BuildNameIndex(catalog) or {}
    local rows = {}
    for _, crate in ipairs(data.crates or {}) do
        local crateMarket = catalogByID and catalogByID[tonumber(crate.id)] or nil
        local crateCost, crateReason = PriceFor(crateMarket, 1)
        local alternatives = {}
        local bestBundle
        for index, bundle in ipairs(crate.bundles or {}) do
            local evaluated = EvaluateBundle(bundle, byName)
            evaluated.index = index
            alternatives[#alternatives + 1] = evaluated
            if evaluated.complete and (not bestBundle or evaluated.costCopper < bestBundle.costCopper) then
                bestBundle = evaluated
            end
        end
        local gross = crateCost and bestBundle and (crateCost + bestBundle.costCopper) or nil
        local net = gross and crate.rewardCashCopper ~= nil and (gross - crate.rewardCashCopper) or nil
        local row = {
            itemID = tonumber(crate.id), itemName = crate.name, name = crate.name,
            tier = crate.tier, category = crate.category,
            turnIn = true, turnInType = "crate", cratePriceCopper = crateCost, cratePriceReason = crateReason,
            crateMarket = crateMarket, bundleAlternatives = alternatives, bestBundle = bestBundle,
            bundleCostCopper = bestBundle and bestBundle.costCopper or nil,
            completionCostCopper = gross, cashReturnCopper = crate.rewardCashCopper,
            rewardFavor = crate.rewardFavor, reputation = crate.reputation,
            netCostCopper = net,
            netCostPerFavorCopper = net and tonumber(crate.rewardFavor) and crate.rewardFavor > 0
                and (net / crate.rewardFavor) or nil,
            completionStatus = gross and "complete" or (crateCost and "materials-incomplete" or "crate-price-incomplete"),
            rewardStatus = (crate.rewardFavor ~= nil or crate.reputation ~= nil) and "reported" or "unknown",
            variants = {},
        }
        local seen = {}
        for _, alternative in ipairs(alternatives) do
            for _, line in ipairs(alternative.lines or {}) do
                local key = NormalizeName(line.itemName)
                if not seen[key] then seen[key] = true; row.variants[#row.variants + 1] = { itemName = line.itemName } end
            end
        end
        rows[#rows + 1] = row
    end
    local writRows = BuildWritRows(catalog, catalogByID, byName)
    for _, row in ipairs(writRows) do rows[#rows + 1] = row end
    return rows
end

Engine.EvaluateBundle = EvaluateBundle
Engine.PriceFor = PriceFor
Engine.NormalizeName = NormalizeName
Engine.BuildWritRows = BuildWritRows
Engine.EvaluateRecipe = EvaluateRecipe
