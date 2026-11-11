local MM = _G.ModuloMarket
if not MM then return end

local API = _G.C_AuctionHouse
local ITEM_API = _G.C_Item
local BATCH_SIZE = 250
local ITEM_REQUESTS_PER_FRAME = 20
local RESPONSE_TIMEOUT = 90
local SCAN_TIMEOUT = 900
local MAX_AUCTIONS = 500000
local REPLICATE_COOLDOWN = 900

local Replicate = {
    active = false,
    pendingConfirmation = false,
    attemptedThisSession = false,
    stage = "idle",
}
MM.Replicate = Replicate

local function Now()
    return type(_G.GetTime) == "function" and _G.GetTime() or 0
end

local function WallTime()
    return type(_G.time) == "function" and _G.time() or 0
end

local function SetStatus(message)
    Replicate.status = tostring(message or "")
    if MM.MarketUI and MM.MarketUI.SetStatus then
        MM.MarketUI.SetStatus(Replicate.status)
    elseif MM.Scanner and MM.Scanner.SetStatus then
        MM.Scanner.SetStatus(Replicate.status)
    end
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return false, "API_MISSING" end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then return false, tostring(a) end
    return true, a, b, c
end

local function PackReturns(...)
    return { n = select("#", ...), ... }
end

local function GetCooldownRemaining(now)
    now = tonumber(now) or WallTime()
    local previous = type(MM.db) == "table" and tonumber(MM.db.replicateProbeAttemptAt) or nil
    if not previous then return 0 end
    if now < previous then return REPLICATE_COOLDOWN end
    return math.max(0, REPLICATE_COOLDOWN - (now - previous))
end

local function IsAuctionHouseOpen()
    return MM.Scanner and MM.Scanner.IsAuctionHouseOpen
        and MM.Scanner.IsAuctionHouseOpen() == true
end

local function CanScanSafely()
    if MM.Scanner and MM.Scanner.CanScanSafely then
        return MM.Scanner.CanScanSafely()
    end
    return false, "Market safety gate unavailable"
end

local function SplitColon(value)
    local result = {}
    value = tostring(value or "") .. ":"
    for field in value:gmatch("(.-):") do
        result[#result + 1] = field
    end
    return result
end

local function ParseItemLink(itemLink, itemID)
    if type(itemLink) ~= "string" or itemLink == "" then return nil, "NO_ITEM_LINK" end
    local body = itemLink:match("|H([^|]+)|h") or itemLink
    local fields = SplitColon(body)
    local linkType = fields[1]
    local key = {
        itemID = tonumber(itemID) or tonumber(fields[2]),
        itemSuffix = 0,
        bonusLists = {},
        modifiers = {},
    }
    if linkType == "battlepet" then
        key.battlePetSpeciesID = tonumber(fields[2])
        key.isPet = true
        if not key.battlePetSpeciesID then return nil, "INVALID_BATTLE_PET_LINK" end
        return key
    end
    if linkType ~= "item" or not key.itemID or key.itemID <= 0 then
        return nil, "UNSUPPORTED_ITEM_LINK"
    end
    local linkItemID = tonumber(fields[2])
    if not linkItemID or linkItemID ~= key.itemID then
        return nil, "ITEM_LINK_ID_MISMATCH"
    end

    key.itemSuffix = tonumber(fields[8]) or 0
    local bonusCount = tonumber(fields[14]) or 0
    if bonusCount < 0 or bonusCount > 128 then return nil, "INVALID_BONUS_COUNT" end
    local cursor = 15
    for i = 1, bonusCount do
        local bonusID = tonumber(fields[cursor])
        if not bonusID then return nil, "INVALID_BONUS_ID" end
        key.bonusLists[#key.bonusLists + 1] = bonusID
        cursor = cursor + 1
    end

    local modifierCount = tonumber(fields[cursor]) or 0
    cursor = cursor + 1
    if modifierCount < 0 or modifierCount > 64 then return nil, "INVALID_MODIFIER_COUNT" end
    for i = 1, modifierCount do
        local modifierType = tonumber(fields[cursor])
        local modifierValue = tonumber(fields[cursor + 1])
        if not modifierType or not modifierValue then return nil, "INVALID_MODIFIER" end
        key.modifiers[#key.modifiers + 1] = {
            type = modifierType,
            value = modifierValue,
        }
        cursor = cursor + 2
    end

    if ITEM_API and type(ITEM_API.GetDetailedItemLevelInfo) == "function" then
        local okLevel, level = pcall(ITEM_API.GetDetailedItemLevelInfo, itemLink)
        if okLevel and type(level) == "number" then key.itemLevel = level end
    end
    return key
end

local function ItemKeyIdentity(itemKey)
    if type(itemKey) ~= "table" then return nil end
    local parts = {
        tostring(itemKey.itemID or ""),
        tostring(itemKey.itemLevel or ""),
        tostring(itemKey.itemSuffix or ""),
        tostring(itemKey.battlePetSpeciesID or ""),
        tostring(itemKey.isPet or ""),
    }
    if type(itemKey.bonusLists) == "table" then
        for i = 1, #itemKey.bonusLists do
            parts[#parts + 1] = "b" .. tostring(itemKey.bonusLists[i])
        end
    end
    if type(itemKey.modifiers) == "table" then
        for i = 1, #itemKey.modifiers do
            local modifier = itemKey.modifiers[i]
            if type(modifier) == "table" then
                parts[#parts + 1] = "m" .. tostring(modifier.type or "") .. ":" .. tostring(modifier.value or "")
            end
        end
    end
    return table.concat(parts, ":")
end

local function GetItemClassID(itemID)
    if not ITEM_API or type(ITEM_API.GetItemInfoInstant) ~= "function" then return nil end
    local ok, _, _, _, _, _, classID = pcall(ITEM_API.GetItemInfoInstant, itemID)
    if ok then return tonumber(classID) end
    return nil
end

local function NeedsItemData(itemID, hasAllInfo, itemLink, itemKey)
    if hasAllInfo ~= true or not itemLink or not itemKey then return true end
    local classID = GetItemClassID(itemID)
    if classID == 2 or classID == 4 then
        return type(itemKey.itemLevel) ~= "number"
    end
    return false
end

local function GetItemName(itemID, suppliedName)
    if type(suppliedName) == "string" and suppliedName ~= "" then return suppliedName end
    if ITEM_API and type(ITEM_API.GetItemNameByID) == "function" then
        local ok, name = pcall(ITEM_API.GetItemNameByID, itemID)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    return nil
end

local function NewScan(total, startedAt, startedAtWallTime)
    return {
        startedAt = tonumber(startedAt) or Now(),
        timestamp = tonumber(startedAtWallTime) or WallTime(),
        total = total,
        nextIndex = 0,
        processed = 0,
        aggregates = {},
        aggregateCount = 0,
        pendingByItemID = {},
        loadQueue = {},
        loadHead = 1,
        requestedItemIDs = {},
        itemDataResolved = {},
        pendingLoadCount = 0,
        retryQueue = {},
        retryHead = 1,
        unresolvedAuctionCount = 0,
        invalidItemIDCount = 0,
        invalidStackCount = 0,
        infoErrorCount = 0,
        linkErrorCount = 0,
        unpricedAuctionCount = 0,
        unpricedQuantity = 0,
        pricedAuctionCount = 0,
        pricedQuantity = 0,
        totalQuantity = 0,
        petAuctionCount = 0,
    }
end

local function MarkUnresolved(scan, count)
    scan.unresolvedAuctionCount = scan.unresolvedAuctionCount + (tonumber(count) or 1)
end

local function AggregateRecord(scan, index, info, itemLink)
    local itemID = tonumber(info[17])
    local stackCount = tonumber(info[3])
    local buyoutCopper = tonumber(info[10]) or 0
    if not itemID or itemID <= 0 then
        scan.invalidItemIDCount = scan.invalidItemIDCount + 1
        MarkUnresolved(scan)
        return false
    end
    if not stackCount or stackCount <= 0 then
        scan.invalidStackCount = scan.invalidStackCount + 1
        MarkUnresolved(scan)
        return false
    end

    local itemKey, parseError = ParseItemLink(itemLink, itemID)
    if not itemKey then
        scan.linkErrorCount = scan.linkErrorCount + 1
        MarkUnresolved(scan)
        return false
    end
    local identity = ItemKeyIdentity(itemKey)
    if not identity then
        MarkUnresolved(scan)
        return false
    end

    local row = scan.aggregates[identity]
    if not row then
        row = {
            key = identity,
            itemKey = itemKey,
            itemID = itemID,
            itemLevel = itemKey.itemLevel,
            itemSuffix = itemKey.itemSuffix,
            battlePetSpeciesID = itemKey.battlePetSpeciesID,
            isPet = itemKey.isPet,
            bonusLists = itemKey.bonusLists,
            modifiers = itemKey.modifiers,
            itemName = GetItemName(itemID, info[1]),
            itemLink = itemLink,
            minPriceCopper = nil,
            minPriceQuantity = 0,
            totalQuantity = 0,
            pricedQuantity = 0,
            unpricedQuantity = 0,
            auctionCount = 0,
            pricedAuctionCount = 0,
            unpricedAuctionCount = 0,
        }
        scan.aggregates[identity] = row
        scan.aggregateCount = scan.aggregateCount + 1
    elseif (not row.itemName or row.itemName == "") and type(info[1]) == "string" and info[1] ~= "" then
        row.itemName = info[1]
    end

    row.totalQuantity = row.totalQuantity + stackCount
    row.auctionCount = row.auctionCount + 1
    scan.totalQuantity = scan.totalQuantity + stackCount

    if buyoutCopper > 0 then
        local unitPrice = math.ceil(buyoutCopper / stackCount)
        row.pricedQuantity = row.pricedQuantity + stackCount
        row.pricedAuctionCount = row.pricedAuctionCount + 1
        scan.pricedQuantity = scan.pricedQuantity + stackCount
        scan.pricedAuctionCount = scan.pricedAuctionCount + 1
        if not row.minPriceCopper or unitPrice < row.minPriceCopper then
            row.minPriceCopper = unitPrice
            row.minPriceQuantity = stackCount
        elseif unitPrice == row.minPriceCopper then
            row.minPriceQuantity = row.minPriceQuantity + stackCount
        end
    else
        row.unpricedQuantity = row.unpricedQuantity + stackCount
        row.unpricedAuctionCount = row.unpricedAuctionCount + 1
        scan.unpricedQuantity = scan.unpricedQuantity + stackCount
        scan.unpricedAuctionCount = scan.unpricedAuctionCount + 1
    end
    if itemKey.isPet then scan.petAuctionCount = scan.petAuctionCount + 1 end
    return true
end

local function QueueForItemData(scan, itemID, index)
    if scan.itemDataResolved[itemID] == true then
        scan.retryQueue[#scan.retryQueue + 1] = index
        return
    elseif scan.itemDataResolved[itemID] == false then
        MarkUnresolved(scan)
        return
    end
    local pending = scan.pendingByItemID[itemID]
    if not pending then
        pending = {}
        scan.pendingByItemID[itemID] = pending
        if not scan.requestedItemIDs[itemID] then
            scan.requestedItemIDs[itemID] = true
            scan.loadQueue[#scan.loadQueue + 1] = itemID
        end
    end
    pending[#pending + 1] = index
end

local function ReadAuction(scan, index, isRetry)
    local okInfo, info = pcall(function()
        return PackReturns(API.GetReplicateItemInfo(index))
    end)
    if not okInfo then
        scan.infoErrorCount = scan.infoErrorCount + 1
        MarkUnresolved(scan)
        return
    end

    local itemID = tonumber(info[17])
    if not itemID or itemID <= 0 then
        scan.invalidItemIDCount = scan.invalidItemIDCount + 1
        MarkUnresolved(scan)
        return
    end
    local stackCount = tonumber(info[3])
    if not stackCount or stackCount <= 0 then
        scan.invalidStackCount = scan.invalidStackCount + 1
        MarkUnresolved(scan)
        return
    end

    local okLink, itemLink = pcall(API.GetReplicateItemLink, index)
    if not okLink then
        scan.linkErrorCount = scan.linkErrorCount + 1
        itemLink = nil
    end
    local itemKey = itemLink and ParseItemLink(itemLink, itemID) or nil

    if not isRetry and NeedsItemData(itemID, info[18], itemLink, itemKey) then
        QueueForItemData(scan, itemID, index)
        return
    end
    if isRetry and (not itemLink or not itemKey or NeedsItemData(itemID, info[18], itemLink, itemKey)) then
        MarkUnresolved(scan)
        return
    end
    if not itemLink or not itemKey then
        if not isRetry then
            QueueForItemData(scan, itemID, index)
        else
            MarkUnresolved(scan)
        end
        return
    end
    AggregateRecord(scan, index, info, itemLink)
end

local function QueuePendingRetries(scan, itemID, success)
    local pending = scan.pendingByItemID[itemID]
    scan.itemDataResolved[itemID] = success == true
    if not pending then return end
    scan.pendingByItemID[itemID] = nil
    if not success then
        MarkUnresolved(scan, #pending)
        return
    end
    for i = 1, #pending do
        scan.retryQueue[#scan.retryQueue + 1] = pending[i]
    end
end

local function RequestQueuedItemData(scan, itemID)
    local pending = scan.pendingByItemID[itemID]
    if not pending then return end
    local cached = false
    if ITEM_API and type(ITEM_API.IsItemDataCachedByID) == "function" then
        local ok, value = pcall(ITEM_API.IsItemDataCachedByID, itemID)
        cached = ok and value == true
    end
    if cached then
        QueuePendingRetries(scan, itemID, true)
        return
    end
    if not ITEM_API or type(ITEM_API.RequestLoadItemDataByID) ~= "function" then
        QueuePendingRetries(scan, itemID, false)
        return
    end
    scan.pendingLoadCount = scan.pendingLoadCount + 1
    local ok, err = pcall(ITEM_API.RequestLoadItemDataByID, itemID)
    if not ok then
        scan.pendingLoadCount = math.max(0, scan.pendingLoadCount - 1)
        QueuePendingRetries(scan, itemID, false)
        return
    end
end

local function StopEvents()
    if Replicate.frame then
        Replicate.frame:SetScript("OnUpdate", nil)
        Replicate.frame:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE")
        Replicate.frame:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
        Replicate.frame:UnregisterEvent("AUCTION_HOUSE_CLOSED")
    end
end

local function Abort(reason)
    local scan = Replicate.scan
    StopEvents()
    Replicate.active = false
    Replicate.stage = "idle"
    Replicate.scan = nil
    if scan then
        SetStatus(string.format(
            "Full Market scan stopped — %s. Previous saved market data is unchanged. Processed %d/%d auctions; %d variants built; %d records unresolved.",
            tostring(reason), scan.processed, scan.total, scan.aggregateCount, scan.unresolvedAuctionCount))
    else
        SetStatus("Full Market scan stopped — " .. tostring(reason) .. ". Previous saved market data is unchanged; no retry will occur.")
    end
    if MM.MarketUI and MM.MarketUI.RefreshActions then MM.MarketUI.RefreshActions() end
end

local function SaveHistoryPoint(snapshot)
    if type(MM.db) ~= "table" or type(snapshot.rows) ~= "table" then return end
    MM.db.marketHistory = MM.db.marketHistory or {}
    local point = {
        timestamp = snapshot.timestamp,
        source = "C_AuctionHouse.ReplicateItems",
        items = {},
    }
    for i = 1, #snapshot.rows do
        local row = snapshot.rows[i]
        local itemID = tonumber(row.itemID)
        if itemID then
            local entry = point.items[itemID]
            local quantity = tonumber(row.totalQuantity) or 0
            if not entry then
                point.items[itemID] = {
                    price = tonumber(row.minPriceCopper),
                    quantity = quantity,
                }
            else
                entry.quantity = entry.quantity + quantity
                local price = tonumber(row.minPriceCopper)
                if price and price > 0 and (not entry.price or price < entry.price) then
                    entry.price = price
                end
            end
        end
    end
    local history = MM.db.marketHistory
    history[#history + 1] = point
    while #history > 4 do table.remove(history, 1) end
end

local function Finish(scan)
    local duration = math.max(0, Now() - scan.startedAt)
    local rows = {}
    for _, row in pairs(scan.aggregates) do
        rows[#rows + 1] = row
    end
    table.sort(rows, function(a, b)
        local an = string.lower(tostring(a.itemName or ""))
        local bn = string.lower(tostring(b.itemName or ""))
        if an == bn then return tostring(a.key) < tostring(b.key) end
        return an < bn
    end)

    local complete = scan.processed == scan.total
        and scan.unresolvedAuctionCount == 0
        and scan.invalidItemIDCount == 0
        and scan.invalidStackCount == 0
        and scan.infoErrorCount == 0
        and scan.linkErrorCount == 0

    if not complete then
        Abort(string.format(
            "acquisition finished with incomplete records (invalid IDs %d, invalid stacks %d, info errors %d, link errors %d)",
            scan.invalidItemIDCount, scan.invalidStackCount, scan.infoErrorCount, scan.linkErrorCount))
        return
    end

    local version, build, buildDate, interface = GetBuildInfo()
    local snapshot = {
        schemaVersion = 2,
        complete = true,
        dataComplete = true,
        timestamp = WallTime(),
        scanStartedAt = scan.timestamp,
        timestampText = type(_G.date) == "function" and _G.date("%Y-%m-%d %H:%M:%S") or "unknown",
        clientVersion = tostring(version or "unknown"),
        clientBuild = tostring(build or "unknown"),
        interface = tonumber(interface) or 0,
        source = "C_AuctionHouse.ReplicateItems",
        priceUnit = "copper",
        resultCount = #rows,
        auctionCount = scan.total,
        processedAuctionCount = scan.processed,
        totalQuantity = scan.totalQuantity,
        pricedQuantity = scan.pricedQuantity,
        unpricedQuantity = scan.unpricedQuantity,
        pricedAuctionCount = scan.pricedAuctionCount,
        unpricedAuctionCount = scan.unpricedAuctionCount,
        minPriceDepthKnown = true,
        scanDurationSeconds = duration,
        rows = rows,
    }
    if type(MM.db) ~= "table" then
        Abort("SavedVariables unavailable; complete data was not committed")
        return
    end

    -- Transactional last-known-good replacement: only this complete, fully
    -- identified dataset replaces the prior Market snapshot.
    SaveHistoryPoint(snapshot)
    MM.db.lastMarketSnapshot = snapshot
    MM.db.lastMarketScanAt = snapshot.timestamp
    Replicate.active = false
    Replicate.stage = "idle"
    Replicate.scan = nil
    StopEvents()
    if MM.MarketUI and MM.MarketUI.Refresh then MM.MarketUI.Refresh() end
    SetStatus(string.format(
        "Market scan complete: %d item variants from %d auctions in %.1fs. %d units priced; %d units have no buyout. Previous data safely replaced.",
        #rows, scan.total, duration, scan.pricedQuantity, scan.unpricedQuantity))
    if MM.Print then
        MM.Print(string.format("Market snapshot saved: %d variants from %d auctions in %.1fs.",
            #rows, scan.total, duration))
    end
end

local function OnInitialReplicateResponse()
    if not Replicate.active or Replicate.stage ~= "waiting_response" then return end
    Replicate.frame:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE")
    local okCount, count = SafeCall(API and API.GetNumReplicateItems)
    if not okCount or type(count) ~= "number" or count <= 0 then
        Abort("Replicate response arrived but the auction count was unavailable")
        return
    end
    if count > MAX_AUCTIONS then
        Abort(string.format("auction count %d exceeds the safety limit %d", count, MAX_AUCTIONS))
        return
    end
    local scan = NewScan(count, Replicate.requestStartedAt, Replicate.requestStartedAtWallTime)
    Replicate.scan = scan
    Replicate.stage = "reading"
    Replicate.frame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    SetStatus(string.format("Reading full auction list: 0/%d auctions. Processing %d records per frame; missing item data is queued separately.",
        count, BATCH_SIZE))
end

local function OnEvent(_, event, ...)
    if event == "REPLICATE_ITEM_LIST_UPDATE" then
        OnInitialReplicateResponse()
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        if not Replicate.active or not Replicate.scan then return end
        local itemID, success = ...
        itemID = tonumber(itemID)
        if not itemID or not Replicate.scan.pendingByItemID[itemID] then return end
        Replicate.scan.pendingLoadCount = math.max(0, Replicate.scan.pendingLoadCount - 1)
        QueuePendingRetries(Replicate.scan, itemID, success ~= false)
    elseif event == "AUCTION_HOUSE_CLOSED" then
        Abort("Auction House closed during acquisition")
    end
end

local function OnUpdate(_, elapsed)
    if not Replicate.active then return end
    local scan = Replicate.scan
    if Replicate.stage == "waiting_response" then
        if Now() - Replicate.requestStartedAt >= RESPONSE_TIMEOUT then
            Abort("no initial Replicate response within 90 seconds; attempt consumed and no retry will occur")
        end
        return
    end
    if not scan then return end
    if Now() - scan.startedAt >= SCAN_TIMEOUT then
        Abort("15-minute processing safety timeout")
        return
    end
    if not IsAuctionHouseOpen() then
        Abort("Auction House is no longer open")
        return
    end
    local safe, reason = CanScanSafely()
    if not safe then
        Abort("Sell-tab safety gate: " .. tostring(reason))
        return
    end

    local requestStop = math.min(#scan.loadQueue, scan.loadHead + ITEM_REQUESTS_PER_FRAME - 1)
    while scan.loadHead <= requestStop do
        local itemID = scan.loadQueue[scan.loadHead]
        scan.loadHead = scan.loadHead + 1
        RequestQueuedItemData(scan, itemID)
    end

    local retryStop = math.min(#scan.retryQueue, scan.retryHead + BATCH_SIZE - 1)
    while scan.retryHead <= retryStop do
        local index = scan.retryQueue[scan.retryHead]
        scan.retryHead = scan.retryHead + 1
        ReadAuction(scan, index, true)
    end

    local stopIndex = math.min(scan.total - 1, scan.nextIndex + BATCH_SIZE - 1)
    while scan.nextIndex <= stopIndex do
        ReadAuction(scan, scan.nextIndex, false)
        scan.nextIndex = scan.nextIndex + 1
        scan.processed = scan.processed + 1
    end

    if scan.nextIndex >= scan.total
        and scan.loadHead > #scan.loadQueue
        and scan.retryHead > #scan.retryQueue
        and scan.pendingLoadCount == 0 then
        -- A pending map entry with no load event is not treated as complete.
        local pendingCount = 0
        for _ in pairs(scan.pendingByItemID) do pendingCount = pendingCount + 1 end
        if pendingCount > 0 then
            Abort(string.format("%d item-data requests did not complete", pendingCount))
            return
        end
        Finish(scan)
        return
    end

    if scan.processed % 5000 < BATCH_SIZE then
        SetStatus(string.format(
            "Building Market database: %d/%d auctions (%.1f%%); %d variants; %d item-data requests pending; %d unresolved.",
            scan.processed, scan.total, (scan.processed / scan.total) * 100,
            scan.aggregateCount, scan.pendingLoadCount, scan.unresolvedAuctionCount))
    end
end

function Replicate.Prepare()
    if Replicate.active then
        SetStatus("A full Market scan is already running.")
        return
    end
    if MM.Scanner and MM.Scanner.active then
        SetStatus("Stop the Browse snapshot before preparing a Replicate Market scan.")
        return
    end
    if not IsAuctionHouseOpen() then
        SetStatus("Open the Auction House before starting a full Market scan.")
        return
    end
    local safe, reason = CanScanSafely()
    if not safe then
        SetStatus("Market scan blocked — " .. tostring(reason) .. ". Clear the Sell tab first.")
        return
    end
    if not API or type(API.ReplicateItems) ~= "function"
        or type(API.GetNumReplicateItems) ~= "function"
        or type(API.GetReplicateItemInfo) ~= "function"
        or type(API.GetReplicateItemLink) ~= "function" then
        SetStatus("Required Replicate APIs are unavailable. No request sent.")
        return
    end
    if Replicate.attemptedThisSession or (MM.Scanner and MM.Scanner.replicateProbeAttemptedThisSession) then
        SetStatus("A Replicate request was already attempted this session. No retry permitted.")
        return
    end
    local remaining = GetCooldownRemaining()
    if remaining > 0 then
        SetStatus(string.format("Market's local Replicate timer has %d seconds remaining. Another addon may have a newer shared cooldown; no request sent.",
            math.ceil(remaining)))
        return
    end
    Replicate.pendingConfirmation = true
    if MM.MarketUI and MM.MarketUI.RefreshActions then MM.MarketUI.RefreshActions() end
    SetStatus("Full scan: shared 15-minute cooldown. Make sure no other addon scanned in the last 15 minutes; keep the Auction House open. One request only. Incomplete scans keep your previous data.")
    if MM.MarketUI and MM.MarketUI.RefreshActions then MM.MarketUI.RefreshActions() end
end

function Replicate.CancelPrepare()
    Replicate.pendingConfirmation = false
    if MM.MarketUI and MM.MarketUI.RefreshActions then MM.MarketUI.RefreshActions() end
    SetStatus("Full Market scan confirmation cancelled. No request sent.")
end

function Replicate.Confirm()
    if not Replicate.pendingConfirmation then
        SetStatus("Review the full Market scan warning before confirming.")
        return
    end
    if Replicate.attemptedThisSession or (MM.Scanner and MM.Scanner.replicateProbeAttemptedThisSession) then
        Replicate.pendingConfirmation = false
        SetStatus("A Replicate request was already attempted this session. No retry permitted.")
        return
    end
    if MM.Scanner and MM.Scanner.active or not IsAuctionHouseOpen() then
        Replicate.CancelPrepare()
        SetStatus("Scan cancelled: keep the Auction House open and stop the Browse scan first.")
        return
    end
    local safe, reason = CanScanSafely()
    if not safe then
        Replicate.CancelPrepare()
        SetStatus("Scan cancelled by Sell-tab safety gate: " .. tostring(reason))
        return
    end
    if GetCooldownRemaining() > 0 then
        Replicate.CancelPrepare()
        SetStatus("Scan cancelled: Market's local 15-minute timer remains active. Another addon may have consumed the shared cooldown.")
        return
    end

    local now = WallTime()
    Replicate.attemptedThisSession = true
    if MM.Scanner then MM.Scanner.replicateProbeAttemptedThisSession = true end
    if type(MM.db) == "table" then MM.db.replicateProbeAttemptAt = now end
    Replicate.pendingConfirmation = false
    Replicate.active = true
    Replicate.stage = "waiting_response"
    Replicate.requestStartedAt = Now()
    Replicate.requestStartedAtWallTime = now
    Replicate.frame:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
    Replicate.frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
    Replicate.frame:SetScript("OnUpdate", OnUpdate)
    if MM.MarketUI and MM.MarketUI.RefreshActions then MM.MarketUI.RefreshActions() end
    SetStatus("One full Replicate request sent. Waiting up to 90 seconds for the initial response. No retry will occur.")
    local ok, err = pcall(API.ReplicateItems)
    if not ok then
        Abort("ReplicateItems raised an error: " .. tostring(err) .. "; attempt consumed")
    end
end

function Replicate.GetState()
    return {
        active = Replicate.active,
        stage = Replicate.stage,
        pendingConfirmation = Replicate.pendingConfirmation,
        attemptedThisSession = Replicate.attemptedThisSession
            or (MM.Scanner and MM.Scanner.replicateProbeAttemptedThisSession == true) or false,
        cooldownRemaining = GetCooldownRemaining(),
    }
end

Replicate.frame = CreateFrame("Frame")
Replicate.frame:SetScript("OnEvent", OnEvent)

