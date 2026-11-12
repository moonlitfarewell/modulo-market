# ModuloMarket Runtime Audit 0.7.3 — single-pass tooltip search warmup

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.7.2.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PENDING; FOREVER RUNTIME NOT RUN.

## Player problem and observable failure

After installing 0.7.2, the player reported that searching still repeatedly started new searches every 0.5–1 seconds. The screenshot showed a normal idle Crafts view after clearing the query; the prior 0.7.1/0.7.2 reports showed Waiting/Filtering cycling during tooltip search. The player also reported recipe names remained grey even though the selected-recipe status was red.

## Evidence and diagnosis

The 0.7.2 source deferred tooltip refreshes until the active view build and sort completed, but then started another complete `StartViewBuild()` pass. Since each pass could discover another batch of uncached item IDs, the catalogue could be rescanned repeatedly while tooltip data was still arriving.

A separate confirmed presentation mismatch existed in `MarketUI.lua`: the selected-recipe badge explicitly rendered Unknown red, but the Crafts row renderer used muted grey as the fallback for any status other than known, learnable or unlearnable.

Competing explanations for the recurring search cycle:
1. **Repeated full-pass refresh after tooltip event batches:** directly supported by the 0.7.2 source and matches the prior Waiting/Filtering sequence.
2. **Independent refresh from other view/filter lifecycle events:** possible but not needed to explain the repeated pass; remains a possible separate trigger if cycling persists after this change.

## Player problem / observable 0.7.3 result

A tooltip search should scan the catalogue once to identify unresolved item IDs, load their data in bounded batches, then run exactly one final full search pass using the populated tooltip cache. Individual item-data events must not restart the catalogue search. Search results should settle; item-data requests that never answer must time out and fail closed rather than loop indefinitely.

## Ownership and scope

- ModuloMarket remains a separate optional child addon depending on MODULO.
- MODULO 1.0.48 is unchanged and does not depend on ModuloMarket.
- No ForeverDB data, importer, credentials, auction snapshot, price formula, recipe acquisition evidence, or account/character crafting-scope logic is changed.
- Unknown and Not Learnable remain separate logical statuses and filters, but both render red in Crafts rows and the selected-recipe inspector.

## Implementation

- `MatchesSearch` now returns a pending result when tooltip data is unavailable, rather than treating it as a definitive non-match.
- The active view build records unresolved item IDs.
- After the initial catalogue pass, a bounded warmup queue requests missing tooltip data (20 item IDs per frame) and tracks each outstanding ID individually.
- Once the queue has been requested and all responses have arrived, one final `StartViewBuild()` pass evaluates the normalized tooltip cache.
- A 15-second warmup timeout marks unresolved item IDs unavailable for this search and proceeds once, preventing an endless wait/restart cycle.
- Tooltip item-data events no longer schedule a full-catalogue refresh.
- Crafts row status colour mapping now renders the fallback/Unknown status red, matching the inspector.

## Verification

- Focused 0.7.3 search regression tests: **8 passed**.
- Lua syntax: all **9 addon Lua files parsed successfully** with `texlua` and `loadfile`.
- Manifest JSON parse: PASS.
- Manifest version agreement: Core, TOC and manifest all **0.7.3**.
- Manifest inventory: **135 package files**, including the manifest and 0.7.3 audit; manifest `file_count` excludes the manifest itself (134).
- Full historical pytest suite: **171 passed, 54 failed**. The failing tests are retained legacy assertions pinned to earlier versions, removed seven-tab/My Crafts UI, pre-0.7.3 colour mapping, or superseded historical data/UI assumptions. They are not counted as passes and were not rewritten to manufacture a green suite.
- ZIP CRC: PASS (`ZipFile.testzip()` returned no bad member).
- Fresh extraction: PASS; exact recursive file comparison matched all 135 packaged files.
- Parent MODULO 1.0.48 source ZIP CRC: PASS; parent source is unchanged.
- Archive SHA-256 and exact byte count are recorded in the handoff.

## NOT RUN / UNKNOWN

- Forever 1.60.1 build 70888 runtime retest: NOT RUN.
- Actual in-client tooltip request completion, search responsiveness, tooltip-effect recall and timeout behavior: UNKNOWN until player retests.
- No claim of Forever runtime verification is made.

## Player acceptance

1. Search `heal` in Crafts; it must not repeatedly cycle Waiting/Filtering or restart the full search for each item-data event.
2. Search `spell damage`; tooltip-only effect matching remains available.
3. The search reaches a stable result count after the tooltip warmup and final pass.
4. Change the query while warmup is active; stale results must not overwrite the new query.
5. Clear search, switch tabs, change profession and switch Account/Character scope; no stale search may overwrite the new view.
6. Unknown and Not Learnable recipe names are both visibly red in the Crafts list and inspector, while their filter meanings remain distinct.
7. No Lua errors, freezes, taint or broken interactions.

**Exit status:** SOURCE IMPLEMENTED; OFFLINE VERIFICATION PENDING; FOREVER RUNTIME NOT RUN. Keep runtime defect open until player-visible acceptance passes.
