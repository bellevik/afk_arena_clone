# Phase 9: Equipment / Gear Foundation

## What Was Built

- authored equipment items in `project/data/items/equipment_items.json`
- a shared `InventoryState` autoload for item counts and hero equipment slots
- weapon, armor, and accessory slot support
- equip and unequip flow on the Heroes screen
- automatic stat-bonus aggregation from equipped gear
- formation power and battle setup now include equipment bonuses

## How To Run

Open the repository root in Godot 4.3+ and run the project, or start it from the terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

## How To Test

1. Launch the project and open `Heroes`.
2. Select a hero and scroll to the equipment section.
3. Equip a weapon, armor, and accessory from the inventory list.
4. Confirm the item counts decrease and the hero's visible stats rise immediately.
5. Equip a different item into the same slot and confirm the previous item returns to inventory.
6. Unequip an item by tapping its equipped slot row and confirm the item returns to inventory.
7. Open `Formation` and confirm the active team's power changes if the equipped hero is assigned.
8. Run a battle and confirm the geared hero enters battle with the stronger stats.
9. Optionally run the headless smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_09_smoke.gd
```

## Acceptance Checklist

- [x] Gear can be equipped and removed
- [x] Stats update immediately
- [x] Gear affects battle performance
- [x] Inventory UI remains stable while equipping and replacing items

## Regression Check

- Hero leveling still works
- Reward and AFK collection still work
- Campaign progression still unlocks stages correctly
- Battle still resolves deterministic auto-combat with ultimates

## Known Limitations

- Equipment inventory is session-only and not part of a unified save payload yet
- There is no loot-drop source for gear yet; inventory starts from authored sample counts
- Gear has no upgrade, rarity-roll, or set-bonus system yet
- Equipment management currently lives on the Heroes screen rather than a dedicated inventory route

## Next Phase Goals

Phase 10 should harden persistence and test utilities:

- unified save/load
- save versioning
- reset save
- debug grants and unlock shortcuts
