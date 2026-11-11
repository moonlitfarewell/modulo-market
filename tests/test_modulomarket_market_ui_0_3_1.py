from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"
UI = (ADDON / "MarketUI.lua").read_text()
ENGINE = (ADDON / "RecipeEngine.lua").read_text()
TOC = (ADDON / "ModuloMarket.toc").read_text()


def test_versions_and_complete_recipe_capture_are_not_capped_at_twenty():
    assert re.search(r"^## Version: 0\.5\.2$", TOC, re.M)
    assert "state.index + 19" in ENGINE  # bounded batch, not a total limit
    assert "if state.index <= #state.recipeIDs then" in ENGINE
    assert "for id, oldRecipe in pairs(previous.recipes)" in ENGINE
    assert "MAX_RECIPES" not in ENGINE
    assert "all %d" in UI.lower()


def test_market_search_is_tokenized_and_searches_relevant_item_and_recipe_fields():
    assert "NormalizeSearchText" in UI
    assert "MatchesSearch(item, build.query, isCrafting)" in UI
    assert "item.variants" in UI
    assert "item.reagentLines" in UI
    assert "item.itemID" in UI


def test_sortable_headers_cover_all_items_and_crafts():
    assert "UI.headerButtons" in UI
    assert 'market = { key = "name", ascending = true }' in UI
    assert 'sortKey = "price"' in UI
    assert 'sortKey = "depth"' in UI
    assert 'sortKey = "profit"' in UI
    assert "ComesBefore(a, b, key, ascending)" in UI
    assert "UI.sortByTab" in UI
    assert "UpdateHeaderIndicators" in UI
    assert r"Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up" in UI and r"Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up" in UI
    assert "local budget = 500" in UI


def test_money_uses_gold_silver_copper_icons_and_coin_colours():
    for icon in ("UI-GoldIcon", "UI-SilverIcon", "UI-CopperIcon"):
        assert icon in UI
    for colour in ("ffffd700", "ffc7c7cf", "ffeda55f"):
        assert colour in UI


def test_market_background_is_translucent_without_fading_controls():
    assert "function ApplyBackgroundOpacity(frame, alpha)" in UI
    assert "UI.opacitySlider" in UI
    assert "MM.db.backgroundOpacity = alpha" in UI


def test_manifest_inventory_includes_new_audit_and_tests():
    manifest = json.loads((ROOT / "MANIFEST.json").read_text())
    assert manifest["version"] == "0.5.2"
    assert "MODULOMARKET-RUNTIME-AUDIT-0.4.0.md" in manifest["files"]
    assert "tests/test_modulomarket_market_ui_0_3_1.py" in manifest["files"]
    actual = sorted(
        p.relative_to(ROOT).as_posix()
        for p in ROOT.rglob("*")
        if p.is_file() and "__pycache__" not in p.parts
        and ".pytest_cache" not in p.parts and p.suffix != ".pyc"
    )
    assert sorted(manifest["files"]) == actual
