# ModuloMarket 0.6.5 — acquisition-source integration runtime audit

**Previous child update:** `ModuloMarket-GitHub-Update-0.6.4.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48 (unchanged)  
**Scope:** preserve and display ForeverDB acquisition-source detail for known and unlearned recipes.  
**Forever runtime status:** <strong>NOT RUN</strong>.

## 1. Player problem and observable result

The player selected recipes whose inspector said the acquisition source was unknown or merely recorded, despite ForeverDB's canonical data already containing trainer/vendor/recipe-item/drop/quest records. The 0.6.4 compiler discarded those details and retained only broad recipe-level source flags.

0.6.5 now preserves the detailed records in the generated runtime data, indexes them by profession/recipe ID (including known recipes), displays up to three prioritized records in the selected-recipe inspector, and exposes the complete list in the recipe hover tooltip.

## 2. Evidence and counter-evidence

- Active canonical input: `data/ForeverDB-Canonical-1.60.1.70888.json`, client build `1.60.1.70888`; unchanged in this slice.
- Canonical records: 2,493 profession recipes; 10,369 acquisition-source rows.
- Evidence distribution: 4,137 `FOREVER_OBSERVED`; 2,292 `CLASSIC_BORROWED`; 3,907 `UNKNOWN`; 33 `FOREVER_CLIENT`.
- Source-type distribution: 5,234 trainer; 1,580 vendor; 1,813 recipe item; 1,629 drop; 80 quest; 33 automatic.
- The canonical provider evidence is not independent MODULO runtime observation. Provider labels are retained, not promoted.
- Unknown drop/quest links remain unknown. A quest existing in the Forever client is not proof that the recipe-to-quest link was observed. An observed NPC is not proof that the NPC teaches the recipe.
- Mixed evidence is retained per source row; aggregate craft status is not used as a substitute for individual source evidence.

## 3. Player problem and implementation acceptance

| Area | Implementation | Offline evidence | Runtime acceptance |
|---|---|---|---|
| Importer/compiler | Preserve reviewed source fields and trainer cost evidence | Python source-contract tests; generated runtime inspection | NOT RUN |
| Runtime index | Index source rows by profession ID + recipe ID, including already-known recipes | Lua provider harness | NOT RUN |
| Known recipe de-duplication | Known recipe still appears once; source details retrievable separately | Lua provider harness | NOT RUN |
| Inspector | Up to three prioritized sources with NPC/location/vendor details | UI source-contract test | NOT RUN |
| Recipe tooltip | Full source list and evidence labels | UI source-contract test | NOT RUN |
| Evidence safety | Unknown, Classic-borrowed and inferred links remain visibly unconfirmed | Python source-contract test and Lua harness | NOT RUN |

## 4. Ownership, dependencies and compatibility

- Only the optional ModuloMarket child repository changes.
- Parent MODULO 1.0.48 is unchanged. ModuloMarket depends on MODULO; MODULO does not depend on ModuloMarket.
- No new addon dependency, API request, API key, SavedVariables schema change, market snapshot gate change or auction-house action.
- Exact source build `1.60.1.70888` and existing exact-current-client market snapshot gate remain unchanged.
- Canonical source JSON and historical `1.60.1.70862` canonical file remain unchanged.

## 5. Risks and scope

- Generated `ForeverDBData.lua` grows from 1,536,052 bytes to 5,035,631 bytes. In-client load time and memory impact are UNKNOWN pending Forever runtime observation.
- Inspector shows up to three source rows. Full source list is in the recipe tooltip.
- Vendor currencies/costs are shown as supplied by the canonical data; availability and current in-game prices are not independently revalidated.
- Source coordinates and locations are provider data, not a live waypoint or proof of current NPC placement.
- No manual source reporting or player-maintained source state was added.

## 6. Verification performed

- Focused regression command:
  `pytest -q tests/test_modulomarket_acquisition_sources_0_6_5.py tests/test_foreverdb_importer.py tests/test_foreverdb_raw_adapter.py tests/test_modulomarket_foreverdb_0_6_1_refresh.py tests/test_modulomarket_ui_0_6_3_inspector_footer.py tests/test_modulomarket_ui_0_6_4_layout.py`
  Result: **39 passed** (includes importer, source integration, provider refresh, UI regression and version-reporting tests).
- Lua provider harness:
  `texlua tests/foreverdb_provider_0_5_3_harness.lua AddOns/ModuloMarket/ForeverDBData.lua AddOns/ModuloMarket/ProfessionData.lua`
  Result: **PASS**. Includes known-recipe source lookup, no duplicate known recipe, source-row evidence preservation, build gating and baseline behavior.
- Lua syntax:
  `texlua /tmp/check_lua_syntax.lua AddOns/ModuloMarket/*.lua`
  Result: **9/9 PASS**. The temporary checker loads each addon Lua file with `loadfile`; it does not execute WoW APIs.
- Full historical Python suite: **156 passed, 29 failed**. Failures are legacy source-contract assertions hard-coded to historical 0.6.3/0.6.4 versions or prior UI implementation details. This is not reported as a full-suite pass. The 0.6.4 baseline audit recorded 149 passed / 32 failed. Two milestone assertions and the version-reporting harness were advanced to 0.6.5; the remaining failures are older source-contract assertions pinned to 0.6.3-era versions/layouts. The full-suite failure count is lower than the 0.6.4 baseline; no new full-suite failure was introduced by this slice.
- Forever client runtime: **NOT RUN**.

## 7. Acceptance criteria for player test

1. On Forever build 70888, open My Crafts and select a known recipe that has a ForeverDB acquisition record. Verify the source details appear without duplicating the recipe row.
2. Open All Crafts and select an unlearned recipe with an observed trainer/vendor record. Verify NPC name, faction, zone and vendor price where present.
3. Hover the recipe name and verify all source rows are shown, including more than the three inspector rows where applicable.
4. Select a recipe with both observed and Classic-borrowed routes. Verify each route has its own evidence label.
5. Select a recipe with an unknown quest/drop relationship. Verify it remains UNKNOWN/UNVERIFIED even if a quest or NPC is present in the client.
6. Verify limited-stock, reputation and currency-cost details where supplied.
7. Check load time/memory, all seven tabs, profession filters, row selection, hover tooltips and absence of Lua errors.

**Exit status:** SOURCE IMPLEMENTED; OFFLINE VERIFIED for focused tests/harness; FOREVER RUNTIME NOT RUN. Do not mark the capability runtime accepted until the player-visible checks pass on the relevant Forever client.
