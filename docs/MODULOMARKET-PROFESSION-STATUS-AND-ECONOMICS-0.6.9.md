# ModuloMarket 0.6.9 — character-aware Crafts, Materials and Economics

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.6.8.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS AND LUA SYNTAX PASS; FOREVER RUNTIME NOT RUN.

## Player problem

The previous UI separated learned recipes into My Crafts and all supported recipes into All Crafts. Materials only distinguished known and unlearned craft outputs. This did not answer the useful planning question: which recipes belong to professions this character actually has, and which require a profession they do not have? Economics also resembled All Items too closely.

## Adopted behaviour

### Six-tab navigation

- All Items
- Economics
- Crafts
- Materials
- Low Supply
- History

My Crafts and All Crafts are consolidated into one Crafts tab. It contains the known recipes captured automatically from profession windows plus supported unlearned recipe candidates. Existing craftability, profitability, review and loss filters remain.

### Character-aware recipe status

- **Known by you (green):** recipe was captured as learned by this character.
- **Learnable (gold):** character has the profession. The recipe may require more skill; the selected-recipe inspector shows current skill and the recipe's recorded learning threshold when available.
- **Not learnable (red):** an authoritative native profession list confirms the character does not have the recipe's profession.
- **Unknown (neutral grey):** the client profession list is unavailable or the required status cannot be established. It is not mislabelled red.

The native `GetProfessions` / `GetProfessionInfo` result is used to determine profession ownership and skill. The captured ProfessionMaster recipe summary is a fallback for positive profession observations only; absence from that partial capture is not treated as proof that a profession is absent. Learnable/Not learnable filters are disabled unless the native profession list is available.

Skill eligibility is separate from profession ownership. `canLearnNow` is only true when both current skill and a numeric learning threshold are available and current skill meets that threshold. Unknown thresholds are not guessed.

### Materials

The shared item-role dropdown now exposes Known craft outputs, Learnable craft outputs, Unavailable craft outputs, Gathering resources and Crafting reagents. The same status semantics and overlap precedence apply.

Skinning coverage now includes the core classic leather/hide progression tiers: Light, Medium, Heavy, Thick and Rugged leather/hide. This is an explicitly conservative subset, not a complete creature-to-item skinning loot catalogue. Special scales and creature leathers without evidenced skill gates remain unmapped.

### Economics

Economics now has a distinct item-analysis table:

- Cheapest market unit price
- Best available craft cost
- Recent saved price movement
- Total market units
- Best craft profit

Its relationship filters are Crafted outputs, Gathered/collected, Crafting reagents and Other market items. Filters combine as OR when more than one is checked; with none checked, all items remain visible.

Dropped/loot and vendor-sourced item filters are visible but disabled. The current ForeverDB data describes acquisition of recipes (trainer/vendor/drop/quest), not a complete source catalogue for the market item itself. Treating recipe-learning sources as item-origin data would be incorrect. These filters require a reliable item-acquisition dataset before they can be enabled.

## Evidence and counter-evidence

- The active 70888 canonical dataset and field-level source evidence are unchanged.
- Existing `ProfessionData` recipe output and reagent relationships remain the basis for craft/material roles.
- Native profession APIs are used only through guarded calls. If absent or failing, the addon preserves an Unknown state rather than inferring missing professions.
- The core Skinning mapping is a limited item/threshold list, not proof of every skinning output or creature loot table.
- Economics' item-origin data gap is explicit: current recipe acquisition source rows cannot safely classify all market items as dropped or vendor-sourced.

## Ownership, dependencies and scope

- Only the optional ModuloMarket child addon changes. Parent MODULO 1.0.48 is unchanged.
- ModuloMarket continues to depend on MODULO; MODULO does not depend on ModuloMarket.
- No new dependency, API request, credential, SavedVariables schema, auction snapshot rule, ForeverDB canonical record, acquisition precedence or pricing formula is introduced.
- Existing exact-build auction market snapshot compatibility remains unchanged.

## Tests and acceptance

Offline tests cover the three learning states, unknown-state safety, native profession API use, consolidated navigation, economics filters/table semantics, Skinning subset and release version agreement. Lua syntax is checked across all nine addon Lua files.

Forever runtime is **NOT RUN**. Player acceptance must verify:
1. Exactly six tabs appear and Crafts contains known plus unlearned candidates.
2. Known is green, Learnable gold, Not learnable red; Unknown stays neutral when native profession ownership cannot be read.
3. Profession skill/current threshold appears accurately in the selected recipe panel.
4. Materials offers the same status filters and Skinning leather/hide items appear.
5. Economics shows cheapest price, craft cost, saved price change, total units and best craft profit; category filters combine correctly.
6. Dropped/loot and Vendor sourced remain visibly disabled, not silently inferred.
7. Search, profession selection, sort, selection restore, hover tooltips and all remaining tabs work without Lua errors.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; LUA SYNTAX PASS; FOREVER RUNTIME NOT RUN.
