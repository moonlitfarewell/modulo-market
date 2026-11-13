import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENGINE = (ROOT / "AddOns/ModuloMarket/RecipeEngine.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()


def test_profession_open_forces_a_fresh_snapshot_and_retries_missing_info():
    assert 'if event == "TRADE_SKILL_SHOW" then' in ENGINE
    assert 'Recipes.ScheduleCapture(true)' in ENGINE
    assert 'state.retryCounts[recipeID]' in ENGINE
    assert 'lastCaptureReason = "recipe-info-unavailable"' in ENGINE
    assert 'Previous snapshot preserved.' in ENGINE


def test_active_profession_skill_is_authoritative_and_merged():
    assert "function Recipes.SaveActiveProfessionSnapshot(profession)" in ENGINE
    assert 'previous.skillSource ~= "C_TradeSkillUI"' in ENGINE
    assert "snapshot.professions[pid] = previous" in ENGINE


def test_version_is_aligned():
    assert '## Version: 0.8.3' in TOC
    assert 'MM.version = "0.8.3"' in CORE


def test_runtime_harness():
    texlua = shutil.which("texlua")
    if not texlua:
        import pytest
        pytest.skip("texlua unavailable")
    result = subprocess.run([texlua, str(ROOT / "tests/profession_capture_0_7_8_harness.lua")], cwd=ROOT, capture_output=True, text=True, check=True)
    assert "profession capture harness PASS" in result.stdout
