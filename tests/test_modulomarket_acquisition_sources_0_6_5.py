import json
from pathlib import Path

ROOT = Path(__file__).parents[1]
CANONICAL = json.loads((ROOT / "data/ForeverDB-Canonical-1.60.1.70888.json").read_text())
COMPILER = (ROOT / "tools/foreverdb_importer/market_data_importer.py").read_text()
RUNTIME = (ROOT / "AddOns/ModuloMarket/ForeverDBData.lua").read_text()
PROFESSION = (ROOT / "AddOns/ModuloMarket/ProfessionData.lua").read_text()
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()


def all_sources():
    for profession in CANONICAL["professions"]:
        for recipe in profession["recipes"]:
            for source in recipe.get("acquisition_sources", []):
                yield profession, recipe, source


def test_canonical_dataset_contains_field_level_acquisition_routes():
    sources = list(all_sources())
    assert len(sources) > 10000
    assert {source["evidence"] for _, _, source in sources} >= {
        "FOREVER_OBSERVED", "CLASSIC_BORROWED", "UNKNOWN", "FOREVER_CLIENT"
    }
    assert any(source.get("npc_id") and source.get("zone") for _, _, source in sources)
    assert any(source.get("price_per_item_copper") is not None for _, _, source in sources)
    assert any(source.get("quest_id") for _, _, source in sources)
    assert any(source.get("item_id") for _, _, source in sources)


def test_compiler_preserves_acquisition_source_details_not_only_type_flags():
    for field in (
        '"acquisitionSources"', '"npc_id"', '"zone"', '"map_id"',
        '"price_per_item_copper"', '"limited_stock"', '"quest_id"',
        '"item_id"', '"entity_evidence"', '"source_text"',
    ):
        assert field in COMPILER
        assert field in RUNTIME
    assert len(RUNTIME) > 4_000_000


def test_profession_index_exposes_known_and_unlearned_recipe_source_details():
    assert "foreverRecipeDetails" in PROFESSION
    assert "function Data.GetForeverRecipeDetails" in PROFESSION
    assert "acquisitionSources = type(sourceRecipe.acquisitionSources)" in PROFESSION
    assert "trainerCostEvidence" in PROFESSION


def test_inspector_and_recipe_tooltip_show_each_evidence_level_without_promoting_unknown():
    for label in ("FOREVER OBSERVED", "FOREVER CLIENT", "CLASSIC BORROWED", "UNKNOWN / UNVERIFIED"):
        assert label in UI
    assert "NPC observed on Forever; this recipe-to-NPC link is not confirmed." in UI
    assert "additional source records; hover the recipe for the full list." in UI
    assert "Acquisition sources" in UI
    assert "CLASSIC BORROWED — UNCONFIRMED" in UI
