local MM = _G.ModuloMarket
if not MM then return end

local UI = {
    frame = nil,
    rows = {},
    visibleRows = {},
    catalog = {},
    catalogByID = {},
    viewRows = {},
    selectedItem = nil,
    selectedByTab = {},
    rowHeight = 24,
    -- 25 virtual rows cover the 555px viewport at 24px/row, including partial rows.
    visibleCount = 25,
    listOffset = 0,
    catalogSnapshot = nil,
    catalogBuild = nil,
    viewBuild = nil,
    rankSort = nil,
    activeTab = "market",
    professionFilter = 0,
    tabFilterState = {},
    craftFilters = { craftableOnly = false, profitableOnly = false, reviewOnly = false, hideLowProfit = false },
    economicsFilters = { crafted = false, gathered = false, material = false, other = false },
    marketQuickFilters = {
        craftingMaterialsOnly = false,
        lowSupplyOnly = false,
        highProfitOnly = false,
        reviewOnly = false,
    },
    economicsByItemID = nil,
    vendorPriceCache = {},
    itemClassCache = {},
    itemClassRequested = {},
    itemClassFailed = {},
    itemClassPendingIDs = {},
    itemClassPendingOrder = {},
    itemClassPendingIndex = 1,
    vendorPriceRequested = {},
    vendorPriceFailed = {},
    historyBars = {},
    itemRoleFilter = "all",
    itemTypeFilter = "all",
    professionOptions = {},
    sortByTab = {
        market = { key = "name", ascending = true },
        economics = { key = "profit", ascending = false },
        crafts = { key = "profit", ascending = false },
        materials = { key = "name", ascending = true },
        low = { key = "name", ascending = true },
        history = { key = "change", ascending = false },
    },
    refreshElapsed = 0,
    lowSupplyThreshold = 5,
    auctionHouseButtons = {},
    craftingScope = "account",
    tooltipSearchCache = {},
    tooltipSearchRequested = {},
    searchBuildDueAt = nil,
    searchGeneration = 0,
    tooltipSearchWarmup = nil,
    tooltipSearchMode = false,
    tooltipSearchDiagnostics = { searches = 0, requests = 0, cacheHits = 0, events = 0, failures = 0, timeouts = 0, completed = 0, structuredReads = 0, legacyFallbacks = 0, emptyResults = 0, lastItemID = nil, lastSource = "none", lastLineCount = 0, lastState = "idle" },
}
MM.MarketUI = UI

local SelectItem

local function Now()
    return type(_G.GetTime) == "function" and _G.GetTime() or 0
end

local function FormatMoney(copper)
    copper = math.floor(tonumber(copper) or 0)
    local sign = ""
    if copper < 0 then sign = "-"; copper = math.abs(copper) end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperPart = copper % 100
    local parts = {}
    if gold > 0 then
        parts[#parts + 1] = string.format("|cffffd700%d|r|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t", gold)
    end
    if silver > 0 or gold > 0 then
        parts[#parts + 1] = string.format("|cffc7c7cf%02d|r|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t", silver)
    end
    if copperPart > 0 or silver > 0 or gold > 0 or (#parts == 0) then
        parts[#parts + 1] = string.format("|cffeda55f%02d|r|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t", copperPart)
    end
    return sign .. table.concat(parts, " ")
end

local function NormalizeSearchText(value)
    value = string.lower(tostring(value or ""))
    value = value:gsub("['’]", "")
    value = value:gsub("[^%w]+", " ")
    return value:match("^%s*(.-)%s*$") or ""
end

local searchTooltip
local function GetTooltipSearchText(itemID)
    itemID = tonumber(itemID)
    if not itemID then return "" end
    local cached = UI.tooltipSearchCache[itemID]
    if cached ~= nil then
        UI.tooltipSearchDiagnostics.cacheHits = UI.tooltipSearchDiagnostics.cacheHits + 1
        return cached or ""
    end

    UI.tooltipSearchScansThisFrame = (UI.tooltipSearchScansThisFrame or 0) + 1
    local api = _G.C_Item
    local isCached = false
    if type(api) == "table" and type(api.IsItemDataCachedByID) == "function" then
        local cacheOK, cacheValue = pcall(api.IsItemDataCachedByID, itemID)
        isCached = cacheOK and cacheValue == true
    end
    local hasCacheAPI = type(api) == "table" and type(api.IsItemDataCachedByID) == "function"
    local loaded = hasCacheAPI and isCached
        or (not hasCacheAPI and type(_G.GetItemInfo) == "function" and _G.GetItemInfo(itemID) ~= nil)
    if not loaded then
        if not UI.tooltipSearchRequested[itemID] and (UI.tooltipSearchRequestsThisFrame or 0) < 10 then
            UI.tooltipSearchRequested[itemID] = true
            UI.tooltipSearchRequestsThisFrame = (UI.tooltipSearchRequestsThisFrame or 0) + 1
            UI.tooltipSearchDiagnostics.requests = UI.tooltipSearchDiagnostics.requests + 1
            if type(api) == "table" and type(api.RequestLoadItemDataByID) == "function" then
                local ok, accepted = pcall(api.RequestLoadItemDataByID, itemID)
                if not ok or accepted == false then
                    UI.tooltipSearchRequested[itemID] = nil
                    UI.tooltipSearchCache[itemID] = false
                    UI.tooltipSearchDiagnostics.failures = UI.tooltipSearchDiagnostics.failures + 1
                    UI.tooltipSearchDiagnostics.lastError = ok and "item-data request rejected" or tostring(accepted)
                end
            else
                UI.tooltipSearchRequested[itemID] = nil
                UI.tooltipSearchCache[itemID] = false
                UI.tooltipSearchDiagnostics.failures = UI.tooltipSearchDiagnostics.failures + 1
                UI.tooltipSearchDiagnostics.lastError = "C_Item.RequestLoadItemDataByID unavailable"
            end
        end
        return nil
    end

    local lines = {}
    local source = "none"
    local structured = _G.C_TooltipInfo
    if type(structured) == "table" and type(structured.GetItemByID) == "function" then
        local ok, data = pcall(structured.GetItemByID, itemID)
        if ok and type(data) == "table" and type(data.lines) == "table" then
            UI.tooltipSearchDiagnostics.structuredReads = UI.tooltipSearchDiagnostics.structuredReads + 1
            source = "C_TooltipInfo.GetItemByID"
            for _, line in ipairs(data.lines) do
                if type(line) == "table" then
                    if type(line.leftText) == "string" and line.leftText ~= "" then
                        lines[#lines + 1] = line.leftText
                    end
                    if type(line.rightText) == "string" and line.rightText ~= "" then
                        lines[#lines + 1] = line.rightText
                    end
                end
            end
        end
    end

    -- Older clients may not expose structured tooltip data. Fall back to a
    -- hidden GameTooltip, but verify that it actually produced lines: pcall()
    -- only tells us the setter did not throw, not that it populated the tooltip.
    if #lines == 0 then
        if not searchTooltip then
            searchTooltip = CreateFrame("GameTooltip", "ModuloMarketSearchTooltip", UIParent, "GameTooltipTemplate")
            searchTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        end
        local function ReadLegacyLines()
            local found = {}
            for i = 1, 40 do
                local left = _G["ModuloMarketSearchTooltipTextLeft" .. i]
                local right = _G["ModuloMarketSearchTooltipTextRight" .. i]
                local a = left and left.GetText and left:GetText()
                local b = right and right.GetText and right:GetText()
                if a and a ~= "" then found[#found + 1] = a end
                if b and b ~= "" then found[#found + 1] = b end
            end
            return found
        end
        searchTooltip:ClearLines()
        local setterOK = false
        if type(searchTooltip.SetItemByID) == "function" then
            setterOK = pcall(searchTooltip.SetItemByID, searchTooltip, itemID)
        end
        lines = ReadLegacyLines()
        if #lines == 0 then
            searchTooltip:ClearLines()
            local link
            if type(_G.GetItemInfo) == "function" then
                local _, itemLink = _G.GetItemInfo(itemID)
                link = itemLink
            end
            if link and type(searchTooltip.SetHyperlink) == "function" then
                pcall(searchTooltip.SetHyperlink, searchTooltip, link)
                lines = ReadLegacyLines()
            end
        end
        searchTooltip:Hide()
        source = "GameTooltip fallback"
        UI.tooltipSearchDiagnostics.legacyFallbacks = UI.tooltipSearchDiagnostics.legacyFallbacks + 1
        if #lines == 0 then
            UI.tooltipSearchDiagnostics.emptyResults = UI.tooltipSearchDiagnostics.emptyResults + 1
            UI.tooltipSearchDiagnostics.lastError = setterOK
                and "GameTooltip setters returned no readable lines"
                or "GameTooltip item tooltip unavailable"
        end
    end

    UI.tooltipSearchDiagnostics.lastItemID = itemID
    UI.tooltipSearchDiagnostics.lastSource = source
    UI.tooltipSearchDiagnostics.lastLineCount = #lines
    local normalized = NormalizeSearchText(table.concat(lines, " "))
    UI.tooltipSearchCache[itemID] = normalized ~= "" and normalized or false
    UI.tooltipSearchRequested[itemID] = nil
    return normalized
end

local function MatchesSearch(item, query, isCrafting, includeTooltip)
    if query == "" then return true end
    if string.match(query, "^%d+$") then
        local numericID = tonumber(query)
        return tonumber(item.itemID) == numericID or tonumber(item.recipeID) == numericID
    end
    local fields = {
        (type(item.itemName) == "string" and item.itemName ~= "" and item.itemName)
            or ("Item " .. tostring(item.itemID or "")),
        item.recipeName,
        item.professionName,
        item.itemID,
        item.recipeID,
    }
    if isCrafting and type(item.reagentLines) == "table" then
        for _, reagent in ipairs(item.reagentLines) do
            fields[#fields + 1] = reagent.itemName
            fields[#fields + 1] = reagent.itemID
        end
    elseif type(item.variants) == "table" then
        for _, variant in ipairs(item.variants) do
            fields[#fields + 1] = variant.itemName
            fields[#fields + 1] = variant.itemID
        end
    end
    local haystack = NormalizeSearchText(table.concat((function()
        local values = {}
        for i = 1, #fields do
            if fields[i] ~= nil then values[#values + 1] = tostring(fields[i]) end
        end
        return values
    end)(), " "))
    local allNameTokensMatch = true
    for token in string.gmatch(query, "%S+") do
        if not string.find(haystack, token, 1, true) then allNameTokensMatch = false; break end
    end
    if not allNameTokensMatch and includeTooltip then
        local tooltipText = GetTooltipSearchText(item.itemID)
        if tooltipText == nil then return nil end -- pending: do not treat unloaded tooltip data as a final no-match
        if tooltipText then haystack = haystack .. " " .. tooltipText end
    end
    for token in string.gmatch(query, "%S+") do
        if not string.find(haystack, token, 1, true) then return false end
    end
    return true
end

local function ParseGold(value)
    if type(value) ~= "string" then return nil end
    local cleaned = value:gsub("[gG]", ""):gsub(",", "."):match("^%s*(.-)%s*$")
    local gold = tonumber(cleaned)
    if not gold or gold < 0 or gold > 100000000 then return nil end
    return math.floor(gold * 10000 + 0.5)
end

local function ParseInteger(value, fallback)
    local number = tonumber(value)
    if not number then return fallback end
    return math.max(1, math.min(100000000, math.floor(number)))
end

local function GetSnapshot()
    local db = MM.db
    if type(db) ~= "table" then return nil end
    local market, browse = db.lastMarketSnapshot, db.lastSnapshot
    if type(market) == "table" and market.complete == true
        and (type(browse) ~= "table" or (tonumber(market.timestamp) or 0) >= (tonumber(browse.timestamp) or 0)) then
        return market
    end
    if type(browse) == "table" and browse.complete == true then return browse end
    if type(market) == "table" and market.complete == true then return market end
    return nil
end

local function GetMarketPrice(itemID)
    if UI.recipeMarketBuildCompatible == false then return nil end
    return UI.catalogByID and UI.catalogByID[tonumber(itemID)] or nil
end

local function GetItemName(item)
    local name = type(item.itemName) == "string" and item.itemName or nil
    if not name or name == "" then return "Item #" .. tostring(item.itemID or "?") end
    return name
end

local function GetItemDisplayName(item)
    local name = GetItemName(item)
    local data = MM.ProfessionData
    local tags = data and data.GetItemTags and data.GetItemTags(item and item.itemID)
    if not tags or #tags == 0 then return name end

    -- Colour is the only row-level status cue. It mirrors the player-facing
    -- filters: learned craft, unlearned craft, gathering resource, reagent.
    -- Keep the internal evidence tags out of item names entirely.
    local has = {}
    for _, tag in ipairs(tags) do has[tag] = true end
    local nameColor = "|cffffffff"
    if has.known then
        nameColor = "|cff8ee6a2"       -- Known by you / known craft output
    elseif has.future then
        nameColor = "|cffffd77a"       -- A profession you have; skill may still be required
    elseif has.unlearnable then
        nameColor = "|cffff6666"       -- Required profession not currently learned
    elseif has.gather then
        nameColor = "|cff82d9ff"       -- Gathering resource
    elseif has.material then
        nameColor = "|cffb6e2ff"       -- Crafting reagent
    end
    return nameColor .. name .. "|r"
end

-- Resolve real client item artwork; never substitute decorative icons for data identities.
local itemIconCache = {}
local function GetItemIcon(itemID)
    itemID = tonumber(itemID)
    if not itemID then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    if itemIconCache[itemID] then return itemIconCache[itemID] end
    local icon
    local api = _G.C_Item
    if type(api) == "table" and type(api.GetItemIconByID) == "function" then
        local ok, value = pcall(api.GetItemIconByID, itemID)
        if ok and value then icon = value end
    end
    if not icon and type(_G.GetItemInfo) == "function" then
        local ok, _, _, _, _, _, _, _, _, texture = pcall(_G.GetItemInfo, itemID)
        if ok and texture then icon = texture end
    end
    if not icon and type(api) == "table" and type(api.RequestLoadItemDataByID) == "function" then
        pcall(api.RequestLoadItemDataByID, itemID)
    end
    if icon then
        itemIconCache[itemID] = icon
        return icon
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function CacheVendorInfo(itemID, sellPrice, classID)
    sellPrice = tonumber(sellPrice)
    if not itemID or sellPrice == nil then return false end
    UI.vendorPriceCache[itemID] = {
        sellPrice = sellPrice,
        classID = tonumber(classID),
    }
    UI.vendorPriceRequested[itemID] = nil
    UI.vendorPriceFailed[itemID] = nil
    return true
end

local function ReadVendorInfo(itemID)
    local api = _G.C_Item
    if type(api) == "table" and type(api.GetItemInfo) == "function" then
        local ok, info = pcall(api.GetItemInfo, itemID)
        if ok and type(info) == "table" then
            local sellPrice = info.sellPrice or info.sellPriceCopper
            local classID = info.classID or info.itemClassID
            if CacheVendorInfo(itemID, sellPrice, classID) then
                return tonumber(sellPrice), tonumber(classID)
            end
        end
    end

    local fn = _G.GetItemInfo
    if type(fn) == "function" then
        local ok, itemName, itemLink, quality, itemLevel, requiredLevel, itemClass,
            itemSubClass, maxStack, equipLocation, texture, sellPrice, classID = pcall(fn, itemID)
        if ok and CacheVendorInfo(itemID, sellPrice, classID) then
            return tonumber(sellPrice), tonumber(classID)
        end
    end
    return nil, nil
end

local function GetVendorInfo(itemID, requestLoad)
    itemID = tonumber(itemID)
    if not itemID then return nil, nil end
    local cached = UI.vendorPriceCache[itemID]
    if cached and cached.sellPrice ~= nil then return cached.sellPrice, cached.classID end
    if UI.vendorPriceFailed[itemID] then return nil, nil end

    local sellPrice, classID = ReadVendorInfo(itemID)
    if sellPrice ~= nil then return sellPrice, classID end

    if requestLoad and not UI.vendorPriceRequested[itemID] then
        UI.vendorPriceRequested[itemID] = true
        local api = _G.C_Item
        if type(api) == "table" and type(api.RequestLoadItemDataByID) == "function" then
            local ok = pcall(api.RequestLoadItemDataByID, itemID)
            if not ok then UI.vendorPriceRequested[itemID] = nil end
        else
            -- Legacy GetItemInfo also initiates an item-cache request on clients
            -- that do not expose C_Item.RequestLoadItemDataByID.
            local fn = _G.GetItemInfo
            if type(fn) == "function" then pcall(fn, itemID) end
        end
    end
    return nil, nil
end

local function GetVendorStatus(itemID, vendorPrice)
    if vendorPrice ~= nil then return FormatMoney(vendorPrice) end
    if UI.vendorPriceRequested[tonumber(itemID)] then return "Loading item data…" end
    if UI.vendorPriceFailed[tonumber(itemID)] then return "Unavailable from client data" end
    return "Waiting for item data"
end

local SetStatus

local function GetAllCraftSources()
    local result, seen = {}, {}
    local known = MM.Recipes and MM.Recipes.GetAllRecipes and MM.Recipes.GetAllRecipes(UI.craftingScope) or {}
    for _, recipe in ipairs(known or {}) do
        local key = tostring(recipe.professionID or "") .. ":" .. tostring(recipe.recipeID or "")
        if not seen[key] then
            seen[key] = true
            recipe.craftSourceStatus = "known"
            result[#result + 1] = recipe
        end
    end
    local future = MM.ProfessionData and MM.ProfessionData.GetAllFutureRecipes
        and MM.ProfessionData.GetAllFutureRecipes() or {}
    for _, sourceRecipe in ipairs(future or {}) do
        local key = tostring(sourceRecipe.professionID or "") .. ":" .. tostring(sourceRecipe.recipeID or "")
        if not seen[key] then
            seen[key] = true
            -- ProfessionData owns these cached candidates. Never write scope-derived
            -- status back onto them: account and character catalogues are rebuilt
            -- repeatedly and must not inherit each other's KNOWN marker.
            local recipe = {}
            for field, value in pairs(sourceRecipe) do recipe[field] = value end
            recipe.craftSourceStatus = MM.ProfessionData and MM.ProfessionData.GetRecipeLearningStatus
                and MM.ProfessionData.GetRecipeLearningStatus(recipe) or "unknown"
            result[#result + 1] = recipe
        end
    end
    return result
end

-- Status is evidence, not a display default. Missing or invalid values must
-- never be promoted to KNOWN by a downstream presentation path.
local function GetCraftSourceStatus(recipe)
    local status = type(recipe) == "table" and recipe.craftSourceStatus or nil
    if status == "known" or status == "learnable"
        or status == "unlearnable" or status == "unknown" then
        return status
    end
    return "unknown"
end

local function HasExplicitReviewForItem(itemID)
    local data = MM.ProfessionData
    local entry = data and data.GetItem and data.GetItem(itemID)
    if not entry then return false end
    for _, key in ipairs({ "knownCrafts", "futureCrafts", "unknownFutureCrafts" }) do
        for _, recipe in ipairs(entry[key] or {}) do
            local freshness = recipe.freshnessStatus
                or (recipe.recipeData and recipe.recipeData.freshnessStatus)
            if freshness == "review" then return true end
        end
    end
    return false
end

local function StartEconomicsIndex()
    if UI.economicsIndexBuild then return end
    local recipes = GetAllCraftSources()
    UI.economicsIndexBuild = {
        recipes = recipes,
        index = 1,
        byID = {},
        total = #recipes,
        cut = tonumber(MM.db and MM.db.auctionHouseCutPercent) or 5,
    }
    if UI.resultCount then UI.resultCount:SetText("Indexing recipe economics…") end
    SetStatus(string.format("Preparing item economics: 0/%d recipes", #recipes))
end

local function StepEconomicsIndex()
    local build = UI.economicsIndexBuild
    if not build then return end
    local stop = math.min(build.total, build.index + 99)
    while build.index <= stop do
        local recipe = build.recipes[build.index]
        local economics
        if not recipe.sourceUnknown and not recipe.borrowedSources then
            economics = MM.Recipes and MM.Recipes.BuildEconomics
                and MM.Recipes.BuildEconomics(recipe, function(itemID)
                    return GetMarketPrice(itemID)
                end, build.cut)
        end
        local itemID = tonumber(recipe.outputItemID or recipe.craftedItemId)
        if economics and itemID then
            economics.recipeKey = tostring(recipe.professionID or "") .. ":" .. tostring(recipe.recipeID or "")
            economics.craftSourceStatus = GetCraftSourceStatus(recipe)
            economics.requiredSkill = recipe.requiredSkill
            economics.borrowedSkill = recipe.borrowedSkill
            economics.borrowedSources = recipe.borrowedSources
            economics.sourceUnknown = recipe.sourceUnknown
            local previous = build.byID[itemID]
            local replace = not previous
            if previous then
                if economics.profitCopper ~= nil then
                    replace = previous.profitCopper == nil
                        or economics.profitCopper > previous.profitCopper
                elseif previous.profitCopper == nil and economics.materialCostCopper ~= nil then
                    replace = previous.materialCostCopper == nil
                        or economics.materialCostCopper < previous.materialCostCopper
                end
            end
            if replace then build.byID[itemID] = economics end
        end
        build.index = build.index + 1
    end
    if build.index <= build.total then
        SetStatus(string.format("Preparing item economics: %d/%d recipes",
            math.min(build.index - 1, build.total), build.total))
        return
    end
    UI.economicsByItemID = build.byID
    UI.economicsIndexBuild = nil
    UI.StartViewBuild()
end

local function GetMaterialCatalog()
    local result, seen = {}, {}
    for _, item in ipairs(UI.catalog or {}) do
        if MM.ProfessionData and MM.ProfessionData.IsMaterial
            and MM.ProfessionData.IsMaterial(item.itemID) then
            result[#result + 1] = item
            seen[tonumber(item.itemID)] = true
        end
    end
    local missing = MM.ProfessionData and MM.ProfessionData.GetMaterialItems
        and MM.ProfessionData.GetMaterialItems() or {}
    for _, entry in ipairs(missing) do
        local id = tonumber(entry.itemID)
        if id and not seen[id] then
            local name = entry.itemName
            if (not name or name == "") and type(_G.GetItemInfo) == "function" then
                local ok, itemName = pcall(_G.GetItemInfo, id)
                if ok and type(itemName) == "string" then name = itemName end
            end
            result[#result + 1] = {
                itemID = id, itemName = name or ("Item #" .. id),
                totalQuantity = 0, auctionCount = 0, variantCount = 0,
                noMarketData = true,
            }
            seen[id] = true
        end
    end
    return result
end

local function GetHistoryDelta(itemID)
    local history = MM.db and MM.db.marketHistory or {}
    local found = {}
    for i = #history, 1, -1 do
        local item = history[i].items and history[i].items[tonumber(itemID)]
        if item and tonumber(item.price) then
            found[#found + 1] = tonumber(item.price)
            if #found >= 2 then break end
        end
    end
    if #found < 2 then return nil end
    return found[1] - found[2]
end

local function GetItemClassID(itemID, requestLoad)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    local cached = UI.itemClassCache[itemID]
    if cached ~= nil then return cached end
    if UI.itemClassFailed[itemID] then return nil end

    local api = _G.C_Item
    if type(api) == "table" and type(api.GetItemInfo) == "function" then
        local ok, info = pcall(api.GetItemInfo, itemID)
        if ok and type(info) == "table" then
            local classID = tonumber(info.classID or info.itemClassID)
            if classID ~= nil then
                UI.itemClassCache[itemID] = classID
                return classID
            end
        end
    end

    local fn = _G.GetItemInfo
    if type(fn) == "function" then
        local ok, itemName, itemLink, quality, itemLevel, requiredLevel, itemClass,
            itemSubClass, maxStack, equipLocation, texture, sellPrice, classID = pcall(fn, itemID)
        classID = ok and tonumber(classID) or nil
        if classID ~= nil then
            UI.itemClassCache[itemID] = classID
            return classID
        end
    end

    if requestLoad and not UI.itemClassRequested[itemID]
        and not UI.itemClassPendingIDs[itemID] then
        UI.itemClassPendingIDs[itemID] = true
        UI.itemClassPendingOrder[#UI.itemClassPendingOrder + 1] = itemID
    end
    return nil
end

local function StepItemClassWarmup()
    if UI.activeTab ~= "market" or not UI.itemTypeFilter or UI.itemTypeFilter == "all" then return end
    local order = UI.itemClassPendingOrder or {}
    local index = tonumber(UI.itemClassPendingIndex) or 1
    local attempted = 0
    while attempted < 10 and index <= #order do
        local itemID = tonumber(order[index])
        attempted = attempted + 1
        index = index + 1
        if itemID then
            UI.itemClassPendingIDs[itemID] = nil
            if not UI.itemClassCache[itemID] and not UI.itemClassFailed[itemID]
                and not UI.itemClassRequested[itemID] then
                local api = _G.C_Item
                local requestOK = false
                if type(api) == "table" and type(api.RequestLoadItemDataByID) == "function" then
                    local ok, accepted = pcall(api.RequestLoadItemDataByID, itemID)
                    requestOK = ok and accepted ~= false
                elseif type(_G.GetItemInfo) == "function" then
                    requestOK = pcall(_G.GetItemInfo, itemID)
                end
                if requestOK then
                    UI.itemClassRequested[itemID] = true
                else
                    UI.itemClassFailed[itemID] = true
                end
            end
        end
    end
    if index > #order then
        UI.itemClassPendingOrder = {}
        UI.itemClassPendingIndex = 1
    else
        UI.itemClassPendingIndex = index
    end
end

local function MatchesItemType(itemID, filter)
    if not filter or filter == "all" then return true end
    local classID = GetItemClassID(itemID, true)
    if not classID then return false end
    if filter == "consumables" then return classID == 0 end
    if filter == "equipment" then return classID == 2 or classID == 4 end
    if filter == "tradeGoods" then return classID == 7 end
    if filter == "other" then
        return classID ~= 0 and classID ~= 2 and classID ~= 4 and classID ~= 7
    end
    return false
end

local function GetLowSupplyThreshold(item)
    local base = tonumber(MM.db and MM.db.lowSupplyThreshold) or UI.lowSupplyThreshold
    local data = MM.ProfessionData
    local isMaterial = data and data.IsMaterial and data.IsMaterial(item.itemID)
    local isGatherable = data and data.IsGatherable and data.IsGatherable(item.itemID)
    local _, classID = GetVendorInfo(item.itemID, false)
    if isMaterial or isGatherable or classID == 0 or classID == 7 then
        return base * 5
    elseif classID == 2 or classID == 4 then
        return base
    end
    return base * 2
end

local function RefreshProfessionOptions()
    local options = { { text = "All professions", value = 0 } }
    local data = MM.ProfessionData
    local list = data and data.GetProfessions and data.GetProfessions() or {}
    for _, profession in ipairs(list) do
        options[#options + 1] = {
            text = tostring(profession.name or ("Profession " .. tostring(profession.id))),
            value = tonumber(profession.id),
        }
    end
    UI.professionOptions = options
    return options
end

local function RaiseMarketTooltip(owner, title, body)
    if not _G.GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if type(GameTooltip.SetFrameStrata) == "function" then GameTooltip:SetFrameStrata("TOOLTIP") end
    if type(GameTooltip.SetFrameLevel) == "function" then
        local ownerLevel = owner and type(owner.GetFrameLevel) == "function" and owner:GetFrameLevel() or 1
        local tooltipLevel = type(GameTooltip.GetFrameLevel) == "function" and GameTooltip:GetFrameLevel() or 1
        GameTooltip:SetFrameLevel(math.max(tooltipLevel, ownerLevel + 100))
    end
    if type(GameTooltip.ClearLines) == "function" then GameTooltip:ClearLines() end
    GameTooltip:SetText(title or "")
    if body and body ~= "" then GameTooltip:AddLine(body, 1, 1, 1, true) end
    GameTooltip:Show()
end

local function AddBevelBorder(parent, x, top, width, height, style, layer)
    x, top = tonumber(x) or 0, tonumber(top) or 0
    width, height = math.max(4, tonumber(width) or 4), math.max(4, tonumber(height) or 4)
    style = style or "panel"
    layer = layer or "BORDER"
    local palettes = {
        outer = { dark = {0.012, 0.009, 0.006, 0.98}, gold = {0.70, 0.52, 0.22, 0.95}, shade = {0.16, 0.105, 0.035, 0.98}, bright = {0.90, 0.72, 0.36, 0.90}, thick = 3 },
        plaque = { dark = {0.012, 0.009, 0.006, 1}, gold = {0.82, 0.64, 0.27, 1}, shade = {0.20, 0.13, 0.045, 1}, bright = {0.98, 0.80, 0.40, 1}, thick = 2 },
        panel = { dark = {0.012, 0.010, 0.008, 0.96}, gold = {0.55, 0.40, 0.17, 0.88}, shade = {0.20, 0.14, 0.065, 0.95}, bright = {0.78, 0.60, 0.29, 0.72}, thick = 2 },
        card = { dark = {0.008, 0.007, 0.006, 0.98}, gold = {0.65, 0.48, 0.20, 0.95}, shade = {0.22, 0.15, 0.06, 0.96}, bright = {0.86, 0.68, 0.33, 0.88}, thick = 2 },
        tab = { dark = {0.008, 0.007, 0.005, 0.95}, gold = {0.50, 0.36, 0.14, 0.90}, shade = {0.15, 0.105, 0.045, 0.95}, bright = {0.72, 0.55, 0.24, 0.82}, thick = 1 },
        control = { dark = {0.008, 0.006, 0.004, 0.98}, gold = {0.58, 0.42, 0.17, 0.95}, shade = {0.18, 0.12, 0.045, 0.98}, bright = {0.78, 0.60, 0.28, 0.82}, thick = 1 },
        button = { dark = {0.008, 0.006, 0.004, 1}, gold = {0.72, 0.52, 0.19, 1}, shade = {0.24, 0.12, 0.035, 1}, bright = {0.92, 0.70, 0.28, 0.95}, thick = 2 },
    }
    local c = palettes[style] or palettes.panel
    local t = c.thick
    local function edge(name, color, px, py, w, h)
        local texture = parent:CreateTexture(nil, layer)
        texture:SetColorTexture(color[1], color[2], color[3], color[4])
        texture:SetPoint("TOPLEFT", parent, "TOPLEFT", px, py)
        texture:SetSize(math.max(1, w), math.max(1, h))
        return texture
    end
    local result = {}
    result.topShadow = edge("topShadow", c.dark, x, top, width, t)
    result.bottomShadow = edge("bottomShadow", c.dark, x, top - height + t, width, t)
    result.leftShadow = edge("leftShadow", c.dark, x, top, t, height)
    result.rightShadow = edge("rightShadow", c.dark, x + width - t, top, t, height)
    result.topGold = edge("topGold", c.gold, x + t, top - t, width - (t * 2), 1)
    result.leftGold = edge("leftGold", c.bright, x + t, top - t, 1, height - (t * 2))
    result.bottomShade = edge("bottomShade", c.shade, x + t, top - height + t, width - (t * 2), 1)
    result.rightShade = edge("rightShade", c.shade, x + width - t - 1, top - t, 1, height - (t * 2))
    if style == "plaque" or style == "outer" then
        result.cornerTL = edge("cornerTL", c.bright, x + t, top - t, 3, 3)
        result.cornerTR = edge("cornerTR", c.bright, x + width - t - 3, top - t, 3, 3)
        result.cornerBL = edge("cornerBL", c.shade, x + t, top - height + t, 3, 3)
        result.cornerBR = edge("cornerBR", c.shade, x + width - t - 3, top - height + t, 3, 3)
    end
    return result
end

local function ApplyMarketButtonSkin(button, style)
    if not button or button.marketSkinApplied then return end
    button.marketSkinApplied = true
    local w = type(button.GetWidth) == "function" and button:GetWidth() or 100
    local h = type(button.GetHeight) == "function" and button:GetHeight() or 24
    button.marketFill = button:CreateTexture(nil, "BACKGROUND")
    button.marketFill:SetAllPoints(button)
    if style == "control" then
        button.marketFill:SetColorTexture(0.025, 0.022, 0.017, 0.98)
    elseif style == "option" then
        button.marketFill:SetColorTexture(0.055, 0.043, 0.026, 0.98)
    else
        button.marketFill:SetColorTexture(0.16, 0.025, 0.014, 0.98)
    end
    local normal = type(button.GetNormalTexture) == "function" and button:GetNormalTexture() or nil
    local pushed = type(button.GetPushedTexture) == "function" and button:GetPushedTexture() or nil
    local highlight = type(button.GetHighlightTexture) == "function" and button:GetHighlightTexture() or nil
    local disabled = type(button.GetDisabledTexture) == "function" and button:GetDisabledTexture() or nil
    -- The legacy UIPanelButtonTemplate artwork is red on the Forever client.
    -- For custom dark controls it must not bleed through the hand-drawn market
    -- fill/border; retain the template only for click/disabled behavior.
    local templateAlpha = style == "control" and 0 or 0.12
    if normal and normal.SetAlpha then normal:SetAlpha(templateAlpha) end
    if pushed and pushed.SetAlpha then pushed:SetAlpha(style == "control" and 0 or 0.16) end
    if highlight and highlight.SetAlpha then highlight:SetAlpha(style == "control" and 0 or 0.10) end
    if disabled and disabled.SetAlpha then disabled:SetAlpha(0) end
    button.marketHighlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.marketHighlight:SetAllPoints(button)
    button.marketHighlight:SetColorTexture(0.90, 0.67, 0.25, 0.14)
    button.marketBorder = AddBevelBorder(button, 0, 0, w, h,
        style == "control" and "control" or "button", "OVERLAY")
    local text = type(button.GetFontString) == "function" and button:GetFontString() or nil
    if text and type(text.GetFont) == "function" and type(text.SetFont) == "function" then
        local ok, fontPath, fontSize, flags = pcall(text.GetFont, text)
        if ok and fontPath and tonumber(fontSize) then
            pcall(text.SetFont, text, fontPath, tonumber(fontSize) + 1, flags)
        end
        if text.SetTextColor then text:SetTextColor(1, 0.88, 0.62) end
    end
end

local function AddInsetSurface(parent, x, top, width, height, color)
    local surface = parent:CreateTexture(nil, "BACKGROUND")
    surface:SetColorTexture(color[1], color[2], color[3], color[4])
    surface:SetPoint("TOPLEFT", parent, "TOPLEFT", x, top)
    surface:SetSize(width, height)
    return surface
end

UI.dropdowns = UI.dropdowns or {}

function UI.CloseDropdownMenus()
    for _, dropdown in ipairs(UI.dropdowns or {}) do
        if dropdown and dropdown.CloseMenu then dropdown:CloseMenu() end
    end
end

local function CreateDropdown(parent, width, x, y, getOptions, getValue, onChanged)
    -- Use an explicit button + popup rather than UIDropDownMenuTemplate.
    -- The stock dropdown menu has been visible but inert on the target Forever
    -- client; this keeps the interaction path local and directly testable.
    local dropdown = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    dropdown:SetSize(width, 24)
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    dropdown:EnableMouse(true)
    ApplyMarketButtonSkin(dropdown, "control")

    dropdown.label = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dropdown.label:SetPoint("LEFT", dropdown, "LEFT", 8, 0)
    dropdown.label:SetPoint("RIGHT", dropdown, "RIGHT", -24, 0)
    dropdown.label:SetJustifyH("LEFT")
    dropdown.label:SetWordWrap(false)
    dropdown.label:SetTextColor(0.96, 0.91, 0.78)

    dropdown.arrow = dropdown:CreateTexture(nil, "OVERLAY")
    dropdown.arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    dropdown.arrow:SetTexCoord(0.2, 0.8, 0.2, 0.8)
    dropdown.arrow:SetVertexColor(0.95, 0.72, 0.28)
    dropdown.arrow:SetSize(14, 14)
    dropdown.arrow:SetPoint("RIGHT", dropdown, "RIGHT", -5, 0)

    local popup = CreateFrame("Frame", nil, UIParent)
    dropdown.menu = popup
    dropdown.optionButtons = {}
    popup:SetFrameStrata("TOOLTIP")
    popup:SetToplevel(true)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup.background = popup:CreateTexture(nil, "BACKGROUND")
    popup.background:SetAllPoints(popup)
    popup.background:SetColorTexture(0.025, 0.022, 0.018, 0.98)
    popup.borderTop = popup:CreateTexture(nil, "BORDER")
    popup.borderTop:SetColorTexture(0.62, 0.46, 0.18, 0.95)
    popup.borderTop:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, 0)
    popup.borderTop:SetPoint("TOPRIGHT", popup, "TOPRIGHT", 0, 0)
    popup.borderTop:SetHeight(1)
    popup.borderBottom = popup:CreateTexture(nil, "BORDER")
    popup.borderBottom:SetColorTexture(0.62, 0.46, 0.18, 0.95)
    popup.borderBottom:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 0, 0)
    popup.borderBottom:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", 0, 0)
    popup.borderBottom:SetHeight(1)
    popup.borderLeft = popup:CreateTexture(nil, "BORDER")
    popup.borderLeft:SetColorTexture(0.62, 0.46, 0.18, 0.95)
    popup.borderLeft:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, 0)
    popup.borderLeft:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 0, 0)
    popup.borderLeft:SetWidth(1)
    popup.borderRight = popup:CreateTexture(nil, "BORDER")
    popup.borderRight:SetColorTexture(0.62, 0.46, 0.18, 0.95)
    popup.borderRight:SetPoint("TOPRIGHT", popup, "TOPRIGHT", 0, 0)
    popup.borderRight:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", 0, 0)
    popup.borderRight:SetWidth(1)
    popup:Hide()

    local function updateText()
        local value = getValue()
        local options = getOptions() or {}
        for _, option in ipairs(options) do
            if option.value == value then
                dropdown.label:SetText(option.text)
                return
            end
        end
        dropdown.label:SetText(options[1] and options[1].text or "Select")
    end

    local function closeMenu()
        popup:Hide()
        if _G.GameTooltip then GameTooltip:Hide() end
    end

    local function openMenu()
        -- The dropdown's own help tooltip must not remain floating over its
        -- option list after the click transfers interaction to the popup.
        if _G.GameTooltip then GameTooltip:Hide() end
        local options = getOptions() or {}
        local rowHeight = 21
        local popupHeight = math.max(rowHeight + 8, (#options * rowHeight) + 8)
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
        popup:SetSize(width, popupHeight)
        popup:SetFrameLevel(math.min(10000, (parent:GetFrameLevel() or 1) + 30))

        for i, option in ipairs(options) do
            local optionButton = dropdown.optionButtons[i]
            if not optionButton then
                optionButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
                dropdown.optionButtons[i] = optionButton
            end
            optionButton:ClearAllPoints()
            optionButton:SetSize(width - 8, 19)
            ApplyMarketButtonSkin(optionButton, "option")
            optionButton:SetPoint("TOPLEFT", popup, "TOPLEFT", 4, -4 - ((i - 1) * rowHeight))
            optionButton:SetText(option.text or tostring(option.value))
            optionButton:Enable()
            if option.disabled then optionButton:Disable() end
            local selectedValue = option.value
            local selectedDisabled = option.disabled == true
            optionButton:SetScript("OnClick", function()
                if selectedDisabled then return end
                onChanged(selectedValue)
                updateText()
                closeMenu()
            end)
            if option.tooltipText and type(GameTooltip) == "table" then
                optionButton:SetScript("OnEnter", function(self)
                    RaiseMarketTooltip(self, option.tooltipTitle or option.text, option.tooltipText)
                end)
                optionButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
            else
                optionButton:SetScript("OnEnter", nil)
                optionButton:SetScript("OnLeave", nil)
            end
            optionButton:Show()
        end
        for i = #options + 1, #dropdown.optionButtons do
            dropdown.optionButtons[i]:Hide()
        end
        popup:Show()
    end

    dropdown.ToggleMenu = function()
        if popup:IsShown() then closeMenu() else openMenu() end
    end
    dropdown.CloseMenu = closeMenu
    dropdown.menu = popup
    dropdown:SetScript("OnClick", dropdown.ToggleMenu)
    dropdown:SetScript("OnHide", closeMenu)
    UI.dropdowns[#UI.dropdowns + 1] = dropdown
    dropdown.RefreshText = updateText
    dropdown.SetEnabled = function(self, enabled)
        if enabled then
            self:Enable()
        else
            self:Disable()
            closeMenu()
        end
    end
    updateText()
    return dropdown
end
local function IncreaseFontSize(fontString, delta)
    if not fontString or type(fontString.GetFont) ~= "function"
        or type(fontString.SetFont) ~= "function" then return false end
    local ok, fontPath, fontSize, flags = pcall(fontString.GetFont, fontString)
    if not ok or not fontPath or not tonumber(fontSize) then return false end
    local setOK = pcall(fontString.SetFont, fontString, fontPath,
        tonumber(fontSize) + (tonumber(delta) or 1), flags)
    return setOK == true
end

local function AddLabel(parent, text, x, y, width, height, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width or 300)
    if height then label:SetHeight(height) end
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(text or "")
    return label
end

local function SetDetailEconomics(text)
    if not UI.detailEconomics then return end
    UI.detailEconomics:SetText(text or "")
    local contentHeight = 1
    if type(UI.detailEconomics.GetStringHeight) == "function" then
        local ok, measured = pcall(UI.detailEconomics.GetStringHeight, UI.detailEconomics)
        if ok then contentHeight = math.max(1, tonumber(measured) or 1) end
    end
    contentHeight = contentHeight + 8
    if UI.detailEconomics.SetHeight then UI.detailEconomics:SetHeight(contentHeight) end
    if UI.detailScrollChild and UI.detailScroll then
        UI.detailScrollChild:SetHeight(math.max(UI.detailScroll:GetHeight(), contentHeight))
        if UI.detailScroll.SetVerticalScroll then UI.detailScroll:SetVerticalScroll(0) end
    end
end

local function CreateInput(parent, labelText, x, y, width, defaultValue)
    AddLabel(parent, labelText, x, y + 2, width, 18, "GameFontNormalSmall")
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetSize(width, 24)
    input:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 18)
    input:SetAutoFocus(false)
    input:SetText(defaultValue or "")
    input:SetMaxLetters(18)
    return input
end

local function AddButton(parent, text, width, x, y, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    ApplyMarketButtonSkin(button, "button")
    return button
end

SetStatus = function(text)
    if not UI.status then return end
    local fullText = tostring(text or "")
    UI.statusMessage = fullText
    local displayText = fullText
    if #displayText > 210 then displayText = displayText:sub(1, 207) .. "..." end
    UI.status:SetText(displayText)
end

local function NewAggregate(row)
    return {
        itemID = tonumber(row.itemID),
        itemName = type(row.itemName) == "string" and row.itemName or nil,
        minPriceCopper = tonumber(row.minPriceCopper) and tonumber(row.minPriceCopper) > 0
            and tonumber(row.minPriceCopper) or nil,
        minPriceQuantity = tonumber(row.minPriceQuantity),
        depthKnown = tonumber(row.minPriceQuantity) ~= nil,
        totalQuantity = tonumber(row.totalQuantity) or 0,
        auctionCount = tonumber(row.auctionCount) or 0,
        auctionCountKnown = tonumber(row.auctionCount) ~= nil,
        pricedQuantity = tonumber(row.pricedQuantity)
            or ((tonumber(row.minPriceCopper) or 0) > 0 and (tonumber(row.totalQuantity) or 0) or 0),
        unpricedQuantity = tonumber(row.unpricedQuantity)
            or ((tonumber(row.minPriceCopper) or 0) <= 0 and (tonumber(row.totalQuantity) or 0) or 0),
        variantCount = 1,
        bestVariant = row,
        variants = { row },
    }
end

local function AddVariant(aggregate, row)
    aggregate.variants[#aggregate.variants + 1] = row
    aggregate.variantCount = aggregate.variantCount + 1
    aggregate.totalQuantity = aggregate.totalQuantity + (tonumber(row.totalQuantity) or 0)
    aggregate.auctionCount = aggregate.auctionCount + (tonumber(row.auctionCount) or 0)
    if tonumber(row.auctionCount) == nil then aggregate.auctionCountKnown = false end
    aggregate.pricedQuantity = aggregate.pricedQuantity + (tonumber(row.pricedQuantity)
        or ((tonumber(row.minPriceCopper) or 0) > 0 and (tonumber(row.totalQuantity) or 0) or 0))
    aggregate.unpricedQuantity = aggregate.unpricedQuantity + (tonumber(row.unpricedQuantity) or 0)

    local price = tonumber(row.minPriceCopper)
    if price and price > 0 then
        local depth = tonumber(row.minPriceQuantity)
        if not aggregate.minPriceCopper or price < aggregate.minPriceCopper then
            aggregate.minPriceCopper = price
            aggregate.minPriceQuantity = depth
            aggregate.depthKnown = depth ~= nil
            aggregate.bestVariant = row
        elseif price == aggregate.minPriceCopper then
            if depth then
                aggregate.minPriceQuantity = (tonumber(aggregate.minPriceQuantity) or 0) + depth
            else
                aggregate.depthKnown = false
                aggregate.minPriceQuantity = nil
            end
        end
    end
    if (not aggregate.itemName or aggregate.itemName == "") and row.itemName then
        aggregate.itemName = row.itemName
    end
end

local function StartCatalog(snapshot)
    UI.catalogSnapshot = snapshot
    UI.recipeMarketBuildCompatible = true
    UI.recipeMarketSnapshotBuild = nil
    UI.recipeMarketCurrentBuild = nil
    if MM.ProfessionData and type(MM.ProfessionData.IsMarketSnapshotCompatible) == "function" then
        local compatible, snapshotBuild = MM.ProfessionData.IsMarketSnapshotCompatible(snapshot)
        UI.recipeMarketBuildCompatible = compatible == true
        UI.recipeMarketSnapshotBuild = snapshotBuild
        local provider = MM.ProfessionData.GetFutureProviderStatus
            and MM.ProfessionData.GetFutureProviderStatus() or nil
        UI.recipeMarketCurrentBuild = provider and provider.currentBuild or nil
    end
    UI.economicsByItemID = nil
    UI.economicsIndexBuild = nil
    UI.catalog = {}
    UI.catalogByID = {}
    UI.catalogBuild = {
        rows = snapshot and snapshot.rows or {},
        index = 1,
        byID = {},
        ordered = {},
        total = snapshot and #(snapshot.rows or {}) or 0,
        startedAt = Now(),
    }
    UI.viewRows = {}
    UI.viewBuild = nil
    UI.rankSort = nil
    UI.selectedItem = nil
    if UI.detailName then
        UI.detailName:SetText("Select an item")
        UI.detailPrice:SetText("—")
        UI.detailSupply:SetText("—")
        UI.detailVariants:SetText("")
    end
    SetStatus(string.format("Preparing market index: 0/%d", UI.catalogBuild.total))
end

local function StepCatalog()
    local build = UI.catalogBuild
    if not build then return end
    local stop = math.min(build.total, build.index + 249)
    while build.index <= stop do
        local row = build.rows[build.index]
        if type(row) == "table" and tonumber(row.itemID) then
            local id = tonumber(row.itemID)
            local aggregate = build.byID[id]
            if not aggregate then
                aggregate = NewAggregate(row)
                build.byID[id] = aggregate
                build.ordered[#build.ordered + 1] = id
            else
                AddVariant(aggregate, row)
            end
        end
        build.index = build.index + 1
    end
    if build.index <= build.total then
        SetStatus(string.format("Preparing market index: %d/%d", math.min(build.index - 1, build.total), build.total))
        return
    end
    for i = 1, #build.ordered do
        UI.catalog[i] = build.byID[build.ordered[i]]
    end
    UI.catalogByID = build.byID
    local duration = math.max(0, Now() - (build.startedAt or Now()))
    UI.lastIndexDuration = duration
    UI.lastIndexRows = build.total
    UI.catalogBuild = nil
    SetStatus(string.format("%d items ready · indexed %d rows in %.2fs.",
        #UI.catalog, build.total, duration))
    UI.StartViewBuild()
end

function UI.StartViewBuild()
    if not UI.search or UI.catalogBuild then return end
    UI.searchBuildDueAt = nil
    UI.tooltipSearchWarmup = nil
    local query = NormalizeSearchText(UI.search:GetText() or "")
    UI.listOffset = 0
    UI.viewRows = {}
    UI.rankSort = nil
    local isCrafting = UI.activeTab == "crafts"
    local source
    if UI.activeTab == "crafts" then
        source = GetAllCraftSources()
    elseif UI.activeTab == "materials" then
        source = GetMaterialCatalog()
    else
        source = UI.catalog
    end
    if (UI.activeTab == "economics"
        or (UI.activeTab == "market" and UI.marketQuickFilters.highProfitOnly))
        and not UI.economicsByItemID then
        StartEconomicsIndex()
        return
    end
    UI.viewBuild = {
        generation = UI.searchGeneration,
        index = 1, query = query, rows = {}, tab = UI.activeTab,
        professionFilter = UI.professionFilter,
        itemRoleFilter = UI.itemRoleFilter,
        itemTypeFilter = UI.itemTypeFilter,
        economicsFilters = {
            crafted = UI.economicsFilters.crafted,
            gathered = UI.economicsFilters.gathered,
            material = UI.economicsFilters.material,
            other = UI.economicsFilters.other,
        },
        craftFilters = {
            craftableOnly = UI.craftFilters.craftableOnly,
            profitableOnly = UI.craftFilters.profitableOnly,
            reviewOnly = UI.craftFilters.reviewOnly,
            hideLowProfit = UI.craftFilters.hideLowProfit,
        },
        marketQuickFilters = {
            craftingMaterialsOnly = UI.marketQuickFilters.craftingMaterialsOnly,
            lowSupplyOnly = UI.marketQuickFilters.lowSupplyOnly,
            highProfitOnly = UI.marketQuickFilters.highProfitOnly,
            reviewOnly = UI.marketQuickFilters.reviewOnly,
        },
        source = source or {}, total = #(source or {}), startedAt = Now(), pendingTooltipIDs = {},
        includeTooltip = UI.tooltipSearchMode == true,
    }
    if UI.scroll then
        UI.scroll:SetVerticalScroll(0)
        UI.scrollChild:SetHeight(1)
    end
    if UI.resultCount then UI.resultCount:SetText("Filtering…") end
end

-- Text entry is intentionally debounced. Tooltip lookup is relatively expensive
-- on the target client, so rebuilding the full catalogue for every typed character
-- creates unnecessary work and can starve the visible UI.
local SEARCH_DEBOUNCE_SECONDS = 0.35
local function ScheduleSearchBuild()
    UI.searchGeneration = (UI.searchGeneration or 0) + 1
    UI.viewBuild = nil
    UI.rankSort = nil
    UI.tooltipSearchWarmup = nil
    UI.tooltipSearchMode = false
    UI.searchBuildDueAt = Now() + SEARCH_DEBOUNCE_SECONDS
    if UI.resultCount then UI.resultCount:SetText("Waiting…") end
end

local function StepView()
    local build = UI.viewBuild
    if not build then return end
    if build.generation ~= UI.searchGeneration then UI.viewBuild = nil; return end
    local source = build.source or {}
    local stop = math.min(build.total, build.index + 249)
    UI.tooltipSearchRequestsThisFrame = 0
    UI.tooltipSearchScansThisFrame = 0
    local cut = tonumber(MM.db and MM.db.auctionHouseCutPercent) or 5
    while build.index <= stop and (UI.tooltipSearchScansThisFrame or 0) < 30 do
        local sourceItem = source[build.index]
        local item = sourceItem
        local isCrafting = build.tab == "crafts"
        if isCrafting and MM.Recipes then
            item = MM.Recipes.BuildEconomics(sourceItem, function(itemID)
                return GetMarketPrice(itemID)
            end, cut)
            if item then
                item.recipeKey = tostring(sourceItem.professionID or "") .. ":" .. tostring(sourceItem.recipeID or "")
                item.recipeName = sourceItem.recipeName
                item.itemName = item.itemName or sourceItem.recipeName
                item.craftSourceStatus = GetCraftSourceStatus(sourceItem)
                item.requiredSkill = sourceItem.requiredSkill
                item.currentProfessionSkill = sourceItem.currentProfessionSkill
                item.canLearnNow = sourceItem.canLearnNow
                item.learningStatus = sourceItem.learningStatus
                item.borrowedSkill = sourceItem.borrowedSkill
                item.borrowedSources = sourceItem.borrowedSources
                item.sourceUnknown = sourceItem.sourceUnknown
                item.skillThresholds = sourceItem.skillThresholds
                local providerDetails = MM.ProfessionData and MM.ProfessionData.GetForeverRecipeDetails
                    and MM.ProfessionData.GetForeverRecipeDetails(sourceItem.professionID, sourceItem.recipeID)
                if providerDetails then
                    item.acquisitionSources = providerDetails.acquisitionSources
                    item.recipeData.acquisitionSources = providerDetails.acquisitionSources
                    item.recipeData.trainerCostCopper = providerDetails.trainerCostCopper
                    item.recipeData.trainerCostEvidence = providerDetails.trainerCostEvidence
                    item.professionSkill = providerDetails.learnAtSkill or item.professionSkill
                    item.recipeData.professionSkill = providerDetails.learnAtSkill or item.recipeData.professionSkill
                    item.trainerCostCopper = providerDetails.trainerCostCopper
                else
                    item.acquisitionSources = sourceItem.acquisitionSources
                end
            end
        elseif build.tab == "economics" and type(item) == "table" then
            item.economics = UI.economicsByItemID and UI.economicsByItemID[tonumber(item.itemID)]
            item.historyDeltaCopper = GetHistoryDelta(item.itemID)
        elseif build.tab == "history" and type(item) == "table" then
            item.historyDeltaCopper = GetHistoryDelta(item.itemID)
        end
        if type(item) == "table" then
            local matches = MatchesSearch(item, build.query, isCrafting, build.includeTooltip)
            if matches == nil and tonumber(item.itemID) then
                build.pendingTooltipIDs[tonumber(item.itemID)] = true
            end
            if matches and build.professionFilter and build.professionFilter ~= 0 then
                if isCrafting then
                    matches = tonumber(item.professionID) == tonumber(build.professionFilter)
                else
                    matches = MM.ProfessionData and MM.ProfessionData.Matches(item.itemID,
                        build.professionFilter, "all") or false
                end
            end
            if matches and isCrafting and build.itemRoleFilter ~= "all" then
                local status = GetCraftSourceStatus(item)
                if build.itemRoleFilter == "known" or build.itemRoleFilter == "learnable"
                    or build.itemRoleFilter == "unlearnable" then
                    matches = status == build.itemRoleFilter
                end
            elseif matches and not isCrafting and build.itemRoleFilter ~= "all" then
                matches = MM.ProfessionData and MM.ProfessionData.Matches(item.itemID, 0,
                    build.itemRoleFilter) or false
            end
            if matches and build.tab == "market" and build.itemTypeFilter ~= "all" then
                matches = MatchesItemType(item.itemID, build.itemTypeFilter)
            end
            if matches and build.tab == "market" then
                local filters = build.marketQuickFilters or {}
                if filters.craftingMaterialsOnly then
                    matches = MM.ProfessionData and MM.ProfessionData.IsMaterial
                        and MM.ProfessionData.IsMaterial(item.itemID) or false
                end
                if matches and filters.lowSupplyOnly then
                    matches = (tonumber(item.totalQuantity) or 0) <= GetLowSupplyThreshold(item)
                end
                if matches and filters.highProfitOnly then
                    local best = UI.economicsByItemID and UI.economicsByItemID[tonumber(item.itemID)]
                    matches = best ~= nil and tonumber(best.profitCopper) ~= nil
                        and tonumber(best.profitCopper) > 0
                end
                if matches and filters.reviewOnly then
                    matches = HasExplicitReviewForItem(item.itemID)
                end
            end
            if matches and build.tab == "economics" then
                local filters = build.economicsFilters or {}
                local any = filters.crafted or filters.gathered or filters.material or filters.other
                if any then
                    local data = MM.ProfessionData
                    local crafted = data and (data.Matches(item.itemID, 0, "known")
                        or data.Matches(item.itemID, 0, "learnable")
                        or data.Matches(item.itemID, 0, "unlearnable")) or false
                    local gathered = data and data.Matches(item.itemID, 0, "gather") or false
                    local material = data and data.Matches(item.itemID, 0, "material") or false
                    local other = not crafted and not gathered and not material
                    matches = (filters.crafted and crafted) or (filters.gathered and gathered)
                        or (filters.material and material) or (filters.other and other)
                end
            end
            if matches and build.tab == "materials" then
                matches = MM.ProfessionData and MM.ProfessionData.IsMaterial
                    and MM.ProfessionData.IsMaterial(item.itemID) or false
            end
            if matches and isCrafting then
                local filters = build.craftFilters or {}
                local status = GetCraftSourceStatus(item)
                local freshness = item.freshnessStatus
                    or (item.recipeData and item.recipeData.freshnessStatus)
                local hasOutput = tonumber(item.itemID) ~= nil and (tonumber(item.outputQuantity) or 0) > 0
                local completeCost = item.costComplete == true and tonumber(item.materialCostCopper) ~= nil
                local profit = tonumber(item.profitCopper)
                if filters.craftableOnly then
                    matches = status == "known" and hasOutput and completeCost
                end
                if matches and filters.profitableOnly then matches = profit ~= nil and profit > 0 end
                if matches and filters.hideLowProfit then matches = profit == nil or profit > 0 end
                if matches and filters.reviewOnly then matches = freshness == "review" end
                if matches and filters.craftableOnly and not hasSale then
                    -- Craftability describes recipe/output/cost completeness, not auction profitability.
                    matches = status == "known" and hasOutput and completeCost
                end
            end
            if matches then
                if build.tab == "low" then
                    if (tonumber(item.totalQuantity) or 0) <= GetLowSupplyThreshold(item) then
                        build.rows[#build.rows + 1] = item
                    end
                else
                    build.rows[#build.rows + 1] = item
                end
            end
        end
        build.index = build.index + 1
    end
    if build.index <= build.total then
        if UI.resultCount then
            UI.resultCount:SetText(string.format("Filtering %d/%d…", math.min(build.index - 1, build.total), build.total))
        end
        return
    end
    UI.lastFilterDuration = math.max(0, Now() - (build.startedAt or Now()))
    local pendingIDs = {}
    for itemID in pairs(build.pendingTooltipIDs or {}) do pendingIDs[#pendingIDs + 1] = itemID end
    if build.includeTooltip and build.query ~= "" and #pendingIDs > 0 then
        UI.viewBuild = nil
        UI.tooltipSearchWarmup = {
            generation = build.generation,
            ids = pendingIDs, index = 1, outstanding = 0,
            startedAt = Now(), query = build.query, tab = build.tab,
            awaiting = {},
        }
        UI.tooltipSearchDiagnostics.lastState = "warming"
        UI.tooltipSearchDiagnostics.pending = #pendingIDs
        -- Show immediate name/reagent matches while tooltip descriptions load;
        -- the final pass later adds any tooltip-only matches.
        UI.FinishView(build.rows)
        if UI.resultCount then UI.resultCount:SetText(string.format("Loading descriptions: 0/%d", #pendingIDs)) end
        return
    end
    UI.viewBuild = nil
    if #build.rows > 1 then
        local sort = UI.sortByTab[build.tab] or { key = "name", ascending = true }
        UI.rankSort = {
            key = sort.key,
            ascending = sort.ascending,
            source = build.rows,
            target = {},
            width = 1,
            left = 1,
            i = 1,
            j = 2,
            k = 1,
            right = math.min(3, #build.rows + 1),
            mid = 2,
            count = #build.rows,
        }
        local sortLabel = sort.key == "name" and "name"
            or (sort.key == "price" and (build.tab == "market" and "cheapest price" or "sale price")
            or (sort.key == "depth" and "at-price quantity"
            or (sort.key == "change" and "price change" or "profit")))
        SetStatus(string.format("Sorting all %d %s by %s…", #build.rows,
            (build.tab == "crafts" and "profession crafts") or "items", sortLabel))
        return
    end
    UI.FinishView(build.rows)
end

local TOOLTIP_SEARCH_TIMEOUT_SECONDS = 15
local function StepTooltipSearchWarmup()
    local warmup = UI.tooltipSearchWarmup
    if not warmup then return end
    if warmup.generation ~= UI.searchGeneration then UI.tooltipSearchWarmup = nil; return end
    if Now() - (warmup.startedAt or Now()) >= TOOLTIP_SEARCH_TIMEOUT_SECONDS then
        for _, itemID in ipairs(warmup.ids) do
            UI.tooltipSearchRequested[itemID] = nil
            UI.tooltipSearchCache[itemID] = false
            warmup.awaiting[itemID] = nil
        end
        UI.tooltipSearchDiagnostics.timeouts = UI.tooltipSearchDiagnostics.timeouts + 1
        UI.tooltipSearchDiagnostics.lastState = "timeout"
        UI.tooltipSearchDiagnostics.pending = 0
        UI.tooltipSearchWarmup = nil
        UI.StartViewBuild()
        return
    end
    -- Reconcile outstanding requests against the cache as well as events. This
    -- protects against client builds that populate item data without delivering
    -- the event signature expected by this addon.
    local api = _G.C_Item
    for itemID in pairs(warmup.awaiting) do
        local cached = type(_G.GetItemInfo) == "function" and _G.GetItemInfo(itemID) ~= nil
        if not cached and type(api) == "table" and type(api.IsItemDataCachedByID) == "function" then
            local ok, value = pcall(api.IsItemDataCachedByID, itemID)
            cached = ok and value == true
        end
        if cached then
            warmup.awaiting[itemID] = nil
            warmup.outstanding = math.max(0, warmup.outstanding - 1)
            UI.tooltipSearchRequested[itemID] = nil
        end
    end
    UI.tooltipSearchRequestsThisFrame = 0
    UI.tooltipSearchScansThisFrame = 0
    local processed = 0
    while warmup.index <= #warmup.ids and processed < 10 do
        local itemID = warmup.ids[warmup.index]
        local text = GetTooltipSearchText(itemID)
        if text == nil then
            if UI.tooltipSearchRequested[itemID] then
                warmup.outstanding = warmup.outstanding + 1
                warmup.awaiting[itemID] = true
                warmup.index = warmup.index + 1
                processed = processed + 1
            else
                -- Per-frame request budget reached. Retry this ID next frame.
                break
            end
        else
            warmup.index = warmup.index + 1
            processed = processed + 1
        end
    end
    if warmup.index > #warmup.ids and warmup.outstanding <= 0 then
        UI.tooltipSearchWarmup = nil
        UI.tooltipSearchDiagnostics.completed = UI.tooltipSearchDiagnostics.completed + 1
        UI.tooltipSearchDiagnostics.lastState = "complete"
        UI.tooltipSearchDiagnostics.pending = 0
        UI.StartViewBuild() -- one final pass, now backed by resolved/cached tooltip data
        return
    end
    if UI.resultCount then
        local resolved = math.max(0, warmup.index - 1 - warmup.outstanding)
        UI.resultCount:SetText(string.format("Loading descriptions: %d/%d", resolved, #warmup.ids))
    end
end

local function UpdateResultRange()
    if not UI.resultCount then return end
    local total = #(UI.viewRows or {})
    local first = total > 0 and (math.floor((UI.listOffset or 0) / UI.rowHeight) + 1) or 0
    local last = total > 0 and math.min(total, first + UI.visibleCount - 1) or 0
    UI.resultCount:SetText(string.format("%d-%d / %d", first, last, total))
end

function UI.FinishView(rows)
    UI.viewRows = rows
    UI.rankSort = nil
    UI.scrollChild:SetHeight(math.max(1, #UI.viewRows * UI.rowHeight))
    UI.RenderRows()
    if UI.activeTab == "history" then UI.RenderHistory() end
    local wanted = UI.selectedByTab[UI.activeTab]
    local chosen
    if wanted then
        for _, candidate in ipairs(UI.viewRows) do
            if (wanted.recipeKey and candidate.recipeKey == wanted.recipeKey)
                or (wanted.itemID and tonumber(candidate.itemID) == tonumber(wanted.itemID)) then
                chosen = candidate
                break
            end
        end
    end
    if not chosen then chosen = UI.viewRows[1] end
    if chosen and SelectItem then SelectItem(chosen)
    elseif not chosen then
        UI.selectedItem = nil
        if UI.detailName then UI.detailName:SetText("No matching items") end
        if UI.detailIcon then UI.detailIcon:Hide() end
        if UI.detailBadges then UI.detailBadges:SetText("") end
        SetDetailEconomics("No entries match the current filters. Adjust the filters or search to see results.")
    end
    UpdateResultRange()
    local provider = MM.ProfessionData and MM.ProfessionData.GetFutureProviderStatus
        and MM.ProfessionData.GetFutureProviderStatus()
    if provider then
        if provider.available and provider.dataSource == "ForeverDB.net" then
            if UI.recipeMarketBuildCompatible == false then
                local baselineNote = provider.dataBuildMatchesClient and "" or string.format(
                    " · ForeverDB baseline %s remains loaded; %d hotfix-linked records flagged for review",
                    tostring(provider.datasetBuild or "UNKNOWN"), provider.reviewWatchCount or 0)
                local refreshInstruction = " Refresh: open Auction House > Update Full Market > Confirm, then wait for the full scan to finish."
                if not UI.catalogSnapshot then
                    SetStatus("Craft profitability paused: no completed market snapshot for client build "
                        .. tostring(provider.currentBuild or "UNKNOWN") .. "." .. refreshInstruction .. baselineNote)
                else
                    SetStatus(string.format(
                        "Craft profitability paused: auction snapshot %s does not match client %s.%s",
                        tostring(UI.recipeMarketSnapshotBuild or "UNKNOWN"),
                        tostring(provider.currentBuild or "UNKNOWN"), refreshInstruction) .. baselineNote)
                end
            else
                local freshness = provider.dataBuildMatchesClient and "build matched"
                    or string.format("baseline from %s; client %s",
                        tostring(provider.datasetBuild or "UNKNOWN"), tostring(provider.currentBuild or "UNKNOWN"))
                local review = (provider.reviewWatchCount or 0) > 0
                    and string.format(" · %d hotfix-linked records flagged for review", provider.reviewWatchCount) or ""
                SetStatus(string.format(
                    "ForeverDB %s · %d observed · %d Classic-borrowed · %d unverified · %d speculative + %d non-item outputs excluded%s",
                    freshness, provider.count or 0, provider.borrowedSourceCount or 0,
                    provider.unknownSourceCount or 0, provider.speculativeCount or 0,
                    provider.nonItemCount or 0,
                    (provider.reviewWatchCount or 0) > 0
                        and string.format(" · %d review flags", provider.reviewWatchCount) or ""))
            end
        elseif provider.available then
            SetStatus(string.format("%d unlearned craft candidates · %d borrowed-source · %d unknown-source",
                provider.count or 0, provider.borrowedSourceCount or 0, provider.unknownSourceCount or 0))
        else
            SetStatus(provider.status .. " · known recipes remain available")
        end
    end
end

local function ComesBefore(a, b, key, ascending)
    local av, bv
    if key == "name" then
        av, bv = NormalizeSearchText(GetItemName(a)), NormalizeSearchText(GetItemName(b))
    elseif key == "price" then
        av = tonumber(a.minPriceCopper or a.salePriceCopper) or math.huge
        bv = tonumber(b.minPriceCopper or b.salePriceCopper) or math.huge
    elseif key == "depth" then
        av = tonumber(a.minPriceQuantity) or math.huge
        bv = tonumber(b.minPriceQuantity) or math.huge
    elseif key == "materials" then
        av = tonumber(a.materialCostCopper or (a.economics and a.economics.materialCostCopper)) or math.huge
        bv = tonumber(b.materialCostCopper or (b.economics and b.economics.materialCostCopper)) or math.huge
    elseif key == "total" then
        av = tonumber(a.totalQuantity) or math.huge
        bv = tonumber(b.totalQuantity) or math.huge
    elseif key == "change" then
        av = tonumber(a.historyDeltaCopper) or (ascending and math.huge or -math.huge)
        bv = tonumber(b.historyDeltaCopper) or (ascending and math.huge or -math.huge)
    else
        av = tonumber(a.estimatedProfitCopper or a.profitCopper
            or (a.economics and a.economics.profitCopper)) or -math.huge
        bv = tonumber(b.estimatedProfitCopper or b.profitCopper
            or (b.economics and b.economics.profitCopper)) or -math.huge
    end
    if av == bv then
        local an, bn = NormalizeSearchText(GetItemName(a)), NormalizeSearchText(GetItemName(b))
        if an == bn then return (tonumber(a.itemID or a.recipeID) or 0) < (tonumber(b.itemID or b.recipeID) or 0) end
        return an < bn
    end
    if ascending then return av < bv end
    return av > bv
end

local function StepRankSort()
    local state = UI.rankSort
    if not state then return end
    local budget = 500
    while budget > 0 do
        if state.width >= state.count then
            UI.FinishView(state.source)
            return
        end
        if state.left > state.count then
            state.source, state.target = state.target, state.source
            state.width = state.width * 2
            state.left = 1
            state.i = 1
            state.j = state.width + 1
            state.k = 1
            state.mid = math.min(state.width + 1, state.count + 1)
            state.right = math.min(state.width * 2 + 1, state.count + 1)
        end
        if state.k >= state.right then
            state.left = state.left + state.width * 2
            state.i = state.left
            state.mid = math.min(state.left + state.width, state.count + 1)
            state.j = state.mid
            state.k = state.left
            state.right = math.min(state.left + state.width * 2, state.count + 1)
        else
            local takeLeft
            if state.i >= state.mid then
                takeLeft = false
            elseif state.j >= state.right then
                takeLeft = true
            else
                takeLeft = ComesBefore(state.source[state.i], state.source[state.j], state.key, state.ascending)
            end
            if takeLeft then
                state.target[state.k] = state.source[state.i]
                state.i = state.i + 1
            else
                state.target[state.k] = state.source[state.j]
                state.j = state.j + 1
            end
            state.k = state.k + 1
            budget = budget - 1
        end
    end
end

function UI.RenderRows()
    -- Item-data callbacks may arrive while ProfessionMaster is initializing,
    -- before CreateUI has populated the virtual row pool. An empty table is
    -- truthy in Lua, so checking only UI.rows is not sufficient.
    if type(UI.rows) ~= "table" or not UI.rows[1] or not UI.scrollChild then return end
    local rowPoolCount = #UI.rows
    if rowPoolCount == 0 then return end
    local startIndex = math.floor((UI.listOffset or 0) / UI.rowHeight) + 1
    local isCrafting = UI.activeTab == "crafts"
    for i = 1, math.min(UI.visibleCount or rowPoolCount, rowPoolCount) do
        local index = startIndex + i - 1
        local item = UI.viewRows[index]
        local button = UI.rows[i]
        if button then
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", UI.scrollChild, "TOPLEFT", 0, -((index - 1) * UI.rowHeight))
        UI.visibleRows[i] = item
        if item then
            if button.icon then
                button.icon:SetTexture(GetItemIcon(item.itemID))
                button.icon:Show()
            end
            if button.rowShade then
                if index % 2 == 0 then
                    button.rowShade:SetColorTexture(0.105, 0.086, 0.052, 0.30)
                else
                    button.rowShade:SetColorTexture(0.018, 0.019, 0.021, 0.26)
                end
                button.rowShade:Show()
            end
            local profitText = "—"
            if isCrafting then
                local status = GetCraftSourceStatus(item)
                local color = status == "known" and "|cff8ee6a2"
                    or (status == "learnable" and "|cffffd77a"
                    or (status == "unlearnable" and "|cffff6666"
                    or (status == "unknown" and "|cffff6666" or "|cffff6666")))
                -- Known/unlearned is the player-facing distinction. Source
                -- confidence remains in the data model, not as row prefixes.
                button.name:SetText(color .. GetItemName(item) .. "|r")
                button.price:SetText(item.salePriceCopper and FormatMoney(item.salePriceCopper) or "—")
                -- Keep the table compact even for recipes with many reagents.
                -- Full reagent detail (icons, quantities and per-line costs) is
                -- available from the material-column hover tooltip.
                local materialCost = item.materialCostCopper and FormatMoney(item.materialCostCopper) or "—"
                button.depth:SetText(materialCost)
                button.atPrice:SetText(item.minPriceQuantity ~= nil and tostring(item.minPriceQuantity) or "—")
                button.total:SetText(item.totalQuantity ~= nil and tostring(item.totalQuantity) or "—")
                if item.profitCopper ~= nil then
                    local profitColor = item.profitCopper >= 0 and "|cff55dd77" or "|cffff6666"
                    profitText = profitColor .. FormatMoney(item.profitCopper) .. "|r"
                elseif item.costComplete == false then
                    profitText = "|cff999999Incomplete|r"
                end
            elseif UI.activeTab == "economics" then
                local economics = item.economics
                button.name:SetText(GetItemDisplayName(item))
                button.price:SetText(item.minPriceCopper and FormatMoney(item.minPriceCopper) or "No buyout")
                button.depth:SetText(economics and economics.materialCostCopper
                    and FormatMoney(economics.materialCostCopper) or "—")
                local delta = tonumber(item.historyDeltaCopper)
                local deltaText = "—"
                if delta ~= nil then
                    local deltaColor = delta > 0 and "|cff55dd77+" or (delta < 0 and "|cffff6666-" or "|cffcccccc")
                    deltaText = deltaColor .. FormatMoney(math.abs(delta)) .. "|r"
                end
                button.atPrice:SetText(deltaText)
                button.total:SetText(tostring(item.totalQuantity or 0))
                if economics and economics.profitCopper ~= nil then
                    local profitColor = economics.profitCopper >= 0 and "|cff55dd77" or "|cffff6666"
                    profitText = profitColor .. FormatMoney(economics.profitCopper) .. "|r"
                elseif economics then profitText = "|cff999999Incomplete|r" end
            else
                button.name:SetText(GetItemDisplayName(item))
                button.price:SetText(item.minPriceCopper and FormatMoney(item.minPriceCopper) or "No buyout")
                button.depth:SetText(item.minPriceQuantity ~= nil and tostring(item.minPriceQuantity) or "—")
                button.atPrice:SetText(tostring(item.totalQuantity or 0))
                button.total:SetText(item.auctionCountKnown and tostring(item.auctionCount or 0) or "—")
                if UI.activeTab == "history" then
                    button.depth:SetText(item.historyDeltaCopper ~= nil
                        and ((item.historyDeltaCopper > 0 and "|cff55dd77+" or (item.historyDeltaCopper < 0 and "|cffff6666" or "|cffffffff"))
                            .. FormatMoney(math.abs(item.historyDeltaCopper)) .. "|r") or "—")
                    button.total:SetText(tostring(item.totalQuantity or 0))
                elseif UI.activeTab == "low" then
                    button.depth:SetText(item.minPriceQuantity ~= nil and tostring(item.minPriceQuantity) or "—")
                end
                local best = UI.economicsByItemID and UI.economicsByItemID[tonumber(item.itemID)]
                if best and best.profitCopper ~= nil then
                    local profitColor = best.profitCopper >= 0 and "|cff55dd77" or "|cffff6666"
                    profitText = profitColor .. FormatMoney(best.profitCopper) .. "|r"
                end
            end
            button.profit:SetText(profitText)
            local selected = UI.selectedItem
            local same = selected and (isCrafting
                and selected.recipeKey == item.recipeKey
                or (not isCrafting and selected.itemID == item.itemID))
            if same then
                button:LockHighlight()
                if button.selectedWash then button.selectedWash:Show() end
                if button.selectedAccent then button.selectedAccent:Show() end
                if button.selectedTop then button.selectedTop:Show() end
                if button.selectedBottom then button.selectedBottom:Show() end
            else
                button:UnlockHighlight()
                if button.selectedWash then button.selectedWash:Hide() end
                if button.selectedAccent then button.selectedAccent:Hide() end
                if button.selectedTop then button.selectedTop:Hide() end
                if button.selectedBottom then button.selectedBottom:Hide() end
            end
            button:Show()
        else
            button:Hide()
            if button.icon then button.icon:Hide() end
            if button.rowShade then button.rowShade:Hide() end
            if button.selectedWash then button.selectedWash:Hide() end
            if button.selectedAccent then button.selectedAccent:Hide() end
            if button.selectedTop then button.selectedTop:Hide() end
            if button.selectedBottom then button.selectedBottom:Hide() end
            UI.visibleRows[i] = nil
        end
        end
    end
    for i = rowPoolCount + 1, #(UI.visibleRows or {}) do UI.visibleRows[i] = nil end
    if UI.activeTab == "economics" then
        local function measured(fs, fallback)
            local width = fs and type(fs.GetStringWidth) == "function" and fs:GetStringWidth() or nil
            return math.max(fallback, tonumber(width) or fallback)
        end
        local widths = {
            profit = measured(UI.headerButtons[6] and UI.headerButtons[6].label, 120),
            total = measured(UI.headerButtons[5] and UI.headerButtons[5].label, 68),
            change = measured(UI.headerButtons[4] and UI.headerButtons[4].label, 88),
            depth = measured(UI.headerButtons[3] and UI.headerButtons[3].label, 100),
            price = measured(UI.headerButtons[2] and UI.headerButtons[2].label, 100),
        }
        for i = 1, math.min(UI.visibleCount or rowPoolCount, rowPoolCount) do
            local row = UI.rows[i]
            if row and UI.visibleRows[i] then
                widths.profit = math.max(widths.profit, measured(row.profit, 120))
                widths.total = math.max(widths.total, measured(row.total, 68))
                widths.change = math.max(widths.change, measured(row.atPrice, 88))
                widths.depth = math.max(widths.depth, measured(row.depth, 100))
                widths.price = math.max(widths.price, measured(row.price, 100))
            end
        end
        widths.profit = math.min(190, widths.profit + 14)
        widths.total = math.min(100, widths.total + 12)
        widths.change = math.min(126, widths.change + 12)
        widths.depth = math.min(150, widths.depth + 12)
        widths.price = math.min(128, widths.price + 12)
        local right = 1106
        local xProfit = right - widths.profit
        local xTotal = xProfit - 6 - widths.total
        local xChange = xTotal - 6 - widths.change
        local xDepth = xChange - 6 - widths.depth
        local xPrice = xDepth - 6 - widths.price
        local columns = {
            { x = 302, w = math.max(90, xPrice - 302 - 6), justify = "LEFT" },
            { x = xPrice, w = widths.price, justify = "RIGHT" },
            { x = xDepth, w = widths.depth, justify = "RIGHT" },
            { x = xChange, w = widths.change, justify = "RIGHT" },
            { x = xTotal, w = widths.total, justify = "RIGHT" },
            { x = xProfit, w = widths.profit, justify = "RIGHT" },
        }
        for i, column in ipairs(columns) do
            local header = UI.headerButtons[i]
            header:ClearAllPoints(); header:SetPoint("TOPLEFT", UI.frame, "TOPLEFT", column.x, -218); header:SetWidth(column.w)
            header.label:SetWidth(column.w - 8); header.label:SetJustifyH(column.justify)
        end
        for _, row in ipairs(UI.rows or {}) do
            local positions = { 27, xPrice - 298, xDepth - 298, xChange - 298, xTotal - 298 }
            local fields = { row.name, row.price, row.depth, row.atPrice, row.total }
            local fieldWidths = { columns[1].w - 12, widths.price, widths.depth, widths.change, widths.total }
            for j = 1, #fields do
                fields[j]:ClearAllPoints(); fields[j]:SetPoint("LEFT", row, "LEFT", positions[j], 0); fields[j]:SetWidth(fieldWidths[j])
            end
            row.profit:ClearAllPoints(); row.profit:SetPoint("RIGHT", row, "RIGHT", -4, 0); row.profit:SetWidth(widths.profit)
        end
    end
    UpdateResultRange()
end

function UI.RenderHistory()
    if not UI.historyText then return end
    local item = UI.selectedItem
    if not item then
        UI.historyText:SetText("Select an item to compare saved prices.")
        for _, bar in ipairs(UI.historyBars or {}) do bar:Hide() end
        for _, label in ipairs(UI.historyBarLabels or {}) do label:Hide() end
        return
    end
    local history = MM.db and MM.db.marketHistory or {}
    local points = {}
    for i = math.max(1, #history - 3), #history do
        local snapshot = history[i]
        local found = snapshot.items and snapshot.items[tonumber(item.itemID)]
        if found and tonumber(found.price) then
            points[#points + 1] = {
                price = tonumber(found.price),
                quantity = tonumber(found.quantity) or 0,
                timestamp = tonumber(snapshot.timestamp) or 0,
            }
        end
    end
    if #points == 0 then
        UI.historyText:SetText("No saved full-market history yet. Each completed full scan adds a comparison point.")
        for _, bar in ipairs(UI.historyBars or {}) do bar:Hide() end
        for _, label in ipairs(UI.historyBarLabels or {}) do label:Hide() end
        return
    end
    local lines = {}
    for i = #points, 1, -1 do
        local point = points[i]
        local dateText = type(_G.date) == "function" and _G.date("%d %b %H:%M", point.timestamp)
            or tostring(point.timestamp)
        lines[#lines + 1] = string.format("%s  %s  (%s units)",
            dateText, FormatMoney(point.price), tostring(point.quantity))
    end
    UI.historyText:SetText(table.concat(lines, "\n"))

    local minPrice, maxPrice = points[1].price, points[1].price
    for _, point in ipairs(points) do
        minPrice = math.min(minPrice, point.price)
        maxPrice = math.max(maxPrice, point.price)
    end
    local span = math.max(1, maxPrice - minPrice)
    for i, bar in ipairs(UI.historyBars or {}) do
        local point = points[i]
        local percentLabel = UI.historyBarLabels and UI.historyBarLabels[i]
        if point then
            local graphHeight = UI.historyGraph and UI.historyGraph.GetHeight
                and (UI.historyGraph:GetHeight() or 104) or 104
            local height = 10 + ((point.price - minPrice) / span) * math.max(24, graphHeight - 42)
            bar:ClearAllPoints()
            bar:SetPoint("BOTTOMLEFT", UI.historyGraph, "BOTTOMLEFT", (i - 1) * 58 + 8, 4)
            bar:SetSize(38, height)
            local previous = points[i - 1]
            local change = previous and previous.price > 0
                and ((point.price - previous.price) / previous.price * 100) or 0
            if percentLabel then
                percentLabel:ClearAllPoints()
                percentLabel:SetPoint("BOTTOM", UI.historyGraph, "BOTTOMLEFT",
                    (i - 1) * 58 + 27, math.min(height + 1, graphHeight - 24))
                percentLabel:SetText(string.format("%+.1f%%", change))
                if type(percentLabel.SetTextColor) == "function" then
                    percentLabel:SetTextColor(change > 0 and 0.35 or (change < 0 and 1 or 0.85),
                        change > 0 and 1 or (change < 0 and 0.38 or 0.82),
                        change > 0 and 0.48 or (change < 0 and 0.32 or 0.55))
                end
                percentLabel:Show()
            end
            if previous and point.price > previous.price then
                bar:SetColorTexture(0.22, 0.72, 0.38, 0.95)
            elseif previous and point.price < previous.price then
                bar:SetColorTexture(0.78, 0.25, 0.22, 0.95)
            else
                bar:SetColorTexture(0.72, 0.62, 0.36, 0.95)
            end
            bar:Show()
        else
            bar:Hide()
            if percentLabel then percentLabel:Hide() end
        end
    end
end

local function AppendSkillThresholdLines(lines, thresholds)
    if type(thresholds) ~= "table" then return end
    local evidence = thresholds.other_threshold_evidence or thresholds.threshold_evidence
    local parts = {}
    for _, key in ipairs({ "orange", "yellow", "green", "grey" }) do
        local value = tonumber(thresholds[key])
        if value then parts[#parts + 1] = key:sub(1, 1):upper() .. key:sub(2) .. " " .. value end
    end
    if #parts > 0 and evidence == "FOREVER_CLIENT" then
        lines[#lines + 1] = "Skill-up colours (Forever client data; not trainer requirements): "
            .. table.concat(parts, " · ")
    end
    local classicOrange = tonumber(thresholds.orange_classic)
    if classicOrange then
        lines[#lines + 1] = "Classic orange " .. classicOrange .. " (borrowed; not Forever-confirmed)"
    end
end

local function SelectPrimaryAcquisitionSource(sources)
    if type(sources) ~= "table" then return nil end
    local priorities = { "FOREVER_OBSERVED", "CLASSIC_BORROWED", "FOREVER_CLIENT", "UNKNOWN" }
    -- Prefer a direct Forever recipe/source relationship. If none exists, use
    -- the Classic route as the useful default rather than dumping every route.
    for _, evidence in ipairs(priorities) do
        for _, source in ipairs(sources) do
            if type(source) == "table" and source.evidence == evidence
                and source.type ~= "trainer_observation" and source.inferred ~= true then
                return source
            end
        end
    end
    for _, source in ipairs(sources) do
        if type(source) == "table" and source.type ~= "trainer_observation" then return source end
    end
    return nil
end

local function AppendPrimaryAcquisitionLines(lines, recipe, item)
    local sources = recipe.acquisitionSources or item.acquisitionSources
    local source = SelectPrimaryAcquisitionSource(sources)
    if not source then
        lines[#lines + 1] = "Acquisition: Unknown"
        return
    end
    local kind = source.type
    local label = kind == "trainer" and "Trainer"
        or kind == "vendor" and "Vendor"
        or (kind == "recipe_item" or kind == "recipe_item_hidden" or kind == "recipe_item_not_in_client") and "Recipe"
        or kind == "drop" and "Drop"
        or kind == "quest" and "Quest"
        or kind == "automatic" and "Automatic"
        or "Source"
    local name = source.name or (kind == "automatic" and "Learned automatically") or "Unknown"
    lines[#lines + 1] = label .. ": " .. tostring(name)
    if source.zone and source.zone ~= "" then
        lines[#lines + 1] = "Location: " .. tostring(source.zone)
    end
    local cost
    if kind == "trainer" then
        cost = tonumber(recipe.trainerCostCopper or item.trainerCostCopper)
    elseif kind == "vendor" then
        cost = tonumber(source.price_per_item_copper or source.price_copper)
    end
    if cost and cost > 0 then lines[#lines + 1] = "Cost: " .. FormatMoney(cost) end
end

local function RenderCraftDetail(item)
    local recipe = item and item.recipeData
    if not recipe then
        SetDetailEconomics("Recipe details are unavailable.")
        if UI.detailProfit then UI.detailProfit:SetText("—") end
        return
    end
    local lines = {
        "Recipe: " .. tostring(recipe.recipeName or item.recipeName or "Unknown recipe"),
        "Output: " .. tostring(item.outputQuantity or "?") .. " × " .. tostring(item.itemName or ("Item #" .. tostring(item.itemID or "?"))),
        "",
        "|cffffd100ACQUISITION|r",
    }
    AppendPrimaryAcquisitionLines(lines, recipe, item)
    if item.variableYield then
        lines[#lines + 1] = "|cffffaa44Variable output; profit uses minimum yield.|r"
    end
    if not item.outputQuantity then
        lines[#lines + 1] = "|cffffaa44Output quantity unavailable; profit is withheld.|r"
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "|cffffd100REAGENTS|r"
    if #(item.reagentLines or {}) == 0 then
        lines[#lines + 1] = "No reagent data supplied by the client."
    else
        for _, reagent in ipairs(item.reagentLines) do
            local label = "|T" .. tostring(GetItemIcon(reagent.itemID)) .. ":16:16:0:0|t "
                .. tostring(reagent.itemName or ("Item #" .. tostring(reagent.itemID or "?")))
            local qty = tostring(reagent.quantity or "?")
            if reagent.lineCostCopper then
                lines[#lines + 1] = string.format("%s × %s  —  %s",
                    label, qty, FormatMoney(reagent.lineCostCopper))
                if (reagent.choiceCount or 0) > 1 then
                    lines[#lines] = lines[#lines] .. " (cheapest listed choice)"
                end
            else
                lines[#lines + 1] = string.format("%s × %s  —  |cffff6666price or quantity unknown|r", label, qty)
            end
        end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Total material cost / craft: " ..
        (item.materialCostCopper and FormatMoney(item.materialCostCopper) or "|cffff6666Incomplete — missing market data|r")
    if item.grossSaleCopper then
        lines[#lines + 1] = "Gross sale / craft: " .. FormatMoney(item.grossSaleCopper)
        lines[#lines + 1] = "After " .. tostring(item.cutPercent or 5) .. "% AH cut: " .. FormatMoney(item.netSaleCopper)
    end
    local vendorPrice = GetVendorInfo(item.itemID, true)
    if vendorPrice then
        lines[#lines + 1] = "Vendor sell / unit: " .. FormatMoney(vendorPrice)
        if item.outputQuantity and item.materialCostCopper then
            local vendorProfit = vendorPrice * item.outputQuantity - item.materialCostCopper
            local vendorColor = vendorProfit >= 0 and "|cff55dd77" or "|cffff6666"
            lines[#lines + 1] = "Craft → vendor: " .. vendorColor .. FormatMoney(vendorProfit) .. "|r / craft"
        end
    end
    if item.yieldNote then lines[#lines + 1] = item.yieldNote end
    if #(item.missing or {}) > 0 then
        lines[#lines + 1] = "|cffffaa44Unknown: " .. table.concat(item.missing, ", ") .. "|r"
    end
    if UI.detailProfit then
        if item.profitCopper ~= nil then
            local color = item.profitCopper >= 0 and "|cff55dd77" or "|cffff6666"
            local netSale = tonumber(item.netSaleCopper)
            local margin = netSale and netSale > 0 and (item.profitCopper / netSale * 100) or nil
            UI.detailProfit:SetText(color .. FormatMoney(item.profitCopper) .. "|r")
            if margin then lines[#lines + 1] = string.format("Profit margin: %.1f%%", margin) end
        else
            UI.detailProfit:SetText("Incomplete")
            lines[#lines + 1] = "Profit unavailable until every required price is known."
        end
    end
    SetDetailEconomics(table.concat(lines, "\n"))
end

local function RenderMarketRecipeContext(item)
    local recipes = MM.Recipes and MM.Recipes.GetAllRecipes() or {}
    local itemID = tonumber(item and item.itemID)
    if not itemID then
        SetDetailEconomics("Select an item to inspect its market, gathering and recipe relationships.")
        if UI.detailProfit then UI.detailProfit:SetText("—") end
        return
    end

    local makes, uses = {}, {}
    local cut = tonumber(MM.db and MM.db.auctionHouseCutPercent) or 5
    for _, recipe in ipairs(recipes) do
        local creates = tonumber(recipe.outputItemID) == itemID
        local consumes = false
        for _, slot in ipairs(recipe.reagents or {}) do
            for _, choice in ipairs(slot.choices or {}) do
                if tonumber(choice.itemID) == itemID then consumes = true; break end
            end
            if consumes then break end
        end
        if creates or consumes then
            local summary = MM.Recipes.BuildEconomics(recipe, function(id)
                return GetMarketPrice(id)
            end, cut)
            local label = tostring(recipe.recipeName or "Recipe") .. " · " .. tostring(recipe.professionName or "Profession")
            if summary and summary.profitCopper ~= nil then
                local color = summary.profitCopper >= 0 and "|cff55dd77" or "|cffff6666"
                label = label .. " · " .. color .. FormatMoney(summary.profitCopper) .. "/craft|r"
            elseif creates then
                label = label .. " · cost incomplete"
            end
            if creates and #makes < 6 then makes[#makes + 1] = label end
            if consumes and #uses < 8 then
                uses[#uses + 1] = label .. " → " .. tostring(summary and summary.itemName or "crafted item")
            end
        end
    end

    local lines = {}
    local professionData = MM.ProfessionData and MM.ProfessionData.GetItem(itemID)
    local gathering = MM.ProfessionData and MM.ProfessionData.GetGatheringInfo(itemID)
    local knownOutputCount = 0
    for _, recipe in ipairs(professionData and professionData.knownCrafts or {}) do
        if tonumber(recipe.outputItemID or recipe.craftedItemId) == itemID then
            knownOutputCount = knownOutputCount + 1
        end
    end
    local otherOutputCount = math.max(0, #makes - knownOutputCount)
    local craftingSummary = knownOutputCount > 0
        and string.format("%d known recipe%s", knownOutputCount, knownOutputCount == 1 and "" or "s")
        or "No known recipes"
    if otherOutputCount > 0 then
        craftingSummary = craftingSummary .. " · other supported routes"
    end
    lines[#lines + 1] = "|TInterface\\Icons\\Trade_BlackSmithing:16|t |cffffd100Crafting:|r " .. craftingSummary
    local gatheringNames = {}
    if gathering then
        for _, professionID in ipairs({ 182, 186, 356, 393 }) do
            local info = gathering[professionID]
            if info then
                local professionName = (professionData and professionData.professions[professionID])
                    or "Gathering profession"
                gatheringNames[#gatheringNames + 1] = {
                    name = tostring(professionName) .. " (Classic)",
                    skill = tonumber(info.requiredSkill) or 1,
                    currentSkill = tonumber(info.currentSkill),
                    canGatherNow = info.canGatherNow == true,
                    skillKnown = info.skillKnown == true,
                }
            end
        end
    end
    if #gatheringNames > 0 then
        local names = {}
        for _, entry in ipairs(gatheringNames) do names[#names + 1] = entry.name end
        lines[#lines + 1] = "|TInterface\\Icons\\INV_Misc_Herb_01:16|t |cff66ccffGathering:|r "
            .. table.concat(names, ", ")
    else
        lines[#lines + 1] = "|TInterface\\Icons\\INV_Misc_Herb_01:16|t |cff66ccffGathering:|r No mapped source"
    end
    local futureRecipes = {}
    if professionData then
        for _, future in ipairs(professionData.futureCrafts or {}) do
            futureRecipes[#futureRecipes + 1] = future
        end
        for _, future in ipairs(professionData.unknownFutureCrafts or {}) do
            futureRecipes[#futureRecipes + 1] = future
        end
    end
    for _, recipe in ipairs(futureRecipes) do
        local creates = tonumber(recipe.outputItemID) == itemID
        local consumes = false
        for _, slot in ipairs(recipe.reagents or {}) do
            for _, choice in ipairs(slot.choices or {}) do
                if tonumber(choice.itemID) == itemID then consumes = true; break end
            end
            if consumes then break end
        end
        if creates or consumes then
            local summary = MM.Recipes.BuildEconomics(recipe, function(id)
                return GetMarketPrice(id)
            end, cut)
            local sourceLabel = recipe.borrowedSources and " · source unconfirmed"
                or (recipe.sourceUnknown and " · source unknown" or " · unlearned")
            local freshnessLabel = recipe.freshnessStatus == "review"
                and (" · REVIEW: " .. tostring(recipe.freshnessField or "hotfix-linked field")) or ""
            local label = tostring(recipe.recipeName or "Recipe") .. " · "
                .. tostring(recipe.professionName or "Profession") .. sourceLabel .. freshnessLabel
            if summary and summary.profitCopper ~= nil then
                local color = summary.profitCopper >= 0 and "|cff55dd77" or "|cffff6666"
                label = label .. " · " .. color .. FormatMoney(summary.profitCopper) .. "/craft|r"
            elseif creates then
                label = label .. " · price or quantity incomplete"
            end
            if creates and #makes < 10 then makes[#makes + 1] = label end
            if consumes and #uses < 12 then
                uses[#uses + 1] = label .. " → " .. tostring(summary and summary.itemName or "crafted item")
            end
        end
    end
    if #gatheringNames > 0 then
        lines[#lines + 1] = "|cff66ccffGATHERING REQUIREMENTS|r"
        for _, entry in ipairs(gatheringNames) do
            if entry.canGatherNow then
                lines[#lines + 1] = string.format("%s · can gather now (skill %d; your skill %d)",
                    entry.name, entry.skill, entry.currentSkill or entry.skill)
            elseif entry.skillKnown then
                lines[#lines + 1] = string.format("%s · requires skill %d (your skill %d)",
                    entry.name, entry.skill, entry.currentSkill or 0)
            else
                lines[#lines + 1] = string.format("%s · requires skill %d (current skill not captured)",
                    entry.name, entry.skill)
            end
        end
    end
    if #makes > 0 then
        if #lines > 0 then lines[#lines + 1] = "" end
        lines[#lines + 1] = "|cffffd100CRAFTED BY|r"
        for _, line in ipairs(makes) do lines[#lines + 1] = line end
    end
    if #uses > 0 then
        if #lines > 0 then lines[#lines + 1] = "" end
        lines[#lines + 1] = "|cffffd100USED IN|r"
        for _, line in ipairs(uses) do lines[#lines + 1] = line end
    end
    if professionData and #professionData.futureCrafts > 0 then
        if #lines > 0 then lines[#lines + 1] = "" end
        lines[#lines + 1] = professionData and #professionData.knownCrafts > 0
            and "|cffffc04dOTHER UNLEARNED RECIPES|r"
            or "|cffffc04dFUTURE CRAFTS (UNLEARNED)|r"
        for i = 1, math.min(6, #professionData.futureCrafts) do
            local future = professionData.futureCrafts[i]
            local note = future.borrowedSources and " · source borrowed from Vanilla" or ""
            local skill = future.requiredSkill and (" · Skill " .. future.requiredSkill)
                or (future.borrowedSkill and " · skill estimate unconfirmed" or "")
            local freshness = future.freshnessStatus == "review"
                and (" · REVIEW: " .. tostring(future.freshnessField or "hotfix-linked field")) or ""
            lines[#lines + 1] = tostring(future.recipeName) .. " · "
                .. tostring(future.professionName or "Profession") .. skill .. note .. freshness
            AppendSkillThresholdLines(lines, future.skillThresholds)
        end
        if #professionData.unknownFutureCrafts > 0 then
            lines[#lines + 1] = string.format("+ %d additional unlearned recipes have unknown acquisition sources",
                #professionData.unknownFutureCrafts)
        end
    elseif professionData and #professionData.unknownFutureCrafts > 0 then
        if #lines > 0 then lines[#lines + 1] = "" end
        lines[#lines + 1] = "|cffffaa44Unlearned recipes exist, but Forever acquisition sources are unknown.|r"
    end
    if UI.activeTab == "economics" then
        local vendorPrice = GetVendorInfo(itemID, true)
        local cut = tonumber(MM.db and MM.db.auctionHouseCutPercent) or 5
        local auctionPrice = tonumber(item.minPriceCopper)
        if #lines > 0 then lines[#lines + 1] = "" end
        lines[#lines + 1] = "|cffffd100SALE OPTIONS|r"
        lines[#lines + 1] = "Auction lowest ask / unit: " .. (auctionPrice and FormatMoney(auctionPrice) or "No current buyout")
        if auctionPrice then
            lines[#lines + 1] = "Auction proceeds after " .. tostring(cut) .. "% cut: "
                .. FormatMoney(math.floor(auctionPrice * (1 - cut / 100))) .. " / unit"
        end
        lines[#lines + 1] = "Vendor sell / unit: " .. GetVendorStatus(itemID, vendorPrice)
        local best = UI.economicsByItemID and UI.economicsByItemID[itemID]
        if best then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "|cffffd100BEST CRAFT ROUTE|r"
            lines[#lines + 1] = tostring(best.professionName or "Profession") .. " · " .. tostring(best.recipeName or "Recipe")
            local routeStatus = GetCraftSourceStatus(best)
            if routeStatus == "known" then
                lines[#lines + 1] = "Recipe known by this character"
            elseif routeStatus == "learnable" then
                lines[#lines + 1] = "Unlearned recipe · profession learned"
            elseif routeStatus == "unlearnable" then
                lines[#lines + 1] = "Unlearned recipe · profession not learned"
            else
                lines[#lines + 1] = "Recipe learning status unknown"
            end
            lines[#lines + 1] = "Material cost / craft: " .. (best.materialCostCopper and FormatMoney(best.materialCostCopper) or "Incomplete")
            lines[#lines + 1] = "Auction profit / craft: " .. (best.profitCopper ~= nil and FormatMoney(best.profitCopper) or "Unavailable")
            if vendorPrice and best.materialCostCopper and best.outputQuantity then
                local vendorProfit = vendorPrice * best.outputQuantity - best.materialCostCopper
                local color = vendorProfit >= 0 and "|cff55dd77" or "|cffff6666"
                lines[#lines + 1] = "Vendor profit / craft: " .. color .. FormatMoney(vendorProfit) .. "|r"
            end
        end
    end
    SetDetailEconomics(table.concat(lines, "\n"))
    if UI.detailProfit then
        local best = UI.economicsByItemID and UI.economicsByItemID[itemID]
        if best and best.profitCopper ~= nil then
            local color = best.profitCopper >= 0 and "|cff55dd77" or "|cffff6666"
            UI.detailProfit:SetText(color .. FormatMoney(best.profitCopper) .. "|r")
        else
            UI.detailProfit:SetText("—")
        end
    end
    if UI.relationshipHeading then UI.relationshipHeading:SetText("Relationships") end
    if UI.marketInfoHeading then UI.marketInfoHeading:SetText("Market Information") end
end

SelectItem = function(item)
    if not item then return end
    UI.selectedItem = item
    UI.selectedByTab[UI.activeTab] = { itemID = tonumber(item.itemID), recipeKey = item.recipeKey }
    UI.detailName:SetText(item.recipeData and GetItemName(item) or GetItemDisplayName(item))
    if UI.detailIcon then UI.detailIcon:SetTexture(GetItemIcon(item.itemID)); UI.detailIcon:Show() end
    if UI.detailBadges then
        local tags = {}
        if item.recipeData then
            local state = GetCraftSourceStatus(item)
            tags[#tags + 1] = state == "known" and "|cff55dd77KNOWN|r"
                or (state == "learnable" and "|cffffd166LEARNABLE|r"
                or (state == "unlearnable" and "|cffff6666NOT LEARNABLE|r" or "|cffff6666UNKNOWN|r"))
            local freshness = item.freshnessStatus
                or (item.recipeData and item.recipeData.freshnessStatus)
            if freshness == "review" then tags[#tags + 1] = "|cffffc04dREVIEW|r"
            elseif freshness == "baseline" or item.sourceProvider == "ForeverDB.net" then
                tags[#tags + 1] = "|cff79c9ffBASELINE|r"
            end
        else
            tags[#tags + 1] = "|cff79c9ffMARKET ITEM|r"
        end
        UI.detailBadges:SetText(table.concat(tags, "    "))
    end
    if UI.marketInfoHeading then
        UI.marketInfoHeading:SetText(item.recipeData and "Craft Economics" or "Market Information")
    end
    if UI.relationshipHeading then
        UI.relationshipHeading:SetText(item.recipeData and "Recipe Details" or "Relationships")
    end
    if UI.detailProfitLabel then
        UI.detailProfitLabel:SetText(item.recipeData and "PROFIT / CRAFT" or "BEST CRAFT PROFIT")
    end
    local vendorPrice = GetVendorInfo(item.itemID, true)
    UI.detailPrice:SetText(item.minPriceCopper and FormatMoney(item.minPriceCopper)
        or (item.salePriceCopper and FormatMoney(item.salePriceCopper))
        or (vendorPrice and FormatMoney(vendorPrice)) or "No buyout")
    UI.detailSupply:SetText(string.format("%d units", tonumber(item.totalQuantity) or 0))
    if UI.detailAtPrice then
        UI.detailAtPrice:SetText(item.minPriceQuantity ~= nil and tostring(item.minPriceQuantity) or "—")
    end
    if item.recipeData then
        local requiredSkill = tonumber(item.requiredSkill or item.professionSkill
            or item.recipeData.professionSkill)
        local currentSkill, hasProfession
        if MM.ProfessionData and MM.ProfessionData.GetCharacterProfessionSkill then
            currentSkill, hasProfession = MM.ProfessionData.GetCharacterProfessionSkill(item.professionID)
        end
        local skillSummary
        if hasProfession then
            skillSummary = (UI.craftingScope == "account" and "Best recorded account skill " or "Your skill ") .. tostring(currentSkill or "?")
                .. (requiredSkill and (" · Requires " .. tostring(requiredSkill)) or " · Requirement unknown")
        elseif MM.ProfessionData and MM.ProfessionData.HasAuthoritativeProfessionList
            and MM.ProfessionData.HasAuthoritativeProfessionList() then
            skillSummary = "Profession not learned"
                .. (requiredSkill and (" · Requires " .. tostring(requiredSkill)) or "")
        else
            skillSummary = "Profession status unknown"
                .. (requiredSkill and (" · Requires " .. tostring(requiredSkill)) or "")
        end
        UI.detailVariants:SetText(tostring(item.professionName or "Profession") .. " · " .. skillSummary)
        RenderCraftDetail(item)
    else
        UI.detailVariants:SetText(item.noMarketData and "No current Auction House listing"
            or string.format("%d market variants grouped by item ID", item.variantCount or 1))
        RenderMarketRecipeContext(item)
    end
    UI.RenderHistory()
    UI.RenderRows()
end

local vendorInfoEvents = CreateFrame("Frame")
vendorInfoEvents:RegisterEvent("GET_ITEM_INFO_RECEIVED")
pcall(vendorInfoEvents.RegisterEvent, vendorInfoEvents, "ITEM_DATA_LOAD_RESULT")
vendorInfoEvents:SetScript("OnEvent", function(_, event, itemID, success)
    itemID = tonumber(itemID)
    if not itemID then return end
    -- Item cache completion can also resolve the real icon for virtualized rows.
    itemIconCache[itemID] = nil
    UI.itemClassCache[itemID] = nil
    UI.itemClassRequested[itemID] = nil
    UI.itemClassPendingIDs[itemID] = nil
    UI.itemClassFailed[itemID] = nil
    UI.vendorPriceRequested[itemID] = nil
    if success == false then
        UI.vendorPriceFailed[itemID] = true
        UI.vendorPriceCache[itemID] = nil
        UI.itemClassFailed[itemID] = true
    else
        UI.vendorPriceFailed[itemID] = nil
        local sellPrice = ReadVendorInfo(itemID)
        local classID = GetItemClassID(itemID, false)
        if classID == nil then UI.itemClassFailed[itemID] = true end
        if UI.itemTypeFilter and UI.itemTypeFilter ~= "all" and UI.activeTab == "market"
            and classID ~= nil then
            UI.itemTypeRefreshDueAt = Now() + 0.25
        end
        if sellPrice == nil then
            -- The client completed its item-data notification but still exposes no
            -- vendor value. Avoid repeatedly requesting the same unavailable item.
            UI.vendorPriceFailed[itemID] = true
        end
    end
    if UI.selectedItem and tonumber(UI.selectedItem.itemID) == itemID then
        SelectItem(UI.selectedItem)
    else
        UI.RenderRows()
    end
end)

local function NormalizeBuildKey(value)
    local text = tostring(value or "")
    local trailingNumber = text:match("(%d+)$")
    return trailingNumber or text
end

local function UpdateMetadata()
    local snapshot = GetSnapshot()
    local provider = MM.ProfessionData and MM.ProfessionData.GetFutureProviderStatus
        and MM.ProfessionData.GetFutureProviderStatus() or nil
    local currentBuild = provider and provider.currentBuild or nil
    local currentVersion, clientBuild
    if type(_G.GetBuildInfo) == "function" then
        local ok, version, build = pcall(_G.GetBuildInfo)
        if ok then currentVersion, clientBuild = version, build end
    end
    if not currentBuild and currentVersion and clientBuild then
        currentBuild = tostring(currentVersion) .. "." .. tostring(clientBuild)
    end
    if not snapshot then
        UI.metadata:SetText("No saved Auction House data")
        if UI.auctionDataLabel then UI.auctionDataLabel:SetText("Auction Data: unavailable") end
        if UI.auctionDataState then
            UI.auctionDataState:SetText("|cffffaa44Unknown|r")
        end
    else
        local age = math.max(0, (type(_G.time) == "function" and _G.time() or 0)
            - (tonumber(snapshot.timestamp) or 0))
        local ageText = age < 3600 and string.format("%dm", math.floor(age / 60))
            or (age < 86400 and string.format("%dh", math.floor(age / 3600))
            or string.format("%dd", math.floor(age / 86400)))
        local source = snapshot.source == "C_AuctionHouse.ReplicateItems" and "Full Market" or "Browse"
        UI.metadata:SetText(string.format("%s data · %s ago · %s auction records",
            source, ageText, tostring(snapshot.auctionCount or snapshot.resultCount or 0)))
        local snapshotBuild = tostring(snapshot.clientBuild or "UNKNOWN")
        local match = currentBuild and snapshot.clientBuild
            and NormalizeBuildKey(snapshotBuild) == NormalizeBuildKey(currentBuild)
        local stateText = match and "|cff55dd77Current|r"
            or (currentBuild and snapshot.clientBuild and "|cffffaa44Mismatch|r"
            or "|cffaaaaaaUnknown|r")
        local displayBuild = match and tostring(currentBuild) or snapshotBuild
        if UI.auctionDataLabel then
            UI.auctionDataLabel:SetText("Auction Data: " .. displayBuild)
        end
        if UI.auctionDataState then UI.auctionDataState:SetText(stateText) end
    end
    if UI.recipeDataLabel then
        if provider and provider.available then
            UI.recipeDataLabel:SetText("Recipe Data: " .. tostring(provider.datasetBuild or "UNKNOWN"))
            if UI.recipeDataState then
                UI.recipeDataState:SetText(provider.dataBuildMatchesClient
                    and "|cff55dd77Current|r" or "|cff79c9ffBaseline|r")
            end
            if UI.reviewDataLabel then
                UI.reviewDataLabel:SetText("Review records: " .. tostring(tonumber(provider.reviewWatchCount) or 0))
            end
        else
            UI.recipeDataLabel:SetText("Recipe Data: unavailable")
            if UI.recipeDataState then UI.recipeDataState:SetText("|cffffaa44Unknown|r") end
            if UI.reviewDataLabel then UI.reviewDataLabel:SetText("Review records: —") end
        end
    end
end

function UI.RefreshActions()
    if not UI.frame then return end
    local state = MM.Replicate and MM.Replicate.GetState and MM.Replicate.GetState() or {}
    local remaining = math.max(0, tonumber(state.cooldownRemaining) or 0)
    if UI.scanStateLabel then
        if state.pendingConfirmation then
            UI.scanStateLabel:SetText("|cffffc04dScan: Confirmation required|r")
        elseif state.active then
            UI.scanStateLabel:SetText("|cff55dd77Scan: Active|r")
        elseif state.attemptedThisSession then
            UI.scanStateLabel:SetText("|cffffaa44Scan: Used this session|r")
        elseif remaining > 0 then
            UI.scanStateLabel:SetText("|cffaaaaaaScan: Cooldown|r")
        else
            UI.scanStateLabel:SetText("|cff55dd77Scan: Idle|r")
        end
    end
    if state.pendingConfirmation then
        UI.confirmButton:Show()
        UI.cancelButton:Show()
    else
        UI.confirmButton:Hide()
        UI.cancelButton:Hide()
    end
    if state.active then
        UI.scanButton:SetText("Scanning…")
        UI.scanButton:SetEnabled(false)
    elseif state.pendingConfirmation then
        UI.scanButton:SetText("Review scan warning")
        UI.scanButton:SetEnabled(false)
    elseif state.attemptedThisSession then
        UI.scanButton:SetText("Scan already used")
        UI.scanButton:SetEnabled(false)
    elseif remaining > 0 then
        if remaining >= 60 then
            UI.scanButton:SetText(string.format("Scan in %dm", math.ceil(remaining / 60)))
        else
            UI.scanButton:SetText(string.format("Scan in %ds", math.ceil(remaining)))
        end
        UI.scanButton:SetEnabled(false)
    else
        UI.scanButton:SetText("Update full market")
        UI.scanButton:SetEnabled(true)
    end
end

function UI.Refresh()
    if not UI.frame then return end
    UpdateMetadata()
    if MM.ProfessionData and MM.ProfessionData.GetFutureProviderStatus then
        local provider = MM.ProfessionData.GetFutureProviderStatus()
        if not provider.available and UI.status then
            SetStatus(provider.status .. " · known recipes remain available")
        end
    end
    local snapshot = GetSnapshot()
    if snapshot ~= UI.catalogSnapshot then
        StartCatalog(snapshot)
    elseif not UI.catalogBuild and not UI.economicsIndexBuild and not UI.viewBuild and not UI.rankSort then
        UI.StartViewBuild()
    end
    UI.RefreshActions()
end

function UI.SetStatus(message)
    SetStatus(message)
end

local function UpdateHeaderIndicators()
    local sort = UI.sortByTab[UI.activeTab] or { key = "name", ascending = true }
    for _, header in ipairs(UI.headerButtons or {}) do
        local label = header.baseLabel or ""
        if header.label then header.label:SetText(label) end
        if header.sortIndicator then
            if header.sortKey == sort.key then
                header.sortIndicator:SetTexture(sort.ascending
                    and "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up"
                    or "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
                -- Crop the square scrollbar-button border so only its direction
                -- triangle is visible beside the sorted column heading.
                header.sortIndicator:SetTexCoord(0.2, 0.8, 0.2, 0.8)
                header.sortIndicator:Show()
            else
                header.sortIndicator:Hide()
            end
        end
    end
end


local function ShowMarketItemTooltip(owner, item, showRecipe)
    if not _G.GameTooltip or type(item) ~= "table" then return end
    local itemID = tonumber(item.itemID)
    local recipeID = tonumber(item.recipeID)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if type(GameTooltip.SetFrameStrata) == "function" then GameTooltip:SetFrameStrata("TOOLTIP") end
    if type(GameTooltip.SetFrameLevel) == "function" then
        local ownerLevel = owner and type(owner.GetFrameLevel) == "function" and owner:GetFrameLevel() or 1
        local tooltipLevel = type(GameTooltip.GetFrameLevel) == "function" and GameTooltip:GetFrameLevel() or 1
        GameTooltip:SetFrameLevel(math.max(tooltipLevel, ownerLevel + 100))
    end
    local shown = false
    if showRecipe and recipeID then
        if type(GameTooltip.SetSpellByID) == "function" then
            local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, recipeID)
            shown = ok and type(GameTooltip.NumLines) == "function" and (GameTooltip:NumLines() or 0) > 0
        end
        if not shown and type(GameTooltip.SetHyperlink) == "function" then
            local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. recipeID)
            shown = ok and type(GameTooltip.NumLines) == "function" and (GameTooltip:NumLines() or 0) > 0
        end
    end
    if not shown and itemID then
        if type(GameTooltip.SetItemByID) == "function" then
            local ok = pcall(GameTooltip.SetItemByID, GameTooltip, itemID)
            shown = ok and type(GameTooltip.NumLines) == "function" and (GameTooltip:NumLines() or 0) > 0
        end
        if not shown and type(GameTooltip.SetHyperlink) == "function" then
            local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. itemID)
            shown = ok and type(GameTooltip.NumLines) == "function" and (GameTooltip:NumLines() or 0) > 0
        end
    end
    if not shown then
        GameTooltip:ClearLines()
        GameTooltip:SetText(GetItemName(item))
    end
    if showRecipe and recipeID then
        if item.professionName then
            GameTooltip:AddLine(tostring(item.professionName)
                .. " · Skill " .. tostring(item.professionSkill or "?"), 0.8, 0.8, 0.8, true)
        end
        local sourceLines = {}
        AppendPrimaryAcquisitionLines(sourceLines, item.recipeData or {}, item)
        for _, line in ipairs(sourceLines) do GameTooltip:AddLine(line, 0.9, 0.9, 0.9, true) end
    elseif item.recipeID then
        GameTooltip:AddLine("Recipe: " .. tostring(item.recipeName or item.recipeID), 0.8, 0.8, 0.8, true)
    end
    GameTooltip:Show()
end

local function AttachFilterTooltip(region, title, body)
    if not region or not body then return end
    region:SetScript("OnEnter", function(self) RaiseMarketTooltip(self, title, body) end)
    region:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
end

local function SetTab(tab)
    local previousTab = UI.activeTab
    UI.tabFilterState[previousTab] = UI.tabFilterState[previousTab] or {}
    UI.tabFilterState[previousTab].search = UI.search and UI.search:GetText() or ""
    UI.tabFilterState[previousTab].profession = UI.professionFilter
    UI.tabFilterState[previousTab].role = UI.itemRoleFilter
    UI.tabFilterState[previousTab].itemType = UI.itemTypeFilter
    UI.tabFilterState[previousTab].economicsFilters = {
        crafted = UI.economicsFilters.crafted, gathered = UI.economicsFilters.gathered,
        material = UI.economicsFilters.material, other = UI.economicsFilters.other,
    }
    UI.tabFilterState[previousTab].craftFilters = {
        craftableOnly = UI.craftFilters.craftableOnly,
        profitableOnly = UI.craftFilters.profitableOnly,
        reviewOnly = UI.craftFilters.reviewOnly,
        hideLowProfit = UI.craftFilters.hideLowProfit,
    }
    UI.tabFilterState[previousTab].marketQuickFilters = {
        craftingMaterialsOnly = UI.marketQuickFilters.craftingMaterialsOnly,
        lowSupplyOnly = UI.marketQuickFilters.lowSupplyOnly,
        highProfitOnly = UI.marketQuickFilters.highProfitOnly,
        reviewOnly = UI.marketQuickFilters.reviewOnly,
    }
    if UI.selectedItem then
        UI.selectedByTab[previousTab] = { itemID = tonumber(UI.selectedItem.itemID), recipeKey = UI.selectedItem.recipeKey }
    end
    UI.CloseDropdownMenus()
    UI.activeTab = tab
    if tab ~= "economics" then UI.economicsIndexBuild = nil end
    local saved = UI.tabFilterState[tab] or {}
    UI.professionFilter = tonumber(saved.profession) or 0
    UI.itemRoleFilter = saved.role or "all"
    UI.itemTypeFilter = saved.itemType or "all"
    local savedEconomics = saved.economicsFilters or {}
    UI.economicsFilters.crafted = savedEconomics.crafted == true
    UI.economicsFilters.gathered = savedEconomics.gathered == true
    UI.economicsFilters.material = savedEconomics.material == true
    UI.economicsFilters.other = savedEconomics.other == true
    local savedCraft = saved.craftFilters or {}
    UI.craftFilters.craftableOnly = savedCraft.craftableOnly == true
    UI.craftFilters.profitableOnly = savedCraft.profitableOnly == true
    UI.craftFilters.reviewOnly = savedCraft.reviewOnly == true
    UI.craftFilters.hideLowProfit = savedCraft.hideLowProfit == true
    local savedMarket = saved.marketQuickFilters or {}
    UI.marketQuickFilters.craftingMaterialsOnly = savedMarket.craftingMaterialsOnly == true
    UI.marketQuickFilters.lowSupplyOnly = savedMarket.lowSupplyOnly == true
    UI.marketQuickFilters.highProfitOnly = savedMarket.highProfitOnly == true
    UI.marketQuickFilters.reviewOnly = savedMarket.reviewOnly == true
    if UI.search then UI.search:SetText(saved.search or "") end
    local tabTitle = tab == "market" and "All Items"
        or (tab == "crafts" and "Crafts"
        or (tab == "low" and "Low Supply" or tab:gsub("^%l", string.upper)))
    if UI.centerHeading then UI.centerHeading:SetText(tabTitle) end
    if UI.filterHeading then UI.filterHeading:SetText("Filters — " .. tabTitle) end
    if UI.professionDropdown and UI.professionDropdown.RefreshText then UI.professionDropdown.RefreshText() end
    for name, button in pairs(UI.tabs) do
        if name == tab then
            button:Disable()
            if button.selectedMark then button.selectedMark:Show() end
            if button.background then button.background:SetColorTexture(0.28, 0.185, 0.060, 1) end
            if button.marketTop then button.marketTop:SetColorTexture(0.98, 0.76, 0.30, 1) end
            if button.marketBottom then button.marketBottom:SetColorTexture(0.34, 0.22, 0.065, 1) end
            if button.marketLeft then button.marketLeft:SetColorTexture(0.86, 0.64, 0.25, 1) end
            if button.marketRight then button.marketRight:SetColorTexture(0.34, 0.22, 0.065, 1) end
        else
            button:Enable()
            if button.selectedMark then button.selectedMark:Hide() end
            if button.background then button.background:SetColorTexture(0.022, 0.020, 0.018, 0.99) end
            if button.marketTop then button.marketTop:SetColorTexture(0.48, 0.36, 0.18, 0.92) end
            if button.marketBottom then button.marketBottom:SetColorTexture(0.12, 0.085, 0.035, 0.98) end
            if button.marketLeft then button.marketLeft:SetColorTexture(0.44, 0.32, 0.13, 0.82) end
            if button.marketRight then button.marketRight:SetColorTexture(0.08, 0.06, 0.025, 0.98) end
        end
    end

    local craftTab = tab == "crafts"
    local labels = { "Item / Recipe", "Cheapest", "Materials", "At Price", "Total", "Profit / Craft" }
    local keys = { "name", "price", "materials", "depth", "total", "profit" }
    if craftTab then
        labels = { "Recipe", "Materials (cost)", "Sale / Unit", "At Price", "Total", "Profit / Craft" }
        keys = { "name", "materials", "price", "depth", "total", "profit" }
    elseif tab == "economics" then
        labels = { "Item", "Cheapest", "Craft cost", "Price change", "Total units", "Best craft profit" }
        keys = { "name", "price", "materials", "change", "total", "profit" }
    elseif tab == "materials" then
        labels = { "Item", "Cheapest", "At Price", "Total Units", "Best Craft Profit" }
        keys = { "name", "price", "depth", "total", "profit" }
    elseif tab == "low" then
        labels = { "Item", "Cheapest", "At Price", "Total Units", "Listings", "Best Craft Profit" }
        keys = { "name", "price", "depth", "total", "total", "profit" }
    elseif tab == "history" then
        labels = { "Item", "Cheapest", "Price Change", "Latest Units", "Total", "Best Craft Profit" }
        keys = { "name", "price", "change", "total", "total", "profit" }
    else
        labels = { "Item", "Cheapest", "At Price", "Total Units", "Listings", "Best Craft Profit" }
        keys = { "name", "price", "depth", "total", "total", "profit" }
    end
    for i = 1, #UI.headerButtons do
        local header = UI.headerButtons[i]
        header.baseLabel = labels[i]
        header.label:SetText(labels[i] or "")
        header.sortKey = keys[i]
        if labels[i] then header:Show() else header:Hide() end
    end
    if craftTab then
        local craftColumns = {
            { x = 302, w = 205, justify = "LEFT" },
            { x = 510, w = 166, justify = "LEFT" },
            { x = 680, w = 96, justify = "RIGHT" },
            { x = 782, w = 70, justify = "RIGHT" },
            { x = 858, w = 70, justify = "RIGHT" },
            { x = 920, w = 170, justify = "RIGHT" },
        }
        for i, column in ipairs(craftColumns) do
            local header = UI.headerButtons[i]
            header:ClearAllPoints(); header:SetPoint("TOPLEFT", UI.frame, "TOPLEFT", column.x, -218); header:SetWidth(column.w)
            header.label:SetWidth(column.w - 14); header.label:SetJustifyH(column.justify)
        end
        for _, row in ipairs(UI.rows or {}) do
            row.name:ClearAllPoints(); row.name:SetPoint("LEFT", row, "LEFT", 27, 0); row.name:SetWidth(180)
            row.depth:ClearAllPoints(); row.depth:SetPoint("LEFT", row, "LEFT", 212, 0); row.depth:SetWidth(160)
            row.price:ClearAllPoints(); row.price:SetPoint("LEFT", row, "LEFT", 382, 0); row.price:SetWidth(96)
            row.atPrice:ClearAllPoints(); row.atPrice:SetPoint("LEFT", row, "LEFT", 484, 0); row.atPrice:SetWidth(70)
            row.total:ClearAllPoints(); row.total:SetPoint("LEFT", row, "LEFT", 560, 0); row.total:SetWidth(70)
            row.profit:ClearAllPoints(); row.profit:SetPoint("RIGHT", row, "RIGHT", -4, 0); row.profit:SetWidth(170)
        end
    elseif tab == "economics" then
        local economicsColumns = {
            { x = 302, w = 205, justify = "LEFT" },
            { x = 510, w = 105, justify = "RIGHT" },
            { x = 620, w = 150, justify = "RIGHT" },
            { x = 776, w = 72, justify = "RIGHT" },
            { x = 852, w = 72, justify = "RIGHT" },
            { x = 914, w = 176, justify = "RIGHT" },
        }
        for i, column in ipairs(economicsColumns) do
            local header = UI.headerButtons[i]
            header:ClearAllPoints(); header:SetPoint("TOPLEFT", UI.frame, "TOPLEFT", column.x, -218); header:SetWidth(column.w)
            header.label:SetWidth(column.w - 14); header.label:SetJustifyH(column.justify)
        end
        for _, row in ipairs(UI.rows or {}) do
            row.total:Show()
            row.name:ClearAllPoints(); row.name:SetPoint("LEFT", row, "LEFT", 27, 0); row.name:SetWidth(182)
            row.price:ClearAllPoints(); row.price:SetPoint("LEFT", row, "LEFT", 212, 0); row.price:SetWidth(105)
            row.depth:ClearAllPoints(); row.depth:SetPoint("LEFT", row, "LEFT", 322, 0); row.depth:SetWidth(150)
            row.atPrice:ClearAllPoints(); row.atPrice:SetPoint("LEFT", row, "LEFT", 478, 0); row.atPrice:SetWidth(72)
            row.total:ClearAllPoints(); row.total:SetPoint("LEFT", row, "LEFT", 554, 0); row.total:SetWidth(72)
            row.profit:ClearAllPoints(); row.profit:SetPoint("RIGHT", row, "RIGHT", -4, 0); row.profit:SetWidth(176)
        end
    elseif tab == "materials" then
        local materialColumns = {
            { x = 302, w = 205, justify = "LEFT" },
            { x = 510, w = 105, justify = "RIGHT" },
            { x = 620, w = 150, justify = "RIGHT" },
            { x = 776, w = 72, justify = "RIGHT" },
            { x = 836, w = 254, justify = "RIGHT" },
        }
        for i, column in ipairs(materialColumns) do
            local header = UI.headerButtons[i]
            header:ClearAllPoints(); header:SetPoint("TOPLEFT", UI.frame, "TOPLEFT", column.x, -218); header:SetWidth(column.w)
            header.label:SetWidth(column.w - 14); header.label:SetJustifyH(column.justify)
        end
        UI.headerButtons[6]:Hide()
        for _, row in ipairs(UI.rows or {}) do
            row.name:ClearAllPoints(); row.name:SetPoint("LEFT", row, "LEFT", 27, 0); row.name:SetWidth(182)
            row.price:ClearAllPoints(); row.price:SetPoint("LEFT", row, "LEFT", 212, 0); row.price:SetWidth(105)
            row.depth:ClearAllPoints(); row.depth:SetPoint("LEFT", row, "LEFT", 322, 0); row.depth:SetWidth(150)
            row.atPrice:ClearAllPoints(); row.atPrice:SetPoint("LEFT", row, "LEFT", 478, 0); row.atPrice:SetWidth(72)
            row.total:Hide()
            row.profit:ClearAllPoints(); row.profit:SetPoint("RIGHT", row, "RIGHT", -4, 0); row.profit:SetWidth(254)
        end
    else
        local marketColumns = {
            { x = 302, w = 205, justify = "LEFT" },
            { x = 510, w = 105, justify = "RIGHT" },
            { x = 620, w = 150, justify = "RIGHT" },
            { x = 776, w = 72, justify = "RIGHT" },
            { x = 852, w = 72, justify = "RIGHT" },
            { x = 914, w = 176, justify = "RIGHT" },
        }
        for i, column in ipairs(marketColumns) do
            local header = UI.headerButtons[i]
            header:ClearAllPoints(); header:SetPoint("TOPLEFT", UI.frame, "TOPLEFT", column.x, -218); header:SetWidth(column.w)
            header.label:SetWidth(column.w - 14); header.label:SetJustifyH(column.justify)
        end
        for _, row in ipairs(UI.rows or {}) do
            row.total:Show()
            row.name:ClearAllPoints(); row.name:SetPoint("LEFT", row, "LEFT", 27, 0); row.name:SetWidth(182)
            row.price:ClearAllPoints(); row.price:SetPoint("LEFT", row, "LEFT", 212, 0); row.price:SetWidth(105)
            row.depth:ClearAllPoints(); row.depth:SetPoint("LEFT", row, "LEFT", 322, 0); row.depth:SetWidth(150)
            row.atPrice:ClearAllPoints(); row.atPrice:SetPoint("LEFT", row, "LEFT", 478, 0); row.atPrice:SetWidth(72)
            row.total:ClearAllPoints(); row.total:SetPoint("LEFT", row, "LEFT", 554, 0); row.total:SetWidth(72)
            row.profit:ClearAllPoints(); row.profit:SetPoint("RIGHT", row, "RIGHT", -4, 0); row.profit:SetWidth(176)
        end
    end
    if UI.roleLabel then
        UI.roleLabel:SetText(craftTab and "Recipe status"
            or (tab == "materials" and "Material relationship" or "Item role"))
    end
    UpdateHeaderIndicators()

    if UI.roleDropdown then
        UI.roleDropdown:Enable()
        if UI.roleDropdown.RefreshText then UI.roleDropdown.RefreshText() end
    end
    local showItemTypeFilter = tab == "market"
    if UI.itemTypeLabel then
        if showItemTypeFilter then UI.itemTypeLabel:Show() else UI.itemTypeLabel:Hide() end
    end
    if UI.itemTypeDropdown then
        if showItemTypeFilter then UI.itemTypeDropdown:Show() else UI.itemTypeDropdown:Hide() end
        if UI.itemTypeDropdown.RefreshText then UI.itemTypeDropdown.RefreshText() end
    end
    local showCraftFilters = tab == "crafts"
    if UI.craftFilterHeading then
        if showCraftFilters then UI.craftFilterHeading:Show() else UI.craftFilterHeading:Hide() end
    end
    for key, control in pairs(UI.craftFilterControls or {}) do
        if showCraftFilters then control:Show() else control:Hide() end
        if control.SetChecked then control:SetChecked(UI.craftFilters[key] == true) end
        if control.label then
            if showCraftFilters then control.label:Show() else control.label:Hide() end
        end
    end
    local showEconomicsFilters = tab == "economics"
    if UI.economicsFilterHeading then
        if showEconomicsFilters then UI.economicsFilterHeading:Show() else UI.economicsFilterHeading:Hide() end
    end
    for key, control in pairs(UI.economicsFilterControls or {}) do
        if showEconomicsFilters then control:Show() else control:Hide() end
        if control.SetChecked then control:SetChecked(UI.economicsFilters[key] == true) end
        if control.label then
            if showEconomicsFilters then control.label:Show() else control.label:Hide() end
        end
    end
    local showMarketQuickFilters = tab == "market"
    if UI.marketQuickFilterHeading then
        if showMarketQuickFilters then UI.marketQuickFilterHeading:Show()
        else UI.marketQuickFilterHeading:Hide() end
    end
    for key, control in pairs(UI.marketQuickFilterControls or {}) do
        if showMarketQuickFilters then control:Show() else control:Hide() end
        if control.SetChecked then control:SetChecked(UI.marketQuickFilters[key] == true) end
        if control.label then
            if showMarketQuickFilters then control.label:Show() else control.label:Hide() end
        end
    end
    if UI.detailHeading then UI.detailHeading:SetText(craftTab and "Selected Recipe" or "Selected Item") end
    if UI.detailName then UI.detailName:SetText("Loading selection…") end
    if UI.detailIcon then UI.detailIcon:Hide() end
    if UI.detailBadges then UI.detailBadges:SetText("") end
    if UI.detailPrice then UI.detailPrice:SetText("—") end
    if UI.detailSupply then UI.detailSupply:SetText("—") end
    if UI.detailVariants then UI.detailVariants:SetText("") end
    if UI.marketInfoHeading then
        UI.marketInfoHeading:SetText(craftTab and "Craft Economics" or "Market Information")
    end
    if UI.relationshipHeading then
        UI.relationshipHeading:SetText(craftTab and "Recipe Details" or "Relationships")
    end
    if UI.detailProfitLabel then
        UI.detailProfitLabel:SetText(craftTab and "PROFIT / CRAFT" or "BEST CRAFT PROFIT")
    end
    if UI.detailProfit then UI.detailProfit:SetText("—") end
    SetDetailEconomics(craftTab
        and ("All supported recipes. Known, learnable and unavailable recipes are grouped by your professions.")
        or (tab == "materials" and "Materials used by known and supported unlearned recipes."
            or "Select an item to inspect its market, vendor value and recipe relationships."))
    if UI.historyGraph then
        for _, bar in ipairs(UI.historyBars or {}) do bar:Hide() end
    end
    UI.StartViewBuild()
end

local function ApplyBackgroundOpacity(frame, alpha)
    -- This is intentionally whole-window opacity: panels, borders, controls,
    -- text and data all fade together. Tooltips are independent UI elements.
    alpha = math.max(0.35, math.min(1.0, tonumber(alpha) or 0.85))
    if type(MM.db) == "table" then MM.db.backgroundOpacity = alpha end
    if frame and type(frame.SetAlpha) == "function" then frame:SetAlpha(alpha) end
    if UI.opacityValue then UI.opacityValue:SetText(string.format("%d%%", math.floor(alpha * 100 + 0.5))) end
    return alpha
end

local function CreateUI()
    if UI.frame then return UI.frame end
    local frame = CreateFrame("Frame", "ModuloMarketMainFrame", UIParent, "BasicFrameTemplateWithInset")
    -- Keep the template's functional close control and title text, but remove its
    -- decorative perimeter/inset chrome. ModuloMarket draws its own inner panels.
    for _, chromeKey in ipairs({ "NineSlice", "Inset", "TitleBg", "TopTileStreaks" }) do
        local chrome = frame[chromeKey]
        if chrome and chrome.Hide then chrome:Hide() end
    end
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    UI.craftingScope = (MM.db and MM.db.craftingScope == "character") and "character" or "account"
    if type(MM.db) == "table" then MM.db.craftingScope = UI.craftingScope end
    local initialOpacity = ApplyBackgroundOpacity(frame,
        MM.db and MM.db.backgroundOpacity or 0.85)
    frame:SetSize(1460, 850)
    if type(_G.GetScreenWidth) == "function" and type(_G.GetScreenHeight) == "function" then
        local screenWidth, screenHeight = _G.GetScreenWidth(), _G.GetScreenHeight()
        if tonumber(screenWidth) and tonumber(screenHeight) then
            local fitScale = math.min(1, (screenWidth - 40) / 1460, (screenHeight - 40) / 850)
            frame:SetScale(math.max(0.70, fitScale))
        end
    end
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    local titlePlate = frame:CreateTexture(nil, "BACKGROUND")
    titlePlate:SetColorTexture(0.028, 0.020, 0.009, 1)
    titlePlate:SetPoint("TOP", frame, "TOP", 0, -2)
    titlePlate:SetSize(340, 36)
    AddBevelBorder(frame, 560, -2, 340, 36, "plaque", "BORDER")
    local titleInner = frame:CreateTexture(nil, "ARTWORK")
    titleInner:SetColorTexture(0.16, 0.105, 0.035, 0.28)
    titleInner:SetPoint("TOPLEFT", titlePlate, "TOPLEFT", 5, -5)
    titleInner:SetPoint("BOTTOMRIGHT", titlePlate, "BOTTOMRIGHT", -5, 5)
    local titleAccentLeft = frame:CreateTexture(nil, "ARTWORK")
    titleAccentLeft:SetColorTexture(0.86, 0.67, 0.29, 0.95)
    titleAccentLeft:SetSize(5, 5)
    titleAccentLeft:SetPoint("LEFT", titlePlate, "LEFT", 8, 0)
    local titleAccentRight = frame:CreateTexture(nil, "ARTWORK")
    titleAccentRight:SetColorTexture(0.86, 0.67, 0.29, 0.95)
    titleAccentRight:SetSize(5, 5)
    titleAccentRight:SetPoint("RIGHT", titlePlate, "RIGHT", -8, 0)
    AddInsetSurface(frame, 18, -30, 1424, 78, {0.018, 0.016, 0.012, 0.86})
    AddBevelBorder(frame, 18, -30, 1424, 78, "panel", "BORDER")
    frame.TitleText:ClearAllPoints()
    frame.TitleText:SetPoint("CENTER", titlePlate, "CENTER", 0, 0)
    frame.TitleText:SetSize(310, 28)
    frame.TitleText:SetText("Modulo Market")
    if frame.TitleText.SetFontObject then frame.TitleText:SetFontObject("GameFontNormalLarge") end
    if frame.TitleText.SetTextColor then frame.TitleText:SetTextColor(1, 0.82, 0.12) end
    frame:Hide()
    _G.UISpecialFrames = _G.UISpecialFrames or {}
    local specialFrameRegistered = false
    for _, name in ipairs(_G.UISpecialFrames) do
        if name == "ModuloMarketMainFrame" then specialFrameRegistered = true; break end
    end
    if not specialFrameRegistered then
        _G.UISpecialFrames[#_G.UISpecialFrames + 1] = "ModuloMarketMainFrame"
    end

    AddInsetSurface(frame, 22, -34, 398, 22, {0.012, 0.011, 0.009, 0.96})
    AddBevelBorder(frame, 22, -34, 398, 22, "control", "BORDER")
    AddInsetSurface(frame, 430, -34, 278, 22, {0.012, 0.011, 0.009, 0.96})
    AddBevelBorder(frame, 430, -34, 278, 22, "control", "BORDER")
    UI.metadata = AddLabel(frame, "Loading market data…", 30, -38, 382, 18, "GameFontNormal")
    IncreaseFontSize(UI.metadata, 1)
    UI.scanStateLabel = AddLabel(frame, "Scan: Idle", 442, -38, 254, 18, "GameFontNormal")
    IncreaseFontSize(UI.scanStateLabel, 1)
    UI.status = AddLabel(frame, "Ready", 28, -92, 1390, 18, "GameFontDisableSmall")
    UI.status:SetWordWrap(false)
    UI.statusTooltip = CreateFrame("Button", nil, frame)
    UI.statusTooltip:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -92)
    UI.statusTooltip:SetSize(1400, 18)
    UI.statusTooltip:SetFrameLevel(frame:GetFrameLevel() + 2)
    UI.statusTooltip:SetScript("OnEnter", function(self)
        if not _G.GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Market status", 1, 0.82, 0.15)
        GameTooltip:AddLine(UI.statusMessage or "", 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    UI.statusTooltip:SetScript("OnLeave", function()
        if _G.GameTooltip then GameTooltip:Hide() end
    end)
    if MM.ForeverDBData and MM.ForeverDBData.meta then
        UI.attribution = AddLabel(frame,
            "|cff66ccffData from ForeverDB.net — https://foreverdb.net|r",
            24, -830, 650, 14, "GameFontDisableSmall")
    end
    local clientVersion, clientBuild
    if type(_G.GetBuildInfo) == "function" then
        local ok, version, build = pcall(_G.GetBuildInfo)
        if ok then clientVersion, clientBuild = version, build end
    end
    local versionLabel = "ModuloMarket v" .. tostring(MM.version or "UNKNOWN")
    if clientVersion and clientBuild then
        versionLabel = versionLabel .. string.format(" · Client %s build %s", clientVersion, tostring(clientBuild))
    end
    UI.versionLabel = AddLabel(frame, versionLabel, 1085, -830, 340, 14, "GameFontDisableSmall")
    UI.scanButton = AddButton(frame, "Update Full Market", 190, 24, -62, function()
        if MM.Replicate then MM.Replicate.Prepare() end
        UI.RefreshActions()
    end)
    UI.confirmButton = AddButton(frame, "Confirm full scan", 150, 225, -62, function()
        if MM.Replicate then MM.Replicate.Confirm() end
        UI.RefreshActions()
    end)
    UI.cancelButton = AddButton(frame, "Cancel", 80, 385, -62, function()
        if MM.Replicate then MM.Replicate.CancelPrepare() end
        UI.RefreshActions()
    end)
    UI.confirmButton:Hide()
    UI.cancelButton:Hide()
    UI.browseButton = AddButton(frame, "Browse Scan", 150, 485, -62, function()
        frame:Hide()
        if MM.Scanner and MM.Scanner.Toggle then MM.Scanner.Toggle() end
    end)
    AddButton(frame, "Close", 80, 645, -62, function() frame:Hide() end)

    UI.opacityLabel = AddLabel(frame, "Window opacity", 1250, -36, 126, 18, "GameFontNormalSmall")
    UI.opacityLabel:SetJustifyH("CENTER")
    IncreaseFontSize(UI.opacityLabel, 1)
    UI.opacitySlider = CreateFrame("Slider", nil, frame)
    UI.opacitySlider:SetSize(108, 14)
    UI.opacitySlider:SetPoint("TOPLEFT", frame, "TOPLEFT", 1258, -60)
    UI.opacitySlider:SetOrientation("HORIZONTAL")
    UI.opacitySlider:SetMinMaxValues(0.35, 1.0)
    UI.opacitySlider:SetValueStep(0.05)
    UI.opacitySlider:SetObeyStepOnDrag(true)
    UI.opacitySlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local opacityTrack = UI.opacitySlider:CreateTexture(nil, "BACKGROUND")
    opacityTrack:SetColorTexture(0.20, 0.17, 0.13, 0.95)
    opacityTrack:SetPoint("LEFT", UI.opacitySlider, "LEFT", 0, 0)
    opacityTrack:SetPoint("RIGHT", UI.opacitySlider, "RIGHT", 0, 0)
    opacityTrack:SetHeight(6)
    UI.opacityValue = AddLabel(frame, "", 1380, -36, 42, 18, "GameFontHighlightSmall")
    ApplyBackgroundOpacity(frame, initialOpacity)
    UI.opacitySlider:SetValue(initialOpacity)
    UI.opacitySlider:SetScript("OnValueChanged", function(_, value)
        ApplyBackgroundOpacity(frame, value)
    end)

    local tabStrip = frame:CreateTexture(nil, "BACKGROUND")
    tabStrip:SetColorTexture(0.045, 0.035, 0.025, 0.95)
    tabStrip:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -112)
    tabStrip:SetSize(1424, 34)
    AddBevelBorder(frame, 18, -112, 1424, 34, "panel", "BORDER")
    UI.tabs = {}
    local tabSpecs = {
        { "market", "All Items", 194 },
        { "economics", "Economics", 194 },
        { "crafts", "Crafts", 194 },
        { "materials", "Materials", 194 },
        { "low", "Low Supply", 194 },
        { "history", "History", 194 },
    }
    local tabX = 22
    for _, spec in ipairs(tabSpecs) do
        local key, label, width = spec[1], spec[2], spec[3]
        local button = CreateFrame("Button", nil, frame)
        button:SetSize(width, 30)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", tabX, -114)
        button.background = button:CreateTexture(nil, "BACKGROUND")
        button.background:SetAllPoints(button)
        button.background:SetColorTexture(0.035, 0.029, 0.020, 0.98)
        button.marketTop = button:CreateTexture(nil, "BORDER")
        button.marketTop:SetColorTexture(0.62, 0.46, 0.20, 0.82)
        button.marketTop:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        button.marketTop:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
        button.marketTop:SetHeight(1)
        button.marketBottom = button:CreateTexture(nil, "BORDER")
        button.marketBottom:SetColorTexture(0.12, 0.085, 0.035, 0.98)
        button.marketBottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
        button.marketBottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        button.marketBottom:SetHeight(1)
        button.marketLeft = button:CreateTexture(nil, "BORDER")
        button.marketLeft:SetColorTexture(0.44, 0.32, 0.13, 0.82)
        button.marketLeft:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        button.marketLeft:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
        button.marketLeft:SetWidth(1)
        button.marketRight = button:CreateTexture(nil, "BORDER")
        button.marketRight:SetColorTexture(0.08, 0.06, 0.025, 0.98)
        button.marketRight:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
        button.marketRight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        button.marketRight:SetWidth(1)
        button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
        button.highlight:SetAllPoints(button)
        button.highlight:SetColorTexture(0.65, 0.48, 0.18, 0.22)
        button.selectedMark = button:CreateTexture(nil, "ARTWORK")
        button.selectedMark:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        button.selectedMark:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        button.selectedMark:SetHeight(3)
        button.selectedMark:SetColorTexture(1, 0.72, 0.18, 1)
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        button.label:SetPoint("CENTER")
        button.label:SetText(label)
        IncreaseFontSize(button.label, 1)
        button.label:SetTextColor(0.96, 0.89, 0.72)
        button.tabKey = key
        button:SetScript("OnClick", function() SetTab(key) end)
        if key == "market" then
            button.tooltipText = "Every item in the saved Auction House market snapshot."
        elseif key == "economics" then
            button.tooltipText = "Market analysis with price movement, best craft cost/profit and relationship filters. Drop and item-vendor source filters remain unavailable until reliable item-acquisition data is mapped."
        elseif key == "crafts" then
            button.tooltipText = "All supported profession recipes, grouped by whether you know them, can learn them with your professions, or lack the required profession."
        elseif key == "materials" then
            button.tooltipText = "Items used as reagents by known or supported unlearned recipes, with their market value and recipe relationships."
        elseif key == "low" then
            button.tooltipText = "Low-supply items, including crafting materials. Supply thresholds adjust for materials and stackable goods."
        elseif key == "history" then
            button.tooltipText = "Compare recent saved market prices and supply. Each completed full scan adds a point."
        end
        if button.tooltipText then
            button:SetScript("OnEnter", function(self)
                RaiseMarketTooltip(self, label, self.tooltipText)
            end)
            button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        UI.tabs[key] = button
        if key == UI.activeTab then
            button.selectedMark:Show()
            button.background:SetColorTexture(0.22, 0.15, 0.055, 1)
            button:Disable()
        else
            button.selectedMark:Hide()
        end
        tabX = tabX + width + 4
    end

    local leftPanel = frame:CreateTexture(nil, "BACKGROUND")
    leftPanel:SetColorTexture(0.035, 0.032, 0.028, 0.92)
    leftPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -158)
    leftPanel:SetSize(260, 650)
    local centerPanel = frame:CreateTexture(nil, "BACKGROUND")
    centerPanel:SetColorTexture(0.025, 0.026, 0.028, 0.90)
    centerPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 286, -158)
    centerPanel:SetSize(834, 650)
    local rightPanel = frame:CreateTexture(nil, "BACKGROUND")
    rightPanel:SetColorTexture(0.035, 0.032, 0.028, 0.92)
    rightPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 1126, -158)
    rightPanel:SetSize(300, 650)
    local function AddPanelBorder(x, y, width, height)
        AddBevelBorder(frame, x, y, width, height, "panel", "BORDER")
    end
    local function AddPanelInnerEdge(x, y, width, height)
        local sheen = frame:CreateTexture(nil, "ARTWORK")
        sheen:SetColorTexture(0.62, 0.47, 0.22, 0.055)
        sheen:SetPoint("TOPLEFT", frame, "TOPLEFT", x + 2, y - 2)
        sheen:SetSize(width - 4, 18)
        local inner = frame:CreateTexture(nil, "ARTWORK")
        inner:SetColorTexture(0.0, 0.0, 0.0, 0.42)
        inner:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x + 2, y - height + 2)
        inner:SetSize(width - 4, 12)
        AddPanelBorder(x, y, width, height)
    end
    AddPanelInnerEdge(18, -158, 260, 650)
    AddPanelInnerEdge(286, -158, 834, 650)
    AddPanelInnerEdge(1126, -158, 300, 650)
    local function AddPanelHeader(x, y, width)
        local plate = frame:CreateTexture(nil, "ARTWORK")
        plate:SetColorTexture(0.15, 0.105, 0.045, 0.78)
        plate:SetPoint("TOPLEFT", frame, "TOPLEFT", x + 2, y - 1)
        plate:SetSize(width - 4, 27)
        local upper = frame:CreateTexture(nil, "ARTWORK")
        upper:SetColorTexture(0.52, 0.38, 0.15, 0.20)
        upper:SetPoint("TOPLEFT", plate, "TOPLEFT", 0, 0)
        upper:SetPoint("TOPRIGHT", plate, "TOPRIGHT", 0, 0)
        upper:SetHeight(9)
        local rule = frame:CreateTexture(nil, "ARTWORK")
        rule:SetColorTexture(0.78, 0.58, 0.25, 0.82)
        rule:SetPoint("TOPLEFT", plate, "BOTTOMLEFT", 0, 0)
        rule:SetSize(width - 4, 1)
        local lowerRule = frame:CreateTexture(nil, "ARTWORK")
        lowerRule:SetColorTexture(0.025, 0.018, 0.009, 1)
        lowerRule:SetPoint("TOPLEFT", plate, "BOTTOMLEFT", 0, -1)
        lowerRule:SetSize(width - 4, 1)
        -- Short bright end caps make the header plate read as a fitted metal
        -- rail rather than a flat strip, without changing panel geometry.
        for _, side in ipairs({"LEFT", "RIGHT"}) do
            local cap = frame:CreateTexture(nil, "ARTWORK")
            cap:SetColorTexture(0.88, 0.66, 0.29, 0.82)
            if side == "LEFT" then
                cap:SetPoint("TOPLEFT", plate, "TOPLEFT", 0, -1)
            else
                cap:SetPoint("TOPRIGHT", plate, "TOPRIGHT", 0, -1)
            end
            cap:SetSize(2, 23)
        end
    end
    AddPanelHeader(18, -158, 260)
    AddPanelHeader(286, -158, 834)
    AddPanelHeader(1126, -158, 300)
    AddInsetSurface(frame, 26, -620, 244, 176, {0.020, 0.018, 0.014, 0.96})
    AddPanelBorder(26, -620, 244, 176)
    AddPanelHeader(26, -620, 244)
    UI.dataHeading = AddLabel(frame, "Data", 36, -628, 220, 22, "GameFontNormal")
    IncreaseFontSize(UI.dataHeading, 1)
    UI.auctionDataLabel = AddLabel(frame, "Auction Data: unavailable", 36, -656, 166, 18, "GameFontHighlightSmall")
    UI.auctionDataState = AddLabel(frame, "Unknown", 204, -656, 58, 18, "GameFontNormalSmall")
    UI.recipeDataLabel = AddLabel(frame, "Recipe Data: unavailable", 36, -682, 166, 18, "GameFontHighlightSmall")
    UI.recipeDataState = AddLabel(frame, "Unknown", 204, -682, 58, 18, "GameFontNormalSmall")
    UI.reviewDataLabel = AddLabel(frame, "Review records: —", 36, -708, 220, 18, "GameFontHighlightSmall")
    UI.craftingScopeLabel = AddLabel(frame, "Crafting Scope", 36, -734, 220, 16, "GameFontNormalSmall")
    UI.craftingScopeDropdown = CreateDropdown(frame, 220, 36, -752,
        function() return {
            { text = "Account Crafting", value = "account", tooltipTitle = "Account Crafting",
                tooltipText = "Combines known recipes and recorded profession ownership across characters that have been captured on this account. Missing character evidence remains Unknown." },
            { text = "Character Crafting", value = "character", tooltipTitle = "Character Crafting",
                tooltipText = "Uses only the currently logged-in character's learned recipes and native profession list." },
        } end,
        function() return UI.craftingScope end,
        function(value)
            UI.craftingScope = value == "character" and "character" or "account"
            MM.db.craftingScope = UI.craftingScope
            if MM.ProfessionData and MM.ProfessionData.Refresh then MM.ProfessionData.Refresh() end
            UI.economicsByItemID = nil
            UI.economicsIndexBuild = nil
            RefreshProfessionOptions()
            UI.StartViewBuild()
        end)
    UI.filterHeading = AddLabel(frame, "Filters — All Items", 30, -166, 230, 24, "GameFontNormalLarge")
    IncreaseFontSize(UI.filterHeading, 2)
    UI.centerHeading = AddLabel(frame, "All Items", 302, -166, 500, 24, "GameFontNormalLarge")
    IncreaseFontSize(UI.centerHeading, 2)
    local tableHeaderBand = frame:CreateTexture(nil, "ARTWORK")
    tableHeaderBand:SetColorTexture(0.105, 0.078, 0.038, 0.88)
    tableHeaderBand:SetPoint("TOPLEFT", frame, "TOPLEFT", 298, -210)
    tableHeaderBand:SetSize(812, 28)
    local tableHeaderTop = frame:CreateTexture(nil, "ARTWORK")
    tableHeaderTop:SetColorTexture(0.72, 0.53, 0.22, 0.92)
    tableHeaderTop:SetPoint("TOPLEFT", tableHeaderBand, "TOPLEFT", 0, 0)
    tableHeaderTop:SetPoint("TOPRIGHT", tableHeaderBand, "TOPRIGHT", 0, 0)
    tableHeaderTop:SetHeight(1)
    local tableHeaderBottom = frame:CreateTexture(nil, "ARTWORK")
    tableHeaderBottom:SetColorTexture(0.28, 0.19, 0.07, 0.98)
    tableHeaderBottom:SetPoint("BOTTOMLEFT", tableHeaderBand, "BOTTOMLEFT", 0, 0)
    tableHeaderBottom:SetPoint("BOTTOMRIGHT", tableHeaderBand, "BOTTOMRIGHT", 0, 0)
    tableHeaderBottom:SetHeight(1)
    AddLabel(frame, "Search", 30, -198, 230, 18, "GameFontNormal")
    UI.search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    UI.search:SetSize(230, 24)
    UI.search:SetPoint("TOPLEFT", frame, "TOPLEFT", 32, -220)
    UI.search:SetTextInsets(8, 8, 0, 0)
    UI.search:SetAutoFocus(false)
    UI.search:SetMaxLetters(80)
    UI.search:SetScript("OnTextChanged", function(self, userInput)
        if userInput == false then return end
        ScheduleSearchBuild()
    end)
    UI.search:SetScript("OnEnterPressed", function(self)
        UI.searchGeneration = (UI.searchGeneration or 0) + 1
        UI.searchBuildDueAt = nil
        UI.tooltipSearchMode = true
        UI.tooltipSearchDiagnostics.searches = UI.tooltipSearchDiagnostics.searches + 1
        UI.tooltipSearchDiagnostics.lastState = "submitted"
        self:ClearFocus()
        UI.StartViewBuild()
    end)
    AttachFilterTooltip(UI.search, "Search", "Typing searches names, professions, IDs, reagents and tooltip descriptions automatically after a short pause. Press Enter to search immediately.")

    RefreshProfessionOptions()
    UI.professionDropdown = CreateDropdown(frame, 230, 32, -284,
        function() return UI.professionOptions end,
        function() return UI.professionFilter end,
        function(value)
            UI.professionFilter = tonumber(value) or 0
            UI.StartViewBuild()
        end)
    UI.professionLabel = AddLabel(frame, "Profession", 30, -252, 230, 18, "GameFontNormal")
    IncreaseFontSize(UI.professionLabel, 1)
    AttachFilterTooltip(UI.professionDropdown, "Profession", "Limit the active view to one profession. All professions keeps every supported profession in the results.")
    local function GetRoleOptions()
        local futureProvider = MM.ProfessionData and MM.ProfessionData.GetFutureProviderStatus
            and MM.ProfessionData.GetFutureProviderStatus()
        local futureReady = futureProvider and futureProvider.available
        local professionStatusReady = MM.ProfessionData
            and MM.ProfessionData.HasAuthoritativeProfessionList
            and MM.ProfessionData.HasAuthoritativeProfessionList()
        if UI.activeTab == "crafts" then
            return {
                { text = "All recipes", value = "all",
                    tooltipTitle = "All recipes",
                    tooltipText = "Show every supported recipe, whether you have learned it or not." },
                { text = "Known by you", value = "known",
                    tooltipTitle = "Known recipes",
                    tooltipText = "Recipes recorded from this character's profession windows." },
                { text = "Learnable", value = "learnable", disabled = not futureReady
                    or not (data and data.HasAnyProfessionEvidence and data.HasAnyProfessionEvidence()),
                    tooltipTitle = "Learnable recipes",
                    tooltipText = "Recipes for professions recorded on this character or elsewhere on the account, depending on Crafting Scope." },
                { text = "Not learnable", value = "unlearnable", disabled = not futureReady or not professionStatusReady
                    or UI.craftingScope == "account",
                    tooltipTitle = "Not learnable",
                    tooltipText = "Recipes for professions this character does not currently have. Account scope keeps missing character evidence Unknown." },
            }
        end
        local gatherReady = MM.ProfessionData and MM.ProfessionData.HasGatheringData
            and MM.ProfessionData.HasGatheringData()
        local options = {
            { text = "All item roles", value = "all",
                tooltipTitle = "All item roles",
                tooltipText = "Show every item in the selected view, regardless of profession relationship." },
            { text = "Known craft outputs", value = "known",
                tooltipTitle = "Known craft outputs",
                tooltipText = "Items produced by at least one recipe recorded as learned by this character." },
            { text = futureReady and "Learnable craft outputs" or "Craft data unavailable",
                value = "learnable", disabled = not futureReady or not professionStatusReady,
                tooltipTitle = "Learnable craft outputs",
                tooltipText = "Items produced by recipes for professions you have." },
            { text = "Unavailable craft outputs", value = "unlearnable", disabled = not futureReady or not professionStatusReady,
                tooltipTitle = "Unavailable craft outputs",
                tooltipText = "Items produced by recipes for professions this character does not have." },
            { text = gatherReady and "Gathering resources" or "Gathering data unavailable",
                value = "gather", disabled = not gatherReady,
                tooltipTitle = "Gathering resources",
                tooltipText = "Items mapped to Mining, Herbalism, Fishing or the core Skinning leather progression. This classification does not guarantee current skill eligibility." },
            { text = "Crafting reagents", value = "material",
                tooltipTitle = "Crafting reagents",
                tooltipText = "Items used as ingredients by at least one known or supported unlearned recipe." },
        }
        return options
    end
    UI.roleDropdown = CreateDropdown(frame, 230, 32, -366,
        GetRoleOptions,
        function() return UI.itemRoleFilter end,
        function(value)
            UI.itemRoleFilter = value
            UI.StartViewBuild()
        end)
    UI.roleLabel = AddLabel(frame, "Item role", 30, -334, 230, 18, "GameFontNormal")
    IncreaseFontSize(UI.roleLabel, 1)
    AttachFilterTooltip(UI.roleDropdown, "Item role", "Filter by learned or unlearned recipe outputs, or by gathering and material roles where supported.")

    local function GetItemTypeOptions()
        return {
            { text = "All item types", value = "all",
                tooltipTitle = "All item types",
                tooltipText = "Include all market items, regardless of their client item class." },
            { text = "Consumables", value = "consumables",
                tooltipTitle = "Consumables",
                tooltipText = "Items whose client item class is Consumable." },
            { text = "Equipment", value = "equipment",
                tooltipTitle = "Equipment",
                tooltipText = "Weapons and armor, using the client's item-class metadata." },
            { text = "Trade Goods", value = "tradeGoods",
                tooltipTitle = "Trade Goods",
                tooltipText = "Items whose client item class is Trade Goods." },
            { text = "Other item classes", value = "other",
                tooltipTitle = "Other item classes",
                tooltipText = "Items in other reported client item classes. Items without loaded class metadata are not included." },
        }
    end
    UI.itemTypeDropdown = CreateDropdown(frame, 230, 32, -448,
        GetItemTypeOptions,
        function() return UI.itemTypeFilter end,
        function(value)
            UI.itemTypeFilter = value or "all"
            UI.StartViewBuild()
        end)
    UI.itemTypeLabel = AddLabel(frame, "Item Types", 30, -416, 230, 18, "GameFontNormal")
    IncreaseFontSize(UI.itemTypeLabel, 1)
    AttachFilterTooltip(UI.itemTypeDropdown, "Item Types",
        "Filter by the item's class as reported by the game client. Missing item metadata is not guessed.")

    UI.craftFilterControls = {}
    local craftFilterSpecs = {
        { "craftableOnly", "Craftable only", "Known recipes with a resolved output and complete reagent cost." },
        { "profitableOnly", "Profitable only", "Show recipes with a calculated positive profit after the configured auction-house cut." },
        { "reviewOnly", "Review items only", "Show only records explicitly marked for hotfix-linked review." },
        { "hideLowProfit", "Hide non-profitable", "Hide recipes with zero or negative calculated profit. Incomplete profit remains visible." },
    }
    for i, spec in ipairs(craftFilterSpecs) do
        local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        check:SetSize(22, 22)
        check:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -414 - ((i - 1) * 31))
        local label = AddLabel(frame, spec[2], 54, -414 - ((i - 1) * 31), 210, 20, "GameFontHighlightSmall")
        IncreaseFontSize(label, 1)
        check.label = label
        check.filterKey = spec[1]
        check:SetScript("OnEnter", function(self) RaiseMarketTooltip(self, spec[2], spec[3]) end)
        check:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
        check:SetScript("OnClick", function(self)
            UI.craftFilters[self.filterKey] = self:GetChecked() == true
            UI.StartViewBuild()
        end)
        UI.craftFilterControls[spec[1]] = check
    end
    UI.craftFilterHeading = AddLabel(frame, "CRAFT FILTERS", 30, -394, 230, 18, "GameFontNormal")
    UI.economicsFilterControls = {}
    local economicsFilterSpecs = {
        { "crafted", "Crafted outputs", "Items produced by at least one known or supported unlearned recipe.", true },
        { "gathered", "Gathered / collected", "Items mapped to Mining, Herbalism, Fishing or the supported Skinning leather tiers.", true },
        { "material", "Crafting reagents", "Items used as ingredients by supported recipes.", true },
        { "other", "Other market items", "Items without a mapped craft-output, gathering or reagent relationship.", true },
        { "dropped", "Dropped / loot", "Disabled: this release does not have a reliable item-drop source catalogue.", false },
        { "vendor", "Vendor sourced", "Disabled: vendor recipe-learning sources are not the same as item acquisition sources.", false },
    }
    for i, spec in ipairs(economicsFilterSpecs) do
        local y = -414 - ((i - 1) * 29)
        local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        check:SetSize(22, 22)
        check:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, y)
        local label = AddLabel(frame, spec[2], 54, y, 210, 20, "GameFontHighlight")
        check.label = label
        check.filterKey = spec[1]
        if not spec[4] then
            check:Disable()
            label:SetText("|cff777777" .. spec[2] .. "|r")
        else
            check:SetScript("OnClick", function(self)
                UI.economicsFilters[self.filterKey] = self:GetChecked() == true
                UI.StartViewBuild()
            end)
        end
        check:SetScript("OnEnter", function(self) RaiseMarketTooltip(self, spec[2], spec[3]) end)
        check:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
        UI.economicsFilterControls[spec[1]] = check
    end
    UI.economicsFilterHeading = AddLabel(frame, "ECONOMICS FILTERS", 30, -394, 230, 18, "GameFontNormal")

    UI.marketQuickFilterControls = {}
    local optionsDivider = frame:CreateTexture(nil, "ARTWORK")
    optionsDivider:SetColorTexture(0.55, 0.40, 0.16, 0.76)
    optionsDivider:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -480)
    optionsDivider:SetSize(230, 1)
    UI.marketQuickFilterHeading = AddLabel(frame, "OPTIONS", 30, -490, 230, 18, "GameFontNormalLarge")
    IncreaseFontSize(UI.marketQuickFilterHeading, 1)
    local marketQuickFilterSpecs = {
        { "craftingMaterialsOnly", "Crafting materials only",
            "Items used as reagents by supported recipes; uses the existing profession material catalogue." },
        { "lowSupplyOnly", "Low supply only",
            "Uses the same item-aware supply threshold as the Low Supply tab." },
        { "highProfitOnly", "High profit only",
            "Shows market items with a source-confirmed best craft route and positive calculated auction profit after the configured cut." },
        { "reviewOnly", "Show review items only",
            "Shows only items linked to recipe records explicitly marked for hotfix-linked review." },
    }
    for i, spec in ipairs(marketQuickFilterSpecs) do
        local y = -516 - ((i - 1) * 24)
        local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        check:SetSize(22, 22)
        check:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, y)
        local label = AddLabel(frame, spec[2], 54, y, 210, 20, "GameFontHighlightSmall")
        check.label = label
        check.filterKey = spec[1]
        check:SetScript("OnEnter", function(self) RaiseMarketTooltip(self, spec[2], spec[3]) end)
        check:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
        check:SetScript("OnClick", function(self)
            UI.marketQuickFilters[self.filterKey] = self:GetChecked() == true
            if self.filterKey == "highProfitOnly" and UI.marketQuickFilters.highProfitOnly
                and not UI.economicsByItemID then
                StartEconomicsIndex()
            else
                UI.StartViewBuild()
            end
        end)
        UI.marketQuickFilterControls[spec[1]] = check
    end
    UI.tabFilterState[UI.activeTab] = { search = "", profession = 0, role = "all" }
    UI.tabFilterState[UI.activeTab].craftFilters = {}
    UI.resultCount = AddLabel(frame, "", 990, -166, 116, 20, "GameFontNormalSmall")
    UI.resultCount:SetWordWrap(false)
    UI.resultCount:SetJustifyH("RIGHT")

    UI.headerButtons = {}
    UI.tableHeaderSurface = AddInsetSurface(frame, 302, -218, 802, 34,
        {0.035, 0.029, 0.018, 0.98})
    UI.tableHeaderBorder = AddBevelBorder(frame, 302, -218, 802, 34, "control", "BORDER")
    UI.tableColumnGuides = {}
    for _, guideX in ipairs({ 520, 650, 760, 850, 935 }) do
        local guide = frame:CreateTexture(nil, "BORDER")
        guide:SetColorTexture(0.48, 0.36, 0.16, 0.22)
        guide:SetPoint("TOPLEFT", frame, "TOPLEFT", guideX, -220)
        guide:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", guideX, -252)
        guide:SetWidth(1)
        UI.tableColumnGuides[#UI.tableColumnGuides + 1] = guide
    end
    local headers = {
        { "Recipe / Item", 302, 205, "LEFT", "name" },
        { "Sale / Unit", 680, 96, "RIGHT", "price" },
        { "Materials (cost)", 510, 166, "LEFT", "materials" },
        { "At Price", 782, 70, "RIGHT", "depth" },
        { "Total", 858, 70, "RIGHT", "total" },
        { "Profit / Craft", 920, 170, "RIGHT", "profit" },
    }
    for i = 1, #headers do
        local h = headers[i]
        local header = CreateFrame("Button", nil, frame)
        header:SetSize(h[3], 18)
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", h[2], -218)
        header.label = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header.label:SetPoint("LEFT", header, "LEFT", 0, 0)
        header.label:SetWidth(h[3] - 14)
        header.label:SetJustifyH(h[4])
        header.sortIndicator = header:CreateTexture(nil, "OVERLAY")
        header.sortIndicator:SetSize(10, 10)
        header.sortIndicator:SetPoint("RIGHT", header, "RIGHT", -1, 0)
        header.sortIndicator:Hide()
        header.baseLabel = h[1]
        header.label:SetText(h[1])
        IncreaseFontSize(header.label, 1)
        header.sortKey = h[5]
        header:SetScript("OnClick", function()
            local tab = UI.activeTab
            local sort = UI.sortByTab[tab] or { key = "name", ascending = true }
            if sort.key == header.sortKey then
                sort.ascending = not sort.ascending
            else
                sort.key = header.sortKey
                sort.ascending = header.sortKey ~= "profit"
            end
            UI.sortByTab[tab] = sort
            UpdateHeaderIndicators()
            UI.StartViewBuild()
        end)
        UI.headerButtons[i] = header
    end
    UI.priceHeader = UI.headerButtons[2].label
    UI.depthHeader = UI.headerButtons[4].label
    UI.totalHeader = UI.headerButtons[6].label
    UI.materialHeader = UI.headerButtons[3].label
    UI.atPriceHeader = UI.headerButtons[4].label
    UI.totalQuantityHeader = UI.headerButtons[5].label
    UpdateHeaderIndicators()

    UI.scroll = CreateFrame("ScrollFrame", "ModuloMarketMainScrollFrame", frame, "UIPanelScrollFrameTemplate")
    UI.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 298, -242)
    UI.scroll:SetSize(812, 555)
    -- The Blizzard template normally places its scrollbar just outside the
    -- scroll frame. Keep it within the centre panel instead of over the border.
    local marketScrollBar = _G.ModuloMarketMainScrollFrameScrollBar
    if marketScrollBar then
        marketScrollBar:ClearAllPoints()
        marketScrollBar:SetPoint("TOPRIGHT", UI.scroll, "TOPRIGHT", -1, -16)
        marketScrollBar:SetPoint("BOTTOMRIGHT", UI.scroll, "BOTTOMRIGHT", -1, 16)
        marketScrollBar:SetWidth(16)
    end
    UI.scrollChild = CreateFrame("Frame", nil, UI.scroll)
    UI.scrollChild:SetSize(796, 1)
    UI.scroll:SetScrollChild(UI.scrollChild)
    UI.scroll:SetScript("OnVerticalScroll", function(_, offset)
        UI.listOffset = offset
        UI.RenderRows()
    end)

    for i = 1, UI.visibleCount do
        local slot = i
        local row = CreateFrame("Button", nil, UI.scrollChild)
        row:SetSize(796, UI.rowHeight)
        row:SetPoint("TOPLEFT", UI.scrollChild, "TOPLEFT", 0, -((i - 1) * UI.rowHeight))
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.rowShade = row:CreateTexture(nil, "BACKGROUND")
        row.rowShade:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.rowShade:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        row.selectedWash = row:CreateTexture(nil, "BACKGROUND")
        row.selectedWash:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.selectedWash:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        row.selectedWash:SetColorTexture(0.48, 0.32, 0.055, 0.43)
        row.selectedWash:Hide()
        row.selectedAccent = row:CreateTexture(nil, "ARTWORK")
        row.selectedAccent:SetColorTexture(0.96, 0.70, 0.22, 1)
        row.selectedAccent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.selectedAccent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        row.selectedAccent:SetWidth(3)
        row.selectedAccent:Hide()
        row.selectedTop = row:CreateTexture(nil, "ARTWORK")
        row.selectedTop:SetColorTexture(0.86, 0.62, 0.20, 0.82)
        row.selectedTop:SetPoint("TOPLEFT", row, "TOPLEFT", 2, 0)
        row.selectedTop:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
        row.selectedTop:SetHeight(1)
        row.selectedTop:Hide()
        row.selectedBottom = row:CreateTexture(nil, "ARTWORK")
        row.selectedBottom:SetColorTexture(0.50, 0.34, 0.10, 0.80)
        row.selectedBottom:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 2, 0)
        row.selectedBottom:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        row.selectedBottom:SetHeight(1)
        row.selectedBottom:Hide()
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        local function RowText(anchor, x, width, justify)
            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            IncreaseFontSize(fs, 1)
            if anchor == "LEFT" then fs:SetPoint("LEFT", row, "LEFT", x, 0)
            else fs:SetPoint("RIGHT", row, "RIGHT", x, 0) end
            fs:SetWidth(width); fs:SetJustifyH(justify); fs:SetWordWrap(false)
            return fs
        end
        row.name = RowText("LEFT", 27, 182, "LEFT")
        row.nameHit = CreateFrame("Button", nil, row)
        row.nameHit:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.nameHit:SetSize(210, UI.rowHeight)
        row.nameHit:SetFrameLevel(row:GetFrameLevel() + 2)
        row.nameHit:SetScript("OnEnter", function(self)
            local selected = UI.visibleRows[slot]
            if selected then
                local craftingRow = UI.activeTab == "crafts"
                ShowMarketItemTooltip(self, selected, craftingRow and selected.recipeID ~= nil)
            end
        end)
        row.nameHit:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
        row.nameHit:SetScript("OnClick", function()
            local selected = UI.visibleRows[slot]
            if selected then SelectItem(selected) end
        end)
        row.materialHit = CreateFrame("Button", nil, row)
        row.materialHit:SetPoint("LEFT", row, "LEFT", 202, 0)
        row.materialHit:SetSize(170, UI.rowHeight)
        row.materialHit:SetFrameLevel(row:GetFrameLevel() + 2)
        row.materialHit:SetScript("OnEnter", function(self)
            local selected = UI.visibleRows[slot]
            if selected and (UI.activeTab == "crafts") then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetFrameStrata("TOOLTIP")
                GameTooltip:SetText("Materials and cost", 1, 0.82, 0.35)
                for _, reagent in ipairs(selected.reagentLines or {}) do
                    local icon = GetItemIcon(reagent.itemID)
                    local iconMarkup = icon and ("|T" .. tostring(icon) .. ":16:16:0:0|t ") or ""
                    GameTooltip:AddLine(iconMarkup .. string.format("%s × %s  %s",
                        tostring(reagent.itemName or ("Item #" .. tostring(reagent.itemID or "?"))),
                        tostring(reagent.quantity or "?"),
                        reagent.lineCostCopper and FormatMoney(reagent.lineCostCopper) or "Price unknown"),
                        1, 1, 1, true)
                end
                GameTooltip:AddLine("Total material cost: " .. (selected.materialCostCopper and FormatMoney(selected.materialCostCopper) or "Incomplete"), 1, 0.82, 0.35, true)
                GameTooltip:Show()
            end
        end)
        row.materialHit:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
        row.materialHit:SetScript("OnClick", function()
            local selected = UI.visibleRows[slot]
            if selected then SelectItem(selected) end
        end)
        row.price = RowText("LEFT", 212, 105, "RIGHT")
        row.depth = RowText("LEFT", 322, 105, "RIGHT")
        row.atPrice = RowText("LEFT", 432, 82, "RIGHT")
        row.total = RowText("LEFT", 519, 82, "RIGHT")
        row.profit = RowText("LEFT", 606, 145, "RIGHT")
        row:SetScript("OnClick", function()
            local selected = UI.visibleRows[slot]
            if selected then SelectItem(selected) end
        end)
        UI.rows[i] = row
    end

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.45, 0.40, 0.30, 0.8)
    divider:SetSize(1, 650)
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 1119, -158)

    -- Inspector cards mirror the approved proof of concept while reusing the
    -- existing market, relationship and history data sources.
    local function AddInspectorCard(x, top, width, height)
        AddInsetSurface(frame, x, top, width, height, {0.010, 0.011, 0.013, 0.98})
        local header = frame:CreateTexture(nil, "ARTWORK")
        header:SetColorTexture(0.16, 0.115, 0.050, 0.78)
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", x + 2, top - 2)
        header:SetSize(width - 4, 24)
        local headerGlow = frame:CreateTexture(nil, "ARTWORK")
        headerGlow:SetColorTexture(0.55, 0.40, 0.16, 0.18)
        headerGlow:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
        headerGlow:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, 0)
        headerGlow:SetHeight(8)
        local rule = frame:CreateTexture(nil, "ARTWORK")
        rule:SetColorTexture(0.78, 0.58, 0.25, 0.84)
        rule:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
        rule:SetSize(width - 4, 1)
        AddBevelBorder(frame, x, top, width, height, "card", "OVERLAY")
    end
    AddInspectorCard(1136, -270, 280, 144)
    AddInspectorCard(1136, -422, 280, 170)
    AddInspectorCard(1136, -602, 280, 206)

    UI.detailHeading = AddLabel(frame, "Selected item", 1142, -166, 268, 24, "GameFontNormalLarge")
    IncreaseFontSize(UI.detailHeading, 2)
    UI.detailHeading:SetWordWrap(false)
    AddInsetSurface(frame, 1139, -201, 54, 54, {0.005, 0.005, 0.005, 1})
    AddBevelBorder(frame, 1139, -201, 54, 54, "control", "OVERLAY")
    UI.detailIcon = frame:CreateTexture(nil, "ARTWORK")
    UI.detailIcon:SetSize(48, 48)
    UI.detailIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 1142, -204)
    UI.detailIcon:Hide()
    UI.detailName = AddLabel(frame, "Choose an item", 1200, -204, 208, 30, "GameFontNormalLarge")
    IncreaseFontSize(UI.detailName, 1)
    UI.detailName:SetWordWrap(true)
    if UI.detailName.SetNonSpaceWrap then UI.detailName:SetNonSpaceWrap(true) end
    UI.detailBadges = AddLabel(frame, "", 1200, -234, 208, 18, "GameFontHighlight")
    UI.detailVariants = AddLabel(frame, "", 1142, -254, 268, 18, "GameFontDisableSmall")
    UI.detailVariants:SetWordWrap(true)
    if UI.detailVariants.SetNonSpaceWrap then UI.detailVariants:SetNonSpaceWrap(true) end

    local function AddDetailRowLabel(text, x, y, width)
        local label = AddLabel(frame, text, x, y, width, 18, "GameFontNormal")
        IncreaseFontSize(label, 1)
        return label
    end
    local function AddDetailRowValue(text, x, y, width)
        local value = AddLabel(frame, text, x, y, width, 18, "GameFontHighlightLarge")
        IncreaseFontSize(value, 1)
        return value
    end
    UI.marketInfoHeading = AddLabel(frame, "Market Information", 1142, -278, 268, 22, "GameFontNormalLarge")
    AddDetailRowLabel("SALE PRICE / UNIT", 1142, -304, 128)
    UI.detailPrice = AddDetailRowValue("—", 1274, -304, 132)
    AddDetailRowLabel("TOTAL LISTED", 1142, -328, 128)
    UI.detailSupply = AddDetailRowValue("—", 1274, -328, 132)
    AddDetailRowLabel("AT PRICE", 1142, -352, 128)
    UI.detailAtPrice = AddDetailRowValue("—", 1274, -352, 132)
    UI.detailProfitLabel = AddDetailRowLabel("BEST CRAFT PROFIT", 1142, -376, 128)
    UI.detailProfit = AddDetailRowValue("—", 1274, -376, 132)

    UI.relationshipHeading = AddLabel(frame, "Relationships", 1142, -430, 268, 22, "GameFontNormalLarge")
    IncreaseFontSize(UI.relationshipHeading, 1)
    UI.detailScroll = CreateFrame("ScrollFrame", "ModuloMarketDetailScrollFrame", frame, "UIPanelScrollFrameTemplate")
    UI.detailScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 1140, -456)
    UI.detailScroll:SetSize(270, 124)
    local detailScrollBar = _G.ModuloMarketDetailScrollFrameScrollBar
    if detailScrollBar then
        detailScrollBar:ClearAllPoints()
        detailScrollBar:SetPoint("TOPRIGHT", UI.detailScroll, "TOPRIGHT", -1, -14)
        detailScrollBar:SetPoint("BOTTOMRIGHT", UI.detailScroll, "BOTTOMRIGHT", -1, 14)
        detailScrollBar:SetWidth(12)
    end
    UI.detailScrollChild = CreateFrame("Frame", nil, UI.detailScroll)
    UI.detailScrollChild:SetSize(250, 124)
    UI.detailScroll:SetScrollChild(UI.detailScrollChild)
    UI.detailEconomics = UI.detailScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    IncreaseFontSize(UI.detailEconomics, 1)
    UI.detailEconomics:SetPoint("TOPLEFT", UI.detailScrollChild, "TOPLEFT", 0, 0)
    UI.detailEconomics:SetWidth(244)
    UI.detailEconomics:SetHeight(124)
    UI.detailEconomics:SetWordWrap(true)
    if UI.detailEconomics.SetNonSpaceWrap then UI.detailEconomics:SetNonSpaceWrap(true) end
    UI.detailEconomics:SetJustifyH("LEFT")
    if UI.detailScroll.EnableMouseWheel then UI.detailScroll:EnableMouseWheel(true) end
    UI.detailScroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local maxScroll = math.max(0, UI.detailScrollChild:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(maxScroll, current - (delta * 42)))
        )
    end)

    UI.detailItemTooltip = CreateFrame("Button", nil, frame)
    UI.detailItemTooltip:SetPoint("TOPLEFT", frame, "TOPLEFT", 1142, -200)
    UI.detailItemTooltip:SetSize(50, 50)
    UI.detailItemTooltip:SetFrameLevel(frame:GetFrameLevel() + 2)
    UI.detailItemTooltip:SetScript("OnEnter", function(self)
        if UI.selectedItem then ShowMarketItemTooltip(self, UI.selectedItem, false) end
    end)
    UI.detailItemTooltip:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
    UI.detailRecipeTooltip = CreateFrame("Button", nil, frame)
    UI.detailRecipeTooltip:SetPoint("TOPLEFT", frame, "TOPLEFT", 1200, -200)
    UI.detailRecipeTooltip:SetSize(208, 34)
    UI.detailRecipeTooltip:SetFrameLevel(frame:GetFrameLevel() + 2)
    UI.detailRecipeTooltip:SetScript("OnEnter", function(self)
        if UI.selectedItem then ShowMarketItemTooltip(self, UI.selectedItem, true) end
    end)
    UI.detailRecipeTooltip:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)

    UI.detailFooter = CreateFrame("Frame", nil, frame)
    UI.detailFooter:SetPoint("TOPLEFT", frame, "TOPLEFT", 1136, -602)
    UI.detailFooter:SetSize(280, 206)
    UI.historyHeading = AddLabel(frame, "Market History", 1142, -610, 268, 22, "GameFontNormalLarge")
    IncreaseFontSize(UI.historyHeading, 1)
    UI.historyText = AddLabel(UI.detailFooter, "", 6, -32, 268, 54, "GameFontHighlight")
    IncreaseFontSize(UI.historyText, 1)
    UI.historyText:SetWordWrap(true)
    if UI.historyText.SetNonSpaceWrap then UI.historyText:SetNonSpaceWrap(true) end
    UI.historyGraph = CreateFrame("Frame", nil, UI.detailFooter)
    UI.historyGraph:SetPoint("TOPLEFT", UI.detailFooter, "TOPLEFT", 6, -90)
    UI.historyGraph:SetSize(236, 104)
    UI.historyBaseline = UI.historyGraph:CreateTexture(nil, "BORDER")
    UI.historyBaseline:SetColorTexture(0.62, 0.48, 0.22, 0.52)
    UI.historyBaseline:SetPoint("BOTTOMLEFT", UI.historyGraph, "BOTTOMLEFT", 3, 3)
    UI.historyBaseline:SetPoint("BOTTOMRIGHT", UI.historyGraph, "BOTTOMRIGHT", -3, 3)
    UI.historyBaseline:SetHeight(1)
    UI.historyBarLabels = {}
    for i = 1, 4 do
        local label = UI.historyGraph:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        IncreaseFontSize(label, 1)
        label:SetWidth(54)
        label:SetJustifyH("CENTER")
        UI.historyBarLabels[i] = label
        label:Hide()
        local bar = UI.historyGraph:CreateTexture(nil, "ARTWORK")
        bar:SetColorTexture(0.72, 0.62, 0.36, 0.95)
        UI.historyBars[i] = bar
        bar:Hide()
    end

    frame:SetScript("OnHide", function()
        UI.CloseDropdownMenus()
        if _G.GameTooltip then GameTooltip:Hide() end
    end)
    frame:SetScript("OnShow", function(self)
        UI.CloseDropdownMenus()
        self:SetFrameStrata("DIALOG")
        self:SetToplevel(true)
        if type(self.Raise) == "function" then self:Raise() end
        UI.craftingScope = (MM.db and MM.db.craftingScope == "character") and "character" or "account"
        if UI.craftingScopeDropdown and UI.craftingScopeDropdown.RefreshText then UI.craftingScopeDropdown.RefreshText() end
        if MM.ProfessionData and MM.ProfessionData.Refresh then
            MM.ProfessionData.Refresh()
            UI.economicsByItemID = nil
            RefreshProfessionOptions()
            if UI.professionDropdown and UI.professionDropdown.RefreshText then
                UI.professionDropdown.RefreshText()
            end
            if UI.roleDropdown and UI.roleDropdown.RefreshText then
                UI.roleDropdown.RefreshText()
            end
        end
        UI.Refresh()
    end)
    frame:SetScript("OnUpdate", function(_, elapsed)
        local now = Now()
        if UI.searchBuildDueAt and now >= UI.searchBuildDueAt then
            UI.searchBuildDueAt = nil
            UI.tooltipSearchMode = true
            UI.tooltipSearchDiagnostics.searches = UI.tooltipSearchDiagnostics.searches + 1
            UI.tooltipSearchDiagnostics.lastState = "debounced"
            UI.StartViewBuild()
        end
        -- Run the warmup watchdog independently of other work queues so a stale
        -- catalogue/economics task cannot starve its hard timeout.
        if UI.tooltipSearchWarmup then StepTooltipSearchWarmup() end
        StepItemClassWarmup()
        if UI.itemTypeRefreshDueAt and now >= UI.itemTypeRefreshDueAt
            and not UI.catalogBuild and not UI.economicsIndexBuild
            and not UI.viewBuild and not UI.rankSort then
            UI.itemTypeRefreshDueAt = nil
            UI.StartViewBuild()
        end
        if UI.catalogBuild then StepCatalog()
        elseif UI.economicsIndexBuild then StepEconomicsIndex()
        elseif UI.viewBuild then StepView()
        elseif UI.rankSort then StepRankSort() end
        UI.refreshElapsed = UI.refreshElapsed + (tonumber(elapsed) or 0)
        if UI.refreshElapsed >= 1 then
            UI.refreshElapsed = UI.refreshElapsed - 1
            UI.RefreshActions()
        end
    end)
    UI.frame = frame
    local tooltipSearchEvents = CreateFrame("Frame")
    tooltipSearchEvents:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    tooltipSearchEvents:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    tooltipSearchEvents:SetScript("OnEvent", function(_, event, itemID, success)
        itemID = tonumber(itemID)
        if itemID and UI.tooltipSearchRequested[itemID] then
            UI.tooltipSearchDiagnostics.events = UI.tooltipSearchDiagnostics.events + 1
            UI.tooltipSearchRequested[itemID] = nil
            if success == false then
                UI.tooltipSearchDiagnostics.failures = UI.tooltipSearchDiagnostics.failures + 1
                UI.tooltipSearchCache[itemID] = false
            else
                -- The warmup phase reads and caches this tooltip before the one
                -- final search pass. Never schedule a whole-catalogue rebuild here.
                UI.tooltipSearchCache[itemID] = nil
            end
            local warmup = UI.tooltipSearchWarmup
            if warmup and warmup.awaiting[itemID] then
                warmup.awaiting[itemID] = nil
                warmup.outstanding = math.max(0, warmup.outstanding - 1)
            end
        end
    end)
    UI.tooltipSearchEvents = tooltipSearchEvents
    -- Newly created controls default to visible. Apply the active tab once all
    -- tab-specific controls exist so inactive filter groups never overlap on first open.
    SetTab(UI.activeTab or "market")
    return frame
end

function UI.GetSearchDiagnostics()
    local d = UI.tooltipSearchDiagnostics or {}
    local warmup = UI.tooltipSearchWarmup
    local outstanding = 0
    if warmup then outstanding = tonumber(warmup.outstanding) or 0 end
    return {
        searches = d.searches or 0, requests = d.requests or 0, events = d.events or 0,
        cacheHits = d.cacheHits or 0, failures = d.failures or 0, timeouts = d.timeouts or 0,
        completed = d.completed or 0, state = d.lastState or "idle",
        pending = warmup and #warmup.ids or 0, outstanding = outstanding,
        lastError = d.lastError or "none",
        structuredReads = d.structuredReads or 0,
        legacyFallbacks = d.legacyFallbacks or 0,
        emptyResults = d.emptyResults or 0,
        lastItemID = d.lastItemID or 0,
        lastSource = d.lastSource or "none",
        lastLineCount = d.lastLineCount or 0,
    }
end

function UI.GetTooltipSearchDebug(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil, "Provide an item ID." end
    local text = GetTooltipSearchText(itemID)
    return text, UI.tooltipSearchDiagnostics.lastSource or "none",
        UI.tooltipSearchDiagnostics.lastLineCount or 0
end

function UI.GetMarketItemByID(itemID)
    return GetMarketPrice(itemID) or nil
end

function UI.OnRecipesUpdated()
    UI.economicsByItemID = nil
    UI.economicsIndexBuild = nil
    if MM.ProfessionData and MM.ProfessionData.Refresh then
        MM.ProfessionData.Refresh()
        RefreshProfessionOptions()
        if UI.professionDropdown and UI.professionDropdown.RefreshText then
            UI.professionDropdown.RefreshText()
        end
        if UI.roleDropdown and UI.roleDropdown.RefreshText then
            UI.roleDropdown.RefreshText()
        end
    end
    if not UI.frame then return end
    if UI.activeTab == "crafts"
        or UI.activeTab == "economics" or UI.activeTab == "materials" then
        UI.StartViewBuild()
    elseif UI.selectedItem and not UI.selectedItem.recipeData then
        RenderMarketRecipeContext(UI.selectedItem)
    end
end

function UI.Raise()
    local frame = CreateUI()
    -- Keep the Market below native GameTooltip and contextual tooltip frames.
    -- Frame level cannot outrank another frame in a higher strata.
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    if type(frame.Raise) == "function" then frame:Raise() end
end

function UI.Toggle()
    if UI.AttachMinimapButton then UI.AttachMinimapButton() end
    local frame = CreateUI()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        UI.Raise()
    end
end

function UI.Show()
    if UI.AttachMinimapButton then UI.AttachMinimapButton() end
    CreateUI():Show()
    UI.Raise()
end

local function IsDefaultBlizzardSellTab(parent)
    if parent ~= _G.AuctionFrame then return false end
    local selected
    if type(_G.PanelTemplates_GetSelectedTab) == "function" then
        local ok, value = pcall(_G.PanelTemplates_GetSelectedTab, parent)
        if ok then selected = tonumber(value) end
    end
    if not selected then selected = tonumber(parent.selectedTab) end
    if selected ~= 2 then return false end
    local sellTab = _G.AuctionFrameTab2
    if sellTab and type(sellTab.IsShown) == "function" and not sellTab:IsShown() then
        return false
    end
    return true
end

function UI.AttachAuctionHouseButton()
    -- The target Classic auction UI uses AuctionFrameTab2 for Blizzard's
    -- native Sell tab. Fail closed on other frames/addon-owned tab surfaces.
    local parent = _G.AuctionFrame
    if not parent or type(parent.IsObjectType) ~= "function" or not parent:IsObjectType("Frame") then
        return false
    end
    local button = UI.auctionHouseButtons[parent]
    if not button then
        button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        button:SetSize(116, 20)
        button:SetFrameStrata("TOOLTIP")
        button:SetToplevel(true)
        button:SetFrameLevel((parent:GetFrameLevel() or 0) + 8)
        button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -42, -34)
        button:SetText("Modulo Market")
        button:SetScript("OnClick", UI.Show)
        UI.auctionHouseButtons[parent] = button
        local function RefreshLauncherVisibility()
            if IsDefaultBlizzardSellTab(parent) then button:Show() else button:Hide() end
        end
        if type(parent.HookScript) == "function" then
            parent:HookScript("OnShow", RefreshLauncherVisibility)
            parent:HookScript("OnHide", function() button:Hide() end)
        end
        -- Blizzard's native tab buttons fire OnClick before their panel update;
        -- defer visibility to the next frame so selectedTab has settled.
        for index = 1, 12 do
            local tab = _G["AuctionFrameTab" .. index]
            if tab and type(tab.HookScript) == "function" then
                tab:HookScript("OnClick", function()
                    button:SetScript("OnUpdate", function(self)
                        self:SetScript("OnUpdate", nil)
                        RefreshLauncherVisibility()
                    end)
                end)
            end
        end
        UI.auctionHouseVisibilityRefresh = RefreshLauncherVisibility
    end
    if UI.auctionHouseVisibilityRefresh then UI.auctionHouseVisibilityRefresh() end
    return true
end

local function PositionMinimapButton(button, angle)
    local minimap = _G.Minimap
    if not minimap then return end
    angle = tonumber(angle) or math.rad(225)
    local radius = (tonumber(minimap:GetWidth()) or 140) / 2 + 8
    button:ClearAllPoints()
    button:SetPoint("CENTER", minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
    if type(MM.db) == "table" then MM.db.minimapAngle = angle end
end

function UI.AttachMinimapButton()
    local minimap = _G.Minimap
    if not minimap then return false end
    if UI.minimapButton then return true end
    local button = CreateFrame("Button", "ModuloMarketMinimapButton", minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((minimap.GetFrameLevel and minimap:GetFrameLevel() or 1) + 5)
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp")
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetAllPoints(button)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function(_, mouseButton)
        if not mouseButton or mouseButton == "LeftButton" then UI.Toggle() end
    end)
    button:SetScript("OnEnter", function(self)
        if _G.GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("Modulo Market")
            GameTooltip:AddLine("Left-click to open", 1, 1, 1)
            GameTooltip:AddLine("Drag to move", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function(dragButton)
            if not _G.GetCursorPosition then return end
            local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
            local cursorX, cursorY = GetCursorPosition()
            local centerX, centerY = minimap:GetCenter()
            local dx, dy = cursorX / scale - centerX, cursorY / scale - centerY
            local angle
            if math.atan2 then
                angle = math.atan2(dy, dx)
            elseif dx > 0 then
                angle = math.atan(dy / dx)
            elseif dx < 0 and dy >= 0 then
                angle = math.atan(dy / dx) + math.pi
            elseif dx < 0 and dy < 0 then
                angle = math.atan(dy / dx) - math.pi
            elseif dy > 0 then
                angle = math.pi / 2
            else
                angle = -math.pi / 2
            end
            PositionMinimapButton(dragButton, angle)
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    UI.minimapButton = button
    PositionMinimapButton(button, MM.db and MM.db.minimapAngle)
    return true
end

local launcherEvents = CreateFrame("Frame")
pcall(launcherEvents.RegisterEvent, launcherEvents, "AUCTION_HOUSE_SHOW")
pcall(launcherEvents.RegisterEvent, launcherEvents, "PLAYER_LOGIN")
pcall(launcherEvents.RegisterEvent, launcherEvents, "PLAYER_ENTERING_WORLD")
pcall(launcherEvents.RegisterEvent, launcherEvents, "ADDON_LOADED")
launcherEvents:SetScript("OnEvent", function()
    UI.AttachAuctionHouseButton()
    UI.AttachMinimapButton()
end)

function UI.GetProfitScenario(item, costCopper, quantity, cutPercent, salePriceCopper)
    if type(item) ~= "table" then return nil, "NO_ITEM" end
    local price = tonumber(salePriceCopper) or tonumber(item.minPriceCopper)
    costCopper, quantity, cutPercent = tonumber(costCopper), tonumber(quantity), tonumber(cutPercent) or 5
    if not price or price <= 0 then return nil, "NO_BUYOUT" end
    if not costCopper or costCopper < 0 or not quantity or quantity < 1
        or cutPercent < 0 or cutPercent >= 100 then return nil, "INVALID_INPUT" end
    local net = math.floor(price * (1 - cutPercent / 100))
    local profit = net - costCopper
    return {
        grossUnitPriceCopper = price,
        netUnitPriceCopper = net,
        costUnitCopper = costCopper,
        profitUnitCopper = profit,
        quantity = math.floor(quantity),
        totalProfitCopper = profit * math.floor(quantity),
        breakEvenGrossCopper = math.ceil(costCopper / (1 - cutPercent / 100)),
        marginPercent = costCopper > 0 and profit / costCopper * 100 or 0,
        cutPercent = cutPercent,
    }
end

