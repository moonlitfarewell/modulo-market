local ADDON_NAME = ...
local MM = _G.ModuloMarket or {}
_G.ModuloMarket = MM

MM.name = ADDON_NAME or "ModuloMarket"
MM.version = "0.5.2"
MM.debugPrefix = "|cff66ccffModuloMarket:|r "

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(MM.debugPrefix .. tostring(message))
end

MM.Print = Print

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
        Print("MODULO Market by Wells loaded. Type /mm for market and automatic crafting economics, /mmscan for Browse snapshots, or /mmdebug for diagnostics.")
    end
end)
