# ModuloMarket 0.10.1 — Turn-Ins UX refinement runtime/capability audit

**Status:** SOURCE IMPLEMENTED · OFFLINE TESTS PASS (WITH UNCHANGED HISTORICAL BASELINE FAILURES) · FOREVER RUNTIME NOT RUN

## Canonical baseline and provenance

- Baseline archive: user-uploaded `ModuloMarket-GitHub-Update-0.10.0.zip`.
- Archive integrity: `ZipFile.testzip()` returned `None` (no CRC failure).
- Archive contents: 209 files under `modulo-market/`; all 209 paths agree exactly with `MANIFEST.json`.
- Baseline addon version: `Core.lua` `MM.version = "0.10.0"`, TOC `## Version: 0.10.0`, manifest `version = 0.10.0`, TurnInData `version = 0.10.0`.
- Baseline commit recorded in manifest provenance: `parentSha256 = 8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`.
- No other source archive or branch was mixed into this slice.

## Player problem and observable result

The separate Favor and Reputation columns consume width even though they describe one repeatable hand-in outcome. The selected inspector does not identify the cheapest fully priceable material option that drives completion cost. The generic Turn-In Notes paragraph is not selected-crate context, and Turn-In Economics values are oversized.

## Implementation

1. Merge the Favor and Reputation columns into one **Favor / Rep** column. Both values are retained: e.g. `5 F · 0 Rep`; unknown values remain `?` rather than becoming zero (`? F · 0 Rep` for Artisan with the current dataset).
2. Add a sort key for the combined reward column. Existing Favor / Reputation sort keys remain harmless for historical state; the visible header uses the combined key.
3. Keep the 0.10.0 `TurnInEngine.BuildRows` calculation unchanged. The selected inspector labels the chosen fully priceable alternative **BEST VALUE** and lists its exact ingredient names, quantities and line costs. Other alternatives remain listed separately.
4. Add a completion-cost hover tooltip showing the crate purchase price, best material option, required ingredient quantities / line costs and total completion cost. Missing crate price or complete material depth is explicitly reported as incomplete.
5. Replace the generic Turn-In Notes paragraph with the selected crate's known cash / Favor / reputation outcome. Unknown cash or Favor remains unknown; reported zero reputation is called out as no repeatable reputation.
6. Use standard `GameFontHighlight` values in Turn-In Economics. Switching tabs immediately restores `GameFontHighlightLarge` for other tabs, and selecting a non-Turn-Ins item also restores the original styling.
7. Keep all other tab data, calculations, market-snapshot compatibility gate, filters and scan behavior unchanged.

## Evidence and counter-evidence

- The baseline engine already selected the lowest-cost fully priceable accepted alternative and added the labelled crate's own price.
- This slice changes presentation and user explanation only; it does not change price inputs, arithmetic, reward-source confidence or market-depth semantics.
- The best-value marker identifies the cheapest material option only. If the crate's own listing is missing, the overall completion cost remains incomplete.
- The completion tooltip and inspector are source-implemented; mouse hit-testing, wrapping, scrolling, layout at player UI scale and actual live AH data still require client verification.

## Ownership, dependencies and Forever

- Owner: ModuloMarket.
- No new dependencies. No parent MODULO source changed.
- Retail runtime evidence: NOT RUN.
- FOREVER runtime acceptance: **NOT RUN**. The 0.10.0 audit's runtime limitations remain open.

## Tests and validation

The following results are recorded after executing the checks:
- ZIP CRC and manifest agreement: PASS.
- Focused 0.10.1 plus current Turn-In Python tests: **14 passed**.
- Lua syntax: **PASS** for all 11 addon Lua source files using `texlua` `loadfile` compilation.
- Existing Lua Turn-In harness: **PASS** — 30 unique crate definitions, 96 alternative bundles, crate + material arithmetic, cash/Favor/reputation returns, Artisan unknowns, insufficient-depth fail-closed, missing crate-price fail-closed, and one-time bonus separation.
- Full historical Python suite: **283 passed / 87 failed / 370 total**. The exact 87 failing test IDs are unchanged versus running the supplied 0.10.0 archive in the same environment (**276 passed / 87 failed / 363 total**). The seven added 0.10.1 regression tests pass; **zero new failing test IDs**.
- Final output ZIP: CRC check **PASS**; fresh extraction **PASS**; 212 archive files; 212 manifest entries; exact path inventory match; Core / TOC / TurnInData / manifest all report **0.10.1**.
- The handoff includes the final archive SHA-256; Forever client runtime remains **NOT RUN**.

## Acceptance / exit criteria

1. Confirm the five comparison columns and that all 30 crates remain listed.
2. Confirm both reward dimensions remain visible; unknown is `?`, and reported zero reputation stays `0 Rep`.
3. Sort by Favor / Rep and confirm known values sort without treating unknown as zero.
4. Hover completion cost on a crate with multiple alternatives; verify the exact best material option and every ingredient quantity.
5. Select the same crate; verify the inspector identifies the same best option and its costs.
6. Verify missing crate price and insufficient cheapest-price depth remain incomplete.
7. Verify Turn-In Notes update to the selected crate's known hand-in outcome.
8. Verify Turn-In Economics values match normal body text.
9. Switch through all six tabs and verify other tabs retain their original columns, calculations and inspector font sizing.

Release readiness does not mean Forever runtime verified.
