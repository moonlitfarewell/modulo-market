# Modulo Market 0.12.8 Runtime Audit — Conservative Data Distribution Projection

## Status

**DATA PROJECTION IMPLEMENTED; OFFLINE VALIDATION COMPLETE; FOREVER RUNTIME NOT RUN FOR THIS DATA-ONLY CHANGE.** This slice removes specified uncertain/Classic/speculative data from the distributable catalogue while retaining Forever-client recipe structures and explicitly observed/client acquisition evidence. It does not provide legal clearance for retained third-party data or approve 1.0.0.

## Player problem and observable result

0.12.7 distributed mixed-provenance canonical and runtime data even though the UI labelled Classic-borrowed and unknown acquisition routes. 0.12.8 ships a reproducible filtered projection: 2,350 non-speculative recipe structures and 4,166 acquisition rows (4,133 Forever-observed, 33 Forever-client). Classic-borrowed/unknown acquisition rows, Classic comparison fields, non-observed trainer entries/locations, unobserved prices, unverified skill thresholds and speculative recipes are omitted.

## Source and decision evidence

- Exact source bundle: `ModuloMarket-GitHub-Update-0.12.7-ORIGINAL-UI-ASSETS.zip`, SHA-256 `4f550d9fbb9b388d2f81750d531efbe8a430e3dfc9a72125b632e21e7cba6896`, 2,725,824 bytes; ZIP integrity PASS.
- Active unfiltered 70938 canonical SHA-256: `c8491bbb1b88253ba5366515f232bd095b73ec9599de181595f26bb8a0f99ace`.
- Original 70938 runtime SHA-256: `4dfd24ec9238c51ae39e6ba4c27fe782a793118e473c43eaeb112a235c6695bc`.
- Source capture integrity/pagination/normalization review: `docs/FOREVERDB-DATA-REVIEW-2026-11-13.md`.
- Distribution policy and field counts: `MODULOMARKET-DATA-CLEANUP-0.12.8.md`.

## Implementation

- Added `tools/foreverdb_importer/sanitize_distribution.py`.
- Added `data/ForeverDB-Distribution-1.60.1.70938.json`.
- Regenerated `AddOns/ModuloMarket/ForeverDBData.lua` using the existing `market_data_importer.py compile-runtime` compiler.
- Removed unfiltered canonical 70862, 70888 and 70938 JSON files from the public source bundle. Their hashes are preserved in the cleanup audit.
- Updated `data/README.md`, `THIRD-PARTY-NOTICES.md`, root README, MANIFEST, version metadata, and regression harnesses.
- Addon and bundle version advanced together to 0.12.8.

## Exact projection results

- Professions: 12.
- Recipe structures: 2,493 → 2,350; 143 speculative records removed.
- Acquisition rows: 10,369 original; 4,166 retained (4,133 observed, 33 client); 6,203 removed overall.
- Of the 6,203 removed acquisition rows, 47 were attached to speculative recipes (4 observed, 3 Classic-borrowed, 40 unknown); among retained non-speculative recipes, 2,289 Classic-borrowed and 3,867 unknown rows were removed.
- Trainer directory: 269 → 176 observed entities; 93 Classic/non-observed entities removed; 2 mixed observed-entity/Classic-location entries retained without location/title/source fields.
- Trainer costs: only `FOREVER_OBSERVED` retained; 2,071 unobserved/unknown/Classic values quarantined.
- Skill thresholds: only `FOREVER_CLIENT` values retained; 552 orange values and 3 other threshold sets quarantined; `orange_classic` removed.
- Classic comparison fields and source aggregates removed.
- 1,495 retained recipe structures have no retained acquisition row; runtime reports acquisition as unknown rather than inventing a source.

## Offline validation

- `pytest -q`: **147 passed**.
- `texlua tests/foreverdb_provider_0_5_3_harness.lua AddOns/ModuloMarket/ForeverDBData.lua AddOns/ModuloMarket/ProfessionData.lua`: PASS.
- `texlua tests/turnin_writs_0_11_4_harness.lua AddOns/ModuloMarket`: PASS; 11 Writ checks + crate type; 145/150 exact recipe coverage remains unchanged.
- `texluac -p` on all 14 addon Lua files: PASS.
- Canonical schema validation: PASS; 12 professions, 2,350 recipes, 2,171 output records.
- Runtime compiler determinism: PASS; regenerated output is byte-identical to `ForeverDBData.lua`.
- Projection idempotence/fail-closed tests: PASS.
- Runtime data leakage tests: PASS; no Classic/unknown acquisition rows or speculative records.
- Manifest inventory exact: PASS after final manifest generation.
- ZIP CRC, fresh extraction and archive SHA-256: recorded in the standalone audit/handoff.

## Preserved prior runtime evidence

The following inherited FOREVER OBSERVED results remain valid at their demonstrated scope and are not upgraded to FOREVER VERIFIED:

- Closed-window Full Market refresh: PASS on Forever 1.60.1.
- Open-window Full Market refresh: PASS on Forever 1.60.1.
- Explicit Replicate cancellation, Modern presentation: PASS on Forever 1.60.1.
- Explicit Replicate cancellation, Blizz-like presentation: PASS on Forever 1.60.1.

No new in-client behavior was changed in this data-only slice. Forever runtime for the filtered catalogue itself is NOT RUN. Under the user's acceptance-by-exception policy, no routine screenshot is requested unless the user observes missing or incorrect profession data.

## Rights and release limitations

The published ForeverDB developer workflow supports fetching and bundling provider data with releases subject to attribution/no-resale/no-key conditions. The provider also identifies client data as Blizzard's. This projection is not a general licence and does not establish blanket Blizzard rights. The retained Forever-client/player-observed data is not MIT-licensed. No provider contact was made, at the user's direction. No unrestricted redistribution claim is made.

## Decision

0.12.8 is a conservative data-cleanup candidate. The cleanup slice is source/offline accepted when the final test/package gate passes. The retained third-party data rights limitation remains explicit; 1.0.0 approval is not implied.
