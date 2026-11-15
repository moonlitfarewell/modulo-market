# Modulo Market 0.12.8 — Data Cleanup and Distribution Projection

**Decision:** implement the user's no-contact distribution policy using the published ForeverDB developer workflow and the source evidence already captured. No request will be sent to ForeverDB. This is a technical distribution projection, not a legal opinion or independent rights clearance.

## Player problem and observable result

The 0.12.7 package included a mixed-provenance canonical dataset and compiled runtime catalogue. Although the UI labelled Classic-borrowed and unknown acquisition routes, those records were still physically distributed. The observable result in 0.12.8 is a smaller, deterministic catalogue that retains Forever-client recipe structures and only explicitly Forever-observed/client acquisition evidence, with uncertain/Classic-derived details withheld rather than displayed as facts.

## Source evidence and baseline

Reviewed source: 0.12.7 fresh extraction, active canonical capture `data/ForeverDB-Canonical-1.60.1.70938.json` before projection.

| Source file | SHA-256 | 0.12.8 disposition |
|---|---|---|
| `ForeverDB-Canonical-1.60.1.70862.json` | `f2847cfbd537710f4956b0bac21024ff2573756eaef168bb030223213bb91b80` | Removed from distributable bundle; hash/provenance retained here |
| `ForeverDB-Canonical-1.60.1.70888.json` | `e4fc2babab2bb06292ce314c7987121eed1030edf35018b38c743200d1c1e2ef` | Removed from distributable bundle; hash/provenance retained here |
| `ForeverDB-Canonical-1.60.1.70938.json` | `c8491bbb1b88253ba5366515f232bd095b73ec9599de181595f26bb8a0f99ace` | Replaced in distribution by filtered projection |
| 0.12.7 runtime `ForeverDBData.lua` | `5507e9f51b05f3783702d98f47983c2f3f964383e1c38446fb124bf05672135f` | Recompiled from projection |

The original 70938 capture contained 12 professions, 2,493 recipe records and 10,369 acquisition-source rows. The source review established that all recipe structures, output quantities and reagent quantities in this capture were labelled `FOREVER_CLIENT`; individual acquisition routes had separate evidence labels. The 143 speculative recipes were explicitly identified as present in client files but untouched by Forever.

## Distribution rules applied

1. Retain a recipe only when `structure_evidence == FOREVER_CLIENT` and the record is not speculative.
2. Retain output and reagent quantities only when their respective evidence is `FOREVER_CLIENT`; fail closed if a retained recipe violates this condition.
3. Retain acquisition rows only when evidence is `FOREVER_OBSERVED` or `FOREVER_CLIENT`; drop `CLASSIC_BORROWED`, `UNKNOWN`, missing-evidence and inferred rows.
4. Retain trainer-directory entities only when `entity_evidence == FOREVER_OBSERVED`. If a retained trainer's location is not `FOREVER_OBSERVED`, retain the observed trainer identity but remove location/title/source fields and mark place evidence `UNKNOWN`.
5. Retain trainer prices only when `trainer_cost_evidence == FOREVER_OBSERVED`; remove all other prices and leave their evidence `UNKNOWN`.
6. Retain orange skill thresholds only when `orange_evidence == FOREVER_CLIENT`; remove `orange_classic` and the old source label. Retain yellow/green/grey thresholds only when `other_threshold_evidence == FOREVER_CLIENT`.
7. Remove Classic comparison metadata (`classic`, `changed_from_classic`, `classic_vendors`, `leftover_of`) and mixed-source aggregate prose/metadata from the projection.
8. Keep recipe structures that have no retained acquisition route. Their acquisition status remains unknown in the runtime; the projection does not invent a trainer, vendor, drop, quest or recipe-item route.
9. Remove the unfiltered 70862, 70888 and 70938 canonical JSON files from the public bundle. Preserve their source hashes and review history, not the mixed-provenance payloads.

## Exact before/after counts

### Recipe records

| Measure | Before | After |
|---|---:|---:|
| Professions | 12 | 12 |
| Recipe structures | 2,493 | 2,350 |
| Speculative recipes | 143 | 0 |
| Non-speculative Forever-client recipe structures | 2,350 | 2,350 |
| Non-item output records among retained recipes | — | 179 (runtime continues to exclude them from item craft economics) |

### Acquisition-source rows

| Evidence | Before all recipes | On non-speculative recipes | Retained |
|---|---:|---:|---:|
| `FOREVER_OBSERVED` | 4,137 | 4,133 | 4,133 |
| `FOREVER_CLIENT` | 33 | 33 | 33 |
| `CLASSIC_BORROWED` | 2,292 | 2,289 | 0 |
| `UNKNOWN` | 3,907 | 3,867 | 0 |
| **Total** | **10,369** | **10,322** | **4,166** |

The 47 acquisition rows attached to the 143 speculative recipes are also removed: 4 observed, 3 Classic-borrowed and 40 unknown. Of the non-speculative records, 6,156 acquisition rows are excluded (2,289 Classic-borrowed and 3,867 unknown). 1,495 retained recipe structures have no remaining acquisition row and remain explicitly unknown for acquisition purposes.

### Trainer, skill and price fields

- Trainer directory: 269 source entries; 93 non-observed entities excluded; 176 observed entities retained.
- Two observed trainer entities had Classic-borrowed locations; their entity identities remain, but location/title/source fields are withheld.
- 2,071 trainer-price values/evidence records are quarantined unless explicitly observed; retained prices are only those labelled `FOREVER_OBSERVED`.
- 552 orange threshold values without `FOREVER_CLIENT` evidence are withheld; `orange_classic` is never distributed.
- Three other threshold sets without `FOREVER_CLIENT` evidence are withheld.
- Classic comparison metadata is removed from every retained recipe.

## Runtime behavior and ownership

The runtime compiler remains the existing standalone importer `compile-runtime`, applied to the sanitized projection. `ProfessionData.lua` remains unchanged. It will now classify recipes with no retained acquisition rows as unknown-source recipes; it will not report any Classic-borrowed source count. Existing recipe structures, outputs, reagent groups, exact client build gate, Full Market snapshot gate, market calculations, UI and SavedVariables are unchanged.

Modulo Market owns the projection script and runtime adapter. ForeverDB remains the upstream data provider. The addon continues to visibly credit and link ForeverDB. No API key or raw capture archive is included. MODULO dependency direction is unchanged.

## Competing risks and limitations

- **Provider workflow interpretation:** published ForeverDB developer instructions say approved developers should fetch data and bundle it with releases, with visible free-tier credit, no resale/passing off as own, and no distributed API key. This supports the chosen bundle workflow. It is not a general open-data licence.
- **Underlying client data:** ForeverDB identifies Forever-client data as Blizzard's. The projection retains recipe structures/outputs/reagents with `FOREVER_CLIENT` evidence. Their underlying rights are not independently cleared by this cleanup. No blanket Blizzard permission is claimed.
- **Observed data:** `FOREVER_OBSERVED` means players' ForeverDB addon saw the fact in Forever; it is evidence of provenance, not a standalone copyright grant.
- **Unknown recipe acquisition:** recipe structures can remain while their unknown acquisition rows are withheld. The UI must continue to label missing source knowledge as unknown and must not infer a trainer/source from Classic data.
- **Product capability loss:** 143 speculative recipes are removed; 2,289 Classic and 3,867 unknown acquisition rows from non-speculative recipes are removed; 93 trainer entities and 2 locations are removed/withheld. Many recipes therefore have no acquisition guidance. This is intentional, not a data corruption claim.

## Tests and acceptance

- Canonical projection validates against the existing canonical schema: PASS.
- Projection is idempotent: PASS.
- Projection fails closed on non-`FOREVER_CLIENT` recipe structures: PASS.
- No `CLASSIC_BORROWED` or `UNKNOWN` acquisition rows in runtime: PASS.
- No speculative recipes in runtime: PASS.
- Only observed trainer prices retained: PASS.
- Runtime provider harness: PASS; matching build 70938 and baseline behavior on 70889 preserved; 12 professions, 2,350 recipes, 0 speculative, 179 non-item records; observed and unknown acquisition categories remain usable; no borrowed source rows.
- Existing Writ recipe cross-reference harness: expected to be run after regeneration; exact coverage is recorded in the runtime audit.
- Full pytest suite, Lua syntax, fresh extraction, ZIP CRC and SHA-256 are recorded in `MODULOMARKET-RUNTIME-AUDIT-0.12.8.md`.
- Forever runtime: NOT RUN for the changed data projection. User acceptance-by-exception remains in effect; no routine test requested. If the user reports missing/wrong profession information, reopen this slice as a runtime defect.

## Decision

The 0.12.8 projection implements the user's no-contact policy and removes the specifically identified Classic/unknown/speculative acquisition material from the public payload. It is a conservative distribution candidate, not legal clearance for the retained ForeverDB/Blizzard-derived data and not 1.0.0 approval. No provider contact was made.


## 15 November 2026 — public repository publication correction (0.12.9)

The 0.12.8 archive's 290-file manifest and ZIP inventory were correct, and the archive did not contain the three unfiltered canonical snapshots. A separate inspection of the public GitHub `main` tree at commit `c34bb314084f4308ecb0ff9d420473e4ab7a2995` found that the three raw snapshots had nevertheless remained as repository blobs. Their presence was outside the 0.12.8 release archive manifest, but still exposed the raw data through the public repository.

The snapshots were therefore a repository publication defect, not an installable-addon-folder finding and not evidence that the 0.12.8 ZIP contained them. The 0.12.9 candidate removes all three paths from its source tree; the corresponding public Git tree update remains pending. Their original capture hashes remain preserved in this report; Git blob identities and sizes from the affected public tree are recorded in `MODULOMARKET-REPOSITORY-RECONCILIATION-0.12.9.md`.

The repository's other 73 files outside the 0.12.8 package manifest are historical source artifacts: 72 test files and the superseded `MODULOMARKET-RUNTIME-AUDIT-0.7.9.md`. They are retained as repository-only history, not silently treated as release-package files. `MANIFEST.json` remains the release-package inventory. A separate verifier checks both inventories and rejects raw canonical snapshots in the repository.
