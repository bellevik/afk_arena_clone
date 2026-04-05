# Phase 5: Skills, Energy, and Hero Identity

## What Was Built

- authored ultimate skill definitions in `project/data/balance/ultimate_skills.json`
- skill loading in `GameData`
- battle units now carry ultimate metadata and skill definitions
- energy gain from time, attacking, and taking damage
- ultimate casting when energy reaches full
- shield, heal, speed buff, and defense-break support in the simulator
- at least 8 distinct authored hero ultimates wired into battle
- combat log entries for skill usage
- battle UI energy bars on unit cards
- battle cast banner as a placeholder VFX/readability layer

## How To Run

Open the repository root in Godot 4.3+ and run the project, or start it from the terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

## How To Test

1. Launch the project and open `Formation`.
2. Build a mixed team with at least one support, one mage, and one frontline hero.
3. Open `Battle`.
4. Confirm each unit card now shows an energy bar.
5. Let the battle run and verify:
   - energy bars fill over time
   - heroes eventually cast ultimates
   - the cast banner appears when a skill fires
   - combat log contains lines with `used`
   - shield, heal, or buff effects change the battle state
6. Try a different team comp and confirm the battle flow and outcome change.
7. Optionally run the headless smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_05_smoke.gd
```

## Acceptance Checklist

- [x] Heroes accumulate energy
- [x] Ultimates fire automatically at full energy
- [x] Multiple distinct ultimate effects are implemented
- [x] Combat log mentions skill usage
- [x] Skill effects change battle outcomes and unit state

## Regression Check

- Boot still reaches the app shell
- Heroes and Formation screens still load
- Battle route still resolves full encounters without softlocks
- Phase 4 deterministic battle foundation still works with the added skill layer

## Known Limitations

- Enemy units still have no authored ultimates yet
- Placeholder VFX are limited to status text, energy bars, and a cast banner
- There are no animation timelines, sound cues, or damage popups yet
- Balance is intentionally rough while campaign and rewards are still missing

## Next Phase Goals

Phase 6 should connect the battle system to progression:

- campaign stage definitions
- stage selection UI
- battle launch from stage data
- progression unlock flow
- stage completion tracking
