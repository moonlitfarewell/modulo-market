from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"
CORE = ADDON / "Core.lua"
TOC = ADDON / "ModuloMarket.toc"
SCANNER = ADDON / "Scanner.lua"
REPLICATE = ADDON / "Replicate.lua"
MARKET_UI = ADDON / "MarketUI.lua"
MANIFEST = ROOT / "MANIFEST.json"


def test_010_is_the_first_player_facing_market_product_release():
    toc = TOC.read_text()
    core = CORE.read_text()
    assert re.search(r"^## Version: 0\.6\.1$", toc, re.M)
    assert 'MM.version = "0.6.1"' in core
    assert 'SLASH_MODULOMARKET1 = "/mm"' in core
    assert "MarketUI.Toggle()" in core
    assert 'SLASH_MODULOMARKETSCAN1 = "/mmscan"' in core


def test_toc_loads_engine_and_market_ui_after_scanner():
    toc = TOC.read_text()
    assert toc.index("Scanner.lua") < toc.index("Replicate.lua")
    assert toc.index("Replicate.lua") < toc.index("RecipeEngine.lua")
    assert toc.index("RecipeEngine.lua") < toc.index("MarketUI.lua")
    assert toc.index("MarketUI.lua") < toc.index("Diagnostics.lua")


def test_replicate_is_explicitly_confirmed_and_never_automatically_retried():
    source = REPLICATE.read_text()
    assert "function Replicate.Prepare()" in source
    assert "function Replicate.Confirm()" in source
    assert "ReplicateItems" in source
    assert "Replicate.pendingConfirmation = true" in source
    assert "Replicate.attemptedThisSession = true" in source
    assert "No retry will occur" in source
    assert "if not Replicate.active then return end" in source


def test_full_scan_is_bounded_and_has_item_data_enrichment_queue():
    source = REPLICATE.read_text()
    assert "BATCH_SIZE = 250" in source
    assert "ITEM_REQUESTS_PER_FRAME = 20" in source
    assert "RESPONSE_TIMEOUT = 90" in source
    assert "SCAN_TIMEOUT = 900" in source
    assert "RequestLoadItemDataByID" in source
    assert 'RegisterEvent("ITEM_DATA_LOAD_RESULT")' in source
    assert "QueuePendingRetries" in source
    assert "itemDataResolved" in source


def test_variant_identity_retains_suffix_bonus_lists_modifiers_and_pets():
    source = REPLICATE.read_text()
    assert "itemSuffix = tonumber(fields[8]) or 0" in source
    assert "bonusLists" in source
    assert "modifierCount" in source
    assert "battlePetSpeciesID" in source
    assert "GetDetailedItemLevelInfo" in source
    assert "ItemKeyIdentity" in source


def test_aggregation_separates_priced_and_unpriced_supply_and_tracks_depth():
    source = REPLICATE.read_text()
    assert "minPriceCopper" in source
    assert "minPriceQuantity" in source
    assert "totalQuantity" in source
    assert "pricedQuantity" in source
    assert "unpricedQuantity" in source
    assert "math.ceil(buyoutCopper / stackCount)" in source


def test_snapshot_commit_is_transactional_and_does_not_overwrite_browse_snapshot():
    source = REPLICATE.read_text()
    assert "scan.unresolvedAuctionCount == 0" in source
    assert "scan.invalidItemIDCount == 0" in source
    assert "scan.infoErrorCount == 0" in source
    assert "MM.db.lastMarketSnapshot = snapshot" in source
    assert "MM.db.lastSnapshot =" not in source
    assert "Previous saved market data is unchanged" in source


def test_market_ui_has_search_cost_basis_profit_loss_and_break_even():
    source = MARKET_UI.read_text()
    assert 'InputBoxTemplate' in source
    assert 'AddLabel(frame, "Search"' in source
    assert 'CreateInput(frame, "Your cost / unit (gold)"' not in source
    assert 'tabSpecs' in source and 'crafting' in source
    assert 'MM.Recipes.BuildEconomics' in source
    assert "function UI.GetProfitScenario" in source
    assert "breakEvenGrossCopper" in source
    assert "totalProfitCopper" in source
    assert "costBasisByItemKey" not in source


def test_profit_scenario_math_uses_net_after_cut_and_break_even():
    source = MARKET_UI.read_text()
    assert "local net = math.floor(price * (1 - cutPercent / 100))" in source
    assert "local profit = net - costCopper" in source
    assert "breakEvenGrossCopper = math.ceil(costCopper / (1 - cutPercent / 100))" in source


def test_browse_snapshot_keeps_full_item_key_dimensions_and_json_schema():
    source = SCANNER.read_text()
    assert "bonusLists = CopyArray(result.itemKey.bonusLists)" in source
    assert "modifiers = CopyArray(result.itemKey.modifiers)" in source
    assert '  "schemaVersion": 3,' in source
    assert '"bonusLists":%s' in source
    assert '"modifiers":%s' in source


def test_parent_and_child_provenance_agree():
    manifest = json.loads(MANIFEST.read_text())
    assert manifest["version"] == "0.6.1"
    assert manifest["parentSourceBundle"] == "MODULO-Project-Source-1.0.48.zip"
    assert manifest["parentSourceKind"] == "project"
    assert manifest["parentUploader"] == "developer"
    assert manifest["parentSha256"] == "8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da"
    assert "AddOns/ModuloMarket/Replicate.lua" in manifest["files"]
    assert "AddOns/ModuloMarket/MarketUI.lua" in manifest["files"]
    assert "AddOns/ModuloMarket/RecipeEngine.lua" in manifest["files"]
    assert "tests/market_engine_0_1_0_harness.lua" in manifest["files"]
    assert "tests/market_ui_0_1_0_harness.lua" in manifest["files"]
    assert "tests/market_ui_0_2_0_harness.lua" in manifest["files"]
    assert "tests/test_modulomarket_market_engine_0_1_0.py" in manifest["files"]
    assert "MODULOMARKET-RUNTIME-AUDIT-0.4.0.md" in manifest["files"]
    readme = (ROOT / "README.md").read_text()
    assert readme.startswith("# Modulo Market 0.6.1")
    actual = sorted(
        path.relative_to(ROOT).as_posix()
        for path in ROOT.rglob("*")
        if path.is_file()
        and "__pycache__" not in path.parts
        and ".pytest_cache" not in path.parts
        and path.suffix != ".pyc"
    )
    assert sorted(manifest["files"]) == actual
