import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def test_086_catalogue_refresh_is_provenance_only_and_runtime_contract_is_preserved():
    old = json.loads((ROOT / "data/ForeverDB-Canonical-1.60.1.70888.json").read_text())
    new = json.loads((ROOT / "data/ForeverDB-Canonical-1.60.1.70938.json").read_text())
    assert new["client_build"] == "1.60.1.70938"
    assert len(new["professions"]) == 12
    old_prof = {p["slug"]: p for p in old["professions"]}
    new_prof = {p["slug"]: p for p in new["professions"]}
    assert old_prof.keys() == new_prof.keys()
    for slug in old_prof:
        assert old_prof[slug]["recipes"] == new_prof[slug]["recipes"]
        assert old_prof[slug]["trainers"] == new_prof[slug]["trainers"]
    runtime = (ROOT / "AddOns/ModuloMarket/ForeverDBData.lua").read_text()
    assert '["clientBuild"]="1.60.1.70938"' in runtime
    assert runtime.count('["acquisitionSources"]') == 2493
    assert runtime.count('["learnAtSkill"]') == 2493
    assert runtime.count('["trainerCostCopper"]') == 2493
    assert runtime.count('["trainerCostEvidence"]') == 2493
    assert "FOREVER_OBSERVED" in runtime and "CLASSIC_BORROWED" in runtime and "UNKNOWN" in runtime

