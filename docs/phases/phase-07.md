# Phase 7: Rewards, Economy, and Idle/AFK Collection

## What Was Built

- `RewardState` autoload for gold, hero XP, AFK timestamps, highest-cleared-stage reward scaling, and recent reward summaries
- stage-authored `battle_rewards` and `afk_hourly` data in `project/data/stages/campaign_stages.json`
- battle result payout integration in the Phase 5/6 battle screen
- real `Rewards` route and screen
- AFK claim flow with current pending rewards, last battle payout, and last AFK claim summary
- local reward persistence in `user://reward_state.json`
- small debug helper on the Rewards screen to simulate two hours of AFK accumulation

## How To Run

Open the repository root in Godot 4.3+ and run the project, or start it from the terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

## How To Test

1. Launch the project and open `Campaign`.
2. Clear `1-1 Dawn Patrol`.
3. Open `Rewards` and confirm the battle payout appears under `Last Battle Rewards`.
4. Confirm the top balance panel increased by the same amount.
5. Press `Debug +2h AFK`.
6. Confirm the AFK panel shows pending gold and hero XP.
7. Press `Claim AFK Rewards`.
8. Confirm balances increase, pending AFK rewards reset, and `Last AFK Claim` updates.
9. Clear another stage and confirm the AFK snapshot stage increases.
10. Optionally run the headless smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_07_smoke.gd
```

## Acceptance Checklist

- [x] Post-battle rewards are granted correctly
- [x] AFK rewards accumulate over elapsed time
- [x] Claiming AFK rewards updates balances
- [x] Reward scaling responds to campaign progress
- [x] The rewards route is manually testable in the app shell

## Regression Check

- Boot still reaches the app shell
- Heroes, Formation, Campaign, and Battle screens still load
- Campaign victories still unlock the next stage
- Battle restart and speed controls still work
- Phase 5 ultimate skills still resolve during battle

## Known Limitations

- Reward balances persist locally, but roster, formation, and campaign progression still do not share a unified save system
- Reward tuning is authored only for the first 10 sample stages
- The AFK cap is fixed at 12 hours and not yet player-facing in settings
- Enemy units still do not have authored ultimate skills

## Next Phase Goals

Phase 8 should turn the new resources into hero growth:

- hero leveling
- resource costs
- stat scaling from upgrades
- first-pass upgrade UI
