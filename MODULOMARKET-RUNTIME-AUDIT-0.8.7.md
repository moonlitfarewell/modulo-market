# ModuloMarket Runtime Audit 0.8.7 — Dark Foundry visual alignment

## Result
**Visual alignment slice packaged — ModuloMarket 0.8.7.** This is a narrow continuation of the graphical redesign, not a full redesign completion. The standard market/Economics/Crafts Profit / Craft headings and Materials final heading now align to their right-anchored row values. The Relationships viewport is taller, while the existing Market History card and four-point graph remain available in a compact lower inspector section.

## Player problem and observable result
The annotated All Items review identifies a need for clearer table alignment and better use of inspector space. Source inspection found a 16px horizontal offset in Profit / Craft heading placement versus the corresponding right-anchored row value in market/Economics/Crafts, and a misaligned final heading in Materials. The right Relationships scroll viewport was 74px despite unused inspector space. 0.8.7 corrects those specific issues while preserving the established three-panel layout and six tabs.

## Canonical source and evidence availability
- Parent source bundle: `ModuloMarket-GitHub-Update-0.8.6.zip`.
- Parent size: 2,310,740 bytes; SHA-256: `f84174ecdb53f17f3ff4b79819fdcb3306b27de6e9c952ff7371caa0efe1678f`.
- Parent ZIP integrity: PASS; 165 entries; parent manifest/addon/README version 0.8.6.
- Parent 0.8.6 source, tests, README, manifest, data review and historical audits were available. The child repository does not contain child-specific `PROJECT-START-HERE`, `WORKFLOW`, `PROJECT-DECISIONS`, `PROJECT-PROGRESS`, `QA` or `SOURCE-REVIEW-LEDGER`; missing project history is not reconstructed.
- Reviewed the 0.8.6 README, 0.8.6 runtime audit, `docs/MODULOMARKET-UI-VISUAL-REDESIGN-0.8.4.md`, earlier UI redesign records, relevant MarketUI callers/layout code, and historical visual regression tests.
- User-supplied screenshot of the 0.8.4 All Items view: FOREVER OBSERVED for that screen/build only. User-supplied annotated visual reference v2 is design guidance, not runtime acceptance evidence.

## Direction and scope gate
- Player problem: improve scanability and use of the inspector's available space.
- Observable result: aligned Profit / Craft/final Materials heading; 106px Relationships viewport; compact Market History retained.
- MODULO vs specialist ownership: ModuloMarket is a separate optional child addon and owns its UI. Parent MODULO is unchanged; MODULO does not depend on ModuloMarket. No specialist addon owns or is changed by this UI slice.
- Dependencies/API/security/content: no new dependencies, APIs, network calls, saved-state fields, assets or external code. No market content or evidence classification changes.
- Risks: the smaller history graph may need visual adjustment if target-client font metrics or UI scale clip labels; longer relationship content may scroll differently in the actual client. These are source/offline-checked but not target-client verified.
- Scope: MarketUI.lua presentation geometry plus release metadata, documentation and tests only. No recipe/gathering micro-fixes.

## Implementation detail
- Standard market and Economics: At Price and Total headings remain at their existing aligned coordinates; Profit / Craft moves from x=930 to x=914, matching the row's right-anchored 176px value field.
- Crafts: Profit / Craft moves from x=936 to x=920, matching the row's right-anchored 170px field.
- Materials: At Price remains aligned at x=776; the final 254px value field is right-anchored at x=836 and its heading is aligned at x=836 (previously x=852).
- Relationships card: 120px → 152px; scroll viewport and initial child: 74px → 106px. Existing relationship and recipe detail renderers/data remain unchanged.
- Market History card: top y=-552 → -584; height 256px → 224px. History text and graph are repositioned; graph height 145px → 126px. Four stored points and existing change labels/calculation remain.
- Six tabs preserved. My Crafts remains absent.

## Behavior and compatibility review
- Changed source: `AddOns/ModuloMarket/MarketUI.lua` only for runtime behavior.
- Release metadata: `Core.lua`, TOC, manifest, README and audit; visual regression tests updated to the intentional new geometry.
- Relevant callers reviewed: `SetTab`, `RenderMarketRecipeContext`, `RenderCraftDetail`, `SetDetailEconomics`, `UI.RenderHistory`, `UpdateHeaderIndicators`, and row/header positioning. No behavior or data callers changed.
- Auction snapshot exact-build gate, `/mmcompat`, data provenance, market formulas, filtering, sorting, search, virtual row pool, scanning and SavedVariables remain unchanged.

## Verification
- Focused visual/layout regression group: **46 passed**.
- Full historical suite: **240 passed / 61 failed**.
- Baseline comparison against a fresh extraction of 0.8.6: baseline **236 passed / 61 failed** (297 tests); 0.8.7 **240 passed / 61 failed** (301 tests). Exact failing test IDs are identical: **0 new failing IDs; 0 resolved historical failures**. Four new 0.8.7 visual regression tests pass. Eight existing visual geometry assertions were updated to the new intended inspector geometry.
- Lua syntax: `texluac -p AddOns/ModuloMarket/*.lua` — PASS, 9/9 files.
- Compatibility harness: `texlua tests/build_compatibility_0_8_5_harness.lua` — PASS (offline mocked harness only).
- Profession capture harness: `texlua tests/profession_capture_0_7_8_harness.lua` — PASS (offline harness only).
- Release bundle: `ModuloMarket-GitHub-Update-0.8.7.zip`; 2,316,848 bytes; 168 manifest-listed files. ZIP CRC/integrity: PASS. Fresh extraction: PASS. Exact extracted file inventory equals the manifest 168/168; TOC, Core, README and JSON manifest versions all 0.8.7. The archive SHA-256 is supplied with the handoff.

## Forever runtime status and acceptance — NOT RUN
The prior 0.8.4 screenshot is not evidence for 0.8.7. On the actual Forever 1.60.1 client, install 0.8.7 and verify:
1. All six existing tabs render and switch; My Crafts remains absent.
2. In All Items/Economics/Crafts, Profit / Craft heading aligns to row values; in Materials, the final heading aligns to its value.
3. Select items with short and long relationship content; confirm the 106px viewport, scroll bar, no clipped text and no overlap with Market History.
4. Confirm Market History text, four points, percentage labels and bars fit within the 224px lower card at the user's UI scale.
5. Confirm filters, sorting, search, selection, tooltips, market values, scan controls and `/mmcompat` behave unchanged; check for Lua errors.
6. Capture a screenshot and any Lua errors. Keep runtime acceptance OPEN until this passes.

## Acceptance / exit
- Source implementation and offline regression acceptance: PASS.
- Full historical failures: unchanged baseline, explicitly retained.
- Forever 1.60.1 runtime acceptance: NOT RUN; release readiness does not imply Forever runtime verified.
- This slice is complete as an offline-verified visual capability. The broader graphical redesign remains ongoing.
