# Modulo Market 0.12.6 Runtime Audit — Active Replicate Cancellation

## Status

**SOURCE IMPLEMENTED; OFFLINE TESTS PASS; FOREVER RUNTIME ACCEPTANCE NOT RUN.** This is a narrow defect-fix slice on the 0.12.5 reconciled candidate. It is not a 1.0.0 approval and does not resolve the separate data/asset redistribution gates recorded in the 0.12.5 provenance audit.

## Player problem and observable result

After the player confirmed a Full Market Replicate scan, the Cancel button disappeared. The player had no direct control to stop the active operation. Closing the Auction House was not a reliable cancellation mechanism on the observed Forever client; prior closed-window scan behavior showed acquisition can continue.

Required result: after Confirm, Cancel remains visible beside the scan control in both Blizz-like and Modern presentations. Activating it stops the active transaction, discards in-memory partial work, unregisters Replicate event/update handlers, leaves the last-known-good Full Market SavedVariables snapshot unchanged, and does not invoke the successful commit/refresh path.

## Exact source finding

- `MarketUI.RefreshActions()` previously showed `UI.cancelButton` only while `state.pendingConfirmation` was true.
- `Replicate.Confirm()` sets `pendingConfirmation = false` and `active = true`, so the next UI refresh hid the button.
- The button callback and `UI.TriggerCancelScan()` called `Replicate.CancelPrepare()`, which only clears the pre-request confirmation state; it did not stop an active transaction.
- `Modern.RefreshScanActions()` also hid its Cancel button unless confirmation was pending.

## Competing hypotheses for the Auction House close observation

1. The Forever client does not emit `AUCTION_HOUSE_CLOSED` for the UI-close action observed, or emits it on a different lifecycle path. A bounded runtime event trace would distinguish this by recording the event and active/stage state.
2. The event is emitted but the Replicate frame is no longer registered/receiving it at that point. A registration/event trace on the same action would distinguish this.

The new player-facing Cancel path does not depend on either hypothesis: it calls the active transaction's own abort routine directly. The client-side event discrepancy remains unproven and is not silently declared fixed.

## Changes in 0.12.6

- Added `Replicate.Cancel()` for both pending confirmation and active scan states.
- Active cancellation calls the existing `Abort("cancelled by player")` path. This clears the active scan, resets the stage, removes the OnUpdate script and unregisters Replicate response/item-data/Auction House close events.
- Cancellation never calls `Finish()`, `SaveHistoryPoint()`, `MM.db.lastMarketSnapshot = snapshot`, or `OnMarketSnapshotCommitted()`.
- The one-shot Replicate attempt and 15-minute cooldown remain consumed after a confirmed request. No automatic retry is introduced.
- Blizz-like and Modern Cancel controls remain visible while confirmation is pending **or** the scan is active.
- Both presentation controls and the programmatic `UI.TriggerCancelScan()` route to `Replicate.Cancel()`.
- Addon/TOC/manifest version advanced together to 0.12.6. Existing 0.12.5 source and acceptance evidence is retained.

## Acceptance evidence

- Replicate state-machine harness: PASS; covers cancellation before initial response and after the initial response has transitioned into record processing. Verifies inactive/idle state, event cleanup, unchanged saved snapshot, consumed one-shot allowance and cancellation status.
- UI contract test: PASS; verifies active-state visibility and routing for both presentations.
- Modern UI harness: PASS; verifies Cancel stays visible during active processing and hides again after the scan is no longer active.
- Full active pytest suite: **139 passed**.
- Lua syntax: **14/14 addon Lua files passed** `texluac -p`.
- ZIP integrity, manifest inventory and fresh extraction: pending final packaging check below.

## Offline package verification

The complete 0.12.6 source bundle is built from a fresh extraction of the reconciled 0.12.5 candidate. The bundle contains the full addon source, canonical datasets, licensing/provenance records, historical runtime audits, active and historical tests, and importer tooling. Archive CRC, exact manifest inventory, fresh-extraction active tests, Lua syntax and SHA-256 are recorded in the delivery handoff.

## Forever runtime acceptance — NOT RUN

Install 0.12.6 on Forever 1.60.1 and perform a fresh full Replicate scan after cooldown:

1. Open Modulo Market and Auction House; prepare and confirm a Full Market scan.
2. Once `Scan: Active` is visible, verify the Cancel button remains visible beside the disabled scanning control.
3. Activate Cancel while the scan is active.
4. Verify status says the scan was cancelled by the player and previous saved data is unchanged.
5. Verify Full Market timestamp, auction count and visible rows remain unchanged; inspector remains usable.
6. Verify no `Market snapshot saved` success message, no new history point, no automatic retry, and no Lua error.
7. Repeat in the other presentation (Modern and Blizz-like) after cooldown permits.

A source/harness pass is not Forever runtime acceptance. Keep this slice OPEN until player-visible acceptance passes on Forever. Retail runtime NOT RUN.

## Scope and ownership

Modulo Market owns its Replicate transaction and both presentation controls. No MODULO core source, optional addon dependency, SavedVariables schema, auction API policy, acquisition behavior, or pricing calculation changed.

## Risks and limitations

- Cancel is only available while the scan is pending confirmation or active. Once the transaction commits, cancellation is too late and the saved snapshot is already replaced.
- The client exposes the one-shot `C_AuctionHouse.ReplicateItems()` request without a demonstrated request-revocation API in this implementation. After confirmation, Cancel stops Modulo Market's local event handling, auction-record processing and commit path; it cannot claim to retract a request already sent to the client/server. The shared cooldown and one-shot allowance remain consumed.
- Confirmed cancellation consumes the one-shot attempt and cooldown; the player must wait before another Replicate request.
- Closing the Auction House was not accepted as a reliable cancellation method; the direct Cancel control is the supported player action introduced here.
- Existing 0.12.5 Forever observations for closed-window and open-window successful refresh remain preserved and are not reclassified.
