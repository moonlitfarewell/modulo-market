from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_align():
    assert 'MM.version = "0.9.4"' in CORE
    assert "## Version: 0.9.4" in TOC
    assert MANIFEST["version"] == "0.9.4"


def test_native_title_strip_height_and_title_fit():
    assert 'if frame.TitleBg and frame.TitleBg.SetHeight then frame.TitleBg:SetHeight(38) end' in UI
    assert 'frame.TitleText:SetPoint("CENTER", frame, "TOP", 0, -19)' in UI
    assert 'frame.TitleText:SetSize(280, 24)' in UI
    assert 'frame.TitleText:SetText("Modulo Market")' in UI


def test_tab_vertical_side_strokes_are_removed():
    assert 'button.marketLeft = button:CreateTexture' not in UI
    assert 'button.marketRight = button:CreateTexture' not in UI
    assert 'button.marketTop = button:CreateTexture' in UI
    assert 'button.marketBottom = button:CreateTexture' in UI
    assert 'button.selectedMark:SetHeight(3)' in UI


def test_internal_panel_borders_and_outer_window_design_are_preserved():
    assert 'AddPanelInnerEdge(18, -158, 260, 650)' in UI
    assert 'AddPanelInnerEdge(286, -158, 834, 650)' in UI
    assert 'AddPanelInnerEdge(1126, -158, 300, 650)' in UI
    assert 'AddBevelBorder(frame, 18, -112, 1424, 34, "panel", "BORDER")' in UI
    assert 'AddBevelBorder(frame, 5, -5, 1450, 840, "outer", "OVERLAY")' not in UI
