# Architecture

## Goal

This prototype is being built as a modular Godot 4 project with clear separation between app flow, future gameplay systems, authored data, UI, and persistence. Phase 1 establishes the shell that later systems will plug into without rewriting the navigation or boot flow.

## System Layout

Current Phase 1 slices:

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
  Theme access and UI scene controllers.
- `project/scripts/debug/`
  Debug overlay state and developer shortcuts.

Planned future slices:

- `project/scripts/battle/` and `project/scenes/battle/`
  Real-time auto-battle simulation and presentation.
- `project/scripts/data/` and `project/data/`
  Hero, enemy, stage, balance, and item definitions.
- `project/scripts/save/`
  Persistence and save migration logic.
- `project/scripts/systems/`
  Higher-level gameplay services such as rewards and progression.

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

Planned next additions:

- skills and energy
- stage-based battle entry
- reward generation after results
- persistent battle-related progression flow

## Save Flow

Not implemented in Phase 1.

Planned direction:

- a dedicated save service in `project/scripts/save/`
- structured versioned save payload
- explicit restore points for profile, campaign, roster, formation, and reward timestamps
- graceful handling for missing or outdated fields
