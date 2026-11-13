from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())

def test_main_panels_have_inset_finish_without_geometry_changes():
    assert "local function AddPanelInnerEdge(x, y, width, height)" in UI
    assert "AddPanelInnerEdge(18, -158, 260, 650)" in UI
    assert "AddPanelInnerEdge(286, -158, 834, 650)" in UI
    assert "AddPanelInnerEdge(1126, -158, 300, 650)" in UI
    assert "cap:SetSize(2, 23)" in UI

def test_tabs_have_clear_active_and_inactive_visual_states():
    assert 'button.background:SetColorTexture(0.28, 0.185, 0.060, 1)' in UI
    assert 'button.background:SetColorTexture(0.022, 0.020, 0.018, 0.99)' in UI
    tab_block = UI.split("local tabSpecs = {", 1)[1].split("local tabX", 1)[0]
    assert tab_block.count('{"') == 0
    for key in ['"market"', '"economics"', '"crafts"', '"materials"', '"low"', '"history"']:
        assert key in tab_block
    assert "My Crafts" not in tab_block

def test_table_finish_changes_are_visual_only():
    assert 'tableHeaderBand:SetColorTexture(0.105, 0.078, 0.038, 0.88)' in UI
    assert 'row.selectedWash:SetColorTexture(0.42, 0.29, 0.065, 0.36)' in UI
    assert 'row:SetSize(796, UI.rowHeight)' in UI

def test_release_metadata_is_aligned():
    assert 'MM.version = "0.8.8"' in CORE
    assert '## Version: 0.8.8' in TOC
    assert MANIFEST["version"] == "0.8.8"
