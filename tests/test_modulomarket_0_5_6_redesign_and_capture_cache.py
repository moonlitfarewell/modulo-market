from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"
UI = (ADDON / "MarketUI.lua").read_text()
ENGINE = (ADDON / "RecipeEngine.lua").read_text()
CORE = (ADDON / "Core.lua").read_text()
TOC = (ADDON / "ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_three_column_workspace_retains_seven_tabs_and_market_toolbar():
    for tab in ('"market", "All Items"', '"economics", "Economics"',
                '"crafting", "My Crafts"', '"allcrafts", "All Crafts"',
                '"materials", "Materials"', '"low", "Low Supply"',
                '"history", "History"'):
        assert tab in UI
    assert 'AddButton(frame, "Update Full Market"' in UI
    assert 'AddButton(frame, "Browse Scan"' in UI
    assert 'Filters — All Items' in UI
    assert 'Selected item' in UI
    assert 'centerPanel:SetSize(780, 650)' in UI


def test_all_crafts_keeps_full_economic_columns():
    for label in ('"Sale / Unit"', '"Materials"', '"At Price"', '"Total"', '"Profit / Craft"'):
        assert label in UI
    assert 'button.atPrice:SetText(item.minPriceQuantity' in UI
    assert 'button.total:SetText(item.totalQuantity' in UI
    assert 'button.profit:SetText(profitText)' in UI
    assert 'row.atPrice = RowText' in UI and 'row.profit = RowText' in UI


def test_filters_are_stored_per_tab():
    assert 'UI.tabFilterState[previousTab]' in UI
    assert 'local saved = UI.tabFilterState[tab] or {}' in UI
    assert 'UI.tabFilterState[UI.activeTab] = { search = "", profession = 0, role = "all" }' in UI


def test_profession_capture_caches_unchanged_recipe_lists():
    assert 'local function RecipeListSignature(recipeIDs)' in ENGINE
    assert 'previous.recipeListSignature == signature' in ENGINE
    assert 'CAPTURE_ALREADY_RUNNING' in ENGINE
    assert 'RECIPE_LIST_UNCHANGED' in ENGINE
    assert 'recipeListSignature = state.recipeListSignature' in ENGINE
    assert 'C_Timer.After(0.50, run)' in ENGINE
    assert '"NEW_RECIPE_LEARNED"' in ENGINE
    assert 'Recipes.ScheduleCapture(true)' in ENGINE
    assert 'Recipes.CaptureCurrentProfession(forceNow)' in ENGINE


def test_patch_version_and_manifest_are_0_5_7():
    assert 'MM.version = "0.5.8"' in CORE
    assert '## Version: 0.5.8' in TOC
    assert MANIFEST["version"] == "0.5.8"
