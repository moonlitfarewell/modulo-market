# ForeverDB Data Review — 2026-11-13 — Client build 1.60.1.70938

## Scope and player problem
ModuloMarket 0.8.5 carried a recipe catalogue sourced from ForeverDB build 1.60.1.70888 while the player's Forever client and refreshed Full Market snapshot were build 1.60.1.70938. This slice refreshes catalogue provenance only. Observable result: the addon reports a 70938 recipe catalogue, while retaining the existing exact-build auction snapshot gate and all market/UI behavior.

## Evidence and provenance
- Raw user-supplied archive: `capture-20261113-105521.zip`.
- Raw archive SHA-256: `5efb8b4b9c1e9031c8d2721bbebc80a6dc9d4fa573aa29cbf3b0dc9fc0f669a8`.
- ZIP integrity: PASS; 49 archive entries.
- Capture manifest status: `COMPLETE`; provider ForeverDB.net; client build `1.60.1.70938`; captured 2026-11-13T10:55:21Z through 10:56:31Z.
- Manifest records 34 requests and 34 HTTP attempts. All 34 response file byte counts and SHA-256 hashes verified against the manifest.
- All 12 profession slugs are present. Each profession's `pagination_shape_unknown` is false and captured record count equals reported total. Totals sum to 2,493.
- Importer 0.2.3 `inspect` passed hash verification and displayed the raw response shapes. `normalize-capture` completed and `validate` passed.
- Normalized canonical SHA-256: `c8491bbb1b88253ba5366515f232bd095b73ec9599de181595f26bb8a0f99ace`.
- 70938 runtime Lua SHA-256: `4dfd24ec9238c51ae39e6ba4c27fe782a793118e473c43eaeb112a235c6695bc`.

## Capture shape review
The capture manifest itself reports `pagination_shape_unknown: false` for all 12 professions. Profession pages contain the documented `{data, meta}` envelope; each `data` object includes profession metadata, ranks, trainers, trainer note and a `recipes` array. Page metadata includes `total`, `limit`, `offset` and `next`. Every captured page was accounted for by the manifest; no rank/skill wrapper was encountered in this archive. The earlier concern about rank-wrapped pagination is not supported by the actual uploaded capture.

## Normalization and classification
- 12 professions; 2,493 recipes.
- 2,310 item outputs; 183 non-item/unknown outputs.
- 143 speculative records retained in canonical JSON; runtime exclusion behavior remains unchanged.
- Canonical validation: PASS; no duplicate recipe IDs; output quantities and evidence classifications remain as normalized.
- Attribution required: ForeverDB.net, visible link retained by existing addon UI. No API key or credential is included. Raw capture remains outside the public repository.

## 70888 → 70938 reconciliation
- Per profession, recipe additions: 0; removals: 0; changed recipe records: 0.
- Profession metadata and trainer records: unchanged.
- Recipe acquisition-source rows: unchanged (10,369); reagent rows: unchanged (8,416).
- Provider metadata changes: build `1.60.1.70888` → `1.60.1.70938`; items 23,634 → 23,679; quests 6,647 → 6,655; vendors 969 → 974; articles 219 → 221. Other recorded provider counts are unchanged.
- The regenerated 70938 runtime profession payload is byte-identical to the runtime payload regenerated from the 70888 canonical file. The runtime metadata alone advances build, retrieval timestamp and capture-manifest provenance.

## Compiler and runtime contract
The standalone importer 0.2.3 compact compiler does not preserve the full addon runtime contract. The repository's embedded compiler does preserve the allow-listed field-level acquisition source rows and the `learnAtSkill`, `trainerCostCopper`, and `trainerCostEvidence` fields consumed by `ProfessionData.lua`. The 0.8.6 runtime Lua was generated using that embedded repository compiler, not the standalone compact compiler. The 70938 generated output is the same size and schema as 70888; semantic profession payload equality was verified byte-for-byte. No compiler source changes were needed in the addon repository.

## Ownership, dependencies and scope
- ModuloMarket owns its bundled catalogue and the addon-side data adapter.
- ForeverDB.net is the upstream data provider; attribution requirements remain.
- Parent MODULO is a required dependency and is unchanged. Optional LibProfessionDB remains optional.
- No dependency on Auctionator, ProfessionMaster, or other optional specialist addons was added.
- No UI redesign, market calculation, auction scan, SavedVariables, or recipe acquisition logic changes.

## Risks and limitations
- Zero recipe diffs means this refresh advances provenance and provider metadata, not recipe coverage or recipe facts.
- The provider's client-build provenance is not independent proof of live acquisition availability. Existing evidence labels remain unchanged.
- Exact-build auction snapshot compatibility remains a separate gate. User previously supplied a complete 70938 Full Market snapshot diagnostic; this slice does not change or bundle SavedVariables.
- Forever runtime acceptance of this refreshed catalogue is NOT RUN.

## Acceptance and exit criteria
- Raw archive, response hashes, pagination totals, normalized schema and recipe reconciliation: PASS.
- Runtime compilation using the embedded repository compiler and preservation of consumed fields: PASS.
- No UI or calculation change; no exact-build gate weakening: PASS by source diff.
- Full historical suite: 235 PASS / 61 unchanged historical failures, matching the 0.8.5 baseline failure count.
- Lua syntax, harness, fresh extraction, manifest and ZIP integrity: recorded in `MODULOMARKET-RUNTIME-AUDIT-0.8.6.md`.
- Forever client runtime verification: NOT RUN.
