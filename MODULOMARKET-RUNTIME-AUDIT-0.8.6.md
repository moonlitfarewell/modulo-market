# ModuloMarket Runtime Audit 0.8.6 — ForeverDB catalogue reconciliation

## Result
**Data provenance refresh packaged — ModuloMarket 0.8.6.**

The complete ForeverDB capture for client build 1.60.1.70938 is normalized and reconciled against the 1.60.1.70888 catalogue. The capture contains 2,493 recipe records across all 12 professions. There are zero recipe additions, removals, or changed records. The addon runtime data is regenerated with the embedded repository compiler, retaining the complete field-level runtime contract. This is a provenance refresh, not a recipe-content expansion.

## Player problem and observable result
The player's WoW Forever client and refreshed Full Market snapshot are build 70938, while ModuloMarket 0.8.5 carried a ForeverDB recipe catalogue labelled 70888. ModuloMarket 0.8.6 now labels its bundled catalogue as 70938. The exact-build auction snapshot gate remains unchanged and fail-closed.

## Canonical baseline and available project evidence
- Parent source: `ModuloMarket-GitHub-Update-0.8.5.zip` (uploaded source snapshot), 1,775,763 bytes, SHA-256 `6c27ad2f2d716758245759ddf394e5c39a4bc092f8af87cce1ded1839a70a5ba`.
- Parent archive ZIP CRC: PASS; 161 entries.
- Parent addon, README and manifest version: 0.8.5.
- Parent bundle includes README, MANIFEST, historical audits, tests, data canonicals, compatibility contract and integration docs. Child-specific PROJECT-START-HERE, WORKFLOW, PROJECT-DECISIONS, PROJECT-PROGRESS, QA and SOURCE-REVIEW-LEDGER were not present in this repository snapshot; missing child history was not reconstructed.
- Parent 0.8.5 audit recorded 235 PASS / 61 unchanged historical failures, Lua syntax 9/9, compatibility and profession capture harnesses PASS, fresh extraction PASS, manifest 161/161, ZIP CRC PASS. Forever runtime acceptance was NOT RUN.
- User separately supplied a completed 70938 Full Market snapshot diagnostic in the conversation. This package does not alter or include SavedVariables.

## Capture integrity and provenance
- Raw archive: `capture-20261113-105521.zip`, user supplied and retained outside the public repository.
- Raw archive SHA-256: `5efb8b4b9c1e9031c8d2721bbebc80a6dc9d4fa573aa29cbf3b0dc9fc0f669a8`.
- ZIP integrity: PASS; 49 entries.
- Manifest: `COMPLETE`; ForeverDB.net; client build `1.60.1.70938`; 34 requests / 34 HTTP attempts; capture window 2026-11-13T10:55:21Z–10:56:31Z.
- All 34 response files match their manifest SHA-256 hashes and byte counts.
- All 12 profession slugs present. All 12 report `pagination_shape_unknown: false`; captured recipe counts equal reported totals. Total: 2,493.
- Actual raw responses use the documented `{data, meta}` envelope; profession `data` contains `ranks`, `trainers`, and `recipes`; pagination is represented by `limit`, `offset`, `next`, and `total`. No rank/skill-wrapped unknown pagination shape occurs in this capture. The prior concern is not supported by the actual uploaded archive.
- Standalone importer 0.2.3 inspect/hash verification: PASS. `normalize-capture`: PASS. Canonical `validate`: PASS.
- Normalized canonical SHA-256: `c8491bbb1b88253ba5366515f232bd095b73ec9599de181595f26bb8a0f99ace`.
- Generated runtime Lua SHA-256: `4dfd24ec9238c51ae39e6ba4c27fe782a793118e473c43eaeb112a235c6695bc`.

## Data reconciliation: 70888 → 70938
- Recipe records: 2,493 → 2,493.
- Per profession: 0 additions, 0 removals, 0 changed recipe records.
- Profession metadata and trainer records: unchanged.
- Reagent rows: 8,416 unchanged.
- Acquisition-source rows: 10,369 unchanged.
- Provider metadata: build 70888 → 70938; items 23,634 → 23,679; quests 6,647 → 6,655; vendors 969 → 974; articles 219 → 221. Other recorded provider counts are unchanged.
- Output classification remains 2,310 item outputs and 183 non-item/unknown outputs. 143 speculative records remain in canonical data and remain excluded from runtime under the existing compiler policy.
- Historical 70862 and 70888 canonical files are retained unchanged.

## Runtime compiler and field contract
The standalone importer 0.2.3 compact compiler is not the runtime compiler used for this release. The embedded repository compiler was inspected and verified to preserve the runtime's allow-listed field-level `acquisitionSources`, `learnAtSkill`, `trainerCostCopper`, and `trainerCostEvidence` fields consumed by `ProfessionData.lua`.

- Recompiling the 70888 canonical file with the embedded compiler reproduces the shipped 0.8.5 `ForeverDBData.lua` byte-for-byte.
- Compiling the 70938 canonical file with the same compiler produces a profession payload byte-for-byte identical to the 70888 runtime payload.
- Only runtime metadata changes: `clientBuild`, retrieval timestamp and capture manifest provenance.
- Generated output: 5,087,553 bytes; deterministic recompile comparison: PASS.
- No compiler source change was necessary in the addon repository.

## Ownership, dependencies and scope
- ModuloMarket owns its bundled catalogue and addon-side data adapter.
- ForeverDB.net remains the upstream provider; visible attribution/link retained. No key or credential included. Data is not represented as original ModuloMarket data or for resale.
- Required parent dependency MODULO is unchanged. Optional LibProfessionDB remains optional.
- No UI, market calculations, auction scan behavior, SavedVariables schema, item mapping, or graphical redesign changed.
- No specialist addon dependency added. No changes to MODULO or optional addons.

## Risks and limitations
- This capture advances catalogue provenance and provider counts but contributes no recipe-content changes compared with 70888.
- Client recipe presence does not prove live recipe availability or player acquisition. Existing evidence labels and fail-closed behavior remain unchanged.
- Classic-derived learning sources/prices remain labelled borrowed/unconfirmed where applicable.
- Auction snapshot compatibility is independent of recipe catalogue provenance. The exact current-client build gate is unchanged.
- Forever runtime acceptance of the refreshed catalogue and `/mmcompat` is NOT RUN. Offline tests do not prove target-client runtime behavior.

## Verification and acceptance
- Raw archive ZIP integrity and 34/34 response hashes/byte counts: PASS.
- Capture completeness, all profession pagination totals: PASS.
- Normalize and canonical validation: PASS; 12 professions / 2,493 recipes.
- 70888 → 70938 semantic comparison: PASS; 0 added / 0 removed / 0 changed recipes.
- Embedded compiler deterministic output and runtime field contract: PASS.
- Focused tests: 16 PASS (new 0.8.6 regression plus importer and raw-adapter tests).
- Full historical suite: 236 PASS / 61 failures. The 61 failing test IDs match the 0.8.5 baseline; zero new failing IDs.
- Lua syntax: 9/9 PASS using `texluac -p`.
- Compatibility harness: PASS.
- Profession capture harness: PASS.
- Fresh extraction, manifest inventory, archive CRC and hashes: recorded in the standalone companion audit/package handoff.
- Forever runtime: NOT RUN.

## Acceptance / exit
The data reconciliation slice is complete and packaged. The next planned product work returns to the graphical redesign; this slice does not authorize recipe micro-fixes or UI scope changes.
