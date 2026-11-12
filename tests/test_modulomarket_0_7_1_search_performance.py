from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / 'AddOns/ModuloMarket/MarketUI.lua').read_text()
CORE = (ROOT / 'AddOns/ModuloMarket/Core.lua').read_text()
TOC = (ROOT / 'AddOns/ModuloMarket/ModuloMarket.toc').read_text()
MANIFEST = (ROOT / 'MANIFEST.json').read_text()

def test_release_versions_agree():
    assert 'MM.version = "0.7.1"' in CORE
    assert '## Version: 0.7.1' in TOC
    assert '"version": "0.7.1"' in MANIFEST

def test_typing_is_debounced_and_cancels_stale_build():
    assert 'SEARCH_DEBOUNCE_SECONDS = 0.25' in UI
    assert 'local function ScheduleSearchBuild()' in UI
    assert 'UI.viewBuild = nil' in UI
    assert 'UI.rankSort = nil' in UI
    assert 'UI.searchBuildDueAt = Now() + SEARCH_DEBOUNCE_SECONDS' in UI
    assert 'UI.search:SetScript("OnTextChanged", function() ScheduleSearchBuild() end)' in UI

def test_tooltip_load_events_are_coalesced_not_rebuilt_individually():
    assert 'TOOLTIP_REFRESH_COALESCE_SECONDS = 0.30' in UI
    assert 'local function ScheduleTooltipRefresh()' in UI
    assert 'UI.tooltipRefreshDueAt = Now() + TOOLTIP_REFRESH_COALESCE_SECONDS' in UI
    assert 'if success ~= false then ScheduleTooltipRefresh() end' in UI
    assert "if not UI.searchBuildDueAt and UI.search and UI.search:GetText()" in UI

def test_cached_tooltip_text_is_normalized_once():
    assert 'local normalized = NormalizeSearchText(text)' in UI
    assert 'return cached or ""' in UI
    assert 'return NormalizeSearchText(cached or "")' not in UI

def test_async_search_and_effect_matching_are_preserved():
    assert 'GetTooltipSearchText(item.itemID)' in UI
    assert 'RequestLoadItemDataByID' in UI
    assert 'ITEM_DATA_LOAD_RESULT' in UI
    assert 'GET_ITEM_INFO_RECEIVED' in UI
