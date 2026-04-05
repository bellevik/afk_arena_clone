# Phase 8: Hero Progression Systems

## What Was Built

- authored hero progression rules in `project/data/balance/hero_progression.json`
- level-up costs for each level bracket
- ascension-tier level-cap foundation for future merge and star-up systems
- extended `ProfileState` to track hero levels, ascension tier, and star-rank placeholders
- level-up flow on the Heroes screen
- upgrade preview with next-level stat gains
- resource spending through `RewardState`
- roster and battle payload updates that reflect the upgraded hero level immediately

## How To Run

Open the repository root in Godot 4.3+ and run the project, or start it from the terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

## How To Test

1. Launch the project and earn some gold and hero XP from battles or AFK rewards.
2. Open `Heroes`.
3. Select a hero and confirm the detail panel shows available resources, current level cap, and upgrade cost.
4. Press `Level Up`.
5. Confirm the hero level increases and resources decrease.
6. Confirm the roster card updates immediately with stronger stats.
7. Open `Formation` and confirm team power increases if that hero is assigned.
8. Run a battle again and confirm the upgraded team performs better.
9. Continue leveling to the current cap and confirm the panel blocks further upgrades at the cap.
10. Optionally run the headless smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_08_smoke.gd
```

## Acceptance Checklist

- [x] Player can upgrade heroes
- [x] Stats update correctly after level-ups
- [x] Stronger heroes produce stronger battle payloads
- [x] Upgrade costs are enforced
- [x] Level-cap rules are enforced

## Regression Check

- Rewards and AFK claim flow still work
- Campaign stages still unlock in order
- Formation still prevents duplicate hero placement
- Battle still resolves with deterministic combat and ultimate skills

## Known Limitations

- Hero levels do not yet persist inside a unified save system
- Ascension is only a structural foundation in this phase; there is no real merge flow yet
- Equipment and other long-term power systems are still missing
- Enemy progression still comes only from stage-authored levels

## Next Phase Goals

Phase 9 should add the first equipment layer:

- item data
- equip and unequip flow
- stat bonuses from gear
- inventory UI
