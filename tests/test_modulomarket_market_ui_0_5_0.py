from pathlib import Path
import json
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
DATA = (ROOT / "AddOns/ModuloMarket/ProfessionData.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_050_version_and_separate_child_boundary():
    assert 'MM.version = "0.6.2"' in CORE
    assert re.search(r"^## Version: 0\.6\.2$", TOC, re.M)
    assert MANIFEST["version"] == "0.6.2"
    assert "## Dependencies: Modulo" in TOC
    assert "ModuloMarket" not in (ROOT / "AddOns/Modulo/Modulo.toc").read_text() if (ROOT / "AddOns/Modulo/Modulo.toc").exists() else True


def test_050_seven_tabs_replace_profitable_with_all_crafts_and_economics():
    block = UI[UI.index("local tabSpecs = {"):UI.index("local tabX =", UI.index("local tabSpecs = {"))]
    for label in ("All Items", "Economics", "My Crafts", "All Crafts", "Materials", "Low Supply", "History"):
        assert f'"{label}"' in block
    assert '"opportunities"' not in UI
    assert 'button.tooltipText = "Only recipes you have learned' in UI
    assert "All recipe candidates" in UI


def test_050_economics_uses_market_recipe_and_vendor_values_without_manual_inputs():
    assert "local function StartEconomicsIndex()" in UI
    assert "local function StepEconomicsIndex()" in UI
    assert "build.index + 99" in UI
    assert "UI.economicsByItemID = build.byID" in UI
    assert "GetVendorInfo(item.itemID, true)" in UI
    assert "Vendor sell / unit:" in UI
    assert "Vendor profit / craft:" in UI
    assert 'CreateInput(frame, "Your cost / unit (gold)"' not in UI
    assert 'CreateInput(frame, "Target sale price (gold, optional)"' not in UI


def test_050_all_crafts_distinguishes_known_future_borrowed_and_unknown_sources():
    assert "Data.GetAllFutureRecipes()" in UI
    assert 'recipe.borrowedSources and "borrowed"' in UI
    assert 'recipe.sourceUnknown and "unknown"' in UI
    assert 'value = "borrowed"' in UI
    assert 'value = "unknown"' in UI
    assert "Acquisition source borrowed from Vanilla; not confirmed in Forever." in UI
    assert "Acquisition source unknown; availability is not established." in UI


def test_050_gathering_classification_does_not_require_current_skill():
    add = DATA[DATA.index("local function AddGatheringItems"):DATA.index("local function AddKnownRecipes")]
    assert "AddProfession(itemID, professionID, professionName)" in add
    assert "canGatherNow = currentSkill ~= nil and currentSkill >= requiredSkill" in add
    assert "if professionID and currentSkill and requiredSkill and currentSkill >= requiredSkill then" not in add
    assert 'elseif role == "gather"' in DATA


def test_050_materials_are_indexed_from_known_and_candidate_recipe_reagents():
    assert "material.materialForCraft = true" in DATA
    assert "function Data.GetMaterialItems()" in DATA
    assert "local function GetMaterialCatalog()" in UI
    assert "noMarketData = true" in UI
    assert 'value = "material"' in UI


def test_050_item_role_filter_is_available_across_views():
    assert "UI.roleDropdown:Enable()" in UI
    assert "if UI.roleDropdown then UI.roleDropdown:SetEnabled(tab == " not in UI
    assert 'UI.activeTab == "allcrafts"' in UI
    assert 'UI.activeTab == "crafting"' in UI
    assert "Profession filter" not in UI  # filter semantics remain explicit in controls


def test_050_relationship_text_uses_real_newlines_and_role_colours():
    assert 'SetDetailEconomics(table.concat(lines, "\\n"))' in UI
    assert '"|cff80cfff[M]|r"' in UI
    assert '"|cff66ccff[G]|r"' in UI
    assert '"|cff55dd77[C]|r"' in UI


def test_050_low_supply_is_role_adjusted_and_distinguishes_units_from_listings():
    assert "local function GetLowSupplyThreshold(item)" in UI
    assert "return base * 5" in UI
    assert "return base * 2" in UI
    assert '"Listings", "Best Craft Profit"' in UI and 'item.auctionCountKnown and tostring(item.auctionCount or 0)' in UI
    assert "item.auctionCountKnown and tostring(item.auctionCount or 0)" in UI


def test_050_history_shows_change_and_four_point_graph():
    assert "return found[1] - found[2]" in UI
    assert 'keys = { "name", "price", "change", "total", "total", "profit" }' in UI
    assert "UI.historyGraph" in UI
    assert "for i = 1, 4 do" in UI
    assert "bar:SetColorTexture(0.22, 0.72, 0.38, 0.95)" in UI
    assert "bar:SetColorTexture(0.78, 0.25, 0.22, 0.95)" in UI


def test_050_tab_tooltips_are_raised_above_market():
    assert "local function RaiseMarketTooltip" in UI
    assert 'GameTooltip:SetFrameStrata("TOOLTIP")' in UI
    assert "ownerLevel + 100" in UI


def test_050_catalogue_render_stays_virtualized_and_incremental():
    render = UI[UI.index("function UI.RenderRows()"):UI.index("function UI.RenderHistory()")]
    assert "math.min(UI.visibleCount or rowPoolCount, rowPoolCount)" in render
    assert "RequestLoadItemDataByID" not in render
    assert "GetItemInfo" not in render
    assert "local budget = 500" in UI
    assert "elseif UI.economicsIndexBuild then StepEconomicsIndex()" in UI


def test_050_lua_ui_integration_harness():
    texlua = shutil.which("texlua")
    if not texlua:
        import pytest
        pytest.skip("texlua is not installed in this environment")
    result = subprocess.run(
        [texlua, "tests/market_ui_0_5_0_harness.lua", "AddOns/ModuloMarket/MarketUI.lua"],
        cwd=ROOT, text=True, capture_output=True, check=False,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert "ModuloMarket 0.5.3 UI harness passed" in result.stdout
