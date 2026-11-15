from pathlib import Path
import json
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"


def test_snapshot_source_and_refresh_behavioral_harness():
    lua = shutil.which("texlua") or shutil.which("lua")
    assert lua, "Lua interpreter required for behavioral harness"
    result = subprocess.run(
        [lua, str(ROOT / "tests" / "snapshot_source_0_12_5_harness.lua"), str(ROOT)],
        check=True, capture_output=True, text=True,
    )
    assert "snapshot source/refresh behavioral harness: PASS" in result.stdout


def test_release_versions_agree():
    toc = (ADDON / "ModuloMarket.toc").read_text()
    core = (ADDON / "Core.lua").read_text()
    turnins = (ADDON / "TurnInData.lua").read_text()
    writs = (ADDON / "WritData.lua").read_text()
    manifest = json.loads((ROOT / "MANIFEST.json").read_text())
    assert re.search(r"^## Version: 0\.12\.8$", toc, re.M)
    assert 'MM.version = "0.12.8"' in core
    assert 'version = "0.12.8"' in turnins
    assert 'version = "0.12.8"' in writs
    assert manifest["version"] == "0.12.8"
