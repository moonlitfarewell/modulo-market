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


def test_search_name_helper_is_forward_declared_before_first_use():
    declaration = MARKET.index("local GetItemName")
    search_function = MARKET.index("local function MatchesSearch")
    first_call = MARKET.index("GetItemName(item)", search_function)
    assignment = MARKET.index("GetItemName = function(item)")
    assert declaration < search_function < first_call < assignment
    assert "local function GetItemName(item)" not in MARKET


def test_0118_versions_are_aligned():
    assert 'MM.version = "1.0.2"' in CORE
    assert "## Version: 1.0.2" in TOC
    assert 'version = "1.0.2"' in DATA
    assert 'version = "0.12.9"' in WRITS
    assert MANIFEST["version"] == "1.0.2"
