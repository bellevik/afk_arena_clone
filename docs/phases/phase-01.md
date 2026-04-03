# Phase 1: Project Foundation and App Shell

## What Was Built

- New Godot 4 project configured for portrait-first play at `1080x1920`
- Boot scene that hands off into the main app shell
- App shell with:
  - header
  - content host
  - bottom navigation
  - debug button
- Main menu screen
- Placeholder screens for:
  - Heroes
  - Campaign
  - Battle
  - Rewards
  - Settings
- Initial autoload structure:
  - `AppState`
  - `SceneRouter`
  - `ThemeManager`
  - `DebugTools`
- Reusable debug overlay with direct screen routing and session reset
- Baseline documentation and phase tracking

## How To Run

Open the repository root in Godot 4.x and run the project, or start it from the terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/bellevik/git/codex/afk_arena_clone
```

## How To Test

1. Launch the project and wait for the boot scene to transition.
2. Confirm the main menu opens.
3. Navigate to every placeholder screen from the bottom navigation.
4. Open the `DEV` menu and use direct screen jumps.
5. Use `Reset Nav` and confirm the main menu returns.
6. Resize the desktop window and confirm portrait framing remains consistent.
7. Optionally run the headless smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_01_smoke.gd
```

## Acceptance Checklist

- [x] Project launches cleanly
- [x] Main menu navigation works
- [x] Placeholder screens load without missing references
- [x] Portrait-first viewport and stretch settings are configured
- [x] Desktop preserves the same portrait play framing
- [x] Debug overlay opens and routes correctly

## Regression Check

Phase 1 is the foundation phase, so regression coverage is limited to:

- boot transition still reaches the app shell
- every routed screen can still be opened after using the debug overlay
- resetting navigation does not break subsequent screen changes

## Known Limitations

- Feature screens are intentionally placeholders
- No hero data, combat systems, persistence, or rewards exist yet
- No mobile export profile has been authored yet
- The theme is a placeholder styling pass, not final UX polish

## Next Phase Goals

Phase 2 should introduce the first real content layer:

- hero data model
- sample hero dataset
- hero roster screen
- hero detail panel
- data-driven loading path for roster content
