# Data model (Aditya owns this)

**Being redesigned from scratch — nothing here is settled.** `data/library.sample.json`
shows placeholder shape only. When the real model is defined, this file becomes its
documentation and the Python tooling + GDScript loader get synced to it.

Two plumbing contracts survive the redesign unless Aditya says otherwise:

1. **Enrichment** (`scripts/enrich_songs.py`) fills exactly three lookup fields per
   song — `previewUrl`, `artworkUrl`, `appleTrackId` — and never touches authored data.
2. **Audio pipeline** (`scripts/fetch_previews.py`) maps `songs[].id` →
   `game/assets/audio/previews/<id>.ogg`, which is what the in-game jukebox loads.

Open questions for the redesign (from the Godot pivot):

- What does a **room** know? (era ↔ room 1:1? room size/layout data-driven or hand-built
  per scene?)
- Where do **photos** live in the model — per era, per song, or their own collection?
- Gamification hooks — anything the model needs to carry (unlocks, collectibles, order)?
- Per-era **palette** — keep it in the data (nice for UI theming) or purely an art concern?
