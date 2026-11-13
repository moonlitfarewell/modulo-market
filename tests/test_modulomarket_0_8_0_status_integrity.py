from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
ENGINE = (ROOT / "AddOns/ModuloMarket/RecipeEngine.lua").read_text()
PROFESSION = (ROOT / "AddOns/ModuloMarket/ProfessionData.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_missing_or_invalid_status_fails_closed():
    helper = UI.split("local function GetCraftSourceStatus", 1)[1].split(
        "local function StartEconomicsIndex", 1
    )[0]
    assert 'return "unknown"' in helper
    assert 'status == "known"' in helper
    assert 'status == "learnable"' in helper
    assert 'status == "unlearnable"' in helper
    assert 'status == "unknown"' in helper
    assert 'or "known"' not in UI


def test_all_status_consumers_use_one_normalizer():
    assert "economics.craftSourceStatus = GetCraftSourceStatus(recipe)" in UI
    assert "item.craftSourceStatus = GetCraftSourceStatus(sourceItem)" in UI
    assert UI.count("GetCraftSourceStatus(item)") == 4
    assert "local routeStatus = GetCraftSourceStatus(best)" in UI


def test_best_route_never_infers_known_from_not_future():
    assert 'if routeStatus == "known" then' in UI
    assert 'elseif routeStatus == "learnable" then' in UI
    assert 'elseif routeStatus == "unlearnable" then' in UI
    assert 'Recipe learning status unknown' in UI
    assert 'if best.craftSourceStatus == "future" then' not in UI


def test_four_case_root_tea_scope_contract():
    # A known recipe is positive evidence; a future candidate is only learnable/
    # unlearnable/unknown according to the active character's profession evidence.
    assert 'if recipe.learned == true then return "known" end' in PROFESSION
    assert 'if characterProfessions[pid] then return "learnable" end' in PROFESSION
    assert 'if not characterProfessionDataKnown then return "unknown" end' in PROFESSION
    assert 'return "unlearnable"' in PROFESSION
    assert 'if scope == "account" then' in ENGINE
    assert 'local store, key = GetCharacterStore()' in ENGINE
    assert "snapshotSchemaVersion" in ENGINE


def test_automatic_capture_and_snapshot_schema_are_unchanged():
    assert 'elseif event == "TRADE_SKILL_SHOW" then' in ENGINE
    assert 'Recipes.ScheduleCapture(true)' in ENGINE
    assert "local RECIPE_SNAPSHOT_SCHEMA_VERSION = 2" in ENGINE
    assert "MANUAL" not in ENGINE.upper()


def test_release_metadata_alignment_and_manifest_inventory():
    assert '## Version: 0.9.1' in TOC
    assert 'MM.version = "0.9.1"' in CORE
    assert MANIFEST["version"] == "0.9.1"
    assert "MODULOMARKET-RUNTIME-AUDIT-0.8.3.md" in MANIFEST["files"]
    assert "tests/test_modulomarket_0_8_0_status_integrity.py" in MANIFEST["files"]
    assert MANIFEST["file_count"] == len(MANIFEST["files"])
