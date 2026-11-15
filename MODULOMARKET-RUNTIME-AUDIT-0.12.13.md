# Modulo Market 0.12.13 — Diagnostic settings label correction

**Date:** 2026-11-15  
**Parent:** 0.12.12 minimap/settings slice  
**Scope:** Correct the settings row label and button text only; version metadata, manifest, focused test and README.

## Player feedback

The 0.12.12 change altered the button text rather than the truncated row label. The player explicitly wanted the row label shortened, while retaining descriptive button text.

## Change

- Settings row label: **Diagnostic window**.
- Button text: **Open Browse Scan / Snapshot**.
- The button callback remains the existing `MM.Scanner.Toggle()` action.
- No minimap, settings navigation, scan or market behavior changed.

## Verification

- Focused Python assertions: run below.
- Lua syntax: no Lua logic changed; not rerun for this label-only change.
- Forever runtime: NOT RUN; player-visible acceptance is straightforward visual confirmation.

## Acceptance

The Settings row should display **Diagnostic window** without truncation, and the adjacent button should read **Open Browse Scan / Snapshot** and continue opening the existing diagnostic window.
