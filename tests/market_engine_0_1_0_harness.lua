local currentTime = 10
local wallTime = 1794311000
function GetTime() return currentTime end
function time() return wallTime end
function date() return "2026-11-10 18:00:00" end
function GetBuildInfo() return "1.60.1", "70862", "Nov 6 2026", 16001 end
UIParent = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
AuctionHouseFrame = { IsShown = function() return true end }

local function object()
  local o = { scripts = {}, registered = {}, shown = false }
  function o:SetScript(name, callback) self.scripts[name] = callback end
  function o:RegisterEvent(name) self.registered[name] = true end
  function o:UnregisterEvent(name) self.registered[name] = nil end
  function o:SetSize() end function o:SetPoint() end function o:SetMovable() end
  function o:EnableMouse() end function o:RegisterForDrag() end
  function o:Show() self.shown = true end function o:Hide() self.shown = false end
  function o:IsShown() return self.shown end
  return o
end
function CreateFrame() return object() end

local rows = {
  { name = "Copper Ore", count = 2, buyout = 10000, itemID = 100, hasAllInfo = true,
    link = "item:100:0:0:0:0:0:0:0:0:0:0:0:0:0" },
  { name = "Copper Ore", count = 1, buyout = 4000, itemID = 100, hasAllInfo = true,
    link = "item:100:0:0:0:0:0:0:0:0:0:0:0:0:0" },
  { name = "Copper Ore", count = 1, buyout = 8000, itemID = 100, hasAllInfo = true,
    link = "item:100:0:0:0:0:0:42:0:0:0:0:0:2:123:456:1:9:7" },
  { name = "", count = 5, buyout = 0, itemID = 200, hasAllInfo = false, link = nil },
  { name = "", count = 1, buyout = 0, itemID = 200, hasAllInfo = false, link = nil },
}
local itemDataReady = false
local replicateCalls = 0
local itemLoadRequests = 0
C_AuctionHouse = {
  ReplicateItems = function() replicateCalls = replicateCalls + 1 end,
  GetNumReplicateItems = function() return #rows end,
  GetReplicateItemInfo = function(index)
    local r = rows[index + 1]
    if not r then error("invalid index") end
    local ready = r.itemID ~= 200 or itemDataReady
    return ready and r.name or "", nil, r.count, 2, true, 1, "REQ", 0, 0,
      r.buyout, 0, nil, nil, nil, nil, 0, r.itemID, ready and true or false
  end,
  GetReplicateItemLink = function(index)
    local r = rows[index + 1]
    if r.itemID == 200 and not itemDataReady then return nil end
    return r.link or "item:200:0:0:0:0:0:0:0:0:0:0:0:0:0"
  end,
}
C_Item = {
  GetItemInfoInstant = function(itemID) return itemID, "Armor", "Misc", "INVTYPE", 0, 4, 0 end,
  GetDetailedItemLevelInfo = function() return 15 end,
  GetItemInfo = function(item) return "Loaded Item", item, 2, 15 end,
  GetItemNameByID = function(itemID) return itemID == 100 and "Copper Ore" or "Other Ore" end,
  IsItemDataCachedByID = function(itemID) return itemID ~= 200 or itemDataReady end,
  RequestLoadItemDataByID = function(itemID)
    assert(itemID == 200)
    itemLoadRequests = itemLoadRequests + 1
  end,
}

local previousMarket = { complete = true, timestamp = wallTime - 100, rows = {} }
local previousBrowse = { complete = true, timestamp = wallTime - 50, rows = {} }
ModuloMarket = {
  db = {
    lastMarketSnapshot = previousMarket,
    lastSnapshot = previousBrowse,
  },
  Print = function() end,
}
ModuloMarket.MarketUI = {
  SetStatus = function(message) ModuloMarket.lastStatus = message end,
  Refresh = function() ModuloMarket.refreshed = true end,
  RefreshActions = function() end,
}

dofile(arg[1])
dofile(arg[2])
dofile(arg[3])
if arg[4] then dofile(arg[4]) end
local originalRefresh = ModuloMarket.MarketUI.Refresh
ModuloMarket.MarketUI.Refresh = function()
  ModuloMarket.refreshed = true
  originalRefresh()
end

local r = ModuloMarket.Replicate
assert(not r.active, "full scan must not run automatically")
r.Prepare()
assert(not r.active and r.pendingConfirmation, "prepare must require confirmation")
assert(replicateCalls == 0, "prepare must not send request")
r.Confirm()
assert(replicateCalls == 1, "confirmation must send exactly one request")
assert(r.active and r.stage == "waiting_response", "scan should await initial response")
assert(ModuloMarket.db.replicateProbeAttemptAt == wallTime, "attempt timestamp must persist before API call")

-- First event is the initial response. The event is unregistered before row traversal.
r.frame.scripts.OnEvent(r.frame, "REPLICATE_ITEM_LIST_UPDATE")
assert(r.stage == "reading", "initial response should enter bounded processing")
assert(not r.frame.registered.REPLICATE_ITEM_LIST_UPDATE, "subsequent cache update events must not re-enter the initial-response handler")

-- Read all four auctions in one bounded update. The fourth needs item-data loading.
r.frame.scripts.OnUpdate(r.frame, 0.016)
assert(r.scan.processed == 5, "all five auction records should be read")
assert(not ModuloMarket.db.lastMarketSnapshot or ModuloMarket.db.lastMarketSnapshot == previousMarket,
  "incomplete processing must not replace last-known-good Market data")
assert(itemLoadRequests == 0, "new item-data requests are queued and rate-limited to the next frame")

-- Next frame sends the single deduplicated item-data request.
r.frame.scripts.OnUpdate(r.frame, 0.016)
assert(itemLoadRequests == 1, "one missing item ID should create one item-data request")
assert(r.scan.pendingLoadCount == 1, "pending item-data request should be tracked")

-- Simulate the documented item-data completion event.
itemDataReady = true
r.frame.scripts.OnEvent(r.frame, "ITEM_DATA_LOAD_RESULT", 200, true)
assert(r.scan.pendingLoadCount == 0, "item-data completion should clear pending count")

-- Retry the pending auction and commit only after every record is identified.
r.frame.scripts.OnUpdate(r.frame, 0.016)
assert(not r.active, "scan should finish after all records are resolved")
local snapshot = ModuloMarket.db.lastMarketSnapshot
assert(snapshot and snapshot.complete and snapshot.dataComplete, "complete Market snapshot should be committed")
assert(snapshot.auctionCount == 5 and snapshot.processedAuctionCount == 5, "auction counts should be exact")
assert(snapshot.resultCount == 3, "suffix/bonus variant must remain distinct")
assert(snapshot.totalQuantity == 10, "all stack quantities should aggregate")
assert(snapshot.pricedQuantity == 4 and snapshot.unpricedQuantity == 6, "priced and unpriced quantities should remain distinct")
assert(ModuloMarket.db.lastSnapshot == previousBrowse, "Browse last-known-good snapshot must remain untouched")
assert(snapshot.timestamp == wallTime, "snapshot timestamp should be captured at scan start")
assert(ModuloMarket.db.marketHistory and #ModuloMarket.db.marketHistory == 1,
  "completed full scans should append a historical comparison point")
assert(ModuloMarket.db.marketHistory[1].items[100].price == 4000,
  "history should retain the cheapest itemID-level price across variants")
assert(ModuloMarket.db.marketHistory[1].items[100].quantity == 4,
  "history should retain itemID-level total supply across variants")

local ordinary
local suffixed
local unpriced
for _, row in ipairs(snapshot.rows) do
  if row.itemID == 100 and row.itemSuffix == 0 and #(row.bonusLists or {}) == 0 then ordinary = row
  elseif row.itemID == 100 and row.itemSuffix == 42 then suffixed = row
  elseif row.itemID == 200 then unpriced = row end
end
assert(ordinary and ordinary.minPriceCopper == 4000, "minimum unit price should be calculated from total buyout / stack")
assert(ordinary.totalQuantity == 3 and ordinary.minPriceQuantity == 1, "quantity and minimum-price depth should aggregate")
assert(suffixed and #suffixed.bonusLists == 2 and #suffixed.modifiers == 1, "bonus lists and modifiers must be retained in the variant key")
assert(unpriced and unpriced.minPriceCopper == nil and unpriced.unpricedQuantity == 6 and unpriced.auctionCount == 2, "bid-only/no-buyout auctions must not become zero-priced")
assert(ModuloMarket.refreshed == true, "player-facing Market UI should refresh after commit")
assert(replicateCalls == 1, "no retry or second Replicate request is permitted")

local scenario, err = ModuloMarket.MarketUI.GetProfitScenario(ordinary, 3000, 2, 5)
assert(scenario and not err, "profit scenario should calculate")
assert(scenario.netUnitPriceCopper == 3800, "AH cut should apply to sale proceeds")
assert(scenario.profitUnitCopper == 800, "per-unit profit should be net sale minus cost")
assert(scenario.totalProfitCopper == 1600, "total profit should scale by planned quantity")
assert(scenario.breakEvenGrossCopper == 3158, "break-even gross sale price should include AH cut")

print("Modulo Market 0.1.0 Replicate + aggregation + profit harness PASS")
