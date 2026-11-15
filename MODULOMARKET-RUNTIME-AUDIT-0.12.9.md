# Modulo Market 0.12.9 Runtime Audit — Post-push repository reconciliation

## Status

**REPOSITORY/PACKAGE RECONCILIATION PASS; OFFLINE PACKAGE STRUCTURE PASS; HISTORICAL OFFLINE TEST RESULTS INHERITED; FOREVER RUNTIME NOT RUN FOR THIS RECONCILIATION.**

This audit closes the 0.12.9 public Git-tree and release-package reconciliation. It does not certify new addon runtime behavior, repeat the historical full test suite, clear third-party data rights, or approve 1.0.0.

## Player problem and observable result

The 0.12.8 release archive excluded three unfiltered ForeverDB canonical captures, but those files remained in the public Git repository outside the release manifest. The 0.12.9 cleanup removed all three from public `main`. The remaining task was to prove that the complete post-push repository tree, the 0.12.9 package manifest and the release ZIP agreed, and that repository-only history was classified.

The player-facing result is that the public source repository no longer retains those three raw canonical capture files, while the filtered 1.60.1.70938 distribution projection remains available to the addon.

## Canonical source and exact commit

- Repository: `moonlitfarewell/modulo-market`.
- Branch: `main`.
- Verified branch head: `803bdf73042236ce741e9bedf8ae6c2df0a621aa`.
- Commit message: `Post push correction`.
- Parent: `671df73bcdfc68037ffada5371622a318a702a16`.
- Git root tree SHA: `0bedfe3723e9544dd9718ac239be247a91c085e5`.
- The supplied local export's commit guard confirmed local `HEAD` equalled `origin/main` when exported.
- Recursive local Git tree export: 379 entries, comprising 366 blobs and 13 directory entries; `truncated=false`.

The branch head was independently read from GitHub's `main` branch endpoint and matched the uploaded tree export commit. The 379-entry inventory is a complete local Git tree for that commit; it is not represented as a separate fresh GitHub recursive-tree API response.

## Repository-tree verification

The actual repository verifier, `tools/verify_repository_tree.py`, was run against the uploaded tree export and a fresh extraction of the 0.12.9 ZIP.

The first run against the raw Windows ZIP extraction reported 286 blob mismatches. Inspection showed those files had CRLF line endings in the extracted archive, while the corresponding Git blobs use LF. This is a packaging/line-ending representation difference, not evidence that the source files differ.

A temporary verification copy was therefore normalized from CRLF to LF for text files only; the original ZIP and extracted evidence were not altered. The verifier was rerun against that normalized temporary package root.

**Final verifier result: PASS.**

- Tree entries: 379.
- Repository blobs: 366.
- Release manifest paths: 293.
- Manifest file count: 293; no duplicate paths.
- Declared Git blob hashes in the manifest: 292 (the manifest does not hash itself).
- Verifier path/hash comparisons: 293/293, including the MANIFEST.json blob.
- Git blob mismatches after text line-ending normalization: 0.
- Missing local manifest paths: 0.
- Missing manifest paths from Git tree: 0.
- Forbidden unfiltered canonical snapshots present: 0.
- Repository-only files: 73.
- Unclassified repository-only files: 0.

The 73 repository-only files are exactly 72 files under `tests/` and the superseded `MODULOMARKET-RUNTIME-AUDIT-0.7.9.md`. They are retained historical/test material, not part of the 293-file release manifest.

## Forbidden snapshot check

The following paths are absent from the post-push Git tree and from the release package:

- `data/ForeverDB-Canonical-1.60.1.70862.json`
- `data/ForeverDB-Canonical-1.60.1.70888.json`
- `data/ForeverDB-Canonical-1.60.1.70938.json`

GitHub commit `671df73bcdfc68037ffada5371622a318a702a16` records exactly those three deletions. The filtered `data/ForeverDB-Distribution-1.60.1.70938.json` remains present.

## Release ZIP verification

- Artifact: `modulo-market-803bdf7.zip`.
- SHA-256: `daa870ee7237e5c65fe6ee856c1320261d4a806277aa03b96e19cf1447a6b4cc`.
- ZIP integrity test: PASS; no CRC errors.
- Fresh extraction: PASS; 366 regular files.
- Manifest inventory: 293 declared paths, all present.
- Addon TOC version: 0.12.9.
- Core version: `MM.version = "0.12.9"`.
- No `.git/` directory is expected in a `git archive` ZIP.

The ZIP contains Windows-style CRLF conversions for 286 text files relative to their Git blob bytes. The temporary normalized copy was used only for Git blob comparison. The distributable ZIP itself was not rewritten.

## Package hash correction

The 0.12.9 correction changed `tools/foreverdb_importer/Normalize-Latest-Capture.cmd` to LF bytes matching the canonical Git blob and updated its manifest hash. The post-push tree verification confirms the final source and package now agree after accounting for the archive's Windows line-ending conversion.

## Offline validation and evidence boundary

The following results are recorded in the prior 0.12.9 candidate/post-push handoff and are inherited evidence, not tests rerun during this documentation pass:

- `pytest -q`: 149 passed.
- Lua syntax: 14/14 addon Lua files passed using `texluac -p`.
- ForeverDB provider harness: PASS.
- Writ/Turn-In harness: PASS (11 Writ checks plus crate type; 145/150 recipe coverage unchanged).
- Corrected ZIP CRC and fresh extraction: PASS.

This reconciliation pass freshly reran ZIP CRC/extraction checks and the repository-tree verifier. It did not rerun pytest, Lua syntax, or the addon harnesses.

## Runtime and compatibility evidence

- Forever runtime for this repository reconciliation: **NOT RUN**.
- No addon Lua/runtime behavior or distribution projection payload changed in the reconciliation correction.
- Existing inherited Forever 1.60.1 observations remain limited to their recorded scopes: closed-window Full Market refresh, open-window Full Market refresh, and explicit Replicate cancellation in Modern and Blizz-like presentations.
- Those observations remain **FOREVER OBSERVED**, not **FOREVER VERIFIED**.
- Retail behavior does not prove Forever behavior.

## Data rights and distribution limitations

The root MIT licence applies only to original Modulo Market source and the six project-authored UI assets identified in `ASSET-PROVENANCE.md`, subject to contributor rights. The ForeverDB-derived projection is not MIT-licensed. ForeverDB's published developer instructions support fetching/bundling with visible attribution and no API keys, but are not a general open-data licence or a blanket Blizzard rights grant. No provider contact was made. No unrestricted redistribution claim is made. See `THIRD-PARTY-NOTICES.md`, `MODULOMARKET-PROVENANCE-AUDIT-2026-11-15.md` and `MODULOMARKET-DATA-CLEANUP-0.12.8.md`.

## Acceptance and exit criteria

- [x] Three raw canonical snapshot deletions confirmed by GitHub commit evidence.
- [x] Current GitHub `main` head matched the exported local Git commit.
- [x] Complete 379-entry local Git tree export; not truncated.
- [x] All 293 release manifest paths present in local package and Git tree.
- [x] Repository verifier: 293/293 blob comparisons pass after text CRLF-to-LF normalization.
- [x] No forbidden raw canonical paths.
- [x] All 73 repository-only files classified (72 tests and one superseded audit).
- [x] ZIP CRC, fresh extraction and version agreement pass.
- [x] Historical test evidence and fresh checks clearly distinguished.
- [x] Forever runtime remains NOT RUN for this reconciliation.

**0.12.9 repository reconciliation is CLOSED/PASS.** This closes only the repository/package integrity slice. It is not 1.0.0 approval. Remaining 1.0.0 gates are final regression/compatibility review, explicit distribution/licensing posture, and release-candidate build/validation.

## Post-documentation synchronization — 15 November 2026

After the reconciliation records, README and data README were corrected, their four Git blob hashes were refreshed in `MANIFEST.json`. A fresh GitHub recursive-tree API read was then performed against the resulting current `main` head:

- Final verified head at this check: `9c480822fa2bc1c89c3c707da2b57e92e7878e99`.
- Git root tree SHA: `db0b7f1b26c4c7d4f11c6a496c571e1f6303d15c`.
- Recursive tree: not truncated; 379 entries (366 blobs).
- Manifest: version 0.12.9; 293 paths; all present in the Git tree.
- Manifest-declared Git blob hashes: 292/292 match the current remote tree; `MANIFEST.json` is intentionally excluded from its own hash map.
- Repository-only paths: 73; all classified as 72 test files and the superseded 0.7.9 audit.
- Forbidden canonical snapshots: 0.

This final remote-tree check supersedes the earlier 803bdf tree-head reference for the current `main` state. No addon/runtime files changed in the documentation synchronization.
