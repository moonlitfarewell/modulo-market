from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"
SCANNER = ADDON / "Scanner.lua"
TOC = ADDON / "ModuloMarket.toc"
CORE = ADDON / "Core.lua"
MANIFEST = ROOT / "MANIFEST.json"


def test_replicate_probe_is_explicitly_two_step_and_never_automatic():
    source = SCANNER.read_text()
    assert 'Button("Prepare Replicate Probe"' in source
    assert 'Confirm & Send One Request' in source
    assert "function Scanner.PrepareReplicateProbe()" in source
    assert "function Scanner.ConfirmReplicateProbe()" in source
    assert "API.ReplicateItems" in source
    assert "Scanner.replicateProbeAttemptedThisSession = true" in source
    assert "REPLICATE_ITEM_LIST_UPDATE" in source


def test_probe_enforces_cooldown_timeout_and_sample_only():
    source = SCANNER.read_text()
    assert "REPLICATE_COOLDOWN_SECONDS = 900" in source
    assert "REPLICATE_PROBE_TIMEOUT_SECONDS = 90" in source
    assert "GetNumReplicateItems" in source
    assert "GetReplicateItemInfo" in source
    assert "GetReplicateItemLink" in source
    assert "local indices = { 0, math.floor((count - 1) / 2), count - 1 }" in source
    assert "completeScan = false" in source


def test_probe_does_not_change_last_known_good_snapshot():
    source = SCANNER.read_text()
    probe = source[source.index("local function StopReplicateProbe"):source.index("local function CreateUI")]
    assert "MM.db.lastSnapshot =" not in probe
    assert "MM.db.replicateProbeAttemptAt = now" in probe
    assert "pcall(API.ReplicateItems)" in probe


def test_probe_is_bounded_and_fails_closed():
    source = SCANNER.read_text()
    assert "if Scanner.active then" in source
    assert "if not IsAuctionHouseOpen() then" in source
    assert "CanScanSafely()" in source
    assert "Attempt consumed; no retry" in source
    assert "No Replicate response within 90 seconds" in source


def test_probe_load_order_and_version_agreement():
    toc = TOC.read_text()
    assert toc.index("Scanner.lua") < toc.index("Diagnostics.lua")
    assert re.search(r"^## Version: 0\.5\.2$", toc, re.M)
    assert 'MM.version = "0.5.2"' in CORE.read_text()
    manifest = json.loads(MANIFEST.read_text())
    assert manifest["version"] == "0.5.2"
    assert "AddOns/ModuloMarket/Scanner.lua" in manifest["files"]
    assert "tests/replicate_probe_harness.lua" in manifest["files"]
