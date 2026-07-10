# Data model (Aditya owns this)

> ## ⚠ Dormant
>
> This described the data for the music-museum direction. **Music is out of scope and the
> vision is being reworked.** Nothing here is settled, and it may not survive at all — the
> new direction may need no data model.
>
> Don't build against this file, and don't sync code to it. Ask Aditya what the game is
> becoming first.

`data/library.sample.json` still shows the old placeholder shape (`{ meta, eras[],
songs[] }`). It's kept because throwing it away costs nothing to reverse and keeping it
records what the Godot loader was going to expect.

## What the old model was for

An era was a room. A room had songs. A song had a 30-second preview and cover artwork,
both looked up from the iTunes Search API rather than authored by hand.

Two plumbing contracts held it together. Both belonged to scripts that have since been
deleted (`git checkout cff5a68 -- scripts/` restores them):

1. **Enrichment** (`enrich_songs.py`) filled exactly three lookup fields per song —
   `previewUrl`, `artworkUrl`, `appleTrackId` — and never touched authored data.
2. **Audio pipeline** (`fetch_previews.py`) mapped `songs[].id` →
   `game/assets/audio/previews/<id>.ogg`, which is what the in-game jukebox loaded.

## Questions the rework has to answer anyway

These outlived the music direction — any subject the game lands on will face most of them:

- What does a **room** know? (Room size/layout data-driven, or hand-built per scene?)
- Where do **photos** live in the model — per room, per item, or their own collection?
- Gamification hooks — anything the model needs to carry (unlocks, collectibles, order)?
- Per-room **palette** — keep it in data (nice for UI theming) or purely an art concern?
