import hashlib
import importlib.util
import json
from pathlib import Path

import pytest


MODULE_PATH = Path(__file__).parents[1] / "tools" / "foreverdb_importer" / "market_data_importer.py"
SPEC = importlib.util.spec_from_file_location("market_data_importer_raw_adapter", MODULE_PATH)
importer = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(importer)


def _envelope(data, meta):
    return (json.dumps({"data": data, "meta": meta}, separators=(",", ":")) + "\n").encode()


def _recipe(spell_id=1001, name="Test Potion", *, makes=True, speculative=False):
    return {
        "spellId": spell_id,
        "name": name,
        "category": {"id": 2450, "name": "Potions", "parent": {"id": 2424, "name": "Alchemy"}},
        "skill": {"orange": 1, "yellow": 10, "green": 12, "grey": 15, "orangeSource": "client"},
        "makes": {"itemId": 2001, "name": "Test Potion", "count": 2, "quality": "Common",
                  "url": "https://foreverdb.net/item/2001"} if makes else None,
        "reagents": [{"itemId": 765, "name": "Silverleaf", "count": 3}],
        "tools": [],
        "needsNearby": None,
        "learnedFrom": {
            "automatic": False,
            "trainer": None,
            "recipeItems": [{"itemId": 3001, "name": "Recipe: Test Potion"}],
            "recipeItemsHidden": [],
            "recipeItemsNotInClient": [],
            "classicVendors": 0,
            "seenAtForeverTrainers": ["Observed Trainer"],
            "sources": {
                "ways": ["trainer", "vendor", "drop", "quest"],
                "learnAtSkill": 15,
                "recipeItem": {"itemId": 3001, "name": "Recipe: Test Potion"},
                "trainers": {"alliance": [
                    {"npcId": 10, "name": "Observed Trainer", "title": "Alchemist",
                     "faction": "Alliance", "zone": "Stormwind", "mapId": 1453,
                     "x": 1.0, "y": 2.0, "seenInForever": True, "inferred": False,
                     "source": "Seen in Forever"},
                    {"npcId": 11, "name": "Classic Trainer", "title": "Alchemist",
                     "faction": "Alliance", "zone": "Darnassus", "mapId": 1457,
                     "x": 3.0, "y": 4.0, "seenInForever": False, "inferred": False,
                     "source": "Classic data"}
                ]},
                "vendors": {"horde": [
                    {"npcId": 20, "name": "Classic Vendor", "faction": "Horde",
                     "zone": "Orgrimmar", "mapId": 1454, "x": 5.0, "y": 6.0,
                     "seenInForever": False, "price": 100, "stack": 5,
                     "pricePerItem": 20.0, "costs": [], "limitedStock": True,
                     "limitedStockCount": 1, "notOnListPlayersSaw": False,
                     "reputationFaction": None, "source": "Classic data"}
                ]},
                "drops": [{"kind": "drop", "from": "Test Mob", "chancePercent": None, "npcId": 30}],
                "quests": [{"questId": 40, "name": "Test Quest", "faction": "Alliance",
                            "inForeverClient": True, "url": "https://foreverdb.net/quest/40"}],
                "note": "One shared provider note.",
                "trainerCost": 50,
                "trainerCostSource": "Classic data",
            },
            "known": True,
        },
        "newInForever": True,
        "changedFromClassic": [],
        "sameNameRecipes": [],
        "leftoverOf": None,
        "classic": None,
        "campTier": None,
        "speculation": speculative,
        "speculationReasons": ["test reason"] if speculative else [],
        "url": f"https://foreverdb.net/spell/{spell_id}",
    }


def _make_capture(tmp_path, *, recipes=None):
    build = "1.60.1.70862"
    responses = []

    def save(rel, data, meta):
        raw = _envelope(data, meta)
        target = tmp_path / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
        responses.append({"relative_path": rel, "bytes": len(raw),
                          "sha256": hashlib.sha256(raw).hexdigest(),
                          "request_path": "/" + rel, "fetched_at_utc": "2026-11-11T12:00:00Z"})

    save("meta.json", {"build": build, "levelCap": 60},
         {"build": build, "client": "dev-test"})
    save("professions-index.json", [{
        "slug": "alchemy", "name": "Alchemy", "kind": "primary",
        "icon": "https://foreverdb.net/icons/1.webp", "url": "https://foreverdb.net/profession/alchemy",
        "recipeCount": len(recipes or [_recipe()]), "newInForever": 1,
        "changedFromClassic": 0, "trainerCount": 1, "trainersSeenInForever": 1,
    }], {"build": build, "total": 1})
    page_recipes = recipes if recipes is not None else [_recipe()]
    save("professions/alchemy/offset-000000.json", {
        "slug": "alchemy", "name": "Alchemy", "kind": "primary",
        "recipeCount": len(page_recipes),
        "ranks": [{"rank": "Apprentice", "maxSkill": 75, "spellId": 123}],
        "trainers": [{
            "npcId": 10, "name": "Observed Trainer", "title": "Alchemist", "side": "alliance",
            "zone": "Stormwind", "mapId": 1453, "x": 1.0, "y": 2.0,
            "trainsUpToSkill": 75, "seenInForever": True, "placeSeenInForever": True,
            "source": "Seen in Forever",
        }],
        "recipes": page_recipes,
    }, {"build": build, "total": len(page_recipes), "limit": 100, "offset": 0, "next": None})
    manifest = {
        "capture_schema_version": 1, "status": "COMPLETE", "provider": "ForeverDB.net",
        "provider_url": "https://foreverdb.net", "client_build": build,
        "started_at_utc": "2026-11-11T12:00:00Z", "updated_at_utc": "2026-11-11T12:00:05Z",
        "profession_slugs": ["alchemy"],
        "profession_reports": [{"slug": "alchemy", "pages_captured": 1,
                                "recipe_records_captured": len(page_recipes),
                                "reported_total": len(page_recipes), "pagination_shape_unknown": False}],
        "request_count": 3, "responses": responses,
    }
    (tmp_path / "capture-manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    return tmp_path


def test_normalize_capture_maps_observed_and_borrowed_sources_separately(tmp_path):
    capture = _make_capture(tmp_path)
    data = importer.normalize_capture(capture)
    recipe = data["professions"][0]["recipes"][0]
    assert data["client_build"] == "1.60.1.70862"
    assert data["normalization_summary"]["recipe_count"] == 1
    assert recipe["outputs"][0]["quantity_min"] == 2
    assert recipe["outputs"][0]["quantity_max"] == 2
    assert recipe["reagent_groups"][0]["required"] is True
    assert recipe["reagent_groups"][0]["choices"][0]["item_id"] == 765
    by_name = {source.get("name"): source for source in recipe["acquisition_sources"]}
    assert by_name["Observed Trainer"]["evidence"] == "FOREVER_OBSERVED"
    assert by_name["Classic Trainer"]["evidence"] == "CLASSIC_BORROWED"
    assert by_name["Classic Vendor"]["price_per_item_copper"] == 20.0
    assert by_name["Test Mob"]["evidence"] == "UNKNOWN"
    assert by_name["Test Quest"]["evidence"] == "UNKNOWN"
    assert data["provider_notes"] == ["One shared provider note."]
    assert recipe["skill"]["orange_evidence"] == "FOREVER_CLIENT"
    assert "required_skill" not in recipe["skill"]


def test_normalize_capture_keeps_non_item_and_speculative_records(tmp_path):
    recipes = [
        _recipe(1001, "Test Potion"),
        _recipe(1002, "Enchant Bracer - Test", makes=False),
        _recipe(1003, "Speculative Potion", speculative=True),
    ]
    capture = _make_capture(tmp_path, recipes=recipes)
    data = importer.normalize_capture(capture)
    rows = data["professions"][0]["recipes"]
    assert [r["output_kind"] for r in rows] == ["item", "unknown", "item"]
    assert rows[1]["outputs"] == []
    assert rows[2]["provider_metadata"]["speculation"] is True


def test_normalize_capture_rejects_hash_mismatch(tmp_path):
    capture = _make_capture(tmp_path)
    page = capture / "professions/alchemy/offset-000000.json"
    page.write_bytes(page.read_bytes() + b" ")
    with pytest.raises(importer.ImporterError, match="hash/byte mismatch"):
        importer.normalize_capture(capture)


def test_normalize_capture_rejects_partial_capture(tmp_path):
    capture = _make_capture(tmp_path)
    manifest_path = capture / "capture-manifest.json"
    manifest = json.loads(manifest_path.read_text())
    manifest["status"] = "PARTIAL"
    manifest_path.write_text(json.dumps(manifest))
    with pytest.raises(importer.ImporterError, match="COMPLETE"):
        importer.normalize_capture(capture)


def test_normalize_capture_rejects_duplicate_recipe_ids(tmp_path):
    recipe = _recipe()
    capture = _make_capture(tmp_path, recipes=[recipe, dict(recipe)])
    with pytest.raises(importer.ImporterError, match="duplicate recipe spellId"):
        importer.normalize_capture(capture)


def test_runtime_compiler_emits_compact_build_gated_dataset(tmp_path):
    capture = _make_capture(tmp_path / "capture")
    canonical = importer.normalize_capture(capture)
    output = tmp_path / "ForeverDBData.lua"
    importer.compile_runtime(canonical, output)
    content = output.read_text()
    assert "ForeverDB.net" in content
    assert "1.60.1.70862" in content
    assert "sourceKnown" in content
    assert "borrowedSources" in content
    assert output.stat().st_size < 100_000
