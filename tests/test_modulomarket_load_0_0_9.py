from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"
SCANNER = ADDON / "Scanner.lua"
CORE = ADDON / "Core.lua"
TOC = ADDON / "ModuloMarket.toc"


def test_scanner_load_file_is_declared_after_core():
    toc = TOC.read_text().splitlines()
    assert toc.index("Core.lua") < toc.index("Scanner.lua")
    assert toc.index("Scanner.lua") < toc.index("Diagnostics.lua")


def test_event_handler_closes_event_branch_and_function():
    lines = SCANNER.read_text().splitlines()
    start = next(i for i, line in enumerate(lines) if 'Scanner.driver:SetScript("OnEvent"' in line)
    stop = next(i for i in range(start + 1, len(lines)) if lines[i].strip() == "end)")
    block = lines[start:stop + 1]
    assert block[-2].strip() == "end"
    assert block[-1].strip() == "end)"


def test_scanner_exports_toggle_before_addon_loaded_command_can_run():
    source = SCANNER.read_text()
    core = CORE.read_text()
    assert "MM.Scanner = Scanner" in source
    assert "function Scanner.Toggle()" in source
    assert "MarketUI.Toggle()" in core
    assert 'SLASH_MODULOMARKETSCAN1 = "/mmscan"' in core
    assert 'Print("Market UI is not ready.")' in core


def test_ui_scroll_child_is_executable_code():
    lines = SCANNER.read_text().splitlines()
    index = next(i for i, line in enumerate(lines) if "Keep the output widget fixed-size" in line)
    assert lines[index + 1].strip() == "scroll:SetScrollChild(edit)"
    assert not r"\n" in lines[index]


def test_version_agreement():
    assert re.search(r"^## Version: 0\.6\.0$", TOC.read_text(), re.M)
    assert 'MM.version = "0.6.0"' in CORE.read_text()
    assert '"version": "0.6.0"' in (ROOT / "MANIFEST.json").read_text()
