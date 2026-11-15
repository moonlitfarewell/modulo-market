from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_release_versions_agree():
    assert 'MM.version = "0.9.8"' in CORE
    assert '## Version: 0.9.8' in TOC
    assert MANIFEST["version"] == "0.9.8"


def test_typing_runs_name_search_after_trailing_debounce_and_enter_opts_into_tooltips():
    assert 'local SEARCH_DEBOUNCE_SECONDS = 0.5' in UI
    on_update = UI.split('frame:SetScript("OnUpdate"', 1)[1].split('end)', 1)[0]
    assert 'UI.tooltipSearchMode = false' in on_update
    assert 'UI.tooltipSearchDiagnostics.lastState = "name_search"' in on_update
    enter = UI.split('UI.search:SetScript("OnEnterPressed"', 1)[1].split('AttachFilterTooltip(UI.search', 1)[0]
    assert 'UI.tooltipSearchMode = true' in enter
    assert 'UI.tooltipSearchDiagnostics.lastState = "submitted"' in enter
    assert 'Press Enter to run the deeper tooltip-description search' in UI


def test_stale_search_generation_is_discarded():
    assert 'searchGeneration = 0' in UI
    assert 'UI.searchGeneration = (UI.searchGeneration or 0) + 1' in UI
    assert 'generation = UI.searchGeneration' in UI
    assert 'if build.generation ~= UI.searchGeneration then UI.viewBuild = nil; return end' in UI
    assert 'if warmup.generation ~= UI.searchGeneration then UI.tooltipSearchWarmup = nil; return end' in UI


def test_tooltip_work_is_bounded_and_cache_is_retained():
    assert '(UI.tooltipSearchScansThisFrame or 0) < 30' in UI
    assert '(UI.tooltipSearchRequestsThisFrame or 0) < 10' in UI
    assert 'processed < 10' in UI
    assert 'tooltipSearchCache = {}' in UI
    assert 'UI.tooltipSearchDiagnostics.cacheHits' in UI


def test_launcher_is_classic_blizzard_sell_tab_only():
    assert 'local function IsDefaultBlizzardSellTab(parent)' in UI
    assert 'if parent ~= _G.AuctionFrame then return false end' in UI
    assert 'if selected ~= 2 then return false end' in UI
    assert 'if IsDefaultBlizzardSellTab(parent) then button:Show() else button:Hide() end' in UI
    assert 'button:Hide() end)' in UI
    assert 'AuctionFrameTab" .. index' in UI


def test_launcher_does_not_attach_to_modern_or_addon_owned_parent_frames():
    block = UI[UI.index('function UI.AttachAuctionHouseButton()'):UI.index('local function PositionMinimapButton')]
    assert 'local parent = _G.AuctionFrame' in block
    assert '_G.AuctionHouseFrame' not in block
