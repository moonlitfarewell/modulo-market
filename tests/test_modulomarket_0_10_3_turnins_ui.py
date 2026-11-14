from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
DATA = (ROOT / "AddOns/ModuloMarket/TurnInData.lua").read_text(encoding="utf-8")
ENGINE = (ROOT / "AddOns/ModuloMarket/TurnInEngine.lua").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_align():
    assert 'MM.version = "0.11.0"' in CORE
    assert "## Version: 0.11.0" in TOC
    assert 'version = "0.11.0"' in DATA
    assert MANIFEST["version"] == "0.11.0"


def test_turnins_uses_five_columns_and_combined_reward_sort():
    assert '"Favor / Rep"' in UI
    assert '"name", "completion", "price", "reward", "net"' in UI
    assert 'elseif key == "reward" then' in UI
    assert 'button.total:SetText("")' in UI
    assert "local xReward =" in UI
    assert "local xRep =" not in UI


def test_reward_display_is_mutually_exclusive_and_preserves_zero_unknown():
    assert 'function Engine.FormatReward(item, compact)' in ENGINE
    assert 'return tostring(item.rewardFavor) .. (compact and " F" or " Favor")' in ENGINE
    assert 'return tostring(item.reputation) .. (compact and " Rep" or " Reputation")' in ENGINE
    assert 'return "?"' in ENGINE
    assert 'button.atPrice:SetText(FormatTurnInReward(item, true))' in UI
    assert 'UI.detailAtPrice:SetText(FormatTurnInReward(item, false))' in UI
    assert ' F · ' not in UI and ' Favor · ' not in UI


def test_every_material_option_is_rendered_as_a_separate_breakdown():
    assert 'local function RenderTurnInBundleBreakdown(item)' in UI
    assert 'for index, alternative in ipairs(item.bundleAlternatives or {}) do' in UI
    assert 'OPTION %d%s' in UI
    assert 'alternative.index == item.bestBundle.index' in UI
    assert 'Material subtotal' in UI
    assert 'Line: ' in UI
    assert 'Unit: unknown' in UI


def test_completion_cost_hover_explains_full_cost_and_unknowns():
    assert 'row.completionHit:SetScript("OnEnter"' in UI
    assert "selected.bestBundle.lines" in UI
    assert "Total completion: " in UI
    assert "crate price unavailable" in UI


def test_selected_turnin_notes_show_known_outcome():
    assert 'outcome = "Hand in for "' in UI
    assert 'outcome = "Hand-in cash and Favor rewards are UNKNOWN."' in UI
    assert "No repeatable reputation." in UI


def test_turnin_inspector_uses_compact_labels_and_wider_body_sized_values():
    assert 'AddLabel(frame, text, x, y, width, 18, "GameFontNormalSmall")' in UI
    assert 'AddLabel(frame, text, x, y, width, 18, "GameFontHighlight")' in UI
    assert 'UI.detailPrice = AddDetailRowValue("—", 1248, -304, 160)' in UI
    assert 'UI.detailAtPrice = AddDetailRowValue("—", 1248, -352, 160)' in UI
    assert 'local economicsFont = tab == "turnins" and GameFontHighlight or GameFontHighlightLarge' in UI
    assert 'SetFontFromTemplate(value, GameFontHighlight, 1)' in UI
    assert 'SetFontFromTemplate(value, GameFontHighlightLarge, 1)' in UI
    assert 'IncreaseFontSize(UI.detailPrice' not in UI
    assert 'IncreaseFontSize(UI.detailSupply' not in UI
    assert 'IncreaseFontSize(UI.detailAtPrice' not in UI
    assert 'IncreaseFontSize(UI.detailProfit' not in UI


def test_font_size_is_deterministic_across_tab_changes_and_selection():
    helper = UI.split('local function SetFontFromTemplate', 1)[1].split('\nend', 1)[0]
    assert 'template.GetFont' in helper
    assert 'fontString.SetFont' in helper
    assert 'tonumber(fontSize) + (tonumber(delta) or 0)' in helper
    assert 'IncreaseFontSize(value, 1)' not in UI


def test_turnin_selection_renders_rows_before_early_return_for_immediate_highlight():
    turnin_branch = UI.split('if item.turnIn then', 1)[1].split('    end\n    for _, value', 1)[0]
    assert 'UI.RenderRows()' in turnin_branch
    assert 'UI.RenderRows()\n        return\n' in turnin_branch
