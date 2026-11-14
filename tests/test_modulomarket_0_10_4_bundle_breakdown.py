from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
DATA = (ROOT / "AddOns/ModuloMarket/TurnInData.lua").read_text(encoding="utf-8")
ENGINE = (ROOT / "AddOns/ModuloMarket/TurnInEngine.lua").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_and_load_order_align():
    assert 'MM.version = "0.10.4"' in CORE
    assert "## Version: 0.10.4" in TOC
    assert 'version = "0.10.4"' in DATA
    assert MANIFEST["version"] == "0.10.4"
    assert TOC.index("TurnInData.lua") < TOC.index("TurnInEngine.lua") < TOC.index("MarketUI.lua")


def test_crate_purchase_is_separate_from_each_material_option():
    renderer = UI.split("local function RenderTurnInBundleBreakdown", 1)[1].split("\nend", 1)[0]
    assert 'AddRow("CRATE PURCHASE · 1 × CRATE"' in renderer
    assert 'AddRow("MATERIAL OPTIONS · CHOOSE ONE"' in renderer
    assert "Material subtotal" in renderer
    assert "cratePriceCopper" in renderer


def test_all_alternatives_are_rendered_independently_in_source_order():
    renderer = UI.split("local function RenderTurnInBundleBreakdown", 1)[1].split("\nend", 1)[0]
    assert "for index, alternative in ipairs(item.bundleAlternatives or {}) do" in renderer
    assert 'string.format("OPTION %d%s", index' in renderer
    assert "alternative.index == item.bestBundle.index" in renderer
    assert "BEST VALUE" in renderer


def test_each_material_shows_quantity_unit_price_and_line_cost():
    renderer = UI.split("local function RenderTurnInBundleBreakdown", 1)[1].split("\nend", 1)[0]
    assert 'string.format("%d × %s"' in renderer
    assert "reagent.unitPriceCopper" in renderer
    assert '" / ea"' in renderer
    assert 'Unit: ' in renderer
    assert 'Line: ' in renderer
    assert "reagent.lineCostCopper" in renderer


def test_unknown_price_reason_is_explicit_and_option_is_incomplete():
    renderer = UI.split("local function RenderTurnInBundleBreakdown", 1)[1].split("\nend", 1)[0]
    assert 'or "INCOMPLETE"' in renderer
    assert '"Price status: " .. tostring(reagent.reason)' in renderer
    assert 'or "Unit: unknown"' in renderer
    assert "alternative.complete and FormatMoney(alternative.costCopper)" in renderer
    assert "depth < quantity" in ENGINE


def test_turnin_uses_structured_breakdown_and_other_tabs_restore_text():
    turnin_branch = UI.split("if item.turnIn then", 1)[1].split("    end\n    for _, value", 1)[0]
    assert "RenderTurnInBundleBreakdown(item)" in turnin_branch
    assert "SetDetailEconomics(table.concat(lines" not in turnin_branch
    assert "local function SetDetailEconomics(text)" in UI
    assert "HideTurnInBreakdown()" in UI
    assert "UI.detailEconomics:Show()" in UI


def test_breakdown_rows_are_reused_and_scroll_child_tracks_content_height():
    renderer = UI.split("local function RenderTurnInBundleBreakdown", 1)[1].split("\nend", 1)[0]
    assert "UI.turnInBreakdownRows" in renderer
    assert "CreateFontString" in renderer
    assert "row.left:Hide()" in renderer
    assert "UI.detailScrollChild:SetHeight(math.max(UI.detailScroll:GetHeight(), cursorY + 4))" in renderer
    assert "UI.detailScroll:SetVerticalScroll(0)" in renderer


def test_prior_font_and_immediate_highlight_fix_remain():
    assert 'local economicsFont = tab == "turnins" and GameFontHighlight or GameFontHighlightLarge' in UI
    turnin_branch = UI.split("if item.turnIn then", 1)[1].split("    end\n    for _, value", 1)[0]
    assert "UI.RenderRows()" in turnin_branch
    assert "UI.RenderRows()\n        return" in turnin_branch


def test_manifest_inventory_is_exact():
    actual = sorted(str(p.relative_to(ROOT)).replace("\\", "/") for p in ROOT.rglob("*") if p.is_file() and ".git" not in p.parts and "__pycache__" not in p.parts and p.suffix != ".pyc" and ".pytest_cache" not in p.parts)
    assert MANIFEST["files"] == actual
    assert MANIFEST["file_count"] == len(actual)
