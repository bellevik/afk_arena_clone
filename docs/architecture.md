# Architecture

## Goal

This prototype is being built as a modular Godot 4 project with clear separation between app flow, gameplay systems, authored data, UI, and persistence. By Phase 22 the project has a complete local prototype loop, explicit extension hooks, playable summon and quest routes, enemy-authored ultimates, a player-facing settings surface, a first ascension pipeline, recurring daily and weekly quest cadence, a dedicated premium summon economy, a save-backed live-event reward track, event-exclusive stage variants, and temporary event combat modifiers that reuse the shared battle pipeline.

## System Layout

Current runtime slices:

- `project/scenes/boot/`
  Boot entry scene that initializes the prototype and hands off to the app shell.
- `project/scenes/menus/`
  App shell, main menu, and placeholder feature screens.
- `project/scenes/common/`
  Shared UI scenes such as the debug overlay.
- `project/scenes/heroes/`
  Phase 2 hero roster and hero card scenes.
- `project/scenes/battle/`
  Phase 3 formation screen and future battle presentation scenes.
- `project/scripts/core/`
  Cross-scene state and navigation orchestration.
- `project/scripts/data/`
  Content taxonomy, stat models, definition parsing, and data loading services.
- `project/scripts/ui/`
  Theme access, route controllers, and portrait-first screen presentation.
- `project/scripts/debug/`
  Debug overlay state and developer shortcuts.
- `project/scripts/save/`
  Unified versioned save orchestration and restore order.
- `project/scripts/systems/`
  Registry and higher-level extension helpers for future systems.

Phase 12 expansion slices:

- `project/data/stages/campaign_stages_chapter_02.json`
  Adds a second authored chapter so campaign progression now spans twenty stages.
- `project/data/balance/future_feature_hooks.json`
  Describes the future-system seams for summoning, guilds, events, PvP, and quests.
- `project/scripts/systems/future_feature_registry.gd`
  Formats those hooks into readable summaries for the home screen and future tooling.

## Autoload Usage

Phase 1 uses four narrow autoloads:

- `AppState`
  Stores lightweight session information such as current screen and boot count.
- `SceneRouter`
  Owns app-shell routing and screen definitions for the Phase 1 placeholder flow.
- `ThemeManager`
  Exposes the shared UI theme resource and color palette.
- `DebugTools`
  Manages the debug overlay state and debug navigation helpers.

Phase 2 adds:

- `GameData`
  Loads authored hero and enemy definitions from JSON files in `project/data/`.
- `ProfileState`
  Holds the current session's owned hero roster. In Phase 2 it auto-syncs to the authored hero catalog so the full sample roster is visible without save data.

Phase 3 adds:

- `FormationState`
  Owns the active five-slot team arrangement for the current session, including duplicate-prevention rules, quick clear/auto-fill actions, and team power calculation.

Phase 4 adds:

- `project/scripts/battle/battle_builder.gd`
  Builds battle-ready unit payloads from formation state and authored enemy encounters.
- `project/scripts/battle/battle_simulator.gd`
  Owns deterministic combat rules, time progression, target selection, damage, KO handling, and battle results.
- `project/scenes/battle/battle_screen.tscn`
  Presents the simulation using lightweight unit cards, timer/status labels, a result panel, and a combat log.

Phase 5 adds:

- `project/data/balance/ultimate_skills.json`
  Authored ultimate skill definitions with effect types and tuning values.
- `GameData` skill loading
  Loads and exposes ultimate skill definitions by `ultimate_id`.
- extended `BattleSimulator`
  Tracks energy, shields, haste, defense break, healing, and ultimate skill resolution.

Phase 6 adds:

- `CampaignState`
  Owns selected stage, unlocked stages, cleared stages, pending stage battle context, and last campaign battle result.
- `project/data/stages/campaign_stages.json`
  Authored campaign stage definitions with ordered progression and enemy team setups.
- `project/scenes/campaign/campaign_screen.tscn`
  Stage selection and progression UI layered on top of the existing shell.

Phase 7 adds:

- `RewardState`
  Owns gold, hero XP, AFK timestamps, highest-cleared-stage reward snapshot, and recent reward summaries.
- stage-authored reward data
  `project/data/stages/campaign_stages.json` now carries `battle_rewards` and `afk_hourly` entries per stage.
- `project/scenes/rewards/rewards_screen.tscn`
  Displays balances, pending AFK rewards, last battle rewards, and AFK claim actions.

Phase 8 adds:

- `project/data/balance/hero_progression.json`
  Authored level-up costs and ascension-tier cap rules.
- extended `ProfileState`
  Tracks owned hero levels, ascension tier foundation, star-rank foundation, and level-up validation.
- upgraded `hero_roster_screen.tscn`
  Shows upgrade costs, available resources, next-level previews, and level-up actions.

Phase 9 adds:

- `project/data/items/equipment_items.json`
  Authored item definitions with slot type, rarity, inventory count, and stat bonuses.
- `InventoryState`
  Owns inventory counts, hero equipment slots, equip and unequip flow, and aggregated equipment bonuses.
- extended Heroes screen
  Adds the inventory and equipment management UI for the selected hero.

Phase 10 adds:

- `project/scripts/save/save_state.gd`
  A unified versioned save service that serializes and restores profile, formation, campaign, rewards, and inventory.
- subsystem save boundaries
  `ProfileState`, `FormationState`, `CampaignState`, `RewardState`, and `InventoryState` now each expose `serialize_state`, `apply_state`, and reset helpers.
- expanded debug overlay
  Adds save, reload, reset, resource grant, stage unlock, and instant level-up actions for manual testing.

Phase 11 adds:

- shared UI feedback wiring in `ThemeManager`
  Buttons across routed screens now use a lightweight scale and opacity response on press.
- app-shell route transition overlay
  Screen swaps use a short fade so navigation feels less abrupt on mobile.
- portrait-first layout cleanup
  The main menu action area now uses a single-column stack to avoid cramped interactions.
- battle-card readability pass
  Unit bars and text sizing were adjusted for easier in-combat scanning.

Phase 12 adds:

- expanded authored content
  The roster now includes 12 heroes, 6 enemies, 20 campaign stages, and 2 battle test encounters.
- future-feature hook registry
  `GameData` now loads a structured registry of future systems with planned routes, save domains, and dependencies.
- home-screen expansion summary
  The main menu now exposes content footprint plus the future hooks so extension points are visible in the running prototype.

Phase 13 adds:

- `project/data/balance/summon_banners.json`
  Authored banner definitions with costs, pity thresholds, rates, featured heroes, and duplicate fallback rewards.
- `SummonState`
  Owns selected banner, pity counters, total pulls, and latest pull results.
- `project/scenes/summon/summon_screen.tscn`
  A playable summon route that consumes gold and feeds duplicate pulls into star-rank growth.
- star-rank stat scaling in `ProfileState`
  Summoned duplicates now raise `star_rank`, and star rank contributes a percentage bonus to current combat stats.

Phase 14 adds:

- `project/data/balance/quest_board.json`
  Authored milestone quest definitions with tracked event type, target count, and rewards.
- `QuestState`
  Owns quest progress, claimed state, event-listener integration, and reward claiming.
- `project/scenes/quests/quest_board_screen.tscn`
  A dedicated quest board route that shows progress and lets the player claim completed objectives.
- explicit progression signals
  `CampaignState`, `RewardState`, `ProfileState`, and `SummonState` now emit narrow gameplay events that other systems can subscribe to without diffing broad state snapshots.

Phase 15 adds:

- enemy-authored ultimate metadata
  Enemy definitions now carry `ultimate_id`, `ultimate_name`, and `ultimate_description`.
- expanded shared skill catalog
  Enemy skills live in the same `ultimate_skills.json` file as hero skills.
- unchanged battle plumbing with wider content reach
  `BattleBuilder` and `BattleSimulator` already handled skill-bearing units, so the Phase 15 work extends authored data rather than adding a second combat system path.

Phase 16 adds:

- `SettingsState`
  Owns persisted interface and audio preferences such as route transitions, button feedback, and volume targets.
- `project/scenes/settings/settings_screen.tscn`
  Replaces the old placeholder route with a real settings UI for runtime toggles and save-management actions.
- extended `SaveState`
  Persists settings alongside the existing roster, campaign, rewards, summon, quest, and inventory domains.
- runtime UX hooks
  `AppShell` and `ThemeManager` now respect settings-driven transition and button-feedback toggles.

Phase 17 adds:

- expanded hero progression rules
  `hero_progression.json` now includes duplicate-copy requirements and star gains per ascension tier.
- extended `ProfileState`
  Tracks banked merge copies per hero, validates ascension requirements, and consumes copies to raise tiers.
- upgraded roster and summon presentation
  The Heroes screen exposes an `Ascend` action, while the Summon screen now reports copy banking instead of pretending every duplicate is immediate star growth.

Phase 18 adds:

- expanded quest definitions
  `quest_board.json` now describes milestone, daily, and weekly quests in the same authored file.
- upgraded `QuestState`
  Tracks permanent milestone state separately from active recurring cycle state, with automatic daily and weekly reset buckets.
- grouped quest-board presentation
  The quest screen now surfaces cadence sections and reset timers instead of treating every quest as a permanent milestone.

Phase 19 adds:

- expanded summon banner economy data
  `summon_banners.json` now defines premium-shard exchange rates and banner-specific summon currencies.
- extended `RewardState`
  Tracks premium shard balance plus per-banner token balances inside the same unified wallet and save payload.
- upgraded summon presentation
  The Summon screen now exposes token exchange actions and shows both premium shards and selected-banner token balances.

Phase 20 adds:

- `project/data/balance/live_events.json`
  Authored live-event definitions with timing, point sources, milestone rewards, and linked summon banners.
- `EventState`
  Tracks active event selection, point totals, milestone claims, and progression earned from gameplay signals.
- `project/scenes/events/event_screen.tscn`
  Presents the active event, source breakdown, reward track, and linked-banner handoff inside the app shell.

Phase 21 adds:

- authored event-stage variants in `live_events.json`
  Each live event can now define its own stage list, enemy lineups, duration, and battle rewards.
- expanded `EventState`
  Tracks per-event stage selection, unlock state, clear state, pending battle context, and last event battle result.
- upgraded Events route
  The event screen now renders event stages, selected-stage details, and launch actions into the shared battle scene.

Phase 22 adds:

- authored event combat modifiers
  Event stages in `live_events.json` can now define temporary mutators such as stat scaling and starting-energy bonuses.
- battle-payload modifier application in `BattleBuilder`
  Event-stage modifiers are applied before unit payloads reach the simulator, which keeps the combat runtime generic.
- event and battle modifier summaries
  Both the Events route and the Battle route now surface readable modifier summaries so temporary stage rules are visible to the player.

These autoloads are intentionally small. Gameplay rules, battle logic, and authored content should not be pushed into them as the project expands.

## Data Flow

Current flow:

1. `boot.tscn` loads first.
2. `Boot.gd` increments app boot state and transfers to the app shell.
3. `AppShell.gd` registers itself with `SceneRouter`.
4. `SceneRouter` instantiates the requested screen scene into the shell's content host.
5. Feature screens react to button input and route through `SceneRouter`.
6. `DebugTools` controls the shared debug overlay visibility and shortcut actions.

Phase 2 hero roster flow:

1. `GameData` scans `project/data/heroes/` and `project/data/enemies/` on startup.
2. JSON files are parsed into normalized dictionaries with validated metadata and stat blocks.
3. `ProfileState` builds the default owned roster from the loaded hero catalog.
4. `hero_roster_screen.tscn` reads `ProfileState` entries and renders a list of hero cards.
5. Selecting a hero updates the detail panel using the authored definition data, not scene-local hardcoded values.

Phase 3 formation flow:

1. `FormationState` exposes five fixed battle slots:
   - front-left
   - front-right
   - back-left
   - back-center
   - back-right
2. The `formation` route renders those slots and highlights the currently selected slot.
3. The hero picker lists owned heroes from `ProfileState`.
4. Assigning a hero validates ownership and rejects duplicate placement.
5. Team power recalculates immediately from the assigned heroes' current level-scaled stats.

Phase 4 battle flow:

1. `GameData` loads a test encounter from `project/data/balance/battle_test_encounters.json`.
2. `BattleBuilder` converts the active formation into allied battle units and the encounter into enemy battle units.
3. `BattleSimulator` runs deterministic fixed-step combat with no RNG.
4. `battle_screen.tscn` advances the simulator, renders unit state, and appends combat log lines.
5. The result panel reports victory, defeat, or timeout without leaving the app shell.

Phase 5 battle flow:

1. Hero definitions reference `ultimate_id`.
2. `GameData` resolves that id into authored skill data.
3. `BattleBuilder` attaches the skill payload to each battle-ready hero unit.
4. `BattleSimulator` grants energy over time and from combat actions.
5. At full energy, a unit casts its authored ultimate instead of a basic attack.
6. `battle_screen.tscn` shows energy bars, cast feedback, and updated combat logs.

Phase 6 campaign flow:

1. `GameData` loads ordered campaign stages from `project/data/stages/`.
2. `CampaignState` unlocks the first stage and tracks selected/cleared stages for the current session.
3. `campaign_screen.tscn` shows stage status, selected-stage detail, and enemy lineup.
4. Launching a stage stores pending campaign battle context in `CampaignState`.
5. `battle_screen.tscn` consumes that stage context instead of the generic test encounter.
6. On victory, `CampaignState` clears the current stage and unlocks the next one.

Phase 7 reward flow:

1. Stage definitions provide per-stage battle rewards and AFK hourly rates.
2. `battle_screen.tscn` reports completed battle rewards through `RewardState`.
3. `RewardState` grants gold and hero XP immediately after a victorious battle.
4. `CampaignState` stage progression updates the highest-cleared-stage snapshot used for AFK scaling.
5. The `rewards` route reads `RewardState`, shows pending AFK income, and allows manual claiming.

Phase 8 progression flow:

1. `GameData` loads authored hero progression rules from `project/data/balance/hero_progression.json`.
2. `ProfileState` exposes the current hero level, ascension-tier cap, and the next level-up cost for each owned hero.
3. The Heroes screen reads both `ProfileState` and `RewardState` to present upgrade availability.
4. Pressing `Level Up` spends gold and hero XP through `RewardState`.
5. The owned hero level updates inside `ProfileState`, which immediately changes roster rendering, formation power, and battle payload stats.

Phase 9 equipment flow:

1. `GameData` loads authored items from `project/data/items/`.
2. `InventoryState` seeds current inventory counts from authored starting counts and tracks equipped items per hero.
3. The Heroes screen reads `InventoryState` for slot state and available items.
4. Equipping or unequipping an item updates inventory counts and emits `inventory_changed`.
5. `ProfileState.hero_stats()` folds gear bonuses into the hero's level-scaled stats.
6. Formation power and battle payload generation automatically pick up the upgraded stats without extra per-scene logic.

Phase 10 save flow:

1. `SaveState` listens to progression-related subsystem signals.
2. When profile, formation, campaign, rewards, or inventory change, `SaveState` queues a deferred autosave.
3. The save file stores a `version` plus one dictionary per subsystem.
4. On boot, `SaveState` restores each subsystem in dependency order:
   - profile
   - inventory
   - rewards
   - campaign
   - formation
5. If the save file is missing, the game uses authored defaults.
6. If the save file is corrupt or invalid, the game resets to defaults and rewrites a clean save.

Phase 11 UX flow:

1. `ThemeManager` applies the shared theme and recursively wires button feedback for loaded controls.
2. `AppShell` fades routed screen swaps through a lightweight overlay.
3. Screen-specific layout adjustments prioritize portrait tap comfort over information density.
4. Battle card styling improves signal-to-noise without changing combat rules.

Phase 12 extension-hook flow:

1. `GameData` loads `future_feature_hooks.json` alongside battle, stage, skill, and progression data.
2. Each feature hook records a stable id, planned route, save domain, primary UI surface, and dependencies.
3. `FutureFeatureRegistry` formats those hook definitions for player-visible or developer-visible summaries.
4. The main menu surfaces that registry so the prototype communicates where summoning, guilds, events, PvP, and quests attach next.

Phase 13 summon flow:

1. `GameData` loads authored summon banners from `summon_banners.json`.
2. `SummonState` tracks the current banner, pity count, and latest pull results.
3. The summon screen spends gold through `RewardState`.
4. Pull results resolve into hero ids from the existing roster catalog, weighted by rarity and featured entries.
5. `ProfileState` converts duplicate pulls into `star_rank`, which directly boosts hero stats.
6. `SaveState` persists summon banner state alongside profile, formation, campaign, rewards, and inventory.

Phase 14 quest flow:

1. `GameData` loads milestone quest definitions from `quest_board.json`.
2. `QuestState` subscribes to narrow progression signals:
   - `stage_cleared`
   - `battle_rewards_granted`
   - `afk_rewards_claimed`
   - `hero_leveled`
   - `summon_completed`
3. Matching quest entries advance progress immediately when those events fire.
4. The quest board route renders authored progress and claim state.
5. Claiming a completed quest grants rewards through `RewardState`.
6. `SaveState` persists quest progress and claimed entries with the unified save file.

Phase 15 enemy-skill flow:

1. `GameData` loads enemy ultimates from each enemy definition and resolves their `ultimate_id` through the shared skill catalog.
2. `BattleBuilder` attaches that skill payload to enemy battle units in the same way it already does for heroes.
3. `BattleSimulator` treats enemy units exactly like player units for energy gain and casting rules.
4. Battle UI feedback, cast banners, combat log entries, and result summaries automatically reflect enemy casts with no parallel presentation path.

Phase 16 settings flow:

1. `SettingsState` boots with authored defaults and applies runtime-safe values such as master bus volume.
2. The `settings` route renders those values through `settings_screen.tscn`.
3. Player-facing toggles and sliders update `SettingsState` immediately.
4. `SaveState` listens to `settings_changed` and persists the settings block into the unified save payload.
5. `AppShell` and `ThemeManager` read current settings at interaction time, so route transitions and button feedback change without restarting the app.

Phase 17 ascension flow:

1. Duplicate summons enter `ProfileState.award_summoned_hero`.
2. Before a hero reaches max ascension, each duplicate is banked as a merge copy instead of granting direct power.
3. The Heroes screen shows current tier, banked copies, required copies, and the next ascension target.
4. Once a hero reaches the current level cap and has enough merge copies, the player can ascend manually.
5. Ascension spends the copies, raises the hero tier, grants authored stars, and increases the level cap used by the existing level-up flow.
6. `SaveState` persists tier, stars, and merge copies in the same profile payload as the rest of the roster state.

Phase 18 recurring-quest flow:

1. `GameData` loads quest cadence from the same quest-board data file as milestone objectives.
2. `QuestState` stores milestone progress separately from recurring daily and weekly state.
3. Gameplay events such as battle wins, stage clears, AFK claims, hero level-ups, and summons still feed one shared event path.
4. For daily and weekly quests, `QuestState` checks the current active cycle key and resets stale cycle data automatically.
5. The quest board groups entries by cadence and shows the remaining time before recurring resets.
6. `SaveState` persists active recurring progress and claimed state alongside the older milestone quest data.

Phase 19 premium-summon flow:

1. `GameData` loads each banner's dedicated token id, token label, and shard exchange rates.
2. `RewardState` tracks premium shards and token balances alongside gold and hero XP.
3. The Summon screen exchanges premium shards into the selected banner's token currency.
4. `SummonState` spends banner-specific tokens, not gold, when performing pulls.
5. Recurring quests can now grant premium shards, which feed back into the summon exchange loop.
6. `SaveState` persists shard and token balances in the unified rewards domain.

Phase 20 live-event flow:

1. `GameData` loads authored event timing, point sources, milestone rewards, and linked banner ids from `live_events.json`.
2. `EventState` listens to narrow gameplay signals from campaign clears, AFK claims, summons, and quest claims.
3. Matching point-source rules convert those signals into event points for the currently active event.
4. The Events screen renders milestone progress and claims rewards through the shared `RewardState` wallet.
5. The linked-banner action hands the player directly into the event-associated summon banner without scene-local coupling.
6. `SaveState` persists event points and claimed milestones in the same unified save file as the rest of progression.

Phase 21 event-stage flow:

1. `GameData` loads authored event stages from the same `live_events.json` file as milestone rewards and point sources.
2. `EventState` exposes selected, unlocked, and cleared event-stage state per active event.
3. Launching an event stage stores pending event battle context directly in `EventState`.
4. `battle_screen.tscn` resolves either campaign or event battle context and runs both through the same deterministic combat path.
5. Victorious event-stage clears unlock the next event stage, award stage rewards through `RewardState`, and grant event points through the existing event-point source mechanism.
6. `SaveState` persists event-stage progression alongside milestone claims and point totals in the unified save file.

Future gameplay data should flow through authored resources or structured data files loaded by dedicated services, not directly embedded in UI scenes.

## Battle Flow

Phase 4 currently supports:

- one authored test encounter
- allied lineup from the current formation
- enemy lineup from authored encounter data
- fixed-step deterministic combat
- auto-attacks only
- frontline-priority targeting
- KO handling and timeout end conditions
- restart and speed-toggle debug controls

Phase 5 currently adds:

- energy-driven ultimates
- team healing and shielding
- temporary haste buffs
- temporary defense break debuffs
- skill cast feedback in the battle UI

Phase 6 currently adds:

- ordered campaign progression
- stage selection from UI
- stage-specific enemy formations
- next-stage unlock flow tied to battle results

Phase 7 currently adds:

- post-battle gold and hero XP payouts
- AFK income scaled from the highest cleared campaign stage
- local reward-state persistence in `user://reward_state.json`
- a dedicated rewards claim screen

Phase 8 currently adds:

- hero leveling driven by earned resources
- level-up cost enforcement
- ascension-tier level-cap foundation
- immediate stat growth reflected in battle setup and combat outcomes

Phase 9 currently adds:

- authored equipment items
- equip and unequip flow
- inventory counts
- gear-derived stat bonuses in formation and battle

Phase 10 currently adds:

- unified save/load
- save versioning
- corrupt-save recovery
- debug actions for progression and save testing

Phase 11 currently adds:

- button press feedback
- app-shell transitions
- portrait-friendlier route layout
- improved battle readability

Current next-step candidates after Phase 21:

- banner-specific monetization hooks or storefront flow
- temporary event combat modifiers layered on top of the new event-stage route
- a seasonal quest layer that ties recurring objectives into the live-event schedule

## Save Flow

Not implemented in Phase 1.

Current direction:

- `SaveState` now owns the active versioned save file at `user://save_game.json`
- older single-system save artifacts can be migrated or discarded in later cleanup work
- future save migrations should extend the same payload with equipment upgrades, quests, summoning, and other progression systems
- missing or invalid fields continue to fall back safely to authored defaults
