import json
from pathlib import Path

ROOT = Path(__file__).parents[1]
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())
CANONICAL = json.loads((ROOT / "data/ForeverDB-Canonical-1.60.1.70888.json").read_text())
OLD = json.loads((ROOT / "data/ForeverDB-Canonical-1.60.1.70862.json").read_text())
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
DATA = (ROOT / "AddOns/ModuloMarket/ForeverDBData.lua").read_text()
PROFESSION = (ROOT / "AddOns/ModuloMarket/ProfessionData.lua").read_text()

def records(doc):
    return {(p["slug"], str(r["recipe_id"])): r for p in doc["professions"] for r in p["recipes"]}

def test_release_versions_and_runtime_build_agree():
    assert MANIFEST["version"] == "0.6.5"
    assert 'MM.version = "0.6.5"' in CORE
    assert "## Version: 0.6.5" in TOC
    assert CANONICAL["client_build"] == "1.60.1.70888"
    assert '["clientBuild"]="1.60.1.70888"' in DATA

def test_historical_baseline_is_preserved_and_catalogue_identity_stable():
    assert OLD["client_build"] == "1.60.1.70862"
    assert len(records(OLD)) == len(records(CANONICAL)) == 2493
    assert set(records(OLD)) == set(records(CANONICAL))

def test_coarse_grinding_stone_threshold_refresh_and_watch_disposition():
    r = records(CANONICAL)[("blacksmithing", "3326")]
    assert r["name"] == "Coarse Grinding Stone"
    assert r["skill"]["green"] == 70 and r["skill"]["grey"] == 90
    assert r["skill"]["orange_evidence"] == "CLASSIC_BORROWED"
    assert "[3326]" not in PROFESSION
    for rid in ("1283400", "1245246", "3962"):
        assert f"[{rid}]" in PROFESSION

def test_remaining_hotfix_records_unchanged_in_new_capture():
    old, new = records(OLD), records(CANONICAL)
    for key in (("cooking", "1283400"), ("alchemy", "1245246"), ("engineering", "3962")):
        assert old[key] == new[key]

def test_70888_review_evidence_is_included():
    assert (ROOT / "docs/FOREVERDB-DATA-REVIEW-2026-11-12.md").exists()
    assert "The 200 records" in (ROOT / "docs/FOREVERDB-DATA-REVIEW-2026-11-12.md").read_text()


def test_70862_to_70888_field_diff_is_scoped_and_reproducible():
    old, new = records(OLD), records(CANONICAL)
    changed = {k for k in old if old[k] != new[k]}
    acquisition = {k for k in changed if old[k].get("acquisition_sources") != new[k].get("acquisition_sources")}
    metadata = {k for k in changed if old[k].get("provider_metadata") != new[k].get("provider_metadata")}
    skill = {k for k in changed if old[k].get("skill") != new[k].get("skill")}
    assert len(changed) == 200
    assert len(acquisition) == 185
    assert len(metadata) == 28
    assert len(skill) == 1
    for k in old:
        for field in ("name", "category", "category_id", "category_parent", "output_kind", "outputs", "reagent_groups"):
            assert old[k].get(field) == new[k].get(field), (k, field)
