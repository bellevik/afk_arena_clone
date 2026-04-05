# Phase 22 - Event Combat Modifiers

## What Was Built

Phase 22 adds temporary combat mutators to live-event stages without branching the battle system into a separate event-only ruleset.

Implemented in this phase:

- authored per-stage event modifier data inside `live_events.json`
- normalized modifier parsing in `GameData`
- event-stage pending battle definitions that now carry modifier payloads
- battle-builder support for stage-specific stat scaling and starting-energy bonuses
- simulator support for modifier-driven starting energy
- event-screen and battle-screen summaries that explain active stage modifiers

## How To Run

1. Open the project in Godot 4.x.
2. Run the default main scene.
3. Open `Events` from the home screen or debug menu.

## How To Test

1. Select the active event and choose `Cinder Gate`.
2. Confirm the selected-stage panel lists temporary modifiers.
3. Launch the stage.
4. Confirm the battle screen also lists the same active stage modifiers.
5. Let the battle run and verify allied units begin with visible starting energy on stages that grant it.
6. Clear the stage and confirm progression, rewards, and save flow still work.

## Known Limitations

- The modifier vocabulary is intentionally small in this phase: stat scaling and starting energy.
- Event stages still use the shared win condition and battle timer rules.
- The event system still ships with one authored live event at a time.

## Next Phase Goals

- add event-exclusive combat objectives or alternate victory conditions
- support multiple simultaneous live events or rotating event themes
