# Phase 4: Battle Simulation Core

## What Was Built

- deterministic Phase 4 battle simulator with no RNG
- battle test encounter data in `project/data/balance/`
- live `Battle` route and screen
- allied team build from the active formation
- enemy team build from authored encounter data
- front/back slot placement in the arena view
- real-time auto-attacks driven by speed-based cadence
- simple target selection with frontline priority
- damage resolution, HP tracking, and KO handling
- timer-based battle end condition
- in-screen result panel for victory, defeat, or timeout
- combat log output
- battle restart button
- battle speed toggle
- debug-friendly auto-fill fallback if the player opens Battle without assigning a team

## How To Run

Open the repository root in Godot 4.3+ and run the project, or start it from the terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

## How To Test

1. Launch the project and open `Formation`.
2. Assign at least one hero, or use `Auto-Fill`.
3. Open `Battle`.
4. Confirm allied and enemy units appear in their front/back positions.
5. Wait for the battle to auto-resolve.
6. Confirm HP bars move, KO units gray out, and the result panel appears.
7. Press `Restart Battle` and confirm the encounter resets cleanly.
8. Press `Speed` and confirm the battle runs faster while preserving the same outcome.
9. Open `Battle` with an empty formation and confirm the screen auto-fills a team for testing.
10. Optionally run the headless smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_04_smoke.gd
```

## Acceptance Checklist

- [x] A full battle can be started and finished
- [x] Units attack automatically
- [x] Damage and KO resolution work
- [x] Win/loss or timeout result appears
- [x] Battle can be restarted from the same screen
- [x] Deterministic outcomes are reproducible for identical inputs

## Regression Check

- Boot still reaches the app shell
- Main menu still routes to all top-level screens
- Heroes route still loads authored roster data
- Formation route still allows assignment, clear, and auto-fill
- Debug overlay still opens and routes directly to screens

## Known Limitations

- There are no hero ultimates, energy systems, or role-specific skills yet
- There are no attack VFX, damage popups, or animation timelines yet
- The battle encounter list is a single authored test fight, not campaign stage data
- Timeout currently counts as an enemy hold/defeat for the player
- Formation, battle state, and results are not persisted yet

## Next Phase Goals

Phase 5 should build hero identity on top of the current combat core:

- energy gain
- hero ultimates
- skill targeting
- support effects such as healing, shielding, and buffs
- richer combat log detail tied to skill activation
