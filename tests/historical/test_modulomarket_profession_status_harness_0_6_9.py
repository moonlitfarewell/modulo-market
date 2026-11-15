import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).parents[1]


def test_character_aware_profession_status_harness():
    texlua = shutil.which("texlua")
    if not texlua:
        import pytest
        pytest.skip("texlua unavailable")
    result = subprocess.run(
        [texlua, str(ROOT / "tests/profession_status_0_6_9_harness.lua")],
        cwd=ROOT, capture_output=True, text=True, check=True,
    )
    assert "profession status harness PASS" in result.stdout
