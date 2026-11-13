# ModuloMarket Native Frame Foundation 0.9.7

## Direction
Use Blizzard's default frame template as the structural foundation rather than simulating an enlarged title frame with custom textures and global coordinate manipulation. Keep the addon's six-tab workspace, but make addon-owned surfaces restrained and consistent.

## Source review and root cause
The 0.9.6 implementation used `BasicFrameTemplateWithInset`, but overlaid a custom 1424x78 surface, added a separate title-strip border, re-anchored and resized `TitleBg`, and shifted all direct frame children and regions by 28px after construction. This changed content placement without resizing the template's actual NineSlice/title frame. The result was an oversized dark gap and compressed workspace, as shown in the user's 0.9.6 screenshot.

The toolbar buttons were created from `UIPanelButtonTemplate`, but the custom skin hid most native visual states and painted a red/dark fill plus custom border. Panel headers used a filled plate, bright separator, duplicate dark separator and two bright end caps.

## 0.9.7 implementation
- Keep `BasicFrameTemplateWithInset` and leave `TitleBg`, `TitleText` anchors, `NineSlice`, `Inset`, `TopTileStreaks` and close-button geometry to Blizzard.
- Set only `frame.TitleText` content to `Modulo Market`.
- Remove custom title surface, custom title outline and post-construction child/region anchor shifting.
- Restore main frame size to 1460x866; restore authored content coordinates (toolbar metadata y=-38, tabs y=-112, content panel y=-158, footer y=-830).
- Preserve six edge-to-edge tabs, their backgrounds, top/bottom accents, selected marker and hover.
- Keep shared one-pixel outlines but reduce brightness/contrast.
- Simplify panel headers to muted dark plate and one restrained bottom rule; remove duplicate rule and bright side caps.
- Use neutral dark button fills and restore visible native normal/pushed/highlight template feedback.
- Subdue dropdown popup border colour without changing popup registration, close callbacks, selection or callback behavior.

## Scope and ownership
Only ModuloMarket presentation and tests/docs/release metadata changed. No parent MODULO source, specialist addons, market acquisition, auction scanning, calculations, recipe/gathering data, SavedVariables schema, dependencies or build-compatibility gates changed.

## Fallback
The exact 0.9.6 complete source bundle is retained unchanged as `ModuloMarket-GitHub-Update-0.9.6-FALLBACK-BACKUP.zip`, SHA-256 `47a518dc6ee4355baf7894cb1c95b4387a29bb317776fcc3d6cf15ec944e24c2`.

## Acceptance
On Forever 1.60.1 build 70938:
1. Native frame/title/NineSlice geometry appears as the default Blizzard template; no added blank title surface.
2. Title remains correctly positioned by the native title template.
3. Toolbar, tabs, panels and footer occupy the original 1460x866 layout without overlap/clipping.
4. Tabs remain flush.
5. Panel headers have one muted separator; no doubled rules or bright metal end caps.
6. Buttons have neutral surfaces and visible pressed/highlight feedback.
7. All internal panel/card/control borders remain legible but subdued.
8. Dropdowns close on main-window close and tab change, and work after reopening.
9. Filters, sorting, selection, tabs, scan controls, opacity and history remain functional.

## Validation status
Offline validation and package checks are recorded in the 0.9.7 standalone audit. Forever runtime acceptance is NOT RUN. The user's 0.9.6 screenshot is FOREVER OBSERVED evidence of the failed prior visual treatment, not 0.9.7 evidence.
