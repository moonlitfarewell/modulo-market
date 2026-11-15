from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns/ModuloMarket"
CORE = (ADDON / "Core.lua").read_text(encoding="utf-8")
TOC = (ADDON / "ModuloMarket.toc").read_text(encoding="utf-8")
MARKET = (ADDON / "MarketUI.lua").read_text(encoding="utf-8")
MODERN = (ADDON / "ModernUI.lua").read_text(encoding="utf-8")
TURNINS = (ADDON / "TurnInEngine.lua").read_text(encoding="utf-8")
ENGINE = (ADDON / "TurnInEngine.lua").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_are_0_11_7():
    assert 'MM.version = "0.12.8"' in CORE
    assert "## Version: 0.12.8" in TOC
    assert MANIFEST["version"] == "0.12.8"


def test_history_uses_exactly_the_latest_three_snapshots():
    assert "local firstSnapshot = math.max(1, #history - 2)" in MARKET
    assert "for i = firstSnapshot, #history do" in MARKET
    assert "while #history > 3 do table.remove(history, 1) end" in (ADDON / "Replicate.lua").read_text(encoding="utf-8")
    assert "for i = 1, 3 do" in MARKET
    assert "for i = 1, 3 do" in MODERN
    assert "3 * 86400" not in MARKET


def test_turnin_crates_are_explicitly_typed_and_writs_keep_their_type():
    assert 'turnIn = true, turnInType = "crate"' in ENGINE
    assert 'turnIn = true, turnInType = "writ"' in ENGINE
    assert 'item.turnInType ~= build.turnInTypeFilter' in MARKET


def test_category_filter_options_follow_turnin_type_and_reset_invalid_selection():
    assert "GetTurnInCategoryOptions(UI.turnInTypeFilter)" in MARKET
    assert "function UI.GetTurnInCategoryOptions()" in MARKET
    assert "TURNIN_CRATE_CATEGORIES" in MARKET and "TURNIN_WRIT_PROFESSIONS" in MARKET
    assert "validCategory and nextCategory or \"all\"" in MARKET
    assert "UI.GetTurnInCategoryOptions()" in MODERN


def test_turnin_column_names_and_reward_abbreviations_are_consistent():
    expected = ["Turn-In Item", "Cost", "Gross", "REP / FAV", "Net / Reward"]
    for label in expected:
        assert label in MARKET
    for label in ["TURN-IN ITEM", "COST", "GROSS", "REP / FAV", "NET / REWARD"]:
        assert label in MODERN
    assert 'compact and " Fav" or " Favor"' in ENGINE
    assert 'compact and " Rep" or " Reputation"' in ENGINE
    assert "REPORTED REP*" not in MARKET + MODERN
    assert "Rep*" not in MARKET + MODERN


def test_writ_inspector_uses_reputation_without_reported_prefix_or_asterisk():
    assert '"REPUTATION"' in MARKET
    assert '"Daily Writ · " .. tostring(item.reputation or "?")' in MARKET
    assert '" Reputation. Variable Coin Pouch' in MARKET
    assert "reported Rep*" not in MARKET


def test_modern_title_is_centered_without_logo_and_redundant_toolbar_close():
    assert 'Label(frame, "MODULO MARKET", 0, -10, 1536, 30' in MODERN
    assert "title:SetJustifyH(\"CENTER\")" in MODERN
    assert 'Label(frame, "M"' not in MODERN
    assert 'FlatButton(frame, "Close"' not in MODERN
    assert "Modern.closeAction" not in MODERN
    # The top-right X remains as the normal window chrome; Escape and /mm remain available.
    assert "Modern.Hide()" in MODERN


def test_tab_geometry_is_fixed_and_compact():
    assert "local tabX = 18 + math.floor((1424 - (#tabSpecs * 178)) / 2)" in MARKET
    assert 'button:SetSize(width, 28)' in MARKET
    assert "Modern.nav:SetSize(1472, 40)" in MODERN
    assert "button:SetSize(tabWidth, 38)" in MODERN


def test_shift_click_uses_native_chat_link_or_auction_browse_fallback():
    assert "function UI.HandleShiftClick(item)" in MARKET
    assert "_G.ChatFrameUtil" in MARKET
    assert "chatUtil.InsertLink" in MARKET
    assert "_G.ChatEdit_InsertLink" in MARKET
    assert "_G.AuctionFrame" in MARKET and "_G.BrowseName" in MARKET
    assert "browseName:SetText(plainName)" in MARKET
    assert "browseName:SetFocus()" in MARKET
    assert "UI.HandleShiftClick(selected)" in MARKET
    assert "UI.HandleShiftClick(self.item)" in MODERN
    assert 'return "|c" .. GetItemQualityHex(itemID) .. GetItemName(item) .. "|r"' in MARKET


def test_refresh_icon_is_an_authored_rgba_tga():
    with Image.open(ADDON / "Textures/refresh.tga") as im:
        assert im.format == "TGA" and im.mode == "RGBA" and im.size == (64, 64)
        alpha = im.getchannel("A")
        assert alpha.getbbox() is not None
        colors = im.getcolors(64 * 64)
        opaque = [color for _, color in (colors or []) if color[3] > 200]
        assert sum(count for count, color in (colors or []) if color[3] > 200) > 250
        assert opaque and all(min(color[:3]) >= 200 for color in opaque)


def test_item_tooltips_are_native_and_have_no_shift_click_instruction():
    assert "UI.ShowMarketItemTooltip = ShowMarketItemTooltip" in MARKET
    assert "GameTooltip.SetItemByID" in MARKET
    assert "Shift-click to fill the Auction House search field" not in MARKET + MODERN
    assert "UI.ShowMarketItemTooltip(self, self.item" in MODERN


def test_all_tabs_keep_learning_marker_and_item_rarity_name_colour():
    assert "button.statusMarker:SetColorTexture(GetRowCraftMarker(item))" in MARKET
    assert "button.statusMarker:Show()" in MARKET
    assert "button.name:SetText(GetItemDisplayName(item))" in MARKET
    assert "row.statusMarker and UI.GetRowCraftMarker" in MODERN
    assert "UI.GetItemDisplayName(item)" in MODERN
    assert "GetItemQualityHex" in MARKET


def test_inspector_is_named_inspected_item_in_both_presentations():
    assert 'AddInspectorCard(1136, -158, 280, 110)' in MARKET
    assert 'AddLabel(frame, "Inspected Item"' in MARKET
    assert 'Panel(frame, "INSPECTED ITEM"' in MODERN
    assert 'Panel(right, "SELECTED ITEM"' in MODERN


def test_artisan_crate_rewards_follow_user_supplied_favor_and_cash_schedule():
    data = (ADDON / "TurnInData.lua").read_text(encoding="utf-8")
    artisan = data[data.index('id=248695'):data.index('    },\n    -- One-time Shipping Label')]
    assert artisan.count("rewardFavor=20, rewardCashCopper=1000") == 5
    assert artisan.count("rewardFavor=40, rewardCashCopper=2000") == 3
    assert "50 copper per Favor" in data


def test_snapshot_search_uses_cached_client_name_when_snapshot_name_is_missing():
    assert "GetItemName = function(item)" in MARKET
    assert "pcall(GetItemInfoCompat, itemID)" in MARKET
    assert "GetItemName(item)," in MARKET
    assert "GetTooltipSearchText(item.itemID)" in MARKET
