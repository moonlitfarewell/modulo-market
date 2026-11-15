from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_native_template_chrome_is_restored_without_custom_outer_bevel():
    assert 'CreateFrame("Frame", "ModuloMarketMainFrame", UIParent, "BasicFrameTemplateWithInset")' in UI
    assert 'for _, chromeKey in ipairs({ "NineSlice", "Inset", "TitleBg", "TopTileStreaks" }) do' not in UI
    assert 'frame.TitleText:SetPoint("CENTER", frame, "TOP", 0, -33)' not in UI
    assert 'frame.TitleText:SetText("Modulo Market")' in UI
    assert 'frame.TitleText:SetText("Modulo Market")' in UI


def test_custom_outer_perimeter_bevel_is_removed():
    assert 'AddBevelBorder(frame, 5, -5, 1450, 840, "outer", "OVERLAY")' not in UI


def test_inner_panel_and_control_borders_are_preserved():
    assert 'AddPanelInnerEdge(18, -158, 260, 650)' in UI
    assert 'AddPanelInnerEdge(286, -158, 834, 650)' not in UI
    assert 'local centerPanel = frame:CreateTexture' not in UI
    assert 'AddPanelInnerEdge(1126, -158, 300, 650)' in UI
    assert 'AddBevelBorder(frame, 18, -112, 1424, 34, "panel", "BORDER")' in UI
    assert 'UI.tableHeaderBorder' not in UI
    assert 'UI.tableColumnGuides' not in UI
