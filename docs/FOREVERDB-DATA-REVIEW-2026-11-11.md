# ForeverDB raw capture review and field mapping — 2026-11-11

**Project:** ModuloMarket  
**Addon baseline:** 0.5.2  
**Integration slice:** 0.5.3  
**Provider:** [ForeverDB.net](https://foreverdb.net)  
**Capture build:** `1.60.1.70862`  
**Capture window:** `2026-11-11T12:27:21Z` to `2026-11-11T12:27:55Z`  
**Status:** raw capture verified; canonical adapter and compact runtime data generated; Forever runtime NOT RUN.

## 1. Player problem and observable result

Market 0.5.2 can capture only recipes the character has learned and opened in the profession UI. Its optional LibProfessionDB provider supplies a structural unlearned-recipe catalogue, but its acquisition-source and skill evidence may be Classic-borrowed. Unknown output quantity or incomplete reagent data must not produce invented profitability.

The 0.5.3 source result is a build-gated ForeverDB catalogue that contributes unlearned item recipes to the existing item/material/economics index. On the matching client build, known character recipes remain authoritative, speculative recipes are excluded, and future/borrowed/unknown source categories remain separate.

## 2. Exact input evidence and integrity

### Uploaded inputs

- `ModuloMarket-GitHub-Update-0.5.2.zip`: 69 entries; ZIP CRC PASS.
- `ModuloMarket-0.5.2.zip`: 9 entries; ZIP CRC PASS.
- `ModuloMarket-ForeverDB-Importer-0.1.1.zip`: 10 entries; ZIP CRC PASS.
- `capture-20261111-122719.zip`: 49 ZIP entries; ZIP CRC PASS.

The standalone addon ZIP and the GitHub update's `AddOns/ModuloMarket/` Lua/TOC files are byte-identical.

The repository manifest, TOC and `Core.lua` agree at 0.5.2 before the change. The repository manifest inventory contains 69 files. Its parent MODULO provenance identifies 1.0.48, which remains unchanged.

### Capture manifest

- Status: `COMPLETE`.
- Provider: ForeverDB.net.
- Client build: `1.60.1.70862`.
- Requests: 34; manifest response inventory: 34.
- Profession slugs: all 12 documented professions.
- Every captured response's byte count and SHA-256 match the manifest.
- Profession page counts and actual nested `data.recipes` counts match every reported total.
- Actual recipes: 2,493.

The capture does not contain an API key. It has no locale field; locale is retained as `null`, not inferred.

## 3. Actual raw response shape

Every response uses `{data, meta}`.

- `/meta`: `data.build` and global counts.
- `/professions`: `data` is the 12-row profession index.
- `/professions/{slug}`: `data` is a profession object with `ranks`, profession-level `trainers`, and a paginated `recipes` array. Pagination metadata is in `meta.total`, `meta.limit`, `meta.offset` and `meta.next`.

The raw profession recipe array is at `data.recipes`, not directly at `data`. The first 100 records appear at offset 0, followed by explicit offset pages. The 0.5.3 normalizer reads only that observed shape and fails closed on a mismatched page, build, hash, count or profession identity.

## 4. Capture totals

| Profession | Records |
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

Additional observed counts:

- 2,310 records have an item output (`makes.itemId`).
- 183 have no item output: 170 classify as Enchanting enchantment services from their category; 13 remain `unknown` (including Season of Discovery records).
- Every item-output record in this capture has a positive `makes.count`; there are no missing item-output counts.
- No record exposes separate output minimum/maximum fields in this capture; no output range is inferred.
- 8,416 reagent rows are present. Each row has `itemId`, `name`, `count`. No optional/alternative flags are present.
- 143 recipes are marked speculative.
- 70 recipes have `learnedFrom.known=false`.
- Orange skill threshold source: 1,838 `client`, 404 `classic`, 251 absent/unknown.
- 33 recipes are marked automatic.

## 5. Evidence mapping

Evidence is assigned per claim, not merely from the provider name.

### Recipe structure and quantities

- `spellId`, name, category, item output, `makes.count`, reagent item IDs/counts, ranks and profession skill-up thresholds are mapped as `FOREVER_CLIENT` because the API describes these recipe structures as coming from the Forever client and identifies build `1.60.1.70862`.
- `makes.count` is retained as an exact captured count with `quantity_min == quantity_max`. It is not represented as a random range.
- Every raw reagent row becomes one required, single-choice reagent group because the captured API provides a flat reagent list and no optional/alternative marker. This is the provider's captured recipe reagent list; the adapter does not synthesize alternatives.
- If a future capture omits a count, the normalizer leaves quantity null. The economics engine then withholds profit.
- 170 of the 183 no-output rows are Enchanting categories with “enchant” in the category name and are classified as `enchantment`; remaining no-output rows are `unknown`. No fake item output is created.

### Skill

- `skill.orangeSource == "client"` → orange threshold `FOREVER_CLIENT`.
- `skill.orangeSource == "classic"` → orange threshold `CLASSIC_BORROWED`.
- Missing `orangeSource` → `UNKNOWN`.
- Yellow/green/grey client thresholds are kept as client skill-up thresholds.
- `sources.learnAtSkill` and `requiredLevel` are preserved as provider metadata; neither is silently promoted to a trainer learning requirement.
- Classic orange thresholds are not used as a character-level or trainer requirement.

### Acquisition sources

- Trainer rows with `seenInForever=true` and not inferred → `FOREVER_OBSERVED` acquisition edge.
- Trainer rows with `seenInForever=false` → `CLASSIC_BORROWED`.
- Trainer rows marked `inferred=true` → acquisition edge `UNKNOWN`, even if the NPC itself is observed. Entity observation and the inferred recipe-teaching edge remain separate.
- Vendor rows with `seenInForever=true` → `FOREVER_OBSERVED`; false → `CLASSIC_BORROWED`.
- Vendor `price` is retained as copper per purchase/stack; `stack` and `pricePerItem` are retained separately. Non-gold `costs`, limited stock and reputation faction are preserved.
- `trainerCost` and `trainerCostSource` are retained separately. A Forever-observed price is not conflated with a Classic price.
- `seenAtForeverTrainers` names are preserved as direct `FOREVER_OBSERVED` trainer observations.
- Drop rows have no per-row `seenInForever` signal in this capture and are `UNKNOWN`.
- Quest rows have `inForeverClient`, which establishes quest presence in client data but does not by itself prove that this recipe/quest acquisition edge was observed. The acquisition edge remains `UNKNOWN`.
- Recipe-item rows are retained as recipe-item sources, but where no vendor/drop/observation is supplied the acquisition path remains `UNKNOWN`.
- `learnedFrom.known` is preserved as a provider field but is not used alone to claim Forever observation.

### Speculation and availability

- `speculation` and `speculationReasons` are preserved in canonical data.
- Speculative records are excluded from the runtime item-craft catalogue.
- A non-speculative item recipe is classified as confirmed only when it has a direct Forever-observed trainer/vendor/observation source or is marked automatically learned.
- Classic-only source rows become borrowed candidates.
- Recipes with only unknown/unverified acquisition evidence become unknown-source candidates.
- Mixed observed and Classic rows are treated as confirmed only through their observed source; the compact runtime classification does not promote the Classic row.

## 6. Canonical model and generated runtime

New importer command:

```text
python tools/foreverdb_importer/market_data_importer.py normalize-capture <capture-folder> --output data/ForeverDB-Canonical-1.60.1.70862.json
```

The normalizer verifies the capture is COMPLETE, checks all response hashes/byte counts, cross-checks build metadata, verifies all 12 profession slugs, checks pagination totals, rejects duplicate recipe IDs per profession and maps the observed raw shape into canonical v1.

New compact runtime compiler:

```text
python tools/foreverdb_importer/market_data_importer.py compile-runtime data/ForeverDB-Canonical-1.60.1.70862.json --output AddOns/ModuloMarket/ForeverDBData.lua
```

The full canonical JSON retains trainer/vendor/drop/quest/recipe-item detail and field provenance. The compact Lua file includes only current runtime-consumer fields to avoid loading all location and source detail into the addon. Full trainer/vendor location and price presentation is not yet implemented.

The addon:
- loads `ForeverDBData.lua` before `ProfessionData.lua`;
- checks `GetBuildInfo()` against exact dataset build `1.60.1.70862` and requires the saved market snapshot's `clientVersion.clientBuild` to match the current client before recipe economics can use its prices;
- blocks imported data on unknown/mismatched client build;
- excludes speculative records and non-item outputs from item-craft economics;
- de-duplicates learned character recipes by profession/recipe ID and profession/output/normalized name;
- indexes output and reagent/material relationships;
- keeps observed/automatic, Classic-borrowed and unverified sources distinct;
- shows `Data from ForeverDB.net — https://foreverdb.net` in the Market window.

The existing optional LibProfessionDB adapter remains a fallback only when no bundled ForeverDB dataset is present. A present but build-mismatched ForeverDB dataset is not silently replaced by another source.

## 7. Competing hypotheses and counter-evidence

1. **Hypothesis:** The profession endpoint is directly a recipe array and can be parsed from `data`.
   - **Counter-evidence:** actual capture shows `data` is a profession object and recipes are nested at `data.recipes`. A direct-list parser would find zero recipes.
   - **Resolution:** normalize only the observed nested structure and verify every page against manifest totals.

2. **Hypothesis:** Every listed acquisition source is confirmed on Forever because the provider is ForeverDB.
   - **Counter-evidence:** the provider explicitly labels Classic-derived trainers/vendors unless `seenInForever`; drop/quest rows in this capture lack a per-row observation flag; some trainer rows are inferred.
   - **Resolution:** per-row evidence mapping above; no blanket FOREVER_OBSERVED label.

3. **Hypothesis:** `makes.count` can be treated as a variable yield range.
   - **Counter-evidence:** this capture exposes one `count` and no separate min/max keys.
   - **Resolution:** exact fixed count only; no random range is invented.

4. **Hypothesis:** A recipe's orange threshold or `learnAtSkill` is its trainer learning requirement.
   - **Counter-evidence:** the API distinguishes orange client/classic threshold source and learning source fields; project contract keeps skill-up colour separate from trainer requirement.
   - **Resolution:** thresholds remain threshold metadata; no `requiredSkill` is generated from them.

## 8. Dependencies, scope and risks

- No new WoW runtime dependency.
- No API key, HTTP client or network access in the addon.
- No MODULO source or dependency change.
- No Auctionator or ProfessionMaster dependency/private SavedVariables access.
- Existing optional LibProfessionDB remains optional.
- Compact data file adds approximately 1.5 MB of Lua source and a larger runtime table; load-time/memory impact needs target-client observation.
- `GetBuildInfo()` exact formatting is source-harness-tested but must be checked on Forever runtime.
- The capture has no locale field; locale remains unknown.
- No actual recipe-by-recipe comparison against the live profession window has yet been performed.
- The addon does not yet display trainer/vendor locations, costs, quests or drops to players; the canonical data retains them for later work.

## 9. Validation and acceptance

Offline checks include:
- raw ZIP CRC and all response hashes/byte counts;
- actual recipe totals against all profession reports;
- canonical adapter tests for evidence, counts, missing outputs, speculative records, hash failure, partial capture and duplicate IDs;
- canonical JSON Schema validation;
- compact runtime compiler output;
- Lua syntax and a provider harness for exact-build load, mismatch refusal, 12-profession indexing, source classification, speculative/non-item exclusion, known-recipe de-duplication and material relationships;
- complete Python test suite and package/fresh-extraction validation.

**Forever runtime acceptance: NOT RUN.** Player acceptance remains open until the user tests the 0.5.3 addon on Forever build `1.60.1.70862`, confirms Market loads without Lua errors, all profession filters and recipe relationships behave correctly, known recipes are not duplicated, speculative/unknown/borrowed statuses are accurate, profitability is withheld for incomplete prices/quantities, and the ForeverDB credit is visible.
