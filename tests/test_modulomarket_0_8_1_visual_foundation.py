from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_all_items_retains_existing_six_tabs_without_my_crafts():
    tab_block = UI.split("local tabSpecs = {", 1)[1].split("local tabX", 1)[0]
    for key in ['"market"', '"economics"', '"crafts"', '"materials"', '"low"', '"history"']:
        assert key in tab_block
    assert "My Crafts" not in tab_block
    assert tab_block.count('{ "') == 6


def test_inspector_uses_three_structured_cards_inside_existing_right_panel():
    assert "AddInspectorCard(1136, -270, 280, 144)" in UI
    assert "AddInspectorCard(1136, -422, 280, 170)" in UI
    assert "AddInspectorCard(1136, -602, 280, 206)" in UI
    assert 'UI.marketInfoHeading = AddLabel(frame, "Market Information"' in UI
    assert 'UI.relationshipHeading = AddLabel(frame, "Relationships"' in UI
    assert 'UI.historyHeading = AddLabel(frame, "Market History"' in UI
    assert "rightPanel:SetSize(300, 650)" in UI


def test_relationship_content_is_scrollable_and_not_truncated_to_fixed_panel_height():
    assert 'CreateFrame("ScrollFrame", "ModuloMarketDetailScrollFrame", frame, "UIPanelScrollFrameTemplate")' in UI
    assert "UI.detailScroll:SetSize(270, 124)" in UI
    assert "UI.detailScroll:SetScrollChild(UI.detailScrollChild)" in UI
    assert "UI.detailEconomics:SetWidth(244)" in UI
    assert "UI.detailEconomics.GetStringHeight" in UI
    assert "UI.detailScrollChild:SetHeight(math.max(UI.detailScroll:GetHeight(), contentHeight))" in UI
    assert "UI.detailScroll:EnableMouseWheel(true)" in UI
    assert "current - (delta * 42)" in UI and "self:SetVerticalScroll" in UI


def test_market_information_rows_reuse_existing_market_and_profit_values():
    assert 'AddDetailRowLabel("SALE PRICE / UNIT", 1142, -304' in UI
    assert 'AddDetailRowLabel("TOTAL LISTED", 1142, -328' in UI
    assert 'AddDetailRowLabel("AT PRICE", 1142, -352' in UI
    assert 'UI.detailProfitLabel = AddDetailRowLabel("BEST CRAFT PROFIT"' in UI
    assert "local best = UI.economicsByItemID and UI.economicsByItemID[itemID]" in UI
    assert 'UI.detailPrice:SetText(item.minPriceCopper' in UI
    assert 'UI.detailSupply:SetText(string.format("%d units"' in UI


def test_history_panel_preserves_real_saved_points_and_bottom_anchored_bars():
    history = UI.split("function UI.RenderHistory()", 1)[1].split("local function SetDetailEconomics", 1)[0]
    assert "MM.db and MM.db.marketHistory" in history
    assert "snapshot.items and snapshot.items[tonumber(item.itemID)]" in history
    assert "Each completed full scan adds a comparison point." in history
    assert 'UI.historyGraph:SetPoint("TOPLEFT", UI.detailFooter, "TOPLEFT", 6, -90)' in UI
    assert 'bar:SetPoint("BOTTOMLEFT", UI.historyGraph, "BOTTOMLEFT"' in history
    assert "bar:SetSize(38, height)" in history


def test_header_data_labels_use_actual_snapshot_and_provider_provenance():
    assert 'UI.auctionDataLabel = AddLabel(frame, "Auction Data: unavailable"' in UI
    assert 'UI.recipeDataLabel = AddLabel(frame, "Recipe Data: unavailable"' in UI
    assert 'local snapshotBuild = tostring(snapshot.clientBuild or "UNKNOWN")' in UI
    assert "provider.datasetBuild" in UI
    assert "provider.dataBuildMatchesClient" in UI
    assert "provider.reviewWatchCount" in UI
    assert 'stateText = match and "|cff55dd77Current|r"' in UI
    assert 'or "|cffaaaaaaUnknown|r"' in UI


def test_scan_indicator_does_not_claim_unavailable_percentage_progress():
    assert 'UI.scanStateLabel = AddLabel(frame, "Scan: Idle"' in UI
    assert 'UI.scanStateLabel:SetText("|cff55dd77Scan: Active|r")' in UI
    assert 'UI.scanStateLabel:SetText("|cffffc04dScan: Confirmation required|r")' in UI
    assert "progressPercent" not in UI
    assert "Scan: 0%" not in UI


def test_existing_opacity_scope_and_whole_window_fade_are_preserved():
    assert "ApplyBackgroundOpacity(frame, value)" in UI
    assert 'CreateDropdown(frame, 220, 36, -752' in UI
    assert 'if frame and type(frame.SetAlpha) == "function" then frame:SetAlpha(alpha) end' in UI


def test_release_versions_and_manifest_inventory_align():
    assert 'MM.version = "0.9.8"' in CORE
    assert '## Version: 0.9.8' in TOC
    assert MANIFEST["version"] == "0.9.8"
    assert "MODULOMARKET-RUNTIME-AUDIT-0.8.3.md" in MANIFEST["files"]
    assert "tests/test_modulomarket_0_8_1_visual_foundation.py" in MANIFEST["files"]
    assert MANIFEST["file_count"] == len(MANIFEST["files"])
