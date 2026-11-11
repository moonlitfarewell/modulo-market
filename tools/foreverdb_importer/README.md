# Modulo Market ForeverDB importer (developer tool preview 0.1.0)

This is a **developer-side, offline-first tool**. It is not loaded by WoW and does not load in WoW. The current addon source baseline is ModuloMarket 0.5.2.

It prepares the approved ForeverDB API workflow without assuming the response schema before we can inspect a real approved response. The first stage captures and archives raw read-only API responses. The next stage validates a provider-reviewed canonical dataset and can compile that dataset to Lua files for a later addon release.

## Why the importer is split into stages

ForeverDB documents an envelope of `{ data, meta }`, a `/meta` endpoint, a profession index, and `/professions/{slug}` recipe data. The profession endpoint exposes recipe outputs (including min/max for variable yields), reagents, skill colours, acquisition sources, faction-specific vendors/trainers, price data and `seenInForever` evidence. However, its public documentation does not provide a complete example response for every nested recipe/source shape.

Therefore this tool **does not guess the live response mapping**. It archives the raw response, records its hash and build metadata, and provides an inspector. A provider adapter will only be added after we have an approved response sample and have checked every mapped field against its actual JSON shape.

Official documentation: https://foreverdb.net/developers

## Requirements

- Python 3.10 or newer.
- Standard library only; no third-party Python packages are required.
- An approved ForeverDB API key for the `capture` command. The user application is currently pending approval; do not attempt capture until a key has been issued.

## API-key handling

The key is read only from an environment variable (default: `FOREVERDB_API_KEY`). It is never accepted as a command-line argument, written into a capture manifest, or included in request logs. Use a temporary shell environment and unset it afterwards.

### Windows PowerShell

```powershell
$secure = Read-Host "ForeverDB API key" -AsSecureString
$env:FOREVERDB_API_KEY = [System.Net.NetworkCredential]::new("", $secure).Password
python .\tools\foreverdb_importer\market_data_importer.py capture --output .\imports\foreverdb-capture
Remove-Item Env:FOREVERDB_API_KEY
Remove-Variable secure
```

### macOS / Linux shell

```bash
read -s FOREVERDB_API_KEY
export FOREVERDB_API_KEY
python tools/foreverdb_importer/market_data_importer.py capture --output ./imports/foreverdb-capture
unset FOREVERDB_API_KEY
```

Do not paste the key into GitHub, an issue, chat, a screenshot, a command line, a SavedVariables file or the addon. If the key is exposed, revoke it in ForeverDB and create a replacement.

## Capture

```text
python tools/foreverdb_importer/market_data_importer.py capture --output ./imports/foreverdb-capture
```

Safety defaults:

- sequential requests only;
- at least 1.05 seconds between requests (below the documented 60/minute ceiling);
- API page size no greater than 100;
- a 500-request capture safety cap (well below the documented 10,000/day key limit);
- retry handling for transient server errors and `429 Retry-After` responses;
- raw JSON response bytes, SHA-256, request path, capture time and reported client build are archived;
- no API credential is written to disk.

The capture is read-only. It does not touch the game, auction house or SavedVariables.

## Inspect the raw API schema

```text
python tools/foreverdb_importer/market_data_importer.py inspect ./imports/foreverdb-capture
```

This validates response hashes and prints the JSON shape (object keys, array counts and representative value types). It is specifically intended to let us review the actual API response before implementing the provider-to-canonical mapper.

If a profession endpoint returns a rank/skill-wrapped response rather than a direct recipe page, the capture preserves it and marks pagination as schema-unknown. It does not fabricate missing pages or infer recipe structure.

## Canonical recipe data contract

`recipe-data-v1.schema.json` defines our staging format. It is **our internal contract, not ForeverDB's API response schema**. A provider adapter must map real fields into it only after review.

The contract preserves:

- provider URL, exact client build, locale and retrieval timestamp;
- profession and recipe IDs;
- multiple output items;
- output quantity minimum and maximum independently;
- reagent groups, required/optional status, quantities and alternative item choices;
- skill thresholds and their evidence source separately from trainer learning requirements;
- trainer/vendor/quest/drop/auto sources, faction, price and whether players observed the source in Forever;
- field-level evidence labels.

Evidence labels:

- `FOREVER_CLIENT`: structure decoded from a specified Forever client build. This alone does not prove that a recipe can be learned or is live-available.
- `FOREVER_OBSERVED`: a source/behavior observed by players in Forever and reported as such by the provider.
- `CLASSIC_BORROWED`: Classic/Vanilla-derived information; unconfirmed on Forever.
- `FOREVERTOME_CLIENT_ARCHIVE`: client-archive data from ForeverTome, retained as that source and build rather than silently merged.
- `LIBPROFESSIONDB`: data imported from the optional library, with its own per-field provenance retained.
- `UNKNOWN`: not established.

Output quantities and reagent quantities are not defaulted to one. A missing value remains `null`. A variable output remains a min/max range. No expected yield is calculated without a distribution. Multiple outputs remain separate records. A recipe with no item output may be an enchantment or service and must not be treated as a zero-output item craft.

## Validate and compile reviewed canonical data

```text
python tools/foreverdb_importer/market_data_importer.py validate path/to/foreverdb-canonical.json
python tools/foreverdb_importer/market_data_importer.py compile path/to/foreverdb-canonical.json --output ./build/foreverdb-lua
```

The compiler refuses incomplete/invalid metadata and duplicates. It emits one Lua file per profession plus an index. The index includes the required visible credit text and URL: **Data from ForeverDB.net** / `https://foreverdb.net`.

The generated files are **not automatically added to the addon TOC**. They are build artifacts until the recipe adapter, runtime data model, attribution UI and client-build compatibility checks are reviewed and accepted in a later Market capability release.

A synthetic example is included for tests only. The compiler refuses `synthetic_fixture: true` unless `--allow-fixture` is explicitly supplied. Fixture output must never be shipped to players.

## ForeverTome and other fallback sources

ForeverTome currently advertises a downloadable 2,561-recipe client snapshot from build `1.60.1.70707`. Its own notes say client records may include retained historical recipes; presence does not establish live learnability; output ranges are base client effect ranges; no hotfixes are applied; and trainer/vendor/drop/quest learning sources are not confirmed by that dataset. The user's earlier client evidence was build `1.60.1.70862`, so 70707 is not a current-build replacement. No redistribution licence for the downloadable snapshot has been verified here. It is therefore a **schema/reference lead only**, not bundled or compiled by this tool.

ForeverDB remains the primary target because its API explicitly separates client recipe structure from observed Forever acquisition sources and identifies Classic-derived source/price fields. Its terms require visible attribution wherever data is displayed, prohibit resale/presentation as our own, and specify rate limits. These requirements are reflected in the capture defaults and generated metadata.

## Current implementation status

- Implemented: raw API capture client, secret-safe environment key handling, conservative rate limiting, page safety caps, retry handling, raw JSON preservation, response hashes, schema inspector, canonical schema, strict validator, Lua compiler, synthetic fixtures and offline tests.
- Not implemented yet: exact ForeverDB raw-response adapter. It is blocked only on the approved API key and a real response sample; the public documentation does not expose enough nested JSON examples to safely map all fields.
- Not implemented yet: generated data wired into ModuloMarket runtime/UI. That needs a separate addon capability slice, client-build compatibility evidence and visible attribution placement.
- No ForeverDB data, developer ID, account credential or API key is included in this repository.
