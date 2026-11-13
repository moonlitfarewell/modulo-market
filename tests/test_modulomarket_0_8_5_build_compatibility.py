from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
DIAGNOSTICS = (ROOT / "AddOns/ModuloMarket/Diagnostics.lua").read_text()
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()


def test_version_and_command_are_advanced_for_compatibility_slice():
    assert 'MM.version = "0.8.6"' in CORE
    assert "SLASH_MODULOMARKETCOMPAT1 = \"/mmcompat\"" in CORE
    assert "MM.Diagnostics.ShowCompatibility()" in CORE
    assert "## Version: 0.8.6" in TOC


def test_compatibility_report_is_read_only_and_checks_actual_full_market_snapshot():
    assert 'local function AddCompatibilityReport(lines)' in DIAGNOSTICS
    assert "MM.db.lastMarketSnapshot" in DIAGNOSTICS
    assert "type(MM.ProfessionData.IsMarketSnapshotCompatible)" in DIAGNOSTICS
    assert "MM.ProfessionData.GetFutureProviderStatus" in DIAGNOSTICS
    assert "C_AuctionHouse." in DIAGNOSTICS
    assert "C_Item." in DIAGNOSTICS
    assert "C_TooltipInfo.GetItemByID" in DIAGNOSTICS
    assert "NO REQUESTS SENT" in DIAGNOSTICS
    assert "previous complete snapshot is retained" in DIAGNOSTICS


def test_snapshot_mismatch_remains_fail_closed_and_now_explains_recovery():
    assert "UI.recipeMarketBuildCompatible == false" in UI
    assert "Craft profitability paused: auction snapshot" in UI
    assert "open Auction House > Update Full Market > Confirm" in UI
    assert "wait for the full scan to finish" in UI
    assert "dataBuildMatchesClient" in UI


def test_compatibility_report_has_a_dedicated_display_entry_point():
    assert 'MM.Diagnostics.ShowCompatibility = function()' in DIAGNOSTICS
    assert 'pcall(BuildReport, "COMPAT")' in DIAGNOSTICS
