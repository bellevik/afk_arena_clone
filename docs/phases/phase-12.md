# Phase 12

## What Was Built

- expanded the authored roster from 8 to 12 heroes
- expanded the enemy catalog from 3 to 6 enemy archetypes
- expanded the campaign from 10 to 20 stages across two chapters
- added a second battle test encounter for higher-power combat checks
- added a structured future-feature registry for:
  - summoning
  - guilds
  - events
  - PvP
  - quests
- surfaced content counts and future hooks on the home screen

## How To Run

1. Open the project in Godot 4.3 or newer.
2. Run the default main scene.
3. Use the bottom navigation to move between `Home`, `Heroes`, `Formation`, `Campaign`, `Battle`, and `Rewards`.

Optional smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_12_smoke.gd
```

## How To Test

1. Open `Home` and confirm the expansion panel reports 12 heroes, 6 enemies, 20 stages, 12 skills, and 5 future hooks.
2. Open `Campaign` and verify the list extends into Chapter 2.
3. Use `DEV -> Unlock All Stages`, then inspect several Chapter 2 enemy lineups.
4. Open `Battle`, restart the test encounter, and confirm the game still runs normally after the content expansion.
5. Save, reload, and confirm progression and inventory still restore correctly.

## Acceptance Checklist

- game still launches cleanly
- authored content loads without scene or parse errors
- Chapter 2 stages appear in campaign order
- the home screen surfaces future-system hooks
- prior loop features still function after the content expansion

## Regression Check

- hero roster still supports selection, leveling, and equipment
- formation still blocks duplicates and updates team power
- battle still resolves deterministically with energy and ultimates
- campaign still unlocks stages on victory
- rewards still grant battle and AFK income
- save/load still restores the unified runtime state

## Known Limitations

- the future-feature registry is documentation and UI surfacing only; those systems are not implemented yet
- enemy units still rely on basic attacks only
- Chapter 2 balancing is representative, not final tuned content
- settings remains a placeholder route

## Next Goals

- build the next real system on top of the registry, most likely summoning or quests
- give enemies authored skills so late-stage compositions feel more distinct
- expand ascension beyond the current level-cap foundation
