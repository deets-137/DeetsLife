# scripts/

Python data + asset tooling. Stdlib-only except Pillow (for the art generator) —
`pip install pillow` if you don't have it.

## enrich_songs.py

Fills `previewUrl`, `artworkUrl`, and `appleTrackId` for each song via the public iTunes
Search API (no auth). Never overwrites your authored fields unless `--force`. Caches
lookups in `.cache_itunes.json` (gitignored).

```bash
python enrich_songs.py ../data/library.sample.json -o ../data/library.json
```

## fetch_previews.py

Downloads each song's 30s preview and converts it to Ogg Vorbis (Godot can't decode
AAC/.m4a) at `game/assets/audio/previews/<songId>.ogg`. Requires **ffmpeg** on PATH
(`winget install Gyan.FFmpeg` / `brew install ffmpeg`). Raw downloads are cached in
`.cache_previews/` (gitignored); outputs are gitignored too — regenerate anytime.

```bash
python fetch_previews.py ../data/library.json
```

## make_placeholder_art.py

Regenerates the graybox pixel art (`game/assets/`) and the Libresprite templates
(`art/templates/`). Tweak the color constants at the top and re-run to restyle the
graybox. Aditya's hand-drawn art replaces these files 1:1 (same name + size).

```bash
python make_placeholder_art.py
```
