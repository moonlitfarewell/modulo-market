from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARKET_UI = ROOT / "AddOns/ModuloMarket/MarketUI.lua"
CORE = ROOT / "AddOns/ModuloMarket/Core.lua"


def test_item_event_diagnostics_are_opt_in_and_count_unique_ids():
    source = MARKET_UI.read_text(encoding="utf-8")
    assert "itemEvents = { total = 0" in source
    assert 'if event == "GET_ITEM_INFO_RECEIVED" then' in source
    assert 'elseif event == "ITEM_DATA_LOAD_RESULT" then' in source
    assert "events.seenItems[itemID] = true" in source
    assert "events.uniqueItems = events.uniqueItems + 1" in source


def test_item_type_refresh_reschedules_and_triggers_are_counted():
    source = MARKET_UI.read_text(encoding="utf-8")
    assert "perf.itemEvents.refreshScheduled = perf.itemEvents.refreshScheduled + 1" in source
    assert "if not UI.itemTypeRefreshPending then" in source
    assert "local wasClassRequested = UI.itemClassRequested[itemID] == true" in source
    assert "UI.itemTypeRefreshPendingSince = Now()" in source
    assert "StepItemTypeRefreshBatch(now)" in source
    assert "UI.tabPerfDiagnostics.itemEvents.refreshTriggered =" in source


def test_sort_lifecycle_and_comparator_work_are_counted():
    source = MARKET_UI.read_text(encoding="utf-8")
    assert "sortDiagnostics.started = sortDiagnostics.started + 1" in source
    assert "sortDiagnostics.completed = sortDiagnostics.completed + 1" in source
    assert "perf.sorts.restarted = perf.sorts.restarted + 1" in source
    assert "UI.tabPerfDiagnostics.sorts.comparatorCalls =" in source
    assert "lastElapsedSeconds = math.max(0, Now() - (state.startedAt or Now()))" in source


def test_report_exposes_event_and_sort_counters():
    source = CORE.read_text(encoding="utf-8")
    assert "Item events total=%d getInfo=%d loadResult=%d unique=%d" in source
    assert "Sort started=%d completed=%d restarted=%d compares=%d" in source


def test_version_metadata_is_consistent():
    toc = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
    core = CORE.read_text(encoding="utf-8")
    turnin = (ROOT / "AddOns/ModuloMarket/TurnInData.lua").read_text(encoding="utf-8")
    manifest = __import__("json").loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))
    assert "## Version: 1.0.3" in toc
    assert 'MM.version = "1.0.3"' in core
    assert "1.0.3" in turnin
    assert manifest["version"] == "1.0.3"
