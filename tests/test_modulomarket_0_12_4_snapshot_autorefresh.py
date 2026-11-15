from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"


def test_replicate_commit_uses_explicit_snapshot_handoff():
    replicate = (ADDON / "Replicate.lua").read_text()
    assert 'MM.MarketUI.OnMarketSnapshotCommitted(snapshot)' in replicate
    assert 'elseif MM.MarketUI and MM.MarketUI.Refresh then' in replicate


def test_closed_market_defers_and_first_open_consumes_refresh():
    market_ui = (ADDON / "MarketUI.lua").read_text()
    assert 'pendingSnapshotRefresh = false' in market_ui
    assert 'if not UI.frame then' in market_ui
    assert 'UI.pendingSnapshotRefresh = true' in market_ui
    assert 'snapshot and (UI.pendingSnapshotRefresh or snapshot ~= UI.catalogSnapshot)' in market_ui
    assert 'UI.pendingSnapshotRefresh = false' in market_ui


def test_open_presentation_rebuilds_and_invalidates_stale_rows():
    market_ui = (ADDON / "MarketUI.lua").read_text()
    assert 'function UI.OnMarketSnapshotCommitted(snapshot)' in market_ui
    assert 'MM.db.lastMarketSnapshot ~= snapshot' in market_ui
    assert 'UI.blizzlikeVisible == true or modernOpen' in market_ui
    assert 'UI.viewRevision = (UI.viewRevision or 0) + 1' in market_ui
    assert 'if UI.RenderRows then UI.RenderRows() end' in market_ui


def test_modern_show_consumes_deferred_snapshot_refresh():
    modern = (ADDON / "ModernUI.lua").read_text()
    show = modern[modern.index('function Modern.Show()'):modern.index('function Modern.Hide()')]
    assert 'UI.PrepareModernBackend()' in show
    assert 'UI.Refresh()' in show


def test_version_agreement():
    toc = (ADDON / "ModuloMarket.toc").read_text()
    core = (ADDON / "Core.lua").read_text()
    turnins = (ADDON / "TurnInData.lua").read_text()
    writs = (ADDON / "WritData.lua").read_text()
    manifest = json.loads((ROOT / "MANIFEST.json").read_text())
    assert re.search(r"^## Version: 0\.12\.5$", toc, re.M)
    assert 'MM.version = "0.12.5"' in core
    assert 'version = "0.12.5"' in turnins
    assert 'version = "0.12.5"' in writs
    assert manifest["version"] == "0.12.5"
