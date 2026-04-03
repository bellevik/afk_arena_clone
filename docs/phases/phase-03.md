# Phase 3: Team Formation System

## What Was Built

- `FormationState` autoload for the active five-slot team
- dedicated `Formation` route and screen
- fixed slot model:
  - front-left
  - front-right
  - back-left
  - back-center
  - back-right
- assign/remove flow from the owned roster
- duplicate-prevention rules
- quick clear button
- auto-fill button
- team power calculation from current level-scaled hero stats
- session persistence for the active formation while the app remains open

## How To Run

Open the repository root in Godot 4.3+ and run the project, or start it from the terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

## How To Test

1. Launch the project and open `Formation`.
2. Select each slot and assign heroes from the picker.
3. Fill all five slots and confirm the summary reads `Full`.
4. Remove a hero from one slot and confirm the summary returns to `Partial`.
5. Try assigning the same hero twice and confirm the second placement is rejected.
6. Use `Clear Formation` and confirm all slots empty.
7. Use `Auto-Fill` and confirm all slots populate.
8. Optionally run the headless smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_03_smoke.gd
```

## Acceptance Checklist

- [x] Player can assign heroes to slots
- [x] Same hero cannot occupy multiple slots
- [x] Formation persists during the current session
- [x] Team power updates when formation changes
- [x] Clear and auto-fill flows are available

## Regression Check

- Boot still reaches the app shell
- Main menu still routes to all top-level screens
- Heroes route still exists for roster inspection
- Debug overlay still opens and routes directly to screens
- Placeholder routes for campaign, battle, rewards, and settings still work

## Known Limitations

- Formation state is session-only until save/load exists
- Role or slot synergy rules do not exist yet
- Formation is not consumed by battle logic until Phase 4
- The Heroes screen had recent UI regressions reported during manual testing and should be revisited separately

## Next Phase Goals

Phase 4 should turn the active formation into a real encounter:

- battle scene
- allied and enemy unit spawning by slot
- deterministic combat loop
- target selection
- HP bars
- KO handling
- win/loss result flow
