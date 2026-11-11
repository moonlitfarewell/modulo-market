import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOL_DIR = ROOT / "tools" / "foreverdb_importer"
sys.path.insert(0, str(TOOL_DIR))

import market_data_importer as importer

FIXTURE = TOOL_DIR / "fixtures" / "canonical-sample.synthetic.json"


class FakeResponse:
    def __init__(self, payload, status=200, headers=None):
        self.body = payload if isinstance(payload, bytes) else json.dumps(payload).encode("utf-8")
        self.status = status
        self.headers = headers or {}

    def read(self):
        return self.body

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False


def test_canonical_contract_preserves_fixed_variable_and_unknown_outputs():
    data = json.loads(FIXTURE.read_text(encoding="utf-8"))
    assert importer.validate_canonical(data) == []
    outputs = [out for profession in data["professions"] for recipe in profession["recipes"] for out in recipe["outputs"]]
    assert [(out["quantity_min"], out["quantity_max"]) for out in outputs] == [(1, 1), (1, 3), (None, None)]
    assert outputs[-1]["quantity_evidence"] == "UNKNOWN"


def test_validator_rejects_invalid_quantities_and_duplicate_recipe_ids():
    data = json.loads(FIXTURE.read_text(encoding="utf-8"))
    first = data["professions"][0]["recipes"][0]
    first["outputs"][0]["quantity_min"] = -1
    data["professions"][0]["recipes"].append(dict(first))
    errors = importer.validate_canonical(data)
    assert any("quantity_min must be a positive integer" in error for error in errors)
    assert any("duplicate recipe_id" in error for error in errors)


def test_compiler_refuses_synthetic_fixture_without_explicit_allow_flag(tmp_path):
    data = json.loads(FIXTURE.read_text(encoding="utf-8"))
    try:
        importer.compile_canonical(data, tmp_path)
    except importer.ImporterError as exc:
        assert "synthetic fixture" in str(exc)
    else:
        raise AssertionError("synthetic fixture must not compile by default")


def test_compiler_emits_attribution_and_does_not_fill_unknown_output_yield(tmp_path):
    data = json.loads(FIXTURE.read_text(encoding="utf-8"))
    paths = importer.compile_canonical(data, tmp_path, allow_fixture=True)
    assert len(paths) == 3
    index = (tmp_path / "ForeverDBData.lua").read_text(encoding="utf-8")
    alchemy = (tmp_path / "ForeverDBData-alchemy.lua").read_text(encoding="utf-8")
    assert "Data from ForeverDB.net" in index
    assert "https://foreverdb.net" in index
    assert "quantity_min" in alchemy and "quantity_max" in alchemy
    assert "syntheticFixture" in index
    # Unknown values are still explicit nils in the generated table source.
    assert '["quantity_min"] = nil' in alchemy
    assert '["quantity_max"] = nil' in alchemy


def test_capture_uses_environment_secret_for_header_only_and_archives_raw_json(tmp_path):
    secret = "fdb_DO_NOT_PERSIST_THIS_TEST_KEY"
    calls = []

    def fake_open(request, timeout=0):
        headers = {key.lower(): value for key, value in request.header_items()}
        calls.append((request.full_url, headers))
        if request.full_url.endswith("/meta"):
            payload = {"data": {"build": "1.60.1.70862"}, "meta": {}}
        elif "/professions?" in request.full_url:
            payload = {"data": [{"slug": "alchemy"}], "meta": {"total": 1}}
        else:
            payload = {"data": [{"id": 123, "name": "Test Recipe"}], "meta": {"total": 1}}
        return FakeResponse(payload)

    client = importer.ForeverDBClient(secret, opener=fake_open, sleeper=lambda _s: None, clock=lambda: 10.0)
    manifest = importer.capture(client, tmp_path, max_requests=10)
    assert manifest["request_count"] == 3
    assert any(headers.get("x-api-key") == secret for _, headers in calls)
    manifest_text = (tmp_path / "capture-manifest.json").read_text(encoding="utf-8")
    assert secret not in manifest_text
    assert all(secret not in url for url, _ in calls)
    assert (tmp_path / "meta.json").exists()
    assert (tmp_path / "professions-index.json").exists()
    assert (tmp_path / "professions/alchemy/offset-000000.json").exists()
    assert all(row["sha256"] for row in manifest["responses"])


def test_capture_paginates_only_explicit_recipe_arrays_to_reported_total(tmp_path):
    urls = []

    def fake_open(request, timeout=0):
        url = request.full_url
        urls.append(url)
        if url.endswith("/meta"):
            payload = {"data": {"build": "1.60.1.70862"}, "meta": {}}
        elif "/professions?" in url:
            payload = {"data": [{"slug": "mining"}], "meta": {"total": 1}}
        elif "offset=0" in url:
            payload = {"data": [{"id": 1}, {"id": 2}], "meta": {"total": 3}}
        else:
            payload = {"data": [{"id": 3}], "meta": {"total": 3}}
        return FakeResponse(payload)

    client = importer.ForeverDBClient("fdb_TEST", opener=fake_open, sleeper=lambda _s: None, clock=lambda: 10.0)
    manifest = importer.capture(client, tmp_path, page_size=2, max_requests=10)
    report = manifest["profession_reports"][0]
    assert report["pages_captured"] == 2
    assert report["recipe_records_captured"] == 3
    assert report["pagination_shape_unknown"] is False
    assert any("offset=2" in url for url in urls)


def test_capture_preserves_rank_wrapped_response_and_marks_pagination_unknown(tmp_path):
    def fake_open(request, timeout=0):
        if request.full_url.endswith("/meta"):
            payload = {"data": {"build": "1.60.1.70862"}, "meta": {}}
        elif "/professions?" in request.full_url:
            payload = {"data": [{"slug": "mining"}], "meta": {"total": 1}}
        else:
            payload = {"data": {"ranks": [{"name": "Apprentice", "recipes": [{"id": 1}]}]}, "meta": {"total": 1}}
        return FakeResponse(payload)

    client = importer.ForeverDBClient("fdb_TEST", opener=fake_open, sleeper=lambda _s: None, clock=lambda: 10.0)
    manifest = importer.capture(client, tmp_path, max_requests=10)
    assert manifest["profession_reports"][0]["pagination_shape_unknown"] is True
    raw = json.loads((tmp_path / "professions/mining/offset-000000.json").read_text(encoding="utf-8"))
    assert raw["data"]["ranks"][0]["recipes"][0]["id"] == 1


def test_client_refuses_rate_limit_settings_that_exceed_documented_ceiling():
    try:
        importer.ForeverDBClient("fdb_TEST", delay=0.5)
    except importer.ImporterError as exc:
        assert "60/minute" in str(exc)
    else:
        raise AssertionError("too-fast request interval should be rejected")


def test_inspector_verifies_raw_hashes(tmp_path):
    body = json.dumps({"data": {"build": "1.60.1.70862"}, "meta": {}}).encode()
    (tmp_path / "meta.json").write_bytes(body)
    manifest = {"provider": "ForeverDB.net", "client_build": "1.60.1.70862", "request_count": 1,
                "responses": [{"relative_path": "meta.json", "sha256": importer.sha256(body)}]}
    (tmp_path / "capture-manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    report = importer.inspect_capture(tmp_path)
    assert report["files"][0]["sha256_valid"] is True
    assert any("$.data.build" in line for line in report["files"][0]["shape"])
