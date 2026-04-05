# Phase 20 - Live Event Foundation

## What Was Built

Phase 20 turns the old event hook into a playable limited-time event slice.

Implemented in this phase:

- authored live-event definitions with timing, point sources, milestone rewards, and a linked summon banner
- a new `EventState` autoload for active event selection, point gain, milestone claims, and persistence
- an `Events` route with event summary, point-source breakdown, reward-track claims, and linked-banner routing
- save/load support for event points and claimed milestone rewards
- debug support for granting event points during manual testing

## How To Run

1. Open the project in Godot 4.x.
2. Run the default main scene.
3. Open `Events` from the home screen or debug menu.

## How To Test

1. Confirm the active event appears with points, time label, and milestone list.
2. Clear a campaign stage and perform a summon pull.
3. Return to `Events` and verify point gain.
4. Claim the first milestone and confirm balances update.
5. Press `Open linked banner` and confirm the summon screen opens on the event-linked banner.
6. Save, reload, and confirm event points plus claimed milestones persist.

## Known Limitations

- The event system currently ships with one authored live event.
- Event content is a reward track only; it does not yet include event-exclusive stages or modifiers.
- There is still no storefront or purchase flow attached to banner or event content.

## Next Phase Goals

- add banner-specific monetization hooks or event-stage variants
- expand the event system beyond one active reward track
