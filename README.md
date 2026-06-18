# DeetsLife

Interactive 3D art project — a walkable, gamified museum of the music of my life, organized by era.
Jukeboxes and vinyl records are the interaction hubs; photos and other media layer in over time.
Ships as an interactive build and a recorded cinematic walkthrough.

- **Direction & art:** Aditya (style, layout, palette, data model, Apple Music integration).
- **Tech:** Blender (models) → Unity/URP + C# (experience) ← Lightroom (photos), Python (data tooling).

See [docs/BUILD_PLAN.md](docs/BUILD_PLAN.md) for the roadmap and [CLAUDE.md](CLAUDE.md) for working notes.

## Quick start (data tooling)

```bash
cd scripts
python -m venv .venv && . .venv/Scripts/activate   # Windows (Git Bash)
pip install -r requirements.txt                     # currently stdlib-only; here for future deps
python enrich_songs.py ../data/library.sample.json -o ../data/library.json
```
