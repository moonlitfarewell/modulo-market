from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_align():
    assert 'MM.version = "0.9.8"' in CORE
    assert "## Version: 0.9.8" in TOC
    assert MANIFEST["version"] == "0.9.8"


def test_native_blizzard_frame_owns_title_and_nineslice_geometry():
    assert 'CreateFrame("Frame", "ModuloMarketMainFrame", UIParent, "BasicFrameTemplateWithInset")' in UI
    assert 'frame.TitleText:SetText("Modulo Market")' in UI
    assert "frame.TitleBg:ClearAllPoints()" not in UI
    assert "frame.TitleBg:SetHeight(" not in UI
    assert "UI.titleStripBorder" not in UI
    assert "AddInsetSurface(frame, 18, -30, 1424, 78" not in UI


def test_content_uses_original_frame_coordinates_without_post_shift():
    assert "frame:SetSize(1460, 866)" in UI
    assert "(screenHeight - 40) / 866" in UI
    assert "local contentShift" not in UI
    assert "Shift only addon-owned direct children" not in UI
    assert 'UI.metadata = AddLabel(frame, "Loading market data…", 30, -38' in UI
    assert 'UI.filterHeading = AddLabel(frame, "Filters — All Items", 30, -166' in UI


def test_tabs_remain_flush_and_keep_selected_state():
    assert "tabX = tabX + width" in UI
    assert "tabX = tabX + width + 4" not in UI
    assert "button.selectedMark:SetHeight(3)" in UI


def test_panel_headers_have_one_separator_and_no_metal_end_caps():
    block = UI.split("local function AddPanelHeader", 1)[1].split("AddPanelHeader(18", 1)[0]
    assert "local lowerRule" not in block
    assert 'for _, side in ipairs({"LEFT", "RIGHT"})' not in block
    assert "local rule" in block
    assert "plate:SetColorTexture(0.085, 0.073, 0.052, 0.78)" in block


def test_button_skin_is_not_red_and_keeps_native_interaction_feedback():
    block = UI.split("local function ApplyMarketButtonSkin", 1)[1].split("local function AddInsetSurface", 1)[0]
    assert "0.16, 0.025, 0.014" not in block
    assert "normal:SetAlpha(0.30)" in block
    assert "pushed:SetAlpha(0.62)" in block
    assert "highlight:SetAlpha(0.34)" in block


def test_dropdown_popup_lifecycle_and_market_logic_remain_present():
    assert "function UI.CloseDropdownMenus" in UI
    assert "UI.CloseDropdownMenus()" in UI
    assert "function MM.Replicate" not in UI  # scanner/replication ownership stays outside the UI file
