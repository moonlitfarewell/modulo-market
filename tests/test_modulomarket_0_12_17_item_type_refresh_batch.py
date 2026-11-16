from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")


def test_only_requested_item_class_events_dirty_filtered_view():
    assert "local wasClassRequested = UI.itemClassRequested[itemID] == true" in SOURCE
    assert "if wasClassRequested and UI.itemTypeFilter" in SOURCE
    assert "if not UI.itemTypeRefreshPending then" in SOURCE


def test_item_type_refresh_waits_for_class_request_queue_and_responses():
    assert "local function HasPendingItemClassRequests()" in SOURCE
    assert "if index <= #order then return true end" in SOURCE
    assert "for _ in pairs(UI.itemClassRequested or {}) do return true end" in SOURCE
    assert "if HasPendingItemClassRequests() and not timedOut then return end" in SOURCE


def test_batch_has_bounded_timeout_and_single_final_rebuild():
    assert "local ITEM_TYPE_REFRESH_MAX_WAIT_SECONDS = 10" in SOURCE
    assert "UI.itemTypeRefreshPending = false" in SOURCE
    assert "UI.StartViewBuild()" in SOURCE
    assert "UI.itemTypeRefreshDueAt = Now() + 0.25" not in SOURCE


def test_refresh_waits_until_other_build_queues_are_idle():
    assert "or UI.tooltipSearchWarmup then return end" in SOURCE
    assert "StepItemTypeRefreshBatch(now)" in SOURCE
