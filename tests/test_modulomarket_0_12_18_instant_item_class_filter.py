from pathlib import Path
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MARKET = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")


def test_instant_item_info_class_id_is_read_from_sixth_return_value():
    start = MARKET.index("local function GetItemClassID(itemID, requestLoad)")
    end = MARKET.index("local function StepItemClassWarmup()", start)
    block = MARKET[start:end]
    assert "api.GetItemInfoInstant" in block
    assert "_G.GetItemInfoInstant" in block
    assert "returnedID, itemType, itemSubType, equipLocation, icon, classID" in block
    assert "UI.itemClassCache[itemID] = classID" in block
    assert block.index("GetItemInfoInstant") < block.index("GetItemInfoCompat")


def test_vendor_info_reuses_resolved_class_metadata():
    start = MARKET.index("local function CacheVendorInfo")
    end = MARKET.index("local function ReadVendorInfo", start)
    assert "UI.itemClassCache[itemID] = resolvedClassID" in MARKET[start:end]


def test_instant_class_lookup_runtime_contract(tmp_path):
    texlua = shutil.which("texlua")
    if not texlua:
        import pytest
        pytest.skip("texlua is not installed")
    start = MARKET.index("local function GetItemClassID(itemID, requestLoad)")
    end = MARKET.index("local function StepItemClassWarmup()", start)
    function_source = MARKET[start:end]
    script = """
_G = { C_Item = { GetItemInfoInstant = function(itemID)
    if itemID == 100 then return itemID, "Weapon", "Axes", "", 123, 2, 0 end
    if itemID == 200 then return itemID, "Armor", "Cloth", "INVTYPE_CHEST", 456, 4, 1 end
    if itemID == 300 then return itemID, "Trade Goods", "Cloth", "", 789, 7, 5 end
end } }
UI = { itemClassCache = {}, itemClassFailed = {}, itemClassRequested = {},
    itemClassPendingIDs = {}, itemClassPendingOrder = {} }
local function GetItemInfoCompat() error("full item info fallback should not be called") end
""" + function_source + """
assert(GetItemClassID(100, true) == 2, "Instant tuple classID #6 should resolve weapon")
assert(GetItemClassID(200, true) == 4, "Instant tuple classID #6 should resolve armour")
assert(GetItemClassID(300, true) == 7, "Instant tuple classID #6 should resolve trade goods")
assert(UI.itemClassCache[100] == 2 and UI.itemClassCache[200] == 4 and UI.itemClassCache[300] == 7)
assert(#UI.itemClassPendingOrder == 0, "instant class lookups must not queue async requests")
assert(next(UI.itemClassRequested) == nil, "instant class lookups must not await item-data events")
print("Instant item-class runtime contract passed")
"""
    harness = tmp_path / "instant_item_class.lua"
    harness.write_text(script, encoding="utf-8")
    result = subprocess.run([texlua, str(harness)], text=True, capture_output=True, check=False)
    assert result.returncode == 0, result.stdout + result.stderr
    assert "Instant item-class runtime contract passed" in result.stdout


def test_version_metadata_is_consistent():
    toc = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
    core = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
    turnin = (ROOT / "AddOns/ModuloMarket/TurnInData.lua").read_text(encoding="utf-8")
    manifest = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))
    assert "## Version: 1.0.3" in toc
    assert 'MM.version = "1.0.3"' in core
    assert "1.0.3" in turnin
    assert manifest["version"] == "1.0.3"
