from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns" / "ModuloMarket" / "MarketUI.lua").read_text()

def test_market_raise_never_promotes_window_to_tooltip_strata():
    match = re.search(r"function UI\.Raise\(\)(.*?)\nend", UI, re.S)
    assert match, "UI.Raise function must exist"
    body = match.group(1)
    assert 'frame:SetFrameStrata("DIALOG")' in body
    assert 'frame:SetFrameStrata("TOOLTIP")' not in body

def test_game_tooltip_uses_higher_tooltip_strata():
    assert 'GameTooltip:SetFrameStrata("TOOLTIP")' in UI

