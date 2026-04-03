# Phase 2: Data Model and Hero Roster Screen

## What Was Built

- JSON-authored hero definition pipeline
- enemy definition foundation for later stage and battle content
- validated JSON-backed stat and taxonomy handling in the content loader
- `GameData` autoload for content loading and reload support
- `ProfileState` autoload for the default owned roster in session
- live `Heroes` route with:
  - owned hero list
  - selectable hero cards
  - detail panel
  - base stats and per-level growth display
  - ultimate metadata
  - source-file visibility for quick content verification
- sample content:
  - 8 heroes
  - 3 enemy prototypes

## How To Run

Open the repository root in Godot 4.3+ and run the project, or start it from the terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

## How To Test

1. Launch the project and open `Heroes`.
2. Select every hero card and verify the detail panel updates correctly.
3. Confirm the roster summary shows hero and enemy content counts.
4. Edit or add a hero JSON file under `project/data/heroes/`.
5. Press `Reload Data`.
6. Confirm the roster updates without changing the UI scene code.
7. Optionally run the headless smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_02_smoke.gd
```

## Acceptance Checklist

- [x] Hero data loads from authored files
- [x] The Heroes route renders a real roster screen
- [x] Selecting a hero updates the detail panel
- [x] Data is not hardcoded into the UI scene
- [x] Adding a new hero data file is straightforward
- [x] Enemy definition groundwork exists for later phases

## Regression Check

- Boot still transitions into the app shell
- Main menu and non-hero placeholder routes still open
- Debug overlay still opens, cycles screens, and resets navigation
- Portrait-first framing remains intact

## Known Limitations

- Owned heroes are auto-derived from the catalog until save data exists
- Hero portraits are glyph-and-color placeholders only
- There is no formation assignment or battle usage yet
- Enemy definitions are loaded but not rendered anywhere in Phase 2

## Next Phase Goals

Phase 3 should add team formation:

- five-slot formation data
- assign/remove hero flow
- duplicate-prevention rules
- team power calculation
- session persistence for the active formation
