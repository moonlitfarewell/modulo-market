# Modulo Market 0.10.3 — Runtime defect audit

**Status:** SOURCE IMPLEMENTED · FOCUSED TESTS PASS · NO NEW FULL-SUITE FAILURES VS 0.10.2 · FOREVER RUNTIME NOT RUN

## Canonical baseline and provenance

- Sole baseline: user-provided `ModuloMarket-GitHub-Update-0.10.2.zip`.
- Baseline SHA-256: `20201e50d589af33154570ff1ec4cc84602ce66e0b9c7ff908af732bf868a5a5`.
- Baseline ZIP integrity was checked before extraction; no errors were reported.
- No other ModuloMarket branch or source bundle was mixed into this slice.

## Player problems and observable results

The user supplied Forever UI screenshots showing:

1. Inspector metric text growing substantially after each tab change, eventually clipping values in the inspector.
2. Turn-In selected-row highlight appearing later than the inspector update, unlike other tabs.

Expected result:

- Turn-In inspector values exactly match the middle table row font size.
- Other tabs retain their intended larger inspector values.
- Font size remains stable through repeated tab changes and item selection.
- Selecting a Waylaid Crate immediately applies the selected row wash/accent.

## Root-cause evidence and competing hypotheses

### Inspector font growth

- **Hypothesis A — cumulative font mutation:** repeated selection/tab callbacks increase the existing FontString size.
- **Hypothesis B — static font with geometry/scale mismatch:** a stable font is being clipped by insufficient panel width or UI scaling.
- Source inspection confirms Hypothesis A: `SetTab` and non-Turn-In `SelectItem` repeatedly invoked `IncreaseFontSize(value, 1)`, which reads the current size and adds one. The Turn-In branch used a different reset path. This is a stateful, non-idempotent font mutation.
- The fix derives font path, size and flags from a fixed Blizzard font template and assigns the absolute size (`GameFontHighlight + 1` for Turn-Ins; `GameFontHighlightLarge + 1` otherwise). It no longer increments the inspector's current font.
- The user's screenshot is direct evidence of the visual defect before this fix. Static/offline checks cannot establish the actual rendered pixel size; client observation remains required.

### Turn-In selection highlight delay

- **Hypothesis A — delayed/async view rebuild:** selection waits for a later view-build callback before repainting the selected row.
- **Hypothesis B — Turn-In selection handler skips the immediate row refresh:** the Turn-In branch updates inspector content and returns before the common `UI.RenderRows()` call.
- Source inspection confirms Hypothesis B. The normal item-selection path reaches `UI.RenderRows()`, while the Turn-In branch returned early. The fix calls `UI.RenderRows()` immediately before that early return.
- The exact visual latency still needs in-client confirmation.

## Implementation and ownership

- Owner: ModuloMarket.
- New deterministic helper: `SetFontFromTemplate`.
- Turn-In selection calls `UI.RenderRows()` before returning.
- No changes to parent MODULO, dependencies, SavedVariables schema, auction data, pricing, sorting, market-depth semantics, crate data, alternatives, or scanner behavior.
- Prior 0.10.2 exclusive reward formatting and known-zero/unknown semantics are preserved.

## Tests and validation

- Focused Turn-In/UI tests: **16 passed**.
- Lua syntax: **11/11 addon Lua files passed** using `texlua` `loadfile` compilation.
- Turn-In Lua harness: **9 checks passed**, including exclusive reward formatting, 30 unique crate definitions, 96 one-of alternatives, completion economics, unknown rewards, insufficient price depth, missing crate price, and one-time bonus separation.
- Full Python suite: **285 passed / 87 failed / 372 total**.
- Baseline 0.10.2 full suite: **283 passed / 87 failed / 370 total**. Exact failing test IDs compared: **87 unchanged; zero new failures; two additional focused tests pass**.
- Final ZIP CRC, fresh extraction, manifest inventory, and version agreement: **PASS**; see final handoff metadata below.

## Runtime evidence and limitations

- User screenshots establish the defects in the installed build prior to this slice.
- Retail runtime: NOT RUN.
- Forever runtime: NOT RUN. No client screenshot or test has yet established 0.10.3 behavior.

## Final package evidence

- Package version: `0.10.3` across Core, TOC, TurnInData and manifest.
- Archive inventory: 216 files with exact manifest path agreement.
- ZIP CRC and fresh extraction: PASS.
- Archive SHA-256: recorded in the handoff response.

## Exit criteria

1. Turn-In inspector font size matches middle list row text exactly.
2. Repeated tab switching and item selection do not grow inspector text.
3. Non-Turn-In inspector sizing remains unchanged in appearance and stable.
4. Turn-In selection highlight updates immediately.
5. Existing turn-in economics, unknown handling and all non-target functionality remain intact.
6. Player-visible acceptance is confirmed on the relevant Forever client.
