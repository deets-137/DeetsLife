# Pixel art guide (Libresprite → Godot)

How to hand-draw DeetsLife's world. Technique only — every style decision is Aditya's.

## The grid rules (the only hard constraints)

- **Floor tiles are 128×64** — a 2:1 isometric diamond. Draw inside
  `art/templates/tile_template_128x64.png`.
- **The 2:1 line rule:** every diamond edge steps **2 pixels across for every 1 pixel
  up/down**. Freehand lines at other ratios look jagged in iso — stick to 2:1 for
  anything that follows the floor.
- **Walls are 64×112**: an 80px-tall face whose bottom edge follows one top edge of the
  floor diamond (so the base slopes 2:1 across 64px = 32px of rise). Match any
  `game/assets/rooms/<room>/wall_nw.png` / `wall_ne.png` exactly and new walls drop in.
- **A character is a folder**: `game/assets/sprites/<name>/` (`deets/`, `happy/`,
  `lucky/`), with PNGs named exactly after the animation they become — `idle_down.png`,
  `walk_side.png`, `sit_up.png`. The game builds animations from whatever files exist
  (`scripts/character_sprites.gd`), so a new character = a new folder, zero code, and a
  sparse rig (an NPC who only sits) is fine. `.ase` working files live in the folder too.
- **New characters need only the idle poses drawn** — walk strips and sits derive from
  a finished reference rig (see § Deriving a character rig below).
- **Deets is 32×64**, feet at the bottom-center. Three facings: `idle_down`
  (toward camera), `idle_up` (away), `idle_side` (LEFT — the game mirrors it for
  right). Keep the caricature's feet in the bottom ~4 rows so it sits on tiles correctly.
- **Walk cycles are horizontal strips**: `walk_down.png`, `walk_up.png`,
  `walk_side.png` — each frame exactly the idle's size, laid side by side (4 frames of
  32×64 = 128×64). Frame order is step-A → passing → step-B → passing. Keep the body from
  drifting sideways between frames or the walk reads as sliding; flip through the
  Libresprite timeline to check. In Libresprite: draw the frames in the timeline, then
  *File → Export Sprite Sheet* as a **horizontal strip**.
- **Happy is 32×32**, paws on the bottom row, bottom-center anchored — same three
  idle facings, plus three **sit poses** (`sit_down`, `sit_up`, `sit_side`) shown when
  the dog has been standing still for 0.7s, and three walk strips (4 frames of 32×32 =
  128×32, same step-A → passing → step-B → passing order). Nine PNGs total.
  All nine are **hand-drawn and final.**
  - Draw over `art/templates/dog_template_32x32.png` (center line + feet zone) and
    `art/templates/dog_walk_strip_128x32.png` (the 4 cells). The sit poses have their own
    templates — `art/templates/dog_sit_{side,down,up}_template.png` — each carrying the
    bottom-center anchor, the row-31 ground line, the hip row, and a faded ghost of the
    matching idle, so a sit lines up with the idle it cuts to.
  - `art/templates/dog_scale_reference.png` puts the player and the dog on one floor
    tile so you can judge proportions in context — the poodle stands about knee-high.
  - `art/templates/dog_palette.png` is the dog's exact colors, one pixel each. Open it and
    *Palette → Create palette from current sprite* to draw in-palette.
  - **If you redraw Happy's `idle_side.png` or `idle_down.png`, restore the deriver
    first** (note: it predates the per-character folders — it expects the old
    `sprites/dog_*.png` names, so update its paths or copy files through):

    ```bash
    git checkout cff5a68 -- scripts/
    python scripts/derive_dog_frames.py     # never writes the side/down idles
    ```

    `derive_dog_frames.py` rebuilds the up idle and all three walk strips out of those two
    idles by moving your own pixels, so the palette and style stay yours. It finds the legs
    on its own (the hip is the first row below which the silhouette splits into two column
    runs), strides them in opposition for the side view, lifts one paw per step for the
    front/back views, and bobs the body 1px on the passing frames — stretching the legs a
    row so the paws stay planted on row 31. It skips any output you've hand-edited, and
    names them, unless you pass `--force`.

    **Commit your art before running it.** An uncommitted PNG it overwrites is gone.

- **Props** (jukebox, benches, plants…): any size, but the *footprint* must read as one
  or more floor diamonds, and the sprite's bottom-center is its anchor (Y-sorting sorts
  by the base, so a sprite whose base is baked too high will float).

## Per-room assets

Every room owns its art in `game/assets/rooms/<room>/` — `entry`, `room_a`, `room_b`,
`room_c`, `room_d`, `hall`. All graybox placeholders until you draw them:

- `floor_a.png` + `floor_b.png` (128×64 each) — laid in a checker pattern; export the
  same image twice for a plain un-checkered floor.
- `wall_nw.png` + `wall_ne.png` (64×112) — that room's walls. The hall has no
  `wall_ne` (its north end opens straight into room D).
- `art_*.png` (64×112, **optional**) — wall-hung pieces (framed art). Each file is an
  overlay aligned to **one wall tile's canvas**: same coordinates as that wall's
  texture, transparent everywhere except the piece — draw over a copy of the wall PNG
  to place it, keeping horizontal edges on the wall's 2:1 slope so it hangs parallel.
  Which file hangs on which tile is data in `WALL_ART` in `room.gd`. Room C has three
  graybox frames: `art_nw_left` (portrait), `art_nw_right` (landscape), `art_ne_mid`
  (portrait).
- `entry/mat.png` (128×64) — the welcome mat under the spawn tile.
- `door_nw.png` / `door_ne.png` (64×112, **optional**) — doorframe art. Doorways render
  as bare wall gaps until this file exists in the folder of the room that owns the wall
  (all four current doors are in the entry's walls, so: `entry/`). Leave the walkway
  transparent; the frame never blocks movement.

Same drop-in rule as everything else: overwrite a PNG keeping name + size, zero code
changes. Room shapes/positions live in `ROOMS` in `game/scripts/room.gd`.

## Props (`game/assets/props/`)

Furniture and objects, shared across rooms. Bottom-center anchored at the south corner
of their tile footprint, and — unlike tiles/walls — **canvas size is free**: the game
reads the texture size at load, so redraw at whatever dimensions the design wants
under the same filename.

The mahjong set (room C, graybox until drawn):

- `mahjong_table.png` — 1×1-tile footprint: the base diamond (128×64) fills the bottom
  of the canvas, everything above is the table. Placeholder is 128×96. The tabletop
  does NOT need readable mahjong tiles — the playable table view will be its own
  zoomed-in scene later, with its own full-res art.
- `mahjong_chair.png` — one stool, quarter-tile footprint (base diamond 64×32 at the
  canvas bottom). Placeholder is 64×48. Drawn once and reused for all four seats, so
  keep it rotationally symmetric; if it grows a directional back, flag it and it
  becomes `_down`/`_up`/`_side` variants like the player facings.

Colliders match the tile footprints exactly, sealing the table + stool cluster into one
solid group (smaller colliders left pockets the player could wedge into). They live in
`PROPS` in `room.gd` — art changes never touch them.

**Player sit poses:** sitting is wired (E near a stool; the game disables the stool's
collider and snaps the seated sprite onto it — the node anchors at the stool's south
corner for Y-sorting, and `SIT_LIFT` in `player.gd` raises the sprite onto the
cushion). Every
sitter faces the **center of the table**, so only **two diagonal poses** are drawn and
the game mirrors them for the right-hand seats — same convention as the side walk art
(draw facing LEFT):

- `sit_down.png` — seated ¾ view facing **down-left** (toward camera); mirrored for
  the seat whose table is down-right.
- `sit_up.png` — seated ¾ view facing **up-left** (away from camera); mirrored for
  up-right.

The current `deets/sit_down/up.png` are generated drafts still in the old straight-on
facings — placeholders until the diagonals are drawn (same filenames, drop-in). Seat
rigs have no `sit_side`. (Happy's `sit_*` poses are unrelated — his idle-sit stays
cardinal and is final.) New seatable characters get sit poses the same way: derive or
draw `sit_down/up.png` into their folder.

## Deriving a character rig

New characters don't need their animation drawn — only their **idle poses**. The
deriver transfers the new character's colors through a finished reference rig's
hand-drawn frames, so it never invents anatomy (that's what made the first
dog-deriver's output look off). Proven by `lucky/`: three recolored idles in, all six
walk/sit files out, tail correctly beige throughout.

1. Make `game/assets/sprites/<name>/` and draw `idle_down.png` (+ `idle_side.png`,
   `idle_up.png`) **over the reference's idles**, keeping the silhouette — recolor and
   redetail freely inside it. Facings you skip are skipped.
2. From `game/`, run:

   ```bash
   godot --headless --path . --script res://tools/derive_character.gd -- <name> [reference]
   ```

   The reference defaults to `happy`; use a human rig as reference for human
   characters once one has finished animations.
3. Touch up any derived PNG you dislike — **the tool never overwrites an existing
   file**, so edits (and your hand-drawn sources) are safe from regeneration. Delete a
   derived file to re-derive it.

Distinctly-colored moving parts (Happy's tail) are declared once per reference rig in
its `derive_hints.json` — part pixels only borrow colors from that part. If a new
reference rig gains such a part, add its rects there.

## Libresprite workflow

1. **New file** at the exact target size (e.g. 128×64 for a floor tile). Color mode RGBA.
2. **Import the palette:** open `art/templates/palette_deetslife.png`, then
   *Palette → Create palette from current sprite*. Or build your own per-era palette —
   16–32 colors per era is plenty; fewer colors = more cohesion.
3. **Draw over the template:** *File → Open* the tile template, draw on a new layer above
   it, delete/hide the template layer before export.
4. **Use the pencil tool, never the brush** — pixel art wants hard 1px edges, no
   anti-aliasing. Turn off any "smooth"/AA toggles.
5. **Sketch rooms** over `art/templates/grid_guide_1280x640.png` to plan layouts before
   committing to tiles.
6. **Save the working file** as `.ase` beside the PNG it produces — the palettes and dog
   sources live in `game/assets/sprites/` alongside their exports, since they're opened
   constantly. Both are tracked in git. **Export PNG** into `game/assets/rooms/<room>/` /
   `sprites/` / etc. Godot re-imports automatically next time the editor gets focus.

## Godot side (already configured — nothing to do)

- Texture filtering is set to **Nearest** project-wide, so pixels stay crisp. Never
  scale sprites by non-integer factors in-scene.
- Placeholder art is drop-in replaceable: **keep the same filename and size** and the
  game picks it up with zero code changes.
- Characters are `AnimatedSprite2D`s whose animations are built at load by
  `scripts/character_sprites.gd` from the character's folder — even the frame count is
  read from the strip width, so redrawing a strip with **any** frame count needs no
  code change. Deets walks at 7 fps; Happy at 9 — a bit quicker, since a small dog
  takes shorter steps (say the word and I'll retime either).
  `game/scripts/dog.gd` makes the dog trail the player along a breadcrumb path, so it
  follows where you actually walked rather than cutting corners.

## Photos in the world

Your Lightroom-graded photos go in `art/photos/` (Git LFS). Two display patterns, both
supported by the plumbing — mixing per-photo is fine:

- **Dithered into the room's palette** for full pixel-art cohesion (Libresprite:
  *Sprite → Color Mode → Indexed* with that palette, or use its dithering on import).
- **Crisp photo in a pixel-art frame** — the frame sprite has a transparent window; the
  game letterboxes the photo behind it, and walking up + pressing interact opens the
  full-resolution photo as an overlay.

## Regenerating the placeholders (if needed)

The generator was deleted once the art was final. The templates it made are committed in
`art/templates/`, so you rarely want it back — mostly only to restyle the graybox tiles.

```bash
git checkout cff5a68 -- scripts/
python scripts/make_placeholder_art.py   # tweak the color constants at the top first
```

**Existing files are never overwritten** — your hand-drawn art wins, and the script
prints what it skipped. To rebuild one placeholder, delete that file and re-run. To
rebuild everything (this *will* destroy hand-drawn art), pass `--force`. Commit first.
