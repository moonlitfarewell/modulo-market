import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools" / "foreverdb_importer"))
sys.path.insert(0, str(ROOT / "tools"))
from market_data_importer import validate_canonical
from verify_repository_tree import git_blob_sha1, verify_repository_tree
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


def test_release_manifest_matches_local_package_inventory_and_hashes():
    manifest = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))
    declared = set(manifest["files"])
    actual = {
        p.relative_to(ROOT).as_posix()
        for p in ROOT.rglob("*")
        if p.is_file()
        and "__pycache__" not in p.parts
        and ".pytest_cache" not in p.parts
        and p.suffix != ".pyc"
    }
    repository_only = actual - declared
    assert declared <= actual
    assert all(path.startswith("tests/") or path == "MODULOMARKET-RUNTIME-AUDIT-0.7.9.md"
               for path in repository_only)
    assert len(repository_only) == 73
    assert manifest["file_count"] == len(declared)
    assert "MANIFEST.json" in declared
    assert set(manifest["git_blob_sha1"]) == declared - {"MANIFEST.json"}
    assert manifest["git_blob_sha1_excludes"] == ["MANIFEST.json"]
    for rel, expected in manifest["git_blob_sha1"].items():
        payload = (ROOT / rel).read_bytes()
        try:
            payload.decode("utf-8")
        except UnicodeDecodeError:
            pass
        else:
            payload = payload.replace(b"\r\n", b"\n")
        header = f"blob {len(payload)}\0".encode("ascii")
        assert hashlib.sha1(header + payload).hexdigest() == expected


def test_repository_tree_verifier_separates_repo_only_history_and_rejects_raw_canonical(tmp_path):
    package = tmp_path / "package"
    package.mkdir()
    (package / "tests").mkdir()
    (package / "README.md").write_text("package readme\n", encoding="utf-8")
    (package / "tests" / "test_core.py").write_text("assert True\n", encoding="utf-8")
    package_files = ["MANIFEST.json", "README.md", "tests/test_core.py"]
    manifest = {"file_count": len(package_files), "files": package_files}
    (package / "MANIFEST.json").write_text(json.dumps(manifest), encoding="utf-8")
    tree_entries = []
    for rel in package_files:
        tree_entries.append({
            "path": rel, "type": "blob", "sha": git_blob_sha1(package / rel)
        })
    tree_entries.extend([
        {"path": "tests/historical/test_old.py", "type": "blob", "sha": "a" * 40},
        {"path": "MODULOMARKET-RUNTIME-AUDIT-0.7.9.md", "type": "blob", "sha": "b" * 40},
    ])
    clean_tree = {"sha": "clean-fixture", "truncated": False, "tree": tree_entries}
    errors, summary = verify_repository_tree(package, clean_tree)
    assert errors == []
    assert summary["repository_blobs"] == 5
    assert summary["release_manifest_files"] == 3
    assert summary["repository_only_files"] == 2

    dirty_tree = {
        "sha": "dirty-fixture",
        "truncated": False,
        "tree": tree_entries + [
            {"path": "data/ForeverDB-Canonical-1.60.1.70938.json",
             "type": "blob", "sha": "c" * 40}
        ],
    }
    errors, _ = verify_repository_tree(package, dirty_tree)
    assert any("Forbidden unfiltered canonical snapshot" in e for e in errors)
