
_G = _G or _ENV
local currentTime = 100
function GetTime() return currentTime end
function time() return 1790000000 end
function date() return "2026-11-10 12:00:00" end
function GetBuildInfo() return "1.60.1", "70862", "Nov 6 2026", 16001 end
UIParent = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
local oldSnapshot = {
  schemaVersion = 1, complete = true, timestamp = 123,
  timestampText = "previous snapshot", clientVersion = "test", clientBuild = "test",
  interface = 16001, source = "test", priceUnit = "copper",
  resultCount = 1, pageCount = 1,
  rows = { { itemID = 99, minPriceCopper = 50, totalQuantity = 1 } },
}
ModuloMarket = { db = { lastSnapshot = oldSnapshot }, Print = function() end }
local function obj()
  local o = { scripts = {}, shown = false }
  function o:SetSize() end function o:SetPoint() end function o:SetMovable() end
  function o:EnableMouse() end function o:RegisterForDrag() end
  function o:SetScript(k,v) self.scripts[k]=v end
  function o:RegisterEvent() end function o:Hide() self.shown=false end
  function o:Show() self.shown=true end function o:IsShown() return self.shown end
  function o:StartMoving() end function o:StopMovingOrSizing() end
  function o:SetText(v) self.text=v end function o:SetWidth() end
  function o:SetJustifyH() end function o:SetJustifyV() end function o:SetWordWrap() end function o:SetWordWrap() end
  function o:SetMultiLine() end function o:SetAutoFocus() end
  function o:SetFontObject() end function o:SetHeight() end
  function o:SetTextInsets() end function o:SetScrollChild() end
  function o:SetCursorPosition() end function o:HighlightText() end
  function o:SetFocus() end function o:GetText() return self.text or "" end
  function o:ClearFocus() end
  o.TitleText = { SetText = function() end }
  function o:CreateFontString() return obj() end
  return o
end
function CreateFrame() return obj() end
AuctionHouseFrame = { IsShown = function() return true end }
local browseResults = {}
local full = false
local pageCalls, initialCalls = 0, 0
C_AuctionHouse = {
  SendBrowseQuery = function(q)
    assert(q.searchString == "" and #q.sorts == 0 and #q.filters == 0 and #q.itemClassFilters == 0)
    initialCalls = initialCalls + 1
  end,
  RequestMoreBrowseResults = function() pageCalls = pageCalls + 1 end,
  GetBrowseResults = function() return browseResults end,
  HasFullBrowseResults = function() return full end,
  IsThrottledMessageSystemReady = function() return true end,
}
dofile(arg[1])
local s = ModuloMarket.Scanner
s.Toggle()
assert(s.completedSnapshot == oldSnapshot, "saved snapshot not restored on open")
s.Start()
assert(ModuloMarket.db.lastSnapshot == oldSnapshot, "starting a scan replaced the saved snapshot")
local driver = s.driver
driver.scripts.OnUpdate()
assert(initialCalls == 1, "initial browse query not sent")
browseResults = {
  { itemKey = { itemID = 100, itemLevel = 0 }, minPrice = 125, totalQuantity = 3 },
}
driver.scripts.OnEvent(driver, "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
driver.scripts.OnUpdate()
assert(pageCalls == 1, "next page was not sent immediately when throttle reports ready")
full = true
driver.scripts.OnEvent(driver, "AUCTION_HOUSE_BROWSE_RESULTS_ADDED", {
  { itemKey = { itemID = 101 }, minPrice = 250, totalQuantity = 5 },
})
assert(s.completedSnapshot and s.completedSnapshot.complete == true, "complete in-memory snapshot not retained")
assert(s.completedSnapshot.resultCount == 2, "snapshot row count wrong")
assert(ModuloMarket.db.lastSnapshot == s.completedSnapshot, "completed snapshot did not replace SavedVariables")
assert(ModuloMarket.db.lastSnapshot ~= oldSnapshot, "old snapshot was not replaced after successful completion")
local latestSnapshot = ModuloMarket.db.lastSnapshot
s.Start()
assert(ModuloMarket.db.lastSnapshot == latestSnapshot, "new scan start changed the saved snapshot")
driver.scripts.OnEvent(driver, "AUCTION_HOUSE_BROWSE_FAILURE")
assert(ModuloMarket.db.lastSnapshot == latestSnapshot, "failed scan destroyed the last-known-good snapshot")
assert(not s.active, "failed scan remained active")
local json = s.BuildJSON(s.completedSnapshot)
assert(json and json:find('"priceUnit": "copper"', 1, true), "JSON export missing copper unit")
assert(json:find('"itemID":100', 1, true) and json:find('"itemID":101', 1, true), "JSON export missing rows")

local syntheticRows = {}
for i = 1, 2001 do
  syntheticRows[i] = { itemID = i, minPriceCopper = i * 10, totalQuantity = i }
end
local synthetic = {
  complete = true, rows = syntheticRows, timestamp = 1,
  timestampText = "test", clientVersion = "test", clientBuild = "test",
  interface = 16001, pageCount = 1,
}
local part1, index1, count1 = s.BuildJSON(synthetic, 1)
local part2, index2, count2 = s.BuildJSON(synthetic, 2)
local function occurrences(text, needle)
  local _, count = text:gsub(needle, "")
  return count
end
assert(index1 == 1 and count1 == 2, "first export chunk metadata incorrect")
assert(index2 == 2 and count2 == 2, "second export chunk metadata incorrect")
assert(part1:find('"rowStart": 1', 1, true) and part1:find('"rowEnd": 2000', 1, true),
  "first export chunk row bounds incorrect")
assert(part2:find('"rowStart": 2001', 1, true) and part2:find('"rowEnd": 2001', 1, true),
  "second export chunk row bounds incorrect")
assert(occurrences(part1, '"itemID"') == 2000, "first chunk row count incorrect")
assert(occurrences(part2, '"itemID"') == 1, "second chunk row count incorrect")

print("scanner model harness PASS")
