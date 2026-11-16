from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARKET_UI = ROOT / "AddOns/ModuloMarket/MarketUI.lua"
CORE = ROOT / "AddOns/ModuloMarket/Core.lua"
TOC = ROOT / "AddOns/ModuloMarket/ModuloMarket.toc"


def test_tab_perf_diagnostics_are_opt_in_and_exposed():
    source = MARKET_UI.read_text(encoding="utf-8")
    assert "tabPerfDiagnostics = {" in source and "enabled = false" in source
    assert "function UI.SetTabPerfDiagnostics(enabled)" in source
    assert "function UI.ResetTabPerfDiagnostics()" in source
    assert "function UI.GetTabPerfDiagnostics()" in source
    assert "if build.tabPerfEnabled and UI.tabPerfDiagnostics.enabled then" in source


def test_tab_perf_tracks_source_work_rows_and_elapsed_time():
    source = MARKET_UI.read_text(encoding="utf-8")
    for token in (
        "record.sourceRows = record.sourceRows + #(source or {})",
        "active.processedRows = active.processedRows + 1",
        "record.elapsedSeconds = record.elapsedSeconds + elapsed",
        "record.resultRows = record.resultRows + #(rows or {})",
        "diagnostics.sameTabSelections = diagnostics.sameTabSelections + 1",
        "perf.activeBuild.cancelled = true",
        "record.cancelled = record.cancelled + 1",
    ):
        assert token in source


def test_slash_command_supports_on_off_reset_and_report():
    source = CORE.read_text(encoding="utf-8")
    assert 'SLASH_MODULOMARKETTABPERF1 = "/mmtabperf"' in source
    for command in ('command == "on"', 'command == "off"', 'command == "reset"'):
        assert command in source
    assert "GetTabPerfDiagnostics()" in source
    assert "sourceRows=%d processed=%d results=%d" in source


def test_version_metadata_is_consistent():
    toc = TOC.read_text(encoding="utf-8")
    core = CORE.read_text(encoding="utf-8")
    turnin = (ROOT / "AddOns/ModuloMarket/TurnInData.lua").read_text(encoding="utf-8")
    assert "## Version: 1.0.3" in toc
    assert 'MM.version = "1.0.3"' in core
    assert "1.0.3" in turnin
