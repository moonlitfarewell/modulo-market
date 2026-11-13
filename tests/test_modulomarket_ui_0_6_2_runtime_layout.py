from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns" / "ModuloMarket" / "MarketUI.lua").read_text()
CORE = (ROOT / "AddOns" / "ModuloMarket" / "Core.lua").read_text()
TOC = (ROOT / "AddOns" / "ModuloMarket" / "ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_release_versions_agree():
    assert 'MM.version = "0.9.6"' in CORE
    assert '## Version: 0.9.6' in TOC
    assert MANIFEST["version"] == "0.9.6"


def test_render_rows_returns_before_early_item_data_callback_can_dereference_empty_pool():
    body = UI.split("function UI.RenderRows()", 1)[1].split("function UI.RenderHistory()", 1)[0]
    guard = 'if type(UI.rows) ~= "table" or not UI.rows[1] or not UI.scrollChild then return end'
    assert guard in body
    assert body.index(guard) < body.index("button:ClearAllPoints()")
    assert "if button then" in body
    assert "math.min(UI.visibleCount or rowPoolCount, rowPoolCount)" in body


def test_async_item_data_callback_remains_safe_before_row_pool_creation():
    handler = UI.split('vendorInfoEvents:SetScript("OnEvent"', 1)[1].split("end)", 1)[0]
    assert "UI.RenderRows()" in handler
    body = UI.split("function UI.RenderRows()", 1)[1].split("function UI.RenderHistory()", 1)[0]
    assert "not UI.rows[1]" in body and "not UI.scrollChild" in body


def test_centre_panel_reclaims_space_from_inspector_and_expands_scroll_rows():
    assert "centerPanel:SetSize(834, 650)" in UI
    assert 'rightPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 1126, -158)' in UI
    assert "rightPanel:SetSize(300, 650)" in UI
    assert "UI.scroll:SetSize(812, 555)" in UI
    assert "row:SetSize(796, UI.rowHeight)" in UI


def test_craft_material_cost_column_is_wider_and_reagent_tooltip_is_preserved():
    assert '{ x = 510, w = 166, justify = "LEFT" }' in UI
    assert 'row.depth:SetPoint("LEFT", row, "LEFT", 212, 0); row.depth:SetWidth(160)' in UI
    assert 'row.materialHit:SetSize(170, UI.rowHeight)' in UI
    assert 'GameTooltip:AddLine("Total material cost: "' in UI


def test_panel_titles_and_result_count_live_in_their_header_strips():
    assert 'UI.filterHeading = AddLabel(frame, "Filters — All Items", 30, -166' in UI
    assert 'UI.centerHeading = AddLabel(frame, "All Items", 302, -166' in UI
    assert 'UI.detailHeading = AddLabel(frame, "Selected item", 1142, -166, 268' in UI
    assert 'UI.resultCount = AddLabel(frame, "", 990, -166' in UI
    assert "UI.centerHeading:SetText" in UI


def test_inspector_text_is_constrained_to_narrower_panel():
    assert 'UI.detailScroll:SetSize(270, 124)' in UI
    assert 'UI.detailEconomics:SetWidth(244)' in UI
    assert 'UI.detailEconomics:SetWordWrap(true)' in UI
    assert 'UI.detailVariants:SetWordWrap(true)' in UI
    assert 'UI.detailName:SetWordWrap(true)' in UI


def test_skill_up_thresholds_are_shown_with_forever_and_classic_evidence_separated():
    assert "AppendSkillThresholdLines(lines, future.skillThresholds)" in UI
    assert 'evidence == "FOREVER_CLIENT"' in UI
    assert 'thresholds.orange_classic' in UI
    assert 'borrowed; not Forever-confirmed' in UI
    assert 'item.skillThresholds = sourceItem.skillThresholds' in UI


def test_market_and_materials_rows_align_with_expanded_headers():
    assert 'row.depth:SetPoint("LEFT", row, "LEFT", 322, 0); row.depth:SetWidth(150)' in UI
    assert 'row.atPrice:SetPoint("LEFT", row, "LEFT", 478, 0); row.atPrice:SetWidth(72)' in UI
    assert 'row.total:SetPoint("LEFT", row, "LEFT", 554, 0); row.total:SetWidth(72)' in UI
