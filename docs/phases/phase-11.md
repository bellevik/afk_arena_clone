# Phase 11: UX Polish Pass for Vertical Mobile Play

## What Was Built

- shared button press feedback through `ThemeManager`
- app-shell route fade transitions
- less cramped main menu layout with a single-column route stack
- battle unit card readability pass with clearer bars and calmer text sizing
- small shell backdrop polish to make the portrait frame feel less flat

## How To Run

Open the repository root in Godot 4.3+ and run the project, or start it from the terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

## How To Test

1. Launch the project and move across the main routes.
2. Confirm buttons visibly depress and recover on press.
3. Confirm route changes use a short transition instead of hard cuts.
4. Confirm the main menu route buttons are easier to tap in portrait.
5. Open `Battle` and confirm unit cards are easier to scan during combat.
6. Optionally run the headless smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_11_smoke.gd
```

## Acceptance Checklist

- [x] Core routes are comfortable to use in a portrait viewport
- [x] Buttons provide clearer visual feedback
- [x] Screen transitions reduce abrupt route changes
- [x] Battle readability is improved without breaking combat flow

## Regression Check

- Unified save/load still works
- Hero leveling and equipment still work
- Campaign progression still works
- Rewards and AFK collection still work
- Deterministic battle and ultimates still work

## Known Limitations

- The visual language is still placeholder-grade rather than final art direction
- Some screens still carry dense informational copy that could be further simplified later
- Settings remains a placeholder route
- There is still no dedicated fullscreen battle results or mobile-native gesture layer

## Next Phase Goals

Phase 12 should finish the prototype expansion pass:

- modest content growth
- future system hooks
- extension-point documentation
