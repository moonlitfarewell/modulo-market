from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
SCANNER = ROOT / "AddOns" / "ModuloMarket" / "Scanner.lua"
TOC = ROOT / "AddOns" / "ModuloMarket" / "ModuloMarket.toc"
CORE = ROOT / "AddOns" / "ModuloMarket" / "Core.lua"
MANIFEST = ROOT / "MANIFEST.json"


def test_inspection_is_player_started_and_does_not_send_replicate_request():
    source = SCANNER.read_text()
    assert 'Button("Inspect 250 Cached Records"' in source
    body = source[source.index("function Scanner.StartReplicateInspection()"):
                   source.index("function Scanner.PrepareReplicateProbe()")]
    assert "API.ReplicateItems" not in body
    assert "API.GetNumReplicateItems" in body
    assert "No new request was sent" in body


def test_inspection_is_bounded_and_evenly_spaced():
    source = SCANNER.read_text()
    assert "REPLICATE_INSPECT_LIMIT = 250" in source
    assert "REPLICATE_INSPECT_PER_FRAME = 25" in source
    assert "REPLICATE_INSPECT_TIMEOUT_SECONDS = 20" in source
    assert "math.floor((sampleNumber - 1) * (result.totalAvailable - 1)" in source
    assert "fullListComplete = false" in source


def test_inspection_records_documented_replicate_fields_without_loading_data():
    source = SCANNER.read_text()
    body = source[source.index("local function InspectReplicateRecord"):
                   source.index("local function FinishReplicateInspection")]
    assert "info[3]" in body
    assert "info[10]" in body
    assert "info[17]" in body
    assert "info[18]" in body
    assert "GetReplicateItemLink" in body
    assert "GetReplicateItemTimeLeft" in body
    assert "RequestLoadItemDataByID" not in body
    assert "DoesItemExistByID" not in body


def test_inspection_stops_on_lifecycle_safety_and_cache_change():
    source = SCANNER.read_text()
    body = source[source.index("function Scanner.StartReplicateInspection()"):
                   source.index("function Scanner.PrepareReplicateProbe()")]
    assert "IsAuctionHouseOpen()" in body
    assert "CanScanSafely()" in body
    assert "AUCTION_HOUSE_CLOSED" in body
    assert "currentCount ~= result.totalAvailable" in body


def test_inspection_never_mutates_last_known_good_snapshot():
    source = SCANNER.read_text()
    body = source[source.index("local function StopReplicateInspection"):
                   source.index("function Scanner.PrepareReplicateProbe()")]
    assert "MM.db.lastSnapshot =" not in body
    assert "MM.db.lastReplicateInspection = summary" in body


def test_version_agreement():
    assert re.search(r"^## Version: 0\.5\.7$", TOC.read_text(), re.M)
    assert 'MM.version = "0.5.7"' in CORE.read_text()
    manifest = json.loads(MANIFEST.read_text())
    assert manifest["version"] == "0.5.7"
    assert "tests/test_modulomarket_replicate_inspection_0_0_12.py" in manifest["files"]
    assert manifest["parentSourceBundle"] == "MODULO-Project-Source-1.0.48.zip"
    assert manifest["parentProjectFileId"] == "file_000000001a2482128af00913b054f6f9"
    assert manifest["parentSourceKind"] == "project"
    assert manifest["parentUploader"] == "developer"
    assert manifest["parentSha256"] == "8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da"
