from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = (ROOT / "MANIFEST.json").read_text()

def test_release_versions_agree():
    assert 'MM.version = "0.7.4"' in CORE
    assert '## Version: 0.7.4' in TOC
    assert '"version": "0.7.4"' in MANIFEST

def test_typing_is_fast_and_tooltip_search_requires_enter():
    assert 'UI.tooltipSearchMode = false' in UI
    assert 'UI.search:SetScript("OnEnterPressed"' in UI
    assert 'includeTooltip = UI.tooltipSearchMode == true' in UI
    assert 'MatchesSearch(item, build.query, isCrafting, build.includeTooltip)' in UI
    assert 'Typing searches names, professions, IDs and reagents immediately. Press Enter' in UI

def test_item_requests_check_cache_and_do_not_fake_async_fallback():
    assert 'IsItemDataCachedByID' in UI
    assert 'C_Item.RequestLoadItemDataByID unavailable' in UI
    assert 'GetTooltipSearchText(item.itemID)' in UI

def test_warmup_timeout_is_independent_of_other_queues():
    assert 'if UI.tooltipSearchWarmup then StepTooltipSearchWarmup() end' in UI
    assert 'TOOLTIP_SEARCH_TIMEOUT_SECONDS = 15' in UI
    assert 'UI.tooltipSearchDiagnostics.timeouts = UI.tooltipSearchDiagnostics.timeouts + 1' in UI

def test_search_diagnostics_command_is_exposed():
    assert '/mmsearchdebug' in CORE
    assert 'GetSearchDiagnostics()' in UI

def test_rejected_or_missing_request_api_fails_closed_without_retry_loop():
    assert 'accepted == false' in UI
    assert 'UI.tooltipSearchCache[itemID] = false' in UI
    assert 'C_Item.RequestLoadItemDataByID unavailable' in UI

def test_outstanding_requests_reconcile_against_cache_state():
    assert 'for itemID in pairs(warmup.awaiting) do' in UI
    assert 'IsItemDataCachedByID' in UI
    assert 'warmup.outstanding = math.max(0, warmup.outstanding - 1)' in UI

def test_initial_name_matches_render_while_tooltips_warm():
    assert 'UI.FinishView(build.rows)' in UI
    assert 'the final pass later adds any tooltip-only matches' in UI
