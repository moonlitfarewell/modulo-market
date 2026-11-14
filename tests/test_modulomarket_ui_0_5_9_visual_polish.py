from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / 'AddOns' / 'ModuloMarket' / 'MarketUI.lua').read_text()
CORE = (ROOT / 'AddOns' / 'ModuloMarket' / 'Core.lua').read_text()
TOC = (ROOT / 'AddOns' / 'ModuloMarket' / 'ModuloMarket.toc').read_text()
MANIFEST = json.loads((ROOT / 'MANIFEST.json').read_text())


def test_release_versions_agree():
    assert 'MM.version = "0.6.3"' in CORE
    assert '## Version: 0.6.3' in TOC
    assert MANIFEST['version'] == '0.6.3'


def test_real_client_item_icons_are_resolved_and_cached_only_when_known():
    assert 'local function GetItemIcon(itemID)' in UI
    assert 'api.GetItemIconByID' in UI
    assert 'GetItemInfo, itemID' in UI
    assert 'button.icon:SetTexture(GetItemIcon(item.itemID))' in UI
    assert 'UI.detailIcon:SetTexture(GetItemIcon(item.itemID))' in UI
    assert 'GetItemIcon(reagent.itemID)' in UI


def test_virtualized_rows_have_item_art_and_alternating_surface():
    assert 'row.icon = row:CreateTexture' in UI
    assert 'row.rowShade = row:CreateTexture' in UI
    assert 'SetThemeTexture(button.rowShade, "surfaceRaised", {0.105, 0.086, 0.052, 0.30})' in UI and 'SetThemeTexture(button.rowShade, "surface", {0.018, 0.019, 0.021, 0.26})' in UI
    assert 'button.icon:Hide()' in UI


def test_selected_item_panel_exposes_identity_and_provenance_badges():
    assert 'UI.detailIcon = frame:CreateTexture' in UI
    assert 'UI.detailBadges = AddLabel' in UI
    assert 'freshnessStatus' in UI
    assert 'KNOWN' in UI and 'FUTURE' in UI and 'BORROWED' in UI
    assert 'REVIEW' in UI and 'BASELINE' in UI
    assert 'item.sourceProvider == "ForeverDB.net"' in UI


def test_reagent_lines_use_actual_item_icons():
    assert 'local label = "|T" .. tostring(GetItemIcon(reagent.itemID))' in UI


def test_panel_header_plates_and_full_workspace_are_retained():
    assert 'local function AddPanelHeader' in UI
    assert 'AddPanelHeader(18, -158, 260)' in UI
    assert 'AddPanelHeader(286, -158, 834)' in UI
    assert 'AddPanelHeader(1126, -158, 300)' in UI
    assert 'All Items' in UI and 'Economics' in UI and 'My Crafts' in UI
    assert 'All Crafts' in UI and 'Materials' in UI and 'Low Supply' in UI and 'History' in UI


def test_existing_data_and_market_safety_contracts_remain():
    assert 'frame:SetFrameStrata("DIALOG")' in UI
    assert 'frame:SetAlpha(alpha)' in UI
    assert 'labels = { "Item", "Cheapest", "At Price", "Total Units", "Best Craft Profit" }' in UI
    assert 'UI.headerButtons[6]:Hide()' in UI
    assert 'UI.scrollChild' in UI
    assert 'GetMarketPrice(itemID)' in UI
