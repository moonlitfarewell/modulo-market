local wall = 1794311000
function time() return wall end
function date(format, stamp) return "10 Nov 18:00" end
local function object(isRegion)
  local o = { scripts = {}, registered = {}, shown = false, text = "", enabled = true }
  function o:SetScript(name, callback) self.scripts[name] = callback end
  function o:RegisterEvent(name) self.registered[name] = true end
  function o:UnregisterEvent(name) self.registered[name] = nil end
  function o:SetSize(w, h) self.width, self.height = w, h end
  function o:SetPoint(...) self.points = {...} end
  function o:ClearAllPoints() self.points = nil end
  function o:SetMovable() end
  function o:SetBackdropColor(...) self.backdropColor = {...} end
  function o:SetAlpha(v) self.alpha = v end
  function o:SetTexture(v) self.texture = v end
  function o:SetTexCoord(...) self.texCoord = {...} end
  function o:SetOrientation(v) self.orientation = v end
  function o:SetMinMaxValues(a, b) self.minValue, self.maxValue = a, b end
  function o:SetValue(v) self.value = v end
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
  function o:SetFrameStrata(v) self.strata = v end function o:SetToplevel(v) self.toplevel = v end
  function o:SetClampedToScreen(v) self.clamped = v end
  function o:SetFrameLevel(v) self.frameLevel = v end function o:GetFrameLevel() return self.frameLevel or 1 end
  function o:IsObjectType(v) return v == "Frame" end
  function o:SetAllPoints() end
  function o:Disable() self.enabled = false end function o:Enable() self.enabled = true end
  function o:EnableMouse() end function o:RegisterForDrag() end
  function o:SetAutoFocus() end function o:SetMaxLetters() end
  function o:SetNumeric() end function o:SetFontObject() end function o:SetTextInsets() end
  function o:SetMultiLine() end function o:SetCursorPosition() end function o:HighlightText() end
  function o:SetFocus() end function o:ClearFocus() end function o:SetWidth() end
  function o:SetJustifyH() end function o:SetJustifyV() end
  function o:SetWordWrap() end function o:SetColorTexture() end function o:SetScrollChild() end
  function o:SetHighlightTexture() end function o:SetEnabled(v) self.enabled = v end
  function o:LockHighlight() self.highlighted = true end function o:UnlockHighlight() self.highlighted = false end
  function o:SetText(v) self.text = tostring(v or "") end function o:GetText() return self.text end
  function o:Show()
    local was = self.shown
    self.shown = true
    if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
  end
  function o:Hide() self.shown = false end function o:IsShown() return self.shown end
  function o:SetVerticalScroll(v)
    self.scroll = v
    if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self, v) end
  end
  function o:CreateFontString() return object(true) end
  function o:CreateTexture() return object(true) end
  if not isRegion then o.TitleText = object(true) end
  return o
end
function CreateFrame(kind, name, parent, template)
  local frame = object(false)
  frame.kind, frame.name, frame.parent, frame.template = kind, name, parent, template
  if template == "BasicFrameTemplateWithInset" then
    frame.Bg = object(true)
    frame.InsetBg = object(true)
  end
  return frame
end
UIParent = object(false)
Minimap = object(false)
UISpecialFrames = {}
function GetCursorPosition() return 100, 100 end
GameTooltip = { SetOwner=function() end, AddLine=function() end, Show=function() end, Hide=function() end }
local dropdownButtons = {}
function UIDropDownMenu_SetWidth(frame, width) frame.dropdownWidth = width end
function UIDropDownMenu_JustifyText() end
function UIDropDownMenu_Initialize(frame, callback) frame.initialize = callback end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton(info) dropdownButtons[#dropdownButtons + 1] = info end
function UIDropDownMenu_SetSelectedValue(frame, value) frame.selectedValue = value end
function UIDropDownMenu_SetText(frame, text) frame.dropdownText = text end
function UIDropDownMenu_EnableDropDown(frame) frame.dropdownEnabled = true end
function UIDropDownMenu_DisableDropDown(frame) frame.dropdownEnabled = false end
AuctionHouseFrame = object(false)

local rows = {}
for i = 1, 16574 do
  local id = 1000 + (i % 4000)
  rows[#rows + 1] = {
    key = tostring(id) .. ":" .. tostring(i),
    itemID = id,
    itemName = "Item " .. tostring(id),
    minPriceCopper = 10000 + (i % 100) * 100,
    totalQuantity = 1 + (i % 3),
    minPriceQuantity = 1,
    auctionCount = 1,
    pricedQuantity = 1 + (i % 3),
    unpricedQuantity = 0,
  }
end
-- Two variants of one item: the cheapest price wins; all quantities are combined.
rows[1] = { key = "100:variant-a", itemID = 100, itemName = "Copper Ore",
  minPriceCopper = 4000, totalQuantity = 3, minPriceQuantity = 3, auctionCount = 1, pricedQuantity = 3 }
rows[2] = { key = "100:variant-b", itemID = 100, itemName = "Copper Ore",
  minPriceCopper = 3000, totalQuantity = 4, minPriceQuantity = 4, auctionCount = 1, pricedQuantity = 4 }
rows[3] = { key = "200:a", itemID = 200, itemName = "Low Supply Ore",
  minPriceCopper = 8000, totalQuantity = 1, minPriceQuantity = 1, auctionCount = 1, pricedQuantity = 1 }
rows[4] = { key = "200:b", itemID = 200, itemName = "Low Supply Ore",
  minPriceCopper = 9000, totalQuantity = 2, minPriceQuantity = 2, auctionCount = 1, pricedQuantity = 2 }

local replicateState = { active = false, attemptedThisSession = false, cooldownRemaining = 0, pendingConfirmation = false }
ModuloMarket = {
  db = {
    lastSnapshot = {
      complete = true, timestamp = wall - 3600, source = "browse-summary",
      resultCount = #rows, rows = rows,
    },
    costBasisByItemID = { [100] = 2000, [200] = 5000 },
    auctionHouseCutPercent = 5,
    lowSupplyThreshold = 3,
    marketHistory = {
      { timestamp = wall - 86400, items = { [100] = { price = 5000, quantity = 9 } } },
      { timestamp = wall - 3600, items = { [100] = { price = 4000, quantity = 7 } } },
    },
  },
  Replicate = { GetState = function() return replicateState end },
  Scanner = { Toggle = function() ModuloMarket.scannerOpened = true end },
}
local knownRecipes = {
  { recipeID = 7001, professionID = 197, professionName = "Tailoring", professionSkill = 225,
    recipeName = "Craft Copper Widget", outputItemID = 100, reagents = {
      { quantity = 1, choices = { { itemID = 200, name = "Low Supply Ore" } } },
    } },
  { recipeID = 7002, professionID = 197, professionName = "Tailoring", professionSkill = 225,
    recipeName = "Craft Profit Item", outputItemID = 300, reagents = {
      { quantity = 1, choices = { { itemID = 100, name = "Copper Ore" } } },
    } },
}
ModuloMarket.Recipes = {
  GetAllRecipes = function() return knownRecipes end,
  BuildEconomics = function(recipe, lookup, cut)
    local output = lookup(recipe.outputItemID)
    local sale = output and output.minPriceCopper
    local cost = recipe.recipeID == 7001 and 500 or 1000
    local profit = sale and (math.floor(sale * (1 - (cut or 5) / 100)) - cost) or nil
    return {
      recipeData = recipe, recipeID = recipe.recipeID, professionID = recipe.professionID,
      recipeKey = tostring(recipe.professionID) .. ":" .. tostring(recipe.recipeID),
      itemID = recipe.outputItemID, itemName = output and output.itemName or recipe.recipeName,
      recipeName = recipe.recipeName, professionName = recipe.professionName, professionSkill = recipe.professionSkill,
      salePriceCopper = sale, minPriceCopper = sale, totalQuantity = output and output.totalQuantity or 0,
      materialCostCopper = cost, profitCopper = profit, estimatedProfitCopper = profit,
      estimatedMarginPercent = profit and profit / cost * 100 or 0,
      reagentLines = { { itemID = recipe.reagents[1].choices[1].itemID, itemName = recipe.reagents[1].choices[1].name,
        quantity = 1, lineCostCopper = cost, choiceCount = 1 } },
      outputQuantity = 1, grossSaleCopper = sale, netSaleCopper = sale and math.floor(sale * (1 - (cut or 5) / 100)),
      cutPercent = cut or 5, costComplete = true, missing = {},
    }
  end,
}
for id = 1000, 1019 do ModuloMarket.db.costBasisByItemID[id] = 1000 end
dofile("AddOns/ModuloMarket/GatheringItems.lua")
dofile("AddOns/ModuloMarket/ProfessionData.lua")
dofile(arg[1])
local ui = ModuloMarket.MarketUI
ui.Toggle()
assert(ui.frame and ui.frame:IsShown(), "Market UI should open")
assert(ui.frame.strata == "TOOLTIP" and ui.frame.toplevel == true,
  "Market window should open above normal addon frames")
assert(ui.frame.width == 1220 and ui.frame.height == 760,
  "Market window should use the wider layout")
assert(UISpecialFrames[1] == "ModuloMarketMainFrame",
  "Market window should be registered for Escape closing")
assert(ui.visibleCount >= 25 and ui.rowHeight * ui.visibleCount >= 510,
  "Market list should cover the viewport including partially visible first/last rows")
assert(ui.tabs.market.selectedMark.shown and ui.tabs.crafting.selectedMark.shown == false,
  "tab strip should visually mark the active tab")
assert(ui.AttachAuctionHouseButton() and ui.auctionHouseButton,
  "Auction House should expose a direct Market launcher button")
assert(ui.auctionHouseButton.strata == "TOOLTIP",
  "Auction House launcher should remain visible above ordinary AH panels")
assert(ui.auctionHouseButton.points and ui.auctionHouseButton.points[1] == "TOPRIGHT",
  "Auction House launcher should sit in the header at the top-right, clear of the portrait")
assert(ui.catalogBuild ~= nil, "opening a large saved snapshot must start an incremental index")
assert(#ui.catalog == 0, "opening the window must not synchronously traverse all snapshot rows")
assert(ui.status:GetText():find("Preparing market index", 1, true), "indexing progress should be visible")
replicateState.pendingConfirmation = true
ui.RefreshActions()
assert(ui.confirmButton.shown and ui.cancelButton.shown,
  "explicit full-scan confirmation and cancel controls must remain available")
replicateState.pendingConfirmation = false
ui.RefreshActions()

local frames = 0
while ui.catalogBuild or ui.viewBuild or ui.rankSort do
  frames = frames + 1
  assert(frames < 300, "incremental catalog/view build should finish in bounded frames")
  ui.frame.scripts.OnUpdate(ui.frame, 0.016)
end
assert(frames > 50, "large catalog should be spread across multiple frames")
assert(#ui.catalog == 4002, "catalog should collapse duplicate item variants into unique item IDs")
assert(ui.resultCount:GetText() == "1-25 / 4002",
  "result range should make the full catalogue and current visible window explicit")
ui.scroll.scripts.OnVerticalScroll(ui.scroll, 23 * ui.rowHeight)
assert(ui.resultCount:GetText() == "24-48 / 4002",
  "scrolling should advance the visible result range beyond the first twenty rows")
assert(ui.rows[1].points and ui.rows[1].points[5] == -((24 - 1) * ui.rowHeight),
  "virtualized row pool must be re-anchored at the scrolled catalogue index")
assert(ui.rows[1].shown and ui.rows[1].name:GetText() == ui.viewRows[24].itemName,
  "the first visible row must show the item at the current scroll offset")
local lastOffset = (#ui.viewRows * ui.rowHeight) - 510
ui.scroll.scripts.OnVerticalScroll(ui.scroll, lastOffset)
local lastVisible = false
for i = 1, ui.visibleCount do
  if ui.visibleRows[i] and ui.visibleRows[i].itemID == ui.viewRows[#ui.viewRows].itemID then lastVisible = true end
end
assert(lastVisible, "the final catalogue item must be rendered at the maximum scroll offset")
assert(ui.resultCount:GetText():find("4002 / 4002", 1, true),
  "scrolling should expose the true final item in the range counter")
ui.scroll.scripts.OnVerticalScroll(ui.scroll, 0)
ui.frame:Hide()
ui.auctionHouseButton.scripts.OnClick()
assert(ui.frame:IsShown(), "Auction House launcher click should open Market without slash commands")
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end

local copper
local low
for _, item in ipairs(ui.catalog) do
  if item.itemID == 100 then copper = item end
  if item.itemID == 200 then low = item end
end
assert(copper and copper.variantCount == 2, "same item ID variants should become one market row")
assert(copper.minPriceCopper == 3000 and copper.minPriceQuantity == 4,
  "cheapest variant and quantity at that price should be shown")
assert(copper.totalQuantity == 7, "total supply should combine all variants")
assert(low and low.totalQuantity == 3, "total quantity should combine low-supply variants")

assert(ui.resultCount:GetText():find("/ 4002", 1, true), "main view should show the complete item count")
assert(ui.rows[1].shown, "visible list should render")
ui.search:SetText("Copper Ore")
ui.search.scripts.OnTextChanged(ui.search)
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(#ui.viewRows == 1 and ui.viewRows[1].itemID == 100, "search should filter grouped items")
ui.search:SetText("")
ui.search.scripts.OnTextChanged(ui.search)
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(ui.professionDropdown and ui.roleDropdown,
  "profession and item-role filters should be present")
assert(ui.professionDropdown.label:GetText() == "All professions",
  "profession filter should default to all professions")
assert(ui.roleDropdown.label:GetText() == "All item types",
  "item-role filter should default to all item roles")
local function openDropdown(frame)
  frame.scripts.OnClick(frame)
  assert(frame.menu and frame.menu:IsShown(), "dropdown button click must open its visible popup menu")
  return frame.optionButtons
end
local professionOptions = openDropdown(ui.professionDropdown)
local selectedProfession
for _, optionButton in ipairs(professionOptions) do
  if optionButton:GetText() == "Tailoring" then selectedProfession = optionButton; break end
end
assert(selectedProfession and selectedProfession.enabled, "Tailoring should be offered as an enabled profession option")
selectedProfession.scripts.OnClick(selectedProfession)
assert(not ui.professionDropdown.menu:IsShown(), "selecting a dropdown option should close the popup")
assert(ui.professionFilter == 197 and ui.professionDropdown.label:GetText() == "Tailoring",
  "selecting a profession option through the visible menu must apply that profession")
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
local roleOptions = openDropdown(ui.roleDropdown)
local selectedRole
for _, optionButton in ipairs(roleOptions) do
  if optionButton:GetText() == "Known craft outputs" then selectedRole = optionButton; break end
end
assert(selectedRole and selectedRole.enabled, "Known crafts role should be enabled")
selectedRole.scripts.OnClick(selectedRole)
assert(ui.itemRoleFilter == "known" and ui.roleDropdown.label:GetText() == "Known craft outputs",
  "selecting an item-role option through the visible menu must apply that role")
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(#ui.viewRows == 1 and ui.viewRows[1].itemID == 100,
  "Known crafts dropdown selection must filter the market catalogue")
local allRoles = openDropdown(ui.roleDropdown)
for _, optionButton in ipairs(allRoles) do
  if optionButton:GetText() == "All item types" then optionButton.scripts.OnClick(optionButton); break end
end
local allProfessions = openDropdown(ui.professionDropdown)
for _, optionButton in ipairs(allProfessions) do
  if optionButton:GetText() == "All professions" then optionButton.scripts.OnClick(optionButton); break end
end
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
ui.professionFilter = 197
ui.StartViewBuild()
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(#ui.viewRows == 2, "All items profession filter should include known output and reagent relationships")
ui.itemRoleFilter = "known"
ui.StartViewBuild()
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(#ui.viewRows == 1 and ui.viewRows[1].itemID == 100,
  "Known crafts role filter should include learned recipe outputs, not reagents")
ui.professionFilter = 0
ui.itemRoleFilter = "all"
ui.StartViewBuild()
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end

ui.rows[1].scripts.OnClick(ui.rows[1])
assert(ui.selectedItem.itemID == 100, "selecting an item should open detail")
assert(ui.detailPrice:GetText():find("UI%-SilverIcon") and ui.detailPrice:GetText():find("UI%-CopperIcon"),
  "money should use native silver/copper coin textures")
assert(ui.detailSupply:GetText():find("7 units", 1, true), "detail should show combined supply")
assert(ui.detailEconomics:GetText():find("CRAFTED BY", 1, true), "material detail should show recipes that create the selected item")
assert(ui.detailEconomics:GetText():find("USED IN", 1, true), "material detail should show recipes that consume the selected item")
assert(ui.detailProfit:GetText():find("Gathering and recipe relationships", 1, true), "market item detail should focus on recipe context")
assert(ui.historyText:GetText():find("10 Nov", 1, true), "historical prices should render for selected item")

ui.search:SetText("")
ui.search.scripts.OnTextChanged(ui.search)
ui.tabs.crafting.scripts.OnClick(ui.tabs.crafting)
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(#ui.viewRows == 2, "My crafts should show all captured character recipes, including incomplete market data")
assert(ui.tabs.crafting.tooltipText:find("including losses", 1, true),
  "My crafts tab should explain that it includes losses and incomplete prices")
ui.professionFilter = 164
ui.StartViewBuild()
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(#ui.viewRows == 0, "My crafts profession filter should exclude recipes from other professions")
ui.professionFilter = 197
ui.StartViewBuild()
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(#ui.viewRows == 2, "My crafts profession filter should restore the selected profession's recipes")
ui.professionFilter = 0
ui.StartViewBuild()
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(ui.rows[1].price:GetText() ~= "No buyout", "craft rows should show output sale prices")
ui.headerButtons[2].scripts.OnClick(ui.headerButtons[2])
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(ui.viewRows[1].salePriceCopper ~= nil,
  "My crafts Sale / unit header should sort known sale prices before missing prices")
ui.headerButtons[4].scripts.OnClick(ui.headerButtons[4])
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(ui.viewRows[1].profitCopper >= (ui.viewRows[2].profitCopper or -math.huge),
  "My crafts Profit / craft header should sort by calculated profit")
ui.search:SetText("low supply ore")
ui.search.scripts.OnTextChanged(ui.search)
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(#ui.viewRows == 1 and ui.viewRows[1].recipeID == 7001,
  "craft search should include known reagent names")
ui.search:SetText("")
ui.search.scripts.OnTextChanged(ui.search)
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
ui.rows[1].scripts.OnClick(ui.rows[1])
assert(ui.selectedItem.recipeData ~= nil, "selecting a craft should show recipe details")
assert(ui.detailEconomics:GetText():find("REAGENTS", 1, true), "craft detail should show reagent breakdown")

ui.search:SetText("")
ui.search.scripts.OnTextChanged(ui.search)
assert(ui.tabs.allcrafts and ui.tabs.opportunities == nil,
  "All Crafts replaces the overlapping Profitable tab")
ui.tabs.allcrafts.scripts.OnClick(ui.tabs.allcrafts)
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(#ui.viewRows >= 2, "All Crafts should retain known recipes independent of profit sign")

ui.search:SetText("")
ui.search.scripts.OnTextChanged(ui.search)
ui.tabs.low.scripts.OnClick(ui.tabs.low)
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
local hasLowSupplyOre = false
for _, item in ipairs(ui.viewRows) do
  if item.itemID == 200 then hasLowSupplyOre = true end
end
assert(#ui.viewRows >= 2 and hasLowSupplyOre,
  "role-adjusted Low Supply should include scarce materials and other low-quantity items")

local scenario = ui.GetProfitScenario(copper, 2000, 2, 5, 5000)
assert(scenario and scenario.totalProfitCopper == 5500, "custom target scenario math should include AH cut")
ui.browseButton.scripts.OnClick(ui.browseButton)
assert(not ui.frame:IsShown() and ModuloMarket.scannerOpened,
  "Browse scanner should replace rather than overlap the Market window")
-- All-items search accepts punctuation/word-order variation and item-ID tokens.
ui.tabs.market.scripts.OnClick(ui.tabs.market)
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
ui.search:SetText("ore copper")
ui.search.scripts.OnTextChanged(ui.search)
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(#ui.viewRows == 1 and ui.viewRows[1].itemID == 100,
  "search should normalize punctuation and match all query tokens regardless of order")
ui.search:SetText("100")
ui.search.scripts.OnTextChanged(ui.search)
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
assert(#ui.viewRows == 1 and ui.viewRows[1].itemID == 100, "search should match item IDs")

-- Clickable market headers sort the complete filtered catalogue, not just visible rows.
ui.search:SetText("")
ui.search.scripts.OnTextChanged(ui.search)
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
ui.headerButtons[2].scripts.OnClick(ui.headerButtons[2])
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
for i = 2, #ui.viewRows do
  assert((ui.viewRows[i - 1].minPriceCopper or math.huge) <= (ui.viewRows[i].minPriceCopper or math.huge),
    "Cheapest header should sort all items ascending")
end
ui.headerButtons[2].scripts.OnClick(ui.headerButtons[2])
while ui.viewBuild or ui.rankSort do ui.frame.scripts.OnUpdate(ui.frame, 0.016) end
for i = 2, #ui.viewRows do
  assert((ui.viewRows[i - 1].minPriceCopper or -math.huge) >= (ui.viewRows[i].minPriceCopper or -math.huge),
    "second Cheapest click should reverse the full-catalogue sort")
end
assert(ui.frame.backdropColor and ui.frame.backdropColor[4] < 1,
  "Market backdrop should use partial transparency")
assert(ui.opacitySlider and ui.opacitySlider.minValue == 0.15 and ui.opacitySlider.maxValue == 0.85,
  "Market should expose a bounded background-opacity slider")
ui.opacitySlider.scripts.OnValueChanged(ui.opacitySlider, 0.25)
assert(math.abs(ui.frame.backdropColor[4] - 0.25) < 0.001
    and math.abs(ui.frame.Bg.alpha - 0.25) < 0.001
    and math.abs(ui.frame.InsetBg.alpha - 0.25) < 0.001
    and math.abs(ModuloMarket.db.backgroundOpacity - 0.25) < 0.001,
  "opacity slider should update both actual BasicFrameTemplate background textures and persist the value")
assert(ui.opacityValue:GetText() == "25%", "opacity slider should display its current percentage")
ui.headerButtons[2].scripts.OnClick(ui.headerButtons[2])
assert(ui.headerButtons[2].sortIndicator.shown and ui.headerButtons[2].sortIndicator.texture,
  "sort direction should use a visible texture arrow rather than an unsupported font glyph")
assert(ui.AttachMinimapButton() and ui.minimapButton,
  "Market should create a minimap launcher")
ui.minimapButton.scripts.OnClick(ui.minimapButton, "LeftButton")
assert(ui.frame:IsShown(), "left-clicking the minimap button should open Market")
ui.minimapButton.scripts.OnDragStart(ui.minimapButton)
ui.minimapButton.scripts.OnUpdate(ui.minimapButton)
ui.minimapButton.scripts.OnDragStop(ui.minimapButton)
assert(type(ModuloMarket.db.minimapAngle) == "number", "dragging the minimap button should persist its position")
print("Modulo Market 0.4.2 responsive rows + click-driven menus + visible opacity + minimap harness PASS (" .. frames .. " frames)")
