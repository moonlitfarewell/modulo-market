import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools" / "foreverdb_importer"))
from market_data_importer import validate_canonical
from sanitize_distribution import project

DATA = ROOT / "data" / "ForeverDB-Distribution-1.60.1.70938.json"
RUNTIME = ROOT / "AddOns" / "ModuloMarket" / "ForeverDBData.lua"


def load_data():
    return json.loads(DATA.read_text(encoding="utf-8"))


def test_distribution_projection_valid_and_exact_counts():
    data = load_data()
    assert validate_canonical(data) == []
    recipes = [r for p in data["professions"] for r in p["recipes"]]
    assert len(data["professions"]) == 12
    assert len(recipes) == 2350
    assert all(r["structure_evidence"] == "FOREVER_CLIENT" for r in recipes)
    assert not any(r.get("provider_metadata", {}).get("speculation") for r in recipes)
    assert sum(len(r["acquisition_sources"]) for r in recipes) == 4166


def test_no_classic_or_unknown_acquisition_rows_or_comparison_metadata():
    data = load_data()
    for profession in data["professions"]:
        for trainer in profession["trainers"]:
            assert trainer["entity_evidence"] == "FOREVER_OBSERVED"
            if trainer["place_evidence"] != "FOREVER_OBSERVED":
                assert not any(k in trainer for k in ("zone", "map_id", "x", "y", "title"))
        for recipe in profession["recipes"]:
            for source in recipe["acquisition_sources"]:
                assert source["evidence"] in {"FOREVER_OBSERVED", "FOREVER_CLIENT"}
            meta = recipe.get("provider_metadata", {})
            assert not ({"classic", "changed_from_classic", "classic_vendors", "leftover_of"} & set(meta))
            assert meta.get("trainer_cost_copper") is None or meta.get("trainer_cost_evidence") == "FOREVER_OBSERVED"
            skill = recipe.get("skill", {})
            assert "orange_classic" not in skill and "orange_source" not in skill
            if skill.get("orange_evidence") != "FOREVER_CLIENT":
                assert "orange" not in skill
            if skill.get("other_threshold_evidence") != "FOREVER_CLIENT":
                assert not any(k in skill for k in ("yellow", "green", "grey"))


def test_projection_is_idempotent_and_fail_closed_for_non_client_structure():
    data = load_data()
    projected, counts = project(data)
    assert projected == data
    assert counts["recipes_retained"] == 2350
    bad = json.loads(json.dumps(data))
    bad["professions"][0]["recipes"][0]["structure_evidence"] = "UNKNOWN"
    try:
        project(bad)
    except ValueError as exc:
        assert "non-client recipe structure" in str(exc)
    else:
        raise AssertionError("projection must fail closed for non-client recipe structures")


def test_runtime_contains_no_borrowed_or_unknown_source_rows():
    text = RUNTIME.read_text(encoding="utf-8")
    assert '"CLASSIC_BORROWED"' not in text
    assert '"evidence"="UNKNOWN"' not in text
    assert '"speculative"=true' not in text


def test_distribution_runtime_provider_harness():
    import shutil
    import subprocess
    lua = shutil.which("texlua") or shutil.which("lua")
    assert lua, "texlua/lua is required for the ForeverDB runtime harness"
    result = subprocess.run(
        [lua, str(ROOT / "tests" / "foreverdb_provider_0_5_3_harness.lua"),
         str(RUNTIME), str(ROOT / "AddOns" / "ModuloMarket" / "ProfessionData.lua")],
        check=True, capture_output=True, text=True,
    )
    assert "baseline-plus-delta provider harness passed" in result.stdout


def test_unfiltered_canonical_snapshots_are_not_distributed():
    for build in ("70862", "70888", "70938"):
        assert not (ROOT / "data" / f"ForeverDB-Canonical-1.60.1.{build}.json").exists()
    assert DATA.exists()
