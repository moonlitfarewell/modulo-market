from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns" / "ModuloMarket" / "MarketUI.lua").read_text()
CORE = (ROOT / "AddOns" / "ModuloMarket" / "Core.lua").read_text()
TOC = (ROOT / "AddOns" / "ModuloMarket" / "ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())

def test_release_versions_agree():
    assert 'MM.version = "0.6.5"' in CORE
    assert '## Version: 0.6.5' in TOC
    assert MANIFEST["version"] == "0.6.5"

def test_craft_material_cell_shows_total_only():
    assert 'button.depth:SetText(materialCost)' in UI
    assert 'materialSummary' not in UI

def test_material_hover_retains_icons_and_cost_breakdown():
    body = UI.split('row.materialHit:SetScript("OnEnter"', 1)[1].split('row.materialHit:SetScript("OnLeave"', 1)[0]
    assert 'GetItemIcon(reagent.itemID)' in body
    assert '|T' in body
    assert 'reagent.itemName' in body
    assert 'reagent.quantity' in body
    assert 'reagent.lineCostCopper' in body
    assert 'Total material cost:' in body

def test_inspector_text_wraps():
    assert 'UI.detailName:SetWordWrap(true)' in UI
    assert 'UI.detailVariants:SetWordWrap(true)' in UI
    assert 'UI.detailEconomics:SetWordWrap(true)' in UI
    assert 'UI.detailProfit:SetWordWrap(true)' in UI
    assert 'UI.historyText:SetWordWrap(true)' in UI

def test_scrollbar_is_inside_middle_viewport():
    assert 'CreateFrame("ScrollFrame", "ModuloMarketMainScrollFrame", frame, "UIPanelScrollFrameTemplate")' in UI
    assert 'marketScrollBar:SetPoint("TOPRIGHT", UI.scroll, "TOPRIGHT", -1, -16)' in UI
    assert 'marketScrollBar:SetPoint("BOTTOMRIGHT", UI.scroll, "BOTTOMRIGHT", -1, 16)' in UI
    assert 'UI.scrollChild:SetSize(796, 1)' in UI
    assert 'row:SetSize(796, UI.rowHeight)' in UI

def test_opacity_label_and_value_are_above_slider():
    assert 'UI.opacityLabel = AddLabel(frame, "Window opacity", 860, -43, 170, 18' in UI
    assert 'UI.opacitySlider:SetPoint("TOPLEFT", frame, "TOPLEFT", 860, -66)' in UI
    assert 'UI.opacityValue = AddLabel(frame, "", 1036, -43, 48, 18' in UI
