local ADDON_NAME = ...
local MM = _G.ModuloMarket or {}
_G.ModuloMarket = MM

MM.name = ADDON_NAME or "ModuloMarket"
MM.version = "1.0.2"
MM.debugPrefix = "|cff66ccffModuloMarket:|r "

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(MM.debugPrefix .. tostring(message))
end

MM.Print = Print

local function GetClientBuildLabel()
    if type(_G.GetBuildInfo) ~= "function" then return "client build UNKNOWN" end
    local ok, version, build = pcall(_G.GetBuildInfo)
    if not ok or type(version) ~= "string" or version == "" or build == nil then
        return "client build UNKNOWN"
    end
    return string.format("client %s build %s", version, tostring(build))
end

local function PrintVersion()
    local label = "ModuloMarket v" .. MM.version .. " | " .. GetClientBuildLabel()
    local provider = MM.ProfessionData and MM.ProfessionData.GetFutureProviderStatus
        and MM.ProfessionData.GetFutureProviderStatus()
    if provider and provider.dataSource == "ForeverDB.net" then
        local dataState = "not loaded"
        if provider.available then
            if provider.dataBuildMatchesClient == false then
                dataState = string.format("loaded as baseline on client %s; %d records flagged for review",
                    tostring(provider.currentBuild or "UNKNOWN"), provider.reviewWatchCount or 0)
            else
                dataState = "loaded (build match)"
            end
        end
        label = label .. string.format(" | ForeverDB data %s: %s",
            tostring(provider.datasetBuild or "UNKNOWN"), dataState)
    end
    Print(label)
end

local function InitializeDB()
    if type(_G.ModuloMarketDB) ~= "table" then
        _G.ModuloMarketDB = {}
    end
    MM.db = _G.ModuloMarketDB
    MM.db.debug = MM.db.debug ~= false
    if MM.db.craftingScope ~= "character" and MM.db.craftingScope ~= "account" then
        MM.db.craftingScope = "account"
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, event, loadedName)
    if event == "ADDON_LOADED" and loadedName == MM.name then
        InitializeDB()
        if MM.Theme and MM.Theme.Initialize then MM.Theme.Initialize() end
        SLASH_MODULOMARKET1 = "/mm"
        SlashCmdList.MODULOMARKET = function()
            if MM.MarketUI and MM.MarketUI.Toggle then
                MM.MarketUI.Toggle()
            elseif MM.Scanner and MM.Scanner.Toggle then
                MM.Scanner.Toggle()
            else
                Print("Market UI is not ready.")
            end
        end
        SLASH_MODULOMARKETSCAN1 = "/mmscan"
        SlashCmdList.MODULOMARKETSCAN = function()
            if MM.Scanner and MM.Scanner.Toggle then
                MM.Scanner.Toggle()
            else
                Print("Browse scanner UI is not ready.")
            end
        end
        SLASH_MODULOMARKETCOMPAT1 = "/mmcompat"
        SlashCmdList.MODULOMARKETCOMPAT = function()
            if MM.Diagnostics and MM.Diagnostics.ShowCompatibility then
                MM.Diagnostics.ShowCompatibility()
            else
                Print("Compatibility diagnostics are not ready.")
            end
        end
        SLASH_MODULOMARKETDEBUG1 = "/mmdebug"
        SlashCmdList.MODULOMARKETDEBUG = function()
            if MM.Diagnostics and MM.Diagnostics.Toggle then
                MM.Diagnostics.Toggle()
            else
                Print("Diagnostics UI is not ready.")
            end
        end
        SLASH_MODULOMARKETTABPERF1 = "/mmtabperf"
        SlashCmdList.MODULOMARKETTABPERF = function(message)
            local command = tostring(message or ""):lower():match("^%s*(.-)%s*$")
            local ui = MM.MarketUI
            if not ui or not ui.GetTabPerfDiagnostics then
                Print("Tab performance diagnostics are unavailable.")
                return
            end
            if command == "on" then
                ui.SetTabPerfDiagnostics(true)
                Print("Tab performance diagnostics enabled. Reproduce tab switching, then run /mmtabperf.")
                return
            elseif command == "off" then
                ui.SetTabPerfDiagnostics(false)
                Print("Tab performance diagnostics disabled.")
                return
            elseif command == "reset" then
                ui.ResetTabPerfDiagnostics()
                Print("Tab performance counters reset.")
                return
            end
            local d = ui.GetTabPerfDiagnostics()
            Print(string.format("Tab perf enabled=%s selections=%d sameTab=%d cancelledBuilds=%d",
                tostring(d.enabled), d.tabSelections, d.sameTabSelections, d.cancelledBuilds))
            local tabs = {}
            for tab in pairs(d.tabs or {}) do tabs[#tabs + 1] = tab end
            table.sort(tabs)
            if #tabs == 0 and (d.catalogWork.starts or 0) == 0
                and (d.viewWork.frames or 0) == 0 then
                Print("No pipeline samples yet. Use /mmtabperf on before opening Market, then reproduce the hitch.")
                return
            end
            for _, tab in ipairs(tabs) do
                local r = d.tabs[tab]
                Print(string.format("%s req=%d builds=%d done=%d cancelled=%d sourceRows=%d processed=%d results=%d source=%.3fs elapsed=%.3fs last=%.3fs",
                    tab, r.requests, r.builds, r.completed, r.cancelled,
                    r.sourceRows, r.processedRows, r.resultRows,
                    r.sourceSeconds, r.elapsedSeconds, r.lastElapsedSeconds))
            end
            local e, sort = d.itemEvents or {}, d.sorts or {}
            Print(string.format("Item events total=%d getInfo=%d loadResult=%d unique=%d classResolved=%d refreshScheduled=%d rescheduled=%d triggered=%d last=%s:%d filter=%s",
                e.total or 0, e.getItemInfo or 0, e.itemDataLoad or 0, e.uniqueItems or 0,
                e.resolvedClass or 0, e.refreshScheduled or 0, e.refreshRescheduled or 0,
                e.refreshTriggered or 0, e.lastEvent or "none", e.lastItemID or 0, e.lastFilter or "all"))
            Print(string.format("Sort started=%d completed=%d restarted=%d compares=%d lastTab=%s filter=%s rows=%d elapsed=%.3fs",
                sort.started or 0, sort.completed or 0, sort.restarted or 0,
                sort.comparatorCalls or 0, sort.lastTab or "none", sort.lastFilter or "all",
                sort.lastRows or 0, sort.lastElapsedSeconds or 0))
            local c, v, k = d.catalogWork or {}, d.viewWork or {}, d.classLookups or {}
            Print(string.format("Catalog starts=%d done=%d cancelled=%d rows=%d unique=%d variants=%d frames=%d stepTotal=%.1fms stepMax=%.2fms finalize=%.2fms elapsed=%.1fms",
                c.starts or 0, c.completed or 0, c.cancelled or 0, c.processedRows or 0,
                c.uniqueItems or 0, c.variantMerges or 0, c.frames or 0,
                c.totalStepMs or 0, c.maxStepMs or 0, c.finalizeMs or 0, c.lastElapsedMs or 0))
            Print(string.format("View frames=%d rows=%d total=%.1fms max=%.2fms last=%.2fms lastRows=%d tab=%s filter=%s",
                v.frames or 0, v.rowsProcessed or 0, v.totalStepMs or 0, v.maxStepMs or 0,
                v.lastStepMs or 0, v.lastRows or 0, v.lastTab or "none", v.lastFilter or "all"))
            Print(string.format("Class lookup calls=%d cache=%d instant=%d/%d fallback=%d/%d missing=%d queued=%d",
                k.calls or 0, k.cacheHits or 0, k.instantResolved or 0, k.instantCalls or 0,
                k.fallbackResolved or 0, k.fallbackCalls or 0, k.missing or 0, k.requestsQueued or 0))
        end
        SLASH_MODULOMARKETSEARCHDEBUG1 = "/mmsearchdebug"
        SlashCmdList.MODULOMARKETSEARCHDEBUG = function()
            local d = MM.MarketUI and MM.MarketUI.GetSearchDiagnostics and MM.MarketUI.GetSearchDiagnostics()
            if not d then Print("Search diagnostics unavailable."); return end
            Print(string.format("Search state=%s submitted=%d requests=%d events=%d cacheHits=%d failures=%d timeouts=%d completed=%d pending=%d outstanding=%d",
                tostring(d.state), d.searches, d.requests, d.events, d.cacheHits, d.failures,
                d.timeouts, d.completed, d.pending, d.outstanding))
            Print(string.format("Tooltip structured=%d fallback=%d empty=%d lastItem=%d source=%s lines=%d error=%s",
                d.structuredReads or 0, d.legacyFallbacks or 0,
                d.emptyResults or 0, d.lastItemID or 0, tostring(d.lastSource),
                d.lastLineCount or 0, tostring(d.lastError)))
        end
        SLASH_MODULOMARKETTOOLTIPDEBUG1 = "/mmtooltipdebug"
        SlashCmdList.MODULOMARKETTOOLTIPDEBUG = function(message)
            local itemID = tonumber(message)
            if not itemID then Print("Usage: /mmtooltipdebug itemID"); return end
            if not (MM.MarketUI and MM.MarketUI.GetTooltipSearchDebug) then
                Print("Tooltip diagnostics unavailable."); return
            end
            local text, source, lineCount = MM.MarketUI.GetTooltipSearchDebug(itemID)
            if text == nil then Print("Tooltip data is pending or unavailable; retry after item data loads."); return end
            Print(string.format("Tooltip item=%d source=%s lines=%d chars=%d",
                itemID, tostring(source), tonumber(lineCount) or 0, #text))
            if text == "" then Print("No searchable tooltip text was extracted."); return end
            for i = 1, #text, 180 do Print(string.sub(text, i, i + 179)) end
        end
        SLASH_MODULOMARKETREPLICATEDEBUG1 = "/mmreplicatedebug"
        SlashCmdList.MODULOMARKETREPLICATEDEBUG = function()
            if MM.Replicate and MM.Replicate.PrintTargetDiagnostics then
                MM.Replicate.PrintTargetDiagnostics()
            else
                Print("Replicate diagnostics are not ready.")
            end
        end
        SLASH_MODULOMARKETVERSION1 = "/mmversion"
        SlashCmdList.MODULOMARKETVERSION = PrintVersion
        Print("Loaded v" .. MM.version .. " (" .. GetClientBuildLabel() .. "). Type /mm for Market, /mmscan for Browse snapshots, /mmdebug for diagnostics, or /mmsearchdebug for tooltip-search diagnostics, /mmtooltipdebug itemID to inspect extracted tooltip text, /mmcompat for read-only build/API/snapshot compatibility, /mmreplicatedebug for Enchantresses' Spire acquisition diagnostics, /mmversion for version details.")
    end
end)
