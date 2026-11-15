#!/usr/bin/env python3
"""Build a conservative ForeverDB distribution projection from reviewed canonical data.

Keeps Forever-client recipe structures/outputs/reagents and only acquisition facts
explicitly labelled FOREVER_OBSERVED or FOREVER_CLIENT. Removes speculative recipes,
Classic-borrowed and UNKNOWN acquisition rows, Classic comparison fields, non-observed
trainer locations, and non-observed trainer prices. This is a distribution projection,
not a new provider capture or a claim of third-party rights clearance.
"""
from __future__ import annotations
import argparse
import copy
import json
from pathlib import Path
from collections import Counter

KEEP_EVIDENCE = {"FOREVER_OBSERVED", "FOREVER_CLIENT"}
CLASSIC_TRAINER_LOCATION_FIELDS = ("title", "zone", "map_id", "x", "y", "source_text")
PROVIDER_METADATA_ALLOWLIST = {
    "spell_id", "required_level", "automatic", "learn_at_skill",
    "reagent_data_available", "trainer_cost_copper", "trainer_cost_evidence",
    "new_in_forever",
}


def project(data: dict) -> tuple[dict, dict]:
    out = copy.deepcopy(data)
    counts = Counter()
    for profession in out["professions"]:
        kept_trainers = []
        for trainer in profession.get("trainers", []):
            if trainer.get("entity_evidence") != "FOREVER_OBSERVED":
                counts["trainer_entities_excluded"] += 1
                continue
            if trainer.get("place_evidence") != "FOREVER_OBSERVED":
                for field in CLASSIC_TRAINER_LOCATION_FIELDS:
                    trainer.pop(field, None)
                trainer["place_seen_in_forever"] = None
                trainer["place_evidence"] = "UNKNOWN"
                counts["trainer_locations_quarantined"] += 1
            kept_trainers.append(trainer)
        profession["trainers"] = kept_trainers
        profession["trainer_count"] = len(kept_trainers)
        profession["trainers_seen_in_forever_count"] = len(kept_trainers)
        profession.pop("changed_from_classic_count", None)

        kept_recipes = []
        for recipe in profession.get("recipes", []):
            counts["source_recipe_records"] += 1
            if recipe.get("structure_evidence") != "FOREVER_CLIENT":
                raise ValueError(f"Refusing non-client recipe structure: {profession['slug']}:{recipe.get('recipe_id')}")
            for output in recipe.get("outputs", []):
                if output.get("quantity_evidence") != "FOREVER_CLIENT":
                    raise ValueError(f"Refusing non-client output quantity: {recipe.get('recipe_id')}")
            for group in recipe.get("reagent_groups", []):
                if group.get("quantity_evidence") != "FOREVER_CLIENT":
                    raise ValueError(f"Refusing non-client reagent quantity: {recipe.get('recipe_id')}")

            metadata = recipe.get("provider_metadata", {})
            if metadata.get("speculation") is True:
                counts["speculative_recipes_excluded"] += 1
                continue

            sources = recipe.get("acquisition_sources", [])
            kept_sources = []
            for source in sources:
                evidence = source.get("evidence")
                if evidence in KEEP_EVIDENCE and source.get("inferred") is not True:
                    kept_sources.append(source)
                    counts[f"acquisition_{evidence.lower()}"] += 1
                else:
                    counts[f"acquisition_{evidence.lower() if evidence else 'missing'}_excluded"] += 1
            recipe["acquisition_sources"] = kept_sources

            skill = recipe.get("skill") or {}
            # Orange is retained only when the provider explicitly attributes it to
            # Forever client data. Classic comparison thresholds are never shipped.
            if skill.get("orange_evidence") != "FOREVER_CLIENT":
                skill.pop("orange", None)
                counts["orange_thresholds_quarantined"] += 1
            skill.pop("orange_classic", None)
            skill.pop("orange_source", None)
            if skill.get("other_threshold_evidence") != "FOREVER_CLIENT":
                for key in ("yellow", "green", "grey"):
                    skill.pop(key, None)
                counts["other_threshold_sets_quarantined"] += 1
            recipe["skill"] = skill

            if metadata.get("trainer_cost_evidence") != "FOREVER_OBSERVED":
                metadata.pop("trainer_cost_copper", None)
                metadata["trainer_cost_evidence"] = "UNKNOWN"
                counts["trainer_costs_quarantined"] += 1

            recipe["provider_metadata"] = {
                key: value for key, value in metadata.items()
                if key in PROVIDER_METADATA_ALLOWLIST
            }
            counts["recipes_retained"] += 1
            counts["recipes_without_retained_source"] += not bool(kept_sources)
            kept_recipes.append(recipe)

        profession["recipes"] = kept_recipes
        profession["recipe_count"] = len(kept_recipes)
        profession["new_in_forever_count"] = sum(
            1 for r in kept_recipes if r.get("provider_metadata", {}).get("new_in_forever") is True
        )

    # Remove prose/aggregate fields that describe or summarize mixed Classic and
    # unknown source material. The dated audit retains the original source hash/counts.
    out.pop("provider_notes", None)
    out.pop("provider_meta", None)
    out["normalization_summary"] = {
        "profession_count": len(out["professions"]),
        "recipe_count": counts["recipes_retained"],
        "distribution_projection": "FOREVER_CLIENT_STRUCTURE_PLUS_OBSERVED_ACQUISITION_V1",
    }
    counts["professions"] = len(out["professions"])
    counts["retained_trainer_entities"] = sum(len(p.get("trainers", [])) for p in out["professions"])
    counts["retained_acquisition_rows"] = sum(len(r.get("acquisition_sources", [])) for p in out["professions"] for r in p["recipes"])
    return out, dict(counts)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("input", type=Path)
    ap.add_argument("output", type=Path)
    ap.add_argument("--report", type=Path)
    args = ap.parse_args()
    source = json.loads(args.input.read_text(encoding="utf-8"))
    projected, counts = project(source)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(projected, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if args.report:
        args.report.write_text(json.dumps(counts, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(counts, indent=2, sort_keys=True))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
