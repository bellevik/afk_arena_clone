# Phase 16

## What Was Built

- replaced the placeholder settings route with a real player-facing settings screen
- added `SettingsState` for persisted interface and audio preferences
- wired route transitions and shared button feedback to respect settings at runtime
- added player-facing save, reload, and reset actions on top of the unified save service
- extended the unified save payload to include settings data

## How To Run

1. Open the project in Godot 4.3 or newer.
2. Run the default main scene.
3. Open `Settings` from the home screen or bottom navigation bar.

Optional smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_16_smoke.gd
```

## How To Test

1. Open `Settings`.
2. Toggle route transitions off and confirm routed screen changes stop fading.
3. Toggle button feedback off and confirm buttons stop scaling and dimming on press.
4. Adjust the master, music, and SFX sliders and confirm the displayed percentages update immediately.
5. Press `Save Now`, change the settings again, then press `Reload Save` and confirm the saved values restore.
6. Press `Reset Save` twice and confirm the save resets to authored defaults and the app returns to `Home`.

## Acceptance Checklist

- the `Settings` route loads a real screen instead of the placeholder
- interface toggles update runtime behavior immediately
- settings persist through the unified save file
- player-facing save, reload, and reset actions work without using the debug overlay
- older prototype flows remain playable after settings changes and save reloads

## Regression Check

- battle, campaign, summon, and quest routes still load correctly
- unified save still restores roster, rewards, formation, and inventory state
- the debug overlay still opens and works independently of the settings screen
- portrait-first shell framing remains unchanged

## Known Limitations

- only the master volume is currently applied to a real audio bus; music and SFX are stored for future dedicated bus routing
- settings do not yet expose display-quality or accessibility options
- save management is now player-facing, but export/platform-specific preferences are still minimal

## Next Goals

- evolve star rank into real ascension and merge rules
- add recurring quest cadence on top of the milestone quest board
- expand settings with more player-facing options once audio and accessibility systems deepen
