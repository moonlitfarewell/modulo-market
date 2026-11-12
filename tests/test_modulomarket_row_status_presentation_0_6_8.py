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


def test_filter_categories_map_to_consistent_text_colours():
    block = UI.split("local function GetItemDisplayName(item)", 1)[1].split("local function", 1)[0]
    assert 'if has.known then' in block
    assert 'nameColor = "|cff8ee6a2"' in block
    assert 'elseif has.future or has.futureBorrowed or has.futureUnknown then' in block
    assert 'nameColor = "|cffffd77a"' in block
    assert 'elseif has.gather then' in block
    assert 'nameColor = "|cff82d9ff"' in block
    assert 'elseif has.material then' in block
    assert 'nameColor = "|cffb6e2ff"' in block


def test_unlearned_source_classes_share_one_player_facing_colour():
    block = UI.split("local function GetItemDisplayName(item)", 1)[1].split("local function", 1)[0]
    assert "futureBorrowed" in block and "futureUnknown" in block
    assert "|cffffb36b" not in block
    assert "|cffc4cbd3" not in block


def test_release_versions_agree():
    assert 'MM.version = "0.6.8"' in CORE
    assert '## Version: 0.6.8' in TOC
    assert MANIFEST["version"] == "0.6.8"
