#!/usr/bin/env python3
"""Offline-first ForeverDB capture, canonical validation and Lua compiler.

Raw provider capture is intentionally separate from normalization. We will not
map an undocumented response shape into player data until an approved response
sample is available and reviewed. Python 3.10+, standard library only.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

API_ROOT = "https://foreverdb.net/api/v1"
PROVIDER_URL = "https://foreverdb.net"
MIN_INTERVAL = 1.05  # stays below the documented 60 requests/minute ceiling
MAX_PAGE_SIZE = 100
USER_AGENT = "ModuloMarketDataImporter/0.2.0 (+https://github.com/moonlitfarewell/modulo-market)"
EVIDENCE = {
    "FOREVER_CLIENT", "FOREVER_OBSERVED", "FOREVERTOME_CLIENT_ARCHIVE",
    "LIBPROFESSIONDB", "CLASSIC_BORROWED", "UNKNOWN",
}


class ImporterError(RuntimeError):
    pass


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def envelope(value: Any, label: str) -> tuple[Any, dict[str, Any]]:
    if not isinstance(value, dict) or "data" not in value or not isinstance(value.get("meta"), dict):
        raise ImporterError(f"{label}: expected documented JSON {{data, meta}} envelope")
    return value["data"], value["meta"]


def safe_slug(value: Any) -> str:
    if not isinstance(value, str) or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", value):
        raise ImporterError(f"Profession slug is not safe/recognized: {value!r}")
    return value


def named_list(data: Any, keys: tuple[str, ...]) -> list[Any] | None:
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        for key in keys:
            if isinstance(data.get(key), list):
                return data[key]
    return None


def index_slugs(data: Any) -> list[str]:
    rows = named_list(data, ("professions", "results", "items", "records"))
    if rows is None:
        raise ImporterError("Profession index shape is not recognized; raw response was saved for inspection.")
    found: list[str] = []
    for row in rows:
        if isinstance(row, dict):
            slug = row.get("slug") or row.get("key")
            if isinstance(slug, str):
                slug = safe_slug(slug)
                if slug not in found:
                    found.append(slug)
    if not found:
        raise ImporterError("Profession index has no documented slug/key values; raw response was saved.")
    return found


def recipe_page(data: Any) -> list[Any] | None:
    # Only direct recipe pages are paged automatically. Rank-wrapped data is retained raw.
    return named_list(data, ("recipes", "results", "records"))


def meta_total(meta: dict[str, Any]) -> int | None:
    for key in ("total", "count", "totalRecipes"):
        value = meta.get(key)
        if isinstance(value, int) and not isinstance(value, bool) and value >= 0:
            return value
    return None


class ForeverDBClient:
    def __init__(self, api_key: str, *, delay: float = MIN_INTERVAL, timeout: float = 30,
                 opener: Callable[..., Any] | None = None, sleeper: Callable[[float], None] = time.sleep,
                 clock: Callable[[], float] = time.monotonic, retries: int = 4) -> None:
        if not api_key.strip():
            raise ImporterError("API key is empty")
        if delay < MIN_INTERVAL:
            raise ImporterError(f"Delay must be at least {MIN_INTERVAL:.2f}s to respect ForeverDB's 60/minute limit")
        self._key = api_key.strip()
        self.delay, self.timeout, self.opener = delay, timeout, opener or urllib.request.urlopen
        self.sleeper, self.clock, self.retries = sleeper, clock, retries
        self.last_request: float | None = None
        self.request_count = 0

    def get(self, endpoint: str, params: dict[str, Any] | None = None) -> tuple[Any, bytes]:
        if not endpoint.startswith("/") or ".." in endpoint.split("/"):
            raise ImporterError(f"Invalid endpoint: {endpoint}")
        query = urllib.parse.urlencode(params or {})
        url = API_ROOT + endpoint + ("?" + query if query else "")
        request = urllib.request.Request(url, headers={
            "Accept": "application/json", "X-API-Key": self._key, "User-Agent": USER_AGENT,
        }, method="GET")
        for attempt in range(self.retries + 1):
            if self.last_request is not None:
                wait = self.delay - (self.clock() - self.last_request)
                if wait > 0:
                    self.sleeper(wait)
            self.last_request = self.clock()
            self.request_count += 1
            try:
                with self.opener(request, timeout=self.timeout) as response:
                    status = int(getattr(response, "status", 200))
                    body = response.read()
                if not 200 <= status < 300:
                    raise ImporterError(f"ForeverDB HTTP {status} for {endpoint}")
                try:
                    parsed = json.loads(body.decode("utf-8"))
                except (UnicodeDecodeError, json.JSONDecodeError) as exc:
                    raise ImporterError(f"Invalid JSON from {endpoint}: {exc}") from exc
                envelope(parsed, endpoint)
                return parsed, body
            except urllib.error.HTTPError as exc:
                status = int(exc.code)
                if status == 429:
                    header = exc.headers.get("Retry-After") if exc.headers else None
                    try:
                        delay = max(float(header), self.delay) if header else max(5.0, self.delay)
                    except ValueError:
                        delay = max(5.0, self.delay)
                    if attempt >= self.retries:
                        raise ImporterError(f"Rate limited on {endpoint}; Retry-After={header or 'unknown'}; stop and retry later") from exc
                    self.sleeper(delay)
                    self.last_request = self.clock()
                    continue
                if 500 <= status <= 599 and attempt < self.retries:
                    self.sleeper(min(2 ** attempt, 16))
                    continue
                raise ImporterError(f"ForeverDB HTTP {status} for {endpoint}") from exc
            except urllib.error.URLError as exc:
                if attempt >= self.retries:
                    raise ImporterError(f"Network error on {endpoint}: {exc.reason}") from exc
                self.sleeper(min(2 ** attempt, 16))
        raise ImporterError(f"Request failed for {endpoint}")


def capture(client: ForeverDBClient, output: Path, *, page_size: int = 100,
            max_pages: int = 100, max_requests: int = 500) -> dict[str, Any]:
    if not 1 <= page_size <= MAX_PAGE_SIZE:
        raise ImporterError(f"page-size must be 1..{MAX_PAGE_SIZE}")
    if max_pages < 1 or max_requests < 2:
        raise ImporterError("max-pages must be >=1 and max-requests >=2")
    output.mkdir(parents=True, exist_ok=True)
    responses: list[dict[str, Any]] = []
    slugs: list[str] = []
    profession_reports: list[dict[str, Any]] = []
    provider_build: Any = None
    started_at = utc_now()

    def write_manifest(status: str, warnings: list[str] | None = None) -> dict[str, Any]:
        manifest = {
            "capture_schema_version": 1,
            "status": status,
            "provider": "ForeverDB.net",
            "provider_url": PROVIDER_URL,
            "api_root": API_ROOT,
            "started_at_utc": started_at,
            "updated_at_utc": utc_now(),
            "client_build": provider_build,
            "profession_slugs": list(slugs),
            "profession_reports": list(profession_reports),
            "request_count": client.request_count,
            "rate_limit_policy": {"per_minute": 60, "per_day": 10000,
                                  "interval_seconds": client.delay, "max_requests": max_requests},
            "responses": list(responses),
            "credential_policy": "Environment only; never persisted",
            "normalization_status": "RAW_CAPTURE_ONLY_SCHEMA_REVIEW_REQUIRED",
            "warnings": warnings or [
                "Raw capture is not addon-ready data.",
                "Rank/skill-wrapped responses are retained but not auto-paginated until their shape is reviewed.",
                "Client recipe presence does not prove live availability.",
                "Classic-derived learning sources and prices must remain borrowed/unconfirmed.",
            ],
        }
        (output / "capture-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        return manifest

    write_manifest("IN_PROGRESS")

    def get_save(label: str, endpoint: str, params: dict[str, Any]) -> tuple[Any, dict[str, Any]]:
        if client.request_count >= max_requests:
            write_manifest("PARTIAL", [f"Stopped at configured safety cap of {max_requests} requests."])
            raise ImporterError(f"Stopped at safety cap of {max_requests} requests")
        parsed, raw = client.get(endpoint, params)
        data, meta = envelope(parsed, endpoint)
        target = output / label
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
        responses.append({
            "relative_path": Path(label).as_posix(),
            "request_path": endpoint + ("?" + urllib.parse.urlencode(params) if params else ""),
            "fetched_at_utc": utc_now(),
            "sha256": sha256(raw),
            "bytes": len(raw),
        })
        write_manifest("IN_PROGRESS")
        return data, meta

    try:
        meta_data, api_meta = get_save("meta.json", "/meta", {})
        index_data, _ = get_save("professions-index.json", "/professions", {"limit": 100, "offset": 0})
        slugs = index_slugs(index_data)
        write_manifest("IN_PROGRESS")
        if isinstance(meta_data, dict):
            provider_build = meta_data.get("build") or meta_data.get("clientBuild") or meta_data.get("gameBuild")
        provider_build = provider_build or api_meta.get("build") or api_meta.get("clientBuild")
        write_manifest("IN_PROGRESS")

        for slug in slugs:
            offset, pages, count, total, opaque = 0, 0, 0, None, False
            while pages < max_pages:
                params = {"limit": page_size, "offset": offset}
                data, meta = get_save(
                    f"professions/{slug}/offset-{offset:06d}.json",
                    f"/professions/{slug}", params
                )
                pages += 1
                rows = recipe_page(data)
                if rows is None:
                    opaque = True
                    break
                count += len(rows)
                total = meta_total(meta)
                if total is not None and offset + len(rows) >= total:
                    break
                if not rows or len(rows) < page_size:
                    break
                offset += len(rows)
            else:
                opaque = True
            profession_reports.append({
                "slug": slug,
                "pages_captured": pages,
                "recipe_records_captured": count,
                "reported_total": total,
                "pagination_shape_unknown": opaque,
            })
            write_manifest("IN_PROGRESS")
        return write_manifest("COMPLETE")
    except Exception:
        # Keep all responses already fetched discoverable after network/API interruption.
        current = json.loads((output / "capture-manifest.json").read_text(encoding="utf-8"))
        if current.get("status") == "IN_PROGRESS":
            write_manifest("PARTIAL", [
                "Capture did not complete. Previously saved raw responses remain available for inspection.",
                "Inspect the error and retry remaining pages deliberately; do not concatenate unreviewed shapes.",
            ])
        raise



FOREVERDB_PROFESSION_IDS = {
    "alchemy": 171, "blacksmithing": 164, "enchanting": 333,
    "engineering": 202, "leatherworking": 165, "tailoring": 197,
    "herbalism": 182, "mining": 186, "skinning": 393,
    "cooking": 185, "first-aid": 129, "fishing": 356,
}


def _int_or_none(value: Any) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, str) and value.isdigit():
        return int(value)
    return None


def _number_or_none(value: Any) -> int | float | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    return value


def _source_evidence(seen: Any, *, inferred: bool = False) -> str:
    if inferred:
        return "UNKNOWN"
    if seen is True:
        return "FOREVER_OBSERVED"
    if seen is False:
        return "CLASSIC_BORROWED"
    return "UNKNOWN"


def _normalise_foreverdb_recipe(slug: str, raw: dict[str, Any]) -> dict[str, Any]:
    recipe_id = _int_or_none(raw.get("spellId"))
    name = raw.get("name")
    if not recipe_id or recipe_id <= 0 or not isinstance(name, str) or not name.strip():
        raise ImporterError(f"{slug}: recipe is missing a positive spellId or name")

    category = raw.get("category") if isinstance(raw.get("category"), dict) else {}
    category_name = category.get("name") if isinstance(category.get("name"), str) else None
    parent = category.get("parent") if isinstance(category.get("parent"), dict) else {}
    parent_name = parent.get("name") if isinstance(parent.get("name"), str) else None

    makes = raw.get("makes") if isinstance(raw.get("makes"), dict) else None
    outputs: list[dict[str, Any]] = []
    if makes and _int_or_none(makes.get("itemId")) and _int_or_none(makes.get("itemId")) > 0:
        count = _int_or_none(makes.get("count"))
        valid_count = count if count is not None and count > 0 else None
        outputs.append({
            "item_id": _int_or_none(makes.get("itemId")),
            "name": makes.get("name") if isinstance(makes.get("name"), str) else None,
            "quantity_min": valid_count,
            "quantity_max": valid_count,
            "quantity_evidence": "FOREVER_CLIENT" if valid_count is not None else "UNKNOWN",
            "quality": makes.get("quality"),
            "url": makes.get("url"),
        })
        output_kind = "item"
    elif slug == "enchanting" and isinstance(category_name, str) and "enchant" in category_name.lower():
        output_kind = "enchantment"
    else:
        output_kind = "unknown"

    raw_reagents = raw.get("reagents")
    reagent_groups: list[dict[str, Any]] = []
    reagent_data_available = isinstance(raw_reagents, list)
    if isinstance(raw_reagents, list):
        for index, reagent in enumerate(raw_reagents):
            if not isinstance(reagent, dict):
                raise ImporterError(f"{slug}/{recipe_id}: reagent[{index}] is not an object")
            item_id = _int_or_none(reagent.get("itemId"))
            if not item_id or item_id <= 0:
                raise ImporterError(f"{slug}/{recipe_id}: reagent[{index}] has no positive itemId")
            quantity = _int_or_none(reagent.get("count"))
            if quantity is not None and quantity <= 0:
                quantity = None
            reagent_groups.append({
                # ForeverDB's captured recipe reagent list has no optional/alternative
                # flags: each listed row is represented as one required single-choice slot.
                "required": True,
                "quantity_min": quantity,
                "quantity_max": quantity,
                "quantity_evidence": "FOREVER_CLIENT" if quantity is not None else "UNKNOWN",
                "choices": [{
                    "item_id": item_id,
                    "name": reagent.get("name") if isinstance(reagent.get("name"), str) else None,
                }],
            })

    skill = raw.get("skill") if isinstance(raw.get("skill"), dict) else {}
    orange_source = skill.get("orangeSource")
    orange_evidence = (
        "FOREVER_CLIENT" if orange_source == "client"
        else "CLASSIC_BORROWED" if orange_source == "classic"
        else "UNKNOWN"
    )
    skill_data = {
        "orange": _int_or_none(skill.get("orange")),
        "yellow": _int_or_none(skill.get("yellow")),
        "green": _int_or_none(skill.get("green")),
        "grey": _int_or_none(skill.get("grey")),
        "orange_classic": _int_or_none(skill.get("orangeClassic")),
        "orange_source": orange_source if isinstance(orange_source, str) else None,
        "orange_evidence": orange_evidence,
        "other_threshold_evidence": "FOREVER_CLIENT" if any(
            _int_or_none(skill.get(key)) is not None for key in ("yellow", "green", "grey")
        ) else "UNKNOWN",
        # These are client skill-up colours, not trainer learning requirements.
        "threshold_evidence": "FOREVER_CLIENT" if skill else "UNKNOWN",
    }

    learned = raw.get("learnedFrom") if isinstance(raw.get("learnedFrom"), dict) else {}
    source_data = learned.get("sources") if isinstance(learned.get("sources"), dict) else {}
    acquisition: list[dict[str, Any]] = []

    def add_source(row: dict[str, Any]) -> None:
        acquisition.append(row)

    if learned.get("automatic") is True:
        add_source({
            "type": "automatic", "name": None, "faction": None,
            "seen_in_forever": True, "evidence": "FOREVER_CLIENT",
            "source_text": "ForeverDB marks this recipe as learned automatically.",
        })

    trainers = source_data.get("trainers")
    if isinstance(trainers, dict):
        for faction_key, rows in trainers.items():
            if not isinstance(rows, list):
                continue
            for trainer in rows:
                if not isinstance(trainer, dict):
                    continue
                inferred = trainer.get("inferred") is True
                seen = trainer.get("seenInForever")
                add_source({
                    "type": "trainer",
                    "name": trainer.get("name") if isinstance(trainer.get("name"), str) else None,
                    "faction": trainer.get("faction") or faction_key,
                    "npc_id": _int_or_none(trainer.get("npcId")),
                    "title": trainer.get("title"),
                    "zone": trainer.get("zone"),
                    "map_id": _int_or_none(trainer.get("mapId")),
                    "x": _number_or_none(trainer.get("x")),
                    "y": _number_or_none(trainer.get("y")),
                    "seen_in_forever": seen if isinstance(seen, bool) else None,
                    "inferred": inferred,
                    "entity_evidence": "FOREVER_OBSERVED" if seen is True else _source_evidence(seen),
                    "evidence": _source_evidence(seen, inferred=inferred),
                    "source_text": trainer.get("source"),
                })

    vendors = source_data.get("vendors")
    if isinstance(vendors, dict):
        for faction_key, rows in vendors.items():
            if not isinstance(rows, list):
                continue
            for vendor in rows:
                if not isinstance(vendor, dict):
                    continue
                seen = vendor.get("seenInForever")
                add_source({
                    "type": "vendor",
                    "name": vendor.get("name") if isinstance(vendor.get("name"), str) else None,
                    "faction": vendor.get("faction") or faction_key,
                    "npc_id": _int_or_none(vendor.get("npcId")),
                    "title": vendor.get("title"),
                    "zone": vendor.get("zone"),
                    "map_id": _int_or_none(vendor.get("mapId")),
                    "x": _number_or_none(vendor.get("x")),
                    "y": _number_or_none(vendor.get("y")),
                    "price_copper": _int_or_none(vendor.get("price")),
                    "price_per_item_copper": _number_or_none(vendor.get("pricePerItem")),
                    "stack_size": _int_or_none(vendor.get("stack")),
                    "costs": vendor.get("costs") if isinstance(vendor.get("costs"), list) else [],
                    "limited_stock": vendor.get("limitedStock") if isinstance(vendor.get("limitedStock"), bool) else None,
                    "limited_stock_count": _int_or_none(vendor.get("limitedStockCount")),
                    "not_on_list_players_saw": vendor.get("notOnListPlayersSaw") is True,
                    "reputation_faction": vendor.get("reputationFaction"),
                    "seen_in_forever": seen if isinstance(seen, bool) else None,
                    "evidence": _source_evidence(seen),
                    "source_text": vendor.get("source"),
                })

    drops = source_data.get("drops")
    if isinstance(drops, list):
        for drop in drops:
            if not isinstance(drop, dict):
                continue
            add_source({
                "type": "drop", "name": drop.get("from"),
                "npc_id": _int_or_none(drop.get("npcId")),
                "chance_percent": _number_or_none(drop.get("chancePercent")),
                "seen_in_forever": None, "evidence": "UNKNOWN",
                "source_text": drop.get("source"),
            })

    quests = source_data.get("quests")
    if isinstance(quests, list):
        for quest in quests:
            if not isinstance(quest, dict):
                continue
            # inForeverClient establishes that the quest is present in the client;
            # it does not, by itself, prove this recipe/quest acquisition edge was observed.
            add_source({
                "type": "quest", "name": quest.get("name"),
                "quest_id": _int_or_none(quest.get("questId")),
                "faction": quest.get("faction"),
                "in_forever_client": quest.get("inForeverClient") is True,
                "seen_in_forever": None, "evidence": "UNKNOWN",
                "source_text": quest.get("source"),
                "url": quest.get("url"),
            })

    recipe_item_sets = (
        ("recipe_item", learned.get("recipeItems"), "normal"),
        ("recipe_item_hidden", learned.get("recipeItemsHidden"), "hidden"),
        ("recipe_item_not_in_client", learned.get("recipeItemsNotInClient"), "not_in_client"),
    )
    for source_type, rows, visibility in recipe_item_sets:
        if isinstance(rows, list):
            for item in rows:
                if not isinstance(item, dict):
                    continue
                add_source({
                    "type": source_type, "name": item.get("name"),
                    "item_id": _int_or_none(item.get("itemId")),
                    "visibility": visibility,
                    "seen_in_forever": None, "evidence": "UNKNOWN",
                })

    for trainer_name in learned.get("seenAtForeverTrainers", []) if isinstance(learned.get("seenAtForeverTrainers"), list) else []:
        if isinstance(trainer_name, str) and trainer_name.strip():
            if not any(s.get("type") == "trainer" and s.get("name") == trainer_name for s in acquisition):
                add_source({
                    "type": "trainer_observation", "name": trainer_name,
                    "seen_in_forever": True, "evidence": "FOREVER_OBSERVED",
                })

    trainer_cost = _number_or_none(source_data.get("trainerCost"))
    trainer_cost_source = source_data.get("trainerCostSource")
    trainer_cost_evidence = (
        "FOREVER_OBSERVED" if isinstance(trainer_cost_source, str) and "seen in forever" in trainer_cost_source.lower()
        else "CLASSIC_BORROWED" if trainer_cost is not None
        else "UNKNOWN"
    )

    provider_metadata = {
        "spell_id": recipe_id,
        "icon_url": raw.get("icon"),
        "url": raw.get("url"),
        "required_level": _int_or_none(raw.get("requiredLevel")),
        "effect": raw.get("effect"),
        "tools": raw.get("tools") if isinstance(raw.get("tools"), list) else [],
        "needs_nearby": raw.get("needsNearby"),
        "new_in_forever": raw.get("newInForever") is True,
        "changed_from_classic": raw.get("changedFromClassic"),
        "same_name_recipes": raw.get("sameNameRecipes") if isinstance(raw.get("sameNameRecipes"), list) else [],
        "leftover_of": raw.get("leftoverOf"),
        "classic": raw.get("classic"),
        "camp_tier": raw.get("campTier"),
        "speculation": raw.get("speculation") is True,
        "speculation_reasons": raw.get("speculationReasons") if isinstance(raw.get("speculationReasons"), list) else [],
        "learned_from_known": learned.get("known") if isinstance(learned.get("known"), bool) else None,
        "automatic": learned.get("automatic") is True,
        "learning_ways": source_data.get("ways") if isinstance(source_data.get("ways"), list) else [],
        "learn_at_skill": _int_or_none(source_data.get("learnAtSkill")),
        "sources_recipe_item": source_data.get("recipeItem"),
        "trainer_summary": learned.get("trainer"),
        "trainer_counts_by_faction": source_data.get("trainersInAll"),
        "drops_in_all": _int_or_none(source_data.get("dropsInAll")),
        "reputation_faction_id": _int_or_none(source_data.get("reputationFactionId")),
        "classic_vendors": _int_or_none(learned.get("classicVendors")),
        "seen_at_forever_trainers": learned.get("seenAtForeverTrainers") if isinstance(learned.get("seenAtForeverTrainers"), list) else [],
        "trainer_cost_copper": trainer_cost,
        "trainer_cost_evidence": trainer_cost_evidence,
        "trainer_cost_source": trainer_cost_source,
        "reagent_data_available": reagent_data_available,
    }

    return {
        "recipe_id": recipe_id,
        "name": name.strip(),
        "category": category_name,
        "category_id": _int_or_none(category.get("id")),
        "category_parent": parent_name,
        "structure_evidence": "FOREVER_CLIENT",
        "output_kind": output_kind,
        "outputs": outputs,
        "reagent_groups": reagent_groups,
        "skill": skill_data,
        "acquisition_sources": acquisition,
        "provider_metadata": provider_metadata,
    }


def normalize_capture(capture_path: Path) -> dict[str, Any]:
    manifest_path = capture_path / "capture-manifest.json"
    if not manifest_path.is_file():
        raise ImporterError("capture-manifest.json is missing")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("status") != "COMPLETE":
        raise ImporterError("Only COMPLETE captures can be normalized")
    if manifest.get("provider") != "ForeverDB.net" or manifest.get("provider_url") != PROVIDER_URL:
        raise ImporterError("Capture provider metadata does not identify ForeverDB.net")
    build = manifest.get("client_build")
    if not isinstance(build, str) or not build.strip():
        raise ImporterError("Capture manifest has no client_build")

    response_entries = manifest.get("responses")
    if not isinstance(response_entries, list) or not response_entries:
        raise ImporterError("Capture manifest has no response inventory")
    if manifest.get("request_count") != len(response_entries):
        raise ImporterError("Capture request_count does not match its response inventory")
    response_by_path: dict[str, tuple[dict[str, Any], dict[str, Any]]] = {}
    for entry in response_entries:
        rel = entry.get("relative_path")
        if not isinstance(rel, str) or Path(rel).is_absolute() or ".." in Path(rel).parts:
            raise ImporterError(f"Unsafe capture response path: {rel!r}")
        source = capture_path / rel
        if not source.is_file():
            raise ImporterError(f"Capture response is missing: {rel}")
        raw_bytes = source.read_bytes()
        if len(raw_bytes) != entry.get("bytes") or sha256(raw_bytes) != entry.get("sha256"):
            raise ImporterError(f"Capture response hash/byte mismatch: {rel}")
        try:
            parsed = json.loads(raw_bytes.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise ImporterError(f"Capture response is not valid UTF-8 JSON: {rel}") from exc
        data, meta = envelope(parsed, rel)
        if meta.get("build") != build:
            raise ImporterError(f"{rel}: response build {meta.get('build')!r} differs from manifest {build!r}")
        if rel in response_by_path:
            raise ImporterError(f"Duplicate capture response path: {rel}")
        response_by_path[rel] = (data, meta)

    meta_path = next((p for p in response_by_path if Path(p).name == "meta.json"), None)
    index_path = next((p for p in response_by_path if Path(p).name == "professions-index.json"), None)
    if not meta_path or not index_path:
        raise ImporterError("Capture must include meta.json and professions-index.json")
    provider_meta = response_by_path[meta_path][0]
    if not isinstance(provider_meta, dict) or provider_meta.get("build") != build:
        raise ImporterError("meta.json data build does not agree with capture manifest")

    index_rows = named_list(response_by_path[index_path][0], ("professions", "results", "items", "records"))
    if index_rows is None:
        raise ImporterError("Profession index has an unsupported data shape")
    index_by_slug = {row.get("slug"): row for row in index_rows if isinstance(row, dict) and isinstance(row.get("slug"), str)}
    slugs = manifest.get("profession_slugs")
    if not isinstance(slugs, list) or not slugs or len(set(slugs)) != len(slugs) or set(slugs) != set(index_by_slug):
        raise ImporterError("Manifest profession slugs do not exactly match the unique profession index")
    if len(index_by_slug) != len(index_rows):
        raise ImporterError("Profession index contains duplicate or malformed rows")
    reports = {row.get("slug"): row for row in manifest.get("profession_reports", []) if isinstance(row, dict)}
    if set(reports) != set(slugs):
        raise ImporterError("Profession reports do not cover the captured profession list")

    professions: list[dict[str, Any]] = []
    total_recipes = 0
    provider_notes: set[str] = set()
    for slug in slugs:
        if slug not in FOREVERDB_PROFESSION_IDS:
            raise ImporterError(f"No reviewed WoW profession ID mapping for {slug}")
        report = reports[slug]
        if report.get("pagination_shape_unknown") is True:
            raise ImporterError(f"{slug}: capture manifest marks pagination shape unknown")
        if report.get("reported_total") != _int_or_none(index_by_slug[slug].get("recipeCount")):
            raise ImporterError(f"{slug}: profession index recipeCount differs from page report")
        page_entries = [
            (rel, data, meta) for rel, (data, meta) in response_by_path.items()
            if rel.startswith(f"professions/{slug}/") and rel.endswith(".json")
        ]
        page_entries.sort(key=lambda row: _int_or_none(row[2].get("offset")) or 0)
        if len(page_entries) != report.get("pages_captured"):
            raise ImporterError(f"{slug}: page count does not match capture manifest")
        if not page_entries:
            raise ImporterError(f"{slug}: no captured recipe pages")
        recipes: list[dict[str, Any]] = []
        seen_ids: set[int] = set()
        first_data: dict[str, Any] | None = None
        expected_offset = 0
        for page_index, (rel, data, page_meta) in enumerate(page_entries):
            if _int_or_none(page_meta.get("offset")) != expected_offset:
                raise ImporterError(f"{rel}: pagination offset gap/overlap; expected {expected_offset}")
            if not isinstance(data, dict) or data.get("slug") != slug or not isinstance(data.get("recipes"), list):
                raise ImporterError(f"{rel}: expected profession data with matching slug and recipes array")
            if page_meta.get("total") != report.get("reported_total"):
                raise ImporterError(f"{rel}: page total differs from capture manifest")
            if first_data is None:
                first_data = data
            else:
                for key in ("ranks", "trainers", "recipeCount", "name", "kind"):
                    if data.get(key) != first_data.get(key):
                        raise ImporterError(f"{rel}: profession metadata field {key!r} changed between pages")
            if _int_or_none(data.get("recipeCount")) != report.get("reported_total"):
                raise ImporterError(f"{rel}: profession data recipeCount differs from capture report")
            for raw_recipe in data["recipes"]:
                if not isinstance(raw_recipe, dict):
                    raise ImporterError(f"{rel}: recipe row is not an object")
                normalized = _normalise_foreverdb_recipe(slug, raw_recipe)
                note = ((raw_recipe.get("learnedFrom") or {}).get("sources") or {}).get("note")
                if isinstance(note, str) and note.strip():
                    provider_notes.add(note)
                rid = normalized["recipe_id"]
                if rid in seen_ids:
                    raise ImporterError(f"{slug}: duplicate recipe spellId {rid}")
                seen_ids.add(rid)
                recipes.append(normalized)
            expected_offset += len(data["recipes"])
        expected_total = report.get("reported_total")
        if len(recipes) != expected_total or len(recipes) != report.get("recipe_records_captured"):
            raise ImporterError(f"{slug}: normalized recipe total {len(recipes)} disagrees with capture report")
        if first_data is None:
            raise ImporterError(f"{slug}: missing profession detail")
        ranks = first_data.get("ranks") if isinstance(first_data.get("ranks"), list) else []
        skill_cap = max((_int_or_none(rank.get("maxSkill")) or 0 for rank in ranks if isinstance(rank, dict)), default=0) or None
        trainer_rows = first_data.get("trainers") if isinstance(first_data.get("trainers"), list) else []
        trainers = []
        for trainer in trainer_rows:
            if not isinstance(trainer, dict):
                continue
            seen = trainer.get("seenInForever")
            place_seen = trainer.get("placeSeenInForever")
            trainers.append({
                "npc_id": _int_or_none(trainer.get("npcId")),
                "name": trainer.get("name"),
                "title": trainer.get("title"),
                "faction": trainer.get("side"),
                "zone": trainer.get("zone"),
                "map_id": _int_or_none(trainer.get("mapId")),
                "x": _number_or_none(trainer.get("x")),
                "y": _number_or_none(trainer.get("y")),
                "trains_up_to_skill": _int_or_none(trainer.get("trainsUpToSkill")),
                "seen_in_forever": seen if isinstance(seen, bool) else None,
                "place_seen_in_forever": place_seen if isinstance(place_seen, bool) else None,
                "entity_evidence": "FOREVER_OBSERVED" if seen is True else _source_evidence(seen),
                "place_evidence": "FOREVER_OBSERVED" if place_seen is True else _source_evidence(place_seen),
                "source_text": trainer.get("source"),
            })
        index_row = index_by_slug[slug]
        professions.append({
            "slug": slug,
            "profession_id": FOREVERDB_PROFESSION_IDS[slug],
            "name": index_row.get("name") or first_data.get("name") or slug,
            "kind": index_row.get("kind"),
            "icon_url": index_row.get("icon"),
            "url": index_row.get("url"),
            "description": index_row.get("description"),
            "skill_cap": skill_cap,
            "ranks": [
                {"rank": row.get("rank"), "max_skill": _int_or_none(row.get("maxSkill")),
                 "spell_id": _int_or_none(row.get("spellId"))}
                for row in ranks if isinstance(row, dict)
            ],
            "trainers": trainers,
            "recipe_count": _int_or_none(index_row.get("recipeCount")),
            "new_in_forever_count": _int_or_none(index_row.get("newInForever")),
            "changed_from_classic_count": _int_or_none(index_row.get("changedFromClassic")),
            "trainer_count": _int_or_none(index_row.get("trainerCount")),
            "trainers_seen_in_forever_count": _int_or_none(index_row.get("trainersSeenInForever")),
            "recipes": recipes,
        })
        total_recipes += len(recipes)

    retrieved = manifest.get("updated_at_utc") or manifest.get("started_at_utc")
    if not isinstance(retrieved, str) or not retrieved:
        raise ImporterError("Capture manifest has no retrieval timestamp")
    return {
        "schema_version": 1,
        "provider": "ForeverDB.net",
        "provider_url": PROVIDER_URL,
        "client_build": build,
        "locale": manifest.get("locale"),
        "retrieved_at_utc": retrieved,
        "attribution_required": True,
        "attribution_text": "Data from ForeverDB.net",
        "provider_notes": sorted(provider_notes),
        "provider_disclaimer": "ForeverDB is not affiliated with Blizzard Entertainment.",
        "provider_meta": {
            "build": provider_meta.get("build"),
            "level_cap": _int_or_none(provider_meta.get("levelCap")),
            "items": _int_or_none(provider_meta.get("items")),
            "spells": _int_or_none(provider_meta.get("spells")),
            "quests": _int_or_none(provider_meta.get("quests")),
            "vendors": _int_or_none(provider_meta.get("vendors")),
            "dungeons": _int_or_none(provider_meta.get("dungeons")),
            "item_sets": _int_or_none(provider_meta.get("itemSets")),
            "articles": _int_or_none(provider_meta.get("articles")),
            "sources": provider_meta.get("sources"),
        },
        "source_capture": {
            "capture_schema_version": manifest.get("capture_schema_version"),
            "started_at_utc": manifest.get("started_at_utc"),
            "updated_at_utc": manifest.get("updated_at_utc"),
            "request_count": manifest.get("request_count"),
            "response_count": len(response_entries),
            "manifest_sha256": sha256(manifest_path.read_bytes()),
        },
        "professions": professions,
        "normalization_summary": {"profession_count": len(professions), "recipe_count": total_recipes},
    }



def json_shape(value: Any, *, depth: int = 0, max_depth: int = 5, path: str = "$", lines: list[str] | None = None) -> list[str]:
    if lines is None:
        lines = []
    pad = "  " * depth
    if isinstance(value, dict):
        keys = list(value.keys())
        lines.append(f"{pad}{path}: object keys={keys[:30]}{' …' if len(keys) > 30 else ''}")
        if depth < max_depth:
            for key, child in list(value.items())[:30]:
                json_shape(child, depth=depth + 1, max_depth=max_depth, path=f"{path}.{key}", lines=lines)
    elif isinstance(value, list):
        lines.append(f"{pad}{path}: array length={len(value)}")
        if depth < max_depth and value:
            json_shape(value[0], depth=depth + 1, max_depth=max_depth, path=f"{path}[0]", lines=lines)
    elif value is None:
        lines.append(f"{pad}{path}: null")
    else:
        sample = repr(value)
        if len(sample) > 120:
            sample = sample[:117] + "…"
        lines.append(f"{pad}{path}: {type(value).__name__} sample={sample}")
    return lines


def inspect_capture(path: Path) -> dict[str, Any]:
    manifest_path = path / "capture-manifest.json"
    if not manifest_path.is_file():
        raise ImporterError(f"capture-manifest.json is missing in {path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    report = {"manifest": manifest, "files": []}
    for entry in manifest.get("responses", []):
        source = path / entry["relative_path"]
        row: dict[str, Any] = {"path": entry["relative_path"]}
        if not source.is_file():
            row["missing"] = True
        else:
            raw = source.read_bytes()
            row["sha256_valid"] = sha256(raw) == entry.get("sha256")
            try:
                parsed = json.loads(raw.decode("utf-8"))
                row["shape"] = json_shape(parsed, max_depth=4)
            except (UnicodeDecodeError, json.JSONDecodeError) as exc:
                row["parse_error"] = str(exc)
        report["files"].append(row)
    return report


def _positive_quantity(value: Any, field: str, errors: list[str], context: str) -> None:
    if value is not None and (isinstance(value, bool) or not isinstance(value, int) or value <= 0):
        errors.append(f"{context}.{field} must be a positive integer or null")


def validate_canonical(data: Any) -> list[str]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return ["root must be an object"]
    if data.get("schema_version") != 1: errors.append("schema_version must equal 1")
    if data.get("provider") != "ForeverDB.net": errors.append("provider must be ForeverDB.net")
    if data.get("provider_url") != PROVIDER_URL: errors.append("provider_url must be https://foreverdb.net")
    if data.get("attribution_required") is not True: errors.append("attribution_required must be true")
    if not isinstance(data.get("client_build"), str) or not data["client_build"].strip(): errors.append("client_build is required")
    if not isinstance(data.get("retrieved_at_utc"), str) or not data["retrieved_at_utc"].strip(): errors.append("retrieved_at_utc is required")
    professions = data.get("professions")
    if not isinstance(professions, list) or not professions:
        errors.append("professions must be a non-empty array")
        return errors
    seen_slugs: set[str] = set()
    for pi, prof in enumerate(professions):
        pc = f"professions[{pi}]"
        if not isinstance(prof, dict): errors.append(f"{pc} must be an object"); continue
        slug = prof.get("slug")
        if not isinstance(slug, str) or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", slug): errors.append(f"{pc}.slug is invalid")
        elif slug in seen_slugs: errors.append(f"duplicate profession slug {slug}")
        seen_slugs.add(slug if isinstance(slug, str) else f"invalid-{pi}")
        if not isinstance(prof.get("name"), str) or not prof["name"].strip(): errors.append(f"{pc}.name is required")
        pid = prof.get("profession_id")
        if isinstance(pid, bool) or not isinstance(pid, int) or pid <= 0: errors.append(f"{pc}.profession_id must be positive integer")
        recipes = prof.get("recipes")
        if not isinstance(recipes, list): errors.append(f"{pc}.recipes must be an array"); continue
        seen_ids: set[int] = set()
        for ri, recipe in enumerate(recipes):
            rc = f"{pc}.recipes[{ri}]"
            if not isinstance(recipe, dict): errors.append(f"{rc} must be an object"); continue
            rid = recipe.get("recipe_id")
            if isinstance(rid, bool) or not isinstance(rid, int) or rid <= 0: errors.append(f"{rc}.recipe_id must be positive integer")
            elif rid in seen_ids: errors.append(f"{rc}: duplicate recipe_id {rid}")
            else: seen_ids.add(rid)
            if not isinstance(recipe.get("name"), str) or not recipe["name"].strip(): errors.append(f"{rc}.name is required")
            if recipe.get("structure_evidence") not in EVIDENCE: errors.append(f"{rc}.structure_evidence is invalid")
            if recipe.get("output_kind") not in {"item", "enchantment", "service", "unknown"}: errors.append(f"{rc}.output_kind is invalid")
            outputs = recipe.get("outputs")
            if not isinstance(outputs, list): errors.append(f"{rc}.outputs must be an array"); outputs = []
            if recipe.get("output_kind") == "item" and not outputs: errors.append(f"{rc}: item output requires output records")
            for oi, out in enumerate(outputs):
                oc = f"{rc}.outputs[{oi}]"
                if not isinstance(out, dict): errors.append(f"{oc} must be an object"); continue
                iid = out.get("item_id")
                if isinstance(iid, bool) or not isinstance(iid, int) or iid <= 0: errors.append(f"{oc}.item_id must be positive integer")
                _positive_quantity(out.get("quantity_min"), "quantity_min", errors, oc)
                _positive_quantity(out.get("quantity_max"), "quantity_max", errors, oc)
                qmin, qmax = out.get("quantity_min"), out.get("quantity_max")
                if qmin is not None and qmax is not None and qmax < qmin: errors.append(f"{oc}: max quantity below min")
                if out.get("quantity_evidence") not in EVIDENCE: errors.append(f"{oc}.quantity_evidence is invalid")
            groups = recipe.get("reagent_groups")
            if not isinstance(groups, list): errors.append(f"{rc}.reagent_groups must be array"); groups = []
            for gi, group in enumerate(groups):
                gc = f"{rc}.reagent_groups[{gi}]"
                if not isinstance(group, dict): errors.append(f"{gc} must be object"); continue
                if not isinstance(group.get("required"), bool): errors.append(f"{gc}.required must be boolean")
                _positive_quantity(group.get("quantity_min"), "quantity_min", errors, gc)
                _positive_quantity(group.get("quantity_max"), "quantity_max", errors, gc)
                qmin, qmax = group.get("quantity_min"), group.get("quantity_max")
                if qmin is not None and qmax is not None and qmax < qmin: errors.append(f"{gc}: max quantity below min")
                if group.get("quantity_evidence") not in EVIDENCE: errors.append(f"{gc}.quantity_evidence is invalid")
                choices = group.get("choices")
                if not isinstance(choices, list): errors.append(f"{gc}.choices must be array"); continue
                for ci, choice in enumerate(choices):
                    cc = f"{gc}.choices[{ci}]"
                    if not isinstance(choice, dict): errors.append(f"{cc} must be object"); continue
                    iid = choice.get("item_id")
                    if isinstance(iid, bool) or not isinstance(iid, int) or iid <= 0: errors.append(f"{cc}.item_id must be positive integer")
            skill = recipe.get("skill", {})
            if not isinstance(skill, dict): errors.append(f"{rc}.skill must be object")
            elif skill.get("threshold_evidence", "UNKNOWN") not in EVIDENCE: errors.append(f"{rc}.skill.threshold_evidence is invalid")
            sources = recipe.get("acquisition_sources", [])
            if not isinstance(sources, list): errors.append(f"{rc}.acquisition_sources must be array"); continue
            for si, source in enumerate(sources):
                sc = f"{rc}.acquisition_sources[{si}]"
                if not isinstance(source, dict): errors.append(f"{sc} must be object"); continue
                if source.get("evidence") not in EVIDENCE: errors.append(f"{sc}.evidence is invalid")
                if source.get("seen_in_forever") not in (True, False, None): errors.append(f"{sc}.seen_in_forever must be true/false/null")
                price = source.get("price_copper")
                if price is not None and (isinstance(price, bool) or not isinstance(price, int) or price < 0): errors.append(f"{sc}.price_copper must be non-negative integer or null")
    return errors


def lua(value: Any, indent: int = 0) -> str:
    pad, child = " " * indent, " " * (indent + 2)
    if value is None: return "nil"
    if value is True: return "true"
    if value is False: return "false"
    if isinstance(value, (int, float)): return repr(value)
    if isinstance(value, str): return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        if not value: return "{}"
        return "{\n" + ",\n".join(child + lua(v, indent + 2) for v in value) + "\n" + pad + "}"
    if isinstance(value, dict):
        if not value: return "{}"
        rows = []
        for key in sorted(value, key=lambda item: str(item)):
            k = f"[{json.dumps(key, ensure_ascii=False)}]" if isinstance(key, str) else f"[{key}]"
            rows.append(f"{child}{k} = {lua(value[key], indent + 2)}")
        return "{\n" + ",\n".join(rows) + "\n" + pad + "}"
    raise ImporterError(f"Unsupported Lua value: {type(value).__name__}")


def compile_canonical(data: dict[str, Any], output: Path, *, allow_fixture: bool = False) -> list[Path]:
    errors = validate_canonical(data)
    if errors: raise ImporterError("Canonical data invalid:\n- " + "\n- ".join(errors))
    if data.get("synthetic_fixture") and not allow_fixture:
        raise ImporterError("Refusing to compile synthetic fixture without --allow-fixture")
    output.mkdir(parents=True, exist_ok=True)
    meta = {"provider": "ForeverDB.net", "providerURL": PROVIDER_URL,
            "creditText": "Data from ForeverDB.net", "clientBuild": data["client_build"],
            "retrievedAtUTC": data["retrieved_at_utc"], "schemaVersion": 1,
            "syntheticFixture": data.get("synthetic_fixture") is True}
    index = dict(meta)
    index["professions"] = [{"slug": p["slug"], "professionID": p["profession_id"], "name": p["name"]} for p in data["professions"]]
    files: list[Path] = []
    index_path = output / "ForeverDBData.lua"
    index_path.write_text(
        "-- Generated data. Do not edit. Visible ForeverDB attribution is required.\n"
        "local MM = _G.ModuloMarket\nif not MM then return end\n"
        "MM.ForeverDBData = MM.ForeverDBData or { professions = {} }\n"
        "MM.ForeverDBData.meta = " + lua(index) + "\n", encoding="utf-8")
    files.append(index_path)
    for prof in data["professions"]:
        payload = {"slug": prof["slug"], "professionID": prof["profession_id"],
                   "name": prof["name"], "skillCap": prof.get("skill_cap"), "recipes": prof["recipes"]}
        path = output / f"ForeverDBData-{prof['slug']}.lua"
        path.write_text(
            "-- Generated data. Do not edit. Source: ForeverDB.net.\n"
            "local MM = _G.ModuloMarket\nif not MM then return end\n"
            "MM.ForeverDBData = MM.ForeverDBData or { professions = {} }\n"
            f"MM.ForeverDBData.professions[{json.dumps(prof['slug'])}] = " + lua(payload) + "\n",
            encoding="utf-8")
        files.append(path)
    return files




def lua_compact(value: Any) -> str:
    if value is None: return "nil"
    if value is True: return "true"
    if value is False: return "false"
    if isinstance(value, (int, float)): return repr(value)
    if isinstance(value, str): return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    if isinstance(value, list):
        return "{" + ",".join(lua_compact(v) for v in value) + "}"
    if isinstance(value, dict):
        return "{" + ",".join(
            (f"[{json.dumps(key, ensure_ascii=False)}]=" if isinstance(key, str) else f"[{key}]=")
            + lua_compact(value[key])
            for key in sorted(value, key=lambda item: str(item))
        ) + "}"
    raise ImporterError(f"Unsupported Lua value: {type(value).__name__}")


def compile_runtime(data: dict[str, Any], output: Path, *, allow_fixture: bool = False) -> Path:
    errors = validate_canonical(data)
    if errors:
        raise ImporterError("Canonical data invalid:\n- " + "\n- ".join(errors))
    if data.get("synthetic_fixture") and not allow_fixture:
        raise ImporterError("Refusing to compile synthetic fixture without --allow-fixture")

    professions: dict[str, Any] = {}
    for prof in data["professions"]:
        compact_recipes = []
        for recipe in prof["recipes"]:
            sources = recipe.get("acquisition_sources", [])
            observed = sorted({s.get("type") for s in sources if s.get("evidence") == "FOREVER_OBSERVED" and s.get("type")})
            borrowed = sorted({s.get("type") for s in sources if s.get("evidence") == "CLASSIC_BORROWED" and s.get("type")})
            automatic = any(s.get("type") == "automatic" and s.get("evidence") == "FOREVER_CLIENT" for s in sources)
            output_rows = [
                {"id": o["item_id"], "name": o.get("name"),
                 "min": o.get("quantity_min"), "max": o.get("quantity_max")}
                for o in recipe.get("outputs", [])
            ]
            reagent_rows = []
            for group in recipe.get("reagent_groups", []):
                reagent_rows.append({
                    "required": group.get("required", True),
                    "min": group.get("quantity_min"),
                    "max": group.get("quantity_max"),
                    "choices": [
                        {"id": c["item_id"], "name": c.get("name")}
                        for c in group.get("choices", [])
                    ],
                })
            skill = recipe.get("skill", {})
            # Preserve the normalized, field-level acquisition evidence for the
            # in-game inspector. Do not collapse mixed observed/borrowed/unknown
            # routes into one recipe-wide status or infer confidence from provider.
            acquisition_sources = []
            source_fields = (
                "type", "name", "faction", "npc_id", "title", "zone", "map_id",
                "x", "y", "price_copper", "price_per_item_copper", "stack_size",
                "costs", "limited_stock", "limited_stock_count",
                "not_on_list_players_saw", "reputation_faction", "seen_in_forever",
                "inferred", "entity_evidence", "evidence", "source_text",
                "chance_percent", "quest_id", "in_forever_client", "url",
                "item_id", "visibility",
            )
            for source in sources:
                if not isinstance(source, dict):
                    continue
                compact_source = {key: source[key] for key in source_fields if key in source}
                if compact_source.get("type"):
                    acquisition_sources.append(compact_source)
            provider_metadata = recipe.get("provider_metadata", {})
            compact_recipes.append({
                "id": recipe["recipe_id"],
                "name": recipe["name"],
                "kind": recipe.get("output_kind"),
                "outputs": output_rows,
                "reagents": reagent_rows,
                "reagentDataAvailable": provider_metadata.get("reagent_data_available") is True,
                "automatic": automatic,
                "sourceKnown": bool(observed or automatic),
                "borrowedSources": bool(borrowed and not (observed or automatic)),
                "sourceUnknown": not bool(borrowed or observed or automatic),
                "acquisitionSources": acquisition_sources,
                "trainerCostCopper": provider_metadata.get("trainer_cost_copper"),
                "trainerCostEvidence": provider_metadata.get("trainer_cost_evidence"),
                "speculative": provider_metadata.get("speculation") is True,
            })
        professions[prof["slug"]] = {
            "professionID": prof["profession_id"],
            "name": prof["name"],
            "skillCap": prof.get("skill_cap"),
            "recipes": compact_recipes,
        }

    payload = {
        "meta": {
            "provider": data["provider"],
            "providerURL": data["provider_url"],
            "creditText": data.get("attribution_text") or "Data from ForeverDB.net",
            "clientBuild": data["client_build"],
            "retrievedAtUTC": data["retrieved_at_utc"],
            "schemaVersion": data["schema_version"],
            "sourceCapture": data.get("source_capture", {}),
        },
        "professions": professions,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        "-- Generated ForeverDB runtime data. Do not edit.\n"
        "-- Visible attribution is required wherever this data is displayed.\n"
        "local MM = _G.ModuloMarket\nif not MM then return end\n"
        "MM.ForeverDBData = " + lua_compact(payload) + "\n",
        encoding="utf-8",
    )
    return output


def cmd_capture(args: argparse.Namespace) -> int:
    key = os.environ.get(args.api_key_env, "")
    if not key:
        raise ImporterError(f"Set {args.api_key_env}; API keys are not accepted as CLI arguments or saved.")
    out = Path(args.output).expanduser().resolve()
    if out.exists() and any(out.iterdir()): raise ImporterError(f"Output must be a new/empty directory: {out}")
    client = ForeverDBClient(key, delay=args.delay, timeout=args.timeout)
    manifest = capture(client, out, page_size=args.page_size, max_pages=args.max_pages, max_requests=args.max_requests)
    print(f"Raw capture: {out}\nClient build: {manifest.get('client_build') or 'UNKNOWN'}\nProfessions: {len(manifest['profession_slugs'])}\nRequests: {manifest['request_count']}\nStatus: RAW CAPTURE ONLY — schema review required")
    return 0


def cmd_inspect(args: argparse.Namespace) -> int:
    path = Path(args.capture).expanduser().resolve()
    manifest = json.loads((path / "capture-manifest.json").read_text(encoding="utf-8"))
    print(f"ForeverDB capture · build {manifest.get('client_build') or 'UNKNOWN'} · {manifest.get('request_count')} requests")
    for entry in manifest.get("responses", []):
        file = path / entry["relative_path"]
        raw = file.read_bytes()
        print(f"\n--- {entry['relative_path']} · sha256={'PASS' if sha256(raw)==entry['sha256'] else 'FAIL'} ---")
        for line in json_shape(json.loads(raw.decode("utf-8")), max_depth=4): print(line)
    return 0


def cmd_normalize_capture(args: argparse.Namespace) -> int:
    data = normalize_capture(Path(args.capture).expanduser().resolve())
    errors = validate_canonical(data)
    if errors:
        raise ImporterError("Normalized data failed canonical validation:\\n- " + "\\n- ".join(errors))
    output = Path(args.output).expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    recipes = [r for p in data["professions"] for r in p["recipes"]]
    item_outputs = sum(r["output_kind"] == "item" for r in recipes)
    non_item = sum(r["output_kind"] != "item" for r in recipes)
    speculative = sum(r["provider_metadata"]["speculation"] for r in recipes)
    print(f"Normalized and validated {len(recipes)} recipes across {len(data['professions'])} professions.")
    print(f"Item outputs: {item_outputs}; non-item/unknown: {non_item}; speculative records retained: {speculative}")
    print(f"Client build: {data['client_build']} · output: {output}")
    return 0


def cmd_validate(args: argparse.Namespace) -> int:
    data = json.loads(Path(args.input).read_text(encoding="utf-8"))
    errors = validate_canonical(data)
    if errors:
        print("INVALID:\n" + "\n".join("- " + item for item in errors)); return 2
    recipes = [r for p in data["professions"] for r in p["recipes"]]
    outputs = [o for r in recipes for o in r.get("outputs", [])]
    known = sum(o.get("quantity_min") is not None and o.get("quantity_max") is not None for o in outputs)
    ranged = sum(o.get("quantity_min") is not None and o.get("quantity_max") is not None and o["quantity_min"] != o["quantity_max"] for o in outputs)
    unknown = len(outputs) - known
    print(f"VALID · {len(data['professions'])} professions · {len(recipes)} recipes · output records: {len(outputs)} (known {known}, ranges {ranged}, unknown {unknown})")
    if data.get("synthetic_fixture"): print("WARNING: synthetic fixture, not real game data")
    return 0


def cmd_compile_runtime(args: argparse.Namespace) -> int:
    data = json.loads(Path(args.input).read_text(encoding="utf-8"))
    output = compile_runtime(data, Path(args.output).expanduser().resolve(), allow_fixture=args.allow_fixture)
    print(f"Generated compact addon runtime data: {output} ({output.stat().st_size} bytes).")
    if data.get("synthetic_fixture"): print("WARNING: test-only output; do not ship")
    return 0


def cmd_compile(args: argparse.Namespace) -> int:
    data = json.loads(Path(args.input).read_text(encoding="utf-8"))
    files = compile_canonical(data, Path(args.output).expanduser().resolve(), allow_fixture=args.allow_fixture)
    print(f"Generated {len(files)} Lua files. Attribution metadata included.")
    if data.get("synthetic_fixture"): print("WARNING: test-only output; do not ship")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="ForeverDB raw capture and validated offline recipe-data compiler")
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("capture", help="Capture read-only API responses; requires approved API key")
    p.add_argument("--output", required=True)
    p.add_argument("--api-key-env", default="FOREVERDB_API_KEY")
    p.add_argument("--page-size", type=int, default=100)
    p.add_argument("--max-pages", type=int, default=100)
    p.add_argument("--max-requests", type=int, default=500)
    p.add_argument("--delay", type=float, default=MIN_INTERVAL)
    p.add_argument("--timeout", type=float, default=30.0)
    p.set_defaults(func=cmd_capture)
    p = sub.add_parser("inspect", help="Inspect exact raw response shapes and response hashes")
    p.add_argument("capture")
    p.set_defaults(func=cmd_inspect)
    p = sub.add_parser("normalize-capture", help="Normalize a verified raw ForeverDB capture into canonical v1 JSON")
    p.add_argument("capture")
    p.add_argument("--output", required=True)
    p.set_defaults(func=cmd_normalize_capture)
    p = sub.add_parser("validate", help="Validate canonical staging JSON")
    p.add_argument("input")
    p.set_defaults(func=cmd_validate)
    p = sub.add_parser("compile-runtime", help="Compile compact build-gated addon runtime data")
    p.add_argument("input")
    p.add_argument("--output", required=True)
    p.add_argument("--allow-fixture", action="store_true")
    p.set_defaults(func=cmd_compile_runtime)
    p = sub.add_parser("compile", help="Compile validated canonical JSON into per-profession Lua modules")
    p.add_argument("input")
    p.add_argument("--output", required=True)
    p.add_argument("--allow-fixture", action="store_true")
    p.set_defaults(func=cmd_compile)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return int(args.func(args))
    except (ImporterError, OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
