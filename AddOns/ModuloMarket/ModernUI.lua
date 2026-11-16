local MM = _G.ModuloMarket
if not MM then return end
local UI = MM.MarketUI
if not UI then return end

local Modern = { frame = nil, rows = {}, tabs = {}, elapsed = 0, renderedCount = -1, renderedTab = nil }
local themedTextures = setmetatable({}, { __mode = "k" })
local themedFonts = setmetatable({}, { __mode = "k" })
MM.ModernUI = Modern

local TAB_SPECS = {
    { key = "market", label = "ALL ITEMS" },
    { key = "economics", label = "ECONOMICS" },
    { key = "crafts", label = "CRAFTS" },
    { key = "materials", label = "MATERIALS" },
    { key = "turnins", label = "TURN-INS" },
    { key = "history", label = "HISTORY" },
}

local function C(role, fallback)
    return MM.Theme and MM.Theme.GetModernColor and MM.Theme.GetModernColor(role, fallback)
        or fallback or { 0.04, 0.05, 0.07, 1 }
end

local function Paint(texture, role, fallback)
    if not texture then return end
    themedTextures[texture] = { role = role, fallback = fallback }
    local color = C(role, fallback)
    texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

local function Border(parent, role)
    local lines = {}
    for i = 1, 4 do
        lines[i] = parent:CreateTexture(nil, "BORDER")
        Paint(lines[i], role or "border", { 0.30, 0.34, 0.42, 0.9 })
    end
    lines[1]:SetPoint("TOPLEFT"); lines[1]:SetPoint("TOPRIGHT"); lines[1]:SetHeight(1)
    lines[2]:SetPoint("BOTTOMLEFT"); lines[2]:SetPoint("BOTTOMRIGHT"); lines[2]:SetHeight(1)
    lines[3]:SetPoint("TOPLEFT"); lines[3]:SetPoint("BOTTOMLEFT"); lines[3]:SetWidth(1)
    lines[4]:SetPoint("TOPRIGHT"); lines[4]:SetPoint("BOTTOMRIGHT"); lines[4]:SetWidth(1)
    return lines
end

local function Label(parent, text, x, y, width, height, template, colorRole)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then fs:SetWidth(width) end
    if height then fs:SetHeight(height) end
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    if fs.SetWordWrap then fs:SetWordWrap(true) end
    fs:SetText(text or "")
    local role = colorRole or "textPrimary"
    themedFonts[fs] = role
    local color = C(role)
    fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    return fs
end

local function Panel(parent, title, x, y, width, height)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    panel:SetSize(width, height)
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); Paint(bg, "surface", { 0.025, 0.03, 0.043, 0.98 })
    Border(panel, "border")
    local head = panel:CreateTexture(nil, "ARTWORK")
    head:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1)
    head:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -1)
    head:SetHeight(34); Paint(head, "panelHeader")
    local titleText = Label(panel, title, 14, -9, width - 28, 24, "GameFontNormalLarge", "textPrimary")
    panel.titleText = titleText
    local rule = panel:CreateTexture(nil, "ARTWORK")
    rule:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -35)
    rule:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -35)
    rule:SetHeight(1); Paint(rule, "borderStrong")
    return panel, titleText
end

local function FlatButton(parent, text, width, height, callback)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height or 30)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); Paint(bg, "control")
    local border = button:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT"); border:SetPoint("BOTTOMRIGHT"); Paint(border, "border")
    local label = Label(button, text, 8, -7, width - 16, (height or 30) - 8, "GameFontHighlight")
    label:SetJustifyH("CENTER")
    button.label, button.background, button.border = label, bg, border
    button:SetScript("OnEnter", function() Paint(bg, "controlHighlight") end)
    button:SetScript("OnLeave", function() Paint(bg, "control") end)
    button:SetScript("OnClick", callback)
    return button
end

local function AddButtonIcon(button, texturePath, size, side)
    if not button or not texturePath then return nil end
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(texturePath)
    icon:SetSize(size or 16, size or 16)
    if side == "RIGHT" then
        icon:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    else
        icon:SetPoint("LEFT", button, "LEFT", 8, 0)
        if button.label then
            button.label:ClearAllPoints()
            button.label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            button.label:SetPoint("RIGHT", button, "RIGHT", -8, 0)
            button.label:SetJustifyH("LEFT")
        end
    end
    button.iconTexture = icon
    return icon
end

local function SetTextColor(fs, role)
    if not fs then return end
    local color = C(role)
    fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function AddSpecialFrame(name)
    _G.UISpecialFrames = _G.UISpecialFrames or {}
    for _, value in ipairs(_G.UISpecialFrames) do if value == name then return end end
    _G.UISpecialFrames[#_G.UISpecialFrames + 1] = name
end

local function CreateDropdown(parent, labelText, y, width, optionsProvider, getter, setter)
    local sectionLabel = Label(parent, labelText, 16, y, width - 32, 18, "GameFontNormal", "textAccent")
    local button = FlatButton(parent, "", width - 32, 28, nil)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y - 22)
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetFrameLevel(400)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); Paint(bg, "surfaceRaised")
    Border(popup, "borderStrong")
    local function Refresh()
        local selected = getter()
        local options = optionsProvider() or {}
        local display = options[1] and tostring(options[1].text) or (labelText == "PROFESSION" and "All professions" or "All")
        for _, option in ipairs(options) do
            if tostring(option.value) == tostring(selected) then
                display = tostring(option.text)
                break
            end
        end
        button.label:SetText(display)
    end
    local function Rebuild()
        for _, child in ipairs(popup.buttons or {}) do child:Hide() end
        popup.buttons = {}
        local options = optionsProvider() or {}
        popup:SetSize(width - 32, math.max(30, #options * 26 + 8))
        for i, option in ipairs(options) do
            local item = FlatButton(popup, option.text, width - 40, 24, function()
                setter(option.value); popup:Hide(); Refresh()
            end)
            item:SetPoint("TOPLEFT", popup, "TOPLEFT", 4, -4 - ((i - 1) * 26))
            if option.disabled then item:Disable() end
            popup.buttons[#popup.buttons + 1] = item
        end
    end
    button:SetScript("OnClick", function()
        if popup:IsShown() then popup:Hide() else
            Rebuild(); popup:ClearAllPoints(); popup:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -3); popup:Show()
        end
    end)
    AddButtonIcon(button, "Interface\\AddOns\\ModuloMarket\\Textures\\chevron-down.tga", 14, "RIGHT")
    Refresh()
    button.Refresh = Refresh
    button.sectionLabel = sectionLabel
    return button
end

local function MakeCheck(parent, text, x, y, key, getter, setter)
    local check = CreateFrame("Button", nil, parent)
    check:SetSize(270, 24)
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    check.box = check:CreateTexture(nil, "ARTWORK")
    check.box:SetPoint("LEFT", check, "LEFT", 0, 0)
    check.box:SetSize(17, 17)
    Paint(check.box, "control")
    check.outline = {}
    for i = 1, 4 do
        check.outline[i] = check:CreateTexture(nil, "OVERLAY")
        Paint(check.outline[i], "borderStrong", {0.62, 0.68, 0.78, 1})
    end
    check.outline[1]:SetPoint("TOPLEFT", check.box, "TOPLEFT"); check.outline[1]:SetPoint("TOPRIGHT", check.box, "TOPRIGHT"); check.outline[1]:SetHeight(1)
    check.outline[2]:SetPoint("BOTTOMLEFT", check.box, "BOTTOMLEFT"); check.outline[2]:SetPoint("BOTTOMRIGHT", check.box, "BOTTOMRIGHT"); check.outline[2]:SetHeight(1)
    check.outline[3]:SetPoint("TOPLEFT", check.box, "TOPLEFT"); check.outline[3]:SetPoint("BOTTOMLEFT", check.box, "BOTTOMLEFT"); check.outline[3]:SetWidth(1)
    check.outline[4]:SetPoint("TOPRIGHT", check.box, "TOPRIGHT"); check.outline[4]:SetPoint("BOTTOMRIGHT", check.box, "BOTTOMRIGHT"); check.outline[4]:SetWidth(1)
    check.mark = check:CreateTexture(nil, "OVERLAY")
    check.mark:SetPoint("TOPLEFT", check.box, "TOPLEFT", 3, -3)
    check.mark:SetPoint("BOTTOMRIGHT", check.box, "BOTTOMRIGHT", -3, 3)
    check.mark:SetTexture("Interface\\AddOns\\ModuloMarket\\Textures\\check.tga")
    check.mark:SetVertexColor(1, 1, 1, 1)
    check.label = Label(check, text, 26, -3, 238, 20, "GameFontHighlightSmall", "textPrimary")
    check.key = key
    check.getter = getter
    check.setter = setter
    function check:Refresh()
        self.checked = self.getter() == true
        if self.checked then
            Paint(self.box, "controlHighlight")
            for _, edge in ipairs(self.outline) do Paint(edge, "accent") end
            local accent = C("accent")
            self.mark:SetVertexColor(accent[1], accent[2], accent[3], 1)
            self.mark:Show()
        else
            Paint(self.box, "control")
            for _, edge in ipairs(self.outline) do Paint(edge, "borderStrong", {0.62, 0.68, 0.78, 1}) end
            self.mark:Hide()
        end
    end
    check:SetScript("OnClick", function(self)
        local nextValue = self.getter() ~= true
        self.setter(self.key, nextValue)
        self:Refresh()
    end)
    check:SetScript("OnEnter", function(self)
        Paint(self.box, "controlHighlight")
        for _, edge in ipairs(self.outline) do Paint(edge, "accent") end
    end)
    check:SetScript("OnLeave", function(self) self:Refresh() end)
    check:Refresh()
    return check
end

local function GetItemName(item)
    return UI.GetModernItemName and UI.GetModernItemName(item) or tostring(item and item.name or "Unknown item")
end

local function GetRowCells(item, state)
    local tab = state.tab
    local name = GetItemName(item)
    local price, middle, quantity, profit = "—", "—", "—", "—"
    if tab == "turnins" and item.turnIn then
        price = item.completionCostCopper and UI.FormatMoney(item.completionCostCopper) or "Incomplete"
        middle = item.cashReturnCopper ~= nil and UI.FormatMoney(item.cashReturnCopper)
            or (item.cashReturnText or "Unknown")
        quantity = item.rewardFavor ~= nil and (tostring(item.rewardFavor) .. " Fav")
            or (item.reputation ~= nil and (tostring(item.reputation) .. " Rep") or "?")
        local netCost = item.netCostPerRewardCopper or item.netCostPerFavorCopper or item.netCostPerReputationCopper
        profit = netCost ~= nil and UI.FormatMoney(netCost) or "—"
    elseif tab == "crafts" then
        price = item.salePriceCopper and UI.FormatMoney(item.salePriceCopper) or "—"
        middle = item.materialCostCopper and UI.FormatMoney(item.materialCostCopper) or "—"
        quantity = item.minPriceQuantity ~= nil and tostring(item.minPriceQuantity) or "—"
        profit = item.profitCopper ~= nil and UI.FormatMoney(item.profitCopper) or "—"
    elseif tab == "economics" then
        local economics = item.economics
        price = item.minPriceCopper and UI.FormatMoney(item.minPriceCopper) or "No buyout"
        middle = economics and economics.materialCostCopper and UI.FormatMoney(economics.materialCostCopper) or "—"
        quantity = item.historyDeltaCopper ~= nil and UI.FormatMoney(item.historyDeltaCopper) or "—"
        profit = item.totalQuantity ~= nil and tostring(item.totalQuantity) or "—"
    else
        price = item.minPriceCopper and UI.FormatMoney(item.minPriceCopper) or "No buyout"
        middle = item.minPriceQuantity ~= nil and tostring(item.minPriceQuantity) or "—"
        quantity = item.totalQuantity ~= nil and tostring(item.totalQuantity) or "—"
        local best = state.economicsByItemID and state.economicsByItemID[tonumber(item.itemID)]
        if best and best.profitCopper ~= nil then profit = UI.FormatMoney(best.profitCopper) end
        if tab == "history" and item.historyDeltaCopper ~= nil then
            middle = (item.historyDeltaCopper > 0 and "+" or "") .. UI.FormatMoney(item.historyDeltaCopper)
        end
        if tab == "market" then profit = "" end
    end
    return name, price, middle, quantity, profit
end

local function RefreshRowText(row, item, index, state)
    if not item then row:Hide(); row.item = nil; return end
    row.item = item
    if row.icon and UI.GetModernIcon then row.icon:SetTexture(UI.GetModernIcon(item)); row.icon:Show() end
    if row.statusMarker and UI.GetRowCraftMarker then
        local r, g, b, a = UI.GetRowCraftMarker(item)
        row.statusMarker:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
        row.statusMarker:Show()
    elseif row.statusMarker then row.statusMarker:Hide() end
    row:SetPoint("TOPLEFT", Modern.scrollChild, "TOPLEFT", 0, -((index - 1) * 27))
    local name, price, middle, quantity, profit = GetRowCells(item, state)
    row.name:SetText(UI.GetItemDisplayName and UI.GetItemDisplayName(item) or name)
    row.price:SetText(price)
    row.middle:SetText(middle)
    row.quantity:SetText(quantity)
    row.profit:SetText(profit)
    local selected = state.selected and ((state.tab == "crafts" and state.selected.recipeKey == item.recipeKey)
        or (state.tab ~= "crafts" and tonumber(state.selected.itemID) == tonumber(item.itemID)))
    Paint(row.shade, selected and "selected" or (index % 2 == 0 and "surfaceRaised" or "surfaceAlt"))
    if selected then Paint(row.edge, "selectedEdge"); row.edge:Show() else row.edge:Hide() end
    row:Show()
end

local UpdateFilterVisibility

function Modern.RenderRows()
    if not Modern.frame or not Modern.scrollChild then return end
    local state = UI.GetModernState()
    if Modern.professionDropdown and Modern.professionDropdown.Refresh then Modern.professionDropdown.Refresh() end
    local rows = state.rows or {}
    local offset = Modern.scroll and Modern.scroll.GetVerticalScroll and Modern.scroll:GetVerticalScroll() or 0
    local first = math.floor(offset / 27) + 1
    Modern.scrollChild:SetHeight(math.max(1, #rows * 27))
    for i, row in ipairs(Modern.rows) do
        local index = first + i - 1
        RefreshRowText(row, rows[index], index, state)
    end
    if Modern.resultCount then
        local last = math.min(#rows, first + #Modern.rows - 1)
        Modern.resultCount:SetText(string.format("%d–%d / %d", #rows > 0 and first or 0, last, #rows))
    end
    Modern.renderedCount = #rows
    Modern.renderedTab = state.tab
    Modern.renderedRevision = state.viewRevision
    Modern.RefreshHeaders(state.tab)
    Modern.UpdateColumnLayout(state)
    Modern.RefreshInspector()
    Modern.RefreshTabs(state.tab)
    UpdateFilterVisibility(state.tab)
    if Modern.turnInCategoryDropdown and Modern.turnInCategoryDropdown.Refresh then
        Modern.turnInCategoryDropdown.Refresh()
        if Modern.turnInCategoryDropdown.sectionLabel then
            local mode = state.turnInTypeFilter or "all"
            Modern.turnInCategoryDropdown.sectionLabel:SetText(mode == "writ" and "PROFESSION"
                or (mode == "crate" and "CATEGORY" or "CATEGORY / PROFESSION"))
        end
    end
    for _, group in ipairs({ Modern.quickChecks or {}, Modern.craftChecks or {}, Modern.economicsChecks or {} }) do
        for _, check in ipairs(group) do if check.Refresh then check:Refresh() end end
    end
end

local function AddInspectorValue(parent, label, value, x, y, width)
    Label(parent, label, x, y, 100, 18, "GameFontNormalSmall", "textAccent")
    local valueText = Label(parent, value or "—", x + 108, y, width - 108, 34, "GameFontHighlight")
    return valueText
end

function Modern.RefreshInspector()
    if not Modern.frame or not Modern.inspector then return end
    local d = UI.GetModernDetails()
    local state = UI.GetModernState()
    Modern.itemTitle:SetText(d.name ~= "" and d.name or "Select an item")
    Modern.itemBadge:SetText(d.badges or "")
    if d.icon and Modern.itemIcon then Modern.itemIcon:SetTexture(d.icon); Modern.itemIcon:Show()
    else Modern.itemIcon:Hide() end
    Modern.marketCardTitle:SetText(d.marketHeading ~= "" and string.upper(d.marketHeading) or "MARKET INFORMATION")
    Modern.valuePrice:SetText(d.price or "—")
    Modern.valueSupply:SetText(d.supply or "—")
    Modern.valueAtPrice:SetText(d.atPrice or "—")
    Modern.valueProfit:SetText(d.profit or "—")
    Modern.labelPrice:SetText(d.priceLabel or "PRICE")
    Modern.labelSupply:SetText(d.supplyLabel or "TOTAL LISTED")
    Modern.labelAtPrice:SetText(d.atPriceLabel or "AT PRICE")
    Modern.labelProfit:SetText(d.profitLabel or "BEST CRAFT PROFIT")
    if state.tab == "turnins" then
        Modern.relationshipTitle:SetText(state.selected and state.selected.turnInType == "writ"
            and "REQUIRED ITEM / CRAFT OPTIONS" or "REQUIRED BUNDLES")
        Modern.relationshipText:Hide()
        Modern.RenderBundleBreakdown(state.selected)
        Modern.bundleScroll:Show()
    else
        Modern.relationshipTitle:SetText(string.upper(d.relationshipHeading or "RELATIONSHIPS"))
        Modern.bundleScroll:Hide()
        Modern.relationshipText:SetText(d.relationshipText or "No additional relationship details.")
        Modern.relationshipText:Show()
    end
    Modern.historyTitle:SetText(string.upper(d.historyHeading or "MARKET HISTORY"))
    Modern.historyText:SetText(d.historyText or "")
    Modern.historyText:SetHeight(48)
    for i, bar in ipairs(Modern.historyBars) do
        local source = d.historyBars and d.historyBars[i]
        local label = Modern.historyBarLabels[i]
        if source then
            local height = math.max(4, math.min(18, (tonumber(source.height) or 4) * 0.22))
            bar:ClearAllPoints()
            bar:SetPoint("BOTTOMLEFT", Modern.historyCard, "BOTTOMLEFT", 18 + (i - 1) * 66, 9)
            bar:SetSize(42, height)
            Paint(bar, "historyBar")
            bar:Show()
            label:SetText(source.label or "")
            label:ClearAllPoints()
            label:SetPoint("BOTTOM", bar, "TOP", 0, 2)
            label:SetHeight(10)
            label:Show()
        else
            bar:Hide(); label:Hide()
        end
    end
end

local HEADER_MAP = {
    market = { {"ITEM","name"},{"CHEAPEST","price"},{"AT PRICE","depth"},{"TOTAL UNITS","total"},{"",""} },
    economics = { {"ITEM","name"},{"CHEAPEST","price"},{"CRAFT COST","materials"},{"PRICE CHANGE","change"},{"TOTAL UNITS","total"} },
    crafts = { {"RECIPE","name"},{"SALE / UNIT","price"},{"MATERIAL COST","materials"},{"AT PRICE","depth"},{"PROFIT / CRAFT","profit"} },
    materials = { {"ITEM","name"},{"CHEAPEST","price"},{"AT PRICE","depth"},{"TOTAL UNITS","total"},{"BEST CRAFT PROFIT","profit"} },
    turnins = { {"TURN-IN ITEM","name"},{"COST","completion"},{"GROSS","price"},{"REP / FAV","reward"},{"NET / REWARD","net"} },
    history = { {"ITEM","name"},{"CHEAPEST","price"},{"PRICE CHANGE","change"},{"LATEST UNITS","total"},{"BEST CRAFT PROFIT","profit"} },
}

function Modern.RefreshHeaders(tab)
    local specs = HEADER_MAP[tab] or HEADER_MAP.market
    if tab == "turnins" then
        specs = {
            { "TURN-IN ITEM", "name" },
            { "COST", "completion" },
            { "GROSS", "price" },
            { "REP / FAV", "reward" },
            { "NET / REWARD", "net" },
        }
    end
    for i, header in ipairs(Modern.headers or {}) do
        local spec = specs[i] or {"", ""}
        header.label:SetText(spec[1])
        header.sortKey = spec[2]
        if spec[1] == "" then header:Hide() else header:Show() end
    end
end

function Modern.UpdateColumnLayout(state)
    if not Modern.scrollChild or not Modern.headers or not Modern.rows then return end
    state = state or UI.GetModernState()
    local rowWidth = tonumber(Modern.scrollChild:GetWidth()) or 0
    if rowWidth <= 0 then return end

    local activeFields = state.tab == "market"
        and { "price", "middle", "quantity" }
        or { "price", "middle", "quantity", "profit" }
    local fieldHeaders = { price=2, middle=3, quantity=4, profit=5 }
    local minWidths = { price=82, middle=92, quantity=82, profit=118 }
    local maxWidths = { price=176, middle=176, quantity=150, profit=190 }
    local widths = {}

    for _, field in ipairs(activeFields) do
        local header = Modern.headers[fieldHeaders[field]]
        local measured = header and header.label and header.label.GetStringWidth
            and header.label:GetStringWidth() or 0
        widths[field] = math.max(minWidths[field], tonumber(measured) or 0)
    end
    for _, row in ipairs(Modern.rows) do
        if row:IsShown() then
            for _, field in ipairs(activeFields) do
                local cell = row[field]
                local measured = cell and cell.GetStringWidth and cell:GetStringWidth() or 0
                widths[field] = math.max(widths[field], tonumber(measured) or 0)
            end
        end
    end
    local total = 0
    for _, field in ipairs(activeFields) do
        widths[field] = math.min(maxWidths[field], widths[field] + 16)
        total = total + widths[field]
    end

    -- Keep the numeric columns anchored to the right edge; Item/Recipe gets
    -- the remaining width and stays left-aligned.
    local gap, rightPadding = 8, 8
    local availableNumeric = math.max(0, rowWidth - 46 - 90)
    if total + gap * (#activeFields - 1) > availableNumeric then
        local overflow = total + gap * (#activeFields - 1) - availableNumeric
        for i = #activeFields, 1, -1 do
            local field = activeFields[i]
            local reducible = math.max(0, widths[field] - minWidths[field])
            local reduction = math.min(reducible, overflow)
            widths[field] = widths[field] - reduction
            overflow = overflow - reduction
            if overflow <= 0 then break end
        end
    end

    local cursor = rowWidth - rightPadding
    for i = #activeFields, 1, -1 do
        local field = activeFields[i]
        local width = widths[field]
        local x = cursor - width
        local header = Modern.headers[fieldHeaders[field]]
        if header then
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", Modern.centerPanel, "TOPLEFT", 12 + x, -52)
            header:SetWidth(width)
            header.label:ClearAllPoints()
            header.label:SetPoint("LEFT", header, "LEFT", 0, -5)
            header.label:SetPoint("RIGHT", header, "RIGHT", -4, -5)
            header.label:SetJustifyH("RIGHT")
        end
        for _, row in ipairs(Modern.rows) do
            local cell = row[field]
            if cell then
                cell:ClearAllPoints()
                cell:SetPoint("LEFT", row, "LEFT", x, 0)
                cell:SetWidth(width)
                cell:SetJustifyH("RIGHT")
            end
        end
        cursor = x - gap
    end

    local nameWidth = math.max(72, cursor - 34)
    local nameHeader = Modern.headers[1]
    if nameHeader then
        nameHeader:ClearAllPoints()
        nameHeader:SetPoint("TOPLEFT", Modern.centerPanel, "TOPLEFT", 12, -52)
        nameHeader:SetWidth(nameWidth + 22)
        nameHeader.label:ClearAllPoints()
        nameHeader.label:SetPoint("LEFT", nameHeader, "LEFT", 0, -5)
        nameHeader.label:SetPoint("RIGHT", nameHeader, "RIGHT", -4, -5)
        nameHeader.label:SetJustifyH("LEFT")
    end
    for _, row in ipairs(Modern.rows) do
        row.name:ClearAllPoints()
        row.name:SetPoint("LEFT", row, "LEFT", 34, 0)
        row.name:SetWidth(nameWidth)
        row.name:SetJustifyH("LEFT")
    end
    if #activeFields == 3 then
        Modern.headers[5]:Hide()
        for _, row in ipairs(Modern.rows) do row.profit:Hide() end
    else
        Modern.headers[5]:Show()
        for _, row in ipairs(Modern.rows) do row.profit:Show() end
    end
end

function Modern.RefreshTabs(active)
    for key, button in pairs(Modern.tabs) do
        local selected = key == active
        Paint(button.background, selected and "tabActive" or "tabInactive")
        Paint(button.indicator, selected and "accent" or "surfaceRaised")
        SetTextColor(button.label, selected and "textPrimary" or "textMuted")
    end
end

UpdateFilterVisibility = function(tab)
    local function show(object, value) if object then if value then object:Show() else object:Hide() end end end
    local market = tab == "market"
    local crafts = tab == "crafts"
    local economics = tab == "economics"
    local turnins = tab == "turnins"
    show(Modern.professionDropdown, not turnins)
    show(Modern.professionDropdown and Modern.professionDropdown.sectionLabel, not turnins)
    show(Modern.roleDropdown, not turnins)
    show(Modern.roleDropdown and Modern.roleDropdown.sectionLabel, not turnins)
    show(Modern.itemTypeDropdown, market)
    show(Modern.itemTypeDropdown and Modern.itemTypeDropdown.sectionLabel, market)
    for _, check in ipairs(Modern.quickChecks or {}) do show(check, market); show(check.label, market) end
    for _, check in ipairs(Modern.craftChecks or {}) do show(check, crafts); show(check.label, crafts) end
    for _, check in ipairs(Modern.economicsChecks or {}) do show(check, economics); show(check.label, economics) end
    show(Modern.turnInTypeDropdown, turnins)
    show(Modern.turnInTypeDropdown and Modern.turnInTypeDropdown.sectionLabel, turnins)
    show(Modern.turnInTierDropdown, turnins)
    show(Modern.turnInTierDropdown and Modern.turnInTierDropdown.sectionLabel, turnins)
    show(Modern.turnInCategoryDropdown, turnins)
    show(Modern.turnInCategoryDropdown and Modern.turnInCategoryDropdown.sectionLabel, turnins)
    show(Modern.craftingScopeDropdown, not turnins)
    show(Modern.craftingScopeDropdown and Modern.craftingScopeDropdown.sectionLabel, not turnins)
end

function Modern.RenderBundleBreakdown(item)
    if not Modern.bundleScroll or not Modern.bundleChild then return end
    local cursor, used = 0, 0
    local function AddLine(text, role, height)
        used = used + 1
        local fs = Modern.bundleLines[used]
        if not fs then
            fs = Modern.bundleChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            Modern.bundleLines[used] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", Modern.bundleChild, "TOPLEFT", 4, -cursor)
        fs:SetWidth(Modern.bundleChild:GetWidth() - 8)
        fs:SetHeight(height or 16)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        fs:SetWordWrap((height or 16) > 16)
        fs:SetText(text or "")
        SetTextColor(fs, role or "textPrimary")
        fs:Show()
        cursor = cursor + (height or 16)
    end
    if not item or not item.turnIn then
        AddLine("Select a crate or writ to inspect its completion options.", "textMuted", 30)
    else
        local writ = item.turnInType == "writ"
        AddLine(writ and "WRIT PURCHASE · 1 × WRIT" or "CRATE PURCHASE · 1 × CRATE", "textAccent")
        local purchase = writ and item.writPriceCopper or item.cratePriceCopper
        AddLine(purchase and ("Price  " .. UI.FormatMoney(purchase)) or "Price unavailable", purchase and "textPrimary" or "textMuted")
        if writ then
            AddLine("CRAFT OR BUY " .. tostring(item.outputName or "REQUIRED ITEM"), "textAccent")
            local factionGroup = type(_G.UnitFactionGroup) == "function" and _G.UnitFactionGroup("player") or nil
            local factions = MM.WritData and MM.WritData.rewardFaction or {}
            local faction = factionGroup == "Horde" and factions.horde or factions.alliance
            faction = faction or "Azeroth Commerce Authority / Durotar Supply & Logistics"
            AddLine("FACTION · " .. faction, "textMuted")
            if item.handInNPC or item.handInZone then
                AddLine("GUIDE HAND-IN · " .. tostring(item.handInNPC or "NPC unknown")
                    .. (item.handInZone and (" · " .. item.handInZone) or ""), "textMuted")
            end
        else
            AddLine("MATERIAL OPTIONS · CHOOSE ONE", "textAccent")
        end
        if #(item.bundleAlternatives or {}) == 0 then
            AddLine("No matching ForeverDB recipe data or current output listing is available. Completion remains incomplete.", "textMuted", 38)
        end
        for index, alternative in ipairs(item.bundleAlternatives or {}) do
            local best = item.bestBundle and alternative.index == item.bestBundle.index
            local routeTitle = alternative.label or string.format("OPTION %d", index)
            if best then routeTitle = routeTitle .. " · BEST VALUE" end
            AddLine(routeTitle, best and "accent" or "textAccent")
            for _, reagent in ipairs(alternative.lines or {}) do
                AddLine(string.format("%d × %s", tonumber(reagent.quantity) or 0, tostring(reagent.itemName or "Unknown material")), "textPrimary", 17)
                local unit = reagent.unitPriceCopper and UI.FormatMoney(reagent.unitPriceCopper) or "unknown"
                local line = reagent.lineCostCopper and UI.FormatMoney(reagent.lineCostCopper) or "unavailable"
                AddLine("Unit " .. unit .. " / ea  ·  Line " .. line, reagent.lineCostCopper and "textMuted" or "textMuted", 16)
                if not reagent.lineCostCopper and reagent.reason then
                    AddLine("Price: " .. tostring(reagent.reason), "textMuted", 28)
                end
            end
            AddLine((writ and "Route subtotal  " or "Material subtotal  ") .. (alternative.complete and UI.FormatMoney(alternative.costCopper) or "INCOMPLETE"), "textPrimary")
            AddLine("", "textMuted", 6)
        end
    end
    for i = used + 1, #Modern.bundleLines do Modern.bundleLines[i]:Hide() end
    Modern.bundleChild:SetHeight(math.max(1, cursor + 2))
    Modern.bundleScroll:SetVerticalScroll(0)
end

local function CreateUI()
    if Modern.frame then return Modern.frame end
    local frame = CreateFrame("Frame", "ModuloMarketModernFrame", UIParent)
    Modern.frame = frame
    frame:SetSize(1520, 900)
    local savedPosition = MM.db and MM.db.windowPositions and MM.db.windowPositions.modern
    if savedPosition and tonumber(savedPosition.x) and tonumber(savedPosition.y) then
        frame:SetPoint("CENTER", UIParent, "CENTER", tonumber(savedPosition.x), tonumber(savedPosition.y))
    else
        frame:SetPoint("CENTER")
    end
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(false)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        if type(MM.db) == "table" and tonumber(x) and tonumber(y) then
            MM.db.windowPositions = MM.db.windowPositions or {}
            MM.db.windowPositions.modern = { x = x, y = y }
        end
    end)
    local sw, sh = GetScreenWidth and GetScreenWidth() or 1920, GetScreenHeight and GetScreenHeight() or 1080
    local fit = math.min(1, (sw - 36) / 1520, (sh - 36) / 900)
    frame:SetScale(math.max(0.68, fit))

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(); Paint(background, "surface", { 0.025, 0.03, 0.043, 0.99 })
    Modern.background = background
    Border(frame, "borderStrong")
    local topGlow = frame:CreateTexture(nil, "ARTWORK")
    topGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    topGlow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    topGlow:SetHeight(3); Paint(topGlow, "accent")

    local titleBar = frame:CreateTexture(nil, "ARTWORK")
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -3)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -3)
    titleBar:SetHeight(48); Paint(titleBar, "surfaceRaised")
    local title = Label(frame, "MODULO MARKET", 0, -10, 1536, 30, "GameFontNormalLarge", "textPrimary")
    title:SetJustifyH("CENTER")
    Modern.title = title
    local close = FlatButton(frame, "", 38, 34, function() Modern.Hide() end)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -8)
    AddButtonIcon(close, "Interface\\AddOns\\ModuloMarket\\Textures\\close.tga", 16, "LEFT")
    Modern.closeButton = close

    Modern.metadata = Label(frame, "Loading market data…", 28, -62, 420, 22, "GameFontHighlightSmall", "textMuted")
    Modern.scanState = Label(frame, "Scan: Idle", 470, -62, 210, 22, "GameFontHighlightSmall", "accent")
    local update = FlatButton(frame, "Scan Market", 210, 32, function() UI.TriggerFullScan() end)
    update:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -86)
    AddButtonIcon(update, "Interface\\AddOns\\ModuloMarket\\Textures\\refresh.tga", 17, "LEFT")
    Modern.updateButton = update
    local refreshSnapshot = FlatButton(frame, "Refresh", 120, 32, function()
        UI.RefreshSavedSnapshot()
    end)
    refreshSnapshot:SetPoint("TOPLEFT", frame, "TOPLEFT", 250, -86)
    AddButtonIcon(refreshSnapshot, "Interface\\AddOns\\ModuloMarket\\Textures\\refresh.tga", 16, "LEFT")
    Modern.refreshSnapshotButton = refreshSnapshot
    local cancel = FlatButton(frame, "Cancel", 92, 32, function() UI.TriggerCancelScan() end)
    cancel:SetPoint("TOPLEFT", frame, "TOPLEFT", 380, -86)
    AddButtonIcon(cancel, "Interface\\AddOns\\ModuloMarket\\Textures\\cancel.tga", 14, "LEFT")
    cancel:Hide()
    Modern.cancelButton = cancel
    local opacityLabel = Label(frame, "WINDOW OPACITY", 1350, -61, 120, 18, "GameFontNormalSmall", "textMuted")
    opacityLabel:SetJustifyH("RIGHT")
    local opacityValue = Label(frame, "100%", 1472, -61, 34, 18, "GameFontHighlightSmall", "textPrimary")
    opacityValue:SetJustifyH("RIGHT")
    local opacity = CreateFrame("Slider", "ModuloMarketModernOpacity", frame, "OptionsSliderTemplate")
    opacity:SetSize(160, 16); opacity:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -34, -88)
    opacity:SetMinMaxValues(0.35, 1); opacity:SetValueStep(0.05); opacity:SetObeyStepOnDrag(true)
    opacity:SetValue(tonumber(MM.db and MM.db.backgroundOpacity) or 0.85)
    opacity:SetScript("OnValueChanged", function(_, value)
        value = math.max(0.35, math.min(1, tonumber(value) or 1))
        if MM.db then MM.db.backgroundOpacity = value end
        frame:SetAlpha(value); opacityValue:SetText(string.format("%d%%", math.floor(value * 100 + 0.5)))
    end)
    Modern.opacity = opacity

    local navY = -132
    Modern.nav = CreateFrame("Frame", nil, frame)
    Modern.nav:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, navY)
    Modern.nav:SetSize(1472, 40)
    local tabWidth = 1472 / #TAB_SPECS
    for i, spec in ipairs(TAB_SPECS) do
        local button = CreateFrame("Button", nil, Modern.nav)
        button:SetSize(tabWidth, 38)
        button:SetPoint("TOPLEFT", Modern.nav, "TOPLEFT", (i - 1) * tabWidth, 0)
        button.background = button:CreateTexture(nil, "BACKGROUND")
        button.background:SetAllPoints(); Paint(button.background, "tabInactive")
        button.label = Label(button, spec.label, 2, -11, tabWidth - 4, 24, "GameFontNormal", "textMuted")
        button.label:SetJustifyH("CENTER")
        button.indicator = button:CreateTexture(nil, "ARTWORK")
        button.indicator:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        button.indicator:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        button.indicator:SetHeight(3); Paint(button.indicator, "surfaceRaised")
        button:SetScript("OnClick", function() UI.SetTab(spec.key); Modern.RenderRows() end)
        Modern.tabs[spec.key] = button
    end

    local bodyTop = -194
    local leftWidth, centerWidth, rightWidth = 300, 812, 330
    local leftX, centerX, rightX = 24, 340, 1170
    local bodyHeight = 660
    local left = Panel(frame, "FILTERS", leftX, bodyTop, leftWidth, bodyHeight)
    Modern.filtersPanel = left
    local center = Panel(frame, "ALL ITEMS", centerX, bodyTop, centerWidth, bodyHeight)
    Modern.centerPanel = center
    local right = Panel(frame, "INSPECTED ITEM", rightX, bodyTop, rightWidth, bodyHeight)
    Modern.inspector = right
    Modern.centerTitle = center.titleText
    Modern.resultCount = Label(center, "0 / 0", centerWidth - 120, -11, 100, 20, "GameFontHighlightSmall", "textMuted")
    Modern.resultCount:SetJustifyH("RIGHT")

    -- Search and core filters reuse the existing MarketUI state/build pipeline.
    Label(left, "SEARCH", 16, -52, 260, 18, "GameFontNormalSmall", "textAccent")
    local search = CreateFrame("EditBox", nil, left)
    search:SetSize(266, 30); search:SetPoint("TOPLEFT", left, "TOPLEFT", 16, -74)
    search:SetAutoFocus(false); search:SetMaxLetters(80); search:SetTextInsets(32, 8, 0, 0)
    if search.SetFontObject then search:SetFontObject("GameFontHighlight") end
    if search.SetTextColor then search:SetTextColor(0.91, 0.93, 0.97, 1) end
    local searchBg = search:CreateTexture(nil, "BACKGROUND")
    searchBg:SetAllPoints(); Paint(searchBg, "control")
    search.background = searchBg
    search.border = Border(search, "borderStrong")
    local searchIcon = search:CreateTexture(nil, "ARTWORK")
    searchIcon:SetTexture("Interface\\AddOns\\ModuloMarket\\Textures\\search.tga")
    searchIcon:SetSize(16, 16); searchIcon:SetPoint("LEFT", search, "LEFT", 9, 0)
    search.icon = searchIcon
    local placeholder = Label(search, "Search items…", 32, -7, 220, 18, "GameFontDisableSmall", "textMuted")
    search.placeholder = placeholder
    local function RefreshSearchPlaceholder()
        if search:GetText() == "" and not search:HasFocus() then placeholder:Show() else placeholder:Hide() end
    end
    search:SetScript("OnEditFocusGained", function() Paint(searchBg, "controlHighlight"); RefreshSearchPlaceholder() end)
    search:SetScript("OnEditFocusLost", function() Paint(searchBg, "control"); RefreshSearchPlaceholder() end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self) UI.SetSearch(self:GetText()); self:ClearFocus() end)
    search:SetScript("OnTextChanged", function(self, userInput)
        RefreshSearchPlaceholder()
        if userInput then UI.SetSearch(self:GetText()) end
    end)
    RefreshSearchPlaceholder()
    Modern.search = search
    Modern.professionDropdown = CreateDropdown(left, "PROFESSION", -118, leftWidth,
        function() return UI.GetModernState().professionOptions end,
        function() return UI.GetModernState().professionFilter end,
        function(value) UI.SetProfessionFilter(value) end)
    Modern.roleDropdown = CreateDropdown(left, "ITEM ROLE", -190, leftWidth,
        function() return {
            { text="All item roles", value="all" }, { text="Known craft outputs", value="known" },
            { text="Learnable craft outputs", value="learnable" }, { text="Unavailable craft outputs", value="unlearnable" },
            { text="Gathering resources", value="gather" }, { text="Crafting reagents", value="material" },
        } end,
        function() return UI.GetModernState().roleFilter end,
        function(value) UI.SetRoleFilter(value) end)
    Modern.itemTypeDropdown = CreateDropdown(left, "ITEM TYPE", -262, leftWidth,
        function() return {
            { text="All item types", value="all" }, { text="Consumables", value="consumables" },
            { text="Equipment", value="equipment" }, { text="Trade Goods", value="tradeGoods" },
            { text="Other item classes", value="other" },
        } end,
        function() return UI.GetModernState().itemTypeFilter end,
        function(value) UI.SetItemTypeFilter(value) end)
    Label(left, "OPTIONS", 16, -336, 260, 20, "GameFontNormalLarge", "textAccent")
    Modern.quickChecks = {
        MakeCheck(left, "Crafting materials only", 12, -364, "craftingMaterialsOnly", function() return UI.GetModernState().marketQuickFilters.craftingMaterialsOnly end, UI.SetMarketQuickFilter),
        MakeCheck(left, "High profit only", 12, -392, "highProfitOnly", function() return UI.GetModernState().marketQuickFilters.highProfitOnly end, UI.SetMarketQuickFilter),
        MakeCheck(left, "Show review items only", 12, -420, "reviewOnly", function() return UI.GetModernState().marketQuickFilters.reviewOnly end, UI.SetMarketQuickFilter),
    }
    Modern.craftChecks = {
        MakeCheck(left, "Craftable only", 12, -364, "craftableOnly", function() return UI.GetModernState().craftFilters.craftableOnly end, UI.SetCraftFilter),
        MakeCheck(left, "Profitable only", 12, -392, "profitableOnly", function() return UI.GetModernState().craftFilters.profitableOnly end, UI.SetCraftFilter),
        MakeCheck(left, "Review items only", 12, -420, "reviewOnly", function() return UI.GetModernState().craftFilters.reviewOnly end, UI.SetCraftFilter),
        MakeCheck(left, "Hide non-profitable", 12, -448, "hideLowProfit", function() return UI.GetModernState().craftFilters.hideLowProfit end, UI.SetCraftFilter),
    }
    Modern.economicsChecks = {
        MakeCheck(left, "Crafted outputs", 12, -364, "crafted", function() return UI.GetModernState().economicsFilters.crafted end, UI.SetEconomicsFilter),
        MakeCheck(left, "Gathered / collected", 12, -392, "gathered", function() return UI.GetModernState().economicsFilters.gathered end, UI.SetEconomicsFilter),
        MakeCheck(left, "Crafting reagents", 12, -420, "material", function() return UI.GetModernState().economicsFilters.material end, UI.SetEconomicsFilter),
        MakeCheck(left, "Other market items", 12, -448, "other", function() return UI.GetModernState().economicsFilters.other end, UI.SetEconomicsFilter),
    }
    Modern.turnInTypeDropdown = CreateDropdown(left, "TURN-IN TYPE", -364, leftWidth,
        function() return { {text="All turn-ins",value="all"},{text="Waylaid Crates",value="crate"},{text="Craftsman's Writs",value="writ"} } end,
        function() return UI.GetModernState().turnInTypeFilter or "all" end,
        function(value) UI.SetTurnInFilters(UI.GetModernState().turnInTierFilter, UI.GetModernState().turnInCategoryFilter, value) end)
    Modern.turnInTierDropdown = CreateDropdown(left, "TIER", -436, leftWidth,
        function() return {
            {text="All tiers",value="all"},{text="Apprentice",value="Apprentice"},
            {text="Journeyman",value="Journeyman"},{text="Expert",value="Expert"},{text="Artisan",value="Artisan"},
        } end, function() return UI.GetModernState().turnInTierFilter or "all" end,
        function(value) UI.SetTurnInFilters(value, UI.GetModernState().turnInCategoryFilter, UI.GetModernState().turnInTypeFilter) end)
    Modern.turnInCategoryDropdown = CreateDropdown(left, "CATEGORY / PROFESSION", -508, leftWidth,
        function()
            if UI.GetTurnInCategoryOptions then return UI.GetTurnInCategoryOptions() end
            return { {text="All categories / professions",value="all"} }
        end,
        function() return UI.GetModernState().turnInCategoryFilter or "all" end,
        function(value) UI.SetTurnInFilters(UI.GetModernState().turnInTierFilter, value, UI.GetModernState().turnInTypeFilter) end)
    Modern.craftingScopeDropdown = CreateDropdown(left, "CRAFTING SCOPE", -508, leftWidth,
        function() return {
            {text="Account Crafting",value="account"},{text="Character Crafting",value="character"},
        } end, function() return UI.GetModernState().craftingScope end,
        function(value) UI.SetCraftingScope(value) end)
    Label(left, "DATA", 16, -578, 260, 18, "GameFontNormalSmall", "textAccent")
    Modern.dataText = Label(left, "Auction and recipe data status", 16, -602, 264, 46, "GameFontDisableSmall", "textMuted")
    -- The old explanatory hint extended below this panel at compact scales.
    -- Data status is sufficient here; omit the redundant footer text.
    Modern.filterHint = nil

    -- Modern table: separate virtual row pool, but the same source rows and selection model.
    local tableHeader = center:CreateTexture(nil, "ARTWORK")
    tableHeader:SetPoint("TOPLEFT", center, "TOPLEFT", 12, -48)
    tableHeader:SetPoint("TOPRIGHT", center, "TOPRIGHT", -12, -48)
    tableHeader:SetHeight(34); Paint(tableHeader, "surfaceRaised")
    local headerSpecs = {
        {"ITEM", 12, 295, "LEFT", "name"}, {"CHEAPEST", 315, 105, "RIGHT", "price"},
        {"AT PRICE / COST", 430, 125, "RIGHT", "materials"}, {"UNITS", 565, 70, "RIGHT", "total"},
        {"PROFIT / NET", 640, 115, "RIGHT", "profit"},
    }
    Modern.headers = {}
    for _, spec in ipairs(headerSpecs) do
        local button = CreateFrame("Button", nil, center)
        button:SetPoint("TOPLEFT", center, "TOPLEFT", spec[2], -52)
        button:SetSize(spec[3], 28)
        button.label = Label(button, spec[1], 0, -5, spec[3], 20, "GameFontNormalSmall", "textAccent")
        button.label:SetJustifyH(spec[4])
        button:SetScript("OnClick", function() if button.sortKey and button.sortKey ~= "" then UI.SortBy(button.sortKey) end end)
        Modern.headers[#Modern.headers + 1] = button
    end
    Modern.scroll = CreateFrame("ScrollFrame", "ModuloMarketModernScrollFrame", center, "UIPanelScrollFrameTemplate")
    Modern.scroll:SetPoint("TOPLEFT", center, "TOPLEFT", 12, -84)
    Modern.scroll:SetPoint("BOTTOMRIGHT", center, "BOTTOMRIGHT", -30, 14)
    Modern.scrollChild = CreateFrame("Frame", nil, Modern.scroll)
    Modern.scrollChild:SetSize(centerWidth - 46, 1)
    Modern.scroll:SetScrollChild(Modern.scrollChild)
    Modern.scroll:SetScript("OnVerticalScroll", function(self, offset)
        self:SetVerticalScroll(offset)
        Modern.RenderRows()
    end)
    if Modern.scroll.EnableMouseWheel then Modern.scroll:EnableMouseWheel(true) end
    Modern.scroll:SetScript("OnMouseWheel", function(self, delta)
        local contentHeight = Modern.scrollChild:GetHeight() or 1
        local viewportHeight = self:GetHeight() or 1
        local maximum = math.max(0, contentHeight - viewportHeight)
        local nextOffset = math.max(0, math.min(maximum, (self:GetVerticalScroll() or 0) - (delta * 54)))
        self:SetVerticalScroll(nextOffset)
        Modern.RenderRows()
    end)
    for i = 1, 25 do
        local row = CreateFrame("Button", nil, Modern.scrollChild)
        row:SetSize(centerWidth - 48, 26)
        row.shade = row:CreateTexture(nil, "BACKGROUND")
        row.shade:SetAllPoints(); Paint(row.shade, "surfaceAlt")
        row.edge = row:CreateTexture(nil, "ARTWORK")
        row.edge:SetPoint("TOPLEFT", row, "TOPLEFT", 3, 0); row.edge:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 3, 0); row.edge:SetWidth(2); Paint(row.edge, "accent")
        row.statusMarker = row:CreateTexture(nil, "ARTWORK")
        row.statusMarker:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.statusMarker:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        row.statusMarker:SetWidth(3)
        row.statusMarker:Hide()
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20); row.icon:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.name = Label(row, "", 34, -5, 270, 22, "GameFontHighlight")
        row.price = Label(row, "", 315, -5, 105, 22, "GameFontHighlight")
        row.price:SetJustifyH("RIGHT")
        row.middle = Label(row, "", 430, -5, 125, 22, "GameFontHighlight")
        row.middle:SetJustifyH("RIGHT")
        row.quantity = Label(row, "", 565, -5, 70, 22, "GameFontHighlight")
        row.quantity:SetJustifyH("RIGHT")
        row.profit = Label(row, "", 640, -5, 115, 22, "GameFontHighlight")
        row.profit:SetJustifyH("RIGHT")
        row:SetScript("OnClick", function(self, mouseButton)
            if self.item then
                if mouseButton == "LeftButton" and _G.IsShiftKeyDown and _G.IsShiftKeyDown() then
                    UI.HandleShiftClick(self.item)
                    return
                end
                UI.SelectItem(self.item); Modern.RefreshInspector(); Modern.RenderRows()
            end
        end)
        row:SetScript("OnEnter", function(self)
            if self.item and UI.ShowMarketItemTooltip then
                UI.ShowMarketItemTooltip(self, self.item,
                    UI.GetModernState().tab == "crafts" and self.item.recipeID ~= nil)
            end
        end)
        row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        Modern.rows[i] = row
    end

    -- Independent inspector cards.
    local itemCard = Panel(right, "SELECTED ITEM", 10, -46, rightWidth - 20, 106)
    Modern.itemCard = itemCard
    Modern.itemIcon = itemCard:CreateTexture(nil, "ARTWORK")
    Modern.itemIcon:SetSize(52, 52); Modern.itemIcon:SetPoint("TOPLEFT", itemCard, "TOPLEFT", 12, -44)
    Modern.itemTitle = Label(itemCard, "Select an item", 74, -48, 210, 34, "GameFontNormalLarge", "textPrimary")
    Modern.itemBadge = Label(itemCard, "", 74, -82, 210, 18, "GameFontHighlightSmall", "accent")

    local marketCard = Panel(right, "MARKET INFORMATION", 10, -164, rightWidth - 20, 152)
    Modern.marketCard = marketCard; Modern.marketCardTitle = marketCard.titleText
    Modern.labelPrice = Label(marketCard, "PRICE / UNIT", 12, -48, 108, 18, "GameFontNormalSmall", "textAccent")
    Modern.valuePrice = Label(marketCard, "—", 124, -46, 170, 22, "GameFontHighlight")
    Modern.labelSupply = Label(marketCard, "TOTAL LISTED", 12, -72, 108, 18, "GameFontNormalSmall", "textAccent")
    Modern.valueSupply = Label(marketCard, "—", 124, -70, 170, 22, "GameFontHighlight")
    Modern.labelAtPrice = Label(marketCard, "AT PRICE", 12, -96, 108, 18, "GameFontNormalSmall", "textAccent")
    Modern.valueAtPrice = Label(marketCard, "—", 124, -94, 170, 22, "GameFontHighlight")
    Modern.labelProfit = Label(marketCard, "BEST CRAFT", 12, -120, 108, 18, "GameFontNormalSmall", "textAccent")
    Modern.valueProfit = Label(marketCard, "—", 124, -118, 170, 22, "GameFontHighlight")

    local relationshipCard = Panel(right, "RELATIONSHIPS", 10, -328, rightWidth - 20, 170)
    Modern.relationshipCard = relationshipCard; Modern.relationshipTitle = relationshipCard.titleText
    Modern.relationshipText = Label(relationshipCard, "", 12, -48, rightWidth - 44, 112, "GameFontHighlightSmall")
    Modern.bundleScroll = CreateFrame("ScrollFrame", "ModuloMarketModernBundleScroll", relationshipCard, "UIPanelScrollFrameTemplate")
    Modern.bundleScroll:SetPoint("TOPLEFT", relationshipCard, "TOPLEFT", 10, -42)
    Modern.bundleScroll:SetPoint("BOTTOMRIGHT", relationshipCard, "BOTTOMRIGHT", -26, 8)
    Modern.bundleChild = CreateFrame("Frame", nil, Modern.bundleScroll)
    Modern.bundleChild:SetSize(rightWidth - 48, 1)
    Modern.bundleScroll:SetScrollChild(Modern.bundleChild)
    Modern.bundleLines = {}
    Modern.bundleScroll:SetScript("OnVerticalScroll", function(self, offset) self:SetVerticalScroll(offset) end)
    if Modern.bundleScroll.EnableMouseWheel then Modern.bundleScroll:EnableMouseWheel(true) end
    Modern.bundleScroll:SetScript("OnMouseWheel", function(self, delta)
        local maximum = math.max(0, (Modern.bundleChild:GetHeight() or 1) - (self:GetHeight() or 1))
        self:SetVerticalScroll(math.max(0, math.min(maximum, (self:GetVerticalScroll() or 0) - delta * 36)))
    end)
    Modern.bundleScroll:Hide()

    local historyCard = Panel(right, "MARKET HISTORY", 10, -510, rightWidth - 20, 138)
    Modern.historyCard = historyCard; Modern.historyTitle = historyCard.titleText
    Modern.historyText = Label(historyCard, "", 12, -46, rightWidth - 44, 54, "GameFontHighlightSmall")
    Modern.historyBars, Modern.historyBarLabels = {}, {}
    for i = 1, 3 do
        local bar = historyCard:CreateTexture(nil, "ARTWORK")
        bar:SetPoint("BOTTOMLEFT", historyCard, "BOTTOMLEFT", 18 + (i - 1) * 66, 10)
        bar:SetSize(42, 18); Paint(bar, "historyBar"); bar:Hide()
        Modern.historyBars[i] = bar
        local label = Label(historyCard, "", 12 + (i - 1) * 66, -84, 54, 16, "GameFontDisableSmall", "textMuted")
        label:SetJustifyH("CENTER"); label:Hide(); Modern.historyBarLabels[i] = label
    end

    local footer = Label(frame, "Data from ForeverDB.net  ·  Modulo Market", 28, -872, 620, 18, "GameFontDisableSmall", "textMuted")
    Modern.footer = footer
    local version = Label(frame, "Modulo Market v" .. tostring(MM.version or "unknown"), 1240, -872, 250, 18, "GameFontDisableSmall", "textMuted")
    version:SetJustifyH("RIGHT"); Modern.version = version

    frame:SetScript("OnHide", function()
        if UI.frame and UI.frame:IsShown() then UI.frame:Hide() end
    end)
    frame:SetScript("OnShow", function()
        UI.PrepareModernBackend()
        UI.SetTab(UI.GetModernState().tab or "market")
        Modern.ApplyTheme()
        Modern.RenderRows()
    end)
    frame:SetScript("OnUpdate", function(_, elapsed)
        Modern.elapsed = Modern.elapsed + (tonumber(elapsed) or 0)
        if Modern.elapsed < 0.20 then return end
        Modern.elapsed = 0
        local state = UI.GetModernState()
        Modern.metadata:SetText(state.metadata ~= "" and state.metadata or "No saved market snapshot")
        Modern.scanState:SetText(state.scanState or "Scan: Unknown")
        if Modern.dataText then
            Modern.dataText:SetText(tostring(state.auctionData or "Auction Data: unavailable") .. "\n"
                .. tostring(state.recipeData or "Recipe Data: unavailable") .. "\n"
                .. tostring(state.reviewData or "Review records: —"))
        end
        if Modern.craftingScopeDropdown and Modern.craftingScopeDropdown.Refresh then Modern.craftingScopeDropdown.Refresh() end
        Modern.centerTitle:SetText(string.upper((state.tab == "market" and "ALL ITEMS") or (state.tab or "MARKET")))
        if state.searchStatus then
            Modern.resultCount:SetText(state.searchStatus)
        end
        if state.tab ~= Modern.renderedTab or #state.rows ~= Modern.renderedCount
            or state.viewRevision ~= Modern.renderedRevision then
            Modern.RenderRows()
        else
            Modern.RefreshInspector()
            Modern.RefreshTabs(state.tab)
        end
        Modern.RefreshScanActions()
    end)
    frame:Hide()
    AddSpecialFrame("ModuloMarketModernFrame")
    return frame
end

function Modern.RefreshScanActions(state)
    if not Modern.updateButton or not Modern.frame then return end
    state = state or (MM.Replicate and MM.Replicate.GetState and MM.Replicate.GetState()) or {}
    local remaining = math.max(0, tonumber(state.cooldownRemaining) or 0)
    local text, enabled
    if state.active then
        text, enabled = "Scanning…", false
    elseif state.pendingConfirmation then
        text, enabled = "Confirm Scan", true
    elseif state.attemptedThisSession then
        text, enabled = "Scan used this session", false
    elseif remaining > 0 then
        text = remaining >= 60 and string.format("Scan in %dm", math.ceil(remaining / 60))
            or string.format("Scan in %ds", math.ceil(remaining))
        enabled = false
    else
        text, enabled = "Scan Market", true
    end
    Modern.updateButton.label:SetText(text)
    if Modern.updateButton.iconTexture then
        Modern.updateButton.iconTexture:SetTexture(state.pendingConfirmation
            and "Interface\\AddOns\\ModuloMarket\\Textures\\check.tga"
            or "Interface\\AddOns\\ModuloMarket\\Textures\\refresh.tga")
        if enabled then Modern.updateButton.iconTexture:SetVertexColor(1, 1, 1, 1)
        else Modern.updateButton.iconTexture:SetVertexColor(0.55, 0.58, 0.64, 1) end
    end
    if enabled then Modern.updateButton:Enable() else Modern.updateButton:Disable() end
    if state.pendingConfirmation or state.active then Modern.cancelButton:Show() else Modern.cancelButton:Hide() end
    if state.pendingConfirmation then
        Modern.scanState:SetText("Scan: Confirmation required")
    elseif state.active then
        Modern.scanState:SetText("Scan: Active")
    elseif state.attemptedThisSession then
        Modern.scanState:SetText("Scan: Used this session")
    elseif remaining > 0 then
        Modern.scanState:SetText("Scan: Cooldown")
    else
        Modern.scanState:SetText("Scan: Idle")
    end
    local last = type(MM.db) == "table" and MM.db.lastReplicateTargetDiagnostics or nil
    if type(last) == "table" and tonumber(last.completedAt or last.timestamp)
        and not state.active and not state.pendingConfirmation then
        local stamp = tonumber(last.completedAt or last.timestamp)
        local when = type(_G.date) == "function" and _G.date("%H:%M", stamp) or tostring(stamp)
        local outcome = tostring(last.outcome or "unknown"):match("^complete") and "complete" or "aborted"
        Modern.scanState:SetText(Modern.scanState:GetText() .. (outcome == "complete" and " · OK " or " · Failed ") .. when)
    end
end

function Modern.ApplyTheme()
    if not Modern.frame then return end
    for texture, entry in pairs(themedTextures) do
        if texture and entry then
            local color = C(entry.role, entry.fallback)
            texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
        end
    end
    for fontString, role in pairs(themedFonts) do
        if fontString and role then
            local color = C(role)
            fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
        end
    end
    for _, group in ipairs({ Modern.quickChecks or {}, Modern.craftChecks or {}, Modern.economicsChecks or {} }) do
        for _, check in ipairs(group) do if check.Refresh then check:Refresh() end end
    end
    Modern.RefreshTabs(UI.GetModernState().tab)
    Modern.RenderRows()
end

function Modern.Raise()
    local frame = CreateUI()
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    if frame.Raise then frame:Raise() end
end

function Modern.Show()
    local frame = CreateUI()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    local centerX, centerY = frame:GetCenter()
    if type(MM.db) == "table" and tonumber(centerX) and tonumber(centerY) then
        MM.db.windowPositions = MM.db.windowPositions or {}
        MM.db.windowPositions.modern = { x = centerX, y = centerY }
    end
    UI.PrepareModernBackend()
    -- The backend frame may already be shown from an earlier presentation;
    -- explicitly consume any deferred post-scan refresh in that case.
    if UI.Refresh then UI.Refresh() end
    if UI.frame then UI.frame:SetFrameStrata("BACKGROUND"); UI.frame:SetAlpha(0); UI.frame:EnableMouse(false) end
    frame:SetAlpha(tonumber(MM.db and MM.db.backgroundOpacity) or 0.85)
    frame:Show()
    Modern.RefreshScanActions()
    Modern.Raise()
end

function Modern.Hide()
    if Modern.frame then Modern.frame:Hide() end
end

function Modern.Toggle()
    local frame = CreateUI()
    if frame:IsShown() then Modern.Hide() else Modern.Show() end
end

function Modern.ResetWindowPosition()
    if type(MM.db) == "table" then
        MM.db.windowPositions = MM.db.windowPositions or {}
        MM.db.windowPositions.modern = nil
    end
    if Modern.frame then
        Modern.frame:ClearAllPoints()
        Modern.frame:SetPoint("CENTER")
    end
    return true
end

function Modern.IsShown()
    return Modern.frame and Modern.frame:IsShown() or false
end
