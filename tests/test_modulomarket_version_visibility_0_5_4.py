from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"


def test_version_is_consistent_across_toc_core_and_manifest():
    toc = (ADDON / "ModuloMarket.toc").read_text()
    core = (ADDON / "Core.lua").read_text()
    manifest = json.loads((ROOT / "MANIFEST.json").read_text())
    assert "## Version: 0.5.5" in toc
    assert 'MM.version = "0.5.5"' in core
    assert manifest["version"] == "0.5.5"


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


def test_old_foreverdb_dataset_loads_as_baseline_with_targeted_review_flags():
    profession = (ADDON / "ProfessionData.lua").read_text()
    assert 'FOREVERDB_HOTFIX_WATCH' in profession
    assert 'freshnessStatus = hotfixWatch and "review" or "baseline"' in profession
    assert "dataBuildMatchesClient" in profession
    assert "datasetBuild ~= currentBuild" not in profession
