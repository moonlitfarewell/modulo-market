from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns/ModuloMarket"
CORE = (ADDON / "Core.lua").read_text(encoding="utf-8")
TOC = (ADDON / "ModuloMarket.toc").read_text(encoding="utf-8")
MARKET = (ADDON / "MarketUI.lua").read_text(encoding="utf-8")
MODERN = (ADDON / "ModernUI.lua").read_text(encoding="utf-8")
DATA = (ADDON / "TurnInData.lua").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_0117_versions_are_aligned():
    assert 'MM.version = "0.12.1"' in CORE
    assert "## Version: 0.12.1" in TOC
    assert 'version = "0.12.1"' in DATA
    assert MANIFEST["version"] == "0.12.1"


def test_both_windows_center_on_every_explicit_open():
    assert "function UI.CenterWindow()" in MARKET
    assert "CenterMarketWindow(frame, \"blizzlike\")" in MARKET
    assert 'frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)' in MARKET
    assert 'frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)' in MODERN
    assert "function Modern.Show()" in MODERN


def test_quality_colours_use_passive_cache_without_render_time_requests():
    assert "GetItemQualityColor" in MARKET
    assert "local itemQualityCache = {}" in MARKET
    assert "RequestItemQuality" not in MARKET
    quality_block = MARKET.split("local itemQualityCache = {}", 1)[1].split("local function GetItemDisplayName", 1)[0]
    assert "C_Item.RequestLoadItemDataByID" not in quality_block
    assert "itemQualityRequested" not in MARKET
    assert "itemQualityFailed" not in MARKET
    assert "Uncached item quality is not guessed or requested" in quality_block


def test_item_data_event_refreshes_only_active_presentation():
    event_block = MARKET.split('vendorInfoEvents:SetScript("OnEvent"', 1)[1].split("end)", 1)[0]
    assert 'MM.Theme.GetTheme() == "modern"' in event_block
    assert "MM.ModernUI.RenderRows()" in event_block
    assert "SelectItem(UI.selectedItem)" in event_block
    assert event_block.index("if modernActive then") < event_block.index("elseif UI.selectedItem")


def test_legacy_item_name_cache_probe_does_not_suppress_getiteminfo():
    block = MARKET.split("GetItemName = function(item)", 1)[1].split("local itemQualityCache", 1)[0]
    assert "pcall(GetItemInfoCompat, itemID)" in block
    assert "IsItemDataCachedByID" not in block


def test_native_shift_click_dispatcher_is_preferred():
    block = MARKET.split("function UI.HandleShiftClick(item)", 1)[1].split("UI.FillAuctionHouseSearch", 1)[0]
    assert "_G.ChatFrameUtil" in block
    assert "chatUtil.InsertLink" in block
    assert "ChatEdit_GetActiveWindow" not in block
    assert "browseName:SetText(plainName)" in block
    assert "AuctionFrameBrowse_Search" not in block


def test_modern_numeric_columns_are_content_measured_and_right_aligned_on_all_tabs():
    assert "function Modern.UpdateColumnLayout(state)" in MODERN
    assert "cell:GetStringWidth()" in MODERN
    assert "cell:SetJustifyH(\"RIGHT\")" in MODERN
    assert "row.name:SetJustifyH(\"LEFT\")" in MODERN
    assert "Modern.UpdateColumnLayout(state)" in MODERN


def test_modern_inspector_outer_heading_and_inner_card_are_distinct():
    assert 'Panel(frame, "INSPECTED ITEM"' in MODERN
    assert 'Panel(right, "SELECTED ITEM"' in MODERN


def test_artisan_reward_schedule_is_complete_and_category_based():
    artisan = DATA[DATA.index("id=248695"):DATA.index("    },\n    -- One-time Shipping Label")]
    assert artisan.count("rewardFavor=20, rewardCashCopper=1000") == 5
    assert artisan.count("rewardFavor=40, rewardCashCopper=2000") == 3
    assert "50 copper per Favor" in DATA


def test_modern_search_reports_filter_and_tooltip_warmup_progress():
    assert "searchStatus = UI.searchBuildDueAt" in MARKET
    assert "Searching %d/%d" in MARKET
    assert "Loading descriptions %d/%d" in MARKET
    assert "if state.searchStatus then" in MODERN
