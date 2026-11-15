from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / 'AddOns/ModuloMarket/MarketUI.lua').read_text()
RECIPE = (ROOT / 'AddOns/ModuloMarket/RecipeEngine.lua').read_text()
DATA = (ROOT / 'AddOns/ModuloMarket/ProfessionData.lua').read_text()
CORE = (ROOT / 'AddOns/ModuloMarket/Core.lua').read_text()
TOC = (ROOT / 'AddOns/ModuloMarket/ModuloMarket.toc').read_text()
MANIFEST = (ROOT / 'MANIFEST.json').read_text()

def test_release_versions_agree():
    assert 'MM.version = "0.7.1"' in CORE
    assert '## Version: 0.7.1' in TOC
    assert '"version": "0.7.1"' in MANIFEST

def test_account_and_character_scope_are_persistent_and_visible():
    assert 'MM.db.craftingScope = "account"' in CORE
    assert 'Account Crafting' in UI and 'Character Crafting' in UI
    assert 'UI.craftingScope = value == "character" and "character" or "account"' in UI
    assert 'MM.Recipes.GetAllRecipes(UI.craftingScope)' in UI

def test_account_union_is_keyed_by_character_and_deduplicates_recipes():
    assert 'function Recipes.GetAllRecipes(scope)' in RECIPE
    assert 'professionRecipesByCharacter' in RECIPE
    assert 'local key = tostring(profession.professionID or professionID) .. ":" .. tostring(recipeID)' in RECIPE
    assert 'copy.characterKey = character.key' in RECIPE

def test_account_absence_is_not_negative_profession_evidence():
    assert 'return skills, names, false' in DATA
    assert 'function Data.HasAnyProfessionEvidence()' in DATA
    assert 'UI.craftingScope == "account"' in UI

def test_native_profession_snapshot_is_character_scoped():
    assert 'function Recipes.SaveCharacterProfessionSnapshot' in RECIPE
    assert 'store._professionSnapshot' in RECIPE
    assert 'SaveCharacterProfessionSnapshot(skills, names, true)' in DATA

def test_tooltip_search_is_cached_and_async():
    assert 'GetTooltipSearchText(item.itemID)' in UI
    assert 'ModuloMarketSearchTooltip' in UI
    assert 'ITEM_DATA_LOAD_RESULT' in UI
    assert 'GET_ITEM_INFO_RECEIVED' in UI
    assert 'tooltipSearchCache' in UI

def test_economics_columns_are_right_anchored_and_item_gets_remainder():
    assert 'local right = 1106' in UI
    assert 'local xProfit = right - widths.profit' in UI
    assert 'math.max(90, xPrice - 302 - 6)' in UI
