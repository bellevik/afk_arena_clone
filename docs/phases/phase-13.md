# Phase 13

## What Was Built

- added a playable summon route
- added authored summon banner data with featured heroes, pity, and costs
- added a `SummonState` autoload for banner selection, pull history, and pity tracking
- connected duplicate pulls to hero `star_rank`
- made star rank apply a stat bonus that feeds roster, formation, and battle power
- persisted summon state through the unified save file

## How To Run

1. Open the project in Godot 4.3 or newer.
2. Run the default main scene.
3. Open `Home`, then use `Open Summon`.

Optional smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_13_smoke.gd
```

## How To Test

1. Use `DEV -> +5000 Resources` if needed.
2. Open `Summon`.
3. Pull once and confirm gold drops and results appear.
4. Pull ten times and confirm total pulls and pity update.
5. Open `Heroes` and verify at least one summoned hero shows increased stars and summon bonus.
6. Save and reload, then confirm the summon screen still shows the same pity and latest results.

## Acceptance Checklist

- summon screen loads inside the shell
- banners are data-driven
- pulling spends gold and records results
- duplicate pulls increase star rank
- summon state persists through save/load
- older loop features still work

## Regression Check

- hero roster still loads and upgrades correctly
- formation still calculates power from current hero stats
- battle still resolves with upgraded star-rank stats
- campaign and rewards continue to function
- unified save/load still restores all previously implemented systems

## Known Limitations

- summoning uses gold rather than a dedicated premium currency
- pulls always resolve into duplicate copies because the prototype still exposes the full roster by default
- star rank currently boosts stats directly but does not yet feed a true ascension or merge pipeline

## Next Goals

- add quests that react to pulls, upgrades, and campaign clears
- add enemy-authored ultimates for stronger late-stage identity
- evolve star-rank gains into a fuller ascension system
