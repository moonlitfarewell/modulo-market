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


def test_0119_versions_are_aligned():
    assert f'MM.version = "{MANIFEST["version"]}"' in CORE
    assert f'## Version: {MANIFEST["version"]}' in TOC
    assert f'version = "{MANIFEST["version"]}"' in DATA
    assert 'version = "0.12.9"' in WRITS
    assert MANIFEST["version"] == CORE.split('MM.version = "', 1)[1].split('"', 1)[0]


def test_rarity_lookup_never_requests_item_data():
    block = MARKET.split("local itemQualityCache = {}", 1)[1].split("local function GetItemDisplayName", 1)[0]
    assert "GetItemInfoCompat" in block
    assert "ITEM_QUALITY_COLORS" in block
    assert "RequestLoadItemDataByID" not in block
    assert "RequestItemQuality" not in MARKET
    assert "Uncached item quality is not guessed or requested" in block


def test_item_data_completion_refresh_is_coalesced_and_visibility_gated():
    block = MARKET.split('vendorInfoEvents:SetScript("OnEvent"', 1)[1].split("end)", 1)[0]
    assert "QueueVendorInfoRefresh(itemID, success)" in block
    refresh = MARKET.split("local function IsMarketPresentationVisible()", 1)[1].split(
        "local function NormalizeBuildKey", 1
    )[0]
    assert "vendorInfoEvents.pendingRefresh" in refresh
    assert "MM.ModernUI.IsShown()" in refresh
    assert "UI.blizzlikeVisible == true" in refresh
    assert "if not pending or not IsMarketPresentationVisible() then return end" in refresh
