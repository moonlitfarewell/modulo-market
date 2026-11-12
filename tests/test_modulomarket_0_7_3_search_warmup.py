from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / 'AddOns/ModuloMarket/MarketUI.lua').read_text()
CORE = (ROOT / 'AddOns/ModuloMarket/Core.lua').read_text()
TOC = (ROOT / 'AddOns/ModuloMarket/ModuloMarket.toc').read_text()
MANIFEST = (ROOT / 'MANIFEST.json').read_text()

def test_release_versions_agree():
    assert 'MM.version = "0.7.3"' in CORE
    assert '## Version: 0.7.3' in TOC
    assert '"version": "0.7.3"' in MANIFEST

def test_search_waits_for_tooltip_data_without_treating_pending_as_no_match():
    assert 'if tooltipText == nil then return nil' in UI
    assert 'pendingTooltipIDs = {}' in UI
    assert 'build.pendingTooltipIDs[tonumber(item.itemID)] = true' in UI

def test_tooltip_data_is_warmed_once_then_one_final_search_pass_runs():
    assert 'local function StepTooltipSearchWarmup()' in UI
    assert 'UI.tooltipSearchWarmup = {' in UI
    assert 'UI.StartViewBuild() -- exactly one full pass, now backed by resolved/cached tooltip data' in UI
    assert 'if success ~= false then ScheduleTooltipRefresh() end' not in UI
    assert 'local function ScheduleTooltipRefresh()' not in UI

def test_warmup_requests_are_bounded_and_timeout_fails_closed():
    assert 'processed < 20' in UI
    assert 'TOOLTIP_SEARCH_TIMEOUT_SECONDS = 15' in UI
    assert 'UI.tooltipSearchCache[itemID] = false' in UI

def test_warmup_event_accounting_is_per_item_not_global():
    assert 'warmup.awaiting[itemID] = true' in UI
    assert 'if warmup and warmup.awaiting[itemID] then' in UI
    assert 'if loaded then UI.tooltipSearchRequested[itemID] = nil end' in UI
    assert 'warmup.outstanding = math.max(0, warmup.outstanding - 1)' in UI

def test_search_debounce_and_stale_build_cancellation_remain():
    assert 'SEARCH_DEBOUNCE_SECONDS = 0.25' in UI
    assert 'local function ScheduleSearchBuild()' in UI
    assert 'UI.viewBuild = nil' in UI
    assert 'UI.rankSort = nil' in UI
    assert 'UI.searchBuildDueAt = Now() + SEARCH_DEBOUNCE_SECONDS' in UI

def test_unknown_and_not_learnable_are_both_red_in_rows_and_inspector():
    assert 'status == "unlearnable" and "|cffff6666"' in UI
    assert 'status == "unknown" and "|cffff6666"' in UI
    assert 'state == "unlearnable" and "|cffff6666NOT LEARNABLE|r" or "|cffff6666UNKNOWN|r"' in UI

def test_tooltip_effect_search_and_async_item_loading_remain():
    assert 'GetTooltipSearchText(item.itemID)' in UI
    assert 'RequestLoadItemDataByID' in UI
    assert 'ITEM_DATA_LOAD_RESULT' in UI
    assert 'GET_ITEM_INFO_RECEIVED' in UI
