from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"
TOC = ADDON / "ModuloMarket.toc"

def meta(key):
    text = TOC.read_text()
    m = re.search(r"^## " + re.escape(key) + r":\s*(.*?)\s*$", text, re.M)
    return m.group(1) if m else None

def test_market_is_a_separate_grouped_child():
    assert ADDON.is_dir()
    assert meta("Title") == "Modulo Market"
    assert meta("Version") == "0.5.1"
    assert meta("Category") == "Modulo By Wells"
    assert meta("Group") == "Modulo"
    assert meta("Dependencies") == "Modulo"
    assert meta("SavedVariables") == "ModuloMarketDB"

def test_market_has_no_market_economy_mutation_in_this_slice():
    source = "\n".join(p.read_text() for p in ADDON.glob("*.lua"))
    for forbidden in ("SendBrowseQuery(", "RequestMoreBrowseResults(", "PlaceAuctionBid(", "PostItem(", "CancelAuction(", "CraftRecipe("):
        assert forbidden not in source
    assert "IsThrottledMessageSystemReady" in source

def test_market_has_its_own_toc_and_source_files():
    assert (ADDON / "Core.lua").is_file()
    assert (ADDON / "Diagnostics.lua").is_file()
