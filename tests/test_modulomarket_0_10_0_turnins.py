from pathlib import Path
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text(encoding="utf-8")
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text(encoding="utf-8")
DATA = (ROOT / "AddOns/ModuloMarket/TurnInData.lua").read_text(encoding="utf-8")
ENGINE = (ROOT / "AddOns/ModuloMarket/TurnInEngine.lua").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text(encoding="utf-8"))


def test_release_versions_and_load_order_align():
    assert 'MM.version = "0.10.1"' in CORE
    assert "## Version: 0.10.1" in TOC
    assert MANIFEST["version"] == "0.10.1"
    assert TOC.index("TurnInData.lua") < TOC.index("TurnInEngine.lua") < TOC.index("MarketUI.lua")


def test_low_supply_is_replaced_by_turn_ins_not_a_duplicate_market_filter():
    specs = UI.split("local tabSpecs = {", 1)[1].split("\n    }", 1)[0]
    assert '{ "turnins", "Turn-Ins", 194 }' in specs
    assert '{ "low", "Low Supply", 194 }' not in specs
    assert 'button.tooltipText = "Compare every Waylaid Crate' in UI


def test_turnin_dataset_has_all_crates_and_separate_alternative_bundles():
    assert len([line for line in DATA.splitlines() if '{ id=248' in line and 'name="Waylaid Crate:' in line]) == 30
    assert 'rewardFavor=nil' in DATA and 'rewardCashCopper=nil' in DATA
    assert 'firstTurnInBonus = { favor=50, reputation=2000, oneTime=true }' in DATA
    assert 'performanceBonusIncluded = false' in DATA
    assert 'provider = "User-supplied Polestar Codex item index;' in DATA


def test_engine_prices_crate_and_materials_and_fails_closed_on_unknown_depth():
    assert 'local crateCost, crateReason = PriceFor(crateMarket, 1)' in ENGINE
    assert 'else lineCost, reason = PriceFor(marketItem, quantity) end' in ENGINE
    assert 'depth < quantity' in ENGINE
    assert 'deeper listing prices are not exposed by this snapshot' in ENGINE
    assert 'local gross = crateCost and bestBundle and (crateCost + bestBundle.costCopper) or nil' in ENGINE
    assert 'local net = gross and crate.rewardCashCopper ~= nil and (gross - crate.rewardCashCopper) or nil' in ENGINE


def test_ui_exposes_cost_cash_favor_reputation_and_net_return():
    assert '"Completion Cost", "Cash Return", "Favor / Rep", "Net Cost / Favor"' in UI
    assert 'UI.detailPriceLabel:SetText(tab == "turnins" and "COMPLETION COST"' in UI
    assert 'UI.detailSupplyLabel:SetText(tab == "turnins" and "CASH RETURN"' in UI
    assert 'UI.detailAtPriceLabel:SetText(tab == "turnins" and "FAVOR / REP"' in UI
    assert 'UI.detailProfitLabel:SetText(tab == "turnins" and "NET COST / FAVOR"' in UI
    assert 'Search crate / material' in UI


def test_turnin_market_prices_obey_current_snapshot_compatibility_gate():
    assert 'local turnInPriceIndex = UI.recipeMarketBuildCompatible == false and {} or UI.catalogByID' in UI
    assert 'MM.TurnInEngine.BuildRows(UI.catalog, turnInPriceIndex)' in UI


def test_lua_harness_executes_when_texlua_is_available():
    runner = shutil.which("texlua") or shutil.which("luatex")
    if not runner:
        return
    result = subprocess.run([runner, str(ROOT / "tests/turnin_0_10_0_harness.lua"), str(ROOT)],
                           capture_output=True, text=True, check=True)
    assert "PASS 30 crate definitions" in result.stdout
    assert "PASS 96 one-of bundle alternatives" in result.stdout
    assert "PASS missing crate AH price fails closed" in result.stdout
