from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")


def test_view_rows_are_compacted_before_sort_count_and_key_preparation():
    compact = SOURCE.index("local function CompactSortRows")
    compact_call = SOURCE.index("build.rows = CompactSortRows(build.rows)")
    sort_init = SOURCE.index("UI.rankSort = {", compact_call)
    assert compact < compact_call < sort_init
    assert "type(entry.row) == \"table\"" in SOURCE[compact:compact_call]


def test_cached_sort_comparator_handles_missing_keys_without_indexing_nil():
    start = SOURCE.index("local function SortKeysComeBefore")
    end = SOURCE.index("\nlocal function StepRankSort()", start)
    comparator = SOURCE[start:end]
    assert "if a == nil then return false end" in comparator
    assert "if b == nil then return true end" in comparator
    assert "a.primary == b.primary" in comparator


def test_version_metadata_is_aligned_to_1_0_3():
    toc = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
    core = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
    turnin = (ROOT / "AddOns/ModuloMarket/TurnInData.lua").read_text(encoding="utf-8")
    manifest = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))
    assert "## Version: 1.0.3" in toc
    assert 'MM.version = "1.0.3"' in core
    assert 'version = "1.0.3"' in turnin
    assert manifest["version"] == "1.0.3"
