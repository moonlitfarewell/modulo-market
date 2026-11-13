from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_align():
    assert 'MM.version = "0.9.2"' in CORE
    assert "## Version: 0.9.2" in TOC
    assert MANIFEST["version"] == "0.9.2"


def test_outer_template_chrome_is_hidden_without_removing_template_controls():
    assert 'CreateFrame("Frame", "ModuloMarketMainFrame", UIParent, "BasicFrameTemplateWithInset")' in UI
    assert 'for _, chromeKey in ipairs({ "NineSlice", "Inset", "TitleBg", "TopTileStreaks" }) do' in UI
    assert 'if chrome and chrome.Hide then chrome:Hide() end' in UI
    assert 'frame.TitleText:SetText("Modulo Market")' in UI


def test_custom_outer_perimeter_bevel_is_removed():
    assert 'AddBevelBorder(frame, 5, -5, 1450, 840, "outer", "OVERLAY")' not in UI


def test_inner_panel_and_control_borders_are_preserved():
    assert 'AddPanelInnerEdge(18, -158, 260, 650)' in UI
    assert 'AddPanelInnerEdge(286, -158, 834, 650)' in UI
    assert 'AddPanelInnerEdge(1126, -158, 300, 650)' in UI
    assert 'AddBevelBorder(frame, 18, -112, 1424, 34, "panel", "BORDER")' in UI
    assert 'AddBevelBorder(frame, 302, -218, 802, 34, "control", "BORDER")' in UI
