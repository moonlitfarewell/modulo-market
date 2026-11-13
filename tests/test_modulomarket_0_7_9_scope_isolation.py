from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RECIPE = (ROOT / "AddOns/ModuloMarket/RecipeEngine.lua").read_text()
PROFESSION = (ROOT / "AddOns/ModuloMarket/ProfessionData.lua").read_text()
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
DIAGNOSTICS = (ROOT / "AddOns/ModuloMarket/Diagnostics.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
MANIFEST = (ROOT / "MANIFEST.json").read_text()

def test_recipe_snapshot_schema_is_per_profession_and_versioned():
    assert "local RECIPE_SNAPSHOT_SCHEMA_VERSION = 2" in RECIPE
    assert "snapshotSchemaVersion = RECIPE_SNAPSHOT_SCHEMA_VERSION" in RECIPE
    assert "snapshotGeneration = (tonumber(previous and previous.snapshotGeneration) or 0) + 1" in RECIPE
    assert "tonumber(profession.snapshotSchemaVersion) == RECIPE_SNAPSHOT_SCHEMA_VERSION" in RECIPE
    assert "tonumber(previous.snapshotSchemaVersion) == RECIPE_SNAPSHOT_SCHEMA_VERSION" in RECIPE

def test_old_snapshot_records_are_not_positive_known_evidence():
    assert "if recipe.learned == true then return \"known\" end" in PROFESSION
    assert "recipe.craftSourceStatus == \"known\"" not in PROFESSION

def test_future_candidates_are_copied_before_scope_status_is_assigned():
    assert "local recipe = {}" in UI
    assert "for field, value in pairs(sourceRecipe) do recipe[field] = value end" in UI
    assert "recipe.craftSourceStatus = MM.ProfessionData" in UI
    assert "sourceRecipe.craftSourceStatus =" not in UI

def test_version_alignment():
    assert '## Version: 0.7.9' in TOC
    assert 'MM.version = "0.7.9"' in CORE
    assert '"version": "0.7.9"' in MANIFEST

def test_diagnostics_expose_snapshot_schema_generation_and_staleness():
    assert "Required recipe snapshot schema" in DIAGNOSTICS
    assert "snapshotGeneration" in DIAGNOSTICS
    assert "STALE — recapture required" in DIAGNOSTICS
