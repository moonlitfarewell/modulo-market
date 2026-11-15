from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARKET_UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")


def test_item_events_only_queue_presentation_refresh_when_visible():
    assert "if not IsMarketPresentationVisible() then return end" in MARKET_UI
    assert "QueueVendorInfoRefresh(itemID, success)" in MARKET_UI
    assert "FlushVendorInfoRefresh()" in MARKET_UI
    assert "vendorInfoEvents:SetScript(\"OnUpdate\", function(self)" in MARKET_UI


def test_burst_item_events_are_coalesced_and_hidden_windows_are_not_rendered():
    assert "dueAt = Now() + 0.12, items = {}," in MARKET_UI
    assert "pending.dueAt = Now() + 0.12" in MARKET_UI
    assert "if not pending or not IsMarketPresentationVisible() then return end" in MARKET_UI
    assert "MM.ModernUI.IsShown() == true" in MARKET_UI
    assert "UI.blizzlikeVisible == true" in MARKET_UI


def test_cache_updates_and_item_type_refresh_are_preserved():
    for field in [
        "itemIconCache[itemID] = nil",
        "itemQualityCache[itemID] = nil",
        "UI.itemClassCache[itemID] = nil",
        "UI.vendorPriceRequested[itemID] = nil",
        "UI.itemTypeRefreshDueAt = Now() + 0.25",
    ]:
        assert field in MARKET_UI


def test_version_metadata_is_consistent():
    assert "## Version: 0.12.14" in TOC
    assert 'MM.version = "0.12.14"' in CORE
