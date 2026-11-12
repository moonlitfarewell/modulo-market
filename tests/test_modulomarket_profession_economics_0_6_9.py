import json
from pathlib import Path

ROOT = Path(__file__).parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
DATA = (ROOT / "AddOns/ModuloMarket/ProfessionData.lua").read_text()
GATHER = (ROOT / "AddOns/ModuloMarket/GatheringItems.lua").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_native_profession_list_is_the_authority_for_absence():
    assert "GetProfessions" in DATA and "GetProfessionInfo" in DATA
    assert "characterProfessionDataKnown = apiKnown" in DATA
    assert 'if not characterProfessionDataKnown then return "unknown" end' in DATA
    assert "HasAuthoritativeProfessionList" in DATA


def test_skill_requirement_and_current_skill_are_both_retained():
    assert "recipe.currentProfessionSkill" in DATA
    assert "recipe.requiredSkill = required" in DATA
    assert "recipe.canLearnNow" in DATA
    assert '"Your skill "' in UI and '" · Requires "' in UI


def test_unknown_profession_state_is_not_coloured_as_unlearnable():
    row = UI.split("function UI.RenderRows()", 1)[1].split("local vendorInfoEvents", 1)[0]
    assert 'status == "unlearnable" and "|cffff6666"' in row
    assert 'or "|cffb7c0cc"' in row
    assert "not professionStatusReady" in UI


def test_crafts_tab_replaces_both_older_craft_tabs():
    tabs = UI.split("local tabSpecs = {", 1)[1].split("local tabX =", 1)[0]
    assert '"crafts", "Crafts"' in tabs
    assert '"crafting"' not in tabs and '"allcrafts"' not in tabs
    assert '"My Crafts"' not in UI and '"All Crafts"' not in UI


def test_economics_is_a_distinct_price_and_craft_analysis_view():
    assert 'labels = { "Item", "Cheapest", "Craft cost", "Price change", "Total units", "Best craft profit" }' in UI
    assert 'keys = { "name", "price", "materials", "change", "total", "profit" }' in UI
    assert "economicsFilters" in UI
    for key in ("crafted", "gathered", "material", "other"):
        assert f'filters.{key}' in UI
    assert "Dropped / loot" in UI and "Vendor sourced" in UI
    assert "check:Disable()" in UI


def test_skinning_mapping_is_explicitly_a_conservative_core_tier_subset():
    assert "Skinning includes the core classic leather/hide progression items" in GATHER
    for item_id in (783, 2318, 4232, 2319, 4235, 4234, 4305, 4304, 8171, 8170):
        assert f'[{item_id}] = {{ 393,' in GATHER


def test_manifest_and_addon_versions_agree():
    assert MANIFEST["version"] == "0.6.9"
    assert 'MM.version = "0.6.9"' in (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
    assert '## Version: 0.6.9' in (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
