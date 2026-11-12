from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
REPLICATE = (ROOT / "AddOns/ModuloMarket/Replicate.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()


def test_020_versions_and_native_blizzard_templates():
    assert re.search(r"^## Version: 0\.6\.2$", TOC, re.M)
    assert 'BasicFrameTemplateWithInset' in UI
    assert 'UIPanelButtonTemplate' in UI
    assert 'InputBoxTemplate' in UI
    assert "Select an item" in UI


def test_catalog_groups_variant_rows_by_item_id_and_keeps_price_depth():
    assert "byID = {}" in UI
    assert "function StepCatalog()" in UI
    assert "aggregate.variantCount = aggregate.variantCount + 1" in UI
    assert "aggregate.totalQuantity = aggregate.totalQuantity +" in UI
    assert "aggregate.minPriceQuantity = (tonumber(aggregate.minPriceQuantity) or 0) + depth" in UI
    assert "aggregate.bestVariant = row" in UI


def test_opening_market_never_synchronously_traverses_all_saved_rows():
    assert "function StartCatalog(snapshot)" in UI
    assert "function StepCatalog()" in UI
    assert "while build.index <= stop do" in UI
    assert "build.index + 249" in UI
    on_show = UI[UI.index('frame:SetScript("OnShow", function(self)'):UI.index('frame:SetScript("OnUpdate"', UI.index('frame:SetScript("OnShow", function(self)'))]
    assert "UI.Refresh()" in on_show
    assert "StartCatalog(snapshot)" in UI
    assert "table.sort(UI.viewRows" not in UI


def test_render_path_uses_only_virtualized_visible_rows_and_no_item_api_calls():
    render = UI[UI.index("function UI.RenderRows()"):UI.index("function UI.RenderHistory()")]
    assert "math.min(UI.visibleCount or rowPoolCount, rowPoolCount)" in render
    assert "GetItemNameByID" not in render
    assert "RequestLoadItemDataByID" not in render
    assert "GetItemInfo" not in render
    assert "table.sort" not in render


def test_opportunity_ranking_is_incremental_not_a_large_synchronous_sort():
    assert "local function StepRankSort()" in UI
    assert "local budget = 500" in UI
    assert "while budget > 0 do" in UI
    assert "table.sort" not in UI


def test_tabs_cover_item_economics_all_crafts_materials_low_supply_and_history():
    for tab in ['"economics"', '"allcrafts"', '"materials"', '"low"', '"history"']:
        assert tab in UI
    assert 'tabSpecs' in UI and '"crafting"' in UI
    assert 'MM.Recipes.BuildEconomics' in UI
    assert "GetLowSupplyThreshold(item)" in UI
    assert "function UI.RenderHistory()" in UI


def test_historical_points_are_bounded_and_indexed_by_item_id():
    assert "local function SaveHistoryPoint(snapshot)" in REPLICATE
    assert "point.items[itemID]" in REPLICATE
    assert "while #history > 4 do table.remove(history, 1) end" in REPLICATE
    assert "snapshot.items[tonumber(item.itemID)]" in UI


def test_confirm_and_cancel_controls_remain_present():
    assert 'UI.confirmButton = AddButton(frame, "Confirm full scan"' in UI
    assert 'UI.cancelButton = AddButton(frame, "Cancel"' in UI
    assert "MM.Replicate.Confirm()" in UI
    assert "MM.Replicate.CancelPrepare()" in UI


def test_manual_cost_entry_is_removed_from_player_ui():
    assert 'CreateInput(frame, "Your cost / unit (gold)"' not in UI
    assert 'CreateInput(frame, "Target sale price (gold, optional)"' not in UI
    assert 'tabSpecs' in UI and 'crafting' in UI
    assert 'tabSpecs' in UI and 'allcrafts' in UI
    assert "materialCostCopper" in UI
    assert "profitCopper" in UI


def test_audit_and_manifest_inventory_are_complete():
    manifest = json.loads((ROOT / "MANIFEST.json").read_text())
    assert manifest["version"] == "0.6.2"
    assert "MODULOMARKET-RUNTIME-AUDIT-0.4.0.md" in manifest["files"]
    assert "tests/market_ui_0_2_0_harness.lua" in manifest["files"]
    actual = sorted(
        p.relative_to(ROOT).as_posix()
        for p in ROOT.rglob("*")
        if p.is_file()
        and "__pycache__" not in p.parts
        and ".pytest_cache" not in p.parts
        and p.suffix != ".pyc"
    )
    assert sorted(manifest["files"]) == actual
