from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SCANNER = ROOT / "AddOns" / "ModuloMarket" / "Scanner.lua"
TOC = ROOT / "AddOns" / "ModuloMarket" / "ModuloMarket.toc"


def test_version_is_008():
    assert re.search(r"^## Version: 0\.5\.8$", TOC.read_text(), re.M)


def test_only_client_throttle_readiness_gates_requests():
    source = SCANNER.read_text()
    assert "IsThrottledMessageSystemReady" in source
    assert "QUIET_SECONDS" not in source
    assert "Now() - Scanner.lastActivity" not in source
    assert "local function IsThrottleReady()" in source


def test_scan_measures_elapsed_and_throttle_wait():
    source = SCANNER.read_text()
    assert "scanDurationSeconds = scanDurationSeconds" in source
    assert "throttleWaitSeconds = throttleWaitSeconds" in source
    assert "Elapsed %.1fs; throttle wait %.1fs." in source
    assert "FinalizeThrottleWait()" in source


def test_json_uses_real_newline_whitespace():
    source = SCANNER.read_text()
    assert 'return table.concat(out, "\\\\n"), partIndex, partCount' not in source
    assert 'return table.concat(out, "\\n"), partIndex, partCount' in source
