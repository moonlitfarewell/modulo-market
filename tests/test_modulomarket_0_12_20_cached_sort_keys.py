from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")


def test_sort_keys_are_prepared_incrementally_before_merge_sort():
    assert "keys = {}" in SOURCE
    assert "prepareIndex = 1" in SOURCE
    assert "if state.prepareIndex <= state.count then" in SOURCE
    assert "state.keys[row] = BuildSortKey(row, state.key, state.ascending)" in SOURCE


def test_sort_comparator_uses_cached_values_only():
    start = SOURCE.index("local function SortKeysComeBefore")
    end = SOURCE.index("\nlocal function StepRankSort()", start)
    comparator = SOURCE[start:end]
    assert "NormalizeSearchText" not in comparator
    assert "GetItemName" not in comparator
    assert "a.primary == b.primary" in comparator
    assert "a.name < b.name" in comparator
    assert "a.id < b.id" in comparator


def test_sort_preparation_and_merge_keep_existing_per_update_budgets():
    start = SOURCE.index("local function StepRankSort()")
    end = SOURCE.index("\nlocal function UpdateAllItemsColumnLayout", start)
    step = SOURCE[start:end]
    assert "local budget = 500" in step
    assert "budget = budget - 1" in step
    assert "SortKeysComeBefore(" in step


def test_all_sort_modes_keep_existing_primary_value_rules():
    start = SOURCE.index("local function BuildSortKey")
    end = SOURCE.index("\nlocal function SortKeysComeBefore", start)
    keys = SOURCE[start:end]
    for token in ['key == "name"', 'key == "price"', 'key == "depth"',
                  'key == "materials"', 'key == "total"', 'key == "completion"',
                  'key == "favor"', 'key == "reward"', 'key == "net"',
                  'key == "change"', "estimatedProfitCopper", "profitCopper"]:
        assert token in keys


def test_version_metadata_is_0_12_20():
    toc = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
    core = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
    manifest = __import__("json").loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))
    assert "## Version: 1.0.3" in toc
    assert 'MM.version = "1.0.3"' in core
    assert manifest["version"] == "1.0.3"
