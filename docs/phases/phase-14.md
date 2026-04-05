# Phase 14

## What Was Built

- added a dedicated quest board route
- added authored milestone quest definitions
- added `QuestState` for quest progress, claims, and save persistence
- added progression event signals from campaign, rewards, hero leveling, and summoning
- connected quest claiming back into the shared gold and hero XP economy

## How To Run

1. Open the project in Godot 4.3 or newer.
2. Run the default main scene.
3. Open `Home`, then use `Open Quests`.

Optional smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_14_smoke.gd
```

## How To Test

1. Open `Quests`.
2. Complete one or more actions from the current loop:
   - clear a stage
   - win a battle
   - level a hero
   - summon
   - claim AFK rewards
3. Return to `Quests` and confirm progress advanced.
4. Claim a completed quest and verify gold and hero XP increase.
5. Save, reload, and confirm quest progress and claims persist.

## Acceptance Checklist

- quest board loads inside the app shell
- quests are data-driven
- progress updates from real gameplay events
- quest rewards can be claimed exactly once
- quest state persists through unified save/load
- older loop systems still work

## Regression Check

- battles still grant battle rewards
- campaign still unlocks stages correctly
- summons still increase total pulls and star rank
- hero leveling still works and emits no duplicate side effects
- rewards and AFK claims still function normally

## Known Limitations

- quests are milestone-only, not daily or weekly
- there is no quest-specific notification badge yet
- quest rewards currently grant only gold and hero XP

## Next Goals

- add enemy-authored skills for stronger late-stage identity
- build a dedicated settings route
- evolve milestone quests into daily or rotating event structures later
