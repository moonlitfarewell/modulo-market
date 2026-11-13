from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_align():
    assert 'MM.version = "0.9.9"' in CORE
    assert "## Version: 0.9.9" in TOC
    assert MANIFEST["version"] == "0.9.9"


def test_centre_table_perimeter_is_restored_without_reintroducing_fill():
    assert "AddPanelInnerEdge(286, -158, 834, 650)" in UI
    assert "local centerPanel = frame:CreateTexture" not in UI
    assert "UI.tableColumnGuides" not in UI
    assert "UI.tableHeaderSurface" not in UI


def test_all_items_numeric_columns_are_content_sized_and_right_anchored():
    block = UI.split("local function UpdateAllItemsColumnLayout()", 1)[1].split("\nend\n\nfunction UI.RenderRows()", 1)[0]
    assert "GetStringWidth()" in block
    assert "measuredWidth(row.price, 76)" in block
    assert "measuredWidth(row.depth, 58)" in block
    assert "measuredWidth(row.atPrice, 72)" in block
    assert "local rowRight = 796" in block
    assert "local xTotal = rowRight - rightPadding - widths.total" in block
    assert "local xAtPrice = xTotal - columnGap - widths.atPrice" in block
    assert "local xCheapest = xAtPrice - columnGap - widths.cheapest" in block
    assert "local nameWidth = math.max(72, xCheapest - columnGap - 27)" in block


def test_render_rows_recalculates_column_widths_after_visible_values_update():
    render = UI.split("function UI.RenderRows()", 1)[1].split("function UI.RenderHistory()", 1)[0]
    assert 'if UI.activeTab == "market" then UpdateAllItemsColumnLayout() end' in render
    assert 'UI.scroll:SetScript("OnVerticalScroll"' in UI


def test_all_items_fields_follow_the_right_to_left_column_layout():
    block = UI.split("local function UpdateAllItemsColumnLayout()", 1)[1].split("\nend\n\nfunction UI.RenderRows()", 1)[0]
    assert 'row.price:SetPoint("LEFT", row, "LEFT", xCheapest, 0)' in block
    assert 'row.depth:SetPoint("LEFT", row, "LEFT", xAtPrice, 0)' in block
    assert 'row.atPrice:SetPoint("LEFT", row, "LEFT", xTotal, 0)' in block
    assert "row.total:Hide()" in block
    assert "row.profit:Hide()" in block


def test_other_tab_column_layouts_are_separate():
    assert 'local craftColumns = {' in UI
    assert 'local economicsColumns = {' in UI
    assert 'local marketColumns = {' in UI
