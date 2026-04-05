# Phase 17

## What Was Built

- turned duplicate summons into banked merge copies before max ascension
- added authored ascension requirements and star gains per tier
- added a real `Ascend` action to the Heroes screen
- raised hero level caps through ascension instead of leaving ascension as a placeholder concept
- extended the unified save payload to persist merge-copy banking and ascension-tier progression

## How To Run

1. Open the project in Godot 4.3 or newer.
2. Run the default main scene.
3. Use `Summon` to acquire duplicate copies, then open `Heroes` to ascend a hero once it reaches the current level cap.

Optional smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_17_smoke.gd
```

## How To Test

1. Open `Summon` and perform pulls until you gain duplicate copies for a hero.
2. Open `Heroes` and confirm the selected hero shows banked merge copies and the next ascension requirement.
3. Level that hero to the current cap if needed.
4. Press `Ascend To ...` once available.
5. Confirm the hero tier increases, stars increase, copies are spent, and the level cap rises.
6. Save and reload through `Settings` and confirm the ascension state restores.

## Acceptance Checklist

- duplicate summons bank merge copies before max ascension
- heroes can only ascend when they have enough copies and have reached the current level cap
- ascension spends copies, grants stars, and raises the level cap
- summon results and roster UI reflect the new progression model
- unified save/load restores ascension tiers and merge-copy banking

## Regression Check

- leveling still spends the correct resources and respects the current level cap
- formation power and battle payloads still reflect updated hero stats
- summon pity, quest progress, and campaign flow remain intact
- the settings route and save controls still work

## Known Limitations

- the summon economy still uses gold rather than a dedicated premium currency
- ascension currently uses only duplicate copies from summons; there is no shard crafting or alternate merge source yet
- star growth beyond max ascension is intentionally simple and does not yet have a separate awakening UI

## Next Goals

- add daily and weekly quest cadence on top of the milestone quest board
- introduce a dedicated premium summon economy
- expand ascension with richer late-game rules once more content pressure exists
