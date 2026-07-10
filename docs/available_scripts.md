# Available scripts

Everything in `scripts/`. Run them from the repo root unless a snippet says otherwise.

```bash
pip install -r scripts/requirements.txt   # Pillow; the data scripts are stdlib-only
```

Two rules hold across all of them:

- **Hand-drawn art is never overwritten by default.** Both art scripts refuse to clobber
  a file a human has touched, and both take `--force` to do it anyway. Commit first —
  `--force` is not undoable, and a PNG that was never committed is not recoverable.
- **Source art is never written.** `dog_side.png`, `dog_down.png` and the player sprites
  are inputs. Nothing generates them.

| Script | Owns | Safe by default |
|---|---|---|
| `derive_dog_frames.py` | the dog's back view, walk strips, sit poses, templates | yes |
| `make_placeholder_art.py` | graybox tiles, player, Libresprite templates | yes |
| `enrich_songs.py` | `previewUrl` / `artworkUrl` / `appleTrackId` in the library JSON | yes |
| `fetch_previews.py` | `game/assets/audio/previews/<songId>.ogg` | n/a (outputs gitignored) |

---

## derive_dog_frames.py

Builds the rest of the dog out of the two idles Aditya draws by hand, by relocating his
own pixels — so the palette and style stay his. Re-run it whenever you redraw
`dog_side.png` or `dog_down.png`.

**Reads** `game/assets/sprites/dog_side.png` (faces LEFT) and `dog_down.png`. Never writes
either.

**Writes**

```
game/assets/sprites/dog_up.png          32x32   face erased, tail nub added
game/assets/sprites/dog_side_walk.png   128x32  4 frames
game/assets/sprites/dog_down_walk.png   128x32
game/assets/sprites/dog_up_walk.png     128x32
game/assets/sprites/dog_sit_side.png    32x32   starting point, meant to be redrawn
game/assets/sprites/dog_sit_down.png    32x32   "
game/assets/sprites/dog_sit_up.png      32x32   "
art/templates/dog_sit_{side,down,up}_template.png
art/templates/dog_palette.png           the dog's colors, one pixel each
```

It finds the legs itself: the hip is the first row below which the silhouette splits into
two column runs. Side view strides the legs in opposition; the front and back views lift
one paw per step frame. The body bobs 1px on the passing frames, with the legs stretched a
row so the paws stay planted on row 31. Frame order is step-A → passing → step-B → passing.

The **sit poses are starting points, not finished art** — a folded hind leg isn't something
you get by relocating pixels. Redraw them over the matching `dog_sit_*_template.png`, which
carries the bottom-center anchor, the row-31 ground line, the detected hip row, and a 28%
ghost of the idle, so the sit lines up with the idle it cuts to. `dog_palette.png` imports
straight into Libresprite as a palette.

**Not overwriting your work:** before writing, each output is compared pixel-for-pixel
against the file already on disk. A file the script generated round-trips exactly, so any
difference means you edited it — those are skipped and listed in a summary. The comparison
is on pixels, not bytes, because Libresprite and Pillow encode the same image to different
PNGs.

```bash
python scripts/derive_dog_frames.py                # skips anything you've hand-edited
python scripts/derive_dog_frames.py --only sits    # or: --only frames
python scripts/derive_dog_frames.py --force        # overwrite hand-edits. commit first.
```

## make_placeholder_art.py

Graybox art to build against before the real art exists, plus the Libresprite templates.
Placeholders are drop-in replaceable: same filename, same size, zero code changes.

**Writes** the floor/wall tiles, the three player sprites, and
`art/templates/{tile_template_128x64, grid_guide_1280x640, palette_deetslife,
dog_template_32x32, dog_walk_strip_128x32, dog_scale_reference}.png`.

It no longer generates any dog sprite — those are hand-drawn or derived from hand-drawn
art. It still makes the dog *templates*: `dog_template_32x32.png` (single cell) and
`dog_walk_strip_128x32.png` (the four walk cells). `dog_scale_reference.png` puts the
player and the dog on one floor tile so proportions can be judged in context.

Existing files are skipped, so re-running is safe.

```bash
python scripts/make_placeholder_art.py
python scripts/make_placeholder_art.py --force     # regenerates graybox over hand art
```

## enrich_songs.py

Fills exactly three lookup fields per song — `previewUrl`, `artworkUrl`, `appleTrackId` —
from the public iTunes Search API (no auth), matching on `"<title> <artist>"`. It touches
nothing else: Aditya owns the data model, and this adapts to it. Fields already set are
left alone unless `--force`. Lookups cache to `scripts/.cache_itunes.json` (gitignored).

```bash
python scripts/enrich_songs.py data/library.sample.json -o data/library.json
python scripts/enrich_songs.py data/library.json --in-place --force
```

## fetch_previews.py

Downloads each song's 30-second preview and converts it to Ogg Vorbis at
`game/assets/audio/previews/<songId>.ogg`, the path the in-game jukebox loads. The
conversion is not optional: Apple serves AAC/`.m4a` and **Godot cannot decode it**.

Only ever 30-second previews — never full tracks. Full-track listening happens off-game,
where the jukebox opens Apple Music via `OS.shell_open()`.

Run `enrich_songs.py` first so songs have a `previewUrl`. Requires **ffmpeg** on PATH
(`winget install Gyan.FFmpeg`, `brew install ffmpeg`). Raw downloads cache to
`scripts/.cache_previews/`; both that and the `.ogg` outputs are gitignored, so regenerate
them any time from `data/library.json`.

```bash
python scripts/fetch_previews.py data/library.json
python scripts/fetch_previews.py data/library.json --force   # re-fetch everything
```
