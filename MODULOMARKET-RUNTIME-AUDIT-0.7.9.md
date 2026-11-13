# ModuloMarket Runtime Audit 0.7.9 — snapshot schema and crafting-scope isolation

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.7.8.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; FOCUSED TESTS PASS; LUA SYNTAX PASS; FULL HISTORICAL SUITE 193 PASS / 65 FAIL (LEGACY VERSION-PINNED OR SUPERSEDED ASSERTIONS); FOREVER RUNTIME NOT RUN.

## Player problem and observable result

The player demonstrated that Root Tea was correctly `KNOWN` in Account Crafting because another character had learned it, but was incorrectly `KNOWN` in Character Crafting for a character that had not learned it. The selected-recipe inspector simultaneously reported `Profession not learned`. This is a contradictory status: the profession summary was character-scoped, while the recipe badge was carrying a stale positive marker.

Acceptance outcome: Account Crafting may show Root Tea as `KNOWN` from the character that learned it. Character Crafting must not show it as `KNOWN` unless the logged-in character's own current-schema learned-recipe snapshot contains it. Switching scope repeatedly must not transfer derived status between catalogues.

## Competing hypotheses and distinguishing evidence

1. **Shared future-candidate mutation:** `MarketUI.GetAllCraftSources()` obtained cached candidate objects from `ProfessionData.GetAllFutureRecipes()` and assigned `craftSourceStatus` directly onto those shared objects. Account and character catalogues are rebuilt from the same cached candidates. A `KNOWN` marker written while building one scope could survive into the other scope. `ProfessionData.GetRecipeLearningStatus()` also trusted `craftSourceStatus == "known"`, allowing a presentation marker to become positive learned evidence. Source inspection confirms this complete propagation path.
2. **Stale selected-recipe inspector object:** the inspector could retain an old selected item after the scope changed, independently of the catalogue. This remained a plausible secondary UI lifecycle concern, but the shared-candidate mutation is sufficient to explain a future recipe becoming `KNOWN` in a later scope build. The source fix removes this contamination at the producer and status-helper boundaries; in-client retest remains necessary to rule out any separate stale-selection issue.

## Change

- `MarketUI.GetAllCraftSources()` now copies each cached future candidate before assigning scope-derived status. It never mutates `ProfessionData`'s shared future-candidate objects.
- `ProfessionData.GetRecipeLearningStatus()` now treats only `recipe.learned == true` as positive learned evidence. A derived `craftSourceStatus` presentation value cannot promote an unlearned candidate to `KNOWN`.
- Learned recipe snapshots now carry a per-profession `snapshotSchemaVersion` (currently 2), monotonically increasing `snapshotGeneration`, and `snapshotBuild` addon-version provenance.
- `Recipes.GetAllRecipes()` accepts only learned recipe records with the current schema. Older snapshots are retained in SavedVariables but cannot assert `KNOWN` until that character's profession is automatically recaptured.
- Incomplete captures may merge the previous recipe set only when that previous snapshot already uses the current schema. Old-schema recipes are never silently promoted by a partial migration capture.
- Diagnostics now show the required schema and each current character profession snapshot's schema, CURRENT/STALE state, generation, addon build, recipe count and capture time.
- Schema version changes only when the meaning/shape of learned-recipe evidence changes. UI-only addon releases do not force profession recapture.

## Ownership, dependencies and scope

- Only the optional ModuloMarket child addon changes. Parent MODULO 1.0.48 is unchanged.
- ModuloMarket continues to depend on MODULO; MODULO does not depend on ModuloMarket.
- No external addon, API request, credential, ForeverDB data, market price calculation, auction snapshot gate or manual recipe-reporting path changed.
- Profession capture remains automatic from the client's profession APIs.

## Verification

- Focused regression suite: `python -m pytest -q tests/test_modulomarket_0_7_9_scope_isolation.py tests/test_modulomarket_profession_capture_0_7_8.py tests/test_modulomarket_0_7_7_debounced_search_and_sell_launcher.py` — **15 passed**.
- Lua syntax: all nine `AddOns/ModuloMarket/*.lua` files with `texluac -p` — **PASS**.
- Existing profession capture Lua harness: `texlua tests/profession_capture_0_7_8_harness.lua` — **PASS**.
- Full historical Python suite: **193 passed, 65 failed**. The failures are legacy version-pinned assertions and superseded UI/search contracts from earlier releases. They are recorded, not reclassified as passes; focused current-slice checks above are the acceptance evidence for this change.
- These tests and harnesses are offline/source evidence, not Forever client runtime evidence.

## Forever runtime acceptance — NOT RUN

1. Install 0.7.9 and `/reload`.
2. On the character that knows Root Tea, open Cooking. Confirm the automatic snapshot message appears and diagnostics report schema 2, generation 1 or higher, current addon build, and Root Tea in that character's learned snapshot.
3. Switch to Account Crafting. Root Tea must show `KNOWN`.
4. Switch to Character Crafting on that same character. Root Tea must remain `KNOWN`.
5. Log into the character that does not know Root Tea. Before opening Cooking, its old-schema snapshot must be reported `STALE — recapture required` and Root Tea must not be `KNOWN` from another character's record.
6. Open Cooking on that character and allow the automatic capture to finish. Diagnostics must report schema 2 and a new generation. Root Tea must remain unlearned/not known in Character Crafting.
7. Switch repeatedly between Account Crafting and Character Crafting. Account Crafting may union the first character's positive evidence; Character Crafting must only use the logged-in character's learned records.
8. Confirm the recipe badge and profession summary agree, no Lua errors occur, no UI freeze occurs, and both characters' saved snapshots remain intact after relog/reload.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; LUA SYNTAX PASS; FOREVER RUNTIME NOT RUN. Player-visible acceptance remains OPEN until the two-character test above passes on build 70888.
