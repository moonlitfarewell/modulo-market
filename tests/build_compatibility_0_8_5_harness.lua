-- Offline read-only compatibility diagnostic harness for ModuloMarket 0.8.6.
_G.C_TradeSkillUI = {}
_G.C_AuctionHouse = {
    SendBrowseQuery = function() end,
    RequestMoreBrowseResults = function() end,
    GetBrowseResults = function() end,
    HasFullBrowseResults = function() end,
    IsThrottledMessageSystemReady = function() end,
    ReplicateItems = function() end,
    GetNumReplicateItems = function() end,
    GetReplicateItemInfo = function() end,
    GetReplicateItemLink = function() end,
    GetReplicateItemTimeLeft = function() end,
}
_G.C_Item = {
    GetItemNameByID = function() end,
    GetItemInfoInstant = function() end,
    IsItemDataCachedByID = function() end,
    RequestLoadItemDataByID = function() end,
}
_G.C_TooltipInfo = { GetItemByID = function() end }
_G.GetBuildInfo = function() return "1.60.1", 70938, "Nov 13 2026", 16001 end
_G.date = function() return "2026-11-13 10:00:00" end

local snapshot = {
    complete = true,
    dataComplete = true,
    source = "C_AuctionHouse.ReplicateItems",
    schemaVersion = 2,
    clientVersion = "1.60.1",
    clientBuild = "70888",
    timestampText = "2026-11-12 22:00:00",
    resultCount = 309528,
    auctionCount = 309528,
    processedAuctionCount = 309528,
    rows = {},
}
local MM = {
    version = "0.8.6",
    db = { lastMarketSnapshot = snapshot },
    Scanner = {},
    Print = function() end,
    ProfessionData = {
        IsMarketSnapshotCompatible = function(value)
            assert(value == snapshot)
            return false, "1.60.1.70888"
        end,
        GetFutureProviderStatus = function()
            return {
                dataSource = "ForeverDB.net",
                datasetBuild = "1.60.1.70888",
                currentBuild = "1.60.1.70938",
                dataBuildMatchesClient = false,
                available = true,
                reviewWatchCount = 3,
                status = "ForeverDB baseline loaded",
            }
        end,
    },
}
_G.ModuloMarket = MM

dofile("AddOns/ModuloMarket/Diagnostics.lua")
local report = MM.Diagnostics.BuildReport("COMPAT")
assert(report:find("Client build: 70938", 1, true), "client build missing")
assert(report:find("Client interface: 16001", 1, true), "interface missing")
assert(report:find("Snapshot client build: 70888", 1, true), "snapshot build missing")
assert(report:find("Snapshot compatible with current client: false", 1, true), "snapshot gate missing")
assert(report:find("Catalogue build: 1.60.1.70888", 1, true), "catalogue build missing")
assert(report:find("Current client build: 1.60.1.70938", 1, true), "current provider build missing")
assert(report:find("C_AuctionHouse.ReplicateItems = function", 1, true), "Replicate API missing")
assert(report:find("C_Item.RequestLoadItemDataByID = function", 1, true), "item API missing")
assert(report:find("NO REQUESTS SENT", 1, true), "read-only declaration missing")
assert(report:find("choose Update Full Market, confirm the full scan", 1, true), "rescan instructions missing")
assert(report:find("previous complete snapshot is retained", 1, true), "transactional snapshot note missing")
assert(not report:find("PROFESSION SKILL-LINE ENUMERATION", 1, true), "compat report should not enumerate professions")
print("ModuloMarket 0.8.6 build compatibility harness PASS")
