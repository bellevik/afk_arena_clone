# Phase 15

## What Was Built

- added authored ultimate metadata to every enemy definition
- added six enemy-specific skills to the shared skill catalog
- wired enemy ultimates through the existing battle payload builder
- enabled enemy casts in normal battle flow with no separate combat path

## How To Run

1. Open the project in Godot 4.3 or newer.
2. Run the default main scene.
3. Open `Battle` or a later `Campaign` stage and let the fight run long enough for enemy energy to fill.

Optional smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_15_smoke.gd
```

## How To Test

1. Open `Battle` or a later Chapter 2 campaign stage.
2. Let the fight run long enough for enemies to reach full energy.
3. Confirm the combat log and cast banner now show enemy ultimates.
4. Verify the battle still ends cleanly and no unit softlocks after casting.

## Acceptance Checklist

- all enemy definitions load with authored ultimate metadata
- enemy ultimates resolve through the shared skill catalog
- enemies cast ultimates during battle
- battle UI reflects enemy casts cleanly
- prior battle features still work

## Regression Check

- hero ultimates still cast correctly
- battle rewards and campaign progression still report correctly
- quests that depend on battle wins still advance correctly
- summon and quest systems remain unaffected

## Known Limitations

- enemy skills currently reuse the existing hero effect vocabulary rather than introducing enemy-only mechanics
- enemy skill balance is representative and will need tuning against real ascension and gear progression
- there is still no enemy-side formation AI beyond current target selection rules

## Next Goals

- add a dedicated settings screen
- evolve star rank into real ascension and merge rules
- consider enemy-only mechanics once the baseline roster progression is deeper
