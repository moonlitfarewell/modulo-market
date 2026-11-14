local modernPath = arg[1]
local function Region(kind)
    local o = { kind = kind, shown = true, text = "", scripts = {}, height = 20, width = 100 }
    function o:SetPoint(...) end
    function o:ClearAllPoints() end
    function o:SetSize(w, h) self.width, self.height = w, h end
    function o:SetWidth(w) self.width = w end
    function o:SetHeight(h) self.height = h end
    function o:GetHeight() return self.height end
    function o:GetWidth() return self.width end
    function o:SetColorTexture(...) self.color = {...} end
    function o:SetTexture(value) self.texture = value end
    function o:GetTexture() return self.texture end
    function o:SetAllPoints() end
    function o:SetText(value) self.text = tostring(value or "") end
    function o:GetText() return self.text end
    function o:SetTextColor(...) self.textColor = {...} end
    function o:SetJustifyH() end
    function o:SetJustifyV() end
    function o:SetWordWrap() end
    function o:SetTextInsets() end
    function o:SetAutoFocus() end
    function o:SetMaxLetters() end
    function o:SetMinMaxValues() end
    function o:SetValueStep() end
    function o:SetObeyStepOnDrag() end
    function o:SetValue(v) self.value = v end
    function o:GetVerticalScroll() return self.verticalScroll or 0 end
    function o:SetVerticalScroll(v) self.verticalScroll = v end
    function o:EnableMouseWheel() end
    function o:SetScrollChild(child) self.scrollChild = child end
    function o:SetFrameStrata() end
    function o:SetFrameLevel() end
    function o:SetToplevel() end
    function o:SetClampedToScreen() end
    function o:SetMovable() end
    function o:EnableMouse() end
    function o:RegisterForDrag() end
    function o:SetScale(v) self.scale = v end
    function o:SetAlpha(v) self.alpha = v end
    function o:GetAlpha() return self.alpha or 1 end
    function o:SetScript(name, fn) self.scripts[name] = fn end
    function o:GetScript(name) return self.scripts[name] end
    function o:HookScript(name, fn) self.scripts[name] = fn end
    function o:Show()
        local was = self.shown; self.shown = true
        if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function o:Hide()
        local was = self.shown; self.shown = false
        if was and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function o:IsShown() return self.shown end
    function o:Disable() self.enabled = false end
    function o:Enable() self.enabled = true end
    function o:IsEnabled() return self.enabled ~= false end
    function o:ClearFocus() end
    function o:StartMoving() end
    function o:StopMovingOrSizing() end
    function o:Raise() end
    function o:CreateTexture() return Region("Texture") end
    function o:CreateFontString() return Region("FontString") end
    function o:SetChecked(v) self.checked = v end
    function o:GetChecked() return self.checked end
    return o
end
_G.CreateFrame = function() return Region("Frame") end
_G.UIParent = Region("UIParent")
_G.UISpecialFrames = {}
_G.GetScreenWidth = function() return 1920 end
_G.GetScreenHeight = function() return 1080 end
_G.GameTooltip = { SetOwner=function() end, SetText=function() end, Show=function() end, Hide=function() end }
local item = { itemID = 123, name = "Test item", minPriceCopper = 1200, minPriceQuantity = 4, totalQuantity = 12 }
local state = {
    tab = "market", rows = { item }, selected = nil, viewRevision = 1,
    metadata = "Full Market data", scanState = "Scan: Idle", resultCount = 1,
    professionOptions = {{text="All professions",value=0}}, professionFilter = 0,
    roleFilter = "all", itemTypeFilter = "all",
    marketQuickFilters = {craftingMaterialsOnly=false,highProfitOnly=false,reviewOnly=false},
    craftFilters = {craftableOnly=false,profitableOnly=false,reviewOnly=false,hideLowProfit=false},
    economicsFilters = {crafted=false,gathered=false,material=false,other=false},
    turnInTierFilter = "all", turnInCategoryFilter = "all", economicsByItemID = {},
}
local selected, sortKey, searchText, prepared, scanTriggered, browseTriggered
_G.ModuloMarket = {
    version = "0.11.1", db = { backgroundOpacity = 0.85 },
    Theme = { GetModernColor = function(_, role)
        if role == "accent" or role == "borderStrong" or role == "selectedEdge" then return {1,0.19,0.31,1} end
        return {0.04,0.05,0.07,1}
    end },
    MarketUI = {
        PrepareModernBackend = function() prepared = (prepared or 0) + 1 end,
        GetModernState = function() return state end,
        GetModernDetails = function() return {
            name="Test item", badges="MARKET ITEM", icon="test-icon", marketHeading="Market Information",
            priceLabel="PRICE",price="12s",supplyLabel="TOTAL LISTED",supply="12 units",
            atPriceLabel="AT PRICE",atPrice="4",profitLabel="BEST CRAFT",profit="—",
            relationshipHeading="Relationships",relationshipText="No known recipes",
            historyHeading="Market History",historyText="No saved history",bundleLines={},historyBars={},
        } end,
        GetModernItemName = function(value) return value.name end,
        GetModernIcon = function() return "test-icon" end,
        GetModernCraftMarker = function() return 0.25, 0.88, 0.42, 1 end,
        FormatMoney = function(value) return tostring(value) .. "c" end,
        SetTab = function(value) state.tab = value; state.viewRevision = state.viewRevision + 1 end,
        SetSearch = function(value) searchText = value end,
        SetProfessionFilter = function(value) state.professionFilter = value end,
        SetRoleFilter = function(value) state.roleFilter = value end,
        SetItemTypeFilter = function(value) state.itemTypeFilter = value end,
        SetMarketQuickFilter = function(key, value) state.marketQuickFilters[key] = value end,
        SetCraftFilter = function(key, value) state.craftFilters[key] = value end,
        SetEconomicsFilter = function(key, value) state.economicsFilters[key] = value end,
        SetTurnInFilters = function(tier, category) state.turnInTierFilter=tier; state.turnInCategoryFilter=category end,
        SelectItem = function(value) selected = value; state.selected = value end,
        SortBy = function(key) sortKey = key end,
        TriggerFullScan = function() scanTriggered = true end,
        TriggerBrowseScan = function() browseTriggered = true end,
        scanButton = { IsEnabled = function() return true end },
    },
}
assert(loadfile(modernPath))()
local M = ModuloMarket.ModernUI
assert(M and type(M.Show) == "function")
M.Show()
assert(M.frame and M.frame:IsShown())
assert((prepared or 0) >= 1)
assert(M.tabs.market and M.tabs.economics and M.tabs.crafts and M.tabs.materials and M.tabs.turnins and M.tabs.history)
assert(M.rows[1].item == item)
assert(M.rows[1].statusMarker and M.rows[1].statusMarker.shown)
assert(M.rows[1].statusMarker.color[1] == 0.25 and M.rows[1].statusMarker.color[2] == 0.88)
assert(M.updateButton.iconTexture and M.updateButton.iconTexture.texture == "Interface\\Buttons\\UI-RefreshButton")
assert(M.browseButton.iconTexture and M.browseButton.iconTexture.texture == "Interface\\Common\\UI-Searchbox-Icon")
assert(M.filterHint == nil)
assert(M.scroll:GetScript("OnMouseWheel") ~= nil)
M.scroll:GetScript("OnMouseWheel")(M.scroll, -1)
M.tabs.crafts:GetScript("OnClick")(M.tabs.crafts)
assert(state.tab == "crafts")
assert(not M.rows[1].statusMarker.shown)
M.rows[1]:GetScript("OnClick")(M.rows[1])
assert(selected == item)
state.tab = "market"; M.RenderRows()
assert(M.rows[1].statusMarker.shown)
M.headers[2]:GetScript("OnClick")(M.headers[2])
assert(sortKey == "price")
M.search:SetText("mud snapper")
M.search:GetScript("OnEnterPressed")(M.search)
assert(searchText == "mud snapper")
M.updateButton:GetScript("OnClick")(M.updateButton)
M.browseButton:GetScript("OnClick")(M.browseButton)
assert(scanTriggered and browseTriggered)
local crate = { turnIn=true, cratePriceCopper=655, bundleAlternatives={
    {index=1,complete=true,costCopper=360,lines={{quantity=10,itemName="Bolt of Mageweave",unitPriceCopper=30,lineCostCopper=300}}},
    {index=2,complete=false,lines={{quantity=5,itemName="Runecloth",unitPriceCopper=nil,lineCostCopper=nil,reason="No current auction listing"}}},
}, bestBundle={index=1,costCopper=360} }
state.tab = "turnins"; state.selected = crate
M.RefreshInspector()
assert(M.relationshipTitle.text == "REQUIRED BUNDLES")
assert(M.bundleScroll.shown and M.bundleChild.height > 1)
local bundleText = {}
for _, line in ipairs(M.bundleLines) do if line.shown then bundleText[#bundleText+1] = line.text end end
local joined = table.concat(bundleText, "\n")
assert(joined:find("CRATE PURCHASE", 1, true))
assert(joined:find("BEST VALUE", 1, true))
assert(joined:find("Bolt of Mageweave", 1, true))
assert(joined:find("No current auction listing", 1, true))
state.tab = "market"; M.RefreshInspector()
assert(not M.bundleScroll.shown and M.relationshipText.shown)
M.Hide()
assert(not M.frame:IsShown())
print("modern UI visual regression harness: 24 checks passed")
