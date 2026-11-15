from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns/ModuloMarket"
THEME = (ADDON / "Theme.lua").read_text(encoding="utf-8")
CORE = (ADDON / "Core.lua").read_text(encoding="utf-8")
TOC = (ADDON / "ModuloMarket.toc").read_text(encoding="utf-8")


def test_native_vertical_settings_replace_custom_canvas_panel():
    assert "Settings.RegisterVerticalLayoutCategory" in THEME
    assert "Settings.RegisterProxySetting" in THEME
    assert "Settings.CreateDropdown" in THEME
    assert "Settings.RegisterCanvasLayoutCategory" not in THEME
    assert "Settings.RegisterAddOnCategory(category)" in THEME


def test_all_appearance_choices_and_actions_remain_available():
    for value in ["blizzlike", "modern", "classic", "dark", "class", "custom"]:
        assert value in THEME
    for label in ["Blizz-like window", "Modern window", "Classic gold", "Dark grey", "Class colour", "Custom colour"]:
        assert label in THEME
    for action in ["Open Market (/mm)", "Open Browse Scan / Snapshot", "Reset window position"]:
        assert action in THEME


def test_custom_accent_values_remain_persisted_and_independent():
    assert "blizzlikeCustomAccent" in THEME
    assert "customAccent" in THEME
    assert "SetBlizzlikeCustomAccent" in THEME
    assert "SetCustomAccent" in THEME
    assert "ColorPickerFrame:SetupColorPickerAndShow" in THEME
    assert "cancelFunc = Restore" in THEME
    assert '"Choose custom colour"' in THEME
    assert 'function() return Theme.GetBlizzlikeStyle() == "custom" end' in THEME
    assert 'function() return Theme.GetModernPalette() == "custom" end' in THEME


def test_child_styles_are_parented_to_master_appearance():
    assert 'SetParent(blizzlikeInitializer, appearanceInitializer' in THEME
    assert 'SetParent(modernInitializer, appearanceInitializer' in THEME
    assert 'Theme.GetTheme() == "blizzlike"' in THEME
    assert 'Theme.GetTheme() == "modern"' in THEME


def test_child_style_labels_are_parallel_and_controls_are_short():
    assert '"Blizz-like style"' in THEME
    assert '"Modern style"' in THEME
    assert '"Blizz-like appearance"' not in THEME
    assert '"Modern colour palette"' not in THEME
    for label in ["Choose custom colour", "Open Market (/mm)", "Open Browse Scan / Snapshot", "Reset window position"]:
        assert label in THEME


def test_version_and_load_order_remain_consistent():
    assert 'MM.version = "0.12.11"' in CORE
    assert "## Version: 0.12.11" in TOC
    assert TOC.index("Theme.lua") < TOC.index("MarketUI.lua")


def test_native_settings_lua_harness():
    lua = shutil.which("texlua") or shutil.which("lua")
    if not lua:
        raise AssertionError("texlua/lua is required for the native settings harness")
    result = subprocess.run(
        [lua, str(ROOT / "tests/settings_0_12_11_harness.lua"), str(ADDON / "Theme.lua")],
        check=True, capture_output=True, text=True,
    )
    assert "20 checks passed" in result.stdout
