# ModuloMarket UI redesign decision — 0.5.6

## Reference and intent

The user-selected `Modulo Market_ All Crafts Dashboard.png` is the visual premise, not a pixel-perfect specification. The implementation uses a Dark Foundry treatment: charcoal/near-black work surfaces, blackened-metal framing, muted bronze/gold headings and restrained status colours.

## Persistent workspace contract

1. Global market actions and status occupy the top toolbar.
2. All seven existing tabs remain directly accessible beneath the toolbar: All Items, Economics, My Crafts, All Crafts, Materials, Low Supply and History.
3. Search and the existing profession/item-role selectors occupy the left contextual filter column.
4. The centre is the largest workspace and retains the full information appropriate to the active tab.
5. The right column persistently inspects the selected row without leaving the active tab.

No tab, data source, market action, calculation, source status, or recipe evidence class is intentionally removed by this layout pass. Existing filters are preserved and their search/profession/role state is stored independently per tab.

## All Crafts columns

The centre table exposes Recipe, Sale / Unit, Materials, At Price, Total and Profit / Craft. `At Price` is the count available at the lowest ask (`minPriceQuantity`); `Total` is total listed quantity (`totalQuantity`). Profit remains subject to the existing exact-current-client auction snapshot gate and incomplete-input safeguards.

Other tabs retain their own six-column interpretation; the extra columns expose existing market depth, total quantity/listing and best craft-profit information where available rather than replacing the tab's existing data model.

## Layout implementation

- Initial logical frame: 1460 × 850.
- Screen-fit scaling is applied when screen dimensions are exposed, with a 0.70 lower scale bound.
- Left filter, centre data and right detail panels have separate dark surfaces.
- Seven tabs remain full-width and persistent.
- Virtualized rows, incremental filtering/sorting and existing selected-item detail rendering remain in use.

## Profession capture cache decision

`C_TradeSkillUI.GetAllRecipeIDs()` returns all recipe IDs for the open profession, including learned and unlearned entries; the ID list alone therefore cannot indicate when an existing recipe changes from unlearned to learned. A recipe-list signature is used to avoid rebuilding schematics when ordinary profession events leave the recipe-ID set unchanged. The `NEW_RECIPE_LEARNED` event forces a refresh even when the ID set is unchanged. A 0.50-second event coalescing delay merges event bursts. A forced learn event arriving during an active capture queues one follow-up capture.

This keeps recipe learning automatic; no manual reporting, click-to-start action, keypress reporting or manual cooldown state is introduced.

## Evidence and limits

- Source inspection confirms the prior implementation scheduled full captures on `TRADE_SKILL_SHOW`, `TRADE_SKILL_LIST_UPDATE` and `TRADE_SKILL_DATA_SOURCE_CHANGED` without comparing the current recipe list to the saved profession list.
- Offline harness coverage verifies unchanged-list suppression and forced capture when a recipe becomes learned while the recipe-ID list remains identical.
- Public API reference: https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetAllRecipeIDs (learned and unlearned IDs are included).
- Public API reference: https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetRecipeInfo (`learned` is the per-recipe learned-state field).
- Event reference: https://wowlua.dev/api/events/NEW_RECIPE_LEARNED (recipe-learning event and payload).
- Event reference: https://wowlua.dev/api/events/TRADE_SKILL_LIST_UPDATE (profession list update event).
- The target Forever build's exact event cadence and live UI rendering remain runtime acceptance work. Offline harnesses do not prove Forever runtime behavior.
