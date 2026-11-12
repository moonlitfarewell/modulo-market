from pathlib import Path
import json
ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())

def test_version_agreement():
    assert 'MM.version = "0.7.6"' in CORE
    assert '## Version: 0.7.6' in TOC
    assert MANIFEST["version"] == "0.7.6"

def test_initial_tab_visibility_applied_after_controls_are_built():
    marker = 'UI.tooltipSearchEvents = tooltipSearchEvents'
    assert marker in UI
    assert 'SetTab(UI.activeTab or "market")' in UI
    assert UI.index('UI.tooltipSearchEvents = tooltipSearchEvents') < UI.index('SetTab(UI.activeTab or "market")') < UI.index('return frame', UI.index('SetTab(UI.activeTab or "market")'))
    assert 'if showCraftFilters then control:Show() else control:Hide() end' in UI
    assert 'if showEconomicsFilters then control:Show() else control:Hide() end' in UI

def test_structured_tooltip_is_not_read_before_item_data_cache_is_ready():
    cache_check = UI.index('api.IsItemDataCachedByID')
    structured_read = UI.index('structured.GetItemByID')
    assert cache_check < structured_read
    assert 'local loaded = hasCacheAPI and isCached' in UI
    assert 'if not loaded then' in UI[cache_check:structured_read]
    assert 'return nil' in UI[cache_check:structured_read]

def test_uncached_item_requests_async_load_and_retries_on_event():
    assert 'api.RequestLoadItemDataByID' in UI
    assert 'UI.tooltipSearchRequested[itemID] = true' in UI
    assert 'warmup.awaiting[itemID] = nil' in UI
    assert 'warmup.outstanding = math.max(0, warmup.outstanding - 1)' in UI
