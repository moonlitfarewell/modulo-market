# ModuloMarket Runtime Audit — 0.5.9

**Date:** 2026-11-12
**Addon / update version:** 0.5.9
**Parent MODULO:** 1.0.48 — unchanged
**Scope:** Dark Foundry visual polish: actual item/reagent icons, stronger selected-item inspection, panel/row visual hierarchy, and table readability. No tab or data capability is intentionally removed.

## Player problem and observable result

The user compared the in-game 0.5.8 UI with the approved All Crafts Dashboard reference. The three-column structure and tooltip layering were working, but the live interface remained visually sparse: item rows were text-only, selected-item identity and status were weak, reagent details lacked icons, and panel/row separation was flat.

Expected result: real item art appears where client item data exposes it; the selected entry has a clear identity/provenance header; reagent lines identify their actual items; alternating row surfaces and panel header plates improve scanning; all seven tabs and their data columns remain intact.

## Evidence reviewed

- Complete 0.5.8 GitHub update ZIP: CRC verified before extraction.
- 0.5.8 README, MANIFEST, standalone runtime audit, tooltip strata correction and UI redesign notes.
- Existing UI, tooltip, opacity, materials, tab-retention, capture-cache, data provenance and version tests.
- User-provided 0.5.8 in-game screenshots and approved `Modulo Market_ All Crafts Dashboard.png` reference.

The supplied screenshots show a working three-column layout and tooltips visibly above the window. The design reference shows icon-led rows, richer selected-item inspection and more deliberate panel hierarchy.

## Pre-change implementation / acceptance evidence

- 0.5.8 source has seven tabs, persistent contextual filter controls, a virtualized centre list, a selected-entry detail panel, whole-window opacity, and Market `DIALOG` strata below `TOOLTIP`.
- User confirmed tooltips now work in-game.
- The user asked to improve visual quality while preserving all information and functionality.
- The 0.5.8 Forever runtime acceptance for the new 0.5.9 visual elements is necessarily NOT RUN.

## Change

- Added `GetItemIcon(itemID)` using `C_Item.GetItemIconByID` when present and legacy `GetItemInfo` texture fallback. Unresolved question-mark fallback is not permanently cached, allowing later item-cache resolution.
- Added real item icon textures to each virtualized item/recipe row, keyed by the row's actual item ID.
- Added real reagent item icons to the recipe detail's reagent lines.
- Added a larger selected-item icon and improved selected title placement.
- Added contextual status labels derived from recipe state and `freshnessStatus`: Known/Future/Borrowed/Unknown and Baseline/Review as applicable. Review is not inferred from a build mismatch alone.
- Added alternating low-contrast row fills, slightly increased row height and clearer row/header font hierarchy.
- Added restrained bronze header plates/dividers to the three workspace panels.
- Retained all seven tabs, tab-specific columns, filters, scan controls, whole-window opacity, tooltip strata, baseline-plus-delta recipe catalogue, and exact-current-build auction snapshot gate.

## Ownership, dependencies and compatibility

All changes are in the optional ModuloMarket child addon. It continues to depend on MODULO only. Parent MODULO 1.0.48 is unchanged. No Auctionator, ProfessionMaster or other optional addon dependency was added. No ForeverDB recipe or auction data was modified or relabelled.

## Risks and gaps

- Item icon APIs can return nil until the Forever client item cache resolves. A question-mark fallback is used until a real icon becomes available. Live testing must establish that the client's item data events cause rows to be rerendered so icons replace the fallback; this is not yet runtime-proven.
- The detail panel uses recipe freshness state supplied by the existing profession provider; known recipes without freshness metadata do not receive a fabricated review state.
- The larger font/row height and texture layout need visual acceptance at the user's screen resolution and UI scale.
- No tooltip, opacity, capture lifecycle or data-compatibility runtime behavior is claimed newly verified by this slice.

## Verification

- Full Python test suite: recorded below after release packaging.
- Focused 0.5.9 tests cover icon lookup/fallback, row and reagent icon binding, selected-item identity/status, panel header plates, seven-tab retention, whole-window opacity, Materials column behavior and tooltip strata invariants.
- Lua syntax checks, manifest inventory, TOC/manifest/README version agreement, ZIP CRC/SHA-256 and fresh-extraction retest are recorded in release results.

## Runtime acceptance

**FOREVER runtime: NOT RUN.** On Forever client build `1.60.1.70888`, verify:

1. Item icons appear next to real item names in All Items, Economics, My Crafts, All Crafts, Materials, Low Supply and History where an item ID exists.
2. Icons match the actual selected item and recipe output; unresolved data uses the question-mark fallback only temporarily.
3. Reagent icons match the reagent item IDs and do not shift or corrupt line text.
4. Selected item icon, title and Known/Future/Borrowed/Unknown plus Baseline/Review labels reflect the selected record's actual fields.
5. Row striping, panel headers and larger row typography remain legible and do not overlap columns at the user's UI scale.
6. All seven tabs retain their existing controls and information; Materials still omits Listings while other relevant tabs retain their listing columns.
7. Existing tooltip layering and whole-window opacity still work.
8. No Lua errors, broken selection, scroll regression or market scan regression occurs.

Do not mark visual runtime acceptance PASS until the player confirms these checks in the target client.
