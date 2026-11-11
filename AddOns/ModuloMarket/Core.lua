local ADDON_NAME = ...
local MM = _G.ModuloMarket or {}
_G.ModuloMarket = MM

MM.name = ADDON_NAME or "ModuloMarket"
MM.version = "0.5.4"
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
        label = label .. string.format(" | ForeverDB data %s: %s",
            tostring(provider.datasetBuild or "UNKNOWN"),
            provider.available and "loaded" or "not loaded")
    end
    Print(label)
end

local function InitializeDB()
    if type(_G.ModuloMarketDB) ~= "table" then
        _G.ModuloMarketDB = {}
    end
    MM.db = _G.ModuloMarketDB
    MM.db.debug = MM.db.debug ~= false
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
        SLASH_MODULOMARKETDEBUG1 = "/mmdebug"
        SlashCmdList.MODULOMARKETDEBUG = function()
            if MM.Diagnostics and MM.Diagnostics.Toggle then
                MM.Diagnostics.Toggle()
            else
                Print("Diagnostics UI is not ready.")
            end
        end
        SLASH_MODULOMARKETVERSION1 = "/mmversion"
        SlashCmdList.MODULOMARKETVERSION = PrintVersion
        Print("Loaded v" .. MM.version .. " (" .. GetClientBuildLabel() .. "). Type /mm for Market, /mmscan for Browse snapshots, /mmdebug for diagnostics, or /mmversion for version details.")
    end
end)
