# Shardfall Legends

Shardfall Legends is an original Godot 4 prototype for a mobile-first idle hero battler inspired by the broad genre conventions of collection RPG auto-battlers. The project is being built in strict phases, with each phase leaving the game runnable and manually testable.

## Current Scope

Phase 4 currently delivers:

- portrait-first Godot project configuration
- boot scene and app shell
- main menu
- a data-driven hero roster screen with detail panel
- a five-slot formation screen with session assignment state
- a deterministic auto-battle test scene driven by the active formation
- authored battle encounter data and enemy team loading
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

Phase 4 smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_04_smoke.gd
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
- Phase 5 and beyond: not started in code

## Project Layout

- `project/scenes/`: Godot scenes grouped by feature area
- `project/scripts/`: runtime scripts grouped by responsibility
- `project/data/`: authored gameplay data containers and future balance content
- `project/assets/`: placeholder and future production assets
- `project/tests/`: future smoke and workflow tests
- `docs/`: architecture, testing, and per-phase notes
