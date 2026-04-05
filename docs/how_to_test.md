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

## Phase 5 Manual Test Flow

### Energy And Ultimates

1. Launch the project and open `Formation`.
2. Create a mixed lineup with frontline heroes plus at least one support or mage.
3. Open `Battle`.
4. Confirm each combat card shows:
   - energy bar
   - HP bar
   - status line
5. Let the battle run and verify:
   - energy fills over time
   - at full energy, heroes cast ultimates
   - the cast banner appears
   - combat log contains `used`
   - some skills apply healing, shielding, haste, or defense break

### Composition Check

1. Run one battle with a tank-heavy team.
2. Run another battle with more damage-heavy backliners.
3. Confirm the pacing, skill timing, and final outcome change.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_05_smoke.gd
```

Expected result:

- `Phase 5 smoke test passed.`

## Phase 6 Manual Test Flow

### Campaign Progression

1. Launch the project and open `Campaign`.
2. Confirm stage `1-1 Dawn Patrol` is unlocked.
3. Confirm later stages appear but remain locked.
4. Select `1-1 Dawn Patrol`.
5. Confirm the detail panel shows:
   - recommended power
   - duration
   - enemy lineup
6. Press `Launch 1-1 Dawn Patrol`.
7. Let the battle finish.
8. Return to `Campaign` and confirm:
   - `1-1 Dawn Patrol` is marked cleared after victory
   - `1-2 Ash Route` is now unlocked
9. Replay stage 1 and confirm it remains cleared.
10. Attempt a stage while underpowered and confirm a loss does not unlock the next stage.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_06_smoke.gd
```

Expected result:

- `Phase 6 smoke test passed.`

## Phase 7 Manual Test Flow

### Battle Rewards

1. Launch the project and open `Campaign`.
2. Select an unlocked stage and launch the battle.
3. Let the battle finish with a victory.
4. Confirm the result panel now includes a reward line with gold and hero XP.
5. Open `Rewards`.
6. Confirm `Last Battle Rewards` shows the cleared stage and the same payout values.
7. Confirm the top balance panel increased by that reward amount.

### AFK Rewards

1. Stay on `Rewards`.
2. Press `Debug +2h AFK`.
3. Confirm the AFK panel shows pending gold and hero XP based on the highest cleared stage.
4. Press `Claim AFK Rewards`.
5. Confirm:
   - balances increase immediately
   - pending AFK rewards reset to zero
   - `Last AFK Claim` updates
6. Clear another campaign stage and return to `Rewards`.
7. Confirm the AFK snapshot stage updates so future idle income scales higher.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_07_smoke.gd
```

Expected result:

- `Phase 7 smoke test passed.`

## Phase 8 Manual Test Flow

### Hero Leveling

1. Launch the project and make sure you have some gold and hero XP from battles or AFK claims.
2. Open `Heroes`.
3. Select a hero.
4. Confirm the detail panel now shows:
   - available gold and hero XP
   - ascension tier and current level cap
   - next-level stat preview
   - upgrade cost
5. Press `Level Up`.
6. Confirm:
   - the hero level increases
   - gold and hero XP decrease
   - current stats and roster card stats update immediately

### Cost And Cap Validation

1. Try leveling a hero without enough resources.
2. Confirm the button disables and the panel explains that more gold and hero XP are needed.
3. Continue leveling a hero to the current cap.
4. Confirm the panel switches to `Level Cap Reached`.

### Battle Performance Check

1. Note a hero's current level and team power on `Formation`.
2. Level that hero up on `Heroes`.
3. Return to `Formation` and confirm team power increases.
4. Run the same battle before and after leveling.
5. Confirm the upgraded team performs better or at least more comfortably in the deterministic fight.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_08_smoke.gd
```

Expected result:

- `Phase 8 smoke test passed.`

## Phase 9 Manual Test Flow

### Equipment And Inventory

1. Launch the project and open `Heroes`.
2. Select a hero.
3. Scroll to the equipment section.
4. Confirm the panel shows:
   - current equipment bonuses
   - three gear slots: weapon, armor, accessory
   - inventory entries with counts and stat bonuses
5. Tap an available item in the inventory list.
6. Confirm:
   - the item equips to the matching slot
   - the item count decreases
   - current hero stats increase immediately
7. Tap a second item for the same slot.
8. Confirm the old item returns to inventory and the new bonuses replace it.
9. Tap an equipped slot entry and confirm the item unequips and returns to inventory.

### Battle Integration

1. Equip gear on a hero that is part of the active formation.
2. Open `Formation`.
3. Confirm team power increases.
4. Open `Battle`.
5. Confirm the equipped hero has higher battle stats than before.
6. Run the same encounter with and without gear and confirm the geared team performs better or at least more comfortably.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_09_smoke.gd
```

Expected result:

- `Phase 9 smoke test passed.`

## Phase 10 Manual Test Flow

### Save And Reload

1. Launch the project.
2. Make some progress:
   - level up a hero
   - equip an item
   - clear a campaign stage
   - assign a formation
3. Open the `DEV` menu.
4. Press `Save`.
5. Press `Reload Save`.
6. Confirm the following state remains intact:
   - hero levels
   - equipped gear
   - formation assignments
   - currencies
   - campaign progress

### Reset And Debug Tools

1. Open the `DEV` menu again.
2. Press `+5000 Resources` and confirm gold and hero XP increase.
3. Press `Unlock All Stages` and confirm all campaign stages become available.
4. Press `Cap All Heroes` and confirm owned heroes jump to their current caps.
5. Press `Reset Save`.
6. Confirm the game returns to authored defaults:
   - heroes back to level 1
   - no equipped gear
   - empty formation
   - currencies reset
   - campaign progress reset

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_10_smoke.gd
```

Expected result:

- `Phase 10 smoke test passed.`

## Phase 11 Manual Test Flow

### Shell Flow And Tap Feedback

1. Launch the project.
2. Move between `Home`, `Heroes`, `Campaign`, `Battle`, and `Rewards`.
3. Confirm:
   - route changes use a short fade transition
   - buttons visually press down and recover on release
   - the main menu uses a single-column route stack that is easy to tap in portrait

### Battle Readability

1. Open `Battle`.
2. Confirm unit cards read more clearly than before:
   - stronger HP and energy bars
   - calmer text sizing
   - compact status labels
3. Let a battle run and confirm the card readability holds during active combat.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_11_smoke.gd
```

Expected result:

- `Phase 11 smoke test passed.`

## Phase 12 Manual Test Flow

### Expanded Content

1. Launch the project and open `Home`.
2. Confirm the new expansion panel shows:
   - 12 heroes
   - 6 enemies
   - 20 stages
   - 2 test encounters
3. Confirm the same panel lists future hooks for:
   - Summoning Banners
   - Guilds
   - Limited Events
   - PvP Ladder
   - Quest Board

### Campaign Breadth

1. Open `Campaign`.
2. Confirm the stage list now continues through Chapter 2.
3. Use the debug overlay to `Unlock All Stages` if needed for quick verification.
4. Select a late Chapter 2 stage and confirm the enemy lineup includes newer enemies such as:
   - `Storm Lancer`
   - `Bog Shambler`
   - `Ashen Seer`

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_12_smoke.gd
```

Expected result:

- `Phase 12 smoke test passed.`

## Phase 13 Manual Test Flow

### Summon Screen

1. Launch the project and open `Home`.
2. Press `Open Summon`.
3. Confirm at least two banners appear.
4. Select each banner and verify the detail section updates with:
   - gold cost
   - ten-pull cost
   - pity threshold
   - featured heroes

### Pull Flow

1. Ensure you have enough gold from rewards or use `DEV -> +5000 Resources`.
2. Press `Recruit x1`.
3. Confirm:
   - gold decreases
   - the latest results panel populates
   - the selected banner pity count updates unless a Legendary was pulled
4. Press `Recruit x10`.
5. Confirm the results panel shows 10 entries and total pulls increase.

### Roster Impact

1. After summoning, open `Heroes`.
2. Select one of the summoned heroes.
3. Confirm `Stars` increased and the hero now shows a summon bonus percentage.
4. Open `Formation` or `Battle` and confirm the boosted hero contributes more power.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_13_smoke.gd
```

Expected result:

- `Phase 13 smoke test passed.`

## Phase 14 Manual Test Flow

### Quest Board

1. Launch the project and open `Home`.
2. Press `Open Quests`.
3. Confirm the board lists milestone quests for:
   - campaign stage clears
   - battle wins
   - hero level-ups
   - summon pulls
   - AFK claims

### Progression Hooks

1. Win a battle and confirm the battle-win quest progresses.
2. Clear a new campaign stage and confirm the stage-clear quest progresses.
3. Level up a hero and confirm the hero-growth quest progresses.
4. Perform summon pulls and confirm the banner quest progresses.
5. Claim AFK rewards and confirm the idle quest progresses.

### Reward Claim

1. Complete at least one quest target.
2. Press `Claim`.
3. Confirm:
   - the claim button changes to `Claimed`
   - gold and hero XP increase
   - the quest remains completed after leaving and re-entering the screen

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_14_smoke.gd
```

Expected result:

- `Phase 14 smoke test passed.`

## Phase 15 Manual Test Flow

### Enemy Skill Identity

1. Launch the project and open `Battle`.
2. Use a longer or later encounter such as:
   - `field_trial_bravo` in debug validation
   - later Chapter 2 campaign stages in normal play
3. Let the battle run long enough for enemy energy to fill.
4. Confirm the combat log now includes enemy casts such as:
   - `Cinder Lunge`
   - `Sepulcher Guard`
   - `Riptide Volley`
   - `Ashen Prophecy`

### Battle Impact

1. Run a later Chapter 2 stage.
2. Confirm enemy skills visibly affect pacing and pressure instead of relying only on basic attacks.
3. Verify the cast banner still appears and the battle resolves cleanly.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_15_smoke.gd
```

Expected result:

- `Phase 15 smoke test passed.`

## Phase 16 Manual Test Flow

### Settings Screen

1. Launch the project and open `Settings`.
2. Confirm the route is no longer a placeholder screen.
3. Verify the screen shows:
   - interface toggles
   - master, music, and SFX sliders
   - save, reload, and reset buttons
   - current save status text

### Runtime Toggles

1. Turn off `Enable route transitions`.
2. Switch between `Home`, `Heroes`, and `Campaign`.
3. Confirm screen swaps happen immediately with no fade.
4. Turn off `Enable button feedback`.
5. Press several buttons across the app shell and current route.
6. Confirm buttons no longer scale or dim on press.
7. Re-enable both toggles and confirm the feedback returns.

### Save Management

1. Change at least one setting slider and one toggle.
2. Press `Save Now`.
3. Change the settings again to different values.
4. Press `Reload Save`.
5. Confirm the earlier saved values restore.
6. Press `Reset Save` once and confirm the label changes to `Confirm Reset Save`.
7. Press it again and confirm the prototype returns to authored defaults and routes back to `Home`.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_16_smoke.gd
```

Expected result:

- `Phase 16 smoke test passed.`

## Phase 17 Manual Test Flow

### Merge Copies

1. Launch the project and open `Summon`.
2. Use `DEV -> +5000 Resources` if needed.
3. Pull on a banner until one or more duplicate heroes appear.
4. Confirm summon results now show merge-copy banking or ascension/star progress instead of always saying duplicates became direct star growth.

### Ascension

1. Open `Heroes`.
2. Select a hero with banked merge copies.
3. Confirm the detail panel shows:
   - current ascension tier
   - current stars
   - banked merge copies
   - copies required for the next tier
4. Level that hero to its current cap if needed.
5. Press `Ascend To ...` once the button becomes available.
6. Confirm:
   - the ascension tier increases
   - banked merge copies decrease
   - stars increase by the authored tier bonus
   - the hero level cap rises

### Save And Restore

1. After ascending a hero, open `Settings`.
2. Press `Save Now`.
3. Change progression further or reload the app.
4. Press `Reload Save` or relaunch the project.
5. Confirm the ascension tier, stars, and remaining merge copies restore correctly.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_17_smoke.gd
```

Expected result:

- `Phase 17 smoke test passed.`

## Phase 18 Manual Test Flow

### Recurring Quest Board

1. Launch the project and open `Quests`.
2. Confirm the board is now grouped into:
   - milestone quests
   - daily quests
   - weekly quests
3. Confirm daily and weekly sections show reset timers.

### Daily And Weekly Progress

1. Win several battles, claim AFK rewards, level heroes, or summon on a banner.
2. Return to `Quests`.
3. Confirm both milestone and recurring entries advance from the same gameplay actions.
4. Claim a completed daily or weekly quest and confirm gold and hero XP increase.

### Save And Restore

1. Progress at least one daily or weekly quest.
2. Open `Settings` and press `Save Now`.
3. Press `Reload Save`.
4. Confirm the recurring quest progress and claim state restore for the current active cycle.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_18_smoke.gd
```

Expected result:

- `Phase 18 smoke test passed.`

## Phase 19 Manual Test Flow

### Premium Summon Wallet

1. Launch the project and open `Rewards` or `Summon`.
2. Use `DEV -> +5000 Resources`.
3. Confirm the balance display now includes:
   - premium shards
   - banner-specific summon token balances

### Banner Token Exchange

1. Open `Summon`.
2. Select one banner.
3. Press `Forge x1` or `Forge x10`.
4. Confirm premium shards decrease and the selected banner token balance increases.
5. Press `Recruit x1` or `Recruit x10`.
6. Confirm banner tokens, not gold, are consumed for the pull.

### Save And Restore

1. Exchange some banner tokens but do not spend all of them.
2. Open `Settings` and press `Save Now`.
3. Change balances further, then press `Reload Save`.
4. Confirm premium shards and banner token balances restore.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_19_smoke.gd
```

Expected result:

- `Phase 19 smoke test passed.`

## Phase 20 Manual Test Flow

### Live Event Route

1. Launch the project and open `Events` from the main menu or debug menu.
2. Confirm an active event appears with:
   - event name and description
   - current points
   - end timer
   - linked banner button
3. Confirm the point-source panel lists campaign clears, summons, AFK claims, and quest claims.

### Event Progression

1. Clear a campaign stage.
2. Perform at least one summon pull.
3. Claim an AFK reward or a quest reward.
4. Return to `Events`.
5. Confirm event points increased and milestone progress bars moved forward.

### Milestone Claim And Banner Hook

1. Use `DEV -> +150 Event Pts` if you need to reach a milestone faster.
2. Claim the first available milestone.
3. Confirm the granted rewards increase balances immediately.
4. Press `Open linked banner`.
5. Confirm the app routes to `Summon` and the event-linked banner is selected.

### Save / Reload

1. Open `Settings` and press `Save Now`.
2. Change event progress by clearing another stage or using `+150 Event Pts`.
3. Press `Reload Save`.
4. Confirm event points and claimed milestone state restore to the saved values.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_20_smoke.gd
```

Expected result:

- `Phase 20 smoke test passed.`

## Phase 21 Manual Test Flow

### Event Stages

1. Launch the project and open `Events`.
2. Confirm the active event now includes an `Event Stages` section.
3. Confirm the first event stage is unlocked and later event stages begin locked.
4. Select the first event stage and verify the detail panel shows:
   - recommended power
   - duration
   - enemy lineup
   - launch button

### Stage Progression

1. Press `Launch` on the first event stage.
2. Let the battle finish with a victory.
3. Return to `Events`.
4. Confirm:
   - the cleared stage is marked `Cleared`
   - the next event stage is now unlocked
   - the stage reward increased balances
   - event points also increased from the event-stage clear

### Save / Reload

1. Open `Settings` and press `Save Now`.
2. Make more event progress or use `DEV -> +150 Event Pts`.
3. Press `Reload Save`.
4. Confirm event-stage clear state, unlocks, and event points restore to the saved values.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_21_smoke.gd
```

Expected result:

- `Phase 21 smoke test passed.`

## Phase 22 Manual Test Flow

### Event Stage Modifiers

1. Launch the project and open `Events`.
2. Select `Cinder Gate`.
3. Confirm the selected-stage detail panel now includes a `Stage modifiers` section.
4. Confirm `Cinder Gate` lists temporary rules such as allied attack gain, enemy HP gain, and allied starting energy.

### Battle Integration

1. Press `Launch Cinder Gate`.
2. Confirm the battle screen includes a `Stage modifiers` summary.
3. Confirm allied units begin with visible starting energy on the stages that grant it.
4. Let the battle run and confirm the event-stage fight still resolves cleanly.

### Optional Headless Smoke Test

Run this from the repository root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_22_smoke.gd
```

Expected result:

- `Phase 22 smoke test passed.`
