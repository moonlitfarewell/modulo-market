# Modulo Market 0.10.2 — Turn-In reward and inspector sizing audit

**Status:** SOURCE IMPLEMENTED · FOCUSED OFFLINE TESTS PASS · FULL SUITE HAS ZERO NEW FAILURES VS 0.10.1 · FOREVER RUNTIME NOT RUN

## Canonical baseline and provenance

- Sole baseline: user-provided `ModuloMarket-GitHub-Update-0.10.1.zip`.
- Baseline archive SHA-256: `b09ebe12b975117b2de21005b58d6ee145af9c3fb3a1946bfafd4b2107414a03`.
- Baseline ZIP CRC validation: PASS (`ZipFile.testzip()` returned `None`).
- Baseline contained 212 files; `MANIFEST.json` had 212 entries with exact path agreement.
- Baseline `Core.lua`, TOC, `TurnInData.lua` and manifest all agreed on version `0.10.1`.
- No other branch, source ZIP or repository version was mixed into this slice.

## Player problem and observable result

The user supplied Forever UI screenshots showing two defects in 0.10.1:

1. The single `Favor / Rep` cell rendered both values, e.g. `20 F · 0 Rep`, even though the column was intended to represent one reward type.
2. The selected Turn-In inspector's four metric rows were visually cramped: labels were enlarged in a narrow label region, while values were created with an enlarged font and a constrained 132px value region.

The 0.10.2 source now:

- Shows exactly one reward value. A reported Favor value takes precedence; otherwise a reported reputation value is shown; if neither is reported, it shows `?`.
- Preserves known zero as `0 Rep` rather than converting it to unknown.
- Uses the same exclusive rule in the selected inspector, with full words (`Favor` or `Reputation`).
- Classifies the reward as reported when either Favor or reputation is known.
- Uses small native label text and shorter labels (`COMPLETE COST`, `CASH RETURN`, `FAVOR OR REP`, `NET / FAVOR`).
- Creates metric values at `GameFontHighlight` body size and allocates a 160px value column starting at x=1248.
- Retains explicit restoration of the original large metric font on non-Turn-In tabs.

## Root-cause analysis

### Reward column

The 0.10.1 UI source explicitly concatenated `rewardFavor` and `reputation` into one string. Data entries commonly contain a positive Favor reward and a reported reputation value of zero, so the resulting `N F · 0 Rep` was a direct presentation defect. A shared `TurnInEngine.FormatReward` helper now enforces one-value precedence and is covered by executable Lua assertions for Favor precedence, reputation-only rewards, known zero, and unknown.

### Inspector sizing — competing hypotheses and distinguishing evidence

1. **Font-state hypothesis:** enlarged font state from creation or a later tab/font-object transition persisted on the Turn-In view.
2. **Geometry hypothesis:** enlarged labels plus a 128px/132px split left too little space for the actual metric labels and values, independently of font state.

Source inspection confirmed both risks: row labels were enlarged at creation; values were created as `GameFontHighlightLarge` and enlarged; the old split was 128px label / 132px value. The fix removes enlargement at creation, makes body-sized text the default, shortens labels, and widens the value region to 160px. The actual rendered pixel dimensions, font-object behavior and clipping still require in-client observation; static tests cannot prove them.

## Ownership, scope and dependencies

- Owner: ModuloMarket.
- No new dependencies; no parent MODULO source changed.
- No SavedVariables schema, scanner, market snapshot, price arithmetic, market-depth gate, crate catalogue or material alternatives changed.
- The only engine-level change is reward-status classification when reputation is the only reported reward dimension.

## Tests and validation

- Focused Turn-In tests: **14 passed**.
- Lua syntax: **11/11 addon Lua files passed** using `texlua` `loadfile` compilation.
- Lua Turn-In harness: **PASS** — exclusive reward formatting; 30 unique crate definitions; 96 one-of bundle alternatives; crate + material completion cost; cash/Favor/reputation return data; Artisan unknowns; insufficient-depth fail-closed; missing crate-price fail-closed; one-time Shipping Label bonus separation.
- Full Python suite on the 0.10.1 baseline: **283 passed / 87 failed / 370 total**.
- Full Python suite on 0.10.2: **283 passed / 87 failed / 370 total**.
- Exact failing test IDs compared: **87 unchanged; zero new failures; zero resolved historical failures**.
- ZIP integrity, fresh extraction, manifest inventory and version agreement are validated for the final package; exact results and SHA-256 are included in the handoff.

## Runtime evidence and counter-evidence

- The supplied screenshot is direct evidence that the 0.10.1 reward cell and inspector presentation were defective.
- No screenshot or client capture of 0.10.2 has been supplied.
- Retail runtime: **NOT RUN**.
- Forever runtime: **NOT RUN**. The source fix and offline checks do not establish in-client layout acceptance.

## Acceptance / exit criteria

1. A Favor-reward crate displays only `N F`; no appended reputation value.
2. A reputation-only crate displays only `N Rep`.
3. A known zero reputation displays `0 Rep`; an unknown reward displays `?`.
4. The selected inspector displays one reward type only.
5. The four Turn-In metric labels fit; full metric values and coin textures fit in the 160px value region.
6. Switching between Turn-Ins and all other tabs preserves the original non-Turn-In value font sizing.
7. All 30 crates, all 96 alternatives, existing price arithmetic and fail-closed unknown-price behavior remain unchanged.
8. Player-visible acceptance must be confirmed on the relevant Forever client before marking this defect closed.

**Release readiness is not Forever runtime verification.** The visual defect remains runtime-open until the player confirms 0.10.2 in the Forever client.
