# Modulo Market 0.11.3 — scan flow and Modern controls runtime audit

## Result

**SHARED SCAN UI AND MODERN CONTROL REFINEMENT IMPLEMENTED · OFFLINE TESTS PASS · 87 BASELINE FAILURES UNCHANGED · RETAIL RUNTIME NOT RUN · FOREVER FIX ACCEPTANCE NOT RUN**

0.11.3 unifies the existing full-market scan state machine across Blizz-like and Modern, moves Browse Scan diagnostics out of the main windows, adds custom Modern TGA control assets and a custom search field, fixes the profession dropdown's initial display, and confines Market History to a three-day window with bounded Modern graph bars.

## Canonical baseline and provenance

- Sole baseline: user-provided/current `ModuloMarket-GitHub-Update-0.11.2.zip`.
- Baseline SHA-256: `266b601980e662775c10869834b5af5c56d0112d6c852649ef18d83096bd9ddc`.
- Baseline bytes: 2,434,986.
- Baseline ZIP CRC: PASS; archive contains 232 files.
- Baseline `MANIFEST.json` inventory exactly matched its 232 extracted files.
- Baseline `Core.lua`, TOC, `TurnInData.lua`, README and manifest version: 0.11.2.
- Parent MODULO provenance remains 1.0.48; no parent MODULO files are changed.
- No other source bundle was mixed into this slice.

## Player problem and observable result

The player supplied Forever 1.60.1.70938 screenshots and reported:

1. Modern had only an Update Full Market button, while Blizz-like exposed scan confirmation/cancellation separately.
2. Browse Scan was present in the main windows but did not provide a useful Modern workflow; it is a separate snapshot/debug window.
3. Profession dropdown initially displayed `0` instead of All professions.
4. Modern Market History text and graph bars/labels overlapped; the user requested a three-day history window.
5. Modern checkboxes lacked a clear tick mark, search retained a legacy input-box appearance, and stock control glyphs did not fit the Modern design.

## Root-cause diagnosis and counter-evidence

### Scan controls

- Competing hypothesis A: the Replicate scan engine itself was failing or missing confirmation state.
- Competing hypothesis B: the existing engine already had safe Prepare/Confirm/Cancel state transitions, but the presentations exposed them inconsistently.
- Diagnostic: inspect `Replicate.lua` and its callers. `Replicate.Prepare`, `Confirm`, `CancelPrepare`, and `GetState` already implemented the safety/cooldown/one-shot lifecycle. `MarketUI.RefreshActions` already read that state, while Modern's button only delegated to the primary button and did not render the complete state. This supports B; no evidence in the supplied screenshots establishes an engine defect.
- Correction: one primary button now changes from Scan Market to Confirm Scan and then Scanning/cooldown/session-used. Cancel is shown only while confirmation is pending. Both windows read the same `Replicate.GetState` and call the same Prepare/Confirm/Cancel methods. Confirmation rechecks the existing gates.

### Browse Scan

- Competing hypothesis A: Modern's browse button failed because the scanner frame could not be opened.
- Competing hypothesis B: the browse button was an unnecessary main-window control and should route to the existing scanner/debug window from settings.
- Diagnostic: `Scanner.Toggle` is already registered as `/mmscan`, and the scanner frame is created independently. The Modern button called a legacy UI bridge; there is no need to put it in the market workspace.
- Correction: remove the visible Browse Scan control from both market windows; add an Advanced Tools launcher to Modulo Market settings. `/mmscan` remains available. A hidden compatibility button is retained for older internal/test callers but is not shown to players.

### Profession dropdown

- Root cause: the profession getter can be `0` before the dynamic option list is populated; the old renderer displayed the raw getter when no option matched.
- Correction: dropdown display now resolves a matching option label, otherwise falls back to the first option; Profession specifically falls back to All professions while the list is empty. It refreshes as Modern rows/view state refresh.

### Market History

- Root cause: inspector history previously selected the last four stored snapshots without an age cutoff. Modern scaled legacy graph bar heights into a short card and positioned labels in the same vertical region as the text.
- Correction: filter history observations to the last three days, retaining at most four most recent observations for the compact graph. Modern graph bars are clamped to an 18px maximum and percentage labels are anchored above their bars in a fixed lower region beneath the history text.
- If the client wall clock is unavailable, the existing latest-four behavior is retained rather than dropping all history due to an unknown cutoff.

### Modern visual controls

- Root cause: the search field used `InputBoxTemplate`; several controls used generic or stock symbols; the checked checkbox state used a filled accent block rather than a recognizable tick.
- Correction: six addon-owned 64×64 RGBA TGA assets provide refresh, search, dropdown chevron, close, check and cancel icons. Modern search now has a custom surface, border, magnifier, placeholder and focus treatment. Checkbox checked state uses a recognizable tick texture tinted with the current accent.

## Scope and ownership

- Owner: standalone ModuloMarket addon.
- Changed runtime files: `Core.lua`, `MarketUI.lua`, `ModernUI.lua`, `Theme.lua`, `TurnInData.lua` and TOC version metadata.
- Added `AddOns/ModuloMarket/Textures/{refresh,search,chevron-down,close,check,cancel}.tga`.
- Added `tests/replicate_scan_flow_0_11_3_harness.lua` and `tests/test_modulomarket_0_11_3_scan_controls.py`; updated current release assertions and the Modern UI harness.
- Added `docs/MODULOMARKET-SCAN-AND-MODERN-CONTROLS-0.11.3.md`.
- No parent MODULO source changed; no new addon dependency.
- No change to Replicate request semantics, cooldown duration, one-request-per-session gate, Sell-tab safety gate, timeout, Browse snapshot pagination, auction aggregation, pricing, recipe/profession data, Turn-In calculations, history storage schema or SavedVariables schema.

## Risks and diagnostic plan

1. **Button/state synchronization:** UI callbacks or update cadence could leave the Modern label/cancel control stale. Offline tests exercise the shared state model; runtime diagnostic is to click Scan Market, Cancel, Confirm Scan and inspect the resulting state in both presentations.
2. **Shared account cooldown:** other addons can consume the account-wide cooldown without exposing their timestamp. The existing warning and local cooldown caveat remain; final confirmation rechecks the local timer and all existing safety gates. No external cooldown can be inferred.
3. **TGA asset loading:** file validity does not prove Forever's texture loader resolves the path. Offline validation checks file format, alpha mode, dimensions and package inclusion; runtime diagnostic is to inspect all six controls after a clean install/reload in all Modern palettes.
4. **History chart geometry:** card scale and font metrics vary by client resolution/UI scale. Offline tests verify the fixed height cap and non-overlap anchors; runtime diagnostic is to inspect 1–4 observations and confirm no text/bar overlap at the player's UI scale.
5. **Settings launcher:** settings registration and scanner frame lifecycle are source-checked, not client-tested. Runtime diagnostic is to open Browse Scan from addon settings and confirm it behaves like `/mmscan`.

## Verification

- Focused 0.11.3 scan/control and retained recent regression selection: **54 passed**.
- Modern UI harness: **29 checks passed**.
- Replicate scan state-machine harness: **8 checks passed**.
- Theme harness: **19 checks passed**.
- Custom TGA validation: **6/6 files valid RGBA TGA, 64×64**.
- Lua syntax: **13/13 addon Lua files passed** using `texluac -p`.
- Full source suite: **323 passed / 87 failed / 410 total**.
- 0.11.2 baseline suite in the same environment: **316 passed / 87 failed / 403 total**.
- Exact failing test IDs: **87 unchanged; zero new failing IDs; seven additional tests pass**.
- Final package validation: ZIP CRC PASS, exact manifest inventory, version agreement and fresh extraction PASS.

## Runtime evidence and acceptance

- Forever 1.60.1.70938: supplied screenshots establish the 0.11.2 behavior; **0.11.3 fix acceptance NOT RUN**.
- Retail runtime: **NOT RUN**.
- Actual live scan interaction, external shared cooldown behavior, settings-page scanner launcher, TGA rendering, checkbox state and history clipping require player retest.
- No `FOREVER OBSERVED` or `FOREVER VERIFIED` claim is made for these fixes.
- GitHub remote write/push: **NOT RUN**; this is a complete local bundle.

## Acceptance checklist

1. Both Blizz-like and Modern show Scan Market when available; first click changes the same button to Confirm Scan and exposes Cancel without sending a request.
2. Second click sends exactly one Replicate request; active state disables further clicks.
3. Cancel before confirmation sends no request and returns to Scan Market or cooldown countdown.
4. Existing 15-minute local cooldown warning, one-request-per-session, Auction House-open and Sell-tab safety gates remain intact.
5. Browse Scan is absent from both visible main windows; settings launcher opens the scanner/debug window; `/mmscan` remains functional.
6. Profession dropdown displays All professions rather than `0` before/after profession data loads.
7. Inspector Market History shows only the last three days; graph and text do not overlap at actual client scale.
8. Modern search, checked/unchecked checkboxes and six TGA icons render correctly in Dark, Class and Custom palettes.
9. Both presentations retain all six tabs, shared market data and existing calculations; no Lua/protected-action errors.
