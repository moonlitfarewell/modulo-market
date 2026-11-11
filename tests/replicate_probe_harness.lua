local currentTime = 50
local wallTime = 1794310000
function GetTime() return currentTime end
function time() return wallTime end
function date() return "2026-11-10 17:00:00" end
function GetBuildInfo() return "1.60.1", "70862", "Nov 6 2026", 16001 end
UIParent = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
local oldSnapshot = {
  complete = true, resultCount = 1, timestamp = wallTime - 540, rows = {
    { itemID = 77, minPriceCopper = 100, totalQuantity = 2 }
  }
}
ModuloMarket = { db = { lastSnapshot = oldSnapshot }, Print = function() end }
local function obj()
  local o = { scripts = {}, shown = false, registered = {} }
  function o:SetSize() end function o:SetPoint() end function o:SetMovable() end
  function o:EnableMouse() end function o:RegisterForDrag() end
  function o:SetScript(k,v) self.scripts[k]=v end
  function o:RegisterEvent(e) self.registered[e]=true end
  function o:UnregisterEvent(e) self.registered[e]=nil end
  function o:Hide() self.shown=false end function o:Show() self.shown=true end
  function o:IsShown() return self.shown end
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
local replicateCalls = 0
local infoReadCount = 0
local linkReadCount = 0
local infoReadCount = 0
local linkReadCount = 0
C_AuctionHouse = {
  SendBrowseQuery = function() end,
  RequestMoreBrowseResults = function() end,
  GetBrowseResults = function() return {} end,
  HasFullBrowseResults = function() return false end,
  IsThrottledMessageSystemReady = function() return true end,
  ReplicateItems = function() replicateCalls = replicateCalls + 1 end,
  GetNumReplicateItems = function() return 291276 end,
  GetReplicateItemInfo = function(index)
    infoReadCount = infoReadCount + 1
    return nil,nil,2,nil,nil,nil,nil,nil,nil,500,nil,nil,nil,nil,nil,nil,1000+index,true
  end,
  GetReplicateItemLink = function(index)
    linkReadCount = linkReadCount + 1
    return "item:" .. tostring(index) .. ":0:0:0:0:0:0:0:0"
  end,
  GetReplicateItemTimeLeft = function(index) return 2 end,
}
dofile(arg[1])
local s = ModuloMarket.Scanner
s.Toggle()
assert(replicateCalls == 0, "probe must never run automatically")
assert(s.dataAgeText.text == "Auction House data from 9m ago", "data age should mirror ProfessionMaster's relative-age display")
assert(s.replicateProbeButton.text == "Prepare Replicate Probe", "probe button should be ready before a Market attempt")
s.PrepareReplicateProbe()
assert(replicateCalls == 0, "prepare step must not call API")
assert(s.replicateProbePendingConfirmation, "prepare step should require explicit confirmation")
s.ConfirmReplicateProbe()
assert(replicateCalls == 1, "confirmation should issue exactly one request")
assert(s.replicateProbeActive, "probe should wait for result event")
assert(ModuloMarket.db.replicateProbeAttemptAt == time(), "attempt timestamp should be persisted before API call")
assert(s.replicateProbeButton.text == "Waiting for response", "active probe state should be visible")
assert(ModuloMarket.db.lastSnapshot == oldSnapshot, "probe must not replace saved snapshot")
s.replicateProbeFrame.scripts.OnEvent(s.replicateProbeFrame, "REPLICATE_ITEM_LIST_UPDATE")
assert(not s.replicateProbeActive, "probe should stop after first response")
assert(s.replicateProbeButton.text == "Scan in 15m", "button should show the local cooldown countdown after response")
wallTime = wallTime + 60
s.cooldownFrame.scripts.OnUpdate(s.cooldownFrame, 1.1)
assert(s.replicateProbeButton.text == "Scan in 14m", "countdown should refresh like ProfessionMaster")
assert(s.dataAgeText.text == "Auction House data from 10m ago", "snapshot age should refresh")
assert(s.replicateProbeResult.auctionCount == 291276, "auction count should be recorded")
assert(#s.replicateProbeResult.samples == 3, "probe should sample only first/middle/last")
assert(s.replicateProbeResult.samples[1].index == 0, "first sample should use zero-based index")
assert(s.replicateProbeResult.samples[2].index == 145637, "middle sample index incorrect")
assert(s.replicateProbeResult.samples[3].index == 291275, "last sample index incorrect")
assert(s.replicateProbeResult.completeScan == false, "probe must not claim a complete scan")
assert(ModuloMarket.db.lastSnapshot == oldSnapshot, "response must not overwrite saved snapshot")
s.PrepareReplicateProbe()
assert(replicateCalls == 1, "same-session retry must be blocked")
assert(not s.replicateProbePendingConfirmation, "retry must not enter confirmation")
assert(ModuloMarket.db.lastReplicateProbe.auctionCount == 291276, "probe metadata should persist")

-- Inspect the existing cache only. This must not call ReplicateItems again.
s.StartReplicateInspection()
assert(s.replicateInspectActive, "bounded inspection should start")
assert(replicateCalls == 1, "inspection must not send a ReplicateItems request")
for i = 1, 10 do
  local before = infoReadCount
  s.replicateInspectFrame.scripts.OnUpdate(s.replicateInspectFrame, 0.016)
  assert(infoReadCount - before <= 25, "inspection exceeded 25 records in one frame")
end
assert(not s.replicateInspectActive, "bounded inspection should complete")
assert(infoReadCount == 253, "inspection should read exactly 250 additional records after 3 probe samples")
assert(linkReadCount == 253, "inspection should read exactly 250 links after 3 probe samples")
local inspected = ModuloMarket.db.lastReplicateInspection
assert(inspected.inspectedCount == 250, "inspection should process 250 records")
assert(inspected.sampleComplete == true, "bounded sample should be marked complete")
assert(inspected.fullListComplete == false, "bounded sample must not claim full-list completion")
assert(inspected.hasAllInfoTrue == 250, "hasAllInfo count should be recorded")
assert(inspected.positiveBuyouts == 250, "positive buyout count should be recorded")
assert(inspected.invalidStackCounts == 0, "valid stack counts should not be marked invalid")
assert(#inspected.sampleRows == 5, "only five sample rows should be retained")
assert(inspected.sampleRows[1].stackCount == 2, "stack count tuple index incorrect")
assert(inspected.sampleRows[1].buyoutCopper == 500, "buyout tuple index incorrect")
assert(inspected.sampleRows[1].candidateUnitPriceCopper == 250, "candidate unit price incorrect")
assert(ModuloMarket.db.lastSnapshot == oldSnapshot, "bounded inspection must not replace saved snapshot")
assert(replicateCalls == 1, "bounded inspection must not issue another request")
print("replicate probe + bounded inspection model harness PASS")
