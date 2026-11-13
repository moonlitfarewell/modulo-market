from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_align():
    assert 'MM.version = "0.9.0"' in CORE
    assert "## Version: 0.9.0" in TOC
    assert MANIFEST["version"] == "0.9.0"


def test_foreverdb_status_is_compact_but_full_tooltip_is_retained():
    assert '"ForeverDB %s · %d observed · %d Classic-borrowed · %d unverified · %d speculative + %d non-item outputs excluded%s"' in UI
    assert 'GameTooltip:AddLine(UI.statusMessage or "", 0.9, 0.9, 0.9, true)' in UI
    assert 'if #displayText > 210 then displayText = displayText:sub(1, 207) .. "..." end' in UI


def test_dropdown_menu_hides_stale_control_tooltip():
    assert 'local function closeMenu()\n        popup:Hide()\n        if _G.GameTooltip then GameTooltip:Hide() end\n    end' in UI
    assert 'local function openMenu()\n        -- The dropdown\'s own help tooltip must not remain floating over its' in UI
    assert 'if _G.GameTooltip then GameTooltip:Hide() end\n        local options = getOptions() or {}' in UI


def test_dropdown_popup_rows_are_more_compact():
    assert 'local rowHeight = 21' in UI
    assert 'optionButton:SetSize(width - 8, 19)' in UI


def test_relationship_inspector_gets_more_viewport():
    assert 'AddInspectorCard(1136, -422, 280, 170)' in UI
    assert 'UI.detailScroll:SetSize(270, 124)' in UI
    assert 'UI.detailScrollChild:SetSize(250, 124)' in UI
    assert 'UI.detailEconomics:SetHeight(124)' in UI


def test_market_history_graph_is_compacted_without_removing_history():
    assert 'AddInspectorCard(1136, -602, 280, 206)' in UI
    assert 'UI.detailFooter:SetPoint("TOPLEFT", frame, "TOPLEFT", 1136, -602)' in UI
    assert 'UI.historyGraph:SetSize(236, 104)' in UI
    assert 'UI.historyText = AddLabel(UI.detailFooter, "", 6, -32, 268, 54' in UI
    assert 'for i = 1, 4 do' in UI
