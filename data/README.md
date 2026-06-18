# data/

- `library.sample.json` — the canonical shape (an object with `eras[]` and `songs[]`). **You own this.**
  Copy/rename to your real source and edit freely.
- `schema.json` — JSON Schema for validation (optional convenience).
- `library.json` — *generated* (gitignored). Output of `scripts/enrich_songs.py`, consumed by Unity.

The data file is an **object**, not a top-level array, because Unity's `JsonUtility` can't parse a
top-level array. Keep `eras` and `songs` as named arrays inside the root object.
