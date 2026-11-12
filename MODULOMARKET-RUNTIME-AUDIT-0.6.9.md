# ModuloMarket Runtime Audit 0.6.9 — character-aware recipe status and Economics

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.6.8.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS AND LUA SYNTAX PASS; FOREVER RUNTIME NOT RUN.

## Player problem and observable result

The player requested a single slice to consolidate My Crafts and All Crafts, add character-aware recipe states to Crafts and Materials, add Skinning gathering classification, and make Economics meaningfully different from All Items.

0.6.9:
- Replaces the two craft tabs with one Crafts tab containing known and supported unlearned recipes.
- Shows Known by you in green, Learnable in gold, Not learnable in red, and Unknown in neutral grey.
- Uses native profession ownership and skill APIs when available. It does not infer that a profession is absent from a partial saved recipe capture.
- Shows current profession skill and required learning skill in the selected recipe panel where data exists.
- Applies the same learning-state filters to Materials.
- Adds a conservative core Skinning leather/hide progression mapping.
- Makes Economics show cheapest price, craft cost, recent saved price change, total units and best craft profit, with relationship filters.

## Character status rules

`GetProfessions` and `GetProfessionInfo` are queried with guarded calls. The returned skill-line ID is used to map profession ownership and current skill. If the native list cannot be read, a positive profession observation from the saved recipe summary still identifies that profession as present, but missing professions remain Unknown. Learnable and Not learnable filter options are disabled without an authoritative profession list.

A recipe can be Learnable even if its required skill has not yet been reached; `canLearnNow` is separately true only when both numeric values are known and current skill meets the threshold. Missing thresholds are not guessed.

## Skinning evidence limitation

GatheringItems adds ten well-known core classic leather/hide item IDs for Skinning (393): Light, Medium, Heavy, Thick and Rugged tiers. This is a deliberately conservative subset. It does not claim full creature-to-item coverage; special scales and creature leathers remain unmapped until their item IDs and minimum skill gates are evidenced.

## Economics data boundary

Economics relationship filters are:
- Crafted outputs
- Gathered / collected
- Crafting reagents
- Other market items

Multiple selected filters combine as OR. With no relationship filter selected, all market items remain visible.

Dropped/loot and Vendor sourced controls are present but disabled. The available ForeverDB acquisition rows describe how recipes are learned; they do not form a complete market-item acquisition catalogue. Reusing recipe-learning trainer/vendor/drop sources as item-origin facts would be a category error. These filters remain disabled until a reliable item-origin source is integrated.

## Scope and ownership

- ModuloMarket is a separate optional child addon. Parent MODULO 1.0.48 is unchanged.
- No new dependency, API request, credential, SavedVariables schema, auction snapshot gate, canonical ForeverDB data or pricing formula changed.
- Existing acquisition-source preference and exact current-build market snapshot compatibility remain intact.

## Verification

- Focused offline tests: **30 passed** across character-aware profession status, row colours, filters, tab consolidation, Economics, acquisition display and version reporting.
- Dedicated Lua profession-status harness: **PASS**. It verifies owned-profession Learnable, missing-profession Not learnable, separate current/required skill, and Unknown when native profession APIs are absent.
- Lua syntax: **PASS**, all nine addon Lua files parsed with `texlua`.
- Full historical pytest suite: **162 passed, 48 failed**. The remaining failures are legacy source-contract assertions tied to earlier release versions, seven-tab navigation and prior UI contracts; they are not counted as passes and require a separate test-suite maintenance pass.
- Archive CRC/fresh extraction/version agreement: recorded in the final release handoff.
- Forever runtime: **NOT RUN**.

## Player acceptance

1. Exactly six tabs appear: All Items, Economics, Crafts, Materials, Low Supply and History.
2. Crafts contains learned and supported unlearned recipes; My Crafts and All Crafts are gone.
3. Known recipes are green; owned-profession unlearned recipes gold; missing-profession recipes red only when native profession ownership is authoritative; otherwise Unknown remains neutral.
4. The selected recipe shows current skill and learning threshold without guessing missing values.
5. Materials exposes Known, Learnable and Unavailable craft outputs plus Gathering and Crafting reagent relationships.
6. Core Skinning leather/hide tiers appear as gathering items.
7. Economics shows cheapest price, craft cost, saved price movement, total units and best craft profit. Relationship filters combine correctly.
8. Drop/loot and Vendor sourced controls remain disabled until actual item-acquisition evidence is available.
9. Search, sorting, filters, item selection, hover details, tab selection restoration and all other tabs work without Lua errors.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; LUA SYNTAX PASS; HISTORICAL SUITE HAS LEGACY FAILURES; FOREVER RUNTIME NOT RUN.
