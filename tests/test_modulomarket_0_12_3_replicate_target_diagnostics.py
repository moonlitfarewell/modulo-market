from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"

def test_targeted_replicate_diagnostics_follow_item_through_pipeline():
    source = (ADDON / "Replicate.lua").read_text()
    assert "TARGET_DIAGNOSTIC_ITEM_ID = 287025" in source
    assert "targetDiagnostic.auctionRecords" in source
    assert "targetDiagnostic.itemDataQueued" in source
    assert "targetDiagnostic.itemDataRequests" in source
    assert "targetDiagnostic.itemDataSuccess" in source
    assert "targetDiagnostic.itemDataFailure" in source
    assert "targetDiagnostic.aggregatedRecords" in source
    assert "SaveTargetDiagnostics(scan, \"complete\")" in source
    assert "SaveTargetDiagnostics(scan, \"aborted:" in source


def test_diagnostics_are_read_only_and_do_not_trigger_another_replicate():
    source = (ADDON / "Replicate.lua").read_text()
    body = source[source.index("function Replicate.PrintTargetDiagnostics()"):source.index("Replicate.frame = CreateFrame(\"Frame\")")]
    assert "API.ReplicateItems" not in body
    assert "lastReplicateTargetDiagnostics" in body


def test_version_agreement():
    toc = (ADDON / "ModuloMarket.toc").read_text()
    core = (ADDON / "Core.lua").read_text()
    manifest = json.loads((ROOT / "MANIFEST.json").read_text())
    assert re.search(r"^## Version: 0\.12\.5$", toc, re.M)
    assert 'MM.version = "0.12.5"' in core
    assert manifest["version"] == "0.12.5"
