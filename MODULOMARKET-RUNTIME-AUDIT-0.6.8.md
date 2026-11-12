# ModuloMarket Runtime Audit 0.6.8 — filter-aligned item-row presentation

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.6.7.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; LUA SYNTAX PASS; FOREVER RUNTIME NOT RUN.

## Player problem and observable result

Market item rows exposed internal bracket prefixes such as `[C]`, `[F]`, `[F?]`, `[?]`, `[G]` and `[M]`. These codes duplicated the filter controls, cluttered item names and made acquisition-source confidence look like a separate player-facing category.

0.6.8 removes those prefixes from item and craft rows. Text colour alone now communicates the same categories exposed by the filters:

- **Green:** known by you / known craft output.
- **Gold:** unlearned craft output, regardless of whether its best acquisition record is direct Forever, Classic fallback or unknown.
- **Cyan:** gathering resource, when no craft-output category takes precedence.
- **Light blue:** crafting reagent, when no higher-priority category applies.
- **Default text:** ordinary market item with no matching craft, gathering or material role.

The overlap precedence is known craft output, then unlearned craft output, then gathering resource, then crafting reagent. In My Crafts and All Crafts, known recipes are green and all unlearned candidates are gold.

## Evidence and counter-evidence

- The 0.6.7 filters already define the player-facing categories: All / Known / Unlearned and All item types / Known craft outputs / Unlearned craft outputs / Gathering resources / Crafting reagents.
- `ProfessionData.GetItemTags` provides the existing semantic roles; no classification or filter logic was changed.
- Items can have multiple roles. The explicit precedence prevents multiple prefixes or competing colours.
- Borrowed and unknown source evidence remains preserved internally and continues to feed the existing primary-acquisition selection rule. These classes intentionally share the unlearned gold colour.
- Inspector badges and the compact selected-recipe acquisition block are unchanged. Only list-row names and the obsolete All Crafts tab tooltip were changed.

## Implementation and ownership

- Removed internal bracket prefixes from item and craft rows.
- Added one filter-aligned colour per item name.
- Updated the All Crafts tab tooltip so it no longer says borrowed/unknown sources are labelled on rows.
- Advanced Core, TOC and manifest together to ModuloMarket 0.6.8.
- Parent MODULO 1.0.48 is unchanged. ModuloMarket remains an optional child addon.
- No API requests, credentials, canonical ForeverDB data, SavedVariables schema, dependencies, acquisition-source precedence or market calculations changed.

## Tests and verification

- Focused regression tests: **28 passed** across row presentation, recipe-source filters, compact acquisition presentation, inspector footer, layout and ForeverDB refresh contracts.
- Lua syntax: **PASS**, all 9 addon Lua files parsed using the available LuaTeX interpreter.
- Full historical pytest suite: **159 passed, 39 failed**. The failures are legacy source-contract tests pinned to earlier release versions or earlier UI/layout implementations; they are not counted as passes. The focused current-slice and relevant regression set passes.
- Archive integrity, fresh extraction and manifest agreement are recorded in the release handoff.
- Forever runtime: **NOT RUN**. Offline checks do not prove in-client appearance, tooltip behavior or absence of runtime errors.

## Player acceptance

1. Open All Items and confirm no `[C]`, `[F]`, `[F?]`, `[?]`, `[G]` or `[M]` prefixes appear.
2. Confirm known craft outputs are green, unlearned craft outputs gold, gathering resources cyan and crafting reagents light blue.
3. Confirm items with overlapping roles follow the precedence above.
4. Open My Crafts and All Crafts: known recipes are green; all unlearned recipes are gold, including Classic-fallback and unknown-source candidates.
5. Confirm selection, hover tooltips, filters and the compact acquisition inspector still work and no Lua errors appear.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; LUA SYNTAX PASS; FOREVER RUNTIME NOT RUN. Player-visible acceptance remains open until tested on the target client.
