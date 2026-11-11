# ForeverDB integration plan and current implementation status

**Addon baseline:** ModuloMarket 0.5.2 (developer importer preview 0.1.0 plus scalar reagent-key fix)  
**Parent:** MODULO 1.0.48 (unchanged)  
**Status:** offline importer foundation implemented and tested; ForeverDB API approval pending; raw response schema adapter NOT RUN/UNKNOWN.

## Player problem

Market currently has known recipes captured from the player's profession windows and an optional structural unlearned-recipe source. It still lacks a complete, authoritative Forever-specific recipe dataset for all professions, including correct output ranges and actual learning sources. Some recipes therefore show `output quantity unavailable`, and profit must be withheld rather than guessed.

## Ownership and dependency direction

- ModuloMarket owns recipe economics, provenance, market joins and player presentation.
- MODULO remains unchanged and must not depend on Market.
- Auctionator and ProfessionMaster remain independent; Market reads neither private SavedVariables nor private runtime services.
- ForeverDB is a build-time data source only. The addon will not make HTTP requests and will not contain an API key.

## Current source evidence

### ForeverDB API

Official API documentation: https://foreverdb.net/developers

The documented API is read-only and requires an approved API key. Responses have a `{data, meta}` envelope; metadata identifies the game build and pagination information. Documented limits are 60 requests/minute and 10,000 requests/day per key. Keys are account-bound, and the API requires visible credit linking to https://foreverdb.net wherever its data is displayed. It prohibits reselling the data or presenting it as our own.

The profession index documents 12 profession slugs. A profession detail includes recipes, skill colours, reagents, output count/min/max, learning sources, faction-specific trainers/vendors and vendor costs. It distinguishes client-derived recipe structure from learning sources and trainer/vendor prices that are Classic-derived unless `seenInForever`/observation evidence is present.

### ForeverTome (secondary structural reference only)

Public recipe archive: https://forevertome.com/professions

The site currently advertises 2,561 decoded client recipes across 15 professions from client build `1.60.1.70707`. Its own caveats are important: retained historical client recipes do not prove live availability; output counts are base client effect ranges; no hotfixes are applied; client minimum skill is not a verified trainer learning requirement; and trainer/vendor/drop/quest acquisition sources are not confirmed by that snapshot. The user's previously observed client build is `1.60.1.70862`, so `1.60.1.70707` must not be silently treated as current. A redistribution licence for that public JSON download has not been verified; do not bundle or redistribute it on the basis of being downloadable.

### Existing LibProfessionDB fallback

LibProfessionDB 1.9.1 remains an optional structural fallback. Its Forever-specific data and Classic-borrowed acquisition/skill fields must remain individually labelled. It is not a required runtime dependency and is not bundled by this tool preview.

## Evidence model

Evidence is retained per field/claim, not inferred from the provider name:

- `FOREVER_CLIENT`: decoded from a named Forever client build. Recipe presence alone does not prove live learnability.
- `FOREVER_OBSERVED`: a source or behavior observed by players on Forever, where the provider says it was seen.
- `CLASSIC_BORROWED`: Classic/Vanilla-derived; not confirmed on Forever.
- `FOREVERTOME_CLIENT_ARCHIVE`: client-archive data from that source/build; source and build are retained.
- `LIBPROFESSIONDB`: data from that library; field-level borrowed status remains explicit.
- `UNKNOWN`: not established.

Client trivial/colour thresholds, trainer learning requirements and actual character learning are separate concepts. Do not label a client orange/yellow skill threshold as a trainer requirement. Do not make a future craft available solely because a client recipe exists.

## Implemented developer tooling preview 0.1.0

Location: `tools/foreverdb_importer/`

- Standard-library Python 3.10+ tooling; no extra packages.
- Sequential raw API capture using `X-API-Key` from `FOREVERDB_API_KEY` environment variable only.
- Secret is never accepted on the command line, printed, or written to the capture manifest.
- Minimum 1.05-second interval between requests; 500 request capture safety cap; API's maximum 100 rows/page is enforced; HTTP 429 `Retry-After` handling.
- Raw response JSON is preserved with request path, timestamp, byte count and SHA-256. An in-progress/partial manifest survives an interrupted capture.
- JSON response-shape inspector verifies the raw file hashes and prints nested keys/types/array lengths.
- Canonical staging schema v1 separates output records, output quantity min/max, reagent groups/alternatives, skill evidence and acquisition-source evidence.
- Strict validation and per-profession Lua compiler. Generated index includes the required ForeverDB visible attribution text and URL.
- Synthetic test fixture proves fixed, variable and unknown output quantities are preserved. Fixture compilation requires an explicit `--allow-fixture` flag and must never be shipped.
- Offline tests cover environment-only API key use, raw-response capture, hashes, explicit pagination, unknown nested-page preservation, validator failures, duplicate IDs and compiler attribution.

The raw ForeverDB response adapter has deliberately NOT been implemented before API approval and a real response sample. The public documentation is sufficient to plan endpoints and evidence rules but not to safely assume every nested JSON field/path. This is a correctness gate, not unfinished guesswork.

## Canonical recipe data contract

See `tools/foreverdb_importer/recipe-data-v1.schema.json`.

Each recipe retains:
- stable profession/recipe IDs and name/category;
- one or more output item records;
- each output quantity's `min`, `max` and evidence;
- required/optional reagent groups, quantity min/max, quantity evidence and alternative item choices;
- skill threshold values with independent evidence source;
- acquisition source type, name, faction, price, `seen_in_forever` and evidence;
- exact source client build and retrieval timestamp.

Missing quantity remains `null`. Random quantities remain a range; no expected value is invented without a documented distribution. Non-item outputs (enchantments/services) are not forced into fake item outputs. Variable/optional/alternative reagent semantics are preserved instead of flattening all entries into a sum.

For a variable output, economics should report a conservative-to-maximum profit range where all required prices are known. For unknown output quantity, profit remains unavailable. Reagent alternatives are a choice group; only the chosen available alternative is costed. If some alternatives are unpriced, report price coverage/uncertainty rather than claiming the chosen option is the cheapest possible.

## Capture workflow after access is approved

1. Create an API key in the approved ForeverDB account; do not send it to ChatGPT or commit it.
2. Set it temporarily in the shell environment, then run the importer `capture` command (see tooling README).
3. Review `capture-manifest.json`, client build, each response shape and SHA-256 using `inspect`.
4. Implement/update a raw-schema adapter only against the captured shape and the official API docs. Record every mapped field path and its evidence translation.
5. Normalize to canonical v1; validate IDs, quantities, alternatives, outputs, skills, source evidence and build metadata.
6. Compare a sample of recipes/materials against the live Forever profession UI and the client's captured known recipe schematic. Keep disagreements open; never silently choose an answer.
7. Compile per-profession Lua data. Ensure attribution is visible in the in-game UI before any release includes ForeverDB data.
8. Run offline tests and source-review the changed loader/UI/economics callers. Package only after the data is validated.

## Compatibility and build gate

Do not merge datasets across client builds. Every captured set records its exact client build and locale. Before joining recipe data to an auction snapshot, compare recipe-data build to the client build recorded by the user's Market scan. A stale build remains separately labelled and cannot silently override current client-captured data.

The previously observed client evidence refers to `1.60.1.70862`; the currently published ForeverTome archive search result refers to `1.60.1.70707`. They are not interchangeable.

## Not yet implemented / blockers

- ForeverDB access approval and issued key: PENDING.
- Actual ForeverDB API response capture: NOT RUN (awaiting access approval/key).
- Exact raw API schema adapter: NOT RUN/UNKNOWN until a real response is available.
- ForeverDB canonical dataset compiled from approved API responses: NOT RUN.
- Generated Lua connected to addon loader/UI: NOT IMPLEMENTED.
- Visible in-game ForeverDB attribution: NOT IMPLEMENTED; required before shipping any ForeverDB-sourced records.
- Live Forever runtime verification of imported data and recipe economics: NOT RUN.

Do not claim ForeverDB import or Forever recipe completeness until these gates pass.


---

## 2026-11-11 — approved ForeverDB capture reviewed; first integration slice implemented

**Supersedes the pending-access/raw-adapter status above for the 0.5.3 baseline.** The historical 0.5.2 audit remains unchanged.

### Evidence received

The user supplied `capture-20261111-122719.zip` after running the Windows importer with Python installed. The capture is COMPLETE for client build `1.60.1.70862`: 34 responses, all hashes/byte counts valid, 12 profession slugs, 2,493 recipe records. Each profession's actual nested `data.recipes` count matches its manifest total. The exact response shape is now known and recorded in `docs/FOREVERDB-DATA-REVIEW-2026-11-11.md`.

### Implemented in 0.5.3

- `normalize-capture` verifies the raw capture and maps the observed ForeverDB schema into canonical v1.
- `compile-runtime` emits a compact `ForeverDBData.lua` for the current addon data consumer.
- The canonical JSON and original raw capture ZIP are retained under `data/`.
- `ProfessionData.lua` prefers the bundled ForeverDB catalogue when present and only loads it when `GetBuildInfo()` exactly matches the dataset build; Market also requires the saved auction snapshot's `clientVersion.clientBuild` to match the current client before joining its prices to recipe data.
- Learned recipes are de-duplicated; speculative recipes and non-item outputs are excluded from item craft economics.
- Observed/automatic, Classic-borrowed and unknown acquisition sources remain distinct.
- The existing optional LibProfessionDB path remains only when no ForeverDB dataset is bundled; a present but mismatched ForeverDB dataset is blocked rather than silently substituted.
- Market UI displays the required ForeverDB credit and source/build counts.

### Mapping limits

The capture exposes `makes.count`, not separate output min/max values, and reagent arrays have no optional/alternative flags. No random yield ranges or reagent alternatives are inferred. Drop and quest rows lack per-row Forever observation evidence in this capture and remain UNKNOWN. Trainer/vendor rows retain their own `seenInForever` distinction. Orange skill thresholds remain separate from trainer learning requirements.

### Acceptance still open

Offline source/harness tests do not prove target-client behavior. Forever 1.60.1.70862 runtime acceptance remains NOT RUN. The user must verify addon load, exact build detection, recipe/material indexing, known-recipe de-duplication, source-status presentation, profitability withholding for incomplete data and visible attribution in the actual client. Full trainer/vendor source presentation and runtime memory/load impact remain future work.


---

## 2026-11-11 — 0.5.4 client-build update review and safety decision

The user's Forever client reports `GetBuildInfo() = 1.60.1, 70888, Nov 9 2026, 16001`. The bundled canonical capture and generated runtime data remain from `1.60.1.70862`.

### External comparison evidence

- The Forever client-build comparison for `70862 → 70888` reports no profession-table changes in the client files: https://theforeverera.com/en/builds/70862-70888/
- Separate November 10 server hotfix reporting identifies profession-related changes, including Coarse Grinding Stone skill-up range, Journeyman Campfire Kit placement requirement, Minor Arcane Elixir sell price and Iron Grenade vendor price: https://allthings.how/wow-forever-hotfixes-patch-notes/
- Therefore, unchanged client profession records do not establish unchanged server-side profession behavior or acquisition/economic metadata.

### Decision

Do not relax the exact-build gate and do not relabel the `70862` capture as `70888`. Keep imported recipes blocked on `70888` until a fresh ForeverDB capture is obtained, inspected, normalized and compared. A fresh capture requires the user's approved ForeverDB API key in the local `FOREVERDB_API_KEY` environment variable; no key is included in the supplied files or addon. The key must not be sent in chat or committed.

### 0.5.4 capability delivered

- Login announces `ModuloMarket v0.5.4` and the detected client version/build.
- `/mmversion` reports addon version, client version/build and ForeverDB dataset build/load state.
- Market footer shows the addon version and client build.
- Existing exact-build dataset gate and auction-snapshot compatibility gate are retained.

### Acceptance state

- Offline tests and Lua syntax checks: recorded in the 0.5.4 standalone audit.
- Forever client runtime verification of the new announcement/footer/command: NOT RUN; requires player retest.
- Fresh ForeverDB capture for `70888`: NOT RUN; blocked on API key availability and capture.
- Server-hotfix parity for all 2,493 recipe/source/economic rows: UNKNOWN until fresh capture and sample comparison.
