from pathlib import Path
import json

ROOT = Path(__file__).parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_item_names_have_no_internal_bracket_prefixes():
    block = UI.split("local function GetItemDisplayName(item)", 1)[1].split("local function", 1)[0]
    for marker in ("[C]", "[F]", "[F?]", "[?]", "[G]", "[M]"):
        assert marker not in block
    craft_rows = UI.split("if isCrafting then", 1)[1].split("elseif UI.activeTab == \"economics\"", 1)[0]
    assert "button.name:SetText(color .. GetItemName(item) .. \"|r\")" in craft_rows
    for marker in ("[C]", "[F]", "[F?]", "[?]"):
        assert marker not in craft_rows


def test_item_quality_colours_are_separate_from_craft_status_markers():
    assert "GetItemQualityHex" in UI
    assert "_G.GetItemQualityColor" in UI
    assert 'return "|c" .. GetItemQualityHex(item and item.itemID) .. GetItemName(item) .. "|r"' in UI
    assert "local function GetItemCraftMarker(itemID)" in UI
    assert "row.statusMarker:SetWidth(3)" in UI
    assert "button.statusMarker:SetColorTexture(GetItemCraftMarker(item.itemID))" in UI
    assert "hasLearnable then return 1, 0.82, 0.24, 1" in UI
    assert "hasUnlearnableOrUnknown then return 0.95, 0.27, 0.24, 1" in UI
    assert "return 0.25, 0.88, 0.42, 1" in UI
    assert "return 1, 1, 1, 1" in UI


def test_unlearned_source_classes_share_one_player_facing_colour():
    block = UI.split("local function GetItemDisplayName(item)", 1)[1].split("local function", 1)[0]
    assert "futureBorrowed" not in block and "futureUnknown" not in block
    assert "|cffffb36b" not in block
    assert "|cffc4cbd3" not in block


def test_release_versions_agree():
    assert 'MM.version = "0.7.1"' in CORE
    assert '## Version: 0.7.1' in TOC
    assert MANIFEST["version"] == "0.7.1"
