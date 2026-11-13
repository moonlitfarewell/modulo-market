# ModuloMarket Runtime Audit 0.8.0 — Root Tea status integrity

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.7.9.zip`  
**Baseline:** supplied 0.7.9 archive; GitHub `main` at 0.7.9 commit `ab6fb51bfb2f0bf3439f5d79aad5bb4bef4c4a76`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; FOCUSED TESTS 21 PASS; LUA SYNTAX 9 FILES PASS; PROFESSION CAPTURE HARNESS PASS; FULL HISTORICAL SUITE 199 PASS / 65 LEGACY OR SUPERSEDED FAIL; FOREVER RUNTIME NOT RUN.

## Player problem and observable result

Root Tea produces four expected outcomes:

| Character knowledge | Crafting scope | Expected result |
|---|---|---|
| Knows Root Tea | Character | `KNOWN` |
| Knows Root Tea | Account | `KNOWN` |
| Does not know Root Tea | Account | `KNOWN` if another account character has positive learned evidence |
| Does not know Root Tea | Character | Must not be `KNOWN` |

The player-visible contradiction was a green `KNOWN` badge/row alongside “Profession not learned”. The row, selected-recipe badge, filters, economics index and best-craft explanation must not promote missing or invalid status into a positive knowledge claim.

## Evidence and competing explanations

The 0.7.9 source already:
- copies future recipe candidates before assigning scope-derived status;
- permits only `recipe.learned == true` to be positive recipe evidence;
- stores per-profession snapshot schema 2, generation and addon build;
- excludes stale-schema snapshots from positive learned status until automatic recapture;
- keeps account and character recipe sources separate.

The remaining direct defect was in `MarketUI.lua`: six downstream uses defaulted missing `craftSourceStatus` to `"known"` (economics index, view construction, role filtering, craft filters, row rendering and selected detail badge). A separate best-craft explanation treated every status other than the obsolete literal `"future"` as “Recipe known by this character”.

Competing hypotheses:
1. **Presentation fail-open:** missing/invalid status reaches MarketUI and one of those fallbacks promotes it to `known`. This is directly demonstrated by the 0.7.9 source.
2. **Scope/data lifecycle contamination:** a stale selected item or cached object carries status from the other scope. The 0.7.9 producer-side copy and evidence rules address the known shared-object path, but repeated two-character in-client switching remains necessary to exclude another lifecycle defect.

## Change in 0.8.0

- Added one `GetCraftSourceStatus()` normalizer. It permits only `known`, `learnable`, `unlearnable` and `unknown`; missing or invalid values become `unknown`.
- Replaced all six fail-open status defaults with the normalizer.
- Corrected best-craft explanatory text: only explicit `known` says “Recipe known by this character”; learnable, unlearnable and unknown have separate non-positive explanations.
- No snapshot schema change. Schema 2, snapshot generation/build provenance and automatic capture on profession open remain unchanged.
- No manual recipe reporting or manual cooldown/state entry was added.

## Ownership, dependencies and scope

- Only the optional ModuloMarket child addon changes.
- Parent MODULO 1.0.48 is unchanged. ModuloMarket continues to depend on MODULO; MODULO does not depend on ModuloMarket.
- No ForeverDB dataset, market price logic, Auction House snapshot gate, external addon, API request, credential, SavedVariables schema or optional dependency changed.
- Existing 0.7.9 source and historical audit records are preserved.

## Verification

- Focused regression command:
  `python -m pytest -q tests/test_modulomarket_0_8_0_status_integrity.py tests/test_modulomarket_0_7_9_scope_isolation.py tests/test_modulomarket_profession_capture_0_7_8.py tests/test_modulomarket_0_7_7_debounced_search_and_sell_launcher.py`
  — **21 passed**.
- The three current-release version-alignment assertions in the existing focused tests were advanced from 0.7.9 to 0.8.0; no historical behavior assertions were removed.
- Lua syntax: all nine `AddOns/ModuloMarket/*.lua` files checked with `texluac -p` — **PASS**.
- Existing profession capture Lua harness:
  `texlua tests/profession_capture_0_7_8_harness.lua` — **PASS**.
- Full historical Python suite: **199 passed, 65 failed**. The 65 failures are existing legacy version-pinned or superseded source/UI-contract assertions across older release tests. They are retained and not represented as passes; this slice adds six passing focused tests over the 0.7.9 baseline.
- These checks are offline source/test evidence. They do not prove Forever client runtime behavior.

## Forever runtime acceptance — NOT RUN

On Forever 1.60.1 build 70888:

1. On the character that knows Root Tea, open Cooking and allow automatic capture to finish.
2. Character Crafting: Root Tea must be `KNOWN`.
3. Account Crafting: Root Tea must be `KNOWN`.
4. Log into the character that does not know Root Tea. Open Cooking and allow automatic schema-2 capture to finish.
5. Character Crafting: Root Tea must not be `KNOWN`; its row, detail badge and best-craft explanation must agree with the profession-not-learned/unknown state.
6. Account Crafting: Root Tea may be `KNOWN` from the other character's saved positive learned evidence.
7. Switch repeatedly between scopes and reopen/select Root Tea. No status may leak from account scope into character scope.
8. Confirm no Lua errors, no freeze, both characters' snapshots persist across reload, and diagnostics show current schema/generation.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; LUA SYNTAX PASS; PROFESSION CAPTURE HARNESS PASS; FULL HISTORICAL SUITE 199 PASS / 65 LEGACY OR SUPERSEDED FAIL; FOREVER RUNTIME NOT RUN. Player-visible acceptance remains OPEN until the two-character test passes on build 70888. Player-visible acceptance remains OPEN until the two-character test passes on build 70888.
