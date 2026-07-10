# DeetsLife

An interactive isometric pixel-art game: a walkable museum of the music of my life,
organized by **eras**. Each room is an era; jukeboxes are the interaction hubs; photos
and other media layer in over time. Built in **Godot 4**, shipping as desktop builds
(Windows + macOS), with a possible web build later.

## Roles (important)

- **I (Aditya) own all art direction and design.** Room design, palettes, the caricature
  player sprite, jukebox style, mood, layout, the data model. Do not propose visual/style
  decisions unless I ask. Do not invent a data schema and impose it — I define it; code
  adapts to it. I hand-draw the art in Libresprite (see docs/PIXEL_ART_GUIDE.md).
- **Claude owns the technical plumbing.** Godot scenes/GDScript, Python data tooling,
  the preview-audio pipeline, exports, Git/LFS hygiene, debugging. When a task is
  code-related, expect to write it.

When unsure whether something is an "art" call or a "tech" call, ask before deciding.

## ▶ NEXT SESSION STARTS HERE

**Aditya is defining the data model.** `data/library.sample.json` and
`docs/DATA_MODEL.md` are PLACEHOLDER scaffolding — do NOT treat them as settled. Start
by having Aditya define the model; then sync `DATA_MODEL.md`, `enrich_songs.py`,
`fetch_previews.py`, and the GDScript loader to it. Two contracts worth preserving
unless he says otherwise:
1. **Enrichment** fills only `previewUrl` / `artworkUrl` / `appleTrackId`.
2. **Audio pipeline** maps `songs[].id` → `game/assets/audio/previews/<id>.ogg`.

## Tech stack

- **Godot 4.4+** — the game. 2D isometric (128×64 tiles), GDScript, desktop exports.
  The project lives in `game/`; open that folder in the Godot editor.
- **Libresprite** — Aditya hand-draws all pixel art. Working files in `art/src/`,
  exported PNGs into `game/assets/`. Templates + palette in `art/templates/`.
- **Lightroom** — photo processing and per-era grading; exports land in `art/photos/`.
- **Python** — data tooling in `scripts/` (iTunes enrichment, preview download+convert,
  placeholder art generation).

## Key technical constraints (don't violate without flagging)

- **Audio:** Apple/iTunes 30-second preview URLs only — never bundle full tracks.
  **Godot cannot decode AAC/.m4a**, so previews are converted to Ogg Vorbis by
  `scripts/fetch_previews.py` (requires ffmpeg). Converted oggs are gitignored;
  regenerate them from `data/library.json`. Full-track listening happens off-game:
  jukebox links open Apple Music / deets.solutions via `OS.shell_open()`.
- **Isometric grid:** floor tiles are 128×64 (2:1). Tile↔world math lives in
  `game/scripts/room.gd` (`tile_to_world` / `world_to_tile`) — keep it the single
  source of truth.
- **Pixel-art rendering:** texture filter is Nearest project-wide; integer scaling
  only; sprites anchor at bottom-center for Y-sorting.
- **Placeholder art is drop-in replaceable:** same filename + size in `game/assets/`
  = zero code changes. Don't rename asset files casually.
- **Version control:** Git + **Git LFS** for photos/audio/video only (see
  `.gitattributes`); pixel-art PNGs stay in plain git. Godot's `game/.godot/` cache is
  never committed.

## Working principle: vertical slice first

Do NOT scale before the full loop works once. Target the first milestone:
**one room → one jukebox → ~5 records → one photo on the wall → walk up → interact →
hear the 30s preview → see the photo.** Only after that loop runs do we add eras,
rooms, and polish.

## Layout

```
DeetsLife/
  CLAUDE.md              # this file
  README.md
  docs/
    BUILD_PLAN.md        # the step-by-step roadmap
    DATA_MODEL.md        # the data shape (Aditya owns this; code adapts to it)
    PIXEL_ART_GUIDE.md   # Libresprite workflow + tile/sprite specs
  data/
    library.sample.json  # placeholder shape: { meta, eras[], songs[] }
  scripts/
    enrich_songs.py      # fills previewUrl + artwork via iTunes Search API
    fetch_previews.py    # downloads previews, converts m4a→ogg for Godot (ffmpeg)
    make_placeholder_art.py  # regenerates the graybox art + templates
  art/
    src/                 # Libresprite working files (.aseprite)
    templates/           # tile template, grid guide, palette strip
    photos/              # Lightroom exports (Git LFS)
  game/                  # the Godot 4 project — open this folder in Godot
    project.godot
    scenes/              # main.tscn (graybox room), player.tscn
    scripts/             # room.gd (iso math + room build), player.gd (movement)
    assets/
      tiles/  sprites/   # exported pixel art (placeholders until Aditya's art)
      audio/previews/    # generated oggs (gitignored)
```

## Conventions

- GDScript: tabs, typed where reasonable, `snake_case`; scene scripts stay small and
  single-purpose.
- Data files are JSON with an object root (`{ meta, eras, songs }`); Godot's
  `JSON.parse_string` handles it natively.
- Input actions (`move_*`, `interact`) are defined in `project.godot` — use actions,
  never raw keycodes, in gameplay code.
