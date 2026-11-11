# ModuloMarket Runtime Capability Audit 0.5.3 — 2026-11-11

## Result

**ForeverDB data integration source slice implemented — ModuloMarket 0.5.3.**

The approved ForeverDB capture was verified, normalized into canonical v1, compiled into compact addon Lua data, connected to the existing recipe/material/economics index, and guarded by exact client and market-snapshot build checks. This is source/offline acceptance only. Forever runtime acceptance remains **NOT RUN**.

## Player problem and observable result

Market 0.5.2 could capture recipes learned by the current character but did not have a reviewed Forever-specific unlearned recipe catalogue. The previous optional LibProfessionDB path could contain Classic-borrowed learning-source or skill information.

Market 0.5.3 now has a bundled ForeverDB recipe catalogue for client build `1.60.1.70862`. On a matching client, it:
- indexes unlearned item-output recipes and their reagent/material relationships;
- separates Forever-observed/automatic sources, Classic-borrowed sources and unverified sources;
- excludes speculative and non-item/unknown-output records from item-craft economics;
- de-duplicates recipes already learned by the character;
- requires the saved Browse/Replicate snapshot's client version/build to match the current client before recipe economics can use those auction prices;
- displays `Data from ForeverDB.net — https://foreverdb.net` in the Market window.

## Canonical source and parent provenance

### Previous child inputs

| Input | Bytes | SHA-256 |
|---|---:|---|
| `ModuloMarket-GitHub-Update-0.5.2.zip` | 245,890 | `b4ae848d694c101df7ae5afe8a067319f4aa657f18db83cd027c6578cdd3b225` |
| `ModuloMarket-0.5.2.zip` | 51,411 | `d32ecaaee1b05b19c898eacbf836d68b27defd69a264d32ade4fb9c891b80ad2` |
| `ModuloMarket-ForeverDB-Importer-0.1.1.zip` | 19,660 | `df6a4e2bed16d06908eb637c51fe1dd956a0359a4d2b91f28019e14e2cc5d914` |
| User-supplied `capture-20261111-122719.zip` | 456,307 | `8d59b9e495a4dff865ca339a35bfcee5ead1f1621badfd6faaff114d01619a8f` |

All four input ZIPs pass CRC integrity. The standalone 0.5.2 addon files were byte-identical to the GitHub update's `AddOns/ModuloMarket/` files.

### Parent MODULO

- Parent: `MODULO-Project-Source-1.0.48.zip`
- Bytes: 41,236,015
- SHA-256: `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`
- ZIP CRC: PASS; 506 entries.
- Parent version and source were not modified by this Market slice. ModuloMarket remains a separate optional child addon; MODULO has no dependency on Market.

### Raw capture verification

- Provider: ForeverDB.net.
- Capture status: `COMPLETE`.
- Client build: `1.60.1.70862`.
- Capture window: `2026-11-11T12:27:21Z` to `2026-11-11T12:27:55Z`.
- ZIP: 49 entries; CRC PASS.
- Manifest: 34 response entries and `request_count=34`.
- Every response's byte count and SHA-256 match the capture manifest.
- All 12 profession slugs and all profession page totals match actual nested `data.recipes` records.
- API key is not present in the capture or any package.
- Raw capture is intentionally not committed to the public source repository; its exact hash is recorded above. The normalized canonical data is retained in `data/`.

## Data findings and evidence limits

### Counts

| Profession | Recipes |
|---|---:|
| Alchemy | 196 |
| Blacksmithing | 506 |
| Enchanting | 262 |
| Engineering | 275 |
| Leatherworking | 592 |
| Tailoring | 471 |
| Cooking | 132 |
| First Aid | 32 |
| Mining | 18 |
| Herbalism | 3 |
| Skinning | 3 |
| Fishing | 3 |
| **Total** | **2,493** |

Additional facts from the actual records:

- 2,310 recipes have an item output; all have a positive `makes.count`.
- 183 have no item output: 170 Enchanting service categories and 13 unknown/non-item rows.
- 143 are marked speculative; these remain in canonical data but are excluded from the runtime craft catalogue.
- 8,416 reagent rows are present.
- 928 are marked `newInForever`; 737 have `changedFromClassic` information.
- 70 have `learnedFrom.known=false`.
- Orange skill threshold source: 1,838 `client`, 404 `classic`, 251 missing/unknown.
- 33 are marked automatic.
- There are no separate output minimum/maximum fields in this capture and no captured variable output ranges.
- The flat reagent rows expose no optional/alternative markers.

For non-speculative item-output records before character-known recipe de-duplication, source classification is:
- 771 Forever-observed or automatic;
- 276 Classic-borrowed only;
- 1,124 unknown/unverified acquisition source.

These counts are mutually exclusive in the runtime classifier and total 2,171 non-speculative item-output candidates before per-character de-duplication.

### Evidence mapping

- Recipe structure, output item/count, reagent item/count and client skill thresholds: `FOREVER_CLIENT`.
- Trainer/vendor rows with `seenInForever=true`: `FOREVER_OBSERVED`.
- Trainer/vendor rows with `seenInForever=false`: `CLASSIC_BORROWED`.
- Inferred trainer-teaching edges: `UNKNOWN`, even if the NPC itself is observed.
- Automatic learning: `FOREVER_CLIENT`.
- Drops and quests without a per-row observation flag: `UNKNOWN`.
- Recipe-item acquisition without a concrete obtainable source: `UNKNOWN`.
- Classic orange skill thresholds remain `CLASSIC_BORROWED`; they are not promoted to trainer learning requirements.
- `sources.learnAtSkill` and `requiredLevel` are preserved as provider metadata and are not silently converted into trainer requirements.
- The normalizer retains full trainer/vendor/drop/quest/recipe-item evidence in canonical JSON. The compact runtime Lua currently carries only the recipe/economics fields and source-status classification needed by the addon.

No random output range, reagent alternative, optional reagent, trainer learning requirement, drop observation or quest acquisition observation is invented.

## Implementation

### Files changed/added

- `AddOns/ModuloMarket/ForeverDBData.lua` — generated compact runtime data, 1,536,052 bytes.
- `AddOns/ModuloMarket/ProfessionData.lua` — exact client-build gate, ForeverDB recipe provider, source classification, item/material indexing, known recipe de-duplication, snapshot compatibility method.
- `AddOns/ModuloMarket/MarketUI.lua` — source attribution, source/build status and price lookup gate for saved auction snapshots.
- `AddOns/ModuloMarket/Core.lua`, `ModuloMarket.toc` — aligned version 0.5.3 and data load order.
- `tools/foreverdb_importer/market_data_importer.py` — `normalize-capture` and `compile-runtime`.
- `tools/foreverdb_importer/recipe-data-v1.schema.json` — extended canonical data fields.
- `tools/foreverdb_importer/Normalize-Latest-Capture.ps1/.cmd` — Windows convenience wrapper.
- `tests/test_foreverdb_raw_adapter.py`, `tests/foreverdb_provider_0_5_3_harness.lua`, `tests/test_modulomarket_foreverdb_provider_0_5_3.py`.
- `data/ForeverDB-Canonical-1.60.1.70862.json` — normalized full canonical data.
- `docs/FOREVERDB-DATA-REVIEW-2026-11-11.md` — detailed raw mapping and source evidence.
- `docs/FOREVERDB-INTEGRATION-PLAN.md`, `README.md`, `MANIFEST.json` — current status and provenance.

### Data commands

```text
python tools/foreverdb_importer/market_data_importer.py normalize-capture <capture-folder> --output data/ForeverDB-Canonical-1.60.1.70862.json
python tools/foreverdb_importer/market_data_importer.py validate data/ForeverDB-Canonical-1.60.1.70862.json
python tools/foreverdb_importer/market_data_importer.py compile-runtime data/ForeverDB-Canonical-1.60.1.70862.json --output AddOns/ModuloMarket/ForeverDBData.lua
```

The normalizer checks COMPLETE status, provider/build agreement, every response hash/byte count, unique profession slugs, profession index agreement, page counts/offsets/totals, and duplicate recipe IDs. The compact runtime compiler emits only fields currently consumed by the addon; full source detail remains in canonical JSON.

### Runtime behavior and safeguards

- `ForeverDBData.lua` loads before `ProfessionData.lua`.
- `GetBuildInfo()` is composed into an exact client build; the provider refuses to load imported recipes unless it matches the dataset.
- If a bundled ForeverDB dataset exists but the client build cannot be checked or does not match, the addon does not silently substitute another data source.
- Optional LibProfessionDB remains a fallback only when no bundled ForeverDB dataset exists.
- Character-known recipes are de-duplicated by profession/recipe ID and profession/output/normalized name.
- Speculative and non-item/unknown-output rows do not enter item-craft economics.
- Observed/automatic, Classic-borrowed and unknown acquisition sources are kept separate.
- Saved Browse/Replicate snapshots already record `clientVersion` and `clientBuild`; `ProfessionData.IsMarketSnapshotCompatible()` requires that snapshot build to match the current client before MarketUI supplies snapshot prices to recipe economics. Unknown or mismatched snapshots withhold craft profitability.
- The Market window visibly credits ForeverDB with the provider name and URL.
- No new WoW runtime dependency, live API request, API key, MODULO dependency or MODULO source change was introduced.

## Generated data artifact hashes

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `data/ForeverDB-Canonical-1.60.1.70862.json` | 14,798,824 | `f2847cfbd537710f4956b0bac21024ff2573756eaef168bb030223213bb91b80` |
| `AddOns/ModuloMarket/ForeverDBData.lua` | 1,536,052 | `a45a5f18649769b3428611b67648866b9e7c33986476f1579e02594c08ec9172` |
| `tools/foreverdb_importer/market_data_importer.py` | 61,520 | `b784bb884031904725b0cc4f505cfe82864d570810e47faea5f4dcecd923ca09` |
| `tools/foreverdb_importer/recipe-data-v1.schema.json` | 13,170 | `153935013c35f71f6f61f0df6509cbe6d60d76582f50260e323a07ff5f40e8d2` |

Capture manifest SHA-256: `c3dd2e61ad604cb2027cb55f6e1838672d9049bb7bedb9d064cf6f98eb5aebbb`.

## Verification

### Source and data checks

- Actual raw capture ZIP CRC: PASS.
- 34 response hashes and byte counts: PASS.
- Profession totals: 12/12 match; 2,493 actual records.
- Canonical normalizer on actual capture: PASS; deterministic output matches retained canonical JSON.
- Canonical custom validator: PASS; 12 professions, 2,493 recipes, 2,310 item outputs.
- JSON Schema validation (Draft 2020-12): 0 errors.
- Compact runtime compiler: PASS; deterministic output matches `ForeverDBData.lua`.
- Runtime Lua file: 1,536,052 bytes.
- `pytest -q -p no:cacheprovider tests`: **126 passed**.
- `texluac -p` for all 9 addon Lua files: PASS.
- Nine current/relevant Lua model harnesses: PASS, including the new ForeverDB provider harness.
- The provider harness verifies exact build loading, mismatch refusal, market snapshot build compatibility, 12-profession availability, source classification, speculative/non-item exclusion, known recipe de-duplication and material indexing.
- Standalone importer 0.2.0 CLI `--help`, `normalize-capture`, `validate` and `compile-runtime`: PASS.

Older superseded model harnesses `market_ui_0_1_0_harness.lua` and `market_ui_0_4_1_harness.lua` were not used for acceptance: the former's stub lacks the current `SetFrameStrata` method; the latter asserts an older dropdown default and is superseded by passing 0.4.2/0.5.0 UI harnesses.

### Output packages

- Standalone addon: `ModuloMarket-0.5.3.zip`
  - 10 files; ZIP CRC PASS.
  - Bytes: 138,586.
  - SHA-256: `66570d4406a5e4a3304a04cf0851ad0c4d8f3101d43b0e2b9481cafe1854513b`.
- Developer importer: `ModuloMarket-ForeverDB-Importer-0.2.0.zip`
  - 16 entries; ZIP CRC PASS.
  - Bytes: 67,571.
  - SHA-256: `4f69c4ed1fe77352f39b66daf29fb31124dc3e5674c6e9e91ca61ca3c7407aaa`.
- GitHub source update: `ModuloMarket-GitHub-Update-0.5.3.zip`
  - Exact file inventory and fresh-extraction validation recorded in the handoff record delivered with the bundle.

### Important NOT RUN / UNKNOWN

- Forever 1.60.1.70862 in-client runtime verification: **NOT RUN**.
- Actual addon startup/load and `GetBuildInfo()` return formatting on the target Forever client: **NOT RUN**.
- Actual Market saved-snapshot build-gate behavior in the target client: **NOT RUN**.
- In-game attribution rendering: **NOT RUN**.
- Recipe-by-recipe comparison against the live Forever profession UI: **NOT RUN**.
- Runtime memory/load-time impact of the 1.5 MB generated Lua data file: **NOT RUN**.
- Windows PowerShell wrappers were not executed in this Linux environment; Python CLI equivalents passed.
- Trainer/vendor locations, acquisition costs, quest/drop details are retained in canonical JSON but are not yet presented in Market UI.
- Locale was absent from the capture and remains `null`.

## Runtime acceptance checklist

Keep the 0.5.3 runtime acceptance open until the user tests on Forever build `1.60.1.70862`:

1. Install the standalone addon ZIP and load into the target client; confirm no Lua errors.
2. Open Market; confirm the status reports ForeverDB build `1.60.1.70862` and the visible `ForeverDB.net` credit/URL.
3. Confirm all 12 profession filters are available and unlearned item crafts appear.
4. Confirm learned character recipes do not appear as duplicate future crafts.
5. Confirm observed/automatic, Classic-borrowed and unknown source categories remain distinct; speculative and non-item rows are not item crafts.
6. With a same-build Browse or Replicate snapshot, confirm reagent costs and profitability only appear when every required quantity and market price is known.
7. With a mismatched/unknown-build saved snapshot, confirm craft profitability is withheld while ordinary market item prices remain viewable.
8. Confirm the client remains responsive and memory/load impact is acceptable.

**Exit criterion:** player-visible acceptance passes on the exact target client with no Lua errors. Source tests and package success do not close runtime acceptance.
