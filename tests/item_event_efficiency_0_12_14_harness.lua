local path = assert(arg[1], "MarketUI.lua path required")
local file = assert(io.open(path, "r"))
local source = file:read("*a")
file:close()
local first = assert(source:find('local vendorInfoEvents = CreateFrame("Frame")', 1, true))
local last = assert(source:find("\nlocal function NormalizeBuildKey", first, true))
local chunk = assert(load(source:sub(first, last - 1), "vendor-info-handler"))

local now = 10
local modern = false
local classicVisible = false
local modernVisible = false
local renders = 0
local modernRenders = 0
local selections = 0
local readCalls = 0
local classCalls = 0

local frame = { scripts = {}, events = {} }
function frame:RegisterEvent(event) self.events[event] = true end
function frame:SetScript(name, fn) self.scripts[name] = fn end

function CreateFrame() return frame end
function Now() return now end
function ReadVendorInfo() readCalls = readCalls + 1; return 12 end
function GetItemClassID() classCalls = classCalls + 1; return 2 end
function SelectItem() selections = selections + 1 end

itemIconCache = {}
itemQualityCache = {}
UI = {
    itemClassCache = {}, itemClassRequested = {}, itemClassPendingIDs = {},
    itemClassFailed = {}, vendorPriceRequested = {}, vendorPriceFailed = {},
    vendorPriceCache = {}, itemTypeFilter = "all", activeTab = "market",
    selectedItem = nil, blizzlikeVisible = false,
    frame = { IsShown = function() return classicVisible end },
    RenderRows = function() renders = renders + 1 end,
}
MM = {
    Theme = { GetTheme = function() return modern and "modern" or "blizzlike" end },
    ModernUI = {
        IsShown = function() return modernVisible end,
        RenderRows = function() modernRenders = modernRenders + 1 end,
    },
}

chunk()
local onEvent = frame.scripts.OnEvent
assert(type(onEvent) == "function")

-- Hidden windows: caches update, but no render queue is scheduled.
onEvent(frame, "GET_ITEM_INFO_RECEIVED", 101, true)
assert(readCalls == 0 and classCalls == 0)
assert(frame.scripts.OnUpdate == nil)
assert(renders == 0 and modernRenders == 0)

-- Visible classic window: a burst of distinct item events coalesces to one render.
classicVisible = true
UI.blizzlikeVisible = true
onEvent(frame, "GET_ITEM_INFO_RECEIVED", 102, true)
onEvent(frame, "ITEM_DATA_LOAD_RESULT", 102, true)
onEvent(frame, "ITEM_DATA_LOAD_RESULT", 103, true)
assert(readCalls == 0 and classCalls == 0)
assert(type(frame.scripts.OnUpdate) == "function")
now = now + 0.13
frame.scripts.OnUpdate(frame, 0.13)
assert(readCalls == 2 and classCalls == 2)
assert(renders == 1 and modernRenders == 0)

-- Selected-item detail is refreshed once, not as an extra row render.
UI.selectedItem = { itemID = 104 }
onEvent(frame, "GET_ITEM_INFO_RECEIVED", 104, true)
now = now + 0.13
frame.scripts.OnUpdate(frame, 0.13)
assert(selections == 1 and renders == 1)

-- Modern presentation gets one coalesced render when actually visible.
modern = true
modernVisible = true
onEvent(frame, "GET_ITEM_INFO_RECEIVED", 105, true)
onEvent(frame, "ITEM_DATA_LOAD_RESULT", 106, true)
now = now + 0.13
frame.scripts.OnUpdate(frame, 0.13)
assert(modernRenders == 1)

-- Modern window hidden: no render scheduling.
modernVisible = false
onEvent(frame, "GET_ITEM_INFO_RECEIVED", 107, true)
assert(frame.scripts.OnUpdate == nil)
assert(modernRenders == 1)

print("Item event efficiency harness: 5 scenarios passed")
