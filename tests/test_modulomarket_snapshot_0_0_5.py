from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"
TOC = ADDON / "ModuloMarket.toc"
SCANNER = ADDON / "Scanner.lua"
CORE = ADDON / "Core.lua"

def meta(key):
    text = TOC.read_text()
    m = re.search(r"^## " + re.escape(key) + r":\s*(.*?)\s*$", text, re.M)
    return m.group(1) if m else None

def test_market_is_a_separate_grouped_child():
    assert meta("Title") == "Modulo Market"
    assert meta("Version") == "0.5.4"
    assert meta("Category") == "Modulo By Wells"
    assert meta("Group") == "Modulo"
    assert meta("Dependencies") == "Modulo"
    assert meta("SavedVariables") == "ModuloMarketDB"

def test_full_snapshot_is_bounded_and_throttle_paced():
    source = SCANNER.read_text()
    assert 'searchString = ""' in source
    assert "HasFullBrowseResults" in source
    assert "IsThrottledMessageSystemReady" in source
    assert "QUIET_SECONDS" not in source
    assert "MAX_DURATION = 900" in source
    assert "MAX_PAGES = 500" in source
    assert "MAX_RESULTS = 25000" in source
    assert "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" in source
    assert "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" in source

def test_partial_scans_are_not_saved_and_export_requires_complete():
    source = SCANNER.read_text()
    assert "No partial data saved; any previous completed snapshot is unchanged." in source
    assert "complete = true" in source
    assert "snapshot.complete ~= true" in source
    assert "Scanner.completedSnapshot = snapshot" in source
    assert "MM.db.lastSnapshot = snapshot" in source
    assert "MM.db.snapshots" not in source
    assert "local function RestoreSavedSnapshot()" in source
    assert "RestoreSavedSnapshot()" in source
    assert "tonumber(saved.resultCount) == #saved.rows" in source

def test_market_does_not_mutate_auction_or_profession_state():
    source = SCANNER.read_text()
    for forbidden in ("PlaceAuctionBid(", "PostItem(", "PostCommodity(", "CancelAuction(", "CraftRecipe("):
        assert forbidden not in source
    assert "RequestMoreBrowseResults" in source
    assert "SendBrowseQuery" in source

def test_commands_are_split_between_scanner_and_diagnostics():
    source = CORE.read_text()
    assert 'SLASH_MODULOMARKET1 = "/mm"' in source
    assert 'SLASH_MODULOMARKETDEBUG1 = "/mmdebug"' in source


def test_scan_fails_closed_when_sell_tab_has_an_active_item():
    source = SCANNER.read_text()
    assert "HasActiveSellItem" in source
    assert "CanScanSafely" in source
    assert "IsListingAuctions" in source
    assert "ItemSellFrame" in source
    assert "CommoditiesSellFrame" in source
    assert "Scan blocked — " in source
    assert 'Abort("scan safety gate: " .. tostring(reason))' in source


def test_large_json_exports_are_chunked_and_output_widget_is_bounded():
    source = SCANNER.read_text()
    assert "EXPORT_ROWS_PER_PART = 2000" in source
    assert '"exportChunk": true' in source
    assert '"chunkIndex": ' in source
    assert '"chunkCount": ' in source
    assert "local firstRow = (partIndex - 1) * EXPORT_ROWS_PER_PART + 1" in source
    assert 'Button("Previous Part"' in source
    assert 'Button("Next Part"' in source
    assert "edit:SetScript(\"OnTextChanged\"" not in source
    assert "self:SetHeight(math.max(330" not in source
