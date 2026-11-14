from pathlib import Path
import json
import shutil
import subprocess
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns/ModuloMarket"
CORE = (ADDON / "Core.lua").read_text(encoding="utf-8")
TOC = (ADDON / "ModuloMarket.toc").read_text(encoding="utf-8")
MARKET = (ADDON / "MarketUI.lua").read_text(encoding="utf-8")
MODERN = (ADDON / "ModernUI.lua").read_text(encoding="utf-8")
THEME = (ADDON / "Theme.lua").read_text(encoding="utf-8")
TURNINS = (ADDON / "TurnInEngine.lua").read_text(encoding="utf-8")
WRITS = (ADDON / "WritData.lua").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_and_writ_data_are_in_manifest():
    assert 'MM.version = "0.11.4"' in CORE
    assert "## Version: 0.11.4" in TOC
    assert 'version = "0.11.4"' in WRITS
    assert MANIFEST["version"] == "0.11.4"
    assert "WritData.lua" in TOC
    assert "AddOns/ModuloMarket/WritData.lua" in MANIFEST["files"]


def test_both_market_windows_can_be_dragged_beyond_client_edges_and_reset():
    assert MARKET.count("SetClampedToScreen(false)") >= 1
    assert "windowPositions.blizzlike" in MARKET
    assert "function UI.ResetWindowPosition()" in MARKET
    assert "SetClampedToScreen(false)" in MODERN
    assert "windowPositions.modern" in MODERN
    assert "function Modern.ResetWindowPosition()" in MODERN
    assert "Reset Modulo Market window position" in THEME


def test_settings_page_uses_contained_scroll_frame():
    assert 'CreateFrame("ScrollFrame", "ModuloMarketSettingsScrollFrame"' in THEME
    assert "settingsScroll:SetScrollChild(settingsContent)" in THEME
    assert "settingsContent:GetHeight() - self:GetHeight()" in THEME
    assert "Open Browse Scan / Snapshot Debug" in THEME


def test_inspector_values_use_turnin_body_font_size_across_tabs():
    import re
    code = re.sub(r"--[^\n]*", "", MARKET)
    assert "SetFontObject(GameFontHighlight)" in code
    assert "SetFontFromTemplate(value, GameFontHighlight, 1)" in code
    assert "SetFontObject(GameFontHighlightLarge)" not in code
    assert "SetFontFromTemplate(value, GameFontHighlightLarge, 1)" not in code


def test_modern_checkbox_updates_state_before_refreshing_mark():
    click = MODERN.split('check:SetScript("OnClick"', 1)[1].split('end)', 1)[0]
    assert click.index("self.setter(self.key, nextValue)") < click.index("self:Refresh()")
    assert 'Textures\\\\check.tga' in MODERN
    assert 'Textures\\\\check.tga' in MARKET


def test_turnin_filter_supports_crates_and_writs_in_both_windows():
    assert 'value="crate"' in MARKET and 'value="writ"' in MARKET
    assert 'value="crate"' in MODERN and 'value="writ"' in MODERN
    assert "turnInTypeFilter" in MARKET and "turnInTypeFilter" in MODERN
    assert '"Craftsman\'s Writ"' in MARKET


def test_150_writs_are_catalogued_with_tier_reward_and_faction_sources():
    assert WRITS.count("{ outputName =") == 150
    assert 'Journeyman = 75' in WRITS
    assert 'Expert = 125' in WRITS
    assert 'Artisan = 200' in WRITS
    assert 'Azeroth Commerce Authority' in WRITS
    assert 'Durotar Supply & Logistics' in WRITS
    assert 'Variable Coin Pouch' in WRITS


def test_writ_economics_include_writ_and_one_buy_or_craft_route_without_guessing_coin_pouch():
    assert "BuildWritRows(catalog, catalogByID, byName)" in TURNINS
    assert "writPriceCopper" in TURNINS
    assert "netCostPerReputationCopper" in TURNINS
    assert 'cashReturnCopper = nil, cashReturnText = "Variable pouch"' in TURNINS
    assert 'item.turnInType == "writ" and text ~= "?" then return text .. "*"' in MARKET
    assert "PriceFor(marketItem, quantity)" in TURNINS
    assert "Variable reagent quantity is not estimated" in TURNINS


def test_all_modern_utility_textures_are_valid_rgba_tga():
    for name in ("cancel", "check", "chevron-down", "close", "refresh", "search"):
        with Image.open(ADDON / f"Textures/{name}.tga") as im:
            assert im.format == "TGA" and im.mode == "RGBA" and im.size == (64, 64)


def test_writ_turnin_lua_harness():
    lua = shutil.which("texlua") or shutil.which("lua")
    assert lua, "texlua/lua is required for Writ economics harness"
    result = subprocess.run(
        [lua, str(ROOT / "tests/turnin_writs_0_11_4_harness.lua"), str(ADDON)],
        check=True, capture_output=True, text=True,
    )
    assert "11 writ turn-in checks passed" in result.stdout


def test_writ_recipe_names_resolve_against_the_bundled_foreverdb_baseline():
    lua = shutil.which("texlua") or shutil.which("lua")
    assert lua
    result = subprocess.run(
        [lua, str(ROOT / "tests/turnin_writs_0_11_4_harness.lua"), str(ADDON)],
        check=True, capture_output=True, text=True,
    )
    assert "145/150 exact recipe coverage verified against embedded ForeverDBData.lua" in result.stdout


def test_only_artisan_crate_reputation_is_unknown_not_false_zero():
    data = (ADDON / "TurnInData.lua").read_text(encoding="utf-8")
    artisan = [line for line in data.splitlines() if 'tier="Artisan"' in line]
    non_artisan = [line for line in data.splitlines() if 'tier="Apprentice"' in line or 'tier="Journeyman"' in line or 'tier="Expert"' in line]
    assert len(artisan) == 8 and all("reputation=nil" in line for line in artisan)
    assert len(non_artisan) == 22 and all("reputation=0" in line for line in non_artisan)
