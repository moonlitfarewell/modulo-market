# ModuloMarket 0.6.1 — ForeverDB 1.60.1.70888 data refresh audit

**Release:** 0.6.1  
**Previous release:** 0.6.0  
**Scope:** recipe dataset refresh and targeted review-watch disposition only.  
**Parent:** MODULO 1.0.48, unchanged.  
**Target client:** WoW Forever 1.60.1 build 70888.  
**Runtime status:** FOREVER RUNTIME NOT RUN.

## Player problem and observable result

The 0.6.0 package used a ForeverDB recipe baseline from 1.60.1.70862 while the user's current Forever client was 1.60.1.70888. The new package bundles the verified 70888 capture as the active recipe source, so recipe structure can be reported as build-matched on that client. The independent auction snapshot exact-build gate remains intact; the recipe refresh does not make older market prices current.

## Evidence inspected

- Highest supplied child source bundle: `ModuloMarket-GitHub-Update-0.6.0.zip`, 101 ZIP entries, CRC PASS.
- Parent MODULO source: `MODULO-Project-Source-1.0.48.zip`, 506 ZIP entries, CRC PASS. Parent provenance hash in the child manifest remains `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`.
- New raw provider capture: `capture-20261112-113551.zip`, 49 entries, CRC PASS, 458,439 bytes, SHA-256 `48fdbd5da7cd33a2cfce977f0b7239be526cb81c305181fb7df4540e30123c5f`.
- Capture manifest says COMPLETE, ForeverDB.net, build 1.60.1.70888, 34 requests / 34 HTTP attempts, 12 professions, all pagination totals matched and no unknown pagination shape.
- Importer 0.2.3 offline `normalize-capture` and `validate` both exited 0. Result: 2,493 recipes / 12 professions; 2,310 item outputs; 183 non-item or unknown outputs; 143 speculative records retained in canonical data and excluded by runtime compiler policy.
- `compile-runtime` generated `AddOns/ModuloMarket/ForeverDBData.lua` from the normalized 70888 canonical file. Runtime metadata contains exact client build, provider URL, visible credit text, retrieval time and source capture manifest hash.
- No API request was made during this review; the uploaded raw capture was used offline. No API key is included in the package.

## Data comparison

The previous 70862 canonical file is retained unchanged. Comparing profession-scoped `(profession, recipe_id)` identities:

- 2,493 old records and 2,493 new records.
- 12 professions unchanged.
- No recipe IDs added or removed.
- 200 recipe records have at least one normalized field change.
- 185 records changed acquisition-source data.
- 28 records changed provider metadata.
- One record changed skill thresholds. These field counts overlap.
- Recipe names, categories, output kind, output item identity/quantity and reagent groups are unchanged across the comparison.

The only skill change is Blacksmithing Coarse Grinding Stone (recipe 3326): green 62→70 and grey 75→90. Orange/yellow remain 50; the separate orange Classic threshold remains 75 with `CLASSIC_BORROWED` evidence. The prior review watch for this skill-up field is retired because the new capture supplies the changed thresholds. Three unchanged hotfix-watch records remain review flagged: Journeyman Campfire (1283400), Minor Arcane Elixir (1245246), Iron Grenade (3962). No other record is promoted from UNKNOWN or CLASSIC_BORROWED to FOREVER_OBSERVED merely because its provider metadata changed.

Full comparison and disposition: `docs/FOREVERDB-DATA-REVIEW-2026-11-12.md`.

## Implementation and ownership

Changed files are limited to the ModuloMarket child repository: version metadata, active generated `ForeverDBData.lua`, new canonical 70888 JSON, ProfessionData's targeted review-watch entry for recipe 3326, tests, README/data README, review document and audit. The historical 70862 canonical file remains. MODULO 1.0.48 source and dependency direction are unchanged. ModuloMarket remains optional and depends on MODULO; MODULO does not depend on ModuloMarket.

The recipe data build is now 1.60.1.70888. `ProfessionData.lua` still requires an identifiable client build. The saved Browse/Replicate auction snapshot must separately match the current client build before auction prices are joined to recipe data. Three hotfix review flags remain advisory.

## Risks and explicit limitations

- A ForeverDB response is provider data, not an independent project observation of every live in-game recipe, trainer, vendor, source or current availability.
- Acquisition-source changes are retained with their per-row evidence labels. They do not imply all listed source edges are FOREVER_OBSERVED.
- Three reported hotfix-linked records remain unchanged and review flagged.
- Auction pricing is still unavailable if the player has no exact-build 70888 snapshot.
- FOREVER runtime acceptance is NOT RUN. Offline tests, compilation and static checks do not prove target-client behavior.

## Offline verification

- Canonical normalize: PASS (2,493 records, 12 professions).
- Canonical validate: PASS.
- Runtime compile: PASS.
- Full Python regression suite: 163 passed.
- Lua provider harness: included in suite and passed with 70888 match plus 70889 mismatch scenario; verifies exact-build market snapshot gate and three remaining review flags.
- Nine addon Lua files parse with `texlua` loadfile checks (recorded in package build verification).
- ZIP CRC, manifest inventory, version agreement and fresh extraction/retest: PASS (recorded after package build).

## Player acceptance required

1. On client build 70888, `/mmversion` reports ModuloMarket 0.6.1 and ForeverDB data 1.60.1.70888 as build matched.
2. Market reports three remaining hotfix review records.
3. Coarse Grinding Stone shows green 70 / grey 90; orange remains Classic-borrowed.
4. Journeyman Campfire, Minor Arcane Elixir and Iron Grenade remain Review.
5. Without a 70888 market snapshot, craft economics remains withheld. A 70862 snapshot must be rejected.
6. All seven tabs, recipe list, reagent details, acquisition labels and UI remain functional with no Lua errors.

**FOREVER RUNTIME: NOT RUN. Release readiness does not imply Forever runtime verified.**
