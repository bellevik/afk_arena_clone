# Phase 18

## What Was Built

- expanded the quest board with daily and weekly authored objectives
- extended `QuestState` to track recurring cycle state separately from permanent milestone state
- added automatic reset buckets for recurring quests
- grouped the quest board by cadence and surfaced reset timers in the UI
- persisted active recurring quest progress in the unified save flow

## How To Run

1. Open the project in Godot 4.3 or newer.
2. Run the default main scene.
3. Open `Quests` and progress gameplay actions such as battle wins, AFK claims, summons, stage clears, and hero leveling.

Optional smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_18_smoke.gd
```

## How To Test

1. Open `Quests` and confirm milestone, daily, and weekly sections all appear.
2. Confirm daily and weekly sections show reset timers.
3. Progress the appropriate gameplay actions and confirm recurring quests advance.
4. Claim a completed daily or weekly quest and confirm rewards apply immediately.
5. Save and reload through `Settings` and confirm recurring quest progress persists for the active cycle.

## Acceptance Checklist

- milestone quests still work
- daily quests reset through active cycle state
- weekly quests reset through active cycle state
- the quest board surfaces cadence grouping and reset timing
- unified save/load restores recurring quest progress correctly

## Regression Check

- campaign, battle, summon, AFK, and hero-level events still advance quests
- claiming quests still grants rewards through `RewardState`
- the quest route still loads inside the app shell
- save/reload still works across the broader prototype

## Known Limitations

- recurring cadence currently uses simple epoch-based cycle buckets rather than player-local midnight or region-specific reset time
- there is still no seasonal or event-specific quest layer
- recurring quest rewards still use only gold and hero XP

## Next Goals

- add a dedicated premium summon economy
- introduce event-based limited-time content
- expand quest cadence with rotating or seasonal objective sets
