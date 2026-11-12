import json
from pathlib import Path

ROOT = Path(__file__).parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
PROFESSION = (ROOT / "AddOns/ModuloMarket/ProfessionData.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_all_crafts_filter_is_learned_vs_unlearned_only():
    block = UI.split('local function GetRoleOptions()', 1)[1].split('elseif UI.activeTab == "crafting"', 1)[0]
    assert '{ text = "All recipes", value = "all"' in block
    assert '{ text = "Known by you", value = "known"' in block
    assert '{ text = "Unlearned", value = "unlearned"' in block
    for obsolete in ("Unlearned: confirmed", "Unlearned: borrowed", "Unlearned: unknown"):
        assert obsolete not in block


def test_unlearned_filter_includes_every_unlearned_source_class():
    assert 'elseif build.itemRoleFilter == "unlearned" then\n                    matches = status ~= "known"' in UI
    assert 'elseif role == "unlearned" then' in PROFESSION
    assert '#entry.futureCrafts > 0 or #entry.unknownFutureCrafts > 0' in PROFESSION


def test_item_role_filter_hides_acquisition_evidence_categories():
    block = UI.split('local function GetRoleOptions()', 1)[1].split('UI.roleDropdown = CreateDropdown', 1)[0]
    assert '"Unlearned craft outputs"' in block
    for obsolete in ("Unlearned: borrowed", "Unlearned: unknown", "confirmed source"):
        assert obsolete not in block
    assert "gather" in block and "material" in block


def test_release_versions_agree():
    assert 'MM.version = "0.6.7"' in CORE
    assert '## Version: 0.6.7' in TOC
    assert MANIFEST["version"] == "0.6.7"
