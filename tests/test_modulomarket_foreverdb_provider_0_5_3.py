import subprocess
from pathlib import Path


def test_foreverdb_provider_loads_only_matching_client_build():
    root = Path(__file__).parents[1]
    result = subprocess.run(
        [
            "texlua",
            "tests/foreverdb_provider_0_5_3_harness.lua",
            "AddOns/ModuloMarket/ForeverDBData.lua",
            "AddOns/ModuloMarket/ProfessionData.lua",
        ],
        cwd=root,
        text=True,
        capture_output=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert "ModuloMarket baseline-plus-delta provider harness passed" in result.stdout


def test_foreverdb_data_load_order_build_gate_and_visible_credit():
    root = Path(__file__).parents[1]
    toc = (root / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
    core = (root / "AddOns/ModuloMarket/Core.lua").read_text()
    profession = (root / "AddOns/ModuloMarket/ProfessionData.lua").read_text()
    ui = (root / "AddOns/ModuloMarket/MarketUI.lua").read_text()
    assert "## Version: 0.5.7" in toc
    assert 'MM.version = "0.5.7"' in core
    assert toc.index("ForeverDBData.lua") < toc.index("ProfessionData.lua") < toc.index("MarketUI.lua")
    assert "GetBuildInfo" in profession and "FOREVERDB_HOTFIX_WATCH" in profession
    assert 'freshnessStatus = hotfixWatch and "review" or "baseline"' in profession
    assert "datasetBuild ~= currentBuild" not in profession
    assert "dataBuildMatchesClient" in profession
    assert "Data from ForeverDB.net" in ui
    assert "https://foreverdb.net" in ui
    assert "GetMarketPrice" in ui and "recipeMarketBuildCompatible" in ui
    assert "IsMarketSnapshotCompatible" in ui
