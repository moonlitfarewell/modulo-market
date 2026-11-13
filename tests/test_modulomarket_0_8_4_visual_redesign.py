from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_shared_dark_foundry_primitives_cover_all_five_visual_areas():
    assert "local function AddBevelBorder(parent, x, top, width, height, style, layer)" in UI
    for style in ["outer", "plaque", "panel", "card", "tab", "control", "button"]:
        assert f"{style} = {{ dark =" in UI
    assert "local function ApplyMarketButtonSkin(button, style)" in UI
    assert "local function AddInsetSurface(parent, x, top, width, height, color)" in UI
    assert 'AddBevelBorder(frame, 5, -5, 1450, 840, "outer", "OVERLAY")' in UI


def test_header_uses_layered_plaque_and_real_scan_state_not_fabricated_progress():
    assert 'titlePlate:SetSize(340, 36)' in UI
    assert 'AddBevelBorder(frame, 560, -2, 340, 36, "plaque", "BORDER")' in UI
    assert 'AddInsetSurface(frame, 18, -30, 1424, 78' in UI
    assert 'UI.scanStateLabel = AddLabel(frame, "Scan: Idle"' in UI
    assert "state.active" in UI and "state.pendingConfirmation" in UI
    assert "Scan: 0%" not in UI
    assert "progressPercent" not in UI


def test_navigation_keeps_six_tabs_and_adds_state_aware_gold_bevels():
    tab_block = UI.split("local tabSpecs = {", 1)[1].split("local tabX", 1)[0]
    for key in ['"market"', '"economics"', '"crafts"', '"materials"', '"low"', '"history"']:
        assert key in tab_block
    assert "button.marketTop" in UI
    assert "button.marketBottom" in UI
    assert "button.marketLeft" in UI
    assert "button.marketRight" in UI
    assert "0.98, 0.76, 0.30" in UI
    assert "My Crafts" not in tab_block


def test_filters_keep_existing_controls_and_gain_shared_control_skin():
    assert "ApplyMarketButtonSkin(dropdown, \"control\")" in UI
    assert "dropdown.arrow:SetVertexColor(0.95, 0.72, 0.28)" in UI
    assert 'UI.roleLabel = AddLabel(frame, "Item role"' in UI
    assert 'UI.itemTypeLabel = AddLabel(frame, "Item Types"' in UI
    assert 'UI.marketQuickFilterHeading = AddLabel(frame, "OPTIONS"' in UI
    assert 'UI.dataHeading = AddLabel(frame, "Data"' in UI
    assert 'AddInsetSurface(frame, 26, -620, 244, 176' in UI


def test_market_table_gets_a_header_band_and_selected_row_accents_without_geometry_change():
    assert "local tableHeaderBand = frame:CreateTexture" in UI
    assert "row.selectedWash" in UI
    assert "row.selectedAccent" in UI
    assert "row.selectedTop" in UI
    assert "row.selectedBottom" in UI
    assert "rowHeight = 24" in UI
    assert "visibleCount = 25" in UI


def test_inspector_cards_and_icon_mount_are_visually_framed():
    assert "AddBevelBorder(frame, x, top, width, height, \"card\", \"OVERLAY\")" in UI
    assert "AddInsetSurface(frame, 1139, -201, 54, 54" in UI
    assert "UI.detailIcon:SetSize(48, 48)" in UI
    assert 'AddInspectorCard(1136, -270, 280, 144)' in UI
    assert 'AddInspectorCard(1136, -422, 280, 120)' in UI
    assert 'AddInspectorCard(1136, -552, 280, 256)' in UI


def test_visual_redesign_preserves_behavioral_boundaries_and_release_alignment():
    assert "MM.MarketEngine" not in UI
    assert "function UI.RefreshActions()" in UI
    assert "function UI.StartViewBuild()" in UI
    assert "function UI.RenderRows()" in UI
    assert 'MM.version = "0.8.5"' in CORE
    assert '## Version: 0.8.5' in TOC
    assert MANIFEST["version"] == "0.8.5"
    assert "MODULOMARKET-RUNTIME-AUDIT-0.8.4.md" in MANIFEST["files"]
    assert "tests/test_modulomarket_0_8_4_visual_redesign.py" in MANIFEST["files"]
    assert MANIFEST["file_count"] == len(MANIFEST["files"])
