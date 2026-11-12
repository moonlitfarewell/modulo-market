# ModuloMarket 0.6.5 — ForeverDB acquisition-source detail integration

**Previous child update:** `ModuloMarket-GitHub-Update-0.6.4.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48 (unchanged)  
**Provider:** [ForeverDB.net](https://foreverdb.net)  
**Scope:** preserve the 70888 canonical acquisition-source records through runtime compilation and expose them in recipe inspection and tooltips.  
**Runtime status:** FOREVER RUNTIME NOT RUN.

## Player problem and observable result

The 0.6.4 runtime compiler reduced recipe acquisition records to recipe-wide booleans and broad source-type lists. It discarded NPC identities, locations, vendor costs, limited-stock information, recipe-item identities, drop/quest details and per-source evidence before the UI could display them. This is why recipes could show “source unknown” or “source recorded” without showing the actual trainer/vendor/quest/drop record already present in the canonical data.

0.6.5 retains the existing seven-tab UI and market/economics behavior while preserving those source records and making them inspectable.

## Source of truth and data counts

The active canonical file is `data/ForeverDB-Canonical-1.60.1.70888.json`, captured and normalized from the user-supplied 12 November ForeverDB capture. The canonical file itself is unchanged in this slice.

Across 2,493 recipe records, the canonical dataset contains 10,369 acquisition-source rows:

| Evidence | Source rows |
|---|---:|
| `FOREVER_OBSERVED` | 4,137 |
| `CLASSIC_BORROWED` | 2,292 |
| `UNKNOWN` | 3,907 |
| `FOREVER_CLIENT` | 33 |

Source types include 5,234 trainer rows, 1,580 vendor rows, 1,813 recipe-item rows, 1,629 drop rows, 80 quest rows and 33 automatic-learning rows. Counts are source rows, not unique NPCs or unique recipes.

## Before implementation: evidence and counter-evidence

- The canonical normalized JSON contains detailed per-recipe `acquisition_sources` with per-row `evidence` and, where supplied, `seen_in_forever`, `inferred`, `entity_evidence` and source text.
- The 0.6.4 compiler emitted only aggregate booleans (`sourceKnown`, `borrowedSources`, `sourceUnknown`) and omitted the `acquisition_sources` array. `ProfessionData.lua` consequently had no NPC/location/vendor-price fields to pass to the inspector.
- Some rows are explicitly `CLASSIC_BORROWED`; many drops and quests have `UNKNOWN` evidence. A quest's presence in the Forever client does not prove the recipe/quest acquisition relationship was observed. An NPC being observed does not prove that the NPC teaches a particular recipe.
- A recipe may have mixed observed, borrowed and unknown routes. A single recipe-wide boolean cannot safely describe every route; the UI must retain row-level evidence.

## Implementation

### Runtime compiler

- `compile-runtime` now retains a reviewed allow-list of normalized source fields: source type/name/faction; NPC ID/title; zone/map/coordinates; vendor copper and per-item price; stack size; currency costs; limited-stock fields; reputation faction; `seen_in_forever`; `inferred`; entity and recipe-edge evidence; source text; drop chance; quest ID/client-presence/URL; recipe-item ID/visibility.
- Trainer learning cost and its evidence are retained separately.
- The original canonical JSON and raw capture are not modified or bundled differently. No API key or new API request is involved.

### Runtime indexing

- `ProfessionData.lua` indexes source details by profession ID and recipe ID, including recipes already known by the character.
- Known recipes remain deduplicated. The UI can retrieve their ForeverDB details without adding another recipe row.
- Unlearned item-output recipes retain their complete normalized `acquisitionSources` array.
- Existing recipe-wide status behavior is retained for filters and economics. Per-source evidence is displayed independently and does not change profitability eligibility.

### Inspector and tooltip

- Selected recipe inspection shows up to three prioritized source records to protect the limited panel space.
- Recipe hover tooltip shows the full source list.
- Each record carries one of `FOREVER OBSERVED`, `FOREVER CLIENT`, `CLASSIC BORROWED — UNCONFIRMED`, or `UNKNOWN / UNVERIFIED`.
- Trainer/vendor rows show NPC name, faction, title, zone, NPC ID and coordinates where supplied. Vendor rows additionally show price/currency costs, limited stock and reputation metadata where supplied.
- Recipe items, drops, quests and automatic learning are identified separately.
- Inferred recipe-to-NPC links explicitly say the NPC was observed but the teaching relationship is unconfirmed.
- Unknown, missing, and Classic-borrowed evidence is never promoted to confirmed Forever availability.

## Ownership, compatibility and risk

- Only the optional ModuloMarket child repository changes. Parent MODULO 1.0.48 remains byte-for-byte unchanged.
- ModuloMarket continues to depend on MODULO; MODULO does not depend on ModuloMarket.
- No new runtime addon dependency, live HTTP/API call, SavedVariables schema change or auction snapshot gate change.
- Exact client build provenance and the independent exact-current-build market snapshot gate remain unchanged.
- Runtime Lua grew from 1,536,052 bytes to 5,035,631 bytes. The larger table may increase addon load time and memory use; this needs target-client observation.
- The inspector displays only the first three prioritized source rows; the recipe tooltip is the full-detail view.
- The 70888 canonical capture does not prove that every listed source remains currently available in-game. Evidence labels are preserved exactly as normalized; they are not new project runtime observations.

## Tests and verification

- New Python source-contract tests verify canonical source coverage, compiler field retention, runtime source index exposure and UI evidence labels.
- Existing ForeverDB importer, raw-adapter and 70888 refresh tests remain in the focused regression set.
- Lua provider harness verifies matching-build load, known recipe deduplication, queryable source details for an already-known recipe, and observed/borrowed/unknown source rows for future recipes.
- Lua syntax checks cover all nine addon Lua files.
- Full historical pytest suite results are reported in the standalone audit; legacy source-contract failures are not silently counted as passes.
- Archive CRC, fresh extraction, version/manifest agreement and SHA-256 are recorded at packaging.

## Player acceptance / exit criteria

1. On Forever build 70888, open My Crafts and select a known recipe with a ForeverDB source record. The inspector should show its acquisition details without duplicating the recipe row.
2. Open All Crafts and select an unlearned recipe with an observed trainer or vendor. Verify NPC, faction, location and vendor price where present.
3. Hover the recipe name. The tooltip should show all available source rows, not just the first three.
4. Select a recipe with mixed observed and Classic-borrowed routes. Each row must retain its own evidence label.
5. Select a recipe with unknown drop/quest links. It must remain explicitly unknown/unverified; client presence or NPC observation alone must not promote the link.
6. Verify vendor currency costs and limited-stock notes where the canonical data supplies them.
7. Confirm no Lua errors, load stalls, market snapshot gate regressions or changes to all seven tabs.

**FOREVER RUNTIME: NOT RUN.** Offline tests and harnesses do not establish in-client rendering, load performance, data validity or live acquisition availability.
