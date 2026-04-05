# Phase 10: Save/Load, Persistence Hardening, and Debug Tools

## What Was Built

- a unified versioned save service in `project/scripts/save/save_state.gd`
- one active save file for:
  - owned heroes and hero levels
  - formation
  - campaign progress
  - currencies and AFK timestamps
  - equipped gear and inventory counts
- corrupt-save recovery that resets back to authored defaults
- debug overlay actions for:
  - save
  - reload
  - reset save
  - grant resources
  - unlock all stages
  - cap all heroes

## How To Run

Open the repository root in Godot 4.3+ and run the project, or start it from the terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

## How To Test

1. Launch the project and make some progress:
   - level up a hero
   - equip gear
   - assign a formation
   - clear a campaign stage
2. Open `DEV`.
3. Press `Save`, then `Reload Save`.
4. Confirm all progression state remains intact.
5. Use `+5000 Resources`, `Unlock All Stages`, and `Cap All Heroes` to confirm the debug actions update runtime state.
6. Press `Reset Save`.
7. Confirm the game returns to authored defaults.
8. Optionally run the headless smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_10_smoke.gd
```

## Acceptance Checklist

- [x] Closing and reopening the game preserves progress through the unified save
- [x] Save reset works
- [x] Debug tools work
- [x] Corrupt or invalid save data falls back safely to defaults

## Regression Check

- Hero leveling still works
- Equipment still affects formation and battle
- Rewards and AFK claim flow still work
- Campaign stage unlock progression still works
- Deterministic battle and hero ultimates still work

## Known Limitations

- Some older single-system save artifacts may remain on disk until a cleanup phase removes them
- Save versioning is present, but migration logic is still minimal because only one unified version exists so far
- Debug save controls currently live only in the developer overlay
- Settings remains a placeholder route

## Next Phase Goals

Phase 11 should focus on mobile-first usability:

- better panel hierarchy
- clearer tap targets
- smoother transitions
- improved battle readability
