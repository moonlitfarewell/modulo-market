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
    assert 'MM.version = "0.12.8"' in CORE
    assert "## Version: 0.12.8" in TOC
    assert 'version = "0.12.8"' in DATA
    assert 'version = "0.12.8"' in WRITS
    assert MANIFEST["version"] == "0.12.8"


def test_rarity_lookup_never_requests_item_data():
    block = MARKET.split("local itemQualityCache = {}", 1)[1].split("local function GetItemDisplayName", 1)[0]
    assert "GetItemInfoCompat" in block
    assert "ITEM_QUALITY_COLORS" in block
    assert "RequestLoadItemDataByID" not in block
    assert "RequestItemQuality" not in MARKET
    assert "Uncached item quality is not guessed or requested" in block


def test_item_data_completion_only_refreshes_active_presentation():
    block = MARKET.split('vendorInfoEvents:SetScript("OnEvent"', 1)[1].split("end)", 1)[0]
    assert 'MM.Theme.GetTheme() == "modern"' in block
    assert "if modernActive then" in block
    assert "MM.ModernUI.RenderRows()" in block
    assert "elseif UI.selectedItem" in block
    assert "SelectItem(UI.selectedItem)" in block
    assert block.index("if modernActive then") < block.index("elseif UI.selectedItem")
