from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_042_version_agreement():
    assert 'MM.version = "0.6.1"' in CORE
    assert re.search(r"^## Version: 0\.6\.1$", TOC, re.M)
    assert MANIFEST["version"] == "0.6.1"


def test_042_opacity_applies_to_whole_window():
    assert "frame:SetAlpha(alpha)" in UI
    assert "whole-window opacity" in UI


def test_042_dropdowns_use_click_driven_local_popup():
    assert 'CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")' in UI
    assert "dropdown.ToggleMenu = function()" in UI
    assert "optionButton:SetScript(\"OnClick\"" in UI
    assert "UIDropDownMenu_Initialize(dropdown" not in UI


def test_042_visual_and_dropdown_fixes_are_preserved_in_050():
    assert "frame:SetAlpha(alpha)" in UI
    assert "dropdown.ToggleMenu = function()" in UI
    assert "Only recipes you have learned" in UI
    assert "All recipe candidates" in UI
    assert "function UI.RenderHistory()" in UI


def test_042_auction_house_launcher_is_header_anchored():
    assert 'button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -42, -34)' in UI
