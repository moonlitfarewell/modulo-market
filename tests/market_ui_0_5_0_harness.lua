local wall = 1794311000
function time() return wall end
function date(format, stamp) return "10 Nov 18:00" end

local function object(isRegion)
  local o = { scripts = {}, registered = {}, shown = false, text = "", enabled = true, frameLevel = 1 }
  function o:SetScript(name, callback) self.scripts[name] = callback end
  function o:RegisterEvent(name) self.registered[name] = true end
  function o:UnregisterEvent(name) self.registered[name] = nil end
  function o:SetSize(w, h) self.width, self.height = w, h end
  function o:SetPoint(...) self.points = {...} end
  function o:ClearAllPoints() self.points = nil end
  function o:SetMovable() end
  function o:StartMoving() end
  function o:StopMovingOrSizing() end
  function o:SetBackdropColor(...) self.backdropColor = {...} end
  function o:SetAlpha(v) self.alpha = v end
  function o:SetTexture(v) self.texture = v end
  function o:SetTexCoord(...) self.texCoord = {...} end
  function o:SetOrientation(v) self.orientation = v end
  function o:SetMinMaxValues(a, b) self.minValue, self.maxValue = a, b end
  function o:SetValue(v) self.value = v end
  function o:GetValue() return self.value end
  function o:SetValueStep(v) self.valueStep = v end
  function o:SetObeyStepOnDrag(v) self.obeyStep = v end
  function o:SetThumbTexture(v) self.thumbTexture = v end
  function o:SetHeight(v) self.height = v end
  function o:SetWidth(v) self.width = v end
  function o:RegisterForClicks(...) self.clicks = {...} end
  function o:GetWidth() return self.width or 140 end
  function o:GetCenter() return self.centerX or 0, self.centerY or 0 end
  function o:GetEffectiveScale() return 1 end
  function o:SetParent(v) self.parent = v end
  function o:SetHighlightTexture(v) self.highlightTexture = v end
  function o:SetFrameStrata(v) self.strata = v end
  function o:SetToplevel(v) self.toplevel = v end
  function o:SetClampedToScreen(v) self.clamped = v end
  function o:SetFrameLevel(v) self.frameLevel = v end
  function o:GetFrameLevel() return self.frameLevel or 1 end
  function o:IsObjectType(v) return v == "Frame" end
  function o:SetAllPoints() end
  function o:Disable() self.enabled = false end
  function o:Enable() self.enabled = true end
  function o:EnableMouse() end
  function o:RegisterForDrag() end
  function o:SetAutoFocus() end
  function o:SetMaxLetters() end
  function o:SetNumeric() end
  function o:SetFontObject() end
  function o:SetTextInsets() end
  function o:SetMultiLine() end
  function o:SetCursorPosition() end
  function o:HighlightText() end
  function o:SetFocus() end
  function o:ClearFocus() end
  function o:SetJustifyH() end
  function o:SetJustifyV() end
  function o:SetWordWrap() end
  function o:SetColorTexture(...) self.color = {...} end
  function o:SetScrollChild() end
  function o:SetEnabled(v) self.enabled = v end
  function o:LockHighlight() self.highlighted = true end
  function o:UnlockHighlight() self.highlighted = false end
  function o:SetText(v) self.text = tostring(v or "") end
  function o:GetText() return self.text end
  function o:Show()
    local was = self.shown
    self.shown = true
    if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
  end
  function o:Hide() self.shown = false end
  function o:IsShown() return self.shown end
  function o:SetVerticalScroll(v)
    self.scroll = v
    if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self, v) end
  end
  function o:CreateFontString() return object(true) end
  function o:CreateTexture() return object(true) end
  if not isRegion then o.TitleText = object(true) end
  return o
end

local allFrames = {}
function CreateFrame(kind, name, parent, template)
  local frame = object(false)
  frame.kind, frame.name, frame.parent, frame.template = kind, name, parent, template
  allFrames[#allFrames + 1] = frame
  if template == "BasicFrameTemplateWithInset" then
    frame.Bg = object(true)
    frame.InsetBg = object(true)
  end
  return frame
end

UIParent = object(false)
Minimap = object(false)
UISpecialFrames = {}
function GetCursorPosition() return 1100, 1100 end
GameTooltip = {
  SetOwner=function(self, owner) self.owner = owner end,
  SetText=function(self, value) self.text = value end,
  SetFrameStrata=function(self, value) self.strata = value end,
  SetFrameLevel=function(self, value) self.frameLevel = value end,
  AddLine=function() end,
  Show=function(self) self.shown = true end,
  Hide=function(self) self.shown = false end,
}
AuctionHouseFrame = object(false)

local rows = {}
for i = 1, 16574 do
  local id = 6000 + (i % 4000)
  rows[#rows + 1] = {
    key = tostring(id) .. ":" .. tostring(i),
    itemID = id, itemName = "Item " .. tostring(id),
    minPriceCopper = 10000 + (i % 1100) * 1100,
    totalQuantity = 1 + (i % 3), minPriceQuantity = 1,
    auctionCount = 1, pricedQuantity = 1 + (i % 3), unpricedQuantity = 0,
  }
end
local function addRow(id, name, price, quantity, listings)
  rows[#rows + 1] = {
    key = tostring(id) .. ":fixture", itemID = id, itemName = name,
    minPriceCopper = price, totalQuantity = quantity, minPriceQuantity = quantity,
    auctionCount = listings, pricedQuantity = quantity, unpricedQuantity = 0,
  }
end
addRow(1100, "Copper Ore", 4000, 7, 2)
addRow(1200, "Low Supply Ore", 8000, 8, 2)
addRow(1300, "Known Crafted Item", 25000, 4, 1)
addRow(1400, "Future Crafted Item", 40000, 2, 1)
addRow(1500, "Unknown Source Item", 30000, 3, 1)
addRow(1600, "Borrowed Source Item", 50000, 1, 1)
addRow(2770, "Copper Ore Node", 4000, 7, 2)

local replicateState = { active = false, attemptedThisSession = false, cooldownRemaining = 0, pendingConfirmation = false }
ModuloMarket = {
  db = {
    lastSnapshot = { complete = true, timestamp = wall - 3600, source = "browse-summary",
      resultCount = #rows, rows = rows },
    auctionHouseCutPercent = 5, lowSupplyThreshold = 3,
    marketHistory = {
      { timestamp = wall - 86400, items = { [1100] = { price = 5000, quantity = 9 } } },
      { timestamp = wall - 3600, items = { [1100] = { price = 4000, quantity = 7 } } },
    },
  },
  Replicate = { GetState = function() return replicateState end },
  Scanner = { Toggle = function() ModuloMarket.scannerOpened = true end },
}

local knownRecipes = {
  { recipeID = 7001, professionID = 197, professionName = "Tailoring", professionSkill = 225,
    recipeName = "Craft Copper Widget", outputItemID = 1300, quantityMin = 1, hasSingleItemOutput = true,
    reagentDataAvailable = true, reagents = {
      { quantity = 1, choices = { { itemID = 1100, name = "Copper Ore" } } },
    } },
  { recipeID = 7002, professionID = 197, professionName = "Tailoring", professionSkill = 225,
    recipeName = "Craft Loss Item", outputItemID = 1200, quantityMin = 1, hasSingleItemOutput = true,
    reagentDataAvailable = true, reagents = {
      { quantity = 1, choices = { { itemID = 1100, name = "Copper Ore" } } },
    } },
}
ModuloMarket.Recipes = {
  GetAllRecipes = function() return knownRecipes end,
  GetProfessionSummary = function()
    return { professions = {
      { professionID = 197, name = "Tailoring", skill = 225 },
      { professionID = 186, name = "Mining", skill = 0 },
    } }
  end,
  BuildEconomics = function(recipe, lookup, cut)
    local outputID = tonumber(recipe.outputItemID or recipe.craftedItemId)
    local output = outputID and lookup(outputID)
    local sale = output and output.minPriceCopper
    local materialCost = recipe.recipeID == 7001 and 1000 or (recipe.recipeID == 7002 and 9000 or 2000)
    local profit = sale and math.floor(sale * (1 - (cut or 5) / 100)) - materialCost or nil
    return {
      recipeData = recipe, recipeID = recipe.recipeID, professionID = recipe.professionID,
      recipeKey = tostring(recipe.professionID) .. ":" .. tostring(recipe.recipeID),
      itemID = outputID, itemName = output and output.itemName or recipe.recipeName,
      recipeName = recipe.recipeName, professionName = recipe.professionName, professionSkill = recipe.professionSkill,
      salePriceCopper = sale, minPriceCopper = sale, totalQuantity = output and output.totalQuantity or 0,
      materialCostCopper = materialCost, profitCopper = profit, estimatedProfitCopper = profit,
      estimatedMarginPercent = profit and profit / materialCost * 100 or 0,
      reagentLines = { { itemID = 1100, itemName = "Copper Ore", quantity = 1, lineCostCopper = materialCost } },
      outputQuantity = tonumber(recipe.quantityMin) or 1, grossSaleCopper = sale,
      netSaleCopper = sale and math.floor(sale * (1 - (cut or 5) / 100)),
      cutPercent = cut or 5, costComplete = true, missing = {},
    }
  end,
}

local futureRows = {
  [197] = {
    { recipeID = 7100, name = "Future Tailoring Recipe", craftedItemId = 1400, quantityMin = 1,
      requiredSkill = 150, reagents = { [1100] = 2 }, sources = { trainer = true } },
    { recipeID = 7101, name = "Unknown Source Recipe", craftedItemId = 1500, quantityMin = 1,
      requiredSkill = 175, reagents = { [1200] = 1 } },
    { recipeID = 7102, name = "Borrowed Source Recipe", craftedItemId = 1600, quantityMin = 1,
      requiredSkill = 200, reagents = { [1100] = 3 }, sources = { trainer = true } },
    -- Same known output and recipe name, but a different library key: this must
    -- not be shown as a future recipe for an item the character already crafts.
    { recipeID = 7103, name = "Craft Copper Widget", craftedItemId = 1300, quantityMin = 1,
      requiredSkill = 225, reagents = { [1100] = 1 }, sources = { trainer = true } },
  },
}
local db = {}
function db:IsReady() return true end
function db:GetGameVersion() return "Forever" end
function db:GetProfessions() return { 197 } end
function db:Iterate(professionID)
  local list, index = futureRows[professionID] or {}, 0
  return function()
    index = index + 1
    local recipe = list[index]
    if recipe then return professionID, recipe.recipeID, recipe end
  end
end
function db:GetRecipeSources(recipeID)
  for _, recipe in ipairs(futureRows[197]) do
    if recipe.recipeID == recipeID then return recipe.sources end
  end
end
function db:IsAutoTaughtRecipe() return false end
function db:IsHiddenRecipe() return false end
function db:IsBorrowed(recipeID, field)
  if recipeID == 7102 and (field == "sources" or field == "requiredSkill") then return "Vanilla" end
end
function LibStub(name)
  if name == "LibProfessionDB-1.0" then return db end
end

dofile("AddOns/ModuloMarket/GatheringItems.lua")
dofile("AddOns/ModuloMarket/ProfessionData.lua")
dofile(arg[1])

local vendorReady = {}
function GetItemInfo(itemID)
  if itemID == 1300 and not vendorReady[itemID] then return nil end
  return "Item " .. tostring(itemID), "item:" .. tostring(itemID), 1, 1, 1,
    "Trade Goods", "Other", 20, "", 134400, 125, 7
end
C_Item = {
  RequestLoadItemDataByID = function(itemID) C_Item.requested = itemID end,
}

local ui = ModuloMarket.MarketUI
local function drain()
  local count = 0
  while ui.catalogBuild or ui.economicsIndexBuild or ui.viewBuild or ui.rankSort do
    count = count + 1
    assert(count < 1500, "incremental UI build did not complete")
    ui.frame.scripts.OnUpdate(ui.frame, 0.016)
  end
end

ui.Toggle()
assert(ui.frame and ui.frame:IsShown(), "Market UI should open")
assert(ui.frame.strata == "TOOLTIP", "Market should remain frontmost")
assert(UISpecialFrames[1] == "ModuloMarketMainFrame", "Escape-close registration should remain")
drain()

local knownOutput = ModuloMarket.ProfessionData.GetItem(1300)
assert(knownOutput and #knownOutput.knownCrafts == 1,
  "known recipe output should remain classified as known")
assert(#knownOutput.futureCrafts == 0 and not ModuloMarket.ProfessionData.Matches(1300, 0, "future"),
  "a differently keyed database duplicate of a known recipe must not also be future")
local knownTags = ModuloMarket.ProfessionData.GetItemTags(1300) or {}
for _, tag in ipairs(knownTags) do
  assert(tag ~= "future" and tag ~= "futureBorrowed",
    "known output tags must not contain a future classification for the same recipe")
end
-- Item-level roles are exclusive: a known output stays a known output even if
-- a separate unlearned route for the same item exists in the database.
knownOutput.futureCrafts[1] = { borrowedSources = true }
assert(not ModuloMarket.ProfessionData.Matches(1300, 0, "borrowed"),
  "known output must not also match the borrowed future-output role")
local exclusiveTags = ModuloMarket.ProfessionData.GetItemTags(1300) or {}
for _, tag in ipairs(exclusiveTags) do
  assert(tag ~= "futureBorrowed", "known output must have a single item-level craft state")
end
knownOutput.futureCrafts[1] = nil

for _, tab in ipairs({ "market", "economics", "crafting", "allcrafts", "materials", "low", "history" }) do
  assert(ui.tabs[tab], "missing tab " .. tab)
end
assert(not ui.tabs.opportunities, "the duplicate Profitable tab should be removed")

ui.tabs.market.scripts.OnEnter(ui.tabs.market)
assert(GameTooltip.strata == "TOOLTIP" and GameTooltip.frameLevel > ui.frame:GetFrameLevel(),
  "tab tooltip must render above the Market frame")
ui.tabs.market.scripts.OnLeave(ui.tabs.market)

-- Click the actual profession popup option and verify that Mining + Gatherable resources
-- includes mapped ore even when current skill is below the node threshold.
ui.professionDropdown.ToggleMenu()
local miningOption
for _, button in ipairs(ui.professionDropdown.optionButtons) do
  if button:GetText() == "Mining" then miningOption = button; break end
end
assert(miningOption, "Mining profession option should exist")
miningOption.scripts.OnClick(miningOption)
ui.roleDropdown.ToggleMenu()
local gatherOption
for _, button in ipairs(ui.roleDropdown.optionButtons) do
  if button:GetText() == "Gathering resources" then gatherOption = button; break end
end
assert(gatherOption, "Gatherable resources role option should exist")
gatherOption.scripts.OnClick(gatherOption)
drain()
assert(#ui.viewRows > 0, "Mining + Gatherable resources should return mapped materials regardless of current skill")
local copper = ModuloMarket.ProfessionData.GetItem(2770)
assert(copper and copper.gathering[186] and copper.gathering[186].canGatherNow == false,
  "gathering classification should be independent of current skill")
ui.rows[1].scripts.OnClick(ui.rows[1])
assert(ui.detailEconomics:GetText():find("requires skill", 1, true),
  "gathering detail should distinguish unlearned/insufficient skill from missing resource mapping")

-- Item role filtering remains available in the other item-oriented views.
for _, tab in ipairs({ "economics", "materials", "low", "history" }) do
  ui.tabs[tab].scripts.OnClick(ui.tabs[tab])
  drain()
  assert(ui.roleDropdown.enabled, "role dropdown should remain enabled on " .. tab)
end

-- Materials includes reagent items and their details use real line breaks.
ui.professionFilter = 0
ui.tabs.materials.scripts.OnClick(ui.tabs.materials)
drain()
local hasMaterial = false
for _, item in ipairs(ui.viewRows) do if item.itemID == 1100 then hasMaterial = true end end
assert(hasMaterial, "Materials should include known recipe reagents")
ui.search:SetText("Copper Ore")
ui.search.scripts.OnTextChanged(ui.search)
drain()
if #ui.viewRows > 0 then
  ui.rows[1].scripts.OnClick(ui.rows[1])
  local detail = ui.detailEconomics:GetText()
  assert(not detail:find("\\n", 1, true), "relationship detail must not print literal backslash-n")
end

-- All Crafts combines known, future, borrowed and unknown-source recipe records.
ui.search:SetText("")
ui.search.scripts.OnTextChanged(ui.search)
ui.tabs.allcrafts.scripts.OnClick(ui.tabs.allcrafts)
drain()
assert(#ui.viewRows == 5, "All Crafts should contain known plus three future recipe candidates")
local statuses = {}
for _, item in ipairs(ui.viewRows) do statuses[item.craftSourceStatus] = true end
assert(statuses.known and statuses.future and statuses.borrowed and statuses.unknown,
  "All Crafts should label each source-certainty class")
ui.roleDropdown.ToggleMenu()
local unknownOption
for _, button in ipairs(ui.roleDropdown.optionButtons) do
  if button:GetText() == "Unlearned: unknown" then unknownOption = button; break end
end
assert(unknownOption, "All Crafts should offer an unknown-source filter")
unknownOption.scripts.OnClick(unknownOption)
drain()
assert(#ui.viewRows == 1 and ui.viewRows[1].itemID == 1500,
  "Unknown source filter should isolate source-unknown candidate recipes")

-- My Crafts remains learned-only; Economics indexes all craft routes incrementally.
ui.tabs.crafting.scripts.OnClick(ui.tabs.crafting)
drain()
assert(#ui.viewRows == 2, "My Crafts should retain only the two known recipes")
ui.tabs.economics.scripts.OnClick(ui.tabs.economics)
drain()
assert(ui.economicsByItemID and ui.economicsByItemID[1300],
  "Economics should index known craft material costs and profit")
local econItem
for _, item in ipairs(ui.viewRows) do if item.itemID == 1300 then econItem = item; break end end
assert(econItem and econItem.economics and econItem.economics.profitCopper ~= nil,
  "Economics should show automatic recipe profit for a craftable market item")
local econRowIndex
for i, item in ipairs(ui.visibleRows) do
  if item and item.itemID == 1300 then econRowIndex = i; break end
end
assert(econRowIndex, "known crafted output should be visible in Economics")
ui.rows[econRowIndex].scripts.OnClick(ui.rows[econRowIndex])
local vendorDetail = ui.detailEconomics:GetText()
assert(vendorDetail:find("Vendor sell / unit", 1, true),
  "Economics detail should show vendor sale alongside auction value")
assert(vendorDetail:find("Loading item data", 1, true),
  "uncached vendor values should show a loading state while the client loads item data")
assert(C_Item.requested == 1300, "selecting an uncached item should request item data")
vendorReady[1300] = true
for _, frame in ipairs(allFrames) do
  if frame.registered["GET_ITEM_INFO_RECEIVED"] and frame.scripts.OnEvent then
    frame.scripts.OnEvent(frame, "GET_ITEM_INFO_RECEIVED", 1300, true)
  end
end
vendorDetail = ui.detailEconomics:GetText()
assert(ui.vendorPriceCache[1300] and ui.vendorPriceCache[1300].sellPrice == 125,
  "vendor value should be cached after the item-info event")
assert(not vendorDetail:find("Loading item data", 1, true)
  and not vendorDetail:find("Unavailable from client data", 1, true),
  "vendor detail should refresh after item data arrives")

-- Low supply counts units and listings separately, and materials use a broader threshold.
ui.tabs.low.scripts.OnClick(ui.tabs.low)
drain()
local lowMaterial
for _, item in ipairs(ui.viewRows) do if item.itemID == 1200 then lowMaterial = item end end
assert(lowMaterial, "Low Supply should include low-stock crafting materials")

-- History shows delta and a small chart from retained scan points.
ui.tabs.history.scripts.OnClick(ui.tabs.history)
drain()
local historyItem
for _, item in ipairs(ui.viewRows) do if item.itemID == 1100 then historyItem = item end end
assert(historyItem and historyItem.historyDeltaCopper == -1000,
  "History should calculate the latest-vs-previous price movement")
ui.rows[1].scripts.OnClick(ui.rows[1])
local visibleBars = 0
for _, bar in ipairs(ui.historyBars) do if bar.shown then visibleBars = visibleBars + 1 end end
assert(visibleBars == 2, "History graph should render its two available points")

print("ModuloMarket 0.5.3 UI harness passed")
