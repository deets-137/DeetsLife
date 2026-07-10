# Pixel art guide (Libresprite → Godot)

How to hand-draw DeetsLife's world. Technique only — every style decision is Aditya's.

## The grid rules (the only hard constraints)

- **Floor tiles are 128×64** — a 2:1 isometric diamond. Draw inside
  `art/templates/tile_template_128x64.png`.
- **The 2:1 line rule:** every diamond edge steps **2 pixels across for every 1 pixel
  up/down**. Freehand lines at other ratios look jagged in iso — stick to 2:1 for
  anything that follows the floor.
- **Walls are 64×112**: an 80px-tall face whose bottom edge follows one top edge of the
  floor diamond (so the base slopes 2:1 across 64px = 32px of rise). Match
  `game/assets/tiles/wall_nw.png` / `wall_ne.png` exactly and new walls drop in.
- **The player is 32×64**, feet at the bottom-center. Three facings: `player_down`
  (toward camera), `player_up` (away), `player_side` (LEFT — the game mirrors it for
  right). Keep the caricature's feet in the bottom ~4 rows so it sits on tiles correctly.
  These three are the **idle/standing** poses.
- **Walk cycles are horizontal strips**: `player_down_walk.png`, `player_up_walk.png`,
  `player_side_walk.png` — each frame exactly 32×64, laid side by side (4 frames =
  128×64). Frame order is step-A → passing → step-B → passing. Keep the body from
  drifting sideways between frames or the walk reads as sliding; flip through the
  Libresprite timeline to check. In Libresprite: draw the frames in the timeline, then
  *File → Export Sprite Sheet* as a **horizontal strip**.
- **Props** (jukebox, benches, plants…): any size, but the *footprint* must read as one
  or more floor diamonds, and the sprite's bottom-center is its anchor (Y-sorting sorts
  by the base, so a sprite whose base is baked too high will float).

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
6. **Save the working file** as `.aseprite` into `art/src/` (tracked in git), and
   **export PNG** into `game/assets/tiles/` / `sprites/` / etc. Godot re-imports
   automatically next time the editor gets focus.

## Godot side (already configured — nothing to do)

- Texture filtering is set to **Nearest** project-wide, so pixels stay crisp. Never
  scale sprites by non-integer factors in-scene.
- Placeholder art is drop-in replaceable: **keep the same filename and size** and the
  game picks it up with zero code changes.
- The player is an `AnimatedSprite2D` with six animations — `idle_down/up/side` (the
  single-frame poses) and `walk_down/up/side` (the strips, sliced into 32×64 atlas
  regions in `game/scenes/player.tscn`), walking at 7 fps. Redrawing a strip with the
  **same frame count** needs no code change; changing the frame count means updating
  the atlas regions in `player.tscn` — flag it and I'll adjust.

## Photos in the world

Your Lightroom-graded photos go in `art/photos/` (Git LFS). Two display patterns, both
supported by the plumbing — mixing per-photo is fine:

- **Dithered into the era's palette** for full pixel-art cohesion (Libresprite:
  *Sprite → Color Mode → Indexed* with the era palette, or use its dithering on import).
- **Crisp photo in a pixel-art frame** — the frame sprite has a transparent window; the
  game letterboxes the photo behind it, and walking up + pressing interact opens the
  full-resolution photo as an overlay.

## Regenerating the placeholders

```bash
cd scripts
python make_placeholder_art.py   # tweak the color constants at the top first if you like
```
