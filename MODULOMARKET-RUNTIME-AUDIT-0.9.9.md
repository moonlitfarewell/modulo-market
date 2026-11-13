# MODULOMARKET RUNTIME AUDIT 0.9.9

## Result
The All Items centre panel's four-sided perimeter is restored, and its three numeric columns now size to the widest visible header/value from the right edge, leaving the remaining space to Item. This is a presentation-only correction to 0.9.8. The 0.9.8 source bundle remains preserved.

## Player problem and observable result
The user's 0.9.8 screenshot showed the centre panel retained only its right-side edge; top, left and bottom edges were missing. Numeric columns remained too wide and Item had insufficient space.

Expected result: full perimeter without centre fill; no vertical column dividers; Total Units, At Price and Cheapest content-sized from the right; Item fills the remaining space.

## Source of truth and evidence
- Highest-version complete child bundle used: `ModuloMarket-GitHub-Update-0.9.8.zip`.
- Archive size 2,369,728 bytes; SHA-256 `f66d62e61827a404e8c21aeee9fbe1c198816a0bc1ae408b701b6e55688b82e9`.
- ZIP CRC check PASS; 200 entries.
- Manifest version/file_count/file inventory: 0.9.8 / 200 / 200; TOC and Core runtime version both 0.9.8.
- Fresh extraction of 0.9.8 was available and used as the comparison test baseline.
- User-supplied screenshot is FOREVER OBSERVED evidence of the 0.9.8 All Items appearance only. It is not runtime evidence for 0.9.9.
- Relevant files inspected: `MarketUI.lua`, `Core.lua`, TOC, README, MANIFEST, 0.9.8 audit, 0.9.8 All Items design record, 0.9.8 regression tests, and relevant prior UI tests.
- The child repository does not contain child-specific `PROJECT-START-HERE`, `WORKFLOW`, `PROJECT-DECISIONS`, `PROJECT-PROGRESS`, `QA`, `SOURCE-REVIEW-LEDGER`, a separate architecture file, or a Forever compatibility contract. Missing history was not reconstructed.

## Before-change code evidence
- Centre panel background texture had already been removed in 0.9.8.
- Centre panel perimeter call `AddPanelInnerEdge(286, -158, 834, 650)` had also been removed, explaining the missing three edges (the right-side divider remained separately drawn).
- All Items had fixed widths and hard-coded positions for its numeric fields.
- `UI.RenderRows()` updates the virtualized visible row pool after scroll, sort, filter and view builds. It is the appropriate bounded place to remeasure visible content.
- Each virtual row is 796px wide; the scroll frame/child geometry is unchanged.

## Implementation
### Border
Restored `AddPanelInnerEdge(286, -158, 834, 650)`, which uses the existing four-edge one-pixel `AddBevelBorder` helper. No centre fill texture, boxed table header or vertical column guide texture was reintroduced.

### Dynamic All Items columns
- Measures `GetStringWidth()` for the Cheapest/At Price/Total Units headers and visible row strings.
- The sizing helper runs after each `UI.RenderRows()` population pass, so it adapts after scroll, sort, filter and refresh events, not just when the tab is first selected.
- Cheapest uses `row.price`; At Price uses `row.depth`; Total Units uses `row.atPrice`.
- Applies 14px breathing room, minimum widths and defensive upper bounds.
- Places Total Units at the right edge, then At Price, then Cheapest, with Item taking the remaining left-side width.
- Header and row anchors share the same calculated positions.
- Recalculates in `UI.RenderRows()` after the visible rows' text is populated, so scrolling, sorting, filtering and refreshes can adjust widths.

The measurement scope is the 25-row virtualized visible pool, not every item in the full catalogue. This is intentional: it avoids a full-catalogue measurement pass and adapts as the player browses.

## Ownership, dependencies and scope
- ModuloMarket-owned UI layout only.
- No MODULO parent source or specialist addon changes.
- No dependencies, SavedVariables, market calculations, auction acquisition, recipe data, ForeverDB data, scan behavior or other tab data changed.
- Other tab-specific header/row layouts remain in their separate branches.
- Item quality colours and craft markers from 0.9.8 remain unchanged.

## Validation
- Focused 0.9.9 tests: **6 PASS**.
- Updated current All Items regression tests: **10 PASS** (0.9.8 feature tests now also assert the 0.9.9 restored border/current dynamic layout).
- Full suite on working tree: **275 PASS / 81 failures**.
- Comparison against the fresh-extracted 0.9.8 baseline: 0.9.8 baseline was **289 PASS / 61 failures**. There are 20 additional failing IDs, all identified as historical expectations: 17 tests pin an earlier release version/metadata; 3 older visual-contract tests assert prior panel-border geometry that this requested border restoration supersedes. These are known stale assertions, not new runtime failures. No other new failing IDs were found.
- All 9 addon Lua files pass `texluac -p`.
- Package ZIP CRC, manifest inventory, fresh extraction and fresh-extraction tests recorded below.
- Forever runtime acceptance: **NOT RUN** for 0.9.9.

## Acceptance / exit criteria
Source slice complete. Player-visible acceptance remains open until the user tests on WoW Forever 1.60.1 build 70938:
- continuous four-sided centre panel border;
- no centre background fill or vertical column dividers;
- numeric columns fit visible content from the right, Item takes remainder;
- widths adapt while scrolling through longer values;
- sorting/filtering/header interactions remain functional;
- other tabs retain independent layouts;
- no Lua errors.

## Final package verification
- Release archive: `ModuloMarket-GitHub-Update-0.9.9.zip`.
- ZIP CRC: PASS (`ZipFile.testzip()` returned `None`).
- Archive entries: 203.
- Fresh extraction: 203 files; manifest declares 203; exact sorted inventory match: PASS.
- Focused fresh-extraction regression tests: 16 PASS.
- Full fresh-extraction suite: 275 PASS / 81 failures; the 20 additional IDs vs 0.9.8 are the known 17 historical version-pinned tests and 3 superseded visual-contract assertions described above.
- Fresh-extraction Lua syntax: 9/9 PASS.
- Forever runtime acceptance: NOT RUN.
