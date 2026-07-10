#!/usr/bin/env python3
"""
make_placeholder_art.py — generate the DeetsLife placeholder pixel art + Libresprite templates.

Outputs (all paths relative to the repo root):
    game/assets/tiles/floor_beige.png        128x64 isometric floor diamond
    game/assets/tiles/floor_beige_alt.png    slightly darker variant (checkerboard)
    game/assets/tiles/wall_nw.png            64x112 wall slab, top-left room edge
    game/assets/tiles/wall_ne.png            64x112 wall slab, top-right room edge
    game/assets/sprites/player_down.png      32x64 humanoid, facing camera
    game/assets/sprites/player_up.png        32x64 humanoid, facing away
    game/assets/sprites/player_side.png      32x64 humanoid, facing LEFT (flip_h for right)
    art/templates/tile_template_128x64.png   blank diamond outline to draw inside
    art/templates/grid_guide_1280x640.png    isometric grid to sketch rooms over
    art/templates/palette_deetslife.png      starter palette strip (importable in Libresprite)

All placeholder art is meant to be REPLACED by Aditya's hand-drawn work — same sizes,
same filenames, drop-in. Tweak the colors below and re-run if you want different graybox vibes.
"""

from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parent.parent
TILES = REPO / "game" / "assets" / "tiles"
SPRITES = REPO / "game" / "assets" / "sprites"
TEMPLATES = REPO / "art" / "templates"

TILE_W, TILE_H = 128, 64
WALL_H = 80  # wall face height above the tile edge

# ---- palette ----
BEIGE = (216, 200, 168, 255)
BEIGE_ALT = (206, 189, 154, 255)
BEIGE_EDGE = (178, 160, 126, 255)

GREEN_NW = (47, 107, 63, 255)   # top-left wall face (catches more light)
GREEN_NE = (38, 88, 52, 255)    # top-right wall face
GREEN_TOP = (72, 148, 92, 255)  # lit top edge of walls
GREEN_DARK = (26, 58, 36, 255)  # wall base shadow

HAIR = (58, 40, 28, 255)
SKIN = (232, 185, 144, 255)
EYE = (25, 20, 18, 255)
SHIRT = (62, 107, 140, 255)
SHIRT_DARK = (50, 88, 116, 255)
PANTS = (52, 48, 66, 255)
PANTS_DARK = (42, 38, 54, 255)
SHOE = (30, 27, 38, 255)

TRANSPARENT = (0, 0, 0, 0)


def diamond_rows(w=TILE_W, h=TILE_H):
    """Yield (y, x0, x1) inclusive pixel spans of a crisp 2:1 isometric diamond."""
    for y in range(h):
        i = y if y < h // 2 else h - 1 - y
        half = 2 * (i + 1)
        yield y, w // 2 - half, w // 2 + half - 1


def make_floor(fill, path):
    img = Image.new("RGBA", (TILE_W, TILE_H), TRANSPARENT)
    px = img.load()
    for y, x0, x1 in diamond_rows():
        for x in range(x0, x1 + 1):
            px[x, y] = BEIGE_EDGE if x < x0 + 2 or x > x1 - 2 else fill
    img.save(path)


def make_wall(nw, path):
    """64x112 slab. Bottom edge follows one top edge of the floor diamond (2:1 slope)."""
    img = Image.new("RGBA", (64, TILE_H // 2 + WALL_H), TRANSPARENT)
    px = img.load()
    face = GREEN_NW if nw else GREEN_NE
    for x in range(64):
        y_top = (63 - x) // 2 if nw else x // 2
        for y in range(y_top, y_top + WALL_H):
            if y < y_top + 4:
                px[x, y] = GREEN_TOP
            elif y >= y_top + WALL_H - 2:
                px[x, y] = GREEN_DARK
            else:
                px[x, y] = face
    img.save(path)


def _scale2x(img):
    return img.resize((img.width * 2, img.height * 2), Image.NEAREST)


def make_player_down(path):
    img = Image.new("RGBA", (16, 32), TRANSPARENT)
    d = ImageDraw.Draw(img)
    d.rectangle([4, 1, 11, 2], fill=HAIR)                        # hair top
    d.rectangle([5, 3, 10, 8], fill=SKIN)                        # face
    d.rectangle([5, 3, 10, 3], fill=HAIR)                        # fringe
    d.rectangle([4, 3, 4, 5], fill=HAIR)                         # hair sides
    d.rectangle([11, 3, 11, 5], fill=HAIR)
    d.point([(6, 6), (9, 6)], fill=EYE)                          # eyes
    d.rectangle([7, 9, 8, 9], fill=SKIN)                         # neck
    d.rectangle([4, 10, 11, 17], fill=SHIRT)                     # torso
    d.rectangle([3, 11, 3, 16], fill=SHIRT_DARK)                 # arms
    d.rectangle([12, 11, 12, 16], fill=SHIRT_DARK)
    d.point([(3, 17), (12, 17)], fill=SKIN)                      # hands
    d.rectangle([5, 18, 10, 19], fill=PANTS)                     # hips
    d.rectangle([5, 20, 6, 26], fill=PANTS)                      # legs
    d.rectangle([9, 20, 10, 26], fill=PANTS)
    d.rectangle([4, 27, 6, 28], fill=SHOE)                       # shoes
    d.rectangle([9, 27, 11, 28], fill=SHOE)
    _scale2x(img).save(path)


def make_player_up(path):
    img = Image.new("RGBA", (16, 32), TRANSPARENT)
    d = ImageDraw.Draw(img)
    d.rectangle([4, 1, 11, 8], fill=HAIR)                        # back of head
    d.rectangle([7, 9, 8, 9], fill=SKIN)                         # neck
    d.rectangle([4, 10, 11, 17], fill=SHIRT)
    d.rectangle([3, 11, 3, 16], fill=SHIRT_DARK)
    d.rectangle([12, 11, 12, 16], fill=SHIRT_DARK)
    d.point([(3, 17), (12, 17)], fill=SKIN)
    d.rectangle([5, 18, 10, 19], fill=PANTS)
    d.rectangle([5, 20, 6, 26], fill=PANTS)
    d.rectangle([9, 20, 10, 26], fill=PANTS)
    d.rectangle([4, 27, 6, 28], fill=SHOE)
    d.rectangle([9, 27, 11, 28], fill=SHOE)
    _scale2x(img).save(path)


def make_player_side(path):
    """Faces LEFT; the game flips it horizontally for right."""
    img = Image.new("RGBA", (16, 32), TRANSPARENT)
    d = ImageDraw.Draw(img)
    d.rectangle([5, 1, 11, 2], fill=HAIR)
    d.rectangle([10, 3, 11, 7], fill=HAIR)                       # back of head
    d.rectangle([5, 3, 9, 8], fill=SKIN)
    d.rectangle([5, 3, 9, 3], fill=HAIR)
    d.point([(6, 6)], fill=EYE)
    d.rectangle([7, 9, 8, 9], fill=SKIN)
    d.rectangle([5, 10, 10, 17], fill=SHIRT)
    d.rectangle([7, 11, 8, 16], fill=SHIRT_DARK)                 # near arm
    d.rectangle([7, 17, 8, 17], fill=SKIN)                       # hand
    d.rectangle([8, 18, 9, 26], fill=PANTS_DARK)                 # far leg
    d.rectangle([6, 18, 7, 26], fill=PANTS)                      # near leg
    d.rectangle([4, 27, 7, 28], fill=SHOE)                       # toe points left
    d.rectangle([8, 27, 9, 28], fill=SHOE)
    _scale2x(img).save(path)


def make_tile_template(path):
    """Blank diamond outline + faint center guides, to draw floor tiles inside."""
    img = Image.new("RGBA", (TILE_W, TILE_H), TRANSPARENT)
    px = img.load()
    outline = (40, 40, 48, 255)
    guide = (40, 40, 48, 60)
    for y, x0, x1 in diamond_rows():
        px[x0, y] = outline
        px[x0 + 1, y] = outline
        px[x1, y] = outline
        px[x1 - 1, y] = outline
        for x in (63, 64):
            if x0 < x < x1:
                px[x, y] = guide
        if y in (31, 32):
            for x in range(x0 + 2, x1 - 1):
                px[x, y] = guide
    img.save(path)


def make_grid_guide(path):
    """A sheet of staggered 128x64 diamonds to sketch room layouts over."""
    w, h = 1280, 640
    img = Image.new("RGBA", (w, h), (32, 32, 38, 255))
    px = img.load()
    line = (69, 69, 78, 255)
    for row in range(-1, h // 32 + 1):
        for col in range(-1, w // 128 + 1):
            ox = col * 128 + (row % 2) * 64
            oy = row * 32
            for y, x0, x1 in diamond_rows():
                yy = oy + y
                if 0 <= yy < h:
                    for x in (ox + x0, ox + x1):
                        if 0 <= x < w:
                            px[x, yy] = line
    # one filled reference tile near the center
    ox, oy = 5 * 128, 9 * 32
    for y, x0, x1 in diamond_rows():
        for x in range(x0 + 2, x1 - 1):
            px[ox + x, oy + y] = (216, 200, 168, 90)
    img.save(path)


def make_palette(path):
    """One 32px swatch per color — Libresprite can import a palette from this image."""
    colors = [BEIGE, BEIGE_ALT, BEIGE_EDGE, GREEN_TOP, GREEN_NW, GREEN_NE, GREEN_DARK,
              SKIN, HAIR, EYE, SHIRT, SHIRT_DARK, PANTS, PANTS_DARK, SHOE]
    img = Image.new("RGBA", (32 * len(colors), 32), TRANSPARENT)
    d = ImageDraw.Draw(img)
    for i, c in enumerate(colors):
        d.rectangle([i * 32, 0, i * 32 + 31, 31], fill=c)
    img.save(path)


def main():
    for folder in (TILES, SPRITES, TEMPLATES):
        folder.mkdir(parents=True, exist_ok=True)

    make_floor(BEIGE, TILES / "floor_beige.png")
    make_floor(BEIGE_ALT, TILES / "floor_beige_alt.png")
    make_wall(True, TILES / "wall_nw.png")
    make_wall(False, TILES / "wall_ne.png")
    make_player_down(SPRITES / "player_down.png")
    make_player_up(SPRITES / "player_up.png")
    make_player_side(SPRITES / "player_side.png")
    make_tile_template(TEMPLATES / "tile_template_128x64.png")
    make_grid_guide(TEMPLATES / "grid_guide_1280x640.png")
    make_palette(TEMPLATES / "palette_deetslife.png")
    print("Placeholder art written to game/assets/ and art/templates/.")


if __name__ == "__main__":
    main()
