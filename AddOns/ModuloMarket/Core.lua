local ADDON_NAME = ...
local MM = _G.ModuloMarket or {}
_G.ModuloMarket = MM

MM.name = ADDON_NAME or "ModuloMarket"
MM.version = "0.8.6"
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
        SLASH_MODULOMARKETVERSION1 = "/mmversion"
        SlashCmdList.MODULOMARKETVERSION = PrintVersion
        Print("Loaded v" .. MM.version .. " (" .. GetClientBuildLabel() .. "). Type /mm for Market, /mmscan for Browse snapshots, /mmdebug for diagnostics, or /mmsearchdebug for tooltip-search diagnostics, /mmtooltipdebug itemID to inspect extracted tooltip text, /mmcompat for read-only build/API/snapshot compatibility, /mmversion for version details.")
    end
end)
