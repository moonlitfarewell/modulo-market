# ModuloMarket Runtime Audit 0.8.1 — All Items visual foundation

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.8.0.zip`  
**Previous bundle size:** 1,720,115 bytes  
**Previous bundle SHA-256:** `ce3d4c486808a2404bc4f6bdecde0e81fcfbf1c84573d25f7c7f669fffe61d31`  
**Source baseline:** GitHub `moonlitfarewell/modulo-market` `main` at commit `b6a6a1410a1b80eb7a7b3ac41de74f6980cc4206`; commit is one commit ahead of 0.7.9 `ab6fb51bfb2f0bf3439f5d79aad5bb4bef4c4a76`. The local 0.8.0 archive's `MarketUI.lua`, `MANIFEST.json`, `README.md` and 0.8.0 audit Git blob hashes match the fetched GitHub `main` blobs.  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; FOCUSED TESTS 34 PASS; LUA SYNTAX 9 FILES PASS; PROFESSION CAPTURE HARNESS PASS; FULL HISTORICAL SUITE 203 PASS / 65 LEGACY OR SUPERSEDED FAIL; ZIP CRC PASS; FRESH EXTRACTION PASS; MANIFEST 150/150; VERSION AGREEMENT PASS; FOREVER RUNTIME NOT RUN.

## 1. Player problem and observable result

The 0.8.0 All Items screen already has a working three-panel layout and market table, but the header's data context is spread across a market metadata line, a long status line, controls and the footer. The Selected Item inspector presents market values as loose rows, puts relationships into one long text area, and places the history graph in a separate footer. The result is functional but less structured and less legible than the user-approved All Items proof of concept.

The 0.8.1 player-visible target is:
- a clearer header with the existing market metadata, a truthful scan-state indicator, and explicit auction/recipe data provenance;
- the same six existing tabs, with no reintroduced My Crafts tab;
- the same All Items market columns, search, filters, sorting, row selection and tooltips;
- a Selected Item inspector arranged as three visually distinct sections: Market Information, Relationships and Market History;
- a scrollable Relationships area so long recipe/gathering details are not cut off by a fixed-height text region;
- no invented data, status, scan percentage or relationship.

## 2. Evidence and counter-evidence

### Evidence actually inspected

- Supplied 0.8.0 child bundle: ZIP CRC PASS, 148 entries, manifest version 0.8.0 and 148/148 manifest-listed files.
- Parent MODULO 1.0.48 archive: 41,236,015 bytes; SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`; ZIP CRC PASS; size and hash match the child manifest's parent provenance.
- GitHub `main` is 0.8.0. The latest repository commit is `b6a6a1410a1b80eb7a7b3ac41de74f6980cc4206`; it is one commit after 0.7.9 commit `ab6fb51bfb2f0bf3439f5d79aad5bb4bef4c4a76`.
- Exact Git blob matches were verified between the local 0.8.0 archive and GitHub `main` for `MarketUI.lua` (`ed818c48a5d72902714a295b64ee1663a4580795`), `MANIFEST.json` (`d1d38a8d522367d826e67a19d24e611d169d12e7`), `README.md` (`8b04addac8c4df552b3de4b8029b533bd7236d8e`) and `MODULOMARKET-RUNTIME-AUDIT-0.8.0.md` (`e5104c70f35f411a77e13340a447eba3f838b8fb`).
- `MarketUI.lua` already owns the main frame, six tabs, three panels, virtualized table, selected-item renderer, relationship text and market history renderer.
- `RenderMarketRecipeContext()` derives crafting/gathering relationships from existing recipe and profession data. `RenderCraftDetail()` derives selected recipe acquisition/reagent/economics details from existing recipe data.
- `UI.RenderHistory()` reads `MM.db.marketHistory`, takes up to four saved full-market points, displays recorded date/price/quantity and draws the existing four-bar history graph.
- `GetSnapshot()` exposes the current complete auction snapshot. Snapshot records carry `clientBuild` and `timestamp`.
- `MM.ProfessionData.GetFutureProviderStatus()` exposes provider dataset/current build match and review-count metadata used for recipe provenance.
- `Replicate.GetState()` exposes `active`, `stage`, `pendingConfirmation`, `attemptedThisSession` and `cooldownRemaining`. It does **not** expose a percentage-complete field.

### Counter-evidence and constraints

- The 0.8.0 interface already contains the underlying information and most controls. This is a presentation/hierarchy improvement, not a new market or recipe capability.
- The user previously removed My Crafts because it duplicated the existing Crafts workspace. 0.8.1 retains the six tabs and does not add it.
- The mockup's scan progress bar cannot be implemented truthfully from the current Replicate state contract. 0.8.1 shows scan state only and deliberately does not display a fabricated 0%/100% or percentage.
- Recipe `Current`/`Baseline` and `Review` labels are derived from the provider status. Auction `Current` is shown only when the snapshot's client build matches the provider/current client build; otherwise the label says build mismatch or build unknown.
- The supplied child bundle does not contain separate child-level `PROJECT-START-HERE`, `WORKFLOW`, `PROJECT-DECISIONS`, `PROJECT-PROGRESS`, `QA`, `SOURCE-REVIEW-LEDGER` or standalone architecture records. The parent MODULO 1.0.48 bundle was consulted for its start-here, workflow, progress, decisions, QA, review ledger, architecture and Forever compatibility contract. Parent 1.0.48 confirms child addons remain separate packages, with Market depending on MODULO and no reverse dependency. No missing child chat/history was reconstructed.

## 3. Current implementation and acceptance evidence

The 0.8.0 baseline had:
- an existing 1460 × 850 main window with three panels;
- a 300-pixel right inspector;
- market values and relationship detail rendered in a large fixed text area;
- a history footer anchored to the inspector bottom;
- a market metadata line and generic status line;
- six existing tabs.

The 0.8.1 implementation changes only `AddOns/ModuloMarket/MarketUI.lua`, release version metadata, README/manifest, focused tests and this audit:
- reflows the existing header controls to make room for truthful scan and data labels;
- adds auction snapshot build identification and current/mismatch/unknown status from snapshot/provider/client evidence;
- adds recipe dataset build, current/baseline and review count from `GetFutureProviderStatus()`;
- adds a scan state label from existing Replicate state; no percentage progress is claimed;
- builds three gold-bordered inspector cards in the existing right panel;
- places market price, listed quantity, at-price quantity and best-craft-profit values in Market Information;
- places the existing recipe/gathering/recipe-detail text inside a scroll frame, with content height measured from the font string and mouse-wheel scrolling;
- moves saved market history text and the existing four-point graph into the Market History card;
- keeps recipe profit margin visible in the scrollable recipe detail text while the compact profit row shows the money value;
- retains the existing six tabs, market table columns, row pool, sort behavior, filters, selection, tooltips, opacity, crafting-scope dropdown and data attribution.

## 4. Ownership, dependencies and Forever boundaries

- Owner: optional child addon ModuloMarket.
- Parent MODULO 1.0.48 remains unchanged.
- ModuloMarket continues to depend on MODULO; MODULO does not depend on ModuloMarket.
- No new addon dependency, API request, SavedVariables field/schema, database, recipe dataset, auction snapshot gate, market calculation or external-addon integration was added.
- UI changes use existing WoW frame/texture/font-string/ScrollFrame controls already used by the addon. The actual Forever behavior and visual layout still require client acceptance.
- Forever evidence remains NOT RUN for this changed UI path. Static source checks do not establish Forever runtime compatibility.

## 5. Risks and scope

- The inspector's three card heights and scroll-frame geometry may need adjustment at the player's exact screen resolution/UI scale.
- The `UIPanelScrollFrameTemplate` scrollbar placement and mouse-wheel behavior must be checked in Forever.
- Long relationship content must remain accessible and must not overlap Market History.
- Header labels may need width adjustments if actual build strings/review counts exceed the available width.
- Scan-state labels are only as current as `Replicate.GetState()`; no synthetic progress state is added.
- Market/recipe data correctness is unchanged and is not re-certified by this visual slice.
- All Items table columns, market rows and filter semantics are intentionally unchanged.

## 6. Verification

### Focused regression suite

Command:
`python -m pytest -q tests/test_modulomarket_0_8_1_visual_foundation.py tests/test_modulomarket_0_8_0_status_integrity.py tests/test_modulomarket_ui_0_6_4_layout.py tests/test_modulomarket_ui_0_6_3_inspector_footer.py tests/test_modulomarket_profession_capture_0_7_8.py tests/test_modulomarket_0_7_7_debounced_search_and_sell_launcher.py`

Result: **34 passed**.

### Lua syntax

Command: `texluac -p` for every `AddOns/ModuloMarket/*.lua` file.  
Result: **9 files PASS**.

### Existing profession capture harness

Command: `texlua tests/profession_capture_0_7_8_harness.lua`  
Result: **PASS** (`ModuloMarket 0.7.8 profession capture harness PASS`).

### Full historical suite

Command: `python -m pytest -q`  
Result: **203 passed, 65 failed**. The retained historical suite still contains old version-pinned and superseded UI-contract assertions, including a prior My Crafts-tab expectation and earlier inspector/layout assumptions. The 65 failures are not represented as passes or removed from the suite. The previous 0.8.0 audit also recorded 65 historical/superseded failures (199 passed); 0.8.1 does not increase the recorded failure count. Focused current-slice tests are green.

### Package validation

Final bundle validation: `ModuloMarket-GitHub-Update-0.8.1.zip`; exact manifest inventory 150/150; ZIP CRC PASS; fresh extraction PASS; focused tests rerun from fresh extraction — 34 PASS; Lua syntax rerun from fresh extraction — 9/9 PASS; TOC/Core/manifest all 0.8.1; SHA-256 recorded in the release handoff.

## 7. Forever runtime acceptance — NOT RUN

Target: WoW Forever 1.60.1 build 70888.

1. Install 0.8.1 over 0.8.0 and open ModuloMarket at the same resolution/UI scale as the supplied screenshot.
2. Confirm the existing six tabs remain present and no My Crafts tab appears.
3. Confirm the header displays the market snapshot age/count, auction build/status, recipe dataset build/status/review count, opacity and crafting scope without overlapping.
4. Confirm scan state changes appropriately between Idle, Active, Confirmation required, Used this session and Cooldown. Do not expect a percentage progress bar.
5. On All Items, confirm all existing columns, sorting, search, profession/item-role filters, row selection and item tooltips still work.
6. Select an item with no recipe/gathering relationships. Confirm the Relationships section reports the existing unknown/no-known-relationship message rather than inventing a relationship.
7. Select an item with several crafting and gathering relationships. Scroll the Relationships area with the wheel and scrollbar; confirm all content remains reachable and does not overlap Market History.
8. Confirm Market Information shows only available price/listing/at-price/best-craft-profit values; unavailable values remain `—`.
9. Confirm Market History shows saved points only; test both no-history and populated-history cases and verify the four-point graph matches the displayed prices/quantities.
10. Switch through all six tabs, change crafting scope, adjust opacity, filter/search, sort and select another item. Confirm no UI control disappears or stops responding.
11. Check for Lua errors, clipping, overlapping text, broken scrollbars and frame/tooltip layering.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS 34 PASS; FRESH-EXTRACTION TESTS 34 PASS; LUA SYNTAX 9/9 PASS; FRESH-EXTRACTION LUA SYNTAX 9/9 PASS; PROFESSION CAPTURE HARNESS PASS; FULL HISTORICAL SUITE 203 PASS / 65 LEGACY OR SUPERSEDED FAIL; ZIP CRC PASS; FRESH EXTRACTION PASS; MANIFEST 150/150; TOC/CORE/MANIFEST VERSION 0.8.1; FOREVER RUNTIME NOT RUN. Player-visible acceptance remains OPEN until the user tests 0.8.1 on build 70888.
