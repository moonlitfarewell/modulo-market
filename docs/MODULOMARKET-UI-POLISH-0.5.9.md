# ModuloMarket UI polish — 0.5.9

## Player problem and intended result

The 0.5.8 three-column workspace follows the selected Dark Foundry layout, but the user's in-game comparison showed that the implementation remained visually sparse relative to the reference: the central list was text-heavy, item identity was weak, the selected-item panel lacked a strong visual hierarchy, and the panels and rows lacked depth.

The 0.5.9 goal is presentation enrichment without reducing any of the seven tab capabilities, their data columns, filters, market actions, or data-safety rules.

## Evidence reviewed

- ModuloMarket 0.5.8 source ZIP and its standalone runtime audit.
- `README.md`, `MANIFEST.json`, the 0.5.6/0.5.7 UI redesign notes, and 0.5.8 tooltip strata correction note.
- Existing UI and version regression tests.
- User-supplied in-game screenshot of 0.5.8 and the attached All Crafts Dashboard reference.

The supplied screenshot demonstrates that the three-column architecture is present and the tooltips are now visible in front of the window. The reference demonstrates the desired denser, icon-led row design, more structured selected-item panel and more substantial Dark Foundry styling.

## Change

- Added item-icon resolution using the client's item-icon API when available, with `GetItemInfo` fallback. A question-mark icon is used only while the client has not resolved the real icon; unresolved fallback values are not cached permanently.
- Added real output item icons to virtualized market/recipe rows.
- Added actual reagent item icons inline to recipe reagent detail lines.
- Added a larger selected-item icon, clearer title placement, and contextual Known/Future/Borrowed/Unknown plus Baseline/Review status badges derived from recipe provenance fields.
- Added alternating low-contrast row surfaces and stronger row typography for scanability.
- Added subtle header plates and dividers to all three workspace panels.
- Preserved all seven tabs, their existing filters and information models, all market actions, the Materials five-column layout, whole-window opacity, DIALOG Market strata, TOOLTIP tooltip strata, baseline-plus-delta recipe handling, and exact-current-build auction snapshot gating.
- Increased row height modestly to support the more legible font while retaining virtualized rendering.

## Ownership and dependencies

All changes are within the optional ModuloMarket child addon. It continues to depend only on MODULO; MODULO remains unchanged and does not depend on ModuloMarket. No Auctionator or ProfessionMaster dependency was added.

## Risks and limitations

- Actual icon availability depends on the Forever client returning item textures through `C_Item.GetItemIconByID` or legacy `GetItemInfo`. If item data is not loaded yet, the question-mark fallback is temporary; live client acceptance must confirm later resolution.
- The visual hierarchy and text sizing require live acceptance at the user's actual UI scale and screen resolution.
- This slice does not claim new recipe, market or acquisition data verification.

## Offline acceptance

- Full Python regression suite: recorded in release audit.
- Focused visual-polish source tests: verify icon resolution, row icon and shading creation, selected identity/badges, reagent icons, panel header plates, seven-tab retention, opacity and strata invariants.
- Lua syntax, ZIP CRC, manifest inventory, TOC/manifest/README version agreement, and fresh-extraction tests are recorded in release audit.

## Runtime acceptance

**FOREVER runtime: NOT RUN.** The user must confirm on client build `1.60.1.70888` that item icons resolve, rows remain readable, reagent icons match the correct items, selected-item badges reflect the actual provenance, panel headings render correctly, and all seven tabs retain their prior content and controls. Existing tooltip layering and whole-window opacity should be spot-checked to ensure no regression.
