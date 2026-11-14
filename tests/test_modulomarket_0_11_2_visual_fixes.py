from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns/ModuloMarket"
CORE = (ADDON / "Core.lua").read_text(encoding="utf-8")
TOC = (ADDON / "ModuloMarket.toc").read_text(encoding="utf-8")
DATA = (ADDON / "TurnInData.lua").read_text(encoding="utf-8")
MARKET = (ADDON / "MarketUI.lua").read_text(encoding="utf-8")
MODERN = (ADDON / "ModernUI.lua").read_text(encoding="utf-8")
THEME = (ADDON / "Theme.lua").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_0_11_2_release_versions_align():
    assert 'MM.version = "0.11.2"' in CORE
    assert "## Version: 0.11.2" in TOC
    assert 'version = "0.11.2"' in DATA
    assert MANIFEST["version"] == "0.11.2"


def test_modern_toolbar_and_dropdowns_use_real_textures_not_unsupported_glyphs():
    assert 'UI-RefreshButton' in MODERN
    assert 'UI-Searchbox-Icon' in MODERN
    assert 'UI-ScrollBar-ScrollDownButton-Up' in MODERN
    assert '"↻  Update Full Market"' not in MODERN
    assert '"⌕  Browse Scan"' not in MODERN
    assert '"▾  "' not in MODERN


def test_modern_and_blizzlike_checkbox_states_have_visible_contrast():
    assert "check.outline = {}" in MODERN
    assert 'Paint(edge, "borderStrong"' in MODERN
    assert "function UI.ApplyCheckboxContrast()" in MARKET
    assert "GetNormalTexture" in MARKET and "GetCheckedTexture" in MARKET
    assert "ApplyCheckboxContrast()" in THEME
    assert "UI.ApplyCheckboxContrast()" in MARKET


def test_modern_restores_existing_profession_status_row_markers():
    assert "function UI.GetModernCraftMarker(itemID)" in MARKET
    assert "UI.GetModernCraftMarker(item.itemID)" in MODERN
    assert "row.statusMarker:SetColorTexture" in MODERN
    assert 'row.statusMarker:SetWidth(3)' in MODERN


def test_materials_filter_panel_no_longer_places_hint_below_panel():
    assert "Modern.filterHint = nil" in MODERN
    assert 'Label(left, "Filters use the same market catalogue' not in MODERN


def test_turnin_required_bundles_use_structured_scrollable_breakdown():
    assert "function Modern.RenderBundleBreakdown(item)" in MODERN
    assert "Modern.bundleScroll = CreateFrame(\"ScrollFrame\"" in MODERN
    assert "Modern.bundleChild:SetHeight" in MODERN
    assert 'AddLine("MATERIAL OPTIONS · CHOOSE ONE"' in MODERN
    assert '" · BEST VALUE"' in MODERN
    assert '"Unit " .. unit .. " / ea  ·  Line " .. line' in MODERN
    assert 'Modern.relationshipText:SetText(table.concat(d.bundleLines' not in MODERN


def test_theme_harness_and_modern_visual_harness():
    import shutil
    import subprocess
    lua = shutil.which("texlua") or shutil.which("lua")
    assert lua, "texlua/lua is required for runtime-model harnesses"
    theme = subprocess.run(
        [lua, str(ROOT / "tests/theme_0_11_2_harness.lua"), str(ADDON / "Theme.lua")],
        check=True, capture_output=True, text=True,
    )
    assert "19 checks passed" in theme.stdout
    modern = subprocess.run(
        [lua, str(ROOT / "tests/modern_ui_0_11_2_harness.lua"), str(ADDON / "ModernUI.lua")],
        check=True, capture_output=True, text=True,
    )
    assert "24 checks passed" in modern.stdout
