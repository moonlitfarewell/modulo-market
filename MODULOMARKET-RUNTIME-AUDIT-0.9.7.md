# MODULOMARKET RUNTIME AUDIT 0.9.7

## Result
Coordinated UI foundation correction implemented and packaged. Exact 0.9.6 source bundle retained unchanged as fallback. Offline validation passes. Forever runtime acceptance for 0.9.7 is NOT RUN.

## Player problem and evidence
The user's 0.9.6 screenshot showed an oversized dark upper background, title area that did not read as a native Blizzard title frame, content pushed down and workspace compressed. The screenshot is FOREVER OBSERVED evidence for 0.9.6 only, not 0.9.7.

## Source of truth inspected
Highest-version complete source available: `ModuloMarket-GitHub-Update-0.9.6.zip`, 2,355,867 bytes, 194 entries, ZIP CRC PASS, SHA-256 `47a518dc6ee4355baf7894cb1c95b4387a29bb317776fcc3d6cf15ec944e24c2`. Parent manifest, TOC and Core all reported 0.9.6. Inspected README, manifest, TOC, Core, complete MarketUI.lua, relevant UI audit/design records and regression tests. Child-specific PROJECT-START-HERE, WORKFLOW, PROJECT-DECISIONS, PROJECT-PROGRESS, QA and SOURCE-REVIEW-LEDGER are absent; missing history was not reconstructed.

## Root cause
0.9.6 overlaid `BasicFrameTemplateWithInset` with a custom 1424x78 surface and border, re-anchored/resized TitleBg and separately positioned TitleText, then shifted direct children and most frame regions by 28px after creation. This changed the background and addon coordinates rather than the actual Blizzard NineSlice/title geometry. The button skin suppressed native visual states and used custom red/dark fills. Panel headers had duplicate separators and bright side caps.

## 0.9.7 changes
- Keep `BasicFrameTemplateWithInset`; leave Blizzard TitleBg, TitleText anchors, NineSlice, Inset, TopTileStreaks and close-button geometry untouched; set only title text.
- Remove custom title/toolbar surface, custom title outline and global post-construction anchor-shift loop.
- Restore frame size 1460x866 and matching screen-fit calculation. Restore authored coordinates: metadata y=-38, tabs y=-112, content panels y=-158, footer y=-830.
- Preserve six zero-gap tabs, fills, top/bottom accents, hover and selected marker.
- Retain single-pixel shared outlines but reduce brightness/contrast.
- Simplify panel headers to muted dark plate plus one separator; remove duplicate lower rule and bright end caps.
- Replace red button resting fills with neutral dark surfaces; restore native normal/pushed/highlight feedback.
- Subdue dropdown popup border colour; preserve popup selection callbacks and lifecycle.
- No market acquisition/calculation, auction scan, recipe/gathering data, SavedVariables schema, dependencies, parent MODULO or specialist addon changes.

## Ownership and risk
All changes are ModuloMarket presentation. Main risk is actual target-client template rendering/texture layering. Offline source tests cannot prove the visual result. Button feedback and dropdown behavior require in-client acceptance.

## Validation
- Focused UI tests: 23 PASS.
- Full suite: 279 PASS / 61 failures. Compared with exact 0.9.6 parent suite: same 61 failing test IDs; zero new failures. Seven additional tests/assertions pass relative to parent.
- Lua syntax: `texluac -p` all 9 addon Lua files, 9/9 PASS.
- Fresh extraction, manifest inventory, ZIP CRC and fresh-extraction suite are validated after packaging.
- Forever runtime acceptance: NOT RUN for 0.9.7.

## Acceptance criteria
On WoW Forever 1.60.1 build 70938 verify native frame/title/NineSlice geometry; no oversized custom title background; title text placement; toolbar/tabs/panels/footer alignment; flush tabs; subdued single panel-header rule; neutral buttons and visible pressed/highlight feedback; retained internal borders; dropdown dismissal and reopening; search, filters, sorting, selection, scan controls, opacity and history. Until then 0.9.7 is SOURCE IMPLEMENTED, not FOREVER VERIFIED.

## Final package verification
- Release archive: `ModuloMarket-GitHub-Update-0.9.7.zip`
- Archive size before final audit refresh: 2361044 bytes; ZIP entries: 197; `ZipFile.testzip()` returned `None` (PASS).
- Fresh extraction: 197 files; manifest declares 197; exact sorted inventory match: True.
- Fresh-extraction full suite: 279 PASS / 61 historical failures; exact same 61 failure IDs as the 0.9.6 parent; zero new failing IDs.
- Fresh-extraction Lua syntax: 9/9 PASS.
