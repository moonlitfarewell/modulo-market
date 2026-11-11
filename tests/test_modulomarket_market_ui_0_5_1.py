from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
DATA = (ROOT / "AddOns/ModuloMarket/ProfessionData.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()


def test_known_recipe_identity_suppresses_duplicate_future_candidate():
    assert "local function IsAlreadyKnown" in DATA
    assert "NormalizeRecipeName(known.recipeName) == normalizedName" in DATA
    assert "if outputID and not isKnown then" in DATA
    assert "if not entry or #entry.knownCrafts > 0 then return false end" in DATA


def test_item_role_tags_prioritize_known_outputs():
    assert "local hasKnownCraft = #entry.knownCrafts > 0" in DATA
    assert "if hasKnownCraft then" in DATA
    assert 'tags[#tags + 1] = "known"' in DATA
    assert 'tags[#tags + 1] = "futureBorrowed"' in DATA


def test_vendor_price_loading_supports_both_client_item_events():
    assert "local function ReadVendorInfo(itemID)" in UI
    assert 'vendorInfoEvents:RegisterEvent("GET_ITEM_INFO_RECEIVED")' in UI
    assert '"ITEM_DATA_LOAD_RESULT"' in UI
    assert "UI.vendorPriceFailed[itemID]" in UI
    assert "Loading item data…" in UI
    assert "Unavailable from client data" in UI
    assert "Item value not cached" not in UI


def test_item_role_dropdown_explains_exclusive_categories():
    assert '{ text = "All item types", value = "all"' in UI
    assert '{ text = "Known craft outputs", value = "known"' in UI
    assert 'text = "Unlearned: borrowed"' in UI
    assert 'tooltipText = "Items mapped to Mining, Herbalism or Fishing.' in UI
    assert 'text = "Crafting reagents"' in UI


def test_patch_version_is_consistent():
    assert 'MM.version = "0.5.7"' in CORE
    assert "## Version: 0.5.7" in TOC
