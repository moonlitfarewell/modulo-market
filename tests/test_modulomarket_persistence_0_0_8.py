from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"
SCANNER = ADDON / "Scanner.lua"
CORE = ADDON / "Core.lua"
TOC = ADDON / "ModuloMarket.toc"


def test_version_agreement():
    toc = TOC.read_text()
    core = CORE.read_text()
    manifest = (ROOT / "MANIFEST.json").read_text()
    assert re.search(r"^## Version: 0\.6\.3$", toc, re.M)
    assert 'MM.version = "0.6.3"' in core
    assert '"version": "0.6.3"' in manifest


def test_single_last_known_good_snapshot_is_restored():
    source = SCANNER.read_text()
    assert 'MM.db.lastSnapshot = snapshot' in source
    assert 'local function RestoreSavedSnapshot()' in source
    assert 'local saved = type(MM.db) == "table" and MM.db.lastSnapshot or nil' in source
    assert 'saved.complete == true' in source
    assert 'tonumber(saved.resultCount) == #saved.rows' in source
    assert 'RestoreSavedSnapshot()' in source
    assert 'MM.db.snapshots' not in source


def test_only_finish_replaces_saved_snapshot():
    source = SCANNER.read_text()
    assert source.count('MM.db.lastSnapshot = snapshot') == 1
    finish = source.split('local function Finish()', 1)[1].split('local function HasFullResults()', 1)[0]
    start = source.split('local function Start()', 1)[1].split('local function EscapeJSON', 1)[0]
    abort = source.split('local function Abort(reason)', 1)[1].split('local function Finish()', 1)[0]
    assert 'MM.db.lastSnapshot = snapshot' in finish
    assert 'HasFullResults' not in finish  # Finish is called only after the full-results gate.
    assert 'MM.db.lastSnapshot' not in start
    assert 'MM.db.lastSnapshot' not in abort


def test_old_snapshot_is_kept_until_complete_replacement():
    harness = (ROOT / "tests" / "scanner_model_harness.lua").read_text()
    assert 'starting a scan replaced the saved snapshot' in harness
    assert 'completed snapshot did not replace SavedVariables' in harness
    assert 'failed scan destroyed the last-known-good snapshot' in harness
    assert 'saved snapshot not restored on open' in harness
