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
    economicsByItemID = nil,
    vendorPriceCache = {},
    vendorPriceRequested = {},
    vendorPriceFailed = {},
    historyBars = {},
    itemRoleFilter = "all",
    professionOptions = {},
    sortByTab = {
        market = { key = "name", ascending = true },
        economics = { key = "profit", ascending = false },
        crafting = { key = "name", ascending = true },
        allcrafts = { key = "profit", ascending = false },
        materials = { key = "name", ascending = true },
        low = { key = "name", ascending = true },
        history = { key = "change", ascending = false },
    },
    refreshElapsed = 0,
    lowSupplyThreshold = 5,
    auctionHouseButtons = {},
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

local function MatchesSearch(item, query, isCrafting)
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
    local prefix, nameColor = {}, "|cffffffff"
    for _, tag in ipairs(tags) do
        if tag == "known" then
            prefix[#prefix + 1] = "|cff55dd77[C]|r"
            nameColor = "|cff8ee6a2"
        elseif tag == "future" then
            prefix[#prefix + 1] = "|cffffc04d[F]|r"
            if nameColor == "|cffffffff" then nameColor = "|cffffd77a" end
        elseif tag == "futureBorrowed" then
            prefix[#prefix + 1] = "|cffffa64d[F?]|r"
            if nameColor == "|cffffffff" then nameColor = "|cffffb36b" end
        elseif tag == "futureUnknown" then
            prefix[#prefix + 1] = "|cffb7c0cc[?]|r"
            if nameColor == "|cffffffff" then nameColor = "|cffc4cbd3" end
        elseif tag == "gather" then
            prefix[#prefix + 1] = "|cff66ccff[G]|r"
            if nameColor == "|cffffffff" then nameColor = "|cff82d9ff" end
        elseif tag == "material" then
            prefix[#prefix + 1] = "|cff80cfff[M]|r"
            if nameColor == "|cffffffff" then nameColor = "|cffb6e2ff" end
        end
    end
    return table.concat(prefix, " ") .. " " .. nameColor .. name .. "|r"
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
    local known = MM.Recipes and MM.Recipes.GetAllRecipes and MM.Recipes.GetAllRecipes() or {}
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
    for _, recipe in ipairs(future or {}) do
        local key = tostring(recipe.professionID or "") .. ":" .. tostring(recipe.recipeID or "")
        if not seen[key] then
            seen[key] = true
            recipe.craftSourceStatus = recipe.borrowedSources and "borrowed"
                or (recipe.sourceUnknown and "unknown" or "future")
            result[#result + 1] = recipe
        end
    end
    return result
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
            economics.craftSourceStatus = recipe.craftSourceStatus or "known"
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

local function CreateDropdown(parent, width, x, y, getOptions, getValue, onChanged)
    -- Use an explicit button + popup rather than UIDropDownMenuTemplate.
    -- The stock dropdown menu has been visible but inert on the target Forever
    -- client; this keeps the interaction path local and directly testable.
    local dropdown = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    dropdown:SetSize(width, 24)
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    dropdown:EnableMouse(true)

    dropdown.label = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dropdown.label:SetPoint("LEFT", dropdown, "LEFT", 8, 0)
    dropdown.label:SetPoint("RIGHT", dropdown, "RIGHT", -24, 0)
    dropdown.label:SetJustifyH("LEFT")
    dropdown.label:SetWordWrap(false)

    dropdown.arrow = dropdown:CreateTexture(nil, "OVERLAY")
    dropdown.arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    dropdown.arrow:SetTexCoord(0.2, 0.8, 0.2, 0.8)
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
    end

    local function openMenu()
        local options = getOptions() or {}
        local rowHeight = 22
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
            optionButton:SetSize(width - 8, 20)
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
    dropdown:SetScript("OnClick", dropdown.ToggleMenu)
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
    return button
end

SetStatus = function(text)
    if UI.status then UI.status:SetText(tostring(text or "")) end
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
    local query = NormalizeSearchText(UI.search:GetText() or "")
    UI.listOffset = 0
    UI.viewRows = {}
    UI.rankSort = nil
    local isCrafting = UI.activeTab == "crafting" or UI.activeTab == "allcrafts"
    local source
    if UI.activeTab == "crafting" then
        source = MM.Recipes and MM.Recipes.GetAllRecipes() or {}
    elseif UI.activeTab == "allcrafts" then
        source = GetAllCraftSources()
    elseif UI.activeTab == "materials" then
        source = GetMaterialCatalog()
    else
        source = UI.catalog
    end
    if UI.activeTab == "economics" and not UI.economicsByItemID then
        StartEconomicsIndex()
        return
    end
    UI.viewBuild = {
        index = 1, query = query, rows = {}, tab = UI.activeTab,
        professionFilter = UI.professionFilter,
        itemRoleFilter = UI.itemRoleFilter,
        craftFilters = {
            craftableOnly = UI.craftFilters.craftableOnly,
            profitableOnly = UI.craftFilters.profitableOnly,
            reviewOnly = UI.craftFilters.reviewOnly,
            hideLowProfit = UI.craftFilters.hideLowProfit,
        },
        source = source or {}, total = #(source or {}), startedAt = Now(),
    }
    if UI.scroll then
        UI.scroll:SetVerticalScroll(0)
        UI.scrollChild:SetHeight(1)
    end
    if UI.resultCount then UI.resultCount:SetText("Filtering…") end
end

local function StepView()
    local build = UI.viewBuild
    if not build then return end
    local source = build.source or {}
    local stop = math.min(build.total, build.index + 249)
    local cut = tonumber(MM.db and MM.db.auctionHouseCutPercent) or 5
    while build.index <= stop do
        local sourceItem = source[build.index]
        local item = sourceItem
        local isCrafting = build.tab == "crafting" or build.tab == "allcrafts"
        if isCrafting and MM.Recipes then
            item = MM.Recipes.BuildEconomics(sourceItem, function(itemID)
                return GetMarketPrice(itemID)
            end, cut)
            if item then
                item.recipeKey = tostring(sourceItem.professionID or "") .. ":" .. tostring(sourceItem.recipeID or "")
                item.recipeName = sourceItem.recipeName
                item.itemName = item.itemName or sourceItem.recipeName
                item.craftSourceStatus = sourceItem.craftSourceStatus or "known"
                item.requiredSkill = sourceItem.requiredSkill
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
            local matches = MatchesSearch(item, build.query, isCrafting)
            if matches and build.professionFilter and build.professionFilter ~= 0 then
                if isCrafting then
                    matches = tonumber(item.professionID) == tonumber(build.professionFilter)
                else
                    matches = MM.ProfessionData and MM.ProfessionData.Matches(item.itemID,
                        build.professionFilter, "all") or false
                end
            end
            if matches and isCrafting and build.itemRoleFilter ~= "all" then
                local status = item.craftSourceStatus or "known"
                if build.itemRoleFilter == "known" then
                    matches = status == "known"
                elseif build.itemRoleFilter == "future" then
                    matches = status == "future" or status == "auto"
                elseif build.itemRoleFilter == "unknown" then
                    matches = status == "unknown"
                elseif build.itemRoleFilter == "borrowed" then
                    matches = status == "borrowed"
                end
            elseif matches and not isCrafting and build.itemRoleFilter ~= "all" then
                matches = MM.ProfessionData and MM.ProfessionData.Matches(item.itemID, 0,
                    build.itemRoleFilter) or false
            end
            if matches and build.tab == "materials" then
                matches = MM.ProfessionData and MM.ProfessionData.IsMaterial
                    and MM.ProfessionData.IsMaterial(item.itemID) or false
            end
            if matches and isCrafting then
                local filters = build.craftFilters or {}
                local status = item.craftSourceStatus or "known"
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
            (build.tab == "allcrafts" and "profession crafts")
            or (build.tab == "crafting" and "known crafts") or "items", sortLabel))
        return
    end
    UI.FinishView(build.rows)
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
        if UI.detailEconomics then UI.detailEconomics:SetText("No entries match the current filters. Adjust the filters or search to see results.") end
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
                if not UI.catalogSnapshot then
                    SetStatus("Craft profitability disabled: no market snapshot for current client build "
                        .. tostring(provider.currentBuild or "UNKNOWN") .. baselineNote)
                else
                    SetStatus(string.format(
                        "Craft profitability disabled: market snapshot build %s does not match current client build %s",
                        tostring(UI.recipeMarketSnapshotBuild or "UNKNOWN"),
                        tostring(provider.currentBuild or "UNKNOWN")) .. baselineNote)
                end
            else
                local freshness = provider.dataBuildMatchesClient and "build matched"
                    or string.format("baseline from %s; client %s",
                        tostring(provider.datasetBuild or "UNKNOWN"), tostring(provider.currentBuild or "UNKNOWN"))
                local review = (provider.reviewWatchCount or 0) > 0
                    and string.format(" · %d hotfix-linked records flagged for review", provider.reviewWatchCount) or ""
                SetStatus(string.format(
                    "ForeverDB %s · %d observed/automatic-source unlearned crafts · %d Classic-borrowed · %d unverified · %d speculative and %d non-item/unknown-output excluded%s",
                    freshness, provider.count or 0, provider.borrowedSourceCount or 0,
                    provider.unknownSourceCount or 0, provider.speculativeCount or 0,
                    provider.nonItemCount or 0, review))
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
    local isCrafting = UI.activeTab == "crafting" or UI.activeTab == "allcrafts"
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
                    button.rowShade:SetColorTexture(0.19, 0.16, 0.12, 0.22)
                else
                    button.rowShade:SetColorTexture(0.035, 0.032, 0.028, 0.12)
                end
                button.rowShade:Show()
            end
            local profitText = "—"
            if isCrafting then
                local status = item.craftSourceStatus or "known"
                local color = status == "known" and "|cff8ee6a2"
                    or (status == "future" and "|cffffd77a"
                    or (status == "borrowed" and "|cffffb36b" or "|cffb7c0cc"))
                local marker = status == "known" and "[C] " or (status == "future" and "[F] "
                    or (status == "borrowed" and "[F?] " or "[?] "))
                button.name:SetText(marker .. color .. GetItemName(item) .. "|r")
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
                local vendorPrice = GetVendorInfo(item.itemID)
                button.name:SetText(GetItemDisplayName(item))
                button.price:SetText(item.minPriceCopper and FormatMoney(item.minPriceCopper)
                    or (vendorPrice and FormatMoney(vendorPrice) or "—"))
                button.depth:SetText(economics and economics.materialCostCopper
                    and FormatMoney(economics.materialCostCopper) or "—")
                button.atPrice:SetText(item.minPriceQuantity ~= nil and tostring(item.minPriceQuantity) or "—")
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
            if same then button:LockHighlight() else button:UnlockHighlight() end
            button:Show()
        else
            button:Hide()
            if button.icon then button.icon:Hide() end
            if button.rowShade then button.rowShade:Hide() end
            UI.visibleRows[i] = nil
        end
        end
    end
    for i = rowPoolCount + 1, #(UI.visibleRows or {}) do UI.visibleRows[i] = nil end
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
            local height = 8 + ((point.price - minPrice) / span) * 34
            bar:ClearAllPoints()
            bar:SetPoint("BOTTOMLEFT", UI.historyGraph, "BOTTOMLEFT", (i - 1) * 58 + 8, 4)
            bar:SetSize(38, height)
            local previous = points[i - 1]
            local change = previous and previous.price > 0
                and ((point.price - previous.price) / previous.price * 100) or 0
            if percentLabel then
                percentLabel:ClearAllPoints()
                percentLabel:SetPoint("BOTTOM", UI.historyGraph, "BOTTOMLEFT", (i - 1) * 58 + 27, math.min(height + 1, 44))
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

local function SetDetailEconomics(text)
    if UI.detailEconomics then
        UI.detailEconomics:SetText(text or "")
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
    SetDetailEconomics(table.concat(lines, "\n"))
    if UI.detailProfit then
        if item.profitCopper ~= nil then
            local color = item.profitCopper >= 0 and "|cff55dd77" or "|cffff6666"
            local netSale = tonumber(item.netSaleCopper)
            local margin = netSale and netSale > 0 and (item.profitCopper / netSale * 100) or nil
            UI.detailProfit:SetText(color .. FormatMoney(item.profitCopper) .. "|r profit / craft"
                .. (margin and string.format(" (%.1f%%)", margin) or ""))
        else
            UI.detailProfit:SetText("Profit unavailable until every required price is known.")
        end
    end
end

local function RenderMarketRecipeContext(item)
    local recipes = MM.Recipes and MM.Recipes.GetAllRecipes() or {}
    local itemID = tonumber(item and item.itemID)
    if not itemID then
        SetDetailEconomics("Select an item to inspect its market, gathering and recipe relationships.")
        if UI.detailProfit then UI.detailProfit:SetText("Market and profession data") end
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
    if gathering then
        lines[#lines + 1] = "|cff66ccffGATHERED BY|r"
        for professionID, info in pairs(gathering) do
            local professionName = (professionData and professionData.professions[professionID])
                or "Gathering profession"
            local requirement = tonumber(info.requiredSkill) or 1
            if info.canGatherNow then
                lines[#lines + 1] = string.format("%s · can gather now (skill %d; your skill %d)",
                    tostring(professionName), requirement, tonumber(info.currentSkill) or requirement)
            elseif info.skillKnown then
                lines[#lines + 1] = string.format("%s · requires skill %d (your skill %d)",
                    tostring(professionName), requirement, tonumber(info.currentSkill) or 0)
            else
                lines[#lines + 1] = string.format("%s · requires skill %d (current skill not captured)",
                    tostring(professionName), requirement)
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
            if best.craftSourceStatus == "future" then
                lines[#lines + 1] = "Unlearned recipe · recorded acquisition source"
            else
                lines[#lines + 1] = "Recipe known by this character"
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
    if #lines == 0 then
        lines[1] = "No captured recipe or confirmed gathering relationship is known for this item."
    end
    SetDetailEconomics(table.concat(lines, "\n"))
    if UI.detailProfit then
        if UI.activeTab == "economics" then
            local best = UI.economicsByItemID and UI.economicsByItemID[itemID]
            if best and best.profitCopper ~= nil then
                local color = best.profitCopper >= 0 and "|cff55dd77" or "|cffff6666"
                UI.detailProfit:SetText(color .. FormatMoney(best.profitCopper) .. "|r best craft profit")
            else
                UI.detailProfit:SetText("No complete, source-confirmed craft route")
            end
        else
            UI.detailProfit:SetText("Gathering and recipe relationships")
        end
    end
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
            local state = item.craftSourceStatus or "known"
            tags[#tags + 1] = state == "known" and "|cff55dd77KNOWN|r"
                or (state == "future" and "|cffffd166FUTURE|r"
                or (state == "borrowed" and "|cffffa64dBORROWED|r" or "|cffb7c0ccUNKNOWN|r"))
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
    local vendorPrice = GetVendorInfo(item.itemID, true)
    UI.detailPrice:SetText(item.minPriceCopper and FormatMoney(item.minPriceCopper)
        or (item.salePriceCopper and FormatMoney(item.salePriceCopper))
        or (vendorPrice and FormatMoney(vendorPrice)) or "No buyout")
    UI.detailSupply:SetText(string.format("%d units", tonumber(item.totalQuantity) or 0))
    if UI.detailAtPrice then
        UI.detailAtPrice:SetText(item.minPriceQuantity ~= nil and tostring(item.minPriceQuantity) or "—")
    end
    if item.recipeData then
        UI.detailVariants:SetText(string.format("%s · Skill %s",
            tostring(item.professionName or "Profession"),
            tostring(item.professionSkill or item.recipeData.professionSkill or "?")))
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
    UI.vendorPriceRequested[itemID] = nil
    if success == false then
        UI.vendorPriceFailed[itemID] = true
        UI.vendorPriceCache[itemID] = nil
    else
        UI.vendorPriceFailed[itemID] = nil
        local sellPrice = ReadVendorInfo(itemID)
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

local function UpdateMetadata()
    local snapshot = GetSnapshot()
    if not snapshot then
        UI.metadata:SetText("No saved Auction House data")
        return
    end
    local age = math.max(0, (type(_G.time) == "function" and _G.time() or 0) - (tonumber(snapshot.timestamp) or 0))
    local ageText = age < 3600 and string.format("%dm", math.floor(age / 60))
        or (age < 86400 and string.format("%dh", math.floor(age / 3600))
        or string.format("%dd", math.floor(age / 86400)))
    local source = snapshot.source == "C_AuctionHouse.ReplicateItems" and "Full Market" or "Browse"
    UI.metadata:SetText(string.format("%s data · %s ago · %s auction records",
        source, ageText, tostring(snapshot.auctionCount or snapshot.resultCount or 0)))
end

function UI.RefreshActions()
    if not UI.frame then return end
    local state = MM.Replicate and MM.Replicate.GetState and MM.Replicate.GetState() or {}
    local remaining = math.max(0, tonumber(state.cooldownRemaining) or 0)
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
    UI.tabFilterState[previousTab].craftFilters = {
        craftableOnly = UI.craftFilters.craftableOnly,
        profitableOnly = UI.craftFilters.profitableOnly,
        reviewOnly = UI.craftFilters.reviewOnly,
        hideLowProfit = UI.craftFilters.hideLowProfit,
    }
    if UI.selectedItem then
        UI.selectedByTab[previousTab] = { itemID = tonumber(UI.selectedItem.itemID), recipeKey = UI.selectedItem.recipeKey }
    end
    UI.activeTab = tab
    if tab ~= "economics" then UI.economicsIndexBuild = nil end
    local saved = UI.tabFilterState[tab] or {}
    UI.professionFilter = tonumber(saved.profession) or 0
    UI.itemRoleFilter = saved.role or "all"
    local savedCraft = saved.craftFilters or {}
    UI.craftFilters.craftableOnly = savedCraft.craftableOnly == true
    UI.craftFilters.profitableOnly = savedCraft.profitableOnly == true
    UI.craftFilters.reviewOnly = savedCraft.reviewOnly == true
    UI.craftFilters.hideLowProfit = savedCraft.hideLowProfit == true
    if UI.search then UI.search:SetText(saved.search or "") end
    if UI.centerHeading then UI.centerHeading:SetText(tab == "allcrafts" and "All Crafts"
        or (tab == "crafting" and "My Crafts" or (tab == "market" and "All Items"
        or (tab == "low" and "Low Supply" or tab:gsub("^%l", string.upper))))) end
    if UI.filterHeading then UI.filterHeading:SetText("Filters — " .. (tab == "allcrafts" and "All Crafts"
        or (tab == "crafting" and "My Crafts" or (tab == "market" and "All Items"
        or (tab == "low" and "Low Supply" or (tab:gsub("^%l", string.upper))))))) end
    if UI.professionDropdown and UI.professionDropdown.RefreshText then UI.professionDropdown.RefreshText() end
    for name, button in pairs(UI.tabs) do
        if name == tab then
            button:Disable()
            if button.selectedMark then button.selectedMark:Show() end
            if button.background then button.background:SetColorTexture(0.22, 0.15, 0.055, 1) end
        else
            button:Enable()
            if button.selectedMark then button.selectedMark:Hide() end
            if button.background then button.background:SetColorTexture(0.12, 0.085, 0.045, 0.95) end
        end
    end

    local craftTab = tab == "crafting" or tab == "allcrafts"
    local labels = { "Item / Recipe", "Cheapest", "Materials", "At Price", "Total", "Profit / Craft" }
    local keys = { "name", "price", "materials", "depth", "total", "profit" }
    if craftTab then
        labels = { "Recipe", "Materials (cost)", "Sale / Unit", "At Price", "Total", "Profit / Craft" }
        keys = { "name", "materials", "price", "depth", "total", "profit" }
    elseif tab == "economics" then
        labels = { "Item", "Sale / Unit", "Materials", "At Price", "Total", "Profit / Loss" }
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
            { x = 936, w = 170, justify = "RIGHT" },
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
    elseif tab == "materials" then
        local materialColumns = {
            { x = 302, w = 205, justify = "LEFT" },
            { x = 510, w = 105, justify = "RIGHT" },
            { x = 620, w = 150, justify = "RIGHT" },
            { x = 776, w = 72, justify = "RIGHT" },
            { x = 852, w = 254, justify = "RIGHT" },
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
            { x = 930, w = 176, justify = "RIGHT" },
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
        UI.roleLabel:SetText(craftTab and (tab == "allcrafts" and "Known status" or "Recipe status")
            or "Recipe source / item role")
    end
    UpdateHeaderIndicators()

    if UI.roleDropdown then
        UI.roleDropdown:Enable()
        if UI.roleDropdown.RefreshText then UI.roleDropdown.RefreshText() end
    end
    local showCraftFilters = tab == "crafting" or tab == "allcrafts"
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
    if UI.detailHeading then UI.detailHeading:SetText(craftTab and "Selected Recipe" or "Selected Item") end
    if UI.detailName then UI.detailName:SetText("Loading selection…") end
    if UI.detailIcon then UI.detailIcon:Hide() end
    if UI.detailBadges then UI.detailBadges:SetText("") end
    if UI.detailPrice then UI.detailPrice:SetText("—") end
    if UI.detailSupply then UI.detailSupply:SetText("—") end
    if UI.detailVariants then UI.detailVariants:SetText("") end
    SetDetailEconomics(craftTab
        and (tab == "crafting" and "Your known recipes, including losses and incomplete prices."
            or "All recipe candidates. Acquisition source and price-data certainty are shown per recipe.")
        or (tab == "materials" and "Materials used by known and supported unlearned recipes."
            or "Select an item to inspect its market, vendor value and recipe relationships."))
    if UI.detailProfit then
        UI.detailProfit:SetText(tab == "economics" and "Auction and vendor sale comparison"
            or (tab == "allcrafts" and "All profession recipes" or "Automatic recipe valuation"))
    end
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
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
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
    frame.TitleText:SetText("Modulo Market")
    frame:Hide()
    _G.UISpecialFrames = _G.UISpecialFrames or {}
    local specialFrameRegistered = false
    for _, name in ipairs(_G.UISpecialFrames) do
        if name == "ModuloMarketMainFrame" then specialFrameRegistered = true; break end
    end
    if not specialFrameRegistered then
        _G.UISpecialFrames[#_G.UISpecialFrames + 1] = "ModuloMarketMainFrame"
    end

    UI.metadata = AddLabel(frame, "Loading market data…", 24, -36, 760, 18, "GameFontNormal")
    UI.status = AddLabel(frame, "Ready", 24, -92, 900, 18, "GameFontDisableSmall")
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

    UI.opacityLabel = AddLabel(frame, "Window opacity", 860, -43, 170, 18, "GameFontNormalSmall")
    UI.opacityLabel:SetJustifyH("CENTER")
    UI.opacitySlider = CreateFrame("Slider", nil, frame)
    UI.opacitySlider:SetSize(170, 14)
    UI.opacitySlider:SetPoint("TOPLEFT", frame, "TOPLEFT", 860, -66)
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
    UI.opacityValue = AddLabel(frame, "", 1036, -43, 48, 18, "GameFontHighlightSmall")
    ApplyBackgroundOpacity(frame, initialOpacity)
    UI.opacitySlider:SetValue(initialOpacity)
    UI.opacitySlider:SetScript("OnValueChanged", function(_, value)
        ApplyBackgroundOpacity(frame, value)
    end)

    local tabStrip = frame:CreateTexture(nil, "BACKGROUND")
    tabStrip:SetColorTexture(0.045, 0.035, 0.025, 0.95)
    tabStrip:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -112)
    tabStrip:SetSize(1424, 34)
    UI.tabs = {}
    local tabSpecs = {
        { "market", "All Items", 194 },
        { "economics", "Economics", 194 },
        { "crafting", "My Crafts", 194 },
        { "allcrafts", "All Crafts", 194 },
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
        button.background:SetColorTexture(0.12, 0.085, 0.045, 0.95)
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
        button.tabKey = key
        button:SetScript("OnClick", function() SetTab(key) end)
        if key == "market" then
            button.tooltipText = "Every item in the saved Auction House market snapshot."
        elseif key == "economics" then
            button.tooltipText = "Every market item with its best known craft cost, auction profit and vendor alternative where data is available."
        elseif key == "crafting" then
            button.tooltipText = "Only recipes you have learned and Market has captured from your profession windows, including losses and recipes with incomplete market prices."
        elseif key == "allcrafts" then
            button.tooltipText = "All supported profession recipes, including unlearned candidates. Borrowed or unknown acquisition sources are labelled; profit is withheld when quantities or prices are unknown."
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
        local color = { 0.43, 0.32, 0.17, 0.72 }
        local top = frame:CreateTexture(nil, "BORDER")
        top:SetColorTexture(unpack(color)); top:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y); top:SetSize(width, 1)
        local bottom = frame:CreateTexture(nil, "BORDER")
        bottom:SetColorTexture(unpack(color)); bottom:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y - height); bottom:SetSize(width, 1)
        local left = frame:CreateTexture(nil, "BORDER")
        left:SetColorTexture(unpack(color)); left:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y); left:SetSize(1, height)
        local right = frame:CreateTexture(nil, "BORDER")
        right:SetColorTexture(unpack(color)); right:SetPoint("TOPLEFT", frame, "TOPLEFT", x + width, y); right:SetSize(1, height)
    end
    AddPanelBorder(18, -158, 260, 650)
    AddPanelBorder(286, -158, 834, 650)
    AddPanelBorder(1126, -158, 300, 650)
    local function AddPanelHeader(x, y, width)
        local plate = frame:CreateTexture(nil, "ARTWORK")
        plate:SetColorTexture(0.19, 0.145, 0.075, 0.48)
        plate:SetPoint("TOPLEFT", frame, "TOPLEFT", x + 1, y)
        plate:SetSize(width - 2, 28)
        local rule = frame:CreateTexture(nil, "ARTWORK")
        rule:SetColorTexture(0.62, 0.46, 0.22, 0.55)
        rule:SetPoint("TOPLEFT", plate, "BOTTOMLEFT", 0, 0)
        rule:SetSize(width - 2, 1)
    end
    AddPanelHeader(18, -158, 260)
    AddPanelHeader(286, -158, 834)
    AddPanelHeader(1126, -158, 300)
    UI.filterHeading = AddLabel(frame, "Filters — All Items", 30, -166, 230, 24, "GameFontNormalLarge")
    UI.centerHeading = AddLabel(frame, "All Items", 302, -166, 500, 24, "GameFontNormalLarge")
    AddLabel(frame, "Search", 30, -198, 230, 18, "GameFontNormalSmall")
    UI.search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    UI.search:SetSize(230, 24)
    UI.search:SetPoint("TOPLEFT", frame, "TOPLEFT", 32, -220)
    UI.search:SetAutoFocus(false)
    UI.search:SetMaxLetters(80)
    UI.search:SetScript("OnTextChanged", function() UI.StartViewBuild() end)
    AttachFilterTooltip(UI.search, "Search", "Filter the active tab by item name, recipe name, profession or supported numeric ID.")

    RefreshProfessionOptions()
    UI.professionDropdown = CreateDropdown(frame, 230, 32, -284,
        function() return UI.professionOptions end,
        function() return UI.professionFilter end,
        function(value)
            UI.professionFilter = tonumber(value) or 0
            UI.StartViewBuild()
        end)
    UI.professionLabel = AddLabel(frame, "Profession", 30, -252, 230, 18, "GameFontNormalSmall")
    AttachFilterTooltip(UI.professionDropdown, "Profession", "Limit the active view to one profession. All professions keeps every supported profession in the results.")
    local function GetRoleOptions()
        local futureProvider = MM.ProfessionData and MM.ProfessionData.GetFutureProviderStatus
            and MM.ProfessionData.GetFutureProviderStatus()
        local futureReady = futureProvider and futureProvider.available
        if UI.activeTab == "allcrafts" then
            return {
                { text = "All recipe sources", value = "all",
                    tooltipTitle = "All Crafts",
                    tooltipText = "Show every supported known and unlearned recipe candidate." },
                { text = "Known by you", value = "known",
                    tooltipTitle = "Known recipes",
                    tooltipText = "Recipes recorded from this character's profession windows." },
                { text = "Unlearned: confirmed", value = "future", disabled = not futureReady,
                    tooltipTitle = "Unlearned, source recorded",
                    tooltipText = "Not learned by this character. The database records a Forever acquisition source." },
                { text = "Unlearned: borrowed", value = "borrowed", disabled = not futureReady,
                    tooltipTitle = "Unlearned, borrowed source",
                    tooltipText = "Not learned by this character. Acquisition information is borrowed from Vanilla and is not confirmed for Forever." },
                { text = "Unlearned: unknown", value = "unknown", disabled = not futureReady,
                    tooltipTitle = "Unlearned, source unknown",
                    tooltipText = "The recipe is present in the database, but its acquisition source is not established." },
            }
        elseif UI.activeTab == "crafting" then
            return { { text = "Known by you", value = "all" } }
        end
        local gatherReady = MM.ProfessionData and MM.ProfessionData.HasGatheringData
            and MM.ProfessionData.HasGatheringData()
        local options = {
            { text = "All item types", value = "all",
                tooltipTitle = "All item types",
                tooltipText = "Show every item in the selected view, regardless of profession relationship." },
            { text = "Known craft outputs", value = "known",
                tooltipTitle = "Known craft outputs",
                tooltipText = "Items produced by at least one recipe recorded as learned by this character." },
            { text = futureReady and "Unlearned · confirmed source" or "Unlearned crafts (install DB)",
                value = "future", disabled = not futureReady,
                tooltipTitle = "Unlearned, source recorded",
                tooltipText = "Items produced by recipes you have not learned where the database records a Forever acquisition source." },
            { text = "Unlearned: borrowed", value = "borrowed", disabled = not futureReady,
                tooltipTitle = "Unlearned, borrowed source",
                tooltipText = "Items produced by unlearned recipes whose acquisition information is borrowed from Vanilla and is not confirmed for Forever." },
            { text = "Unlearned: unknown", value = "unknown", disabled = not futureReady,
                tooltipTitle = "Unlearned, source unknown",
                tooltipText = "Items produced by unlearned recipes whose acquisition source is not established." },
            { text = gatherReady and "Gathering resources" or "Gathering data unavailable",
                value = "gather", disabled = not gatherReady,
                tooltipTitle = "Gathering resources",
                tooltipText = "Items mapped to Mining, Herbalism or Fishing. This classification does not mean your character can gather them at their current skill. Skinning coverage is not yet mapped." },
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
    UI.roleLabel = AddLabel(frame, "Recipe source / item role", 30, -334, 230, 18, "GameFontNormalSmall")
    AttachFilterTooltip(UI.roleDropdown, "Recipe source / item role", "Choose known, future, borrowed, unknown, gathering or material roles where supported. Hover individual menu options for their evidence definitions.")

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
    UI.tabFilterState[UI.activeTab] = { search = "", profession = 0, role = "all" }
    UI.tabFilterState[UI.activeTab].craftFilters = {}
    UI.resultCount = AddLabel(frame, "", 990, -166, 116, 20, "GameFontNormalSmall")
    UI.resultCount:SetWordWrap(false)
    UI.resultCount:SetJustifyH("RIGHT")

    UI.headerButtons = {}
    local headers = {
        { "Recipe / Item", 302, 205, "LEFT", "name" },
        { "Sale / Unit", 680, 96, "RIGHT", "price" },
        { "Materials (cost)", 510, 166, "LEFT", "materials" },
        { "At Price", 782, 70, "RIGHT", "depth" },
        { "Total", 858, 70, "RIGHT", "total" },
        { "Profit / Craft", 936, 170, "RIGHT", "profit" },
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
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        local function RowText(anchor, x, width, justify)
            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
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
                local craftingRow = UI.activeTab == "crafting" or UI.activeTab == "allcrafts"
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
            if selected and (UI.activeTab == "crafting" or UI.activeTab == "allcrafts") then
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

    UI.detailHeading = AddLabel(frame, "Selected item", 1142, -166, 268, 24, "GameFontNormalLarge")
    UI.detailHeading:SetWordWrap(false)
    UI.detailIcon = frame:CreateTexture(nil, "ARTWORK")
    UI.detailIcon:SetSize(42, 42)
    UI.detailIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 1142, -204)
    UI.detailIcon:Hide()
    UI.detailName = AddLabel(frame, "Choose an item", 1194, -204, 214, 28, "GameFontNormal")
    UI.detailName:SetWordWrap(true)
    if UI.detailName.SetNonSpaceWrap then UI.detailName:SetNonSpaceWrap(true) end
    UI.detailBadges = AddLabel(frame, "", 1194, -230, 214, 18, "GameFontDisableSmall")
    AddLabel(frame, "SALE PRICE / UNIT", 1142, -264, 128, 18, "GameFontNormalSmall")
    UI.detailPrice = AddLabel(frame, "—", 1274, -264, 132, 18, "GameFontHighlight")
    AddLabel(frame, "TOTAL LISTED", 1142, -290, 128, 18, "GameFontNormalSmall")
    UI.detailSupply = AddLabel(frame, "—", 1274, -290, 132, 18, "GameFontHighlight")
    UI.detailVariants = AddLabel(frame, "", 1142, -342, 268, 24, "GameFontDisableSmall")
    UI.detailVariants:SetWordWrap(true)
    if UI.detailVariants.SetNonSpaceWrap then UI.detailVariants:SetNonSpaceWrap(true) end
    UI.detailItemTooltip = CreateFrame("Button", nil, frame)
    UI.detailItemTooltip:SetPoint("TOPLEFT", frame, "TOPLEFT", 1142, -200)
    UI.detailItemTooltip:SetSize(46, 48)
    UI.detailItemTooltip:SetFrameLevel(frame:GetFrameLevel() + 2)
    UI.detailItemTooltip:SetScript("OnEnter", function(self)
        if UI.selectedItem then ShowMarketItemTooltip(self, UI.selectedItem, false) end
    end)
    UI.detailItemTooltip:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
    UI.detailRecipeTooltip = CreateFrame("Button", nil, frame)
    UI.detailRecipeTooltip:SetPoint("TOPLEFT", frame, "TOPLEFT", 1194, -200)
    UI.detailRecipeTooltip:SetSize(214, 28)
    UI.detailRecipeTooltip:SetFrameLevel(frame:GetFrameLevel() + 2)
    UI.detailRecipeTooltip:SetScript("OnEnter", function(self)
        if UI.selectedItem then ShowMarketItemTooltip(self, UI.selectedItem, true) end
    end)
    UI.detailRecipeTooltip:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
    AddLabel(frame, "AT PRICE", 1142, -316, 128, 18, "GameFontNormalSmall")
    UI.detailAtPrice = AddLabel(frame, "—", 1274, -316, 132, 18, "GameFontHighlight")
    UI.detailEconomics = AddLabel(frame,
        "Open each profession window once. Market records your known recipes automatically. Install LibProfessionDB 1.9.1 to identify supported unlearned recipes.",
        1142, -370, 268, 366, "GameFontHighlightSmall")
    UI.detailEconomics:SetWordWrap(true)
    if UI.detailEconomics.SetNonSpaceWrap then UI.detailEconomics:SetNonSpaceWrap(true) end
    UI.detailEconomics:SetJustifyH("LEFT")
    -- Keep the valuation/history footer inside the inspector's bottom edge.
    -- The graph's baseline is anchored to the footer bottom so bars always rise upward.
    UI.detailFooter = CreateFrame("Frame", nil, frame)
    UI.detailFooter:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1138, 52)
    UI.detailFooter:SetSize(280, 122)
    UI.detailProfit = AddLabel(UI.detailFooter, "Automatic recipe valuation", 4, -2, 272, 36, "GameFontNormalLarge")
    UI.detailProfit:SetWordWrap(true)
    if UI.detailProfit.SetNonSpaceWrap then UI.detailProfit:SetNonSpaceWrap(true) end
    UI.historyText = AddLabel(UI.detailFooter, "", 4, -30, 272, 42, "GameFontHighlightSmall")
    UI.historyText:SetWordWrap(true)
    if UI.historyText.SetNonSpaceWrap then UI.historyText:SetNonSpaceWrap(true) end
    UI.historyGraph = CreateFrame("Frame", nil, UI.detailFooter)
    UI.historyGraph:SetPoint("BOTTOMLEFT", UI.detailFooter, "BOTTOMLEFT", 4, 0)
    UI.historyGraph:SetSize(236, 60)
    UI.historyBarLabels = {}
    for i = 1, 4 do
        local label = UI.historyGraph:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetWidth(54)
        label:SetJustifyH("CENTER")
        UI.historyBarLabels[i] = label
        label:Hide()
        local bar = UI.historyGraph:CreateTexture(nil, "ARTWORK")
        bar:SetColorTexture(0.72, 0.62, 0.36, 0.95)
        UI.historyBars[i] = bar
        bar:Hide()
    end

    frame:SetScript("OnShow", function(self)
        self:SetFrameStrata("DIALOG")
        self:SetToplevel(true)
        if type(self.Raise) == "function" then self:Raise() end
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
    return frame
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
    if UI.activeTab == "crafting" or UI.activeTab == "allcrafts"
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

function UI.AttachAuctionHouseButton()
    local parents = {}
    if _G.AuctionHouseFrame then parents[#parents + 1] = _G.AuctionHouseFrame end
    if _G.AuctionFrame then parents[#parents + 1] = _G.AuctionFrame end
    local attached = false
    for _, parent in ipairs(parents) do
        if parent and type(parent.IsObjectType) == "function" and parent:IsObjectType("Frame") then
            attached = true
            local button = UI.auctionHouseButtons[parent]
            if not button then
                button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
                button:SetSize(116, 20)
                button:SetFrameStrata("TOOLTIP")
                button:SetToplevel(true)
                button:SetFrameLevel((parent:GetFrameLevel() or 0) + 8)
                -- Keep the launcher in the header strip, clear of the portrait,
                -- browse controls and the Auction House close button.
                button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -42, -34)
                button:SetText("Modulo Market")
                button:SetScript("OnClick", UI.Show)
                UI.auctionHouseButtons[parent] = button
                if type(parent.HookScript) == "function" then
                    parent:HookScript("OnShow", function() button:Show() end)
                end
            end
            button:Show()
            UI.auctionHouseButton = button
        end
    end
    return attached
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

