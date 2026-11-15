# Modulo Market 0.12.9 — Git repository and release-package reconciliation

## Player problem and observable result

The 0.12.8 release archive was internally clean, but the public GitHub repository still exposed three unfiltered ForeverDB canonical snapshots outside the release manifest. The 0.12.9 candidate is prepared to remove the raw snapshots from both the release package and the public Git tree, while historical test/audit files remain available as explicitly repository-only history. The public main update is not yet performed.

## Exact 0.12.8 baseline

- Repository: `moonlitfarewell/modulo-market`, default branch `main`.
- Parent commit: `c34bb314084f4308ecb0ff9d420473e4ab7a2995`.
- Recursive Git tree SHA: `9adbfef0c4b39e701ff286cdd23937e8983e5e40`.
- Tree entries: 379 (366 blobs, 13 tree entries); tree was not truncated.
- Release `MANIFEST.json`: 290 declared files; every declared path existed in the remote tree.
- Remote blobs outside the release manifest: 76.
- Remaining 73 repository-only files: 72 historical/current test artifacts and one superseded `MODULOMARKET-RUNTIME-AUDIT-0.7.9.md`. They are intentionally retained outside the release package.

### Raw canonical blobs removed

| Path | Bytes | Git blob SHA-1 |
|---|---:|---|
| `data/ForeverDB-Canonical-1.60.1.70862.json` | 14,798,824 | `de1329c98a39f88a49279c3f878dcba441f88033` |
| `data/ForeverDB-Canonical-1.60.1.70888.json` | 14,805,272 | `b3e1e365da78d3aad66ee1b9855346b6db459c42` |
| `data/ForeverDB-Canonical-1.60.1.70938.json` | 14,805,272 | `5f25c0537ea617130ebee3da4cf124e3254d6424` |
| **Total** | **44,409,368** | |

The SHA-1 values above are Git object identifiers from the affected remote tree, not the original capture SHA-256 values. The original capture SHA-256 provenance remains in `MODULOMARKET-DATA-CLEANUP-0.12.8.md`.

## Inventory policy

Two inventories are deliberately distinct:

1. `MANIFEST.json` describes the complete versioned source/release package. It includes the addon, source, docs, tests and tools intended to ship in the package.
2. The GitHub recursive tree describes every public repository blob. It may additionally contain historical test artifacts and superseded audit records that are not part of the release package.

The 0.12.9 verifier, `tools/verify_repository_tree.py`, accepts a downloaded recursive Git tree JSON document. It:
- rejects a truncated tree;
- verifies every manifest path exists locally and remotely;
- compares every package file's locally computed Git blob SHA-1 with the GitHub tree blob SHA;
- rejects all three unfiltered canonical snapshot paths;
- reports repository-only paths separately;
- permits repository-only files only under `tests/` or the exact superseded 0.7.9 audit path, failing closed on unclassified extras.

This means the release ZIP's manifest check can no longer be mistaken for a complete public repository check.

## Implementation

- Removed the three unfiltered canonical JSON files from the 0.12.9 candidate source tree; publication to public `main` remains pending.
- Kept the filtered `data/ForeverDB-Distribution-1.60.1.70938.json`.
- Preserved historical tests and the superseded 0.7.9 audit as repository-only artifacts.
- Updated README, data README, cleanup report and provenance addendum to distinguish repository from release package.
- Corrected the 0.12.8 runtime audit's stale opening status to reflect completed offline validation.
- Advanced addon and package version together to 0.12.9.
- Added a repository-tree verifier and regression coverage.

## Runtime consumer review

The source review confirms that `ProfessionData.lua` classifies recipes with no retained acquisition source as unknown. `MarketUI.lua` omits unknown/borrowed-source recipes from its background economics index, while the Crafts view separately calls `BuildEconomics` for displayed recipes and the item relationship inspector computes recipe summaries independently. This is a distinction between acquisition guidance and craft-cost computation, not evidence that missing acquisition data is silently replaced with a fabricated source.

The complete player-facing effect for all 1,495 recipes without retained acquisition rows remains not runtime demonstrated. No UI or runtime behavior was changed in this slice; no new Forever runtime test is claimed.

## Risks, ownership and limitations

- Modulo Market owns the release manifest, repository verifier, documentation and runtime adapter.
- ForeverDB remains the upstream provider.
- Repository cleanup does not establish legal rights to redistribute retained Forever-client/player-observed data.
- No ForeverDB contact was made.
- The 0.12.9 repository verifier proves Git-tree/package consistency only when run against a complete, current recursive Git tree response; it does not prove a licence grant.
- Forever runtime for the filtered data remains NOT RUN under the user's acceptance-by-exception policy.

## Acceptance and exit criteria

- [x] Exact 0.12.8 archive hash and ZIP integrity reverified.
- [x] 0.12.8 archive contains exactly 290 files matching its manifest.
- [x] Live 0.12.8 parent Git tree fully enumerated; all 290 manifest paths present.
- [x] Three raw canonical repository blobs identified by exact path, size and Git blob ID.
- [x] Historical repository-only files classified and retained.
- [x] Offline regression, Lua syntax and provider/Writ harnesses pass on the 0.12.9 candidate.
- [ ] Public `main` update and post-change recursive tree/package blob-hash verification: NOT RUN.
- [ ] Final 0.12.9 archive SHA-256 and fresh-extraction verification recorded in the completed standalone audit.
- [ ] Forever runtime: NOT RUN; no runtime behavior changed.

The 0.12.9 slice is source/offline accepted only after the remaining package and post-push repository checks pass. It is not 1.0.0 approval.
