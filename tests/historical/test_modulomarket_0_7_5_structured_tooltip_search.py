from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = (ROOT / "MANIFEST.json").read_text()

def test_release_versions_agree():
    assert 'MM.version = "0.7.5"' in CORE
    assert '## Version: 0.7.5' in TOC
    assert '"version": "0.7.5"' in MANIFEST

def test_structured_tooltip_api_is_primary_extraction_path():
    assert '_G.C_TooltipInfo' in UI
    assert 'structured.GetItemByID' in UI
    assert 'line.leftText' in UI
    assert 'line.rightText' in UI
    assert 'C_TooltipInfo.GetItemByID' in UI

def test_legacy_tooltip_fallback_checks_actual_line_population():
    assert 'GameTooltip fallback' in UI
    assert 'if #lines == 0 then' in UI
    assert 'searchTooltip.SetHyperlink' in UI
    assert 'setterOK' in UI

def test_empty_setter_call_is_not_treated_as_successful_extraction():
    assert 'only tells us the setter did not throw' in UI
    assert 'lastLineCount = #lines' in UI
    assert 'emptyResults' in UI

def test_player_can_inspect_exact_extracted_tooltip_text():
    assert 'function UI.GetTooltipSearchDebug(itemID)' in UI
    assert 'SLASH_MODULOMARKETTOOLTIPDEBUG1 = "/mmtooltipdebug"' in CORE
    assert 'GetTooltipSearchDebug(itemID)' in CORE
    assert '/mmtooltipdebug itemID' in CORE

def test_tooltip_search_remains_explicitly_submitted():
    assert 'UI.search:SetScript("OnEnterPressed"' in UI
    assert 'includeTooltip = UI.tooltipSearchMode == true' in UI
    assert 'Press Enter to include item tooltip descriptions and effects.' in UI
