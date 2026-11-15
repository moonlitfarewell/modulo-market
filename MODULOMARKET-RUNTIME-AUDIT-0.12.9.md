# Modulo Market 0.12.9 Runtime Audit — Repository and Distribution Reconciliation

## Status

**0.12.9 CANDIDATE PREPARED; OFFLINE VALIDATION COMPLETE; GITHUB MAIN UPDATE NOT RUN; FOREVER RUNTIME NOT RUN.** The candidate removes the three unfiltered canonical snapshots from its source/package tree, separates repository inventory from release-package inventory, and corrects stale 0.12.8 documentation. The public repository has not yet been modified. No addon runtime behavior or data projection content was changed.

## Player problem and observable result

The 0.12.8 release ZIP was clean, but public GitHub `main` still exposes three unfiltered canonical snapshots outside its 290-file release manifest. The 0.12.9 candidate removes those paths locally; publication remains pending. The 73 other repository-only files are retained as historical tests and one superseded audit, explicitly outside the release package.

## Source and baseline evidence

- Parent archive: `ModuloMarket-GitHub-Update-0.12.8-DATA-CLEANUP.zip`.
- Parent archive bytes: `1,240,917`.
- Parent archive SHA-256: `0e9322a1f9e536a80b2bc4143442974f768012c44bf3868a18fecad477d4cbd8`.
- Parent ZIP CRC: PASS.
- Parent archive files: 290; manifest files: 290; exact path-set agreement: PASS.
- Parent GitHub commit/tree: `c34bb314084f4308ecb0ff9d420473e4ab7a2995`.
- Parent recursive Git tree: 379 entries; 366 blobs; 13 trees; not truncated.
- Parent remote tree contained all 290 package-manifest paths.
- Parent remote tree had 76 blobs outside the package manifest: three raw canonical snapshots, 72 repository-only test artifacts, and one superseded 0.7.9 audit.
- Raw canonical blobs totalled 44,409,368 bytes. Exact sizes and Git blob IDs are recorded in `MODULOMARKET-REPOSITORY-RECONCILIATION-0.12.9.md`.

## Implementation

- Deleted `data/ForeverDB-Canonical-1.60.1.70862.json`.
- Deleted `data/ForeverDB-Canonical-1.60.1.70888.json`.
- Deleted `data/ForeverDB-Canonical-1.60.1.70938.json`.
- Kept the filtered `data/ForeverDB-Distribution-1.60.1.70938.json`.
- Added `tools/verify_repository_tree.py` to compare a complete GitHub recursive tree with the local package manifest and every package file's Git blob SHA-1.
- Added regression coverage for exact local package inventory, blob hashes, repository-only historical files and forbidden canonical paths.
- Updated README/data README, cleanup/provenance history and the 0.12.8 audit status.
- Advanced TOC, Core and MANIFEST version together to 0.12.9.

## Offline validation

- Parent 0.12.8 `pytest -q`: **147 passed**.
- 0.12.9 full source suite: **149 passed**.
- Lua syntax: **14/14 addon Lua files PASS** using `texluac -p`.
- ForeverDB provider harness: **PASS** (`baseline-plus-delta provider harness passed`).
- Writ/Turn-In harness: **PASS**; 11 Writ checks plus crate type; 145/150 exact recipe coverage remains unchanged.
- Package manifest: **293/293 files exact**; Git blob SHA-1 inventory: **292/292 files PASS** (MANIFEST self-hash is checked separately against the Git tree).
- Projection policy, idempotence and fail-closed checks retained.
- Fresh-extraction tests, Lua syntax and both Lua harnesses: **PASS**.
- ZIP CRC and final SHA-256 are recorded in the standalone handoff audit.

## Runtime consumer review

`ProfessionData.lua` retains the unknown acquisition classification when a recipe has no retained source. `MarketUI.lua` excludes unknown/borrowed-source recipes from the background economics index, while the Crafts tab and item relationship inspector have separate economics calls. This does not establish a missing-source display defect; it records the distinct code paths for future player acceptance. No runtime code or runtime data changed in 0.12.9.

## Preserved Forever evidence

The following inherited FOREVER OBSERVED results remain valid only for their recorded scopes:
- Closed-window Full Market refresh.
- Open-window Full Market refresh.
- Explicit Replicate cancellation in Modern presentation.
- Explicit Replicate cancellation in Blizz-like presentation.

Forever runtime for the filtered catalogue remains **NOT RUN**. The 0.12.9 slice does not upgrade any inherited evidence to FOREVER VERIFIED.

## Rights and release limitations

The 0.12.9 repository cleanup is not a licence grant. Retained Forever-client/player-observed data remains third-party/provider-derived and is not MIT-licensed. No blanket Blizzard permission or unrestricted redistribution claim is made. No ForeverDB contact was made.

## Final candidate verification

Post-push GitHub recursive-tree verification is NOT RUN. The final local candidate archive hash is recorded in `MODULOMARKET-RUNTIME-AUDIT-0.12.9-STANDALONE.md`. The standalone record is the handoff copy and is not bundled into the archive, avoiding a self-referential archive hash. Any unperformed check remains NOT RUN/UNKNOWN rather than inferred from source tests.
