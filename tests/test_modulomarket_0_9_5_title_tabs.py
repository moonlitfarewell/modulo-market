from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_align():
    assert 'MM.version = "0.9.5"' in CORE
    assert "## Version: 0.9.5" in TOC
    assert MANIFEST["version"] == "0.9.5"


def test_native_title_background_is_explicitly_reanchored_and_resized():
    assert "frame.TitleBg:ClearAllPoints()" in UI
    assert 'frame.TitleBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -5)' in UI
    assert 'frame.TitleBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -5)' in UI
    assert "frame.TitleBg:SetHeight(44)" in UI
    assert 'frame.TitleText:SetPoint("CENTER", frame, "TOP", 0, -27)' in UI
    assert 'frame.TitleText:SetSize(320, 28)' in UI


def test_content_gets_room_below_title_without_moving_native_close_button():
    assert "frame:SetSize(1460, 882)" in UI
    assert "local contentShift = 16" in UI
    assert "local isCloseButton = child == frame.CloseButton" in UI
    assert "region ~= frame.TitleBg and region ~= frame.TitleText" in UI


def test_tabs_are_edge_to_edge_without_vertical_separator_gap():
    assert "tabX = tabX + width" in UI
    assert "tabX = tabX + width + 4" not in UI
    assert 'button.marketLeft = button:CreateTexture' not in UI
    assert 'button.marketRight = button:CreateTexture' not in UI
    assert 'button.marketTop = button:CreateTexture' in UI
    assert 'button.marketBottom = button:CreateTexture' in UI
    assert 'button.selectedMark:SetHeight(3)' in UI
