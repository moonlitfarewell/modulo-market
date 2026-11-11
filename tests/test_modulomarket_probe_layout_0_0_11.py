from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
SCANNER = ROOT / "AddOns" / "ModuloMarket" / "Scanner.lua"
TOC = ROOT / "AddOns" / "ModuloMarket" / "ModuloMarket.toc"
CORE = ROOT / "AddOns" / "ModuloMarket" / "Core.lua"
MANIFEST = ROOT / "MANIFEST.json"


def test_status_has_dedicated_wrapped_height_before_controls():
    source = SCANNER.read_text()
    assert "status:SetHeight(54)" in source
    assert 'status:SetJustifyV("TOP")' in source
    assert "status:SetWordWrap(true)" in source
    assert 'Button("Start Full Snapshot", 150, 16, -172, Start)' in source
    assert 'Button("Prepare Replicate Probe", 155, 16, -232' in source
    assert 'scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -302' in source


def test_version_agreement():
    assert re.search(r"^## Version: 0\.5\.3$", TOC.read_text(), re.M)
    assert 'MM.version = "0.5.3"' in CORE.read_text()
    assert json.loads(MANIFEST.read_text())["version"] == "0.5.3"
