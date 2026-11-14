# Modulo Market 0.12.1 — item rarity markup correction

Date: 2026-11-14

## Player problem and observable result

The player supplied a Forever screenshot from 0.12.0 showing item names with visible fragments such as `|c...`, missing leading characters, and incorrect colours. This is a rendering/markup defect, not evidence that the saved item names themselves are corrupted.

Expected result: every item-name colour escape must use WoW's required eight hexadecimal digits (alpha + RGB), and the full original item name must remain visible for every supported quality. Unknown quality remains neutral white. No rarity-triggered item-data requests are introduced.

## Evidence and root cause

Inspected the exact uploaded `ModuloMarket-GitHub-Update-0.12.0.zip`, including `AddOns/ModuloMarket/MarketUI.lua`.

The source had an inconsistent return contract:
- `ITEM_QUALITY_COLORS[quality].hex` parsing captured six RGB digits.
- `GetItemQualityColor()` fallback also formatted six RGB digits.
- The unknown-quality fallback returned eight digits (`ffffffff`).
- `GetItemDisplayName()` prepended only `|c` and assumed the helper always returned eight digits.

WoW colour markup requires `|c` followed by eight hexadecimal digits, then the text, then `|r`. When the helper supplied only six digits, the parser consumed the first two characters of the item name as the missing alpha channel. This directly accounts for visible markup fragments, incorrect colours, and leading name characters disappearing. Names beginning with hexadecimal characters (A–F and 0–9) make the corruption especially apparent.

The previous assistant's diagnosis was directionally correct but incomplete: the defect is not simply that the display call omitted an alpha prefix in isolation. The underlying helper returned mixed-length values. The fix establishes one canonical eight-digit return contract for every path.

## Competing explanations considered

1. **Malformed colour escape / mixed-length helper output.** Confirmed by direct source inspection and matches the screenshot symptoms exactly.
2. **Corrupted item names or search-index data.** Not supported by this screenshot: the visible literal `|c` sequence and missing leading characters are consistent with the malformed WoW escape being interpreted during rendering. Search/catalogue data is not rewritten by the display formatter.

The screenshot alone cannot establish whether every other display surface is affected; source inspection shows the shared formatter is used by the market rows, inspector and Modern presentation.

## Implementation in 0.12.1

- Added `NormalizeItemQualityHex()`.
- Six-digit RGB values are normalized to `ff` + RGB.
- Existing eight-digit alpha+RGB values are preserved.
- Invalid/missing colour values fail closed to `ffffffff`.
- Both `ITEM_QUALITY_COLORS` and `GetItemQualityColor()` paths use the same normalizer.
- `GetItemQualityHex()` now consistently returns exactly eight hex digits.
- `GetItemDisplayName()` retains the standard `|c` + eight digits + name + `|r` format.
- All row/inspector/Modern consumers continue using the shared display formatter.
- Passive quality lookup is retained; no item-data requests were added.
- No SavedVariables schema, search behavior, market-data acquisition, addon dependency or scan behavior changed.

## Ownership and dependencies

Modulo Market owns its display formatter. ProfessionMaster remains reference evidence only; there is no dependency on ProfessionMaster. The correction is local to Modulo Market's item-name formatting.

## Validation

- Focused 0.12.1 rarity and 0.12.0 search compatibility tests: **11 passed**.
- Full suite on exact 0.12.0 archive: **368 passed / 90 failed**.
- Full suite on 0.12.1 working tree: **373 passed / 90 failed**.
- The exact same 90 failing test IDs occur in both runs; **zero new failing IDs**, five additional passes.
- Lua syntax: **14/14 addon Lua files passed** `texluac -p`.
- Fresh extraction focused tests and syntax are required and recorded after packaging.
- ZIP integrity, exact manifest inventory and SHA-256 are recorded after packaging.

## Runtime status and limitations

- Forever: **0.12.1 NOT RUN**. The player screenshot is Forever evidence of the 0.12.0 defect, not proof of the correction.
- Retail: **NOT RUN**.
- 0.11.9 opening/population without the previous hang was player-observed. 0.12.1 preserves that passive rarity approach, but no new runtime stability claim is made.
- Correct rarity display on Forever must be confirmed after installation.

## Acceptance test on Forever

1. Install 0.12.1 over 0.12.0 without deleting SavedVariables.
2. Open `/mm` and confirm it remains responsive and the catalogue populates.
3. Inspect rows whose names begin with letters A–F and digits 0–9 (for example `A Head Rag`, `7 Pound Yellowtail`, and `9-60 Battery Pack` if present).
4. Confirm names display completely, with no literal `|c` fragments or missing leading characters.
5. Check common, uncommon, rare, epic and legendary items for appropriate rarity colours when item quality is cached.
6. Check an uncached item remains neutral white rather than triggering a load request.
7. Check the selected-item inspector and Modern presentation for the same formatting.

## Documentation completeness gate

- Root cause, code change, scope and remaining runtime gaps recorded here.
- README and MANIFEST updated.
- Historical test failures preserved and compared against the exact 0.12.0 archive.
- Standalone audit is included in the complete bundle.
