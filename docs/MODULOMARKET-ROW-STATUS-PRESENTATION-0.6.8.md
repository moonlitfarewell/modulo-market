# ModuloMarket 0.6.8 — filter-aligned item-row presentation

**Previous child update:** `ModuloMarket-GitHub-Update-0.6.7.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; FOREVER RUNTIME NOT RUN.

## Player problem and observable result

Market rows exposed internal classification prefixes such as `[C]`, `[F]`, `[F?]`, `[?]`, `[G]` and `[M]`. The prefixes duplicated filter semantics, made names noisy and exposed provider-source confidence as if it were a separate player action.

0.6.8 removes all such prefixes from item and craft rows. Text colour is the only row-level status cue and mirrors the existing filters:

- **Green:** known by you / known craft output.
- **Gold:** unlearned craft output, regardless of whether the best acquisition record is direct Forever, Classic fallback or unknown.
- **Cyan:** gathering resource, when no known or unlearned craft-output category takes precedence.
- **Light blue:** crafting reagent, when no higher-priority craft or gathering category applies.
- **Default text:** ordinary market item with no matching craft/gathering/material role.

Known craft output takes precedence over unlearned output, which takes precedence over gathering, then crafting reagent. This matches the known-output precedence already used by the item-role filter. In All Crafts and My Crafts, learned recipes are green and all unlearned candidates are gold.

## Evidence and counter-evidence

- 0.6.7 already reduced player-facing recipe filters to All / Known / Unlearned and item-role filters to All / Known craft outputs / Unlearned craft outputs / Gathering resources / Crafting reagents.
- `ProfessionData.GetItemTags` already supplies the semantic roles needed to render those categories. The presentation change does not change classification, filtering or source selection.
- A market item may belong to more than one role. The explicit precedence above avoids concatenating multiple tags or competing colours.
- Borrowed and unknown acquisition evidence remain available internally and continue to be considered by the 0.6.6 primary-source selection rule. They deliberately share the unlearned gold colour and are not distinguished on list rows.
- Inspector badges and the compact acquisition detail are unchanged; this slice only changes row-name presentation and an obsolete All Crafts tooltip sentence.

## Implementation and ownership

- Updated `MarketUI.lua` to return names without bracket prefixes and select one filter-aligned colour.
- Removed `[C]`, `[F]`, `[F?]` and `[?]` prefixes from craft rows; known rows use green and unlearned rows use gold.
- Updated the All Crafts tab tooltip so it no longer claims borrowed/unknown sources are labelled on rows.
- Bumped ModuloMarket TOC, runtime version and child manifest together to 0.6.8.
- No canonical ForeverDB data, API usage, credentials, SavedVariables schema, dependencies, source precedence, filters, parent MODULO or optional-addon ownership changed.

## Tests and verification

- Focused regression tests cover prefix removal, colour/category mapping, source-class colour unification and version agreement.
- Lua syntax and in-client rendering are not claimed unless separately executed and recorded in the release handoff.
- Forever runtime: **NOT RUN**. Offline checks cannot prove client rendering or tooltip behavior.

## Player acceptance

1. Open All Items and confirm no `[C]`, `[F]`, `[F?]`, `[?]`, `[G]` or `[M]` prefixes appear.
2. Confirm known craft outputs are green, unlearned craft outputs gold, gathering resources cyan and crafting reagents light blue.
3. Confirm an item with multiple roles uses the precedence documented above and does not show multiple colours/tags.
4. Open My Crafts and All Crafts: known recipes are green; unlearned recipes are gold, including Classic-fallback and unknown-source candidates.
5. Confirm item selection, hover tooltips, filters and the compact acquisition inspector remain functional, with no Lua errors.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; FOREVER RUNTIME NOT RUN. Player-visible acceptance remains open until tested on the target client.
