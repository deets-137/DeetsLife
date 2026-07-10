# DeetsLife

Interactive isometric pixel-art game — a walkable, gamified museum of the music of my
life, organized by era. Jukeboxes are the interaction hubs; photos and other media
layer in over time. Ships as desktop builds (Windows + macOS).

- **Direction & art:** Aditya (style, rooms, palette, caricature sprite, data model).
- **Tech:** Godot 4 + GDScript (game) ← Libresprite (pixel art), Lightroom (photos),
  Python (data tooling), iTunes Search API (30s previews + artwork).

See [docs/BUILD_PLAN.md](docs/BUILD_PLAN.md) for the roadmap,
[docs/PIXEL_ART_GUIDE.md](docs/PIXEL_ART_GUIDE.md) for the art workflow, and
[CLAUDE.md](CLAUDE.md) for working notes.

## Quick start

**Game:** install [Godot 4.4+](https://godotengine.org/download) (standard, not .NET),
open the `game/` folder, hit F5. WASD/arrows to walk.

**Data tooling:**

```bash
cd scripts
python enrich_songs.py ../data/library.sample.json -o ../data/library.json
python fetch_previews.py ../data/library.json    # needs ffmpeg on PATH
```

**Placeholder art** (regenerate after tweaking colors):

```bash
python scripts/make_placeholder_art.py
```
