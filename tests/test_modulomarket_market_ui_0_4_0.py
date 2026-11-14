from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"
UI = (ADDON / "MarketUI.lua").read_text()
DATA = (ADDON / "ProfessionData.lua").read_text()
TOC = (ADDON / "ModuloMarket.toc").read_text()


def test_window_front_accessibility_and_escape():
    assert re.search(r"^## Version: 0\.6\.3$", TOC, re.M)
    assert 'frame:SetFrameStrata("DIALOG")' in UI
    assert 'frame:SetFrameStrata("TOOLTIP")' not in UI
    assert "frame:SetToplevel(true)" in UI
    assert '"ModuloMarketMainFrame"' in UI
    assert "UISpecialFrames" in UI
    assert "AttachAuctionHouseButton" in UI
    assert '"AUCTION_HOUSE_SHOW"' in UI


def test_tabs_are_visually_distinct_and_column_widths_prevent_wrapping():
    assert "selectedMark" in UI
    assert "tabStrip" in UI
    assert 'SetThemeTexture(button.selectedMark, "accent", {1, 0.72, 0.18, 1})' in UI
    assert 'row.name = RowText("LEFT", 27, 182, "LEFT")' in UI
    assert 'row.price = RowText("LEFT", 212, 105, "RIGHT")' in UI
    assert "fs:SetWordWrap(false)" in UI
    assert "row.depth = RowText" in UI
    assert "visibleCount = 25" in UI
    assert "UpdateResultRange" in UI
    assert '"%d-%d / %d"' in UI
    assert "Sorting all %d" in UI


def test_profession_and_item_role_filters_are_wired():
    RECIPE = (ADDON / "RecipeEngine.lua").read_text()
    assert "professionID = tonumber(recipe.professionID)" in RECIPE
    assert "UI.professionDropdown" in UI
    assert "UI.roleDropdown" in UI
    assert "Unlearned crafts (install DB)" in UI
    assert "disabled = not futureReady" in UI
    assert "professionFilter = UI.professionFilter" in UI
    assert "itemRoleFilter = UI.itemRoleFilter" in UI
    assert "MM.ProfessionData.Matches" in UI


def test_future_recipe_catalogue_is_optional_and_provenance_aware():
    assert "## OptionalDeps: LibProfessionDB" in TOC
    assert "ProfessionData.lua" in TOC
    assert 'db:GetGameVersion()' in DATA or '"GetGameVersion"' in DATA
    assert "GetRecipeSources" in DATA
    assert "IsHiddenRecipe" in DATA
    assert "IsBorrowed" in DATA
    assert "unknownFutureCrafts" in DATA
    assert "borrowedSources" in DATA
    assert "futureBorrowed" in DATA
    assert "futureBorrowed" in UI
    assert "sourceUnknown" in DATA


def test_gathering_uses_explicit_item_ids_and_only_character_known_gathering_professions():
    GATHERING = (ADDON / "GatheringItems.lua").read_text()
    TOC = (ADDON / "ModuloMarket.toc").read_text()
    assert "GatheringItems.lua" in TOC
    assert 'value = "gather"' in UI
    assert "HasGatheringData" in UI
    assert "[2770] = { 186, 1 }" in GATHERING
    assert "[2447] = { 182, 1 }" in GATHERING
    assert "[4603] = { 356, 130 }" in GATHERING
    assert "requiredSkill" in DATA and "currentSkill" in DATA
    assert "knownProfessions[professionID]" in DATA
    assert "Skinning" in GATHERING
    assert len(re.findall(r"^\s*\[\d+\] = \{", GATHERING, re.M)) == 87


def test_manifest_inventory_matches_files():
    manifest = json.loads((ROOT / "MANIFEST.json").read_text())
    assert manifest["version"] == "0.6.3"
    actual = sorted(
        p.relative_to(ROOT).as_posix()
        for p in ROOT.rglob("*")
        if p.is_file() and "__pycache__" not in p.parts
        and ".pytest_cache" not in p.parts and p.suffix != ".pyc"
    )
    assert sorted(manifest["files"]) == actual
