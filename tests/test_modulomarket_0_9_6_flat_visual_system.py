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


def test_title_region_uses_native_template_geometry_without_extra_surfaces():
    assert 'CreateFrame("Frame", "ModuloMarketMainFrame", UIParent, "BasicFrameTemplateWithInset")' in UI
    assert 'frame.TitleText:SetText("Modulo Market")' in UI
    assert "frame.TitleBg:SetHeight(" not in UI
    assert "UI.titleStripBorder" not in UI
    assert "frame:SetSize(1460, 866)" in UI
    assert "local contentShift" not in UI
    assert "(screenHeight - 40) / 866" in UI


def test_all_shared_borders_are_flat_single_pixel_outlines_not_embossed_bevels():
    helper = UI.split("local function AddBevelBorder", 1)[1].split("local function ApplyMarketButtonSkin", 1)[0]
    assert "topShadow" not in helper
    assert "bottomShade" not in helper
    assert "cornerTL" not in helper
    assert "thick" not in helper
    assert "top = edge(x, top, width, 1)" in helper
    assert "bottom = edge(x, top - height + 1, width, 1)" in helper
    assert "left = edge(x, top, 1, height)" in helper
    assert "right = edge(x + width - 1, top, 1, height)" in helper


def test_major_panels_and_headers_no_longer_use_fake_bevel_highlights():
    assert "local function AddPanelInnerEdge(x, y, width, height)" in UI
    assert "local sheen = frame:CreateTexture" not in UI
    assert "local inner = frame:CreateTexture" not in UI
    assert "local headerGlow = frame:CreateTexture" not in UI
    assert "local upper = frame:CreateTexture" not in UI


def test_tab_gap_remains_zero_and_tab_accents_are_preserved():
    assert "tabX = tabX + width" in UI
    assert "tabX = tabX + width + 4" not in UI
    assert "button.marketTop = button:CreateTexture" in UI
    assert "button.marketBottom = button:CreateTexture" in UI
    assert "button.selectedMark:SetHeight(3)" in UI
