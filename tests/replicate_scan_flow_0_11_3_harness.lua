local replicatePath = arg[1]
local calls, status = 0, ""
local function Frame()
    local f = { events = {}, scripts = {} }
    function f:RegisterEvent(name) self.events[name] = true end
    function f:UnregisterEvent(name) self.events[name] = nil end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:GetScript(name) return self.scripts[name] end
    return f
end
_G.CreateFrame = function() return Frame() end
local auctionCount = 0
_G.C_AuctionHouse = {
    ReplicateItems = function() calls = calls + 1 end,
    GetNumReplicateItems = function() return auctionCount end,
    GetReplicateItemInfo = function() return nil end,
    GetReplicateItemLink = function() return nil end,
}
_G.GetTime = function() return 100 end
_G.time = function() return 100000 end
_G.ModuloMarket = {
    db = { lastMarketSnapshot = { complete = true, timestamp = 1234, rows = { { itemID = 42 } } } },
    Scanner = {
        active = false,
        IsAuctionHouseOpen = function() return true end,
        CanScanSafely = function() return true end,
    },
    MarketUI = { SetStatus = function(value) status = value end, RefreshActions = function() end },
}
assert(loadfile(replicatePath))()
local R = ModuloMarket.Replicate
R.Prepare()
assert(R.GetState().pendingConfirmation == true and calls == 0, "first click only arms confirmation")
R.CancelPrepare()
assert(R.GetState().pendingConfirmation == false and calls == 0, "cancel returns to idle without sending request")
ModuloMarket.db.replicateProbeAttemptAt = 100000 - 100
R.Prepare()
assert(R.GetState().pendingConfirmation == false and calls == 0, "cooldown blocks preparing a scan")
ModuloMarket.db.replicateProbeAttemptAt = nil
R.Prepare()
assert(R.GetState().pendingConfirmation == true and calls == 0, "scan can be armed after cooldown")
R.Confirm()
local state = R.GetState()
assert(state.active == true and state.pendingConfirmation == false and state.attemptedThisSession == true)
assert(calls == 1, "second click sends exactly one ReplicateItems request")
R.Prepare()
assert(calls == 1 and R.GetState().pendingConfirmation == false, "same-session repeat is rejected")
local previous = ModuloMarket.db.lastMarketSnapshot
local commitCalls = 0
ModuloMarket.MarketUI.OnMarketSnapshotCommitted = function() commitCalls = commitCalls + 1 end
assert(R.Cancel() == true, "active scan exposes explicit Cancel action")
state = R.GetState()
assert(state.active == false and state.pendingConfirmation == false, "Cancel stops active acquisition")
assert(ModuloMarket.db.lastMarketSnapshot == previous, "Cancel preserves last-known-good Full Market snapshot")
assert(commitCalls == 0, "Cancel never invokes successful commit refresh")
assert(status:find("cancelled by player", 1, true), "Cancel reports player cancellation")
assert(R.Cancel() == false, "idle cancellation is a no-op")
print("13 scan flow checks passed")
