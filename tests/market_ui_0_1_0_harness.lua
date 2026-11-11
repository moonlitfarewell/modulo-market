local function object(isRegion)
  local o = { scripts = {}, registered = {}, shown = false, text = "" }
  function o:SetScript(name, callback) self.scripts[name] = callback end
  function o:RegisterEvent(name) self.registered[name] = true end
  function o:UnregisterEvent(name) self.registered[name] = nil end
  function o:SetSize() end function o:SetPoint() end function o:SetMovable() end
  function o:EnableMouse() end function o:RegisterForDrag() end
  function o:SetAutoFocus() end function o:SetMaxLetters() end function o:SetNumeric() end
  function o:SetFontObject() end function o:SetTextInsets() end
  function o:SetMultiLine() end function o:SetCursorPosition() end
  function o:HighlightText() end function o:SetFocus() end function o:ClearFocus() end
  function o:SetWidth() end function o:SetHeight() end
  function o:SetJustifyH() end function o:SetJustifyV() end function o:SetWordWrap() end
  function o:SetColorTexture() end function o:SetScrollChild() end
  function o:SetHighlightTexture() end function o:SetEnabled(value) self.enabled = value end
  function o:SetText(value) self.text = value end
  function o:GetText() return self.text end
  function o:Show() self.shown = true end function o:Hide() self.shown = false end
  function o:IsShown() return self.shown end
  function o:SetVerticalScroll(value)
    self.scroll = value
    if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self, value) end
  end
  function o:CreateFontString() return object(true) end
  function o:CreateTexture() return object(true) end
  if not isRegion then o.TitleText = object(true) end
  return o
end
function CreateFrame() return object() end
UIParent = {}
C_Item = {
  GetItemNameByID = function(itemID) return itemID == 100 and "Copper Ore" or "Silver Ore" end,
  RequestLoadItemDataByID = function() end,
}
local replicateState = { active = false, pendingConfirmation = false, cooldownRemaining = 41 }
ModuloMarket = {
  db = {
    lastMarketSnapshot = {
      complete = true, timestamp = 1794311000, timestampText = "2026-11-10 18:00:00",
      source = "C_AuctionHouse.ReplicateItems", resultCount = 2, auctionCount = 4,
      rows = {
        { key = "100:15:0::", itemID = 100, itemName = "Copper Ore", itemLevel = 15,
          itemSuffix = 0, minPriceCopper = 4000, minPriceQuantity = 1,
          totalQuantity = 3, auctionCount = 2 },
        { key = "200:15:0::", itemID = 200, itemName = "Silver Ore", itemLevel = 15,
          itemSuffix = 0, minPriceCopper = 7000, minPriceQuantity = 2,
          totalQuantity = 8, auctionCount = 2 },
      },
    },
  },
  Scanner = { ItemKeyIdentity = function(key) return tostring(key.itemID) .. ":" .. tostring(key.itemLevel) .. ":" .. tostring(key.itemSuffix) .. "::" end },
  Replicate = { GetState = function() return replicateState end },
}
dofile(arg[1])
local ui = ModuloMarket.MarketUI
ui.Toggle()
assert(ui.frame and ui.frame:IsShown(), "main Market UI should open")
assert(ui.metadata:GetText():find("Last successful Replicate snapshot", 1, true), "metadata should identify the last successful Replicate snapshot")
assert(ui.scanButton:GetText() == "Scan in 41s" and ui.scanButton.enabled == false,
  "button should mirror the Market-local cooldown countdown")
replicateState.cooldownRemaining = 0
ui.RefreshActions()
assert(ui.scanButton:GetText() == "Update Market (Bulk)" and ui.scanButton.enabled == true,
  "button should become locally available when Market's own timer expires")
assert(ui.resultCount:GetText() == "2 matching variants", "snapshot rows should populate search list")
assert(ui.rows[1].shown, "first result row should be visible")
assert(ui.rows[1].label:GetText() == "Copper Ore", "result should show item name")
ui.rows[1].scripts.OnClick(ui.rows[1])
assert(ui.selectedRow.itemID == 100, "selecting a row should open item detail")
assert(ui.lowestText:GetText() == "40s 00c", "item detail should format the current lowest price")
ui.costInput:SetText("0.30")
ui.costInput.scripts.OnTextChanged(ui.costInput)
ui.quantityInput:SetText("2")
ui.quantityInput.scripts.OnTextChanged(ui.quantityInput)
assert(ui.profitText:GetText():find("16s 00c", 1, true), "profit estimator should show total estimated profit")
assert(ui.breakEvenText:GetText():find("31s 58c", 1, true), "break-even should include the AH cut")
ui.costInput.scripts.OnEditFocusLost(ui.costInput)
assert(ModuloMarket.db.costBasisByItemKey["100:15:0::"] == 3000, "cost basis should persist per item variant")
ui.search:SetText("Silver")
ui.search.scripts.OnTextChanged(ui.search)
assert(ui.resultCount:GetText() == "1 matching variants", "name search should filter variants")
assert(ui.rows[1].label:GetText() == "Silver Ore", "filtered row should render")
print("Modulo Market 0.1.0 Market UI model harness PASS")
