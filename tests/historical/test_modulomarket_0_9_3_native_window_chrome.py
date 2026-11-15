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


def test_native_blizzard_frame_template_is_preserved():
    assert 'CreateFrame("Frame", "ModuloMarketMainFrame", UIParent, "BasicFrameTemplateWithInset")' in UI
    assert "Use Blizzard's native frame chrome and title strip." in UI
    assert 'for _, chromeKey in ipairs({ "NineSlice", "Inset", "TitleBg", "TopTileStreaks" })' not in UI


def test_custom_title_plaque_is_removed_and_title_uses_native_title_strip():
    assert "local titlePlate =" not in UI
    assert "titleInner" not in UI
    assert "titleAccentLeft" not in UI
    assert "titleAccentRight" not in UI
    assert 'frame.TitleText:SetPoint("CENTER", frame, "TOP", 0, -33)' not in UI
    assert 'frame.TitleText:SetText("Modulo Market")' in UI
    assert 'frame.TitleText:SetText("Modulo Market")' in UI


def test_only_the_decorative_outer_bevel_is_omitted():
    assert 'AddBevelBorder(frame, 5, -5, 1450, 840, "outer", "OVERLAY")' not in UI
    assert 'AddBevelBorder(frame, 18, -30, 1424, 78, "panel", "BORDER")' not in UI
    assert 'frame:SetSize(1460, 866)' in UI
    assert 'AddBevelBorder(frame, 560, -2, 340, 36, "plaque", "BORDER")' not in UI
