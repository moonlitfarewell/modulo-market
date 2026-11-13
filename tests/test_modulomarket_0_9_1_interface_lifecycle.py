from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_align():
    assert 'MM.version = "0.9.8"' in CORE
    assert "## Version: 0.9.8" in TOC
    assert MANIFEST["version"] == "0.9.8"


def test_every_dropdown_registers_a_close_callback():
    assert "UI.dropdowns = UI.dropdowns or {}" in UI
    assert "function UI.CloseDropdownMenus()" in UI
    assert "if dropdown and dropdown.CloseMenu then dropdown:CloseMenu() end" in UI
    assert "dropdown.CloseMenu = closeMenu" in UI
    assert "UI.dropdowns[#UI.dropdowns + 1] = dropdown" in UI


def test_main_window_hide_and_show_clear_independent_popups():
    assert 'frame:SetScript("OnHide", function()\n        UI.CloseDropdownMenus()' in UI
    assert 'frame:SetScript("OnShow", function(self)\n        UI.CloseDropdownMenus()' in UI
    assert 'if _G.GameTooltip then GameTooltip:Hide() end\n    end)' in UI


def test_dropdowns_close_when_their_control_is_hidden_or_tab_changes():
    assert 'dropdown:SetScript("OnHide", closeMenu)' in UI
    assert 'UI.CloseDropdownMenus()\n    UI.activeTab = tab' in UI


def test_table_has_a_clear_header_rail_and_selected_row_accent():
    assert 'tableHeaderBand:SetColorTexture(0.105, 0.078, 0.038, 0.88)' in UI
    assert 'UI.tableColumnGuides' not in UI
    assert 'UI.tableHeaderSurface' not in UI
    assert 'row.selectedWash:SetColorTexture(0.48, 0.32, 0.055, 0.43)' in UI
    assert 'row.selectedAccent:SetWidth(3)' in UI


def test_history_chart_has_baseline_and_uses_available_height():
    assert 'UI.historyBaseline = UI.historyGraph:CreateTexture(nil, "BORDER")' in UI
    assert 'local graphHeight = UI.historyGraph and UI.historyGraph.GetHeight' in UI
    assert 'math.max(24, graphHeight - 42)' in UI
    assert 'math.min(height + 1, graphHeight - 24)' in UI
