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


def test_native_title_background_remains_template_owned():
    assert "frame.TitleBg:ClearAllPoints()" not in UI
    assert "frame.TitleBg:SetHeight(" not in UI
    assert 'frame.TitleText:SetText("Modulo Market")' in UI


def test_native_template_title_and_original_content_coordinates_are_preserved():
    assert "frame:SetSize(1460, 866)" in UI
    assert "local contentShift" not in UI
    assert 'UI.metadata = AddLabel(frame, "Loading market data…", 30, -38' in UI
    assert "frame.CloseButton" not in UI.split("local contentShift", 1)[-1]


def test_tabs_are_edge_to_edge_without_vertical_separator_gap():
    assert "tabX = tabX + width" in UI
    assert "tabX = tabX + width + 4" not in UI
    assert 'button.marketLeft = button:CreateTexture' not in UI
    assert 'button.marketRight = button:CreateTexture' not in UI
    assert 'button.marketTop = button:CreateTexture' in UI
    assert 'button.marketBottom = button:CreateTexture' in UI
    assert 'button.selectedMark:SetHeight(3)' in UI
