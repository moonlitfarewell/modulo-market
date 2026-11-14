from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns/ModuloMarket"
CORE = (ADDON / "Core.lua").read_text(encoding="utf-8")
THEME = (ADDON / "Theme.lua").read_text(encoding="utf-8")
UI = (ADDON / "MarketUI.lua").read_text(encoding="utf-8")
TOC = (ADDON / "ModuloMarket.toc").read_text(encoding="utf-8")
DATA = (ADDON / "TurnInData.lua").read_text(encoding="utf-8")
README = (ROOT / "README.md").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_and_theme_load_order_align():
    assert 'MM.version = "0.11.0"' in CORE
    assert "## Version: 0.11.0" in TOC
    assert 'version = "0.11.0"' in DATA
    assert MANIFEST["version"] == "0.11.0"
    assert TOC.index("Core.lua") < TOC.index("Theme.lua") < TOC.index("MarketUI.lua")


def test_theme_defaults_preserve_blizzlike_for_existing_savedvariables():
    assert 'theme = "blizzlike"' in THEME
    assert 'if MM.db.theme ~= "modern" then MM.db.theme = "blizzlike" end' in THEME
    assert 'return fallback or { 1, 1, 1, 1 }' in THEME


def test_theme_options_include_requested_appearance_and_palette_choices():
    for label in ["Blizz-like", "Modern", "Dark (grey tone)", "Class (WoW class colour)", "Custom"]:
        assert label in THEME


def test_settings_page_exposes_market_open_button_and_registers_native_fallback():
    assert 'Open Modulo Market (/mm)' in THEME
    assert "MM.MarketUI.Show()" in THEME
    assert "Settings.RegisterCanvasLayoutCategory" in THEME
    assert "InterfaceOptions_AddCategory" in THEME


def test_custom_colour_persists_and_picker_cancel_restores_previous_value():
    assert "MM.db.customAccent = { r = Clamp(r), g = Clamp(g), b = Clamp(b) }" in THEME
    assert "ColorPickerFrame:SetupColorPickerAndShow" in THEME
    assert "cancelFunc = Restore" in THEME


def test_class_palette_uses_current_wow_class_colour():
    assert "CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS" in THEME
    assert 'Theme.SetPalette("class")' not in THEME  # no forced class palette default
    assert 'if mode == "class" then return GetClassAccent() end' in THEME


def test_theme_repaints_existing_and_new_market_surfaces():
    assert "Theme.SetTexture" in UI
    assert "Theme.SetFontColor" in UI
    assert "function UI.ApplyTheme()" in UI
    assert 'SetThemeTexture(row.selectedAccent, "selectedEdge"' in UI
    assert 'SetThemeTexture(header, "panelHeader"' in UI


def test_mm_command_remains_the_existing_market_toggle():
    assert 'SLASH_MODULOMARKET1 = "/mm"' in CORE
    assert "MM.MarketUI.Toggle()" in CORE


def test_no_new_addon_dependencies():
    assert "## Dependencies: Modulo" in TOC
    assert "## OptionalDeps: LibProfessionDB" in TOC
    assert "EllesmereUI" not in TOC and "Polestar" not in TOC


def test_theme_is_cosmetic_and_readme_documents_preserved_behavior():
    for term in ["presentation-only", "market data", "calculations", "scanning"]:
        assert term.lower() in README.lower()


def test_theme_lua_harness():
    import shutil
    lua = shutil.which("texlua") or shutil.which("lua")
    if not lua:
        raise AssertionError("texlua/lua is required for the theme harness")
    result = subprocess.run(
        [lua, str(ROOT / "tests/theme_0_11_0_harness.lua"), str(ADDON / "Theme.lua")],
        check=True, capture_output=True, text=True,
    )
    assert "12 checks passed" in result.stdout


def test_manifest_inventory_is_exact():
    actual = sorted(
        str(p.relative_to(ROOT)).replace("\\", "/")
        for p in ROOT.rglob("*")
        if p.is_file() and ".git" not in p.parts and "__pycache__" not in p.parts
        and p.suffix != ".pyc" and ".pytest_cache" not in p.parts
    )
    assert MANIFEST["files"] == actual
    assert MANIFEST["file_count"] == len(actual)
