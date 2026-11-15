local addon = arg and arg[1]
local function fakeFrame()
    local frame = { events = {}, scripts = {} }
    function frame:RegisterEvent(name) self.events[name] = true end
    function frame:UnregisterEvent(name) self.events[name] = nil end
    function frame:SetScript(name, fn) self.scripts[name] = fn end
    function frame:GetScript(name) return self.scripts[name] end
    return frame
end
_G.CreateFrame = function() return fakeFrame() end
_G.GetTime = function() return 1 end
_G.GetBuildInfo = function() return "1.60.1", "70938" end
_G.time = function() return 100 end
_G.C_AuctionHouse = {
    ReplicateItems = function() end,
    GetNumReplicateItems = function() return 0 end,
    GetReplicateItemInfo = function() return nil end,
    GetReplicateItemLink = function() return nil end,
}
_G.ModuloMarket = { db = {} }
local MM = _G.ModuloMarket
local function eq(actual, expected, message)
    assert(actual == expected, (message or "value mismatch") .. ": got " .. tostring(actual) .. ", expected " .. tostring(expected))
end
local function label()
    return { SetText = function(self, value) self.value = value end }
end

dofile(addon .. "/AddOns/ModuloMarket/MarketUI.lua")
local UI = MM.MarketUI
UI.metadata = label()
UI.status = label()
UI.RenderRows = function() end
UI.RefreshActions = function() end
UI.StartViewBuild = function() end

local marketRows = { { itemID = 1001, itemName = "Full Market item" } }
local browseRows = { { itemID = 2002, itemName = "Browse-only item" } }
local market = { complete = true, timestamp = 10, source = "C_AuctionHouse.ReplicateItems", rows = marketRows }
local newerBrowse = { complete = true, timestamp = 999, source = "Browse", rows = browseRows }
MM.db.lastMarketSnapshot, MM.db.lastSnapshot = market, newerBrowse
UI.frame = {}
UI.blizzlikeVisible = false
MM.ModernUI = { IsShown = function() return false end, RenderRows = function() end }
UI.Refresh()
eq(UI.catalogSnapshot, market, "complete Full Market must outrank newer Browse")

MM.db.lastMarketSnapshot = { complete = false, timestamp = 1000 }
UI.catalogSnapshot, UI.catalogBuild = nil, nil
UI.Refresh()
eq(UI.catalogSnapshot, newerBrowse, "Browse is fallback when Full Market is incomplete")
MM.db.lastMarketSnapshot = nil
UI.catalogSnapshot, UI.catalogBuild = nil, nil
UI.Refresh()
eq(UI.catalogSnapshot, newerBrowse, "Browse is fallback when Full Market is absent")
MM.db.lastSnapshot = { complete = false }
UI.catalogSnapshot, UI.catalogBuild = nil, nil
UI.Refresh()
eq(UI.catalogSnapshot, nil, "incomplete sources must not be selected")

-- Restore the committed source pair and exercise the real UI.Refresh path.
MM.db.lastMarketSnapshot, MM.db.lastSnapshot = market, newerBrowse
local modernRefreshes = 0
MM.ModernUI = { IsShown = function() return false end, RenderRows = function() modernRefreshes = modernRefreshes + 1 end }

-- Blizz-like open: the exact committed Full Market rows are indexed immediately.
UI.frame = {}
UI.blizzlikeVisible = true
UI.pendingSnapshotRefresh = false
UI.OnMarketSnapshotCommitted(market)
eq(UI.catalogSnapshot, market, "Blizz-like refresh uses committed Full Market snapshot")
eq(UI.catalogBuild.rows, marketRows, "Blizz-like catalogue indexes Full Market rows")
eq(UI.pendingSnapshotRefresh, false, "Blizz-like refresh consumes pending state")

-- Modern open: the same committed Full Market snapshot is consumed immediately.
UI.catalogSnapshot = nil
UI.blizzlikeVisible = false
MM.ModernUI.IsShown = function() return true end
UI.OnMarketSnapshotCommitted(market)
eq(UI.catalogSnapshot, market, "Modern refresh uses committed Full Market snapshot")
eq(UI.catalogBuild.rows, marketRows, "Modern catalogue indexes Full Market rows")
assert(modernRefreshes > 0, "Modern rows invalidated/rendered on commit")

-- Both presentations closed while the backend exists: do not build invisibly.
UI.catalogSnapshot = nil
UI.blizzlikeVisible = false
MM.ModernUI.IsShown = function() return false end
UI.pendingSnapshotRefresh = false
local beforeClosedBuild = UI.catalogBuild
UI.OnMarketSnapshotCommitted(market)
eq(UI.catalogSnapshot, nil, "closed presentations defer catalogue build")
eq(UI.pendingSnapshotRefresh, true, "closed presentations retain pending refresh")
eq(UI.catalogBuild, beforeClosedBuild, "closed presentation does not replace catalogue")

-- Closed backend: the first explicit open consumes the deferred refresh.
UI.frame = nil
UI.OnMarketSnapshotCommitted(market)
eq(UI.pendingSnapshotRefresh, true, "missing backend keeps refresh pending")
UI.frame = {}
UI.Refresh()
eq(UI.catalogSnapshot, market, "first open consumes the exact committed snapshot")
eq(UI.catalogBuild.rows, marketRows, "first open indexes Full Market rows")
eq(UI.pendingSnapshotRefresh, false, "first open clears pending refresh")

-- Incomplete/stale commit payloads cannot change pending state or refresh.
local pendingBefore = UI.pendingSnapshotRefresh
local incomplete = { complete = false }
eq(UI.OnMarketSnapshotCommitted(incomplete), false, "incomplete commit rejected")
eq(UI.pendingSnapshotRefresh, pendingBefore, "incomplete commit leaves pending state unchanged")
eq(UI.OnMarketSnapshotCommitted({ complete = true }), false, "uncommitted snapshot rejected")
eq(UI.pendingSnapshotRefresh, pendingBefore, "stale commit leaves pending state unchanged")

-- Exercise the actual Replicate abort path: no response means no snapshot commit
-- and no call to the UI commit hand-off; the last-known-good snapshot survives.
local commitCalls = 0
UI.OnMarketSnapshotCommitted = function() commitCalls = commitCalls + 1; return true end
MM.Scanner = {
    active = false,
    IsAuctionHouseOpen = function() return true end,
    CanScanSafely = function() return true end,
}
dofile(addon .. "/AddOns/ModuloMarket/Replicate.lua")
local R = MM.Replicate
R.Prepare()
eq(R.GetState().pendingConfirmation, true, "Replicate scan requires confirmation")
R.Confirm()
eq(R.GetState().active, true, "confirmed Replicate scan starts")
R.frame:GetScript("OnEvent")(R.frame, "REPLICATE_ITEM_LIST_UPDATE")
eq(R.GetState().active, false, "empty initial response aborts scan")
eq(MM.db.lastMarketSnapshot, market, "aborted scan preserves last-known-good Full Market snapshot")
eq(commitCalls, 0, "aborted scan never invokes committed-snapshot hand-off")

print("snapshot source/refresh behavioral harness: PASS")
