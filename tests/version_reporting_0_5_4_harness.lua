local capturedHandler
local messages = {}
_G.ModuloMarket = {
    ProfessionData = {
        GetFutureProviderStatus = function()
            return {
                dataSource = "ForeverDB.net",
                datasetBuild = "1.60.1.70888",
                currentBuild = "1.60.1.70888",
                available = true,
                dataBuildMatchesClient = true,
                reviewWatchCount = 3,
            }
        end,
    },
}
_G.GetBuildInfo = function() return "1.60.1", "70888", "Nov 9 2026", 16001 end
_G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) messages[#messages + 1] = message end }
_G.SlashCmdList = {}
_G.CreateFrame = function()
    return {
        RegisterEvent = function() end,
        SetScript = function(_, event, handler)
            if event == "OnEvent" then capturedHandler = handler end
        end,
    }
end

dofile(assert(arg[1], "Core.lua path required"))
assert(type(capturedHandler) == "function", "Core must register ADDON_LOADED handler")
capturedHandler(nil, "ADDON_LOADED", "ModuloMarket")
assert(string.find(messages[1], "Loaded v0.6.6", 1, true), "login message must announce addon version")
assert(string.find(messages[1], "client 1.60.1 build 70888", 1, true), "login message must announce client build")
assert(type(SlashCmdList.MODULOMARKETVERSION) == "function", "/mmversion must be registered")
SlashCmdList.MODULOMARKETVERSION()
assert(string.find(messages[2], "ModuloMarket v0.6.6", 1, true), "/mmversion must report addon version")
assert(string.find(messages[2], "ForeverDB data 1.60.1.70888: loaded (build match)", 1, true), "/mmversion must report baseline state and targeted review count")
print("ModuloMarket 0.6.6 version reporting harness passed")
