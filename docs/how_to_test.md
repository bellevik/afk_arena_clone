# How To Test

## Phase 1 Manual Test Flow

### Launch

1. Open the project in Godot 4.x.
2. Run the project.
3. Confirm the boot screen appears briefly, then transitions into the app shell.

### Navigation

1. Confirm the main menu opens by default.
2. Tap or click each bottom navigation button:
   - `Home`
   - `Heroes`
   - `Campaign`
   - `Battle`
   - `Rewards`
   - `Settings`
3. Confirm each destination screen loads without missing references or script errors.
4. Use the `Back to Main Menu` button from each placeholder screen.

### Portrait Framing

1. Resize the desktop window to wide and tall aspect ratios.
2. Confirm the portrait play area remains centered and the app remains readable.
3. Confirm buttons remain large enough to click comfortably.

### Debug Overlay

1. Press the `DEV` button in the header.
2. Confirm the debug overlay appears over the current screen.
3. Use `Cycle Screen` and verify the screen changes.
4. Use direct screen jump buttons and verify routing works.
5. Use `Reset Nav` and verify the app returns to the main menu.
6. Close the overlay and confirm normal navigation still works.

## Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_01_smoke.gd
```

Expected result:

- `Phase 1 smoke test passed.`

## Debug Notes

- The debug overlay is a Phase 1 developer utility, not player-facing UX.
- The state panel reflects lightweight session state only in this phase.

## Phase 2 Manual Test Flow

### Hero Roster

1. Launch the project and open `Heroes`.
2. Confirm at least 8 heroes are listed.
3. Tap or click each hero card.
4. Confirm the detail panel updates with:
   - name
   - rarity
   - role
   - faction
   - lore
   - base stats
   - growth per level
   - ultimate name and description
   - data source path

### Data Reload

1. While the project is closed or running, duplicate one hero JSON file in `project/data/heroes/`.
2. Change its `id`, `name`, and optional stats.
3. Launch the project or press `Reload Data` on the Heroes screen.
4. Confirm the new hero appears in the roster and can be selected.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_02_smoke.gd
```

Expected result:

- `Phase 2 smoke test passed.`

## Phase 3 Manual Test Flow

### Formation Screen

1. Launch the project and open `Formation` from the main menu or debug menu.
2. Select each slot:
   - `Front Left`
   - `Front Right`
   - `Back Left`
   - `Back Center`
   - `Back Right`
3. Assign heroes to all five slots from the picker list.
4. Confirm the summary updates with:
   - assigned count
   - front/back counts
   - status
   - team power

### Validation Rules

1. Assign a hero to one slot.
2. Try assigning the same hero to another slot.
3. Confirm the duplicate placement is rejected.
4. Remove a hero from a filled slot and confirm the slot clears.
5. Use `Clear Formation` and confirm all five slots empty.
6. Use `Auto-Fill` and confirm all five slots populate.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_03_smoke.gd
```

Expected result:

- `Phase 3 smoke test passed.`

## Phase 4 Manual Test Flow

### Battle Screen

1. Launch the project and open `Formation`.
2. Assign heroes manually or use `Auto-Fill`.
3. Open `Battle`.
4. Confirm allied units appear on the left side and enemies appear on the right side.
5. Confirm front slots are positioned ahead of back slots.
6. Let the battle run and verify:
   - units auto-attack
   - HP bars decrease
   - KO units gray out and stop acting
   - the battle ends with `Victory`, `Defeat`, or `Time Up`

### Debug Controls

1. Press `Restart Battle` and confirm the same encounter restarts immediately.
2. Press `Speed` to cycle `1x`, `2x`, and `4x`.
3. Confirm the encounter resolves faster at higher speed while preserving the same winner.
4. Open `Battle` with an empty formation and confirm it auto-fills a lineup for testing.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_04_smoke.gd
```

Expected result:

- `Phase 4 smoke test passed.`
