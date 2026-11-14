# Modulo Market 0.10.3 — Inspector font stability and Turn-In selection feedback

## Player-visible problems

- The selected-item inspector's metric values grew larger after repeated tab changes and selections instead of retaining a stable size.
- On the Turn-Ins tab, selecting a Waylaid Crate updated the inspector before the selected-row highlight became visible.

## Implemented behavior

- Inspector metric values on Turn-Ins use the exact font face and size derived from `GameFontHighlight + 1`, matching the middle table's `RowText` values.
- Inspector metric values on other tabs use a fixed `GameFontHighlightLarge + 1` size, preserving their intended larger treatment.
- Font size is assigned from the template's font path, size and flags. It is not incremented from the FontString's current size during tab switches or item reselection.
- The Turn-In selection path calls `UI.RenderRows()` after updating the inspector and before its early return. The virtual row pool therefore receives the new selection state immediately.
- Reward presentation remains mutually exclusive (Favor, else Reputation, else unknown); known zero remains explicit.

## Root cause

The previous implementation called `IncreaseFontSize(value, 1)` from both `SetTab` and the non-Turn-In `SelectItem` path. Those operations were repeated during normal navigation and changed the current FontString size rather than assigning a stable size from a known template. The Turn-In selection path used a different font reset, so switching between tabs and selections could leave inconsistent sizes.

The Turn-In `SelectItem` branch also returned before the final `UI.RenderRows()` call used by the normal item-selection path. This left the virtualized row highlight waiting for a later row render.

## Scope and ownership

- Owner: ModuloMarket.
- No parent MODULO source, addon dependency, SavedVariables schema, market data, price arithmetic, scanner, filter semantics, sorting, or crate dataset changes.
- No new dependencies.

## Acceptance criteria

1. Inspector metric values on Turn-Ins are the same font size as the middle table's row values.
2. Repeatedly switching tabs and selecting items does not change the metric font size.
3. Non-Turn-In inspector metrics retain their established larger size without cumulative growth.
4. Selecting a Turn-In immediately updates the selected-row wash/accent without waiting for a later build or refresh.
5. Existing exclusive Favor/Rep display, known-zero/unknown distinction, pricing, alternatives, and fail-closed price depth remain unchanged.

Forever in-client visual acceptance is required before closing these defects.
