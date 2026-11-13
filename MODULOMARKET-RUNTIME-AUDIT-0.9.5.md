# MODULOMARKET RUNTIME AUDIT 0.9.5

## Result
The title-strip sizing and tab-join defects identified in the 0.9.4 screenshot are corrected in source. Offline validation is complete. Forever runtime acceptance for 0.9.5 is NOT RUN.

## Player problem and observable result
The player reported that 0.9.4 looked unchanged. The supplied screenshot confirms the title bar still appears too shallow and thin vertical separators remain between tabs.

## Evidence and root-cause diagnosis
- Canonical input: `ModuloMarket-GitHub-Update-0.9.4.zip`, 188 entries, ZIP CRC PASS, SHA-256 `af12ad645e915f65db934969ab827a7319ad03ecb9fb34633d34201e0bdc9443`.
- The 0.9.4 screenshot is FOREVER OBSERVED evidence for 0.9.4 rendering only; it demonstrates that the intended visual acceptance was not met.
- Competing title hypotheses:
  1. **TitleBg constrained by original anchors (confirmed in source):** 0.9.4 only called `TitleBg:SetHeight(38)` while leaving the template's existing anchors intact. The texture's original top/bottom constraints can prevent the intended visible height change.
  2. **Title text region too small:** 0.9.4 used a 280x24 text region at -19; this alone cannot resize the actual title background.
  The distinguishing source diagnostic is whether the texture's anchors are explicitly cleared and reset before assigning height. 0.9.4 did not do so.
- Competing tab hypotheses:
  1. **Inter-tab spacing (confirmed in source):** tab positions advanced by `width + 4`, leaving a four-pixel gap that exposes the strip beneath as a vertical divider.
  2. **Residual side strokes:** 0.9.4 already removed the explicit left/right strokes, so these alone cannot explain the visible gaps.
  The source confirms the four-pixel increment remains the cause.
- No counter-evidence suggests an in-game API or rendering defect; no runtime instrumentation was performed.

## Player problem and observable result
The player needs a title strip visibly comparable to Blizzard's large default windows, with the title centred in it, and a continuous tab row without vertical gaps. Internal borders must remain.

## Changes in 0.9.5
### Native title strip
- Explicitly clear the `TitleBg` anchors and re-anchor its top-left/top-right edges to the frame at 8px horizontal inset and -5px vertical offset.
- Set native title background height to 44px.
- Centre the title at -27px and size its text region to 320x28.
- Increase the main frame height from 850px to 882px and update screen-fit scaling.
- Shift addon-owned direct child frames/regions anchored to the main frame down 16px, creating space beneath the taller title strip.
- Exclude the native close button (by object and name), `Inset`, `NineSlice`, `TitleBg`, `TitleText`, `TopTileStreaks` and `Bg` from the content shift. Nested controls move with their owning widgets.

### Tabs
- Remove the four-pixel inter-tab gap: tab X position now advances by tab width only.
- Preserve tab background, top/bottom accents, selected marker, hover state, labels and click handlers.
- Keep the tab-strip outer border.

### Preserved
- Native Blizzard frame background and close control.
- All internal panel, filter, table, inspector and history borders.
- Six tabs; My Crafts remains absent.
- The 0.9.1 dropdown popup lifecycle correction.
- All market calculations, scanning, data catalogue, recipe/gathering relationships, SavedVariables, APIs and dependencies.

## Ownership, dependencies and scope
- ModuloMarket owns this presentation change.
- No parent MODULO or specialist addon changes.
- No new dependency, API use, data or SavedVariables changes.
- UI-only scope.

## Validation
- Focused 0.9.5 title/tab tests plus the updated 0.9.4 regression tests: 8 PASS.
- Full suite: 267 PASS / 61 historical failures.
- Exact 0.9.4 parent comparison: same 61 failing test IDs; zero new failing IDs.
- Lua syntax: 9/9 PASS.
- Fresh extraction, manifest inventory, ZIP CRC and fresh-extraction suite are recorded after packaging.
- Forever runtime acceptance for 0.9.5: NOT RUN. 0.9.4 screenshot is FOREVER OBSERVED for 0.9.4 only and explicitly records a visual acceptance failure.

## Player acceptance and exit criteria
Install 0.9.5 on Forever 1.60.1 build 70938 and confirm:
1. TitleBg is visibly taller than in 0.9.4 and comparable to Blizzard reference title strips.
2. Title text is centred vertically and horizontally within that strip.
3. The top status/control row begins below the title strip without overlap.
4. Adjacent tabs touch edge-to-edge with no vertical dark gaps.
5. Tab hover/selection/click behavior remains intact.
6. All internal borders remain, the close button remains in the native title corner, and dropdowns still close on main-window hide.
Do not mark 0.9.5 visual acceptance PASS until the target-client screenshot confirms these conditions.

## Governance/source availability
The 0.9.4 child bundle and its README, manifest, historical audit files and tests were available and inspected. Child-specific PROJECT-START-HERE, WORKFLOW, PROJECT-DECISIONS, PROJECT-PROGRESS, QA and SOURCE-REVIEW-LEDGER are not present in this child bundle; missing child history was not reconstructed.

- Full suite command: `python -m pytest -q` — 267 PASS / 61 failures.
- Baseline comparison command ran the same full suite against a fresh extraction of the exact 0.9.4 ZIP: 263 PASS / 61 failures. Failure IDs are identical; zero new failing IDs.
- Lua syntax command: `texluac -p` against each of the 9 `AddOns/ModuloMarket/*.lua` files — 9/9 PASS.
