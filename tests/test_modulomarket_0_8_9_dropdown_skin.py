from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")


def test_control_skin_suppresses_legacy_red_template_art():
    assert 'normal:SetAlpha(0.30)' in UI
    assert 'pushed:SetAlpha(0.62)' in UI
    assert 'highlight:SetAlpha(0.34)' in UI
    assert 'pushed:SetAlpha(0.62)' in UI
    assert 'highlight:SetAlpha(0.34)' in UI
    assert 'disabled:SetAlpha(0)' in UI


def test_dropdowns_keep_custom_dark_fill_and_gold_bevel():
    assert 'ApplyMarketButtonSkin(dropdown, "control")' in UI
    assert 'SetThemeTexture(button.marketFill, "control", {0.035, 0.032, 0.026, 0.96})' in UI
    assert 'style == "control" and "control" or "button"' in UI


def test_dropdown_popup_selection_and_callbacks_are_preserved():
    assert 'dropdown:SetScript("OnClick", dropdown.ToggleMenu)' in UI
    assert 'onChanged(selectedValue)' in UI
    assert 'if selectedDisabled then return end' in UI
