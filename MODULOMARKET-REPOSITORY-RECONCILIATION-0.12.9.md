# Modulo Market 0.12.9 — Git repository and release-package reconciliation

## Player problem and observable result

The 0.12.8 release archive excluded three unfiltered ForeverDB canonical snapshots, but the public GitHub repository still exposed them outside the release manifest. The 0.12.9 cleanup removed those files from public `main`. This reconciliation verifies that the post-push Git tree, release manifest and release ZIP agree, and that the remaining repository-only historical files are explicitly classified.

**Result: repository/package reconciliation PASS for commit `803bdf73042236ce741e9bedf8ae6c2df0a621aa`.** The filtered 1.60.1.70938 distribution projection remains; the three unfiltered canonical captures are absent from both repository and release package.

## Canonical source and tree

- Repository: `moonlitfarewell/modulo-market`.
- Branch: `main`.
- Verified head: `803bdf73042236ce741e9bedf8ae6c2df0a621aa` (`Post push correction`).
- Parent: `671df73bcdfc68037ffada5371622a318a702a16`.
- Git root tree SHA: `0bedfe3723e9544dd9718ac239be247a91c085e5`.
- Local export guard: `HEAD == origin/main`.
- Recursive tree: 379 entries (366 blobs and 13 directory entries), `truncated=false`.

The GitHub `main` branch endpoint independently reported the same head commit. The uploaded tree export is generated from the local Git object database at that matching commit; this is not described as a separate fresh GitHub recursive-tree API download.

## Raw canonical blobs removed

GitHub commit `671df73bcdfc68037ffada5371622a318a702a16`, message `Removing bloat`, deletes exactly:

| Path | Bytes | Git blob SHA-1 |
|---|---:|---|
| `data/ForeverDB-Canonical-1.60.1.70862.json` | 14,798,824 | `de1329c98a39f88a49279c3f878dcba441f88033` |
| `data/ForeverDB-Canonical-1.60.1.70888.json` | 14,805,272 | `b3e1e365da78d3aad66ee1b9855346b6db459c42` |
| `data/ForeverDB-Canonical-1.60.1.70938.json` | 14,805,272 | `5f25c0537ea617130ebee3da4cf124e3254d6424` |
| **Total** | **44,409,368** | |

The SHA-1 values are Git object identifiers, not the original capture SHA-256 values. Original capture provenance and cryptographic hashes remain in `MODULOMARKET-DATA-CLEANUP-0.12.8.md`.

The filtered `data/ForeverDB-Distribution-1.60.1.70938.json` remains present (Git blob `95ba8ad57104a862e2ae0d11a297f7636c0de4e0`).

## Distinct inventories

Two inventories remain deliberately distinct:

1. `MANIFEST.json` defines the 293-file versioned source/release package.
2. The GitHub repository tree defines every public repository blob, including 72 historical/current test files and one superseded audit not included in the release package.

The repository verifier, `tools/verify_repository_tree.py`, checks the package against a complete recursive Git tree, rejects truncated trees, verifies local and remote manifest paths, compares Git blob IDs, rejects the three raw canonical paths and classifies repository-only paths. It fails closed on unclassified extras.

## Verification result

The uploaded export contains 379 entries, 366 blobs and 13 directory entries. The 0.12.9 ZIP contains 366 regular files; all 293 manifest paths exist in the ZIP and Git tree.

The verifier was first run against the raw ZIP extraction. It reported 286 blob mismatches because the Windows-created archive extraction represented text files with CRLF line endings while Git stores the corresponding text blobs with LF. This was investigated rather than waived. A temporary verification copy converted CRLF to LF for text files only; the original ZIP remained unchanged. The verifier was then rerun:

- Manifest paths checked: 293/293.
- Git blob comparisons: 293/293 pass, including the `MANIFEST.json` blob.
- Manifest-declared file hashes: 292 (self-hash excluded).
- Hash mismatches after line-ending normalization: 0.
- Missing local or remote manifest paths: 0.
- Forbidden canonical snapshots: 0.
- Repository-only files: 73.
- Unclassified repository-only files: 0.

Repository-only classification:
- 72 paths under `tests/`.
- `MODULOMARKET-RUNTIME-AUDIT-0.7.9.md` (superseded historical audit).
- No other repository-only paths.

## Release ZIP integrity and identity

- Artifact: `modulo-market-803bdf7.zip`.
- SHA-256: `daa870ee7237e5c65fe6ee856c1320261d4a806277aa03b96e19cf1447a6b4cc`.
- ZIP CRC: PASS.
- Fresh extraction: PASS (366 regular files).
- TOC version: 0.12.9.
- Core version: `MM.version = "0.12.9"`.
- The archive is a source snapshot, so absence of `.git/` is expected.

The ZIP's CRLF representation for 286 text paths is a Windows archive conversion; the normalized temporary copy is used only for Git blob comparison. No line-ending normalization was written back into the ZIP or the canonical source.

## Implementation and ownership

- Modulo Market owns the release manifest, repository verifier, addon package and reconciliation records.
- ForeverDB remains the upstream data provider.
- Repository cleanup does not establish legal rights to redistribute retained ForeverDB/Blizzard-derived data.
- No ForeverDB contact was made.
- No unrestricted redistribution claim is made.

## Runtime and evidence boundaries

No addon Lua/runtime behavior or distribution projection payload changed in this reconciliation correction. Forever runtime for this slice is **NOT RUN**. Inherited Forever 1.60.1 observations remain scoped to closed-window Full Market refresh, open-window Full Market refresh and explicit Replicate cancellation in both presentations; these remain **FOREVER OBSERVED**, not **FOREVER VERIFIED**. The reconciliation is an integrity result, not a runtime compatibility claim.

## Acceptance

- [x] Raw canonical snapshot deletions confirmed by GitHub commit evidence.
- [x] Current GitHub `main` head confirmed as 0.12.9 correction commit.
- [x] Complete 379-entry local Git tree exported with no truncation.
- [x] All 293 release paths present in package and Git tree.
- [x] All 293 blob comparisons pass after documented CRLF-to-LF normalization.
- [x] No forbidden canonical snapshots remain.
- [x] All 73 repository-only files classified.
- [x] ZIP CRC, extraction and version agreement pass.
- [x] Runtime evidence remains accurately scoped.

**The 0.12.9 repository reconciliation is closed/PASS.** This does not approve 1.0.0. The remaining release gates are final regression/compatibility review, explicit distribution/licensing posture and 1.0.0 release-candidate validation.

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
