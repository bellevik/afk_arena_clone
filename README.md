# Shardfall Legends

Shardfall Legends is an original Godot 4 prototype for a mobile-first idle hero battler inspired by the broad genre conventions of collection RPG auto-battlers. The project is being built in strict phases, with each phase leaving the game runnable and manually testable.

## Current Scope

Phase 22 currently delivers:

- portrait-first Godot project configuration
- boot scene and app shell
- main menu
- a data-driven hero roster screen with detail panel
- a five-slot formation screen with session assignment state
- a deterministic auto-battle test scene driven by the active formation
- authored battle encounter data and enemy team loading
- authored ultimate skill data
- hero energy gain and automatic ultimate casting
- shield, heal, haste, and defense-break combat effects
- authored campaign stage data
- campaign screen with stage selection and unlock progression
- campaign battle launch using stage enemy formations
- stage-authored battle rewards and AFK hourly reward rates
- `RewardState` resource balances with simple local persistence
- rewards screen with AFK claim flow, last battle reward summary, and debug AFK simulation
- authored hero progression rules with level costs and ascension-tier caps
- hero leveling from earned resources on the Heroes screen
- immediate stat growth reflected in roster cards, formation power, and battle payloads
- authored equipment items with weapon, armor, and accessory slots
- shared inventory counts plus equip and unequip flow on the Heroes screen
- gear bonuses applied directly to hero stats, formation power, and battle setup
- a unified versioned save file for roster, formation, campaign, rewards, and equipment state
- corrupt-save recovery back to authored defaults
- expanded debug tools for save, reload, reset, grant resources, unlock stages, and cap heroes
- shared button press feedback across routed UI screens
- route transitions in the app shell
- portrait-friendlier main menu layout and calmer battle card readability
- expanded roster content with 12 authored heroes and 6 enemy archetypes
- a 20-stage sample campaign across two chapters
- a second battle test encounter for later-game combat validation
- a future-feature registry describing summoning, guilds, events, PvP, and quest hooks
- a home-screen expansion panel that surfaces content footprint and future extension points
- a playable summon banner screen with exchange, single-pull, and ten-pull actions
- authored summon banner definitions with banner-specific currency, shard exchange costs, pity thresholds, and featured heroes
- duplicate summon rewards that increase hero star rank and boost combat stats
- unified save support for banner selection, pity counters, pull totals, and latest summon results
- a playable quest board screen with claimable milestone objectives
- authored quest definitions tied to stage clears, battle wins, AFK claims, hero levels, and summons
- progression event hooks that let quests react to gameplay without polling broad state diffs
- unified save support for quest progress and claimed rewards
- authored enemy ultimate definitions across the full enemy roster
- enemy ultimate loading through the same shared skill catalog and battle payload path as heroes
- later encounters where enemies cast distinct frontline, burst, volley, and blast skills
- a dedicated player-facing settings screen
- persisted toggles for route transitions and shared button feedback
- audio preference sliders for master, music, and SFX mix targets
- player-facing save, reload, and reset actions built on the unified save service
- duplicate summons that bank merge copies before max ascension
- a roster-screen ascension action that consumes duplicate copies at level cap
- tier-based ascension rewards that grant stars and raise hero level caps
- unified save support for merge-copy banking and ascension tiers
- a quest board with milestone, daily, and weekly objective cadence
- recurring quest reset timers and grouped quest-board presentation
- unified save support for active recurring quest cycles
- a premium shard wallet plus banner-specific summon token balances
- recurring quest rewards that can now grant premium shards
- banner-token exchange flow that converts premium shards into selected-banner summon currency
- an authored live-event data set with point sources, milestone rewards, and a linked summon banner
- a playable Events route with event selection, milestone claiming, and banner handoff
- signal-driven event point gain from campaign clears, summons, AFK claims, and quest claims
- unified save support for event points and claimed milestone rewards
- authored event-exclusive stage variants with enemy lineups, unlock progression, and stage rewards
- live event stage launch from the Events route into the shared battle scene
- save-backed event-stage completion and unlock state
- authored per-stage event combat modifiers such as allied stat boosts, enemy stat surges, and starting-energy bonuses
- battle setup that applies event modifiers before the deterministic simulator begins
- modifier summaries surfaced on both the Events route and the Battle route
- battle restart and speed-toggle debug controls
- battle HP bars, KO handling, results, and combat log output
- JSON-authored hero and enemy definition files
- singleton/autoload scaffolding for app state, content loading, profile state, formation state, routing, theme access, and debug tools
- a reusable debug overlay
- baseline project documentation

## How To Run

1. Open the repository root in Godot 4.x.
2. Run the default main scene, or press Play Project.
3. The project boots into the app shell and opens the main menu automatically.

From the terminal, the local macOS Godot binary can be used:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

Phase 22 smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_22_smoke.gd
```

## Controls / Input

- Touch-first UI layout
- Mouse clicks are fully supported on desktop
- No keyboard input is required for the core Phase 1 flow
- The `DEV` button in the app shell opens the debug overlay

## Current Feature Status

- Phase 1: complete
- Phase 2: complete
- Phase 3: complete
- Phase 4: complete
- Phase 5: complete
- Phase 6: complete
- Phase 7: complete
- Phase 8: complete
- Phase 9: complete
- Phase 10: complete
- Phase 11: complete
- Phase 12: complete
- Phase 13: complete
- Phase 14: complete
- Phase 15: complete
- Phase 16: complete
- Phase 17: complete
- Phase 18: complete
- Phase 19: complete
- Phase 20: complete
- Phase 21: complete
- Phase 22: complete
- Beyond Phase 22: future expansion only

## Project Layout

- `project/scenes/`: Godot scenes grouped by feature area
- `project/scripts/`: runtime scripts grouped by responsibility
- `project/data/`: authored gameplay data containers and future balance content
- `project/assets/`: placeholder and future production assets
- `project/tests/`: future smoke and workflow tests
- `docs/`: architecture, testing, and per-phase notes
