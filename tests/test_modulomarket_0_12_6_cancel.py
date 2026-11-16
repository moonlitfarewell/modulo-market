from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"

def test_player_cancel_is_available_during_active_replicate_scan():
    replicate = (ADDON / "Replicate.lua").read_text()
    market = (ADDON / "MarketUI.lua").read_text()
    modern = (ADDON / "ModernUI.lua").read_text()
    assert "function Replicate.Cancel()" in replicate
    assert 'Abort("cancelled by player")' in replicate
    assert "if state.pendingConfirmation or state.active then UI.cancelButton:Show()" in market
    assert "if state.pendingConfirmation or state.active then Modern.cancelButton:Show()" in modern
    assert "MM.Replicate.Cancel()" in market

def test_cancel_does_not_clear_attempt_or_commit_partial_snapshot():
    replicate = (ADDON / "Replicate.lua").read_text()
    cancel = replicate[replicate.index("function Replicate.Cancel()") : replicate.index("function Replicate.Confirm()") ]
    assert "Abort(\"cancelled by player\")" in cancel
    assert "CancelPrepare()" in cancel
    abort = replicate[replicate.index("local function Abort(reason)") : replicate.index("local function SaveHistoryPoint(snapshot)") ]
    assert "Previous saved market data is unchanged" in abort
    assert "StopEvents()" in abort

def test_0126_version_metadata_agrees():
    toc = (ADDON / "ModuloMarket.toc").read_text()
    core = (ADDON / "Core.lua").read_text()
    turnins = (ADDON / "TurnInData.lua").read_text()
    writs = (ADDON / "WritData.lua").read_text()
    manifest = json.loads((ROOT / "MANIFEST.json").read_text())
    assert re.search(r"^## Version: 1\.0\.2$", toc, re.M)
    assert 'MM.version = "1.0.2"' in core
    assert 'version = "1.0.2"' in turnins
    assert 'version = "0.12.9"' in writs
    assert manifest["version"] == "1.0.2"
