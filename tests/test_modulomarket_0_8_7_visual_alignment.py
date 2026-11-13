from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())

def test_market_table_headers_align_to_the_existing_row_cells():
    assert '{ x = 776, w = 72, justify = "RIGHT" }' in UI
    assert '{ x = 852, w = 72, justify = "RIGHT" }' in UI
    assert '{ x = 914, w = 176, justify = "RIGHT" }' in UI
    assert '{ x = 920, w = 170, justify = "RIGHT" }' in UI
    assert '{ x = 836, w = 254, justify = "RIGHT" }' in UI
    assert 'row.atPrice:SetPoint("LEFT", row, "LEFT", 478, 0)' in UI or 'row.atPrice:SetPoint("LEFT", row, "LEFT", 432, 0)' in UI

def test_relationships_get_more_viewport_without_changing_sources_or_behavior():
    assert 'AddInspectorCard(1136, -422, 280, 170)' in UI
    assert 'UI.detailScroll:SetSize(270, 124)' in UI
    assert 'UI.detailScrollChild:SetSize(250, 124)' in UI
    assert 'AddInspectorCard(1136, -602, 280, 206)' in UI
    assert 'UI.historyGraph:SetSize(236, 104)' in UI
    assert 'RenderMarketRecipeContext(item)' in UI
    assert 'RenderCraftDetail(item)' in UI

def test_existing_six_tabs_and_market_filter_semantics_remain():
    tab_block = UI.split("local tabSpecs = {", 1)[1].split("local tabX", 1)[0]
    for key in ['"market"', '"economics"', '"crafts"', '"materials"', '"low"', '"history"']:
        assert key in tab_block
    assert "My Crafts" not in tab_block
    assert 'UI.itemTypeFilter' in UI and 'UI.marketQuickFilters' in UI
    assert 'MM.MarketEngine' not in UI

def test_release_metadata_is_aligned():
    assert f'MM.version = "{MANIFEST["version"]}"' in CORE
    assert f'## Version: {MANIFEST["version"]}' in TOC
    assert MANIFEST["version"] == "0.9.5"
    assert MANIFEST["file_count"] == len(MANIFEST["files"])
