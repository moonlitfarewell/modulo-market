# ModuloMarket Runtime Audit 0.6.6 — Compact acquisition and inspector polish

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.6.5.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; FOREVER RUNTIME NOT RUN.

## Player problem and observable result

The 0.6.5 inspector showed up to three source rows, evidence badges, explanatory caveats, NPC IDs, coordinates and extra status text. This was too dense for routine use. It also repeated price/listing values in the detail body, displayed a raw recipe ID, and omitted the recipe learning skill because `learn_at_skill` was not carried into the compact runtime data.

0.6.6 keeps the full canonical acquisition data and provenance, but presents only one useful route in the normal inspector:

- `Trainer: Borgus Steelhand`
- `Location: Stormwind City`
- `Cost: 1g 50s`

Source choice prefers a direct `FOREVER_OBSERVED` route, then `CLASSIC_BORROWED` as the fallback, followed by `FOREVER_CLIENT` and `UNKNOWN`. Inferred trainer observations are skipped when selecting the primary route. No evidence badges or alternative-source dump are shown in the normal inspector. The complete underlying rows remain in the data model.

## Inspector changes

- The inspector metadata line shows profession and learning skill once. The detail body is reduced to `Recipe`, `Output`, one compact `ACQUISITION` block, and reagent/economics details.
- Sale price/unit and total listed remain in the summary header; `At price` is now also in that header. Their duplicate body lines are removed.
- Acquisition source type is rendered naturally: `Trainer`, `Vendor`, `Recipe`, `Drop`, `Quest`, or `Automatic`; location and cost are shown only when supplied.
- `learn_at_skill` is compiled into runtime data and shown as the profession learning skill (e.g. Blacksmithing · Skill 245). It is not confused with skill-up colour thresholds.
- Numeric recipe ID is removed from the inspector. Hovering the recipe-name region displays the native recipe tooltip; hovering the icon continues to display the item tooltip.
- History bars show signed percentage change from the preceding captured point. The first point is the 0.0% baseline. Labels are guarded for harness/client compatibility.

## Evidence, counter-evidence and limits

- Canonical 1.60.1.70888 dataset and its 10,369 field-level acquisition rows are unchanged.
- For Phantom Blade (recipe 10007), the canonical source contains Borgus Steelhand, Stormwind City, a direct Forever-observed row, and a 15,000-copper trainer learning cost whose cost provenance is Classic-borrowed. The compact display intentionally shows the useful cost without a provenance badge, as requested; the underlying evidence field is retained.
- The Forever-observed trainer row is used ahead of Classic alternatives. The code does not promote inferred trainer observations to the primary source.
- Classic fallback may not reflect current Forever availability; this is an intentional product choice to provide useful source information unless a direct Forever record supersedes it. It is not a claim of fresh in-game verification.
- Percentage labels represent market-history price change between consecutive saved snapshots, not craft-profit margin. The selected recipe's profit/craft margin remains displayed separately.
- No new API calls, API key handling, external dependencies, SavedVariables changes or parent MODULO dependencies.

## Tests and verification

- Focused regression suite: **43 passed** (compact source selection, source data preservation, importer, raw adapter, build refresh, inspector/footer, layout and version tests).
- Full historical suite: **157 passed, 33 failed**. Failures are primarily legacy source-contract tests pinned to 0.6.3-era code/layout and the prior 0.6.5 presentation. One harness compatibility issue discovered during this run was corrected by guarding optional font-string color support; the focused regression suite was rerun afterward.
- Lua syntax, archive CRC, fresh extraction and final manifest/hash checks are recorded in the release handoff after packaging.
- Forever runtime: **NOT RUN**. No in-client load, rendering, tooltip, skill-value or performance claim is made.

## Player acceptance

1. Select Phantom Blade. Inspector shows `Blacksmithing · Skill 245`, `Recipe: Phantom Blade`, output, price, at-price quantity, total listed, and one acquisition route: Borgus Steelhand / Stormwind City / 1g 50s.
2. Hover the recipe title and verify the native recipe tooltip; hover the icon and verify the item tooltip.
3. Test a recipe whose best source is a Classic fallback and one whose primary route is a drop, recipe item, vendor or quest.
4. Verify history bars show readable signed percentages, with green for increases, red for decreases and a neutral baseline.
5. Check all seven tabs and confirm no Lua errors or regressions.

**Exit status:** SOURCE IMPLEMENTED; OFFLINE FOCUSED TESTS PASS; FOREVER RUNTIME NOT RUN. Keep player-visible acceptance open until these checks pass on the target client.
