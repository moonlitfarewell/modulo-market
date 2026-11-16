from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"


def test_release_version_is_aligned():
    toc = (ADDON / "ModuloMarket.toc").read_text()
    core = (ADDON / "Core.lua").read_text()
    turnins = (ADDON / "TurnInData.lua").read_text()
    manifest = json.loads((ROOT / "MANIFEST.json").read_text())
    assert re.search(r"^## Version: 1\.0\.2$", toc, re.M)
    assert 'MM.version = "1.0.2"' in core
    assert 'version = "1.0.2"' in turnins
    assert manifest["version"] == "1.0.2"


def test_scan_diagnostic_is_written_after_snapshot_commit():
    source = (ADDON / "Replicate.lua").read_text()
    commit = source[source.index("local previousSnapshot = MM.db.lastMarketSnapshot"):source.index("Replicate.active = false", source.index("local previousSnapshot = MM.db.lastMarketSnapshot"))]
    assert "MM.db.lastMarketSnapshot = snapshot" in commit
    assert "MM.db.lastMarketScanAt = snapshot.timestamp" in commit
    assert 'SaveTargetDiagnostics(scan, "complete", snapshot, previousSnapshot)' in commit
    assert "commitConfirmed" in source
    assert "previousSnapshotTimestamp" in source
    assert "snapshotTimestamp" in source


def test_target_diagnostics_report_saved_snapshot_price_and_depth():
    source = (ADDON / "Replicate.lua").read_text()
    assert "snapshotMinPriceCopper" in source
    assert "snapshotTotalQuantity" in source
    assert "snapshotAuctionCount" in source
    assert "snapshotRows" in source
    assert "Target saved snapshot" in source


def test_abort_records_failure_and_preserves_previous_snapshot():
    source = (ADDON / "Replicate.lua").read_text()
    abort = source[source.index("local function Abort(reason)"):source.index("local function SaveHistoryPoint", source.index("local function Abort(reason)"))]
    assert '"aborted: " .. tostring(reason)' in abort
    assert "Previous saved market data is unchanged" in abort
    assert "commitConfirmed = false" in abort


def test_saved_snapshot_refresh_is_local_and_does_not_trigger_replicate():
    source = (ADDON / "MarketUI.lua").read_text()
    start = source.index("function UI.RefreshSavedSnapshot()")
    end = source.index("-- Explicit hand-off from the Replicate transaction", start)
    fn = source[start:end]
    assert "GetSnapshot()" in fn
    assert "UI.pendingSnapshotRefresh = true" in fn
    assert "UI.catalogSnapshot = nil" in fn
    assert "UI.Refresh()" in fn
    assert "Replicate" not in fn
    assert "ReplicateItems" not in fn


def test_both_presentations_expose_refresh_and_blizzlike_close_action_is_removed():
    market = (ADDON / "MarketUI.lua").read_text()
    modern = (ADDON / "ModernUI.lua").read_text()
    assert 'UI.refreshSnapshotButton = AddButton(frame, "Refresh"' in market
    assert 'UI.closeAction = AddButton(frame, "Close"' not in market
    assert 'local refreshSnapshot = FlatButton(frame, "Refresh"' in modern
    assert 'UI.RefreshSavedSnapshot()' in modern
    assert 'local close = FlatButton(frame, ""' in modern  # title-bar X remains the window close


def test_last_scan_outcome_and_time_are_visible_and_diagnostic_report_includes_commit():
    market = (ADDON / "MarketUI.lua").read_text()
    modern = (ADDON / "ModernUI.lua").read_text()
    diagnostics = (ADDON / "Diagnostics.lua").read_text()
    assert '" · OK "' in market and '" · Failed "' in market
    assert '" · OK "' in modern and '" · Failed "' in modern
    assert '"LAST FULL MARKET SCAN / COMMIT"' in diagnostics
    assert "Committed snapshot timestamp" in diagnostics
    assert "Enchantresses' Spire minimum copper" in diagnostics
