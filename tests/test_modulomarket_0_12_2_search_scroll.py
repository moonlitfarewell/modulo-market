import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARKET = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")


def test_new_result_set_resets_scroll_after_replacing_scroll_child_height():
    finish = MARKET.split("function UI.FinishView(rows)", 1)[1].split("\nend", 1)[0]
    assert "UI.viewRows = rows" in finish
    assert "UI.listOffset = 0" in finish
    assert "UI.scrollChild:SetHeight" in finish
    assert "UI.scroll:SetVerticalScroll(0)" in finish
    assert finish.index("UI.scrollChild:SetHeight") < finish.index("UI.scroll:SetVerticalScroll(0)")


def test_virtual_list_clamps_offsets_to_current_result_set():
    assert "local function GetMaximumListOffset(total)" in MARKET
    assert "local function ClampListOffset(offset, total)" in MARKET
    assert "UI.listOffset = ClampListOffset(UI.listOffset, #(UI.viewRows or {}))" in MARKET
    callback = MARKET.split('UI.scroll:SetScript("OnVerticalScroll"', 1)[1].split("\n    end)", 1)[0]
    assert "ClampListOffset(offset, #(UI.viewRows or {}))" in callback
    assert "scrollFrame:SetVerticalScroll(clamped)" in callback


def test_result_counter_cannot_report_a_start_after_the_result_count():
    block = MARKET.split("local function UpdateResultRange()", 1)[1].split("\nend", 1)[0]
    assert "UI.listOffset = ClampListOffset(UI.listOffset, total)" in block
    assert "math.floor(UI.listOffset / UI.rowHeight) + 1" in block


def test_scroll_clamp_handles_empty_small_and_large_result_sets():
    def maximum(total, visible=25, row_height=27):
        return max(0, (max(0, total) - max(1, visible)) * max(1, row_height))
    def clamp(offset, total):
        return min(max(0, offset), maximum(total))
    assert clamp(2700, 0) == 0
    assert clamp(2700, 2) == 0
    assert clamp(2700, 25) == 0
    assert clamp(2700, 26) == 27
    assert clamp(2700, 100) == 2025
    assert clamp(-10, 100) == 0
