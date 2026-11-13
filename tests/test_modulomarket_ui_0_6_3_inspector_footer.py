from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns" / "ModuloMarket" / "MarketUI.lua").read_text()
CORE = (ROOT / "AddOns" / "ModuloMarket" / "Core.lua").read_text()
TOC = (ROOT / "AddOns" / "ModuloMarket" / "ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())

def test_release_versions_agree():
    assert f'MM.version = "{MANIFEST["version"]}"' in CORE
    assert f'## Version: {MANIFEST["version"]}' in TOC
    assert MANIFEST["version"] == CORE.split('MM.version = "', 1)[1].split('"', 1)[0]

def test_profit_and_history_footer_is_a_child_container_inside_inspector():
    body = UI.split('UI.detailFooter = CreateFrame("Frame", nil, frame)', 1)[1].split('for i = 1, 4 do', 1)[0]
    assert 'UI.detailFooter:SetPoint("TOPLEFT", frame, "TOPLEFT", 1136, -584)' in body
    assert 'UI.detailFooter:SetSize(280, 224)' in body
    assert 'UI.historyHeading = AddLabel(frame, "Market History"' in UI
    assert 'AddLabel(UI.detailFooter, "", 6, -32, 268, 58' in body

def test_history_graph_baseline_is_bottom_anchored_and_bars_grow_upward():
    body = UI.split('UI.historyGraph = CreateFrame("Frame", nil, UI.detailFooter)', 1)[1].split('for i = 1, 4 do', 1)[0]
    assert 'UI.historyGraph:SetPoint("TOPLEFT", UI.detailFooter, "TOPLEFT", 6, -96)' in body
    assert 'UI.historyGraph:SetSize(236, 126)' in body
    render = UI.split('function UI.RenderHistory()', 1)[1].split('SelectItem = function(item)', 1)[0]
    assert 'bar:SetPoint("BOTTOMLEFT", UI.historyGraph, "BOTTOMLEFT"' in render
    assert 'bar:SetSize(38, height)' in render
