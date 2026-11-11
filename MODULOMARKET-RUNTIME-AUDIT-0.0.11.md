# Modulo Market Runtime Audit 0.0.11 — Replicate warning layout correction

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.0.11  
**Parent:** MODULO 1.0.48 (unchanged)  
**Release type:** standalone optional child addon; UI correction only.

## Player problem and observable result

The player's screenshot of 0.0.10 showed the long Replicate risk warning overlapping the first row of controls. The warning was difficult to read and the layout could obscure controls.

0.0.11 reserves a fixed 54-pixel status area with top vertical justification and word wrapping. The action rows and output scroll frame move down to ensure the warning has dedicated space. The probe request logic is unchanged. The Lua model harness stubs the FontString word-wrap method; it validates source/layout construction, not actual pixel rendering on the game client.

## Evidence and counter-evidence

- Direct player screenshot: warning text visibly overlaps/abuts the controls.
- Source inspection: status FontString was anchored at y=-78 without a fixed height; controls began at y=-104. A multi-line warning could therefore extend into the control row.
- Counter-evidence: the screenshot shows the prepared state, so the confirmation button being visible is expected. It does not show whether a request was sent.
- Runtime confirmation of the corrected layout is not yet available.

## Ownership and scope

- Owner: separate optional child addon `ModuloMarket`.
- Parent MODULO remains 1.0.48 and unchanged.
- This is a presentation-only correction. No Auction House API, scan pacing, persistence, Replicate request, cooldown or data model logic changed.

## Implementation

- Status FontString: fixed height 54, word wrap enabled, top vertical justification.
- First control row moved from y=-104 to y=-140.
- Previous/Next row moved from y=-134 to y=-170.
- Prepare/Confirm row moved from y=-164 to y=-200.
- Output scroll frame moved from y=-200 to y=-236.
- Added static regression test for the status height, wrapping and layout anchors.
- Replicate probe remains a two-step explicit opt-in; prepare does not send a request. Confirm sends at most one request per session and a 15-minute persisted cooldown applies.

## Tests and package validation

- `python -m pytest -q tests` — **PASS, 30 passed**.
- `texluac -p AddOns/ModuloMarket/Core.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Diagnostics.lua` — **PASS**.
- `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/replicate_probe_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- Fresh extraction, ZIP integrity, manifest inventory and version agreement — **PASS**.
- Forever UI runtime — **NOT RUN**.
- Replicate response — **NOT RUN**.

## Acceptance

Install 0.0.11 and open `/mm`. Click Prepare Replicate Probe. Verify the full warning is readable and does not overlap any buttons. At this point no API request has been sent. Only if willing to accept the documented risk and after ensuring no other Auction House activity is running, click Confirm exactly once. Do not retry.

## Remaining gaps

- Actual Forever layout acceptance for 0.0.11.
- Actual Replicate response and sample data.
- Whether Replicate can safely support a complete full-house scanner, map item variants, handle missing item info, and produce prices/quantities equivalent to browse results.
- No claim of Forever runtime verification.


## Post-release runtime evidence addendum — 2026-11-10

The player subsequently installed 0.0.11 and confirmed the warning layout was readable. The player explicitly confirmed one Replicate request. The initial `REPLICATE_ITEM_LIST_UPDATE` arrived and `GetNumReplicateItems()` reported 291,276 auction records after 17.0 seconds. The probe sampled first, middle and last records; all three reported `hasAllInfo=true`. The UI stated that no snapshot data was read or saved and that the attempt was consumed. This is **FOREVER OBSERVED — initial Replicate response only**. It does not establish full-list traversal, data enrichment, item-key mapping, price/quantity aggregation, snapshot persistence, Sell-tab safety during full processing, or end-to-end performance. See `MODULOMARKET-REPLICATE-PROBE-RESULT-2026-11-10.md` in the conversation handoff; the standalone 0.0.12 audit records the next bounded sample capability.
