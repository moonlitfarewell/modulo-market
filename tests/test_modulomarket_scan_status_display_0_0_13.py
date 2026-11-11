from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
SCANNER = ROOT / "AddOns" / "ModuloMarket" / "Scanner.lua"
TOC = ROOT / "AddOns" / "ModuloMarket" / "ModuloMarket.toc"
CORE = ROOT / "AddOns" / "ModuloMarket" / "Core.lua"
MANIFEST = ROOT / "MANIFEST.json"


def test_professionmaster_style_data_age_and_scan_countdown_are_present():
    source = SCANNER.read_text()
    assert '"Auction House data from " .. FormatRelativeAge(now - stamp)' in source
    assert 'string.format("Scan in %dm"' in source
    assert 'string.format("Scan in %ds"' in source
    assert 'Scanner.cooldownFrame:SetScript("OnUpdate"' in source
    assert "RefreshScanDisplay()" in source


def test_countdown_is_explicitly_local_not_a_claim_of_global_cooldown_visibility():
    source = SCANNER.read_text()
    assert 'MM.db.replicateProbeAttemptAt' in source
    assert "Market's countdown tracks only Market requests" in source
    assert "cannot see external scans" in source
    assert "Auctionator, ProfessionMaster and other addons can consume it" in source
    assert "Another addon may have a newer shared cooldown" in source
    assert "15 minutes have elapsed since any other addon's Replicate scan" in source


def test_wall_clock_rollback_fails_closed():
    source = SCANNER.read_text()
    assert "if now < previous then return REPLICATE_COOLDOWN_SECONDS end" in source


def test_probe_still_requires_explicit_confirmation_and_never_auto_retries():
    source = SCANNER.read_text()
    prepare = source[source.index("function Scanner.PrepareReplicateProbe()"):
                     source.index("function Scanner.ConfirmReplicateProbe()")]
    confirm = source[source.index("function Scanner.ConfirmReplicateProbe()"):
                     source.index("local function CreateUI()")]
    assert "replicateProbePendingConfirmation = true" in prepare
    assert "pcall(API.ReplicateItems)" not in prepare
    assert "pcall(API.ReplicateItems)" in confirm
    assert "replicateProbeAttemptedThisSession = true" in confirm
    assert "no retry" in confirm.lower()


def test_version_agreement():
    assert re.search(r"^## Version: 0\.5\.4$", TOC.read_text(), re.M)
    assert 'MM.version = "0.5.4"' in CORE.read_text()
    manifest = json.loads(MANIFEST.read_text())
    assert manifest["version"] == "0.5.4"
    assert "tests/test_modulomarket_scan_status_display_0_0_13.py" in manifest["files"]
