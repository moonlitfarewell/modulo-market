# ForeverDB distribution projection

## Active distributable dataset

- Provider: [ForeverDB.net](https://foreverdb.net)
- Projection: `ForeverDB-Distribution-1.60.1.70938.json`
- Source client build: `1.60.1.70938`
- Source capture: 2026-11-13T10:55:21Z through 10:56:31Z
- Runtime output: `AddOns/ModuloMarket/ForeverDBData.lua`
- Runtime attribution: `Data from ForeverDB.net` with a visible provider link in the addon UI

The distributable file is a deterministic, conservative projection of the reviewed 70938 capture. It retains non-speculative recipe structures, outputs and reagent quantities labelled `FOREVER_CLIENT`, and acquisition facts labelled `FOREVER_OBSERVED` or `FOREVER_CLIENT`. It excludes speculative recipes, all `CLASSIC_BORROWED` and `UNKNOWN` acquisition rows, Classic comparison metadata, non-observed trainer directory entries, non-observed trainer locations, and trainer prices not explicitly observed in Forever. Skill-up values are retained only when their evidence is `FOREVER_CLIENT`.

The original unfiltered canonical files for builds 70862, 70888 and 70938 were absent from the 0.12.8 release archive but were mistakenly left in the public GitHub repository tree. GitHub commit `671df73` deletes all three from public `main`. The completed post-push 0.12.9 reconciliation confirms that none remains in the 379-entry Git tree or the release ZIP. Their SHA-256 values and source provenance are retained in `MODULOMARKET-DATA-CLEANUP-0.12.8.md`; the raw capture archive remains outside the public repository. The projection does not change the source capture's provenance or claim that omitted fields were false—only that they are not shipped.

## Projection contents

- 12 professions
- 2,350 non-speculative recipe structures (all labelled `FOREVER_CLIENT`)
- 4,166 retained acquisition rows: 4,133 `FOREVER_OBSERVED` and 33 `FOREVER_CLIENT`
- 176 trainer entities retained; two observed entities have location fields withheld because their locations were Classic-derived
- 0 Classic-borrowed or UNKNOWN acquisition rows in the distributable runtime
- 0 speculative recipe records

Recipes whose acquisition evidence was excluded remain available as Forever-client recipe structures but are presented as having unknown acquisition. No missing acquisition route, trainer price or skill threshold is invented.

## Rebuild

From the repository root:

```bash
python tools/foreverdb_importer/sanitize_distribution.py \
  path/to/reviewed-unfiltered-70938-canonical.json \
  data/ForeverDB-Distribution-1.60.1.70938.json
python tools/foreverdb_importer/market_data_importer.py validate \
  data/ForeverDB-Distribution-1.60.1.70938.json
python tools/foreverdb_importer/market_data_importer.py compile-runtime \
  data/ForeverDB-Distribution-1.60.1.70938.json \
  --output AddOns/ModuloMarket/ForeverDBData.lua
```

The unfiltered source input is intentionally not part of this public bundle. It must be supplied from the separately retained, hash-verified source capture. The projection tool fails closed if any retained recipe structure, output quantity or reagent quantity lacks `FOREVER_CLIENT` evidence.

## Attribution and distribution status

The addon visibly credits and links ForeverDB.net. The provider's published developer instructions say approved developers should fetch data themselves and bundle it with releases, must not ship API keys, must not resell the data or present it as their own, and must retain visible attribution on the free tier. Those instructions support the intended bundling workflow but are not a general open-data licence or a blanket licence to Blizzard material. The retained `FOREVER_CLIENT` and `FOREVER_OBSERVED` data remains third-party/provider-derived and is not covered by the root MIT licence. See `THIRD-PARTY-NOTICES.md` and `MODULOMARKET-DATA-CLEANUP-0.12.8.md`.

No API key, account credential or raw capture archive is included in the addon package.


## Repository versus release package

`MANIFEST.json` describes the versioned source/release package, not every file retained in the public Git repository. The repository may also retain historical tests and superseded audit records that are intentionally excluded from the release package. The completed 0.12.9 repository reconciliation ran the separate Git-tree verifier: all 293 manifest paths matched, zero blob mismatches remained after temporary CRLF-to-LF normalization of the Windows ZIP extraction, and all 73 repository-only files were classified. The three unfiltered canonical JSON snapshots are prohibited from both the release package and the public repository.


Repository cleanup lifecycle: retain the filtered distribution projection as the active distributable dataset. Raw canonical captures are provenance inputs, not release assets; once a newer capture has been validated and projected, superseded raw captures can be retired from the active public repository. Preserve capture provenance and cryptographic hashes in the data-cleanup records. The raw 70938 capture was removed from `main` in commit `671df73`; the filtered 70938 projection remains. The final tree check confirms this state.
