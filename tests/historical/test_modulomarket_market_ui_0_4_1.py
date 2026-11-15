from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()


def test_virtual_rows_are_repositioned_at_absolute_scroll_indices():
    render = UI[UI.index("function UI.RenderRows()"):UI.index("function UI.RenderHistory()") ]
    assert "button:ClearAllPoints()" in render
    assert 'button:SetPoint("TOPLEFT", UI.scrollChild, "TOPLEFT", 0, -((index - 1) * UI.rowHeight))' in render
    assert "visibleCount = 25" in UI


def test_dropdown_callbacks_capture_each_option_value():
    helper = UI[UI.index("local function CreateDropdown"):UI.index("local function AddLabel")]
    assert "local selectedValue = option.value" in helper
    assert "local selectedDisabled = option.disabled == true" in helper
    assert "onChanged(selectedValue)" in helper


def test_sort_direction_uses_texture_arrows_not_font_glyphs():
    assert r"Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up" in UI
    assert r"Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up" in UI
    assert 'label = label .. (sort.ascending and "  ▲"' not in UI


def test_background_opacity_is_adjustable_and_persisted():
    assert "UI.opacitySlider = CreateFrame(\"Slider\"" in UI
    assert "SetMinMaxValues(0.35, 1.0)" in UI
    assert "MM.db.backgroundOpacity = alpha" in UI
    assert "ApplyBackgroundOpacity(frame, value)" in UI


def test_minimap_button_opens_drags_and_persists_its_angle():
    assert "function UI.AttachMinimapButton()" in UI
    assert r'SetTexture("Interface\\Icons\\INV_Misc_Coin_01")' in UI
    assert 'button:SetScript("OnClick"' in UI
    assert 'button:SetScript("OnDragStart"' in UI
    assert "MM.db.minimapAngle = angle" in UI


def test_auction_house_launcher_retries_on_lifecycle_events():
    for event in ("AUCTION_HOUSE_SHOW", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ADDON_LOADED"):
        assert f'"{event}"' in UI
    assert "UI.auctionHouseButtons[parent]" in UI
    assert 'parent:HookScript("OnShow"' in UI


def test_version_is_aligned():
    assert re.search(r"^## Version: 0\.6\.3$", TOC, re.M)
    assert 'MM.version = "0.6.3"' in CORE
