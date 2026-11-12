from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns" / "ModuloMarket" / "MarketUI.lua").read_text()
CORE = (ROOT / "AddOns" / "ModuloMarket" / "Core.lua").read_text()
TOC = (ROOT / "AddOns" / "ModuloMarket" / "ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_release_versions_agree():
    assert 'MM.version = "0.6.3"' in CORE
    assert '## Version: 0.6.3' in TOC
    assert MANIFEST["version"] == "0.6.3"


def test_each_craft_tab_remembers_selection_and_defaults_to_first_result():
    assert "selectedByTab = {}" in UI
    assert "UI.selectedByTab[UI.activeTab]" in UI
    assert "if not chosen then chosen = UI.viewRows[1] end" in UI
    assert "if chosen and SelectItem then SelectItem(chosen)" in UI
    assert "local wanted = UI.selectedByTab[UI.activeTab]" in UI


def test_craft_filters_have_explicit_evidence_aware_semantics():
    assert '"craftableOnly", "Craftable only"' in UI
    assert '"profitableOnly", "Profitable only"' in UI
    assert '"reviewOnly", "Review items only"' in UI
    assert '"hideLowProfit", "Hide non-profitable"' in UI
    assert 'status == "known" and hasOutput and completeCost' in UI
    assert 'profit ~= nil and profit > 0' in UI
    assert 'freshness == "review"' in UI
    assert 'profit == nil or profit > 0' in UI


def test_all_crafts_material_column_shows_real_reagents_and_cost_tooltip():
    assert 'labels = { "Recipe", "Materials (cost)", "Sale / Unit"' in UI
    assert 'tostring(reagent.quantity or "?") .. "x |T"' in UI
    assert 'row.materialHit:SetScript("OnEnter"' in UI
    assert 'GameTooltip:AddLine("Total material cost: "' in UI


def test_selected_recipe_inspector_contains_full_market_and_acquisition_context():
    assert '"At price: "' in UI
    assert '"Total listed: "' in UI
    assert '"Total material cost / craft: "' in UI
    assert '"Acquisition: "' in UI
    assert 'string.format(" (%.1f%%)", margin)' in UI


def test_switching_from_craft_to_noncraft_restores_market_column_positions():
    assert 'row.price:SetPoint("LEFT", row, "LEFT", 212, 0)' in UI
    assert 'row.depth:SetPoint("LEFT", row, "LEFT", 322, 0)' in UI
    assert 'row.atPrice:SetPoint("LEFT", row, "LEFT", 478, 0)' in UI
    assert 'row.total:SetPoint("LEFT", row, "LEFT", 554, 0)' in UI


def test_all_tab_switches_restore_their_own_column_geometry():
    assert 'local craftColumns = {' in UI
    assert 'local materialColumns = {' in UI
    assert 'local marketColumns = {' in UI
    assert 'row.depth:SetPoint("LEFT", row, "LEFT", 322, 0)' in UI
    assert 'row.profit:SetPoint("RIGHT", row, "RIGHT", -4, 0)' in UI
