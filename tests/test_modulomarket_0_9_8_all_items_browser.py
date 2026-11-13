from pathlib import Path
import re
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_align():
    assert 'MM.version = "0.9.8"' in CORE
    assert "## Version: 0.9.8" in TOC
    assert MANIFEST["version"] == "0.9.8"


def test_all_items_is_four_column_auction_browser():
    match = re.search(r'elseif tab == "market" then\s+labels = \{([^}]*)\}\s+keys = \{([^}]*)\}', UI)
    assert match is not None
    assert '"Item", "Cheapest", "At Price", "Total Units"' in match.group(1)
    assert '"name", "price", "depth", "total"' in match.group(2)


def test_all_items_uses_at_price_and_total_units_not_listing_count():
    block = UI.split('elseif tab == "market" then\n        local allItemsColumns =', 1)[1].split("\n    else\n        local marketColumns", 1)[0]
    assert "row.depth:SetPoint" in block
    assert "row.atPrice:SetPoint" in block
    assert "row.total:Hide()" in block
    assert "row.profit:Hide()" in block
    assert "row.atPrice:SetPoint" in block


def test_existing_sort_and_scroll_behaviour_is_preserved():
    assert "function UI.FinishView(rows)" in UI
    assert "function UI.RenderRows()" in UI
    assert "UI.scroll:SetScript(\"OnVerticalScroll\"" in UI
    assert "UI.listOffset = offset" in UI
    assert "math.floor((UI.listOffset or 0) / UI.rowHeight) + 1" in UI
    assert "visibleCount = 25," in UI
    assert "key == \"depth\"" in UI and "a.minPriceQuantity" in UI
    assert "key == \"total\"" in UI and "a.totalQuantity" in UI


def test_item_quality_colours_names_and_craft_status_uses_row_marker():
    assert "GetItemQualityHex" in UI
    assert "_G.GetItemQualityColor" in UI
    assert 'return "|c" .. GetItemQualityHex(item and item.itemID) .. GetItemName(item) .. "|r"' in UI
    assert "local function GetItemCraftMarker(itemID)" in UI
    assert "row.statusMarker:SetWidth(3)" in UI
    assert "button.statusMarker:SetColorTexture(GetItemCraftMarker(item.itemID))" in UI
    assert "hasLearnable then return 1, 0.82, 0.24, 1" in UI
    assert "hasUnlearnableOrUnknown then return 0.95, 0.27, 0.24, 1" in UI
    assert "hasKnown then return 0.25, 0.88, 0.42, 1" in UI
    assert "return 1, 1, 1, 1" in UI


def test_all_items_low_supply_shortcut_is_removed_but_legacy_saved_state_is_inert():
    specs = UI.split("local marketQuickFilterSpecs = {", 1)[1].split("\n    }", 1)[0]
    assert '"lowSupplyOnly"' not in specs
    assert "UI.marketQuickFilters.lowSupplyOnly = false" in UI
    assert "lowSupplyOnly = false," in UI


def test_redundant_middle_panel_and_column_guides_are_removed():
    assert "local centerPanel = frame:CreateTexture" not in UI
    assert "AddPanelInnerEdge(286, -158, 834, 650)" not in UI
    assert "UI.tableColumnGuides" not in UI
    assert "local guideX in ipairs({ 520, 650, 760, 850, 935 })" not in UI
    assert "UI.tableHeaderSurface" not in UI
    assert "UI.tableHeaderBorder" not in UI


def test_other_tabs_keep_their_independent_columns():
    assert 'labels = { "Recipe", "Materials (cost)", "Sale / Unit", "At Price", "Total", "Profit / Craft" }' in UI
    assert 'labels = { "Item", "Cheapest", "Craft cost", "Price change", "Total units", "Best craft profit" }' in UI
    assert 'labels = { "Item", "Cheapest", "At Price", "Total Units", "Listings", "Best Craft Profit" }' in UI
    assert 'labels = { "Item", "Cheapest", "Price Change", "Latest Units", "Total", "Best Craft Profit" }' in UI


def test_manifest_inventory_matches_release_tree():
    actual = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or any(part in {".git", "__pycache__", ".pytest_cache"} for part in path.parts):
            continue
        rel = path.relative_to(ROOT).as_posix()
        actual.append(rel)
    assert sorted(actual) == sorted(MANIFEST["files"])
    assert MANIFEST["file_count"] == len(actual)


def test_non_all_items_tabs_restore_their_own_profit_and_listing_fields():
    assert "row.profit:Show()" in UI
    assert "row.total:Show()" in UI
    materials = UI.split('elseif tab == "materials" then\n        local materialColumns =', 1)[1].split('elseif tab == "market" then\n        local allItemsColumns =', 1)[0]
    assert "row.profit:Show()" in materials
    all_items = UI.split('elseif tab == "market" then\n        local allItemsColumns =', 1)[1].split('\n    else\n        local marketColumns', 1)[0]
    assert "row.total:Hide()" in all_items and "row.profit:Hide()" in all_items
