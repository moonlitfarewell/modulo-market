from pathlib import Path
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns/ModuloMarket"
CORE = (ADDON / "Core.lua").read_text(encoding="utf-8")
TOC = (ADDON / "ModuloMarket.toc").read_text(encoding="utf-8")
DATA = (ADDON / "TurnInData.lua").read_text(encoding="utf-8")
MARKET = (ADDON / "MarketUI.lua").read_text(encoding="utf-8")
REPLICATE = (ADDON / "Replicate.lua").read_text(encoding="utf-8")
MODERN = (ADDON / "ModernUI.lua").read_text(encoding="utf-8")
THEME = (ADDON / "Theme.lua").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_0_11_3_release_metadata_aligns():
    assert 'MM.version = "0.12.3"' in CORE
    assert "## Version: 0.12.3" in TOC
    assert 'version = "0.12.3"' in DATA
    assert MANIFEST["version"] == "0.12.3"


def test_single_scan_button_progresses_through_prepare_confirm_and_cancel():
    assert 'UI.scanButton = AddButton(frame, "Scan Market"' in MARKET
    assert 'if state.pendingConfirmation then MM.Replicate.Confirm() else MM.Replicate.Prepare() end' in MARKET
    assert 'UI.cancelButton = AddButton(frame, "Cancel"' in MARKET
    assert 'UI.scanButton:SetText("Confirm Scan")' in MARKET
    assert 'UI.scanButton:SetText("Scan Market")' in MARKET
    assert 'function UI.TriggerCancelScan()' in MARKET
    assert 'MM.ModernUI.RefreshScanActions(state)' in MARKET
    assert 'function Modern.RefreshScanActions(state)' in MODERN
    assert 'Modern.updateButton.label:SetText(text)' in MODERN


def test_browse_snapshot_debug_is_not_a_visible_main_window_action():
    assert 'Open Browse Scan / Snapshot Debug' in THEME
    assert 'if MM.Scanner and MM.Scanner.Toggle then MM.Scanner.Toggle() end' in THEME
    assert 'local browse = FlatButton(frame, "Browse Scan"' not in MODERN
    assert 'UI.browseButton:Hide()' in MARKET


def test_modern_search_checkbox_and_dropdown_use_custom_affordances():
    assert 'CreateFrame("EditBox", nil, left)' in MODERN
    assert 'InputBoxTemplate' not in MODERN
    assert 'Textures\\\\search.tga' in MODERN
    assert 'Textures\\\\chevron-down.tga' in MODERN
    assert 'Textures\\\\check.tga' in MODERN
    assert 'options[1] and tostring(options[1].text)' in MODERN
    assert 'labelText == "PROFESSION" and "All professions"' in MODERN


def test_history_is_limited_to_three_latest_snapshots_and_modern_chart_is_bounded():
    assert 'local firstSnapshot = math.max(1, #history - 2)' in MARKET
    assert 'while #history > 3 do table.remove(history, 1) end' in REPLICATE
    assert 'for i = 1, 3 do' in MODERN
    assert '3 * 86400' not in MARKET
    assert 'if stamp > 0 and found and tonumber(found.price)' in MARKET
    assert 'math.min(18, (tonumber(source.height) or 4) * 0.22)' in MODERN
    assert 'label:SetPoint("BOTTOM", bar, "TOP", 0, 2)' in MODERN


def test_custom_tga_assets_exist_and_are_valid_rgba_files():
    from PIL import Image
    for name in ["refresh", "search", "chevron-down", "close", "check", "cancel"]:
        path = ADDON / "Textures" / f"{name}.tga"
        assert path.is_file()
        with Image.open(path) as image:
            assert image.format == "TGA"
            assert image.mode == "RGBA"
            assert image.size == (64, 64)


def test_scan_flow_lua_harness():
    lua = shutil.which("texlua") or shutil.which("lua")
    assert lua, "texlua/lua is required for scan state-machine harness"
    result = subprocess.run(
        [lua, str(ROOT / "tests/replicate_scan_flow_0_11_3_harness.lua"), str(ADDON / "Replicate.lua")],
        check=True, capture_output=True, text=True,
    )
    assert "8 scan flow checks passed" in result.stdout
