# Phase 19

## What Was Built

- replaced gold-funded banner pulls with banner-specific summon currencies
- added a premium shard wallet and exchange flow for converting shards into selected-banner tokens
- extended the rewards domain so premium shards and banner tokens persist through the unified save file
- updated the summon screen to show shard balance, token balance, exchange actions, and token-funded pulls
- let recurring quests grant premium shards so the new wallet can be exercised through normal progression

## How To Run

1. Open the project in Godot 4.3 or newer.
2. Run the default main scene.
3. Open `Summon`, exchange premium shards into the selected banner's sigils, and perform pulls with those sigils.

Optional smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/bellevik/git/codex/afk_arena_clone --script res://project/tests/phase_19_smoke.gd
```

## How To Test

1. Use `DEV -> +5000 Resources`.
2. Open `Summon` and confirm premium shard and banner-token balances are visible.
3. Exchange shards with `Forge x1` or `Forge x10`.
4. Confirm the selected banner token balance rises and premium shards drop.
5. Perform banner pulls and confirm the banner tokens are spent instead of gold.
6. Save and reload through `Settings` and confirm the shard and token balances restore.

## Acceptance Checklist

- banners use dedicated summon currencies instead of gold
- premium shards can be exchanged into selected-banner summon tokens
- recurring quests can grant premium shards
- summon UI exposes both exchange and pull actions cleanly
- unified save/load restores the premium summon wallet

## Regression Check

- pity counters and pull history still work
- duplicate summons still feed merge-copy and ascension rules
- rewards, quests, and settings still load correctly
- the summon route still works inside the app shell

## Known Limitations

- there is still no storefront, purchase flow, or monetization-facing shop UI
- premium shards currently enter the economy through debug tools and recurring quests only
- banner currencies are still simple per-banner tokens without expiry or event rotation rules

## Next Goals

- add event-based limited-time content
- add banner/shop hooks for future monetization systems
- expand the summon economy with more acquisition sources and tuning controls
