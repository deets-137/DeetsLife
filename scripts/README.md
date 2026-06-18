# scripts/

Python data tooling. Stdlib-only for now — no install required (the venv/requirements are
there for when we add dependencies).

## enrich_songs.py

Fills `previewUrl`, `artworkUrl`, and `appleTrackId` for each song via the public iTunes
Search API (no auth). Never overwrites your authored fields unless `--force`. Caches lookups
in `.cache_itunes.json` (gitignored).

```bash
# from scripts/
python enrich_songs.py ../data/library.sample.json -o ../data/library.json
python enrich_songs.py ../data/library.json --in-place --force   # refresh everything
```

When you bring your real Apple Music export, you have richer/authoritative IDs — we can swap
this lookup for a direct MusicKit/Apple Music API path. The contract (fill those 3 fields)
stays the same so the C# loader doesn't care which source produced them.
