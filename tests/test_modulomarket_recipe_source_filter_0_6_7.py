import json
from pathlib import Path

ROOT = Path(__file__).parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
PROFESSION = (ROOT / "AddOns/ModuloMarket/ProfessionData.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_crafts_tab_has_character_aware_three_state_filter():
    block = UI.split('local function GetRoleOptions()', 1)[1].split('UI.roleDropdown = CreateDropdown', 1)[0]
    assert '{ text = "All recipes", value = "all"' in block
    assert '{ text = "Known by you", value = "known"' in block
    assert '{ text = "Learnable", value = "learnable"' in block
    assert '{ text = "Not learnable", value = "unlearnable"' in block
    assert 'GetRecipeLearningStatus' in UI
    assert 'characterProfessions[pid]' in PROFESSION


def test_recipe_status_is_based_on_character_profession_ownership():
    assert 'function Data.GetRecipeLearningStatus(recipe)' in PROFESSION
    assert 'if characterProfessions[pid] then return "learnable" end' in PROFESSION
    assert 'return "unlearnable"' in PROFESSION
    assert 'recipe.currentProfessionSkill' in PROFESSION
    assert 'recipe.canLearnNow' in PROFESSION


def test_materials_and_item_views_expose_the_same_three_statuses():
    block = UI.split('local function GetRoleOptions()', 1)[1].split('UI.roleDropdown = CreateDropdown', 1)[0]
    assert '"Learnable craft outputs"' in block
    assert '"Unavailable craft outputs"' in block
    assert 'role == "learnable" or role == "unlearnable"' in PROFESSION


def test_old_my_crafts_tab_is_consolidated_into_crafts():
    assert '{ "crafts", "Crafts", 194 }' in UI
    assert '"My Crafts"' not in UI
    assert '"All Crafts"' not in UI
    assert 'build.tab == "crafts"' in UI
    assert 'UI.activeTab == "crafts"' in UI


def test_economics_has_distinct_market_analysis_and_relationship_filters():
    assert 'labels = { "Item", "Cheapest", "Craft cost", "Price change", "Total units", "Best craft profit" }' in UI
    for label in ("Crafted outputs", "Gathered / collected", "Crafting reagents", "Other market items"):
        assert label in UI
    assert 'filters.crafted' in UI and 'filters.gathered' in UI and 'filters.material' in UI
    assert 'Dropped / loot' in UI and 'Vendor sourced' in UI
    assert 'check:Disable()' in UI


def test_skinning_core_leather_tiers_are_mapped():
    gathering = (ROOT / "AddOns/ModuloMarket/GatheringItems.lua").read_text()
    for item_id in (783, 2318, 4232, 2319, 4235, 4234, 4305, 4304, 8171, 8170):
        assert f'[{item_id}] = {{ 393,' in gathering


def test_recipe_row_colours_match_requested_statuses():
    assert 'status == "known" and "|cff8ee6a2"' in UI
    assert 'status == "unlearnable" and "|cffff6666"' in UI
    assert 'status == "learnable" and "|cffffd77a"' in UI


def test_release_versions_agree():
    assert f'MM.version = "{MANIFEST["version"]}"' in CORE
    assert f'## Version: {MANIFEST["version"]}' in TOC
    assert MANIFEST["version"] == CORE.split('MM.version = "', 1)[1].split('"', 1)[0]
