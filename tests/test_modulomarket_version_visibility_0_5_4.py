from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"


def test_version_is_consistent_across_toc_core_and_manifest():
    toc = (ADDON / "ModuloMarket.toc").read_text()
    core = (ADDON / "Core.lua").read_text()
    manifest = json.loads((ROOT / "MANIFEST.json").read_text())
    assert "## Version: 0.5.4" in toc
    assert 'MM.version = "0.5.4"' in core
    assert manifest["version"] == "0.5.4"


def test_login_announcement_and_version_command_include_build():
    core = (ADDON / "Core.lua").read_text()
    assert '"Loaded v" .. MM.version' in core
    assert 'SLASH_MODULOMARKETVERSION1 = "/mmversion"' in core
    assert "SlashCmdList.MODULOMARKETVERSION = PrintVersion" in core
    assert '"client %s build %s"' in core
    assert "provider.datasetBuild" in core


def test_market_footer_shows_addon_and_client_version():
    ui = (ADDON / "MarketUI.lua").read_text()
    assert '"ModuloMarket v" .. tostring(MM.version' in ui
    assert '" · Client %s build %s"' in ui
    assert "UI.versionLabel = AddLabel" in ui


def test_old_foreverdb_dataset_is_not_unlocked_for_70888():
    profession = (ADDON / "ProfessionData.lua").read_text()
    assert 'datasetBuild ~= currentBuild' in profession
    assert "imported recipes are not loaded" in profession
