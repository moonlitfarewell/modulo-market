from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_auction_build_comparison_normalizes_numeric_client_build():
    assert "local function NormalizeBuildKey(value)" in UI
    assert 'local trailingNumber = text:match("(%d+)$")' in UI
    assert "NormalizeBuildKey(snapshotBuild) == NormalizeBuildKey(currentBuild)" in UI
    assert 'UI.auctionDataState:SetText(stateText)' in UI


def test_data_provenance_and_crafting_scope_live_in_left_data_card():
    assert 'UI.dataHeading = AddLabel(frame, "Data"' in UI
    assert 'UI.auctionDataLabel = AddLabel(frame, "Auction Data: unavailable"' in UI
    assert 'UI.recipeDataLabel = AddLabel(frame, "Recipe Data: unavailable"' in UI
    assert 'UI.reviewDataLabel = AddLabel(frame, "Review records: —"' in UI
    assert 'UI.craftingScopeDropdown = CreateDropdown(frame, 220, 36, -752' in UI
    assert 'UI.auctionDataLabel = AddLabel(frame, "Auction Data: unavailable", 660' not in UI


def test_all_items_options_are_real_source_grounded_filters():
    assert 'UI.marketQuickFilterHeading = AddLabel(frame, "OPTIONS"' in UI
    for key in ["craftingMaterialsOnly", "lowSupplyOnly", "highProfitOnly", "reviewOnly"]:
        assert key in UI
    assert 'MM.ProfessionData.IsMaterial(item.itemID)' in UI
    assert 'GetLowSupplyThreshold(item)' in UI
    assert 'tonumber(best.profitCopper) > 0' in UI
    assert 'matches = HasExplicitReviewForItem(item.itemID)' in UI
    assert 'freshness == "review"' in UI


def test_high_profit_filter_builds_existing_recipe_economics_index_first():
    assert '(UI.activeTab == "market" and UI.marketQuickFilters.highProfitOnly)' in UI
    assert 'if self.filterKey == "highProfitOnly" and UI.marketQuickFilters.highProfitOnly' in UI
    assert 'StartEconomicsIndex()' in UI


def test_quick_filters_are_saved_per_tab_and_only_shown_on_all_items():
    assert 'UI.tabFilterState[previousTab].marketQuickFilters = {' in UI
    assert 'local savedMarket = saved.marketQuickFilters or {}' in UI
    assert 'local showMarketQuickFilters = tab == "market"' in UI
    assert 'control:SetChecked(UI.marketQuickFilters[key] == true)' in UI


def test_relationships_are_separate_crafting_and_gathering_rows():
    assert 'Crafting:|r " .. craftingSummary' in UI
    assert 'Gathering:|r "' in UI
    assert 'No mapped source' in UI
    assert 'GATHERING REQUIREMENTS' in UI
    assert 'No captured recipe or confirmed gathering relationship is known for this item.' not in UI
    assert 'tostring(professionName) .. " (Classic)"' in UI


def test_header_keeps_scan_state_without_fabricated_percentage():
    assert 'UI.scanStateLabel = AddLabel(frame, "Scan: Idle"' in UI
    assert "Scan: 0%" not in UI
    assert "progressPercent" not in UI


def test_release_alignment():
    assert 'MM.version = "0.9.1"' in CORE
    assert '## Version: 0.9.1' in TOC
    assert MANIFEST["version"] == "0.9.1"
    assert "MODULOMARKET-RUNTIME-AUDIT-0.8.3.md" in MANIFEST["files"]
    assert "tests/test_modulomarket_0_8_2_mockup_alignment.py" in MANIFEST["files"]
    assert MANIFEST["file_count"] == len(MANIFEST["files"])
