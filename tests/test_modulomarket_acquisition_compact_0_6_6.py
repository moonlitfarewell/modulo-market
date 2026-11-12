import json
from pathlib import Path

ROOT = Path(__file__).parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
COMPILER = (ROOT / "tools/foreverdb_importer/market_data_importer.py").read_text()
RUNTIME = (ROOT / "AddOns/ModuloMarket/ForeverDBData.lua").read_text()
PROFESSION = (ROOT / "AddOns/ModuloMarket/ProfessionData.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_compiler_preserves_learning_skill_for_inspector():
    assert '"learnAtSkill": provider_metadata.get("learn_at_skill")' in COMPILER
    assert '"learnAtSkill"' in RUNTIME
    assert "learnAtSkill = tonumber(sourceRecipe.learnAtSkill)" in PROFESSION
    assert "professionSkill = tonumber(sourceRecipe.learnAtSkill)" in PROFESSION


def test_compact_single_source_prefers_forever_then_classic_fallback():
    assert 'local priorities = { "FOREVER_OBSERVED", "CLASSIC_BORROWED", "FOREVER_CLIENT", "UNKNOWN" }' in UI
    assert "local function AppendPrimaryAcquisitionLines" in UI
    assert 'label .. ": " .. tostring(name)' in UI
    assert 'lines[#lines + 1] = "Location: "' in UI
    assert 'lines[#lines + 1] = "Cost: "' in UI
    assert "AppendAcquisitionSourceLines" not in UI
    assert "FOREVER OBSERVED" not in UI
    assert "CLASSIC BORROWED — UNCONFIRMED" not in UI


def test_inspector_is_concise_and_recipe_tooltip_has_no_numeric_recipe_id():
    detail = UI.split("local function RenderCraftDetail(item)", 1)[1].split("local function RenderMarketRecipeContext", 1)[0]
    assert '"Recipe: "' in detail
    assert '"Output: "' in detail
    assert 'professionSkill and (" · Skill "' not in detail
    assert '"|cffffd100ACQUISITION|r"' in detail
    assert '"At price: "' not in detail
    assert '"Total listed: "' not in detail
    assert '"Recipe ID: "' not in UI
    assert '"%s · Skill %s · Recipe #%s"' not in UI
    assert '"%s · Skill %s"' in UI
    assert 'UI.detailRecipeTooltip:SetPoint("TOPLEFT", frame, "TOPLEFT", 1194, -200)' in UI


def test_history_bars_show_percentage_change_labels():
    assert "UI.historyBarLabels = {}" in UI
    assert 'string.format("%+.1f%%", change)' in UI
    assert "percentLabel:Show()" in UI
    assert 'UI.historyGraph:SetSize(236, 60)' in UI


def test_release_versions_agree():
    assert 'MM.version = "0.6.6"' in CORE
    assert '## Version: 0.6.6' in TOC
    assert MANIFEST["version"] == "0.6.6"
