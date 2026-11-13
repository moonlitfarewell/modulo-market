local MM = _G.ModuloMarket
if not MM then return end

local Engine = {}
MM.TurnInEngine = Engine

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

function Engine.BuildRows(catalog, catalogByID)
    local data = MM.TurnInData or {}
    local byName = BuildNameIndex(catalog)
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
            turnIn = true, cratePriceCopper = crateCost, cratePriceReason = crateReason,
            crateMarket = crateMarket, bundleAlternatives = alternatives, bestBundle = bestBundle,
            bundleCostCopper = bestBundle and bestBundle.costCopper or nil,
            completionCostCopper = gross, cashReturnCopper = crate.rewardCashCopper,
            rewardFavor = crate.rewardFavor, reputation = crate.reputation,
            netCostCopper = net,
            netCostPerFavorCopper = net and tonumber(crate.rewardFavor) and crate.rewardFavor > 0
                and (net / crate.rewardFavor) or nil,
            completionStatus = gross and "complete" or (crateCost and "materials-incomplete" or "crate-price-incomplete"),
            rewardStatus = crate.rewardFavor ~= nil and "reported" or "unknown",
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
    return rows
end

Engine.EvaluateBundle = EvaluateBundle
Engine.PriceFor = PriceFor
Engine.NormalizeName = NormalizeName
