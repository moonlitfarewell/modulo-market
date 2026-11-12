from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def test_version_reporting_runtime_model():
    lua = shutil.which("lua") or shutil.which("texlua")
    if not lua:
        import pytest
        pytest.skip("lua/texlua interpreter unavailable")
    result = subprocess.run(
        [lua, str(ROOT / "tests/version_reporting_0_5_4_harness.lua"),
         str(ROOT / "AddOns/ModuloMarket/Core.lua")],
        check=True, capture_output=True, text=True,
    )
    assert "ModuloMarket 0.6.3 version reporting harness passed" in result.stdout
