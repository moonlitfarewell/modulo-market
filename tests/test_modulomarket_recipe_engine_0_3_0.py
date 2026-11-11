from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"
ENGINE = (ADDON / "RecipeEngine.lua").read_text()
UI = (ADDON / "MarketUI.lua").read_text()
TOC = (ADDON / "ModuloMarket.toc").read_text()


def test_recipe_engine_is_loaded_before_market_ui_and_is_market_owned():
    assert re.search(r"^## Version: 0\.5\.1$", TOC, re.M)
    assert TOC.index("RecipeEngine.lua") < TOC.index("MarketUI.lua")
    assert "MM.Recipes = Recipes" in ENGINE
    assert "api.GetAllRecipeIDs" in ENGINE


def test_capture_is_automatic_bounded_and_character_scoped():
    assert '"TRADE_SKILL_SHOW"' in ENGINE
    assert '"TRADE_SKILL_LIST_UPDATE"' in ENGINE
    assert '"TRADE_SKILL_DATA_SOURCE_CHANGED"' in ENGINE
    assert 'captureFrame:SetScript("OnUpdate"' in ENGINE
    assert "state.index + 19" in ENGINE
    assert "professionRecipesByCharacter" in ENGINE
    assert "info.learned == true" in ENGINE


def test_recipe_cost_requires_known_market_prices_and_real_output_quantity():
    assert "slot.quantityRequired" in ENGINE
    assert "slot.variable" in ENGINE
    assert "everyChoicePriced" in ENGINE
    assert "result.materialCostCopper = totalCost" in ENGINE
    assert "result.profitCopper = result.netSaleCopper - result.materialCostCopper" in ENGINE
    assert "if result.salePriceCopper and result.salePriceCopper > 0 and result.outputQuantity then" in ENGINE


def test_manual_cost_basis_is_not_part_of_the_crafting_ui():
    assert 'CreateInput(frame, "Your cost / unit (gold)"' not in UI
    assert 'CreateInput(frame, "Target sale price (gold, optional)"' not in UI
    assert "RenderMarketRecipeContext" in UI
    assert "RenderCraftDetail" in UI
    assert "tabSpecs" in UI and "crafting" in UI
    assert "tabSpecs" in UI and "allcrafts" in UI


def test_market_keeps_replicate_and_transaction_safety_boundaries():
    source = "\n".join(path.read_text() for path in ADDON.glob("*.lua"))
    for forbidden in ("PlaceAuctionBid(", "PostItem(", "CancelAuction(", "CraftRecipe("):
        assert forbidden not in source
