# Modulo Market 0.11.3 — scan flow and Modern control refinement

## Player problem and observable result

The player reported that Modern exposed only an Update Full Market action while Blizz-like exposed a separate scan/confirm/cancel sequence; Browse Scan did not provide useful value in the main windows; Modern's profession dropdown could show `0`; the history text and graph overlapped; checkboxes lacked a clear checked mark; the search field and utility icons did not match the Modern visual language.

0.11.3 provides:

- Both presentations use one primary full-scan button: **Scan Market** → **Confirm Scan** → **Scanning…**, then cooldown/session-used state.
- A separate **Cancel** action is shown only while confirmation is pending. Cancelling sends no request and returns the primary button to the current available/cooldown state.
- The existing `Replicate` state machine remains the sole scan engine. Cooldown, one-request-per-session, Auction House open, Sell-tab safety, shared cooldown warning, timeout and fail-closed snapshot preservation are unchanged.
- Browse Scan / snapshot diagnostics are no longer a visible action in either main window. The launcher is on the Modulo Market addon settings page; `/mmscan` remains as a compatibility command.
- Modern uses custom TGA assets for refresh, search, dropdown, close, check and cancel affordances.
- Modern search uses a custom dark field, border, icon and placeholder rather than `InputBoxTemplate`.
- Profession dropdown display falls back to its first option (All professions) if options are not yet populated or the stored value has no label match.
- Inspector history includes only observations within the last three days, retaining up to four most recent observations. Modern graph bars and percentage labels are confined to a fixed lower chart region, below the history text.

## Evidence and root-cause findings

- `Replicate.lua` already implemented `Prepare`, `Confirm`, `CancelPrepare` and `GetState`. The UI defect was that the primary button did not advance to confirmation and Modern did not expose the same state transitions.
- `MarketUI.RefreshActions` already read the shared state every second. It now controls both presentations, and Modern also refreshes its visible state while open.
- The profession getter may return `0` before the dynamic profession list has been populated; the previous dropdown renderer displayed the raw value when it could not find a matching option label.
- `UI.RenderHistory` previously selected the last four saved snapshots without checking their age. Modern scaled legacy bar heights into a short card, allowing bars/labels to intrude into text.
- Modern used Blizzard's generic input template and several stock/legacy texture glyphs for controls. The new TGA assets are owned by this addon and add no dependency.

## Scope and ownership

- Owner: standalone ModuloMarket addon.
- Changed runtime files: `Core.lua`, `MarketUI.lua`, `ModernUI.lua`, `Theme.lua`, `TurnInData.lua` and TOC version metadata.
- Added six TGA assets under `AddOns/ModuloMarket/Textures/`.
- Added focused Python and Lua scan-state tests; updated current Modern harness expectations.
- No parent MODULO source changed. No new addon dependency.
- No change to Replicate request semantics, scanner pagination, auction aggregation, pricing, recipe/profession data, Turn-In calculations, market-history storage schema or SavedVariables schema.

## Competing risks and diagnostics

1. **Scan state/UI synchronization:** callbacks or one-second refresh could leave the Modern label stale. Offline diagnostic: exercise Prepare → Cancel, cooldown rejection, Prepare → Confirm, and repeat-attempt rejection; compare both UI refresh paths. Runtime diagnostic: click each state in both presentations and verify the label/cancel control updates immediately.
2. **Shared cooldown interference:** another addon may consume the account-wide cooldown without exposing its timestamp. The existing local timer is explicitly only a local estimate; the warning remains and the final confirmation rechecks local cooldown and safety gates.
3. **TGA loading:** a target client may reject or fail to load a texture path. Offline diagnostic validates six 64×64 RGBA TGA files and exact manifest inclusion. Runtime diagnostic checks each icon in Forever after fresh install/reload.
4. **History timestamps:** absent or invalid local wall-clock time cannot support a three-day cutoff. Source uses the client wall clock when available; unknown clock keeps the existing latest-four fallback rather than silently dropping all history.

## Verification

- Dedicated Replicate state-machine harness: 8 checks passed.
- Modern UI harness: 29 checks passed.
- TGA asset validation: six 64×64 RGBA files.
- Lua syntax: all addon Lua files compiled with `texluac -p`.
- Full regression suite and same-environment 0.11.2 baseline comparison are recorded in the release audit.
- Archive CRC, exact manifest inventory, version agreement and fresh extraction are recorded in the release handoff.

## Runtime evidence and acceptance

- Forever client build 1.60.1.70938: the player's screenshots establish the 0.11.2 behavior and defects; **0.11.3 fix acceptance NOT RUN**.
- Retail runtime: **NOT RUN**.
- Actual TGA rendering, scan interaction with live Auction House, settings launcher, history clipping and Modern text/input focus require client acceptance.
- No `FOREVER VERIFIED` claim is made.
- GitHub remote write/push: **NOT RUN**; complete local bundle only.

## Acceptance checklist

1. In Blizz-like and Modern, first click changes Scan Market to Confirm Scan and displays Cancel; no request is sent on the first click.
2. Second click confirms and sends exactly one Replicate request; button becomes Scanning and cannot be clicked again.
3. Cancel before confirmation sends no request and restores Scan Market or cooldown countdown.
4. Cooldown, attempted-this-session, AH-open and Sell-tab safety gates remain effective.
5. Neither main window displays Browse Scan; settings page opens the existing Browse Scan/snapshot debug window, and `/mmscan` still works.
6. Profession dropdown shows All professions rather than `0` before and after profession data populates.
7. History text and graph do not overlap; only observations within the last three days are displayed; graph bars/labels remain inside their chart area.
8. Modern search, checkboxes and custom TGA utility icons render and interact correctly in all three Modern palettes.
9. Both presentations retain all six tabs and shared market state; no Lua or protected-action errors.
