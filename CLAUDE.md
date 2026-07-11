# DeetsLife

An interactive isometric pixel-art game, built in **Godot 4**, shipping as desktop builds
(Windows + macOS), with a possible web build later.

> **The vision is being reworked.** It began as a walkable museum of the music of my life,
> organized by eras, with jukeboxes as the interaction hubs. **Music and the audio pipeline
> are out of scope for now.** Aditya defines the new direction — do not infer it, and do
> not build toward the old one. What holds regardless: isometric pixel art, hand-drawn by
> Aditya, in a walkable Godot world with the player and the dog.

## Roles (important)

- **I (Aditya) own all art direction and design.** Room design, palettes, the caricature
  player sprite, prop style, mood, layout, the data model — and now the direction of the
  game itself. Do not propose visual/style decisions unless I ask. Do not invent a data
  schema and impose it — I define it; code adapts to it. I hand-draw the art in
  Libresprite (see docs/PIXEL_ART_GUIDE.md).
- **Claude owns the technical plumbing.** Godot scenes/GDScript, exports, Git/LFS
  hygiene, debugging. When a task is code-related, expect to write it.
- **The build loop that works:** Aditya directs the change (layout, dimensions, what
  goes where) → Claude chats it through first, flagging geometry/tech consequences and
  drawing a plan diagram when it's spatial → Claude builds the graybox plumbing and
  verifies it **headless** (script-driven Godot tests + screenshots; never take over
  Aditya's screen or keyboard) → Aditya playtests, then hand-draws and polishes over it.
  Every placeholder is wired for drop-in replacement so his art lands with zero code
  changes.

When unsure whether something is an "art" call or a "tech" call, ask before deciding.

## ▶ NEXT SESSION STARTS HERE

**Aditya is reworking the vision.** Music is out of scope; the data model is on hold.
Don't plan around jukeboxes, eras, previews, or `library.json` until he says otherwise.
`data/library.sample.json` and `docs/DATA_MODEL.md` are dormant scaffolding from the old
direction — do NOT treat them as settled or build against them.

The new direction is emerging through concrete build requests rather than a written
spec — the multi-room map came first. Aditya directs each step; don't assume a subject
or theme beyond what's actually been built. Two directions he has voiced (chatted
through, not yet built): **simple online multiplayer** — direct P2P, one Discord
friend hosts, others join, ≤16 players, custom characters shipped as PNG folders on
join — and a **wardrobe / character creator** where players hand-draw their character
from a template and the game derives the animations (the deriver tool below is the
proven seed of that).

What's actually done and working: the multi-room graybox map (`main.tscn`) — a 5×3
entry room (spawn + welcome mat at its bottom-right) with three doors on its NE wall
into two 5×5 rooms (A, B) and a 1×5 hall to a back 5×5 room (D), plus a door on the
NW wall into a 3×3 room (C, flush with A); the walkable player **Deets** (Aditya's
caricature; real collision: segment colliders along walls/floor edges +
move_and_slide, camera follows); and his dog **Happy**, who trails the player along a
breadcrumb path and sits when idle. Deets' and Happy's art is hand-drawn and final.
Characters are folders (`assets/sprites/<name>/`, PNGs named after their animation),
built at load by `scripts/character_sprites.gd`; new rigs need only idle poses drawn —
`tools/derive_character.gd` derives walk/sit frames through a reference rig's
animation and **never overwrites an existing file**. `lucky/` (cream dog, beige tail,
derived from happy) is the proof-of-concept.
Room floors/walls are graybox, one asset folder per room in `game/assets/rooms/<room>/`
for Aditya to draw over (specs in docs/PIXEL_ART_GUIDE.md § Per-room assets). Room
geometry lives in `ROOMS` in `game/scripts/room.gd`.

Room C is becoming the mahjong corner: a 1×1 table + four quarter-tile stools
(`PROPS` in room.gd, graybox art in `game/assets/props/`, plan in BUILD_PLAN
§ Milestone 0.6). Prop colliders match footprints exactly — smaller ones left corner
pockets the player could wedge into (fixed + verified headless). Three wall-hung
graybox frames hang in C via `WALL_ART` in room.gd (64×112 per-wall-tile overlays,
contract in PIXEL_ART_GUIDE § Per-room assets), awaiting Aditya's art. Sitting is
wired: E (interact) near a free stool snaps the player onto it facing the **center
of the table** (stool collider off while seated; E or movement stands back up).
Seats are data — `seat_face` in `PROPS`; all four resolve to diagonals from two
drawn poses + mirror (`sit_down` = down-left, `sit_up` = up-left, art faces LEFT —
contract in PIXEL_ART_GUIDE § Props). Deets' sit PNGs are straight-on generated
drafts standing in until Aditya draws the diagonals. The mahjong game itself (zoomed tabletop scene + 4 buttons) is
designed-but-not-started; agreed order: multiplayer walk-together slice next, then
the mahjong game built multiplayer-native.

### The deleted tooling (restore if needed)

`scripts/` was removed once the art was final. Everything is recoverable:

```bash
git checkout cff5a68 -- scripts/     # the last commit that still had it
```

| Restore | If you need to |
|---|---|
| `derive_dog_frames.py` | redraw Happy's side/down idles — it's the only thing that rebuilds the up idle and the three walk strips from them (predates the `sprites/happy/` folder move; fix its paths when restoring) |
| `make_placeholder_art.py` | regenerate graybox tiles or the Libresprite templates in `art/templates/` (the template PNGs themselves are committed, so usually you don't) |
| `enrich_songs.py`, `fetch_previews.py` | bring music back — iTunes lookup and 30s-preview conversion |

## Tech stack

- **Godot 4.4+** — the game. 2D isometric (128×64 tiles), GDScript, desktop exports.
  The project lives in `game/`; open that folder in the Godot editor.
- **Libresprite** — Aditya hand-draws all pixel art. `.ase` working files sit beside the
  PNGs they produce, in `game/assets/sprites/`. Templates in `art/templates/`.
- **Lightroom** — photo processing and grading; exports land in `art/photos/`.

## Key technical constraints (don't violate without flagging)

- **Isometric grid:** floor tiles are 128×64 (2:1). Tile↔world math lives in
  `game/scripts/room.gd` (`tile_to_world` / `world_to_tile`) — keep it the single
  source of truth.
- **Pixel-art rendering:** texture filter is Nearest project-wide; integer scaling
  only; sprites anchor at bottom-center for Y-sorting.
- **Collision is real physics:** thin `SegmentShape2D` colliders along every wall and
  floor-boundary edge (built at runtime in `room.gd::_build_collision`), player is a
  `CharacterBody2D` feet-box using `move_and_slide`. Don't reintroduce point-based
  position clamping — it clips.
- **Wall Y-sorting:** each wall tile renders as 4 vertical 16px strips
  (`WALL_STRIPS`), each sorted at its own point on the sloping base line. One sprite
  per wall tile mis-sorts near the ends of the slope. Wall art stays 64×112 and slices
  automatically.
- **Art is drop-in replaceable:** same filename + size in `game/assets/` = zero code
  changes. Don't rename asset files casually.
- **Version control:** Git + **Git LFS** for photos/audio/video only (see
  `.gitattributes`); pixel-art PNGs stay in plain git. Godot's `game/.godot/` cache is
  never committed. **Commit art before running anything that writes to `game/assets/`** —
  an uncommitted PNG that gets overwritten is gone.

## Working principle: vertical slice first

Do NOT scale before one full interaction loop works end to end. The old slice — walk to a
jukebox, hear a 30s preview, see a photo — is void now that music is out of scope, and
**the new one is Aditya's to define.** Until he does, there is no milestone to build
toward; ask rather than pick one.

## Layout

```
DeetsLife/
  CLAUDE.md              # this file
  README.md
  docs/
    BUILD_PLAN.md        # the roadmap (music milestones deferred)
    DATA_MODEL.md        # dormant: from the music direction
    PIXEL_ART_GUIDE.md   # Libresprite workflow + tile/sprite specs
  data/                  # dormant: from the music direction
    library.sample.json
  art/
    src/                 # empty; .ase files now live beside their PNGs
    templates/           # tile template, grid guide, palette strip, dog templates
    photos/              # Lightroom exports (Git LFS)
  game/                  # the Godot 4 project — open this folder in Godot
    project.godot
    scenes/              # main.tscn (graybox multi-room map), player.tscn, dog.tscn
    scripts/             # room.gd (iso math + map build + walkability), player.gd
                         # (movement), dog.gd (breadcrumb follower),
                         # character_sprites.gd (folder → SpriteFrames)
    tools/               # derive_character.gd — headless deriver: idle poses in,
                         # walk/sit frames out via a reference rig; never overwrites
    assets/
      rooms/             # per-room floors/walls/doorframes (entry, room_a–d, hall),
                         # graybox awaiting Aditya's art; entry/ also has mat.png,
                         # room_c/ the three wall-art frames
      props/             # furniture (mahjong table + stool), hand-drawn
      sprites/           # one folder per character (deets/, happy/, lucky/): PNGs
                         # named after their animation (idle_down, walk_side, sit_up)
                         # + .ase files; animations built by character_sprites.gd;
                         # happy/derive_hints.json marks the tail for the deriver
      audio/previews/    # empty; generated oggs were gitignored

  (no scripts/ — deleted once the art was final; restore from cff5a68 if needed)
```

## Conventions

- GDScript: tabs, typed where reasonable, `snake_case`; scene scripts stay small and
  single-purpose.
- Data files are JSON with an object root; Godot's `JSON.parse_string` handles it
  natively. (No live data files right now — the old `{ meta, eras, songs }` shape went
  dormant with the music direction.)
- Input actions (`move_*`, `interact`) are defined in `project.godot` — use actions,
  never raw keycodes, in gameplay code.
