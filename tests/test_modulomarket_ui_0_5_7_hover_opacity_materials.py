from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns" / "ModuloMarket" / "MarketUI.lua").read_text()

def test_market_is_below_tooltip_strata():
    assert 'frame:SetFrameStrata("DIALOG")' in UI
    assert 'GameTooltip:SetFrameStrata("TOOLTIP")' in UI
    assert 'RaiseMarketTooltip(self, label, self.tooltipText)' in UI

def test_item_and_recipe_hover_targets_exist():
    assert 'local function ShowMarketItemTooltip(owner, item, showRecipe)' in UI
    assert 'GameTooltip.SetItemByID' in UI
    assert 'GameTooltip.SetSpellByID' in UI
    assert 'row.nameHit:SetScript("OnEnter"' in UI
    assert 'UI.detailItemTooltip:SetScript("OnEnter"' in UI
    assert 'UI.detailRecipeTooltip:SetScript("OnEnter"' in UI

def test_filter_controls_explain_themselves():
    assert 'AttachFilterTooltip(UI.search' in UI
    assert 'AttachFilterTooltip(UI.professionDropdown' in UI
    assert 'AttachFilterTooltip(UI.roleDropdown' in UI
    assert 'RaiseMarketTooltip(self, option.tooltipTitle or option.text, option.tooltipText)' in UI

def test_opacity_is_whole_window_and_independent_of_tooltips():
    assert 'frame:SetAlpha(alpha)' in UI
    assert 'UI.opacitySlider:SetMinMaxValues(0.35, 1.0)' in UI
    assert 'Window opacity' in UI

def test_materials_hides_listings_and_uses_best_profit_column():
    assert 'labels = { "Item", "Cheapest", "At Price", "Total Units", "Best Craft Profit" }' in UI
    assert 'row.total:Hide()' in UI
    assert 'UI.headerButtons[6]:Hide()' in UI
    assert 'row.profit:SetPoint("RIGHT", row, "RIGHT", 519, 0)' in UI
