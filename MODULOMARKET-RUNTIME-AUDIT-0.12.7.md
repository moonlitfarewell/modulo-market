# Modulo Market 0.12.7 Runtime Audit — Original UI Assets and Evidence Reconciliation

## Status

**SOURCE/ASSET SLICE IMPLEMENTED; OFFLINE REGRESSION PASS; PRIOR FOREVER OBSERVATIONS RECONCILED.** This slice replaces six undocumented UI glyph textures with project-authored assets and corrects the current acceptance record. It does not clear ForeverDB/CMaNGOS dataset rights or approve 1.0.0.

## Player problem and observable result

The prior six TGA UI glyphs had no embedded author/licence metadata or traceable editable source. The observable result is the same six UI affordances (check, close, cancel, refresh, dropdown chevron, search) rendered from original project-authored SVG masters, with source and regeneration instructions included.

## Changes

- Replaced `check.tga`, `close.tga`, `cancel.tga`, `refresh.tga`, `chevron-down.tga`, and `search.tga` with newly rendered 64×64 RGBA glyphs.
- Added editable SVG masters under `assets/ui-icons/`.
- Added `tools/assets/render_modulomarket_icons.py` to reproduce the TGA outputs.
- Added `ASSET-PROVENANCE.md` and expanded the root MIT scope only to original project-authored source and the six listed UI assets, to the extent contributor rights permit.
- Kept third-party data, CMaNGOS-derived records, Blizzard content/trademarks, and external dependencies explicitly excluded.
- Advanced addon and bundle version together to 0.12.7.

## Runtime evidence reconciled from user screenshots

All results below are **FOREVER OBSERVED**, not FOREVER VERIFIED:

| Scope | Observed result | Evidence |
|---|---|---|
| Full Market refresh with Modulo Market closed during scan, then reopened | PASS | User screenshot sequence and successful saved-snapshot status; prior 0.12.5 test |
| Full Market refresh with Modulo Market left open | PASS | User-reported PASS and screenshot showing updated Full Market snapshot/catalogue |
| Explicit cancellation, Modern presentation — confirmation, active processing, post-cancel | PASS | Three user screenshots; Cancel visible in both stages, post-cancel status says previous saved market data unchanged; 291,981 auction count and existing catalogue/inspector retained |
| Explicit cancellation, Blizz-like presentation — confirmation, active processing, post-cancel | PASS | User screenshots; Cancel visible in both stages, post-cancel status says cancelled by player and previous saved market data unchanged; snapshot remains 291,981 auction records |

The cancellation consumes the one-shot attempt and 15-minute cooldown as designed. The user could not immediately start a second scan; the UI reported the cooldown/session state. No repeat scan was required to accept cancellation.

## Acceptance policy

The user has selected acceptance by exception: existing capabilities are treated as accepted unless a user-reported defect, reproducible failure, contradictory evidence, or material compatibility concern appears. This is an operational acceptance policy, not a claim that every feature has been tested or that all features are FOREVER VERIFIED. Preserve exact FOREVER OBSERVED scopes above; do not generalize them to all tabs/features.

## Offline verification

The active pytest suite passes **141 tests** on the working tree and again after fresh extraction. All **14/14 addon Lua files** pass `texluac -p`. The new asset tests verify all six outputs are valid 64×64 RGBA TGA files, have non-empty alpha, have editable SVG masters and provenance records, and are byte-for-byte reproducible by the included renderer. Manifest inventory is exact at 288 files. The final handoff records ZIP CRC and SHA-256.

## Remaining release gates

- ForeverDB data redistribution terms: current developer rules require visible credit/link on the free tier, prohibit resale/passing data off as one's own, require no bundled API key, and say developers fetch and bundle data with releases. Those rules are usage requirements, not an express general open-data licence. The rights applicable to this particular provider dataset remain subject to confirmation.
- CMaNGOS-derived data: provider labels some records as Classic data, not confirmed in Forever, and the provider credits CMaNGOS classic-db GPL-3.0. The package has not yet established a row-level rights chain for the mixed dataset. Do not claim these records are MIT-licensed.
- Remote repository: no 0.12.7 push or fresh full-tree hash comparison has been made.
- Retail runtime: NOT RUN.

## Evidence and sources

- User-provided Forever 1.60.1 screenshots in this conversation (runtime scopes above).
- ForeverDB developer rules: https://foreverdb.net/developers
- ForeverDB source description and Classic-data labels: https://foreverdb.net/about and https://foreverdb.net/addon
- CMaNGOS Classic-DB repository states GPL v3 and requires the licence file in redistributable packages: https://github.com/cmangos/classic-db
- CMaNGOS Classic-DB copyright notice distinguishes Blizzard copyrighted material from the database licence: https://github.com/cmangos/classic-db/blob/master/COPYRIGHT.md

## Decision

0.12.7 is a release-hardening candidate, not a public final release. The six local UI asset provenance gaps are closed by replacement with original project assets. ForeverDB/CMaNGOS data redistribution remains unresolved; 1.0.0 is not cleared.
