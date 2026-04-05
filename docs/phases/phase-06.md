# Phase 6: Campaign Map and Stage Progression

## What Was Built

- `CampaignState` autoload for unlocked stages, cleared stages, stage selection, and pending campaign battle context
- authored campaign stage definitions in `project/data/stages/campaign_stages.json`
- real `Campaign` route and screen
- stage list with locked, unlocked, and cleared states
- selected-stage detail panel with recommended power and enemy lineup
- battle launch from campaign stage data
- stage result reporting back into campaign progression
- next-stage unlock on victory
- session tracking for current campaign progress

## How To Run

Open the repository root in Godot 4.3+ and run the project, or start it from the terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

## How To Test

1. Launch the project and open `Campaign`.
2. Confirm stage `1-1 Dawn Patrol` is unlocked.
3. Confirm later stages start locked.
4. Select `1-1 Dawn Patrol` and press `Launch`.
5. Let the battle resolve.
6. On victory, return to `Campaign` and confirm `1-2 Ash Route` is now unlocked.
7. Launch a locked stage and confirm it cannot be selected until unlocked.
8. Replay a cleared stage and confirm it stays marked cleared.
9. Optionally run the headless smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_06_smoke.gd
```

## Acceptance Checklist

- [x] Player can select available stages
- [x] Winning unlocks the next stage
- [x] Losing does not unlock progression
- [x] Campaign state persists for the current session
- [x] Stages use authored enemy team data

## Regression Check

- Boot still reaches the app shell
- Heroes and Formation screens still load
- Battle route still runs direct test encounters if no campaign stage is pending
- Phase 5 skill and energy systems still work inside campaign battles

## Known Limitations

- Campaign progression is session-only until save/load arrives in a later phase
- There is only one chapter of authored stages so far
- Stage rewards are not granted yet
- Battle restart on a campaign stage replays the same stage but does not yet show stage-completion UI

## Next Phase Goals

Phase 7 should add the reward loop:

- post-battle rewards
- currencies
- AFK reward accumulation
- claim screen
- stage-based reward scaling
