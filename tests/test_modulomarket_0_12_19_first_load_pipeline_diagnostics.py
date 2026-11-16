from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
MARKET = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")


def test_catalogue_build_records_rows_frames_and_high_resolution_step_cost():
    assert "local function PerfMilliseconds()" in MARKET
    assert "catalogPerf.active = { startedMs = PerfMilliseconds()" in MARKET
    assert "activePerf.rows = activePerf.rows + processedThisFrame" in MARKET
    assert "activePerf.variantMerges = activePerf.variantMerges + mergesThisFrame" in MARKET
    assert "activePerf.maxStepMs = math.max(activePerf.maxStepMs, stepMs)" in MARKET
    assert "activePerf.finalizeMs = math.max(0, PerfMilliseconds() - finalizeStartedMs)" in MARKET


def test_view_filter_and_class_lookup_costs_are_reported():
    assert "viewPerf.maxStepMs = math.max(viewPerf.maxStepMs, stepMs)" in MARKET
    assert "perf.classLookups.instantCalls = perf.classLookups.instantCalls + 1" in MARKET
    assert "perf.classLookups.instantResolved = perf.classLookups.instantResolved + 1" in MARKET
    assert "perf.classLookups.cacheHits = perf.classLookups.cacheHits + 1" in MARKET
    assert "Catalog starts=%d done=%d cancelled=%d" in CORE
    assert "View frames=%d rows=%d total=%.1fms max=%.2fms" in CORE
    assert "Class lookup calls=%d cache=%d instant=%d/%d" in CORE


def test_diagnostics_remain_opt_in_and_processing_budget_is_unchanged():
    assert "enabled = false" in MARKET
    assert "build.index + 249" in MARKET


def test_release_version_is_consistent():
    toc = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
    core = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
    turnin = (ROOT / "AddOns/ModuloMarket/TurnInData.lua").read_text(encoding="utf-8")
    manifest = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))
    assert "## Version: 1.0.3" in toc
    assert 'MM.version = "1.0.3"' in core
    assert "1.0.3" in turnin
    assert manifest["version"] == "1.0.3"
