from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
DATA = (ROOT / "AddOns/ModuloMarket/TurnInData.lua").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_align():
    assert 'MM.version = "0.10.1"' in CORE
    assert "## Version: 0.10.1" in TOC
    assert 'version = "0.10.1"' in DATA
    assert MANIFEST["version"] == "0.10.1"


def test_turnins_uses_five_columns_and_combined_reward_sort():
    assert '"Favor / Rep"' in UI
    assert '"name", "completion", "price", "reward", "net"' in UI
    assert 'elseif key == "reward" then' in UI
    assert 'button.total:SetText("")' in UI
    assert "local xReward =" in UI
    assert "local xRep =" not in UI


def test_reward_display_preserves_known_zero_and_unknown():
    assert '" F · " .. (item.reputation ~= nil and tostring(item.reputation) or "?") .. " Rep"' in UI
    assert '" Favor · " .. (item.reputation ~= nil and tostring(item.reputation) or "?") .. " Rep"' in UI


def test_best_material_option_is_identified_and_itemized():
    assert "BEST VALUE · OPTION %d · MATERIALS %s" in UI
    assert "item.bestBundle.lines" in UI
    assert "OTHER MATERIAL OPTIONS" in UI


def test_completion_cost_hover_explains_full_cost_and_unknowns():
    assert 'row.completionHit:SetScript("OnEnter"' in UI
    assert "selected.bestBundle.lines" in UI
    assert "Total completion: " in UI
    assert "crate price unavailable" in UI


def test_selected_turnin_notes_show_known_outcome():
    assert 'outcome = "Hand in for "' in UI
    assert 'outcome = "Hand-in cash and Favor rewards are UNKNOWN."' in UI
    assert "No repeatable reputation." in UI


def test_turnin_economics_font_is_normal_and_other_tabs_restore_original():
    assert "UI.detailPrice:SetFontObject(GameFontHighlight)" in UI
    assert "UI.detailProfit:SetFontObject(GameFontHighlight)" in UI
    assert "UI.detailPrice:SetFontObject(GameFontHighlightLarge); IncreaseFontSize(UI.detailPrice, 1)" in UI
    assert 'local economicsFont = tab == "turnins" and GameFontHighlight or GameFontHighlightLarge' in UI
