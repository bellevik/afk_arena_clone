# Phase 21 - Event Stage Variants

## What Was Built

Phase 21 expands the live-event slice beyond milestone rewards by adding playable event-exclusive stages.

Implemented in this phase:

- authored event-stage definitions embedded in the live-event data file
- event-stage unlock and clear tracking inside `EventState`
- event-stage launch from the `Events` route into the shared battle screen
- event-stage battle rewards through the shared rewards pipeline
- save/load support for event-stage progression and last event battle result

## How To Run

1. Open the project in Godot 4.x.
2. Run the default main scene.
3. Open `Events` from the home screen or debug menu.

## How To Test

1. Select the active event.
2. Confirm the first event stage is unlocked.
3. Launch the first event stage and win the battle.
4. Return to `Events` and confirm the stage is marked cleared and the next stage unlocks.
5. Confirm balances increase from the event-stage reward.
6. Save, reload, and verify event-stage progress persists.

## Known Limitations

- The event system still has one authored event at a time.
- Event stages currently reuse the shared battle rules without temporary modifiers or special objectives.
- Banner monetization hooks still do not exist.

## Next Phase Goals

- add temporary event modifiers or event-stage mutators
- add banner-specific monetization or storefront hooks
