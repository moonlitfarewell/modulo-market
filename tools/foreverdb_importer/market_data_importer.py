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
USER_AGENT = "ModuloMarketDataImporter/0.1 (+https://github.com/moonlitfarewell/modulo-market)"
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
    p = sub.add_parser("validate", help="Validate canonical staging JSON")
    p.add_argument("input")
    p.set_defaults(func=cmd_validate)
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
