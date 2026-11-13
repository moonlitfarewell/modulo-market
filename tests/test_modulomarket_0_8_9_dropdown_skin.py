from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")


def test_control_skin_suppresses_legacy_red_template_art():
    assert 'local templateAlpha = style == "control" and 0 or 0.12' in UI
    assert 'normal:SetAlpha(templateAlpha)' in UI
    assert 'pushed:SetAlpha(style == "control" and 0 or 0.16)' in UI
    assert 'highlight:SetAlpha(style == "control" and 0 or 0.10)' in UI
    assert 'disabled:SetAlpha(0)' in UI


def test_dropdowns_keep_custom_dark_fill_and_gold_bevel():
    assert 'ApplyMarketButtonSkin(dropdown, "control")' in UI
    assert 'button.marketFill:SetColorTexture(0.025, 0.022, 0.017, 0.98)' in UI
    assert 'style == "control" and "control" or "button"' in UI


def test_dropdown_popup_selection_and_callbacks_are_preserved():
    assert 'dropdown:SetScript("OnClick", dropdown.ToggleMenu)' in UI
    assert 'onChanged(selectedValue)' in UI
    assert 'if selectedDisabled then return end' in UI
