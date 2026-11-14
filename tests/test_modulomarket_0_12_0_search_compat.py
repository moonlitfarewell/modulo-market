from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns/ModuloMarket"
MARKET = (ADDON / "MarketUI.lua").read_text(encoding="utf-8")
CORE = (ADDON / "Core.lua").read_text(encoding="utf-8")
TOC = (ADDON / "ModuloMarket.toc").read_text(encoding="utf-8")
DATA = (ADDON / "TurnInData.lua").read_text(encoding="utf-8")
WRITS = (ADDON / "WritData.lua").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_0120_versions_are_aligned():
    assert 'MM.version = "0.12.2"' in CORE
    assert "## Version: 0.12.2" in TOC
    assert 'version = "0.12.2"' in DATA
    assert 'version = "0.12.2"' in WRITS
    assert MANIFEST["version"] == "0.12.2"


def test_search_debounce_is_half_second_and_trailing():
    assert "local SEARCH_DEBOUNCE_SECONDS = 0.5" in MARKET
    schedule = MARKET.split("local function ScheduleSearchBuild()", 1)[1].split("local function StepView()", 1)[0]
    assert "UI.searchBuildDueAt = Now() + SEARCH_DEBOUNCE_SECONDS" in schedule
    assert "UI.searchGeneration = (UI.searchGeneration or 0) + 1" in schedule
    assert "UI.viewBuild = nil" in schedule
    on_update = MARKET.split('frame:SetScript("OnUpdate"', 1)[1].split('end)', 1)[0]
    assert 'UI.tooltipSearchMode = false' in on_update
    assert 'UI.tooltipSearchDiagnostics.lastState = "name_search"' in on_update


def test_enter_is_the_explicit_deep_tooltip_search():
    enter = MARKET.split('UI.search:SetScript("OnEnterPressed"', 1)[1].split('AttachFilterTooltip(UI.search', 1)[0]
    assert "UI.tooltipSearchMode = true" in enter
    assert "UI.searchBuildDueAt = nil" in enter
    assert "UI.StartViewBuild()" in enter


def test_item_info_compat_matches_professionmaster_forever_fallback():
    helper = MARKET.split("local function GetItemInfoCompat(itemID)", 1)[1].split("local function GetItemLinkDisplayName", 1)[0]
    assert "_G.GetItemInfo" in helper
    assert "_G.C_Item" in helper
    assert "api.GetItemInfo" in helper


def test_item_link_name_is_a_search_fallback():
    assert 'itemLink:match("|h%[(.-)%]|h")' in MARKET
    assert "GetItemLinkDisplayName(variant.itemLink)" in MARKET
    name = MARKET.split("GetItemName = function(item)", 1)[1].split("local itemQualityCache", 1)[0]
    assert "item.bestVariant.itemLink" in name
    assert "item.variants" in name


def test_rarity_uses_professionmaster_quality_table_without_render_requests():
    block = MARKET.split("local itemQualityCache = {}", 1)[1].split("local function GetItemDisplayName", 1)[0]
    assert "GetItemInfoCompat" in block
    assert "ITEM_QUALITY_COLORS" in block
    assert "color.hex" in block
    assert "RequestLoadItemDataByID" not in block
    assert "ffffffff" in block
