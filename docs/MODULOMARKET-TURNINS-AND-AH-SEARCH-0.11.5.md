# Modulo Market 0.11.5 — Turn-Ins, history and Auction House search refinement

## Player problem and observable result

The player reported that the History panel still appeared to show four records despite an agreed three-day limit; the tab rails felt progressively oversized; Turn-In Type did not filter Waylaid Crates; the Category / Profession dropdown offered irrelevant options; Writ reputation labels were unnecessarily qualified; and there was no way to pass a visible market item into the Auction House search field without retyping its name.

0.11.5 provides:

- Market History is fail-closed to the rolling last 72 hours. It can show up to four completed full-market snapshots within those 72 hours; four snapshots do not imply four separate days.
- Blizz-like tabs use a compact fixed 178×28 geometry and are centred in the existing strip. Modern tabs use a fixed 1472×40 rail with 38-pixel buttons.
- Every Waylaid Crate row is explicitly `turnInType="crate"`; Craftsman's Writ rows remain `turnInType="writ"`.
- The Category / Profession selector changes its options and label by Turn-In Type: crate categories for Waylaid Crates, professions for Craftsman's Writs, and both when All Turn-Ins is selected. Switching type resets a category selection that is invalid for the new type.
- Both views use the same five Turn-In columns: Turn-In Item, Cost, Gross, Rep / Favor and Net / Reward. Compact reward values read `Fav` and `Rep`. The Writ inspector says `Reputation`; no visible asterisk or "reported" label remains.
- The Modern title is centred and no longer has the M logo. The redundant toolbar Close button is removed; the standard top-right X remains as window chrome, with Escape and `/mm` still available.
- A new white circular refresh arrow is bundled as `Textures/refresh.tga`.
- Shift-clicking an item's icon/name row in either view fills the native Classic Auction House Browse search field when `AuctionFrame` is open. The field is focused and highlighted, but the search is not submitted automatically. Chat link insertion is not hooked or replaced.

## Exact evidence and counter-evidence

### History window

- `UI.RenderHistory` already intended to use `now - 3 * 86400` and retained up to four points.
- The prior code used `cutoff == 0` as an allow-all fallback. If the client clock source returned an unavailable/zero value, old history could pass through without a time limit.
- 0.11.5 requires a valid positive client timestamp and a positive snapshot timestamp, then includes only records with `stamp >= now - 259200`.
- Four completed scans may legitimately fall within a rolling 72-hour window. The UI still retains up to four chart points; it is not a three-record limit.

### Waylaid Crate filtering

- `BuildRows` explicitly assigned `turnInType="writ"` to Writ rows but did not assign a type to crate rows.
- The shared view builder filters with exact equality against `build.turnInTypeFilter`. Thus selecting `crate` rejected every crate row. 0.11.5 sets `turnInType="crate"` on each generated crate row; no UI-side exception is used.

### Category / Profession selector

- The prior two presentations offered the union of seven crate categories and five Writ professions for every Turn-In type.
- The shared `UI.GetTurnInCategoryOptions()` now provides type-specific options. On a type change, the shared filter setter retains a selected category only if it remains valid in the new type. The dropdown's visible label follows the selected type.
- The row filter still compares crate `category` values and Writ `professions` values; no inferred category mapping is introduced.

### Turn-In labels and reward presentation

- The existing economics values and calculations are unchanged. `Cost` is the total completion cost (purchase of one crate/Writ plus one fully priceable completion route); `Gross` is the cash return for crates or variable Coin Pouch label for Writs; `Rep / Favor` is the reward quantity; `Net / Reward` is the existing net-per-Favor or gross-cost-per-Reputation metric.
- Compact Favor text changes from `F` to `Fav`; Reputation remains `Rep`.
- The visible Writ asterisk and "Reported Rep" label are removed as requested. Underlying Writ data provenance remains community-derived and is still recorded as such in this documentation and in the data/audit metadata. This presentation change does not promote the reward schedule to FOREVER OBSERVED or FOREVER VERIFIED.
- Variable Coin Pouch returns remain unpriced and are not deducted from Cost / Rep. Existing 75 / 125 / 200 reputation values are unchanged.

### Shift-click Auction House search

- The supplied AddOns.zip includes Auctionator source. `Auctionator/Source/Shopping/Hooks.lua` hooks the link-insertion path (`ChatFrameUtil.InsertLink` or `ChatEdit_InsertLink`) and can initiate a Shopping search when its own Shopping frame is visible. The installed source also includes a public `Auctionator.API.v1` surface in some client variants, but that path is not required for the requested native Browse field behavior.
- Blizzard Auction UI source references the `BrowseName` edit box as the query field for `AuctionFrameBrowse_Search`.
- To avoid breaking chat item-link insertion or depending on optional Auctionator, 0.11.5 does not replace or hook either link-insertion function. On a Shift+LeftClick over an MM item row it checks that the native `AuctionFrame` is open, switches to the native Browse tab if the Browse field is hidden, fills `BrowseName` with the visible item name, focuses/highlights the text and leaves submission to the player.
- If the native Auction House or `BrowseName` is unavailable, the action fails closed. This implementation targets the Forever 1.60.1 legacy Auction House UI; a separate modern Auction House search API integration is not claimed.

### Tab geometry and Modern chrome

- The prior Blizz-like tabs were fixed at 194×30 and the Modern rail at 1472×48 with 46-pixel buttons. The tab widths were not data-dependent; this slice reduces their fixed footprint and centers the Blizz-like group rather than letting widths expand based on labels.
- The Modern title no longer uses the M logo. The toolbar Close action is removed; the top-right X remains the normal window chrome. Scan confirmation/cancel controls remain unchanged.

## Ownership, dependencies and compatibility

- Owner: standalone Modulo Market addon.
- No parent MODULO source changed.
- No optional addon dependency was added. The Shift-click action uses only the native Classic Auction House field.
- No SavedVariables schema changes.
- Scan confirmation, cancellation, cooldown, one-request-per-session gate, Sell-tab safety, market snapshot format, market pricing, Writ/crate calculations, recipe capture and optional addon ownership remain unchanged.

## Risks and gaps

- Shift-click is limited to the native legacy Auction House Browse field. It does not invoke Auctionator or TSM search tabs and does not automatically submit the query.
- If AuctionFrame is not open, the Shift-click does not launch it.
- A missing/unavailable client time source now results in no history points rather than showing an unbounded history.
- The Writ reputation schedule remains community-derived even though the UI no longer displays a qualification marker, at the user's request.
- Tab sizing is source-verified only; UI scale and actual target-client layout still need runtime acceptance.

## Tests and runtime evidence

See the standalone `MODULOMARKET-RUNTIME-AUDIT-0.11.5.md` for exact commands, test results, archive integrity and SHA-256.

Offline validation for this slice: 10 focused tests passed; the Writ harness passed 11 Writ-specific checks plus the explicit crate-type assertion; the legacy crate harness passed; all 14 Lua files passed `texluac -p`; all six utility TGA assets are valid 64×64 RGBA files. The full historical suite completed with 345 passed / 87 failed / 432 total. The 87 failing test IDs are exactly the same as the 0.11.4 baseline (335 passed / 87 failed / 422 total); zero new failing IDs were introduced.

- Static/offline tests verify the 72-hour cutoff, crate row type, dynamic dropdown options, label values, fixed tab geometry, TGA format and Shift-click routing.
- Lua harness verifies crate and Writ row types and existing Writ completion economics.
- Forever runtime: NOT RUN for 0.11.5.
- Retail runtime: NOT RUN.
- GitHub push: NOT RUN; local bundle only.

## Acceptance / exit criteria

1. History never displays snapshots older than the rolling last 72 hours; four snapshots inside that period remain allowed.
2. Both tab rails remain at fixed compact dimensions across all tabs.
3. Waylaid Crates are visible when Turn-In Type is set to Waylaid Crates; Writs remain visible when Craftsman's Writs is selected.
4. The category selector shows only the relevant categories/professions for the chosen type, resets invalid selections and updates its label.
5. Both views display the five agreed Turn-In column labels and `Fav` / `Rep` abbreviations without visible asterisks.
6. The Writ inspector uses `Reputation`, not `Reported Rep`.
7. Modern title is centred without the M logo; redundant toolbar Close is absent; title-bar X remains.
8. Shift-clicking an item row while the native Auction House is open fills the Browse search field without submitting it or changing chat-link behavior.
9. The new refresh icon is visible on both presentations.
10. Existing scan, market, pricing, recipe, and Turn-In economics behavior remains unchanged.
11. Player-visible acceptance is confirmed on Forever before closing the runtime scope. Until then, Forever runtime remains NOT RUN.
