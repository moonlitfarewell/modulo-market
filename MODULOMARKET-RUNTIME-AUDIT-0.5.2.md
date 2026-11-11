# Modulo Market Runtime Audit 0.5.2 — reagent-key edge fix and ForeverDB importer preparation

**Date:** 2026-11-11  
**Addon:** ModuloMarket 0.5.2  
**Developer tool:** ForeverDB importer preview 0.1.0  
**Parent:** MODULO 1.0.48 (unchanged)  
**Disposition:** source correction and offline importer tooling PASS; ForeverDB approval/raw capture and Forever runtime acceptance NOT RUN.

## 1. Player problem and observable result

The immediate project blocker is recipe completeness: some recipe candidates have unknown output quantities and must not receive invented profit values. ForeverDB access was requested by the user and is awaiting review. The work that can safely proceed before approval is an offline importer that captures exact API responses after approval, inspects the actual schema, validates a provenance-preserving canonical recipe model and compiles only reviewed records.

During regression validation of the current source, the legacy `profession_data_0_4_0_harness.lua` also exposed an edge case in `ProfessionData.NormalizeLibraryReagents`: scalar `itemID -> quantity` maps rejected item IDs `<= 100` as if they were array positions. The final parser accepts sparse positive numeric keys as item IDs, while explicitly detecting contiguous numeric-key scalar arrays so their indexes are not mistaken for item IDs. The harness uses item ID 100 and proved that it was lost from a profession's reagent/material relationship.

0.5.2 delivers:
- the narrow scalar-map parser correction;
- version agreement at Core, TOC and manifest 0.5.2;
- an offline ForeverDB raw-capture, schema-inspection, canonical validation and Lua compilation developer tool;
- no API key, raw API response, or third-party recipe dataset bundled.

## 2. Source of truth and artifacts available

### Child baseline
- Previous released child: `ModuloMarket-0.5.1.zip`, 217,308 bytes, SHA-256 `bb01b6373e3cb174d5c62453da2c0b7899efd90a997be9fec4c1924ada98aeab`, ZIP CRC PASS.
- Current public repository: `https://github.com/moonlitfarewell/modulo-market`, previously verified public with 0.5.1 source on `main`. The update in this audit is prepared locally; it has not yet been committed/pushed by the user.

### Parent
- `MODULO-Project-Source-1.0.48.zip`, 41,236,015 bytes, SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`, ZIP CRC PASS.
- Parent remains 1.0.48 and is unchanged. Market remains a separate optional child; Market depends on MODULO, MODULO does not depend on Market.

### Files inspected
- Current 0.5.1 child source, manifest, TOC, README and 0.5.1 audit.
- `RecipeEngine.lua` and `ProfessionData.lua` recipe capture/canonicalization call sites.
- Existing Python regression tests and Lua harnesses, including `profession_data_0_4_0_harness.lua`.
- MODULO parent project start, README, workflow, progress, decisions, QA, source-review ledger, architecture and Forever compatibility contract.
- ForeverDB public developer documentation: `https://foreverdb.net/developers`.
- ForeverTome public recipe archive page: `https://forevertome.com/professions`.

No ForeverDB API key or actual API response sample is available because developer access is still pending.

## 3. Exact evidence and counter-evidence

### A. Scalar reagent key edge case

**Evidence:** before the patch, `profession_data_0_4_0_harness.lua` failed its assertion that a profession filter includes the known future-recipe reagent at item ID 100.

**Competing hypotheses:**
1. The 0.4.0 harness fixture was using a reagent structure that the current library adapter no longer supports.
2. The scalar itemID-to-quantity branch incorrectly rejects an otherwise valid positive item ID because its `numericKey > 100` heuristic treats lower keys as array indexes.

**Diagnostic:** inspect `NormalizeLibraryReagents` scalar-value branch and call it with `{ [100] = 2 }`. The current source explicitly selected no item ID because 100 is not greater than 100. The harness reproduces that exact path.

**Finding:** hypothesis 2 is confirmed by source and the failing assertion. The table-record branch still requires an explicit `itemID` or an unambiguous high numeric map key to avoid interpreting array indexes as IDs. The scalar map branch now accepts sparse positive numeric keys (including 100), but first detects contiguous 1-based numeric-key arrays and leaves those indexes uninterpreted.

**Change:** scalar map keys are accepted when positive and the table is not a contiguous 1-based numeric array. The previously failing profession data harness now passes and includes a regression check that positional scalar arrays do not create item IDs 1 and 2.

### B. ForeverDB availability and schema

Official documentation states:
- read-only API with API key;
- responses use `{data, meta}`;
- metadata identifies the game build and list pagination;
- `/professions` lists the supported profession set;
- `/professions/{slug}` includes recipe skill colours, reagents, output count/min/max, how learned, trainer/vendor sources, faction/price details and Forever observation status;
- rate limits are 60 requests/minute and 10,000/day;
- visible credit to `https://foreverdb.net` is required wherever the data is shown; data must not be resold or presented as our own.

**Counter-evidence/gap:** public documentation does not provide enough complete nested response examples to implement an exact raw-response mapper without seeing a real approved response. Approval is pending. No request has been sent using an API key.

### C. ForeverTome fallback

The public ForeverTome page advertises 2,561 decoded recipes in build `1.60.1.70707`, with output ranges and reagents. Its own notes state that retained client records do not prove live learnability; client minimum skill is not a verified trainer requirement; output quantities are base client effect ranges; no hotfixes are applied; acquisition sources are not confirmed by that dataset.

The user's prior client evidence is build `1.60.1.70862`. The 70707 archive is therefore not a current-build substitute. A redistribution licence for the downloaded snapshot has not been verified, so it is not included or compiled.

## 4. Developer tooling implementation 0.1.0

New directory: `tools/foreverdb_importer/`.

### Raw capture
- Uses Python standard library only (Python 3.10+).
- Reads API key from `FOREVERDB_API_KEY` environment variable; it is never accepted in a command argument, written to the capture manifest or printed.
- Sends read-only GET requests with `X-API-Key`.
- Sequential requests with minimum 1.05-second delay.
- Enforces `limit <= 100` and default 500-request capture cap, below the API's documented 10,000/day limit.
- Handles 429 `Retry-After` and transient 5xx/network errors.
- Saves exact raw JSON response bytes, path, capture timestamp, SHA-256 and byte count.
- Writes an IN_PROGRESS/PARTIAL manifest during capture so previously downloaded responses remain inspectable after interruption.
- Automatically paginates only explicitly identified recipe arrays with a reported total. Rank/skill-wrapped responses are preserved and marked pagination-shape-unknown rather than guessed.

### Schema inspection
- Reads the capture manifest.
- Verifies each saved response hash.
- Prints nested object keys, arrays/counts and sample types.
- Does not normalize raw responses or infer API field paths.

### Canonical recipe contract
- `recipe-data-v1.schema.json` is Modulo Market's staging contract, **not** a claim about ForeverDB's raw response schema.
- Preserves profession and recipe IDs, multiple item outputs, output quantity min/max/evidence, required/optional reagent groups, quantities and alternate choices, skill threshold evidence, acquisition sources, faction and prices.
- Field evidence remains distinct: `FOREVER_CLIENT`, `FOREVER_OBSERVED`, `CLASSIC_BORROWED`, `FOREVERTOME_CLIENT_ARCHIVE`, `LIBPROFESSIONDB`, `UNKNOWN`.
- Unknown quantity stays null. Variable ranges stay ranges. A recipe with no item output is not converted into a fake item craft.

### Compiler
- Validates canonical data, required ForeverDB provider/attribution metadata, IDs, duplicate profession recipe IDs, positive quantities/ranges and evidence enums.
- Emits one generated Lua file per profession plus an index.
- Generated index includes the visible credit string `Data from ForeverDB.net` and URL `https://foreverdb.net`.
- Synthetic fixture is explicitly flagged and cannot compile without `--allow-fixture`; generated fixture files are tests only and must never be shipped.
- Generated files are build outputs and are not added to the addon's TOC by this developer-tool preview.

## 5. Dependencies, security and boundaries

- No new WoW addon runtime dependency.
- No live Internet request from the addon.
- No API key, developer ID or raw ForeverDB response in repository.
- Raw imports, outputs, build directories, Python cache and environment secrets are git-ignored.
- Auctionator and ProfessionMaster are not dependencies; private data is not read.
- MODULO 1.0.48 unchanged.
- ForeverDB attribution and no-resale terms are documented. The visible in-game attribution component is not yet implemented because no ForeverDB data is bundled.

## 6. Automated validation

### Python
- `python -m pytest -q -p no:cacheprovider tests` — **118 passed** (after updating current version expectations and correcting the source inventory manifest).
- New importer tests — **9 passed**, included in the 118 total. They cover fixed/variable/unknown quantities, validation failures, duplicate IDs, fixture compiler guard, attribution metadata, API-key non-persistence, raw capture, pagination, opaque response preservation, rate-limit pacing and raw response hash validation.

### Lua and generated outputs
- `texluac -p` on the eight addon Lua source files — **PASS**.
- `texluac -p` on synthetic generated index and per-profession Lua modules — **PASS**.
- `texlua tests/recipe_engine_0_3_0_harness.lua AddOns/ModuloMarket/RecipeEngine.lua` — **PASS**.
- `texlua tests/profession_data_0_4_0_harness.lua AddOns/ModuloMarket/ProfessionData.lua` — **PASS** after the scalar-key correction.
- `texlua tests/market_ui_0_5_0_harness.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**.
- `texlua tests/market_ui_0_4_2_harness.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS** after aligning its expectations to the current role labels and All Crafts tab.
- `texlua tests/market_ui_0_2_0_harness.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS** after updating its historical expectations for the 25-row pool, current role labels, All Crafts replacement and role-adjusted low-supply behavior.
- `texlua tests/market_engine_0_1_0_harness.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Replicate.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**.
- `texluac -p` across all eight addon Lua files — **PASS**.
- The older `market_ui_0_4_1_harness.lua` was not run because it still mocks the removed Blizzard `UIDropDownMenuTemplate` path; actual current popup interaction is covered by the 0.4.2 and 0.5.0 harnesses.

These are source/offline model checks, not Forever runtime acceptance.

## 7. Version and package

- `Core.lua`: 0.5.2.
- `ModuloMarket.toc`: 0.5.2.
- `MANIFEST.json`: 0.5.2; full repository file inventory includes the manifest itself.
- Parent MODULO: 1.0.48 unchanged.
- Developer tool: 0.1.0; separate from addon version.

## 8. Player/runtime acceptance and remaining gaps

**NOT RUN / UNKNOWN:**
- ForeverDB API access approval.
- Actual API capture with an issued key.
- Exact raw API schema and pagination semantics for rank/skill-wrapped profession responses.
- Mapping raw API fields to canonical schema.
- Current-build recipe/output yield reconciliation against the player's 1.60.1.70862 client.
- Full Forever client runtime of the 0.5.2 addon source (the scalar key bug fix is offline-tested only).
- Generated dataset integration/loader and visible attribution UI.
- Complete profession recipe coverage, live acquisition availability and current trainer prices.

The next action after access approval is to run one small read-only capture, inspect the exact response, then implement and test the provider adapter. Do not create a complete recipe dataset from the synthetic fixture or the stale 70707 archive.
