# ModuloMarket Runtime Audit 0.7.8 — reliable character profession snapshots

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.7.7.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; 4 FOCUSED PYTESTS PASS; LUA HARNESS PASS; 9-FILE LUA SYNTAX PASS; FULL HISTORICAL SUITE 187 PASS / 66 FAIL (LEGACY VERSION-PINNED OR SUPERSEDED ASSERTIONS); PACKAGE CHECKS PENDING; FOREVER RUNTIME NOT RUN.

## Player problem and observable result

The player reports Account Crafting and Character Crafting do not consistently recognise recipes learned by another character, and the successful profession snapshot chat message has not appeared recently. The supplied 0.7.7 diagnostic is contradictory: the active Cooking API reports skill 300/300, 26 filtered recipe IDs and Root Tea (`1249959`) as learned, while the persisted character summary reports Cooking 5/75 with only five recipes. The same report shows capture events registered and no capture active. This is evidence of stale/incomplete persisted state, not a colour-only rendering defect.

Acceptance outcome: opening a profession refreshes the current character's snapshot; a complete known-recipe list and current skill are saved; partial API metadata cannot replace the last complete snapshot; Account Crafting unions the saved positive evidence from characters.

## Competing hypotheses and distinguishing diagnostics

1. **Stale signature suppresses recapture.** The 0.7.7 engine skips a non-forced capture when the recipe-ID signature matches the saved record. A prior capture can therefore remain stale even after the profession window is reopened. The diagnostic's same-character persisted Cooking count (5) versus live Root Tea learned and 26 available IDs is consistent with this. A forced capture on `TRADE_SKILL_SHOW` distinguishes this: it must rebuild the same signature rather than skip it.
2. **Recipe metadata is temporarily unavailable during the one-pass capture.** The previous engine silently omitted IDs whose `GetRecipeInfo` returned nil, then committed the smaller result with the full ID signature. The new bounded retry counter and `recipe-info-unavailable` failure status distinguish this: if metadata becomes ready on a later frame, it is captured; if it does not, the previous snapshot remains untouched and diagnostics expose the unresolved count.
3. **Legacy profession skill data overwrites the active skill observation.** `ProfessionData` obtains profession ownership/skill through `GetProfessions` / `GetProfessionInfo`, while the diagnostic's active context comes from `C_TradeSkillUI`. The 5/75 versus 300/300 conflict is consistent with a lower-fidelity legacy value replacing the active skill. The new source priority is explicit and tested; runtime diagnostics must confirm 300/300 persists after a refresh.

## Implementation

- Force a fresh capture on every `TRADE_SKILL_SHOW`, including when the recipe-ID signature matches the saved snapshot.
- Retry temporarily nil recipe-info records across bounded update passes, up to four observations per ID.
- Never commit a capture with unresolved recipe metadata. Preserve the previous saved snapshot and print a concise failure message.
- Persist active profession skill/max skill from `C_TradeSkillUI` independently of recipe-list completion.
- Merge profession snapshots rather than replacing the complete per-character profession map. Legacy `GetProfessions` data cannot downgrade a skill already sourced from `C_TradeSkillUI`.
- On success, print `Saved <profession> snapshot: <count> known recipes, skill <skill>/<max>.` Diagnostics include last result, skipped captures, retry pass and unresolved count.

## Ownership, dependencies and scope

- ModuloMarket remains a separate optional child addon depending on MODULO. MODULO 1.0.48 is unchanged and does not depend on ModuloMarket.
- No Auctionator, Blizzard UI, ForeverDB, market pricing, auction snapshot or external API behavior is changed.
- No manual recipe reporting or player-maintained state is introduced. Capture remains automatic from client profession APIs.
- SavedVariables shape is extended additively with capture completeness/source fields and skill provenance; existing character keys and prior recipe records are preserved.

## Offline verification

- Focused regression tests: `python -m pytest -q tests/test_modulomarket_profession_capture_0_7_8.py` — **4 passed**.
- Combined current-slice checks: new capture tests plus 0.7.7 search/launcher tests excluding its historical version assertion — **9 passed, 1 deselected**.
- Lua syntax: all nine addon Lua files parse with `texlua` — **PASS**.
- Full historical suite: **187 passed, 66 failed**. Failures are dominated by old version-pinned assertions and obsolete UI/search contracts from superseded releases; they are not counted as acceptance for this slice and are not silently relabelled as passes.
- Lua harness simulates a stale Cooking 5/75 + five-recipe record, a live 300/300 profession with 26 known recipes, and one transiently unavailable recipe record.
- The test harness is a simulation, not client behavior evidence.

## Forever runtime acceptance — NOT RUN

1. Install the update and `/reload`.
2. Open the character that has Cooking 300/300 and Root Tea learned. Open the Cooking profession window and wait for the capture to finish.
3. Confirm chat reports a saved Cooking snapshot with the current skill and known recipe count. The count should reflect the learned recipes returned by the current API, not an assumed fixed number.
4. Run the ModuloMarket full diagnostics. Confirm Cooking is 300/300, the saved recipe count includes Root Tea, capture is inactive, and last result is `snapshot-saved`.
5. Close the profession window and `/reload`; run diagnostics again. Confirm the saved values persist.
6. Switch to Account Crafting and confirm Root Tea is recognised from this character's saved evidence. Switch to Character Crafting and confirm it remains recognised on this character.
7. Log into a second character with a different profession snapshot, open its profession, and confirm its data is preserved. Return to the first character and confirm the account union includes both characters' positive evidence.
8. Confirm no Lua errors, no repeated capture loop, no UI freeze and no unexpected recipe loss.

**Fallback/diagnostic rule:** if the chat success message does not appear, or diagnostics still show stale values, do not treat the issue as fixed. Capture the updated full diagnostics and keep the defect open. If recipe metadata remains unavailable after four observations, the old snapshot is deliberately preserved and the diagnostic failure reason is the next evidence to investigate.

**Exit status:** SOURCE IMPLEMENTED; OFFLINE HARNESS PASS; FOREVER RUNTIME NOT RUN. Player-visible acceptance remains OPEN until the above checks pass on build 70888.
