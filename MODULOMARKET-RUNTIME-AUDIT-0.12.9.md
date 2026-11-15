# Modulo Market 0.12.9 Runtime Audit — Post-push repository reconciliation

## Status

**RAW SNAPSHOT DELETION COMMIT CONFIRMED; OFFLINE PACKAGE CHECKS PASS; POST-CLEANUP RECURSIVE-TREE VERIFICATION NOT RUN; CORRECTIVE DOC/HASH UPDATE PENDING; FOREVER RUNTIME NOT RUN.**

This audit separates verified GitHub commit evidence from checks that still require a fresh recursive-tree export. No addon runtime behavior or distribution projection content changed in this correction.

## Player problem and observable result

The public repository retained three unfiltered ForeverDB canonical captures even though the filtered 1.60.1.70938 distribution projection was the active addon dataset. Those raw captures were unnecessary public-repository bloat and were not required by the addon package.

GitHub confirms commit [`671df73`](https://github.com/moonlitfarewell/modulo-market/commit/671df73bcdfc68037ffada5371622a318a702a16), message `Removing bloat`, on `main`. Its commit file list contains exactly these three deletions:

- `data/ForeverDB-Canonical-1.60.1.70862.json`
- `data/ForeverDB-Canonical-1.60.1.70888.json`
- `data/ForeverDB-Canonical-1.60.1.70938.json`

Direct GitHub content fetches for all three paths returned HTTP 404. The filtered `data/ForeverDB-Distribution-1.60.1.70938.json` remains present (Git blob `95ba8ad57104a862e2ae0d11a297f7636c0de4e0`).

## Repository and package evidence

- Repository: `moonlitfarewell/modulo-market`, branch `main`.
- 0.12.9 package manifest: 293 declared files; 292 Git blob hashes (manifest self-hash excluded).
- Remote `MANIFEST.json` blob before and after the deletion commit: `585e86813630ea5280f175c69c20fb22328989b8`.
- Remote TOC version: 0.12.9 (previously verified).
- Cleanup commit: `671df73bcdfc68037ffada5371622a318a702a16`.
- Cleanup commit parent: `a0f0ce6bd6318a89f95365a6eed31985b19bb94b`.
- The commit file list contains exactly the three raw snapshot deletions and no package-file modifications.
- The prior remote recursive-tree audit found 382 entries (369 blobs, 13 trees), all 293 manifest paths present, and 76 repository-only blobs. Since the cleanup commit removes exactly three blobs, the expected post-commit inventory is 379 entries (366 blobs, 13 trees) and 73 repository-only blobs. This is a commit-delta inference, **not** a fresh post-commit recursive-tree measurement.
- Fresh recursive tree export, truncation check, complete path inventory and rerun of `tools/verify_repository_tree.py`: **NOT RUN**.

## Package hash reconciliation

The prior live GitHub check found one byte-level mismatch:

- `tools/foreverdb_importer/Normalize-Latest-Capture.cmd`
- GitHub blob SHA-1: `ea339008d52fcb272b76e06516040a96b803d5c1`
- Candidate manifest expected SHA-1: `c7f97351c8a9cbc0cb2141410f9fed454019bb23`
- Cause: GitHub content uses LF line endings; the candidate archive used CRLF.

This correction changes the candidate file to LF and updates the manifest Git blob SHA-1 accordingly. The GitHub file itself already has the intended LF bytes. The corrected documentation and manifest still need to be pushed, after which the full 293-path/292-hash comparison must be rerun against a fresh recursive tree.

## Data lifecycle policy

- Keep the filtered `ForeverDB-Distribution-1.60.1.70938.json` as the active distributable dataset.
- Treat raw canonical captures as temporary provenance inputs, not addon release assets.
- After a newer capture is validated and its filtered projection accepted, retire superseded raw captures from the active public repository.
- Preserve capture provenance, timestamps and cryptographic hashes in the data-cleanup records.
- Do not infer that a new capture is valid merely because a file exists; validate completeness/schema and projection output before retiring the previous source.

## Offline validation inherited from the 0.12.9 candidate

- ZIP CRC and extraction: PASS on the source candidate.
- Full source suite: 149 passed.
- Lua syntax: 14/14 addon Lua files PASS using `texluac -p`.
- ForeverDB provider harness: PASS.
- Writ/Turn-In harness: PASS (11 Writ checks plus crate type; exact recipe coverage 145/150 unchanged).
- Manifest inventory: 293/293 paths; 292/292 declared Git blob hashes in the original candidate.
- Corrective change is documentation/manifest/line-ending reconciliation only; runtime code and projection payload are unchanged.
- Corrected ZIP CRC: **PASS**. Fresh extraction: **PASS**. Full `pytest -q`: **149 passed**. Lua syntax: **14/14 PASS** using `texluac -p`.

## Runtime and compatibility evidence

- Forever runtime: **NOT RUN** for this repository reconciliation.
- No new claim is made about client behavior.
- Existing inherited runtime evidence remains limited to the scopes explicitly recorded in the 0.12.8 audit and is not expanded by this cleanup.
- Retail evidence does not establish Forever behavior.

## Acceptance and exit criteria

1. Push the corrective package/docs update so the repository records the confirmed cleanup and uses the LF-matching importer launcher bytes.
2. Export the complete recursive Git tree for the new `main` head.
3. Run `tools/verify_repository_tree.py` against that tree; require non-truncated tree, all 293 package paths present, 292/292 Git blob hashes matching, no forbidden canonical paths, and only classified repository-only artifacts.
4. Re-run ZIP CRC, fresh extraction, pytest and Lua syntax/harness checks on the final corrected package.
5. Keep Forever runtime marked NOT RUN unless directly exercised on the target client.

Until these pass, repository reconciliation is **partially accepted**: raw snapshot deletion is confirmed, but complete post-cleanup tree/hash acceptance remains open.
