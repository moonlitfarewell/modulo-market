from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns/ModuloMarket"
CORE = (ADDON / "Core.lua").read_text(encoding="utf-8")
THEME = (ADDON / "Theme.lua").read_text(encoding="utf-8")
UI = (ADDON / "MarketUI.lua").read_text(encoding="utf-8")
MODERN = (ADDON / "ModernUI.lua").read_text(encoding="utf-8")
TOC = (ADDON / "ModuloMarket.toc").read_text(encoding="utf-8")
DATA = (ADDON / "TurnInData.lua").read_text(encoding="utf-8")
README = (ROOT / "README.md").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_and_two_window_load_order_align():
    assert 'MM.version = "0.12.8"' in CORE
    assert "## Version: 0.12.8" in TOC
    assert 'version = "0.12.8"' in DATA
    assert MANIFEST["version"] == "0.12.8"
    assert TOC.index("Core.lua") < TOC.index("Theme.lua") < TOC.index("MarketUI.lua") < TOC.index("ModernUI.lua") < TOC.index("Diagnostics.lua")


def test_legacy_saved_theme_migrates_to_blizzlike_style_without_losing_palette():
    assert 'MM.db.marketAppearance = "blizzlike"' in THEME
    assert 'if MM.db.theme == "modern" then' in THEME
    assert 'MM.db.blizzlikeStyle = (oldPalette == "class" or oldPalette == "custom") and oldPalette or "dark"' in THEME
    assert "MM.db.blizzlikeCustomAccent = CopyColor(MM.db.customAccent or defaults.customAccent)" in THEME
    assert 'MM.db.theme = MM.db.marketAppearance' in THEME


def test_blizzlike_keeps_classic_dark_class_and_custom_treatments():
    for label in ["Classic gold", "Dark grey", "Class colour", "Custom colour"]:
        assert label in THEME
    for key in ["classic", "dark", "class", "custom"]:
        assert key in THEME
    assert "function Theme.SetBlizzlikeStyle" in THEME
    assert "function Theme.SetBlizzlikeCustomAccent" in THEME


def test_modern_has_separate_dark_class_custom_palette():
    for label in ["Dark (grey tone)", "Class colour", "Custom colour"]:
        assert label in THEME
    assert "function Theme.GetModernColor" in THEME
    assert "function Theme.GetModernAccent" in THEME
    assert "function Theme.SetCustomAccent" in THEME


def test_settings_page_exposes_appearance_selector_and_market_launcher():
    assert 'Open Modulo Market (/mm)' in THEME
    assert "MM.MarketUI.Show()" in THEME
    assert 'label = "Blizz-like window", value = "blizzlike"' in THEME
    assert 'label = "Modern window", value = "modern"' in THEME
    assert "Settings.RegisterCanvasLayoutCategory" in THEME
    assert "InterfaceOptions_AddCategory" in THEME


def test_modern_is_a_separate_window_not_a_recolour_of_legacy_window():
    assert 'CreateFrame("Frame", "ModuloMarketModernFrame", UIParent)' in MODERN
    assert 'CreateFrame("Frame", "ModuloMarketMainFrame", UIParent, "BasicFrameTemplateWithInset")' in UI
    assert "UI.PrepareModernBackend()" in MODERN
    assert "function UI.GetModernState()" in UI
    assert "function UI.GetModernDetails()" in UI
    assert "UI.SetTab(spec.key)" in MODERN
    assert "UI.SelectItem(self.item)" in MODERN
    assert "UI.SetSearch(self:GetText())" in MODERN


def test_modern_window_has_independent_chrome_navigation_panels_and_row_pool():
    for token in ["MODULO MARKET", "ALL ITEMS", "ECONOMICS", "CRAFTS", "MATERIALS", "TURN-INS", "HISTORY"]:
        assert token in MODERN
    for token in ["FILTERS", "INSPECTED ITEM", "MARKET INFORMATION", "RELATIONSHIPS", "MARKET HISTORY"]:
        assert token in MODERN
    assert "Modern.rows[i] = row" in MODERN
    assert "function Modern.ApplyTheme()" in MODERN
    assert "function Modern.Toggle()" in MODERN


def test_both_presentations_share_existing_market_state_and_scanner_actions():
    assert "function UI.SetTab(tab)" in UI
    assert "function UI.SetSearch(value)" in UI
    assert "function UI.SetCraftingScope(value)" in UI
    assert "function UI.SelectItem(item)" in UI
    assert "function UI.TriggerFullScan()" in UI
    assert "function UI.TriggerBrowseScan()" in UI
    assert "UI.TriggerFullScan()" in MODERN
    assert "UI.TriggerBrowseScan()" not in MODERN
    assert 'Open Browse Scan / Snapshot Debug' in THEME
    assert "UI.GetModernState()" in MODERN
    assert "Modern.craftingScopeDropdown" in MODERN
    assert "Modern.dataText" in MODERN


def test_mm_command_routes_to_selected_presentation_and_blizzlike_remains_available():
    assert 'SLASH_MODULOMARKET1 = "/mm"' in CORE
    assert "function UI.ToggleBlizzlike()" in UI
    assert "function UI.ShowBlizzlike()" in UI
    assert "MM.ModernUI.Toggle()" in UI
    assert "MM.ModernUI.Show()" in UI


def test_custom_colours_persist_independently_for_both_presentations():
    assert "MM.db.customAccent = { r = Clamp(r), g = Clamp(g), b = Clamp(b) }" in THEME
    assert "MM.db.blizzlikeCustomAccent = { r = Clamp(r), g = Clamp(g), b = Clamp(b) }" in THEME
    assert "ColorPickerFrame:SetupColorPickerAndShow" in THEME
    assert "cancelFunc = Restore" in THEME


def test_no_new_addon_dependencies():
    assert "## Dependencies: Modulo" in TOC
    assert "## OptionalDeps: LibProfessionDB" in TOC
    assert "EllesmereUI" not in TOC and "Polestar" not in TOC


def test_theme_is_cosmetic_and_readme_documents_shared_market_behavior():
    for term in ["same market data", "calculations", "scanning", "Blizz-like", "Modern"]:
        assert term.lower() in README.lower()


def test_theme_lua_harness():
    import shutil
    lua = shutil.which("texlua") or shutil.which("lua")
    if not lua:
        raise AssertionError("texlua/lua is required for the theme harness")
    result = subprocess.run(
        [lua, str(ROOT / "tests/theme_0_11_2_harness.lua"), str(ADDON / "Theme.lua")],
        check=True, capture_output=True, text=True,
    )
    assert "19 checks passed" in result.stdout


def test_modern_ui_lua_harness():
    import shutil
    lua = shutil.which("texlua") or shutil.which("lua")
    if not lua:
        raise AssertionError("texlua/lua is required for the Modern UI harness")
    result = subprocess.run(
        [lua, str(ROOT / "tests/modern_ui_0_11_2_harness.lua"), str(ADDON / "ModernUI.lua")],
        check=True, capture_output=True, text=True,
    )
    assert "35 checks passed" in result.stdout


def test_manifest_inventory_is_exact():
    actual = sorted(
        str(p.relative_to(ROOT)).replace("\\", "/")
        for p in ROOT.rglob("*")
        if p.is_file() and ".git" not in p.parts and "__pycache__" not in p.parts
        and p.suffix != ".pyc" and ".pytest_cache" not in p.parts
    )
    assert MANIFEST["files"] == actual
    assert MANIFEST["file_count"] == len(actual)
