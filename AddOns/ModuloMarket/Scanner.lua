local MM = _G.ModuloMarket
if not MM then return end

local API = _G.C_AuctionHouse
local MAX_RESULTS = 25000
local EXPORT_ROWS_PER_PART = 2000
local MAX_PAGES = 500
local MAX_DURATION = 900
local REPLICATE_COOLDOWN_SECONDS = 900
local REPLICATE_PROBE_TIMEOUT_SECONDS = 90
local REPLICATE_INSPECT_LIMIT = 250
local REPLICATE_INSPECT_PER_FRAME = 25
local REPLICATE_INSPECT_TIMEOUT_SECONDS = 20

local Scanner = {
    active = false,
    throttleWaitStartedAt = nil,
    throttleWaitSeconds = 0,
    lastScanDurationSeconds = 0,
    rows = {},
    rowKeys = {},
    pageCount = 0,
    startedAt = 0,
    waitingForResults = false,
    needsNextPage = false,
    replicateProbeAttemptedThisSession = false,
    replicateProbePendingConfirmation = false,
    replicateProbeActive = false,
    replicateInspectActive = false,
}
MM.Scanner = Scanner

local function Now()
    return type(_G.GetTime) == "function" and _G.GetTime() or 0
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return false, "API_MISSING"
    end
    local ok, a, b = pcall(fn, ...)
    if not ok then return false, tostring(a) end
    return true, a, b
end

local function IsAuctionHouseOpen()
    local frame = _G.AuctionHouseFrame
    return frame and type(frame.IsShown) == "function" and frame:IsShown()
end

-- The Forever Auction House shares its browse/throttle channel with selling.
-- A conservative fail-closed gate prevents Market from starting or continuing
-- while the player has an item/commodity staged in the Sell tab.
local function HasActiveSellItem()
    local frame = _G.AuctionHouseFrame
    if not frame then return false end

    if type(frame.IsListingAuctions) == "function" then
        local ok, listing = pcall(frame.IsListingAuctions, frame)
        if ok and listing == true then
            local itemSell = frame.ItemSellFrame
            if itemSell and type(itemSell.GetItem) == "function" then
                local okItem, item = pcall(itemSell.GetItem, itemSell)
                if okItem and item ~= nil then return true end
            end
            local commoditiesSell = frame.CommoditiesSellFrame
            if commoditiesSell and type(commoditiesSell.GetItem) == "function" then
                local okItem, item = pcall(commoditiesSell.GetItem, commoditiesSell)
                if okItem and item ~= nil then return true end
            end
            -- If the client says the frame is in a listing mode but the child
            -- accessors are unavailable, fail closed rather than guess safety.
            return true
        end
    end

    local itemSell = frame.ItemSellFrame
    if itemSell and type(itemSell.GetItem) == "function" then
        local okItem, item = pcall(itemSell.GetItem, itemSell)
        if okItem and item ~= nil then return true end
    end
    local commoditiesSell = frame.CommoditiesSellFrame
    if commoditiesSell and type(commoditiesSell.GetItem) == "function" then
        local okItem, item = pcall(commoditiesSell.GetItem, commoditiesSell)
        if okItem and item ~= nil then return true end
    end

    return false
end

local function CanScanSafely()
    if HasActiveSellItem() then
        return false, "a Sell-tab item is currently staged"
    end
    return true
end

Scanner.IsAuctionHouseOpen = IsAuctionHouseOpen
Scanner.CanScanSafely = CanScanSafely

local function SetStatus(text)
    Scanner.statusText = tostring(text or "")
    if Scanner.status then Scanner.status:SetText(Scanner.statusText) end
    if MM.MarketUI and MM.MarketUI.SetStatus then
        MM.MarketUI.SetStatus(Scanner.statusText)
    end
end

local function GetLastReplicateAttemptTimestamp()
    local saved = type(MM.db) == "table" and tonumber(MM.db.replicateProbeAttemptAt) or nil
    local memory = tonumber(Scanner.replicateProbeAttemptTimestamp)
    if saved and memory then return math.max(saved, memory) end
    return saved or memory
end

local function GetReplicateCooldownRemaining(now)
    now = tonumber(now) or (type(_G.time) == "function" and _G.time() or 0)
    local previous = GetLastReplicateAttemptTimestamp()
    if not previous then return 0 end
    -- A backwards wall-clock jump is not evidence that the shared cooldown elapsed.
    if now < previous then return REPLICATE_COOLDOWN_SECONDS end
    return math.max(0, REPLICATE_COOLDOWN_SECONDS - (now - previous))
end

local function FormatRelativeAge(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    if seconds < 60 then return "less than 1m ago" end
    if seconds < 3600 then return string.format("%dm ago", math.floor(seconds / 60)) end
    if seconds < 86400 then return string.format("%dh ago", math.floor(seconds / 3600)) end
    return string.format("%dd ago", math.floor(seconds / 86400))
end

local function RefreshScanDisplay()
    local now = type(_G.time) == "function" and _G.time() or 0
    local snapshot = Scanner.completedSnapshot
    if type(snapshot) ~= "table" and type(MM.db) == "table" then
        snapshot = MM.db.lastSnapshot
    end
    if Scanner.dataAgeText then
        local stamp = type(snapshot) == "table" and tonumber(snapshot.timestamp) or nil
        if stamp and stamp > 0 and now >= stamp then
            Scanner.dataAgeText:SetText("Auction House data from " .. FormatRelativeAge(now - stamp))
        elseif stamp then
            Scanner.dataAgeText:SetText("Auction House data age unknown")
        else
            Scanner.dataAgeText:SetText("No saved Auction House data yet")
        end
    end

    if Scanner.replicateProbeButton then
        local remaining = GetReplicateCooldownRemaining(now)
        if Scanner.replicateProbeActive then
            Scanner.replicateProbeButton:SetText("Waiting for response")
        elseif Scanner.replicateProbePendingConfirmation then
            Scanner.replicateProbeButton:SetText("Probe warning ready")
        elseif remaining > 0 then
            local label
            if remaining >= 60 then
                label = string.format("Scan in %dm", math.ceil(remaining / 60))
            else
                label = string.format("Scan in %ds", math.ceil(remaining))
            end
            Scanner.replicateProbeButton:SetText(label)
        elseif Scanner.replicateProbeAttemptedThisSession then
            Scanner.replicateProbeButton:SetText("Attempt used this session")
        else
            Scanner.replicateProbeButton:SetText("Prepare Replicate Probe")
        end
    end
end

local function CopyArray(source)
    if type(source) ~= "table" then return nil end
    local copy = {}
    for i = 1, #source do
        local value = source[i]
        if type(value) == "table" then
            local nested = {}
            for key, nestedValue in pairs(value) do nested[key] = nestedValue end
            copy[i] = nested
        else
            copy[i] = value
        end
    end
    return copy
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

local function AddResults(results)
    if type(results) ~= "table" then return 0 end
    local added = 0
    for i = 1, #results do
        local result = results[i]
        if type(result) == "table" then
            local key = ItemKeyIdentity(result.itemKey)
            local itemID = type(result.itemKey) == "table" and result.itemKey.itemID or nil
            local minPrice = result.minPrice
            local quantity = result.totalQuantity
            if key and type(itemID) == "number"
                and type(minPrice) == "number" and minPrice >= 0
                and type(quantity) == "number" and quantity >= 0
                and not Scanner.rowKeys[key] then
                if #Scanner.rows >= MAX_RESULTS then
                    return added, "RESULT_LIMIT"
                end
                Scanner.rowKeys[key] = true
                local itemKey = {
                    itemID = itemID,
                    itemLevel = type(result.itemKey.itemLevel) == "number" and result.itemKey.itemLevel or nil,
                    itemSuffix = type(result.itemKey.itemSuffix) == "number" and result.itemKey.itemSuffix or nil,
                    battlePetSpeciesID = result.itemKey.battlePetSpeciesID,
                    isPet = result.itemKey.isPet,
                    bonusLists = CopyArray(result.itemKey.bonusLists),
                    modifiers = CopyArray(result.itemKey.modifiers),
                }
                local itemName = result.itemName
                if (type(itemName) ~= "string" or itemName == "")
                    and _G.C_Item and type(_G.C_Item.GetItemNameByID) == "function" then
                    local okName, name = pcall(_G.C_Item.GetItemNameByID, itemID)
                    if okName then itemName = name end
                end
                Scanner.rows[#Scanner.rows + 1] = {
                    key = ItemKeyIdentity(itemKey),
                    itemKey = itemKey,
                    itemID = itemID,
                    itemName = type(itemName) == "string" and itemName or nil,
                    itemLevel = itemKey.itemLevel,
                    itemSuffix = itemKey.itemSuffix,
                    battlePetSpeciesID = itemKey.battlePetSpeciesID,
                    isPet = itemKey.isPet,
                    bonusLists = itemKey.bonusLists,
                    modifiers = itemKey.modifiers,
                    minPriceCopper = minPrice,
                    totalQuantity = quantity,
                    source = "browse-summary",
                }
                added = added + 1
            end
        end
    end
    return added
end

local function ResetScan()
    Scanner.active = false
    Scanner.waitingForResults = false
    Scanner.needsNextPage = false
    Scanner.startedAt = 0
    Scanner.pageCount = 0
    Scanner.rows = {}
    Scanner.rowKeys = {}
    if Scanner.driver then Scanner.driver:SetScript("OnUpdate", nil) end
end

local function FinalizeThrottleWait()
    if Scanner.throttleWaitStartedAt then
        Scanner.throttleWaitSeconds = (Scanner.throttleWaitSeconds or 0)
            + math.max(0, Now() - Scanner.throttleWaitStartedAt)
        Scanner.throttleWaitStartedAt = nil
    end
end

local function IsThrottleReady()
    local ok, ready = SafeCall(API and API.IsThrottledMessageSystemReady)
    if not ok then return false, ready end
    if ready ~= true then
        if not Scanner.throttleWaitStartedAt then
            Scanner.throttleWaitStartedAt = Now()
        end
        return false
    end
    FinalizeThrottleWait()
    return true
end

local function Abort(reason)
    if not Scanner.active then return end
    Scanner.lastScanDurationSeconds = math.max(0, Now() - (Scanner.startedAt or Now()))
    FinalizeThrottleWait()
    local duration = Scanner.lastScanDurationSeconds
    local throttleWait = Scanner.throttleWaitSeconds or 0
    ResetScan()
    SetStatus(string.format(
        "Scan stopped — %s. No partial data saved; any previous completed snapshot is unchanged. Elapsed %.1fs; throttle wait %.1fs.",
        tostring(reason), duration, throttleWait))
    MM.Print(string.format("Market scan stopped: %s (%.1fs elapsed; %.1fs throttle wait).",
        tostring(reason), duration, throttleWait))
end

local function Finish()
    local rows = Scanner.rows
    local completedPages = Scanner.pageCount
    Scanner.lastScanDurationSeconds = math.max(0, Now() - (Scanner.startedAt or Now()))
    FinalizeThrottleWait()
    local throttleWaitSeconds = Scanner.throttleWaitSeconds or 0
    local scanDurationSeconds = Scanner.lastScanDurationSeconds
    local timestamp = type(_G.time) == "function" and _G.time() or 0
    local version, build, buildDate, interface = GetBuildInfo()
    local snapshot = {
        schemaVersion = 2,
        complete = true,
        dataComplete = true,
        timestamp = timestamp,
        timestampText = type(_G.date) == "function" and _G.date("%Y-%m-%d %H:%M:%S") or "unknown",
        clientVersion = tostring(version or "unknown"),
        clientBuild = tostring(build or "unknown"),
        interface = tonumber(interface) or 0,
        source = "C_AuctionHouse.SendBrowseQuery",
        snapshotKind = "browse-summary",
        priceUnit = "copper",
        resultCount = #rows,
        pageCount = completedPages,
        scanDurationSeconds = scanDurationSeconds,
        throttleWaitSeconds = throttleWaitSeconds,
        rows = rows,
    }
    -- Replace the last-known-good SavedVariables snapshot only after the new
    -- scan has reached the complete-results gate. Start/abort never touches it.
    local persisted = type(MM.db) == "table"
    if persisted then
        MM.db.lastSnapshot = snapshot
    end
    Scanner.completedSnapshot = snapshot
    Scanner.exportPartIndex = 1
    if MM.MarketUI and MM.MarketUI.Refresh then MM.MarketUI.Refresh() end
    ResetScan()
    RefreshScanDisplay()
    if persisted then
        SetStatus(string.format(
            "Complete snapshot saved: %d item variants across %d pages in %.1fs (%.1fs waiting for throttle).",
            #rows, completedPages, scanDurationSeconds, throttleWaitSeconds))
        MM.Print(string.format(
            "Auction House snapshot saved: %d variants in %.1fs (%.1fs throttle wait).",
            #rows, scanDurationSeconds, throttleWaitSeconds))
    else
        SetStatus(string.format("Complete snapshot captured in memory only: %d variants. SavedVariables unavailable.", #rows))
        MM.Print("Snapshot completed, but SavedVariables were unavailable; this copy will not survive reload.")
    end
end

local function HasFullResults()
    local ok, full = SafeCall(API and API.HasFullBrowseResults)
    if not ok then return false, full end
    return full == true
end

local function SendInitialQuery()
    if not Scanner.active then return end
    if not IsAuctionHouseOpen() then
        Abort("Auction House is no longer open")
        return
    end
    local safe, reason = CanScanSafely()
    if not safe then
        Abort("scan safety gate: " .. tostring(reason))
        return
    end
    if not API or type(API.IsThrottledMessageSystemReady) ~= "function" then
        Abort("throttle readiness API unavailable")
        return
    end
    local throttleReady, throttleError = IsThrottleReady()
    if throttleError then Abort("could not inspect Auction House throttle: " .. tostring(throttleError)); return end
    if not throttleReady then
        SetStatus("Waiting for the shared Auction House throttle to become ready…")
        return
    end
    local ok, err = SafeCall(API.SendBrowseQuery, {
        searchString = "",
        sorts = {},
        filters = {},
        itemClassFilters = {},
    })
    if not ok then Abort("browse query failed: " .. tostring(err)); return end
    Scanner.pageCount = 1
    Scanner.waitingForResults = true
    SetStatus("Full-house query sent. Waiting for results…")
end

local function SendNextPage()
    if not Scanner.active or not Scanner.needsNextPage or Scanner.waitingForResults then return end
    if not IsAuctionHouseOpen() then Abort("Auction House closed"); return end
    local safe, reason = CanScanSafely()
    if not safe then Abort("scan safety gate: " .. tostring(reason)); return end
    if Scanner.pageCount >= MAX_PAGES then Abort("page safety limit reached"); return end

    local throttleReady, throttleError = IsThrottleReady()
    if throttleError then Abort("could not inspect Auction House throttle: " .. tostring(throttleError)); return end
    if not throttleReady then
        SetStatus(string.format("Collected %d variants. Waiting for throttle before page %d…",
            #Scanner.rows, Scanner.pageCount + 1))
        return
    end

    local ok, err = SafeCall(API and API.RequestMoreBrowseResults)
    if not ok then Abort("next page request failed: " .. tostring(err)); return end
    Scanner.pageCount = Scanner.pageCount + 1
    Scanner.waitingForResults = true
    Scanner.needsNextPage = false
    SetStatus(string.format("Requested page %d. Collected %d variants…", Scanner.pageCount, #Scanner.rows))
end

local function OnBrowseResults(results, isInitial)
    if not Scanner.active then return end
    Scanner.waitingForResults = false

    if isInitial then
        local ok, current = SafeCall(API and API.GetBrowseResults)
        if not ok then Abort("could not read initial browse results: " .. tostring(current)); return end
        results = current
    end

    local _, addErr = AddResults(results)
    if addErr then Abort("result safety limit reached"); return end

    local full, fullErr = HasFullResults()
    if fullErr then Abort("could not inspect result completeness: " .. tostring(fullErr)); return end
    if full then
        Finish()
        return
    end

    Scanner.needsNextPage = true
    SetStatus(string.format("Collected %d variants; page %d received. Waiting before next page…", #Scanner.rows, Scanner.pageCount))
end

local function Start()
    if Scanner.active then
        SetStatus("A scan is already running.")
        return
    end
    if not IsAuctionHouseOpen() then
        SetStatus("Open the Auction House before starting a snapshot.")
        return
    end
    local safe, reason = CanScanSafely()
    if not safe then
        SetStatus("Scan blocked — " .. tostring(reason) .. ". Clear the Sell tab first.")
        return
    end
    if not API or type(API.SendBrowseQuery) ~= "function"
        or type(API.RequestMoreBrowseResults) ~= "function"
        or type(API.GetBrowseResults) ~= "function"
        or type(API.HasFullBrowseResults) ~= "function"
        or type(API.IsThrottledMessageSystemReady) ~= "function" then
        SetStatus("Required Forever Auction House APIs are unavailable. No request sent.")
        return
    end

    Scanner.active = true
    Scanner.rows = {}
    Scanner.rowKeys = {}
    Scanner.exportPartIndex = 1
    Scanner.pageCount = 0
    Scanner.startedAt = Now()
    Scanner.waitingForResults = false
    Scanner.needsNextPage = false
    Scanner.throttleWaitStartedAt = nil
    Scanner.throttleWaitSeconds = 0
    Scanner.lastScanDurationSeconds = 0
    SetStatus("Preparing a full-house snapshot…")
    Scanner.driver:SetScript("OnUpdate", function()
        if not Scanner.active then return end
        local elapsed = Now() - Scanner.startedAt
        if elapsed > MAX_DURATION then Abort("15-minute timeout"); return end
        if Scanner.needsNextPage then
            SendNextPage()
        elseif not Scanner.waitingForResults and Scanner.pageCount == 0 then
            SendInitialQuery()
        end
    end)
end

local function EscapeJSON(value)
    return tostring(value):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r")
end

local function JSONNumberArray(values)
    if type(values) ~= "table" or #values == 0 then return "[]" end
    local out = {}
    for i = 1, #values do out[#out + 1] = tostring(tonumber(values[i]) or 0) end
    return "[" .. table.concat(out, ",") .. "]"
end

local function JSONModifiers(values)
    if type(values) ~= "table" or #values == 0 then return "[]" end
    local out = {}
    for i = 1, #values do
        local modifier = values[i]
        if type(modifier) == "table" then
            out[#out + 1] = string.format('{"type":%d,"value":%d}',
                tonumber(modifier.type) or 0, tonumber(modifier.value) or 0)
        end
    end
    return "[" .. table.concat(out, ",") .. "]"
end

local function BuildJSON(snapshot, partIndex)
    if type(snapshot) ~= "table" or snapshot.complete ~= true or type(snapshot.rows) ~= "table" then
        return nil, "No complete snapshot is available."
    end

    local totalRows = #snapshot.rows
    local partCount = math.max(1, math.ceil(totalRows / EXPORT_ROWS_PER_PART))
    partIndex = math.floor(tonumber(partIndex) or 1)
    partIndex = math.max(1, math.min(partCount, partIndex))
    local firstRow = (partIndex - 1) * EXPORT_ROWS_PER_PART + 1
    local lastRow = math.min(totalRows, firstRow + EXPORT_ROWS_PER_PART - 1)

    local out = {
        "{",
        '  "schemaVersion": 3,',
        '  "snapshotComplete": true,',
        '  "exportChunk": true,',
        '  "chunkIndex": ' .. tostring(partIndex) .. ",",
        '  "chunkCount": ' .. tostring(partCount) .. ",",
        '  "rowStart": ' .. tostring(firstRow) .. ",",
        '  "rowEnd": ' .. tostring(lastRow) .. ",",
        '  "timestamp": ' .. tostring(tonumber(snapshot.timestamp) or 0) .. ",",
        '  "timestampText": "' .. EscapeJSON(snapshot.timestampText or "unknown") .. '",',
        '  "clientVersion": "' .. EscapeJSON(snapshot.clientVersion or "unknown") .. '",',
        '  "clientBuild": "' .. EscapeJSON(snapshot.clientBuild or "unknown") .. '",',
        '  "interface": ' .. tostring(tonumber(snapshot.interface) or 0) .. ",",
        '  "priceUnit": "copper",',
        '  "resultCount": ' .. tostring(totalRows) .. ",",
        '  "pageCount": ' .. tostring(tonumber(snapshot.pageCount) or 0) .. ",",
        '  "rows": [',
    }
    for i = firstRow, lastRow do
        local row = snapshot.rows[i]
        local comma = i < lastRow and "," or ""
        out[#out + 1] = string.format(
            '    {"itemID":%d,"itemName":"%s","itemLevel":%s,"itemSuffix":%s,"battlePetSpeciesID":%s,"isPet":%s,"bonusLists":%s,"modifiers":%s,"minPriceCopper":%.0f,"totalQuantity":%.0f}%s',
            tonumber(row.itemID) or 0,
            EscapeJSON(row.itemName or ""),
            row.itemLevel and tostring(row.itemLevel) or "null",
            row.itemSuffix and tostring(row.itemSuffix) or "null",
            row.battlePetSpeciesID and tostring(row.battlePetSpeciesID) or "null",
            row.isPet == true and "true" or "false",
            JSONNumberArray(row.bonusLists),
            JSONModifiers(row.modifiers),
            tonumber(row.minPriceCopper) or 0,
            tonumber(row.totalQuantity) or 0,
            comma
        )
    end
    out[#out + 1] = "  ]"
    out[#out + 1] = "}"
    return table.concat(out, "\n"), partIndex, partCount
end

local function RestoreSavedSnapshot()
    if Scanner.completedSnapshot then return Scanner.completedSnapshot end
    local saved = type(MM.db) == "table" and MM.db.lastSnapshot or nil
    if type(saved) == "table" and saved.complete == true
        and type(saved.rows) == "table"
        and tonumber(saved.resultCount) == #saved.rows then
        Scanner.completedSnapshot = saved
        Scanner.exportPartIndex = 1
        return saved
    end
    return nil
end


local function StopReplicateProbe(status)
    if Scanner.replicateProbeFrame then
        Scanner.replicateProbeFrame:SetScript("OnUpdate", nil)
        Scanner.replicateProbeFrame:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE")
    end
    Scanner.replicateProbeActive = false
    Scanner.replicateProbePendingConfirmation = false
    if Scanner.confirmReplicateButton then Scanner.confirmReplicateButton:Hide() end
    if status then SetStatus(status) end
    RefreshScanDisplay()
end

local function PackReturns(...)
    return { n = select("#", ...), ... }
end

local function SampleReplicateRecord(index, total)
    local okInfo, info = pcall(function()
        return PackReturns(API.GetReplicateItemInfo(index))
    end)
    if not okInfo then
        return { index = index, infoError = tostring(info) }
    end

    local sample = {
        index = index,
        itemID = tonumber(info[17]),
        hasAllInfo = info[18],
    }
    local okLink, link = pcall(API.GetReplicateItemLink, index)
    if okLink then sample.itemLink = link else sample.linkError = tostring(link) end
    if type(API.GetReplicateItemTimeLeft) == "function" then
        local okTime, timeLeft = pcall(API.GetReplicateItemTimeLeft, index)
        if okTime then sample.timeLeft = timeLeft else sample.timeLeftError = tostring(timeLeft) end
    end
    return sample
end

local function OnReplicateProbeResult()
    if not Scanner.replicateProbeActive then return end
    local elapsed = math.max(0, Now() - (Scanner.replicateProbeStartedAt or Now()))
    local okCount, count = pcall(API.GetNumReplicateItems)
    if not okCount or type(count) ~= "number" or count < 0 then
        StopReplicateProbe("Replicate response event received, but GetNumReplicateItems failed: "
            .. tostring(count) .. ". Attempt consumed; do not retry during the cooldown.")
        return
    end

    local samples = {}
    if count > 0 then
        local indices = { 0, math.floor((count - 1) / 2), count - 1 }
        local seen = {}
        for i = 1, #indices do
            local index = indices[i]
            if index >= 0 and index < count and not seen[index] then
                seen[index] = true
                samples[#samples + 1] = SampleReplicateRecord(index, count)
            end
        end
    end

    Scanner.replicateProbeResult = {
        timestamp = type(_G.time) == "function" and _G.time() or 0,
        responseSeconds = elapsed,
        auctionCount = count,
        samples = samples,
        completeScan = false,
    }
    if Scanner.inspectReplicateButton then Scanner.inspectReplicateButton:Show() end
    if type(MM.db) == "table" then
        local allInfoCount = 0
        for i = 1, #samples do
            if samples[i].hasAllInfo == true then allInfoCount = allInfoCount + 1 end
        end
        MM.db.lastReplicateProbe = {
            timestamp = Scanner.replicateProbeResult.timestamp,
            responseSeconds = elapsed,
            auctionCount = count,
            sampleCount = #samples,
            sampleHasAllInfoCount = allInfoCount,
            completeScan = false,
        }
    end
    local allInfoCount = 0
    for i = 1, #samples do
        if samples[i].hasAllInfo == true then allInfoCount = allInfoCount + 1 end
    end
    StopReplicateProbe(string.format(
        "Replicate probe response: %d auctions in %.1fs; sampled %d records (%d report hasAllInfo=true). No snapshot data was read or saved. Attempt consumed; do not retry during cooldown.",
        count, elapsed, #samples, allInfoCount))
    MM.Print(string.format(
        "Replicate diagnostic response: %d auctions in %.1fs; %d sample records. Existing snapshot unchanged.",
        count, elapsed, #samples))
end


local function StopReplicateInspection(status)
    if Scanner.replicateInspectFrame then
        Scanner.replicateInspectFrame:SetScript("OnUpdate", nil)
        Scanner.replicateInspectFrame:UnregisterEvent("AUCTION_HOUSE_CLOSED")
    end
    Scanner.replicateInspectActive = false
    if status then SetStatus(status) end
end

local function NewReplicateInspection(total)
    return {
        startedAt = Now(),
        totalAvailable = total,
        targetCount = math.min(REPLICATE_INSPECT_LIMIT, total),
        processed = 0,
        infoErrors = 0,
        missingItemIDs = 0,
        hasAllInfoTrue = 0,
        hasAllInfoFalse = 0,
        hasAllInfoUnknown = 0,
        missingLinks = 0,
        linkErrors = 0,
        invalidStackCounts = 0,
        positiveBuyouts = 0,
        zeroOrMissingBuyouts = 0,
        sampleRows = {},
    }
end

local function InspectReplicateRecord(index, result)
    local okInfo, info = pcall(function()
        return PackReturns(API.GetReplicateItemInfo(index))
    end)
    if not okInfo then
        result.infoErrors = result.infoErrors + 1
        result.processed = result.processed + 1
        return
    end

    local stackCount = tonumber(info[3])
    local buyoutCopper = tonumber(info[10])
    local itemID = tonumber(info[17])
    local hasAllInfo = info[18]

    if not itemID or itemID <= 0 then
        result.missingItemIDs = result.missingItemIDs + 1
    end
    if hasAllInfo == true then
        result.hasAllInfoTrue = result.hasAllInfoTrue + 1
    elseif hasAllInfo == false then
        result.hasAllInfoFalse = result.hasAllInfoFalse + 1
    else
        result.hasAllInfoUnknown = result.hasAllInfoUnknown + 1
    end
    if not stackCount or stackCount <= 0 then
        result.invalidStackCounts = result.invalidStackCounts + 1
    end
    if buyoutCopper and buyoutCopper > 0 then
        result.positiveBuyouts = result.positiveBuyouts + 1
    else
        result.zeroOrMissingBuyouts = result.zeroOrMissingBuyouts + 1
    end

    local okLink, itemLink = pcall(API.GetReplicateItemLink, index)
    if not okLink then
        result.linkErrors = result.linkErrors + 1
        itemLink = nil
    elseif type(itemLink) ~= "string" or itemLink == "" then
        result.missingLinks = result.missingLinks + 1
        itemLink = nil
    end

    local timeLeft
    if type(API.GetReplicateItemTimeLeft) == "function" then
        local okTime, value = pcall(API.GetReplicateItemTimeLeft, index)
        if okTime then timeLeft = value end
    end

    if #result.sampleRows < 5 then
        local unitPrice
        if stackCount and stackCount > 0 and buyoutCopper and buyoutCopper > 0 then
            unitPrice = math.ceil(buyoutCopper / stackCount)
        end
        result.sampleRows[#result.sampleRows + 1] = {
            index = index,
            itemID = itemID,
            hasAllInfo = hasAllInfo,
            stackCount = stackCount,
            buyoutCopper = buyoutCopper,
            candidateUnitPriceCopper = unitPrice,
            itemLink = itemLink,
            timeLeft = timeLeft,
        }
    end
    result.processed = result.processed + 1
end

local function FinishReplicateInspection(result)
    local duration = math.max(0, Now() - result.startedAt)
    local summary = {
        timestamp = type(_G.time) == "function" and _G.time() or 0,
        totalAvailable = result.totalAvailable,
        inspectedCount = result.processed,
        durationSeconds = duration,
        infoErrors = result.infoErrors,
        missingItemIDs = result.missingItemIDs,
        hasAllInfoTrue = result.hasAllInfoTrue,
        hasAllInfoFalse = result.hasAllInfoFalse,
        hasAllInfoUnknown = result.hasAllInfoUnknown,
        missingLinks = result.missingLinks,
        linkErrors = result.linkErrors,
        invalidStackCounts = result.invalidStackCounts,
        positiveBuyouts = result.positiveBuyouts,
        zeroOrMissingBuyouts = result.zeroOrMissingBuyouts,
        sampleRows = result.sampleRows,
        sampleComplete = result.processed == result.targetCount,
        fullListComplete = false,
    }
    if type(MM.db) == "table" then
        MM.db.lastReplicateInspection = summary
    end
    Scanner.replicateInspectResult = summary
    StopReplicateInspection(string.format(
        "Replicate sample complete: %d/%d records in %.2fs; info errors %d, missing IDs %d, hasAllInfo true/false/unknown %d/%d/%d, nil links %d, invalid stacks %d, positive buyouts %d. Sample only; no full scan or snapshot saved.",
        summary.inspectedCount, math.min(REPLICATE_INSPECT_LIMIT, summary.totalAvailable),
        duration, summary.infoErrors, summary.missingItemIDs,
        summary.hasAllInfoTrue, summary.hasAllInfoFalse, summary.hasAllInfoUnknown,
        summary.missingLinks, summary.invalidStackCounts, summary.positiveBuyouts))
end

function Scanner.StartReplicateInspection()
    if Scanner.replicateInspectActive then
        SetStatus("A cached Replicate inspection is already running.")
        return
    end
    if Scanner.active or Scanner.replicateProbeActive then
        SetStatus("Stop the active Market operation before inspecting cached Replicate records.")
        return
    end
    if not IsAuctionHouseOpen() then
        SetStatus("Open the Auction House before inspecting cached Replicate records.")
        return
    end
    local safe, reason = CanScanSafely()
    if not safe then
        SetStatus("Cached Replicate inspection blocked — " .. tostring(reason) .. ". Clear the Sell tab first.")
        return
    end
    if type(API.GetNumReplicateItems) ~= "function"
        or type(API.GetReplicateItemInfo) ~= "function"
        or type(API.GetReplicateItemLink) ~= "function" then
        SetStatus("Required Replicate read APIs are unavailable. No inspection performed.")
        return
    end

    local okCount, count = pcall(API.GetNumReplicateItems)
    if not okCount or type(count) ~= "number" or count <= 0 then
        SetStatus("No cached Replicate records are currently available. No new request was sent.")
        return
    end

    local result = NewReplicateInspection(count)
    Scanner.replicateInspectActive = true
    Scanner.replicateInspectFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
    Scanner.replicateInspectFrame:SetScript("OnEvent", function(_, event)
        if event == "AUCTION_HOUSE_CLOSED" then
            StopReplicateInspection("Cached Replicate inspection stopped because the Auction House closed. No snapshot changed.")
        end
    end)
    Scanner.replicateInspectFrame:SetScript("OnUpdate", function(_, elapsed)
        if not Scanner.replicateInspectActive then return end
        if Now() - result.startedAt >= REPLICATE_INSPECT_TIMEOUT_SECONDS then
            StopReplicateInspection("Cached Replicate inspection timed out. No snapshot changed.")
            return
        end
        if not IsAuctionHouseOpen() then
            StopReplicateInspection("Cached Replicate inspection stopped because the Auction House is no longer open.")
            return
        end
        local stillSafe, safetyReason = CanScanSafely()
        if not stillSafe then
            StopReplicateInspection("Cached Replicate inspection stopped by Sell-tab safety gate: " .. tostring(safetyReason))
            return
        end
        local okCurrent, currentCount = pcall(API.GetNumReplicateItems)
        if not okCurrent or currentCount ~= result.totalAvailable then
            StopReplicateInspection("Cached Replicate list changed or became unavailable during inspection. Partial sample discarded; no snapshot changed.")
            return
        end

        local stopAt = math.min(result.targetCount, result.processed + REPLICATE_INSPECT_PER_FRAME)
        while result.processed < stopAt do
            local sampleNumber = result.processed + 1
            local index
            if result.targetCount <= 1 then
                index = 0
            else
                index = math.floor((sampleNumber - 1) * (result.totalAvailable - 1)
                    / (result.targetCount - 1))
            end
            InspectReplicateRecord(index, result)
        end
        if result.processed >= result.targetCount then
            FinishReplicateInspection(result)
        end
    end)
    SetStatus(string.format(
        "Inspecting %d evenly spaced cached auction records in batches of %d per frame. No ReplicateItems request will be sent.",
        result.targetCount, REPLICATE_INSPECT_PER_FRAME))
end

function Scanner.PrepareReplicateProbe()
    if Scanner.replicateProbeActive then
        SetStatus("A Replicate probe is already waiting for a response.")
        return
    end
    if Scanner.active then
        SetStatus("Stop the browse snapshot before preparing a Replicate probe.")
        return
    end
    if not IsAuctionHouseOpen() then
        SetStatus("Open the Auction House before preparing the Replicate probe.")
        return
    end
    local safe, reason = CanScanSafely()
    if not safe then
        SetStatus("Replicate probe blocked — " .. tostring(reason) .. ". Clear the Sell tab first.")
        return
    end
    if type(API.ReplicateItems) ~= "function"
        or type(API.GetNumReplicateItems) ~= "function"
        or type(API.GetReplicateItemInfo) ~= "function"
        or type(API.GetReplicateItemLink) ~= "function" then
        SetStatus("Required Replicate APIs are unavailable. No request sent.")
        return
    end
    if Scanner.replicateProbeAttemptedThisSession then
        SetStatus("A Replicate probe was already attempted this session. No retry permitted.")
        return
    end

    local now = type(_G.time) == "function" and _G.time() or 0
    local remaining = GetReplicateCooldownRemaining(now)
    if remaining > 0 then
        SetStatus(string.format("Market's own Replicate attempt was recent (%d seconds remain on its 15-minute timer). No request sent. Another addon may have a newer shared cooldown.",
            math.ceil(remaining)))
        RefreshScanDisplay()
        return
    end

    Scanner.replicateProbePendingConfirmation = true
    if Scanner.confirmReplicateButton then Scanner.confirmReplicateButton:Show() end
    SetStatus("WARNING: ReplicateItems requests the full auction list and has a shared account-wide 15-minute cooldown. Auctionator, ProfessionMaster and other addons can consume it. Market cannot see their request timestamps, so its countdown is only a local estimate. Before confirming, ensure no other AH scan is running and at least 15 minutes have elapsed since any other addon's Replicate scan. Historical disconnect risk exists on very busy Auction Houses. Click Confirm & Send One Request to proceed; no automatic retry.")
    RefreshScanDisplay()
end

function Scanner.ConfirmReplicateProbe()
    if not Scanner.replicateProbePendingConfirmation then
        SetStatus("Prepare the Replicate probe and review its warning first.")
        return
    end
    if Scanner.replicateProbeAttemptedThisSession then
        StopReplicateProbe("A Replicate probe was already attempted this session. No retry permitted.")
        return
    end
    if Scanner.active or not IsAuctionHouseOpen() then
        StopReplicateProbe("Probe cancelled: stop the browse scan and keep the Auction House open. No Replicate request sent.")
        return
    end
    local safe, reason = CanScanSafely()
    if not safe then
        StopReplicateProbe("Probe cancelled by Sell-tab safety gate: " .. tostring(reason))
        return
    end

    local now = type(_G.time) == "function" and _G.time() or 0
    if GetReplicateCooldownRemaining(now) > 0 then
        StopReplicateProbe("Probe cancelled: Market's 15-minute timer is still active. No request sent. Another addon may have a newer shared cooldown.")
        RefreshScanDisplay()
        return
    end

    -- Consume the one-shot allowance before calling the API. Even a thrown API
    -- error must not lead to an automatic or same-session retry.
    Scanner.replicateProbeAttemptedThisSession = true
    Scanner.replicateProbePendingConfirmation = false
    Scanner.replicateProbeAttemptTimestamp = now
    if type(MM.db) == "table" then MM.db.replicateProbeAttemptAt = now end
    Scanner.replicateProbeStartedAt = Now()
    Scanner.replicateProbeActive = true
    Scanner.replicateProbeFrame:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
    Scanner.replicateProbeFrame:SetScript("OnUpdate", function(_, elapsed)
        if not Scanner.replicateProbeActive then return end
        local duration = Now() - (Scanner.replicateProbeStartedAt or Now())
        if duration >= REPLICATE_PROBE_TIMEOUT_SECONDS then
            StopReplicateProbe("No Replicate response within 90 seconds. Attempt consumed; no retry. Existing snapshot unchanged.")
        end
    end)

    SetStatus("One ReplicateItems request sent. Waiting up to 90 seconds for REPLICATE_ITEM_LIST_UPDATE; no retry will occur.")
    RefreshScanDisplay()
    local ok, err = pcall(API.ReplicateItems)
    if not ok then
        StopReplicateProbe("ReplicateItems raised an error: " .. tostring(err)
            .. ". Attempt consumed; no retry. Existing snapshot unchanged.")
        return
    end
end

local function CreateUI()
    if Scanner.frame then return Scanner.frame end
    RestoreSavedSnapshot()
    local frame = CreateFrame("Frame", "ModuloMarketScannerFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(700, 520)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame.TitleText:SetText("Modulo Market — Auction House")
    frame:Hide()

    local intro = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    intro:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -34)
    intro:SetWidth(660)
    intro:SetHeight(50)
    intro:SetJustifyH("LEFT")
    intro:SetWordWrap(true)
    intro:SetText("Read-only full-house snapshot. Uses shared Browse results; do not browse, buy, sell or post while scanning. Stop prevents further pages but cannot cancel a request already sent.\nReplicateItems has a shared account-wide 15-minute cooldown. Auctionator, ProfessionMaster and other addons can consume it; wait 15 minutes after their scans too. Market's countdown tracks only Market requests and cannot see external scans.")

    local dataAge = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dataAge:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -90)
    dataAge:SetWidth(660)
    dataAge:SetHeight(18)
    dataAge:SetJustifyH("LEFT")

    local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    status:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -110)
    status:SetWidth(660)
    status:SetHeight(54)
    status:SetJustifyH("LEFT")
    status:SetJustifyV("TOP")
    status:SetWordWrap(true)
    local previous = Scanner.completedSnapshot
    if type(previous) == "table" and previous.complete == true then
        status:SetText(string.format("Saved snapshot: %d variants, %s. Available across reloads.",
            tonumber(previous.resultCount) or 0, tostring(previous.timestampText or "unknown")))
    else
        status:SetText("No saved snapshot yet. Open the Auction House to begin.")
    end

    local function Button(text, width, x, y, fn)
        local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        b:SetSize(width, 26)
        b:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
        b:SetText(text)
        b:SetScript("OnClick", fn)
        return b
    end

    Button("Start Full Snapshot", 150, 16, -172, Start)
    Button("Stop Scan", 90, 174, -172, function() Abort("stopped by player") end)
    local function ShowExportPart(partIndex)
        local json, result, partCount = BuildJSON(Scanner.completedSnapshot, partIndex)
        if not json then SetStatus(result); return end
        Scanner.exportPartIndex = result
        Scanner.output:SetText(json)
        Scanner.output:SetCursorPosition(0)
        Scanner.output:HighlightText()
        SetStatus(string.format("JSON part %d/%d ready (%d rows). Click output, Ctrl+A, Ctrl+C.",
            result, partCount, math.min(EXPORT_ROWS_PER_PART,
                math.max(0, #Scanner.completedSnapshot.rows - (result - 1) * EXPORT_ROWS_PER_PART))))
    end
    Button("Export JSON Part", 100, 272, -172, function()
        ShowExportPart(Scanner.exportPartIndex or 1)
    end)
    Button("Select All", 90, 380, -172, function()
        Scanner.output:SetFocus()
        Scanner.output:HighlightText()
        SetStatus("Output selected. Press Ctrl+C.")
    end)
    Button("Close", 70, 478, -172, function() frame:Hide() end)
    Button("Previous Part", 100, 16, -202, function()
        ShowExportPart((Scanner.exportPartIndex or 1) - 1)
    end)
    Button("Next Part", 100, 122, -202, function()
        ShowExportPart((Scanner.exportPartIndex or 1) + 1)
    end)

    Scanner.replicateProbeButton = Button("Prepare Replicate Probe", 155, 16, -232, Scanner.PrepareReplicateProbe)
    Scanner.confirmReplicateButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    Scanner.confirmReplicateButton:SetSize(190, 26)
    Scanner.confirmReplicateButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 180, -232)
    Scanner.confirmReplicateButton:SetText("Confirm & Send One Request")
    Scanner.confirmReplicateButton:SetScript("OnClick", Scanner.ConfirmReplicateProbe)
    Scanner.confirmReplicateButton:Hide()

    Scanner.inspectReplicateButton = Button("Inspect 250 Cached Records", 175, 16, -268,
        Scanner.StartReplicateInspection)
    Scanner.inspectReplicateButton:Show()

    Scanner.replicateInspectFrame = CreateFrame("Frame")
    Scanner.replicateProbeFrame = CreateFrame("Frame")
    Scanner.replicateProbeFrame:SetScript("OnEvent", function(_, event)
        if event == "REPLICATE_ITEM_LIST_UPDATE" then
            OnReplicateProbeResult()
        end
    end)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -302)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 16)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(640)
    edit:SetHeight(330)
    edit:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    edit:SetTextInsets(4, 4, 4, 4)
    edit:SetJustifyH("LEFT")
    edit:SetJustifyV("TOP")
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    -- Keep the output widget fixed-size; large JSON must not create a giant scroll child.
    scroll:SetScrollChild(edit)

    Scanner.frame = frame
    Scanner.status = status
    Scanner.dataAgeText = dataAge
    Scanner.output = edit
    Scanner.driver = CreateFrame("Frame")
    Scanner.driver:SetScript("OnEvent", function(_, event, ...)
        if event == "AUCTION_HOUSE_CLOSED" then
            if Scanner.active then Abort("Auction House closed") end
        elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then
            OnBrowseResults(nil, true)
        elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
            OnBrowseResults((...), false)
        elseif event == "AUCTION_HOUSE_BROWSE_FAILURE" then
            if Scanner.active then Abort("Auction House browse failure") end
        elseif event == "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED" then
            if Scanner.active then Abort("Auction House throttle dropped a request") end
        end
    end)
    Scanner.driver:RegisterEvent("AUCTION_HOUSE_CLOSED")
    Scanner.driver:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
    Scanner.driver:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
    Scanner.driver:RegisterEvent("AUCTION_HOUSE_BROWSE_FAILURE")
    Scanner.driver:RegisterEvent("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED")
    Scanner.cooldownFrame = CreateFrame("Frame")
    Scanner.cooldownFrame.elapsed = 0
    Scanner.cooldownFrame:SetScript("OnUpdate", function(ticker, elapsed)
        if not Scanner.frame or not Scanner.frame:IsShown() then return end
        ticker.elapsed = ticker.elapsed + (tonumber(elapsed) or 0)
        if ticker.elapsed >= 1 then
            ticker.elapsed = ticker.elapsed - 1
            RefreshScanDisplay()
        end
    end)
    frame:SetScript("OnShow", RefreshScanDisplay)
    RefreshScanDisplay()
    return frame
end

function Scanner.Toggle()
    local frame = CreateUI()
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

function Scanner.Start()
    CreateUI()
    Start()
end

function Scanner.Stop()
    Abort("stopped by player")
end

function Scanner.BuildJSON(snapshot, partIndex)
    return BuildJSON(snapshot, partIndex)
end

function Scanner.ItemKeyIdentity(itemKey)
    return ItemKeyIdentity(itemKey)
end

function Scanner.SetStatus(text)
    SetStatus(text)
end
