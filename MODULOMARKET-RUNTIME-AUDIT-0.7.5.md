# ModuloMarket Runtime Audit 0.7.5 — structured full-tooltip search

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.7.4.zip`  
**Previous bundle bytes:** 1,692,999  
**Previous bundle SHA-256:** `5e18ebb226ff1440f16a132fe71c776020db8c63b92275b5078a16665af27c04`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE VERIFICATION PENDING; FOREVER RUNTIME NOT RUN.

## Player problem and observable result

The player demonstrated that searching `spirit` could find Egg Nog because its reagent is Holiday Spirits, but did not find Wicked Smoothie even though its visible item tooltip says the effect grants Spirit. The desired behavior is for tooltip search to match the complete item tooltip, including effect/description text, not only recipe name and reagent fields.

The bundled ForeverDB 1.60.1.70888 record identifies Wicked Smoothie's output item as **249876**. Its recipe reagents do not contain Spirit; the tooltip effect is the relevant search source.

## Evidence and competing hypotheses

1. **Hidden GameTooltip extraction returns no/partial text:** plausible and directly exposed by source. The previous implementation treated `pcall(SetItemByID)` success as proof that tooltip lines were populated. A non-throwing setter call can still leave the hidden tooltip empty; the empty result was cached for the session.
2. **The player was testing the fast typing pass rather than the submitted tooltip pass:** possible because 0.7.4 intentionally limited tooltip/effect search to Enter. Typing alone only searches names, professions, IDs and reagents.

The distinguishing checks are:
- Submit the query with Enter.
- Run `/mmtooltipdebug 249876` and inspect the exact extracted text and extraction source.
- Confirm whether the returned text contains the visible effect wording and the token `spirit`.

## External API evidence

The Forever 1.60.1 API reference documents `C_TooltipInfo.GetItemByID(itemID)` returning structured `TooltipData` with a `lines` array; tooltip lines expose `leftText` and optional `rightText`. This supports a direct structured extraction path. It is API/source evidence, not proof of the target client's runtime behavior in this addon.

## Player-visible changes

- Full-tooltip search now prefers `C_TooltipInfo.GetItemByID` and combines all available left/right line text.
- The hidden GameTooltip path remains a fallback for clients without usable structured tooltip data.
- The fallback verifies actual line population. It retries using the item hyperlink if `SetItemByID` produced no lines, rather than trusting `pcall` success alone.
- Extraction diagnostics record structured reads, legacy fallbacks, empty results, last item ID, source and line count.
- `/mmtooltipdebug itemID` prints the exact normalized text used by search, split into bounded chat messages.
- `/mmsearchdebug` includes the extraction-path counters.
- Tooltip/effect search remains an explicit Enter submission. Ordinary typing does not trigger full-catalogue tooltip warmup.

## Ownership, dependencies and scope

- ModuloMarket remains a separate optional child addon depending on MODULO.
- MODULO 1.0.48 is unchanged and does not depend on ModuloMarket.
- No ForeverDB dataset, importer, credentials, auction snapshot, prices, recipe records, crafting scope or other tabs changed.
- No new addon dependencies or player-maintained search state were introduced.

## Offline verification

- Focused 0.7.5 regression tests: **6 passed** (`tests/test_modulomarket_0_7_5_structured_tooltip_search.py`).
- Lua syntax: changed `MarketUI.lua` and `Core.lua` both parsed successfully with `texlua` `loadfile` checks.
- Manifest/TOC/Core version agreement: **0.7.5**, PASS.
- Manifest inventory: **139 entries** including `MANIFEST.json`; `file_count=138` excludes the manifest itself. GitHub update ZIP: 139 entries, CRC PASS; required `modulo-market/` root folder PASS; fresh extraction and exact inventory comparison PASS.
- Full historical test suite is not treated as a clean gate because prior releases retained explicitly documented stale version-pinned tests; report current focused results separately.

## Forever runtime acceptance — NOT RUN

1. Open Crafts, choose Cooking and clear the search.
2. Enter `spirit` and press Enter.
3. Wicked Smoothie must appear because its item tooltip effect grants Spirit. Egg Nog may also appear because Holiday Spirits is a reagent.
4. Run `/mmtooltipdebug 249876`; output must include the visible Wicked Smoothie effect/description text and `spirit`.
5. Run `/mmsearchdebug`; structured extraction should be used on this client where available, with no repeated warmup/rebuild loop.
6. Search `healing` and `spell damage`; result sets must settle and match the visible tooltip content.
7. Clear search and switch tabs/profession/scope during a submitted search; stale work must not overwrite the new view.
8. No Lua errors, freezes, taint or broken UI interactions.

**Exit status:** SOURCE IMPLEMENTED; focused offline tests and changed-file Lua syntax PASS; historical suite 180 PASS / 59 FAIL (retained version-pinned and superseded UI assertions); Forever runtime NOT RUN. Keep the search defect open until the player-visible acceptance passes. Do not mark the defect closed until the player confirms the above on Forever build 70888.

## Reference

- Forever 1.60.1 structured tooltip API: https://warcraft.wiki.gg/wiki/API_C_TooltipInfo.GetItemByID
- Tooltip data line structure and Forever 1.60.1 availability: https://warcraft.wiki.gg/wiki/API%3AC_TooltipInfo.GetHyperlink
