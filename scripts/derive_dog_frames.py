#!/usr/bin/env python3
"""
derive_dog_frames.py — build the dog's back view and walk strips from Aditya's hand-drawn
side + down idles, by moving HIS pixels around. No pixel is invented except the tail nub
on the back view (traced from the side view's tail).

Reads (never writes):
    game/assets/sprites/dog_side.png     32x32, faces LEFT
    game/assets/sprites/dog_down.png     32x32, faces camera

Writes:
    game/assets/sprites/dog_up.png       32x32, faces away
    game/assets/sprites/dog_side_walk.png  128x32  (4 frames)
    game/assets/sprites/dog_down_walk.png  128x32
    game/assets/sprites/dog_up_walk.png    128x32
    art/templates/dog_sit_{side,down,up}_template.png   drawing aids for the sit poses
    art/templates/dog_palette.png                       the dog's colors, one px each

The three sit poses (dog_sit_side/down/up.png) are hand-drawn and this script never
touches them — a folded hind leg isn't something you get by relocating pixels. What it
does instead is emit a template per facing carrying the anchor, ground line, hip row and
a ghost of the idle, so a sit drawn over it lines up with the idle it cuts to.

Re-run this whenever you redraw dog_side.png or dog_down.png. It re-derives everything.
Hand-drew one of the outputs yourself? Pass --keep to skip files that already differ.

How the walk works (frame order: step-A, passing, step-B, passing — per PIXEL_ART_GUIDE):
  * Legs are found automatically: the first row below which the silhouette splits into
    two separate column runs is the hip line. Everything above it is "body".
  * SIDE view: on the step frames the front and hind legs stride in opposite directions;
    on the passing frames the legs line up and the body bobs 1px, with the legs stretched
    one row taller so the paws stay planted on row 31.
  * DOWN/UP views: legs barely travel sideways, so one paw lifts on each step frame
    instead, and the body bobs on the passing frames.
"""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parent.parent
SPRITES = REPO / "game" / "assets" / "sprites"
TEMPLATES = REPO / "art" / "templates"

CELL = 32
GROUND = CELL - 1  # paws sit on this row
FRAMES = 4
BOB = 1            # px the body lifts on a passing frame
STRIDE = 2         # px a side-view leg swings fore/aft
LIFT = 2           # px a down/up-view paw lifts on a step frame

TRANSPARENT = (0, 0, 0, 0)


# ---- reading Aditya's art ----

def _luma(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def _fur_tones(img):
    """The two commonest opaque colors, returned as (base, shadow).

    Ordered by brightness, not by pixel count: the shadow tone outnumbers the base in
    dog_down.png (208px to 164), so counting alone hands the pair back reversed.
    """
    opaque = [(n, c) for n, c in img.getcolors(maxcolors=1 << 16) if c[3]]
    opaque.sort(reverse=True)
    a, b = opaque[0][1], opaque[1][1]
    return (a, b) if _luma(a) >= _luma(b) else (b, a)


def _hip_row(img):
    """First row below which the silhouette stays split into 2+ column runs: the hip line."""
    def runs(y):
        n, prev = 0, False
        for x in range(CELL):
            solid = img.getpixel((x, y))[3] > 0
            if solid and not prev:
                n += 1
            prev = solid
        return n

    for y in range(CELL - 1, -1, -1):
        if runs(y) < 2:
            return y + 1
    raise SystemExit("could not find the hip line — is the dog's silhouette one blob?")


def _leg_spans(img, hip):
    """Column ranges of each leg, unioned over every row below the hip."""
    cols = set()
    for y in range(hip, CELL):
        for x in range(CELL):
            if img.getpixel((x, y))[3]:
                cols.add(x)
    spans, start = [], None
    for x in range(CELL + 1):
        if x in cols and start is None:
            start = x
        elif x not in cols and start is not None:
            spans.append((start, x - 1))
            start = None
    return spans


def _part(img, box):
    return img.crop(box)


# ---- frame assembly ----

def _frame(img, hip, legs, body_dy, leg_dx, leg_dy):
    """One 32x32 walk frame: body shifted by body_dy, each leg by (leg_dx[i], leg_dy[i])."""
    out = Image.new("RGBA", (CELL, CELL), TRANSPARENT)
    body = _part(img, (0, 0, CELL, hip))
    if body_dy >= 0:
        out.alpha_composite(body, (0, body_dy))
    else:
        # Lifting the body would push it off the top of the canvas; crop what rides off.
        out.alpha_composite(body.crop((0, -body_dy, CELL, hip)), (0, 0))

    for (x0, x1), dx, dy in zip(legs, leg_dx, leg_dy):
        leg = _part(img, (x0, hip, x1 + 1, CELL))
        # A lifted body leaves a gap at the hip: stretch the leg up by repeating its top row.
        if body_dy < 0:
            top = leg.crop((0, 0, leg.width, 1))
            for k in range(1, -body_dy + 1):
                out.alpha_composite(top, (x0 + dx, hip - k))
        dest_y = hip + dy
        if dest_y >= 0:
            out.alpha_composite(leg, (x0 + dx, dest_y))
    return out


def _strip(frames):
    strip = Image.new("RGBA", (CELL * FRAMES, CELL), TRANSPARENT)
    for i, f in enumerate(frames):
        strip.alpha_composite(f, (i * CELL, 0))
    return strip


def make_side_walk(img):
    """Front and hind legs stride in opposition; body bobs on the passing frames."""
    hip = _hip_row(img)
    legs = _leg_spans(img, hip)
    if len(legs) != 2:
        raise SystemExit(f"side view: expected 2 legs below row {hip}, found {len(legs)}")
    front, hind = legs  # dog faces left, so the leftmost span is the front leg
    print(f"  side: hip=row{hip} front=x{front[0]}-{front[1]} hind=x{hind[0]}-{hind[1]}")

    poses = [
        (0, [-STRIDE, +STRIDE]),   # step-A: front reaches, hind trails
        (-BOB, [0, 0]),            # passing
        (0, [+STRIDE, -STRIDE]),   # step-B
        (-BOB, [0, 0]),            # passing
    ]
    return _strip([_frame(img, hip, legs, dy, dx, [0, 0]) for dy, dx in poses])


def make_facing_walk(img, label):
    """Down/up view: one paw lifts per step frame, body bobs on the passing frames."""
    hip = _hip_row(img)
    legs = _leg_spans(img, hip)
    if len(legs) != 2:
        raise SystemExit(f"{label}: expected 2 legs below row {hip}, found {len(legs)}")
    print(f"  {label}: hip=row{hip} legs=x{legs[0][0]}-{legs[0][1]}, x{legs[1][0]}-{legs[1][1]}")

    poses = [
        (0, [-LIFT, 0]),   # step-A: left paw up
        (-BOB, [0, 0]),    # passing
        (0, [0, -LIFT]),   # step-B: right paw up
        (-BOB, [0, 0]),    # passing
    ]
    return _strip([_frame(img, hip, legs, dy, [0, 0], ldy) for dy, ldy in poses])


def make_up(down):
    """Back view: the down view with its face erased and the side view's tail added."""
    fur, fur_dark = _fur_tones(down)
    up = down.copy()
    px = up.load()
    wiped = 0
    for y in range(CELL):
        for x in range(CELL):
            c = px[x, y]
            if c[3] and c != fur and c != fur_dark:  # eyes, nose, mouth
                px[x, y] = fur
                wiped += 1
    # Tail nub, rising from the rump toward the camera. Traced from the side view's 3x3
    # tail, widened by one px because we're looking straight up its length.
    tail = ([(x, 14) for x in (15, 16)]
            + [(x, y) for y in range(15, 19) for x in range(14, 18)]
            + [(x, 19) for x in (15, 16)])
    # Whichever tone the rump *isn't*, so the nub reads instead of vanishing into it.
    under = [px[x, y] for x, y in tail if px[x, y][3]]
    tone = fur if under.count(fur_dark) >= under.count(fur) else fur_dark
    for x, y in tail:
        px[x, y] = tone
    print(f"  up: wiped {wiped} face px, drew {len(tail)} px of tail")
    return up


# ---- sit templates (drawing aids; the sit sprites themselves are hand-drawn) ----

GHOST_ALPHA = 72
FEET_ZONE = (200, 120, 90, 55)    # bottom 4 rows: where paws/rump may touch
GROUND = (200, 120, 90, 120)      # row 31 itself
CENTER = (90, 150, 200, 70)       # bottom-center anchor column
HIP = (200, 90, 170, 80)          # where the idle's legs begin
BORDER = (40, 40, 48, 180)


def _ghost(img):
    """The idle, faded — proportions to trace against, not pixels to keep."""
    out = img.copy()
    px = out.load()
    for y in range(CELL):
        for x in range(CELL):
            c = px[x, y]
            if c[3]:
                px[x, y] = (c[0], c[1], c[2], GHOST_ALPHA)
    return out


def make_sit_template(idle):
    """A 32x32 canvas carrying the idle's anchor, ground line, hip and silhouette.

    Everything a sit pose has to agree with so the dog doesn't jump when it sits:
    same bottom-center anchor, same row-31 contact, same head width. No pose is drawn —
    that's Aditya's.
    """
    img = Image.new("RGBA", (CELL, CELL), TRANSPARENT)
    d = ImageDraw.Draw(img)
    d.rectangle([0, CELL - 4, CELL - 1, CELL - 1], fill=FEET_ZONE)
    d.rectangle([0, CELL - 1, CELL - 1, CELL - 1], fill=GROUND)
    d.rectangle([15, 0, 16, CELL - 1], fill=CENTER)
    hip = _hip_row(idle)
    d.rectangle([0, hip, CELL - 1, hip], fill=HIP)
    img.alpha_composite(_ghost(idle))
    d.rectangle([0, 0, CELL - 1, CELL - 1], outline=BORDER)
    return img, hip


def make_palette_strip(*imgs):
    """Every opaque color across the dog art, one column each — importable in Libresprite."""
    seen = []
    for img in imgs:
        for _, c in sorted(img.getcolors(maxcolors=1 << 16), reverse=True):
            if c[3] and c not in seen:
                seen.append(c)
    seen.sort(key=_luma, reverse=True)
    strip = Image.new("RGBA", (len(seen), 1), TRANSPARENT)
    for i, c in enumerate(seen):
        strip.putpixel((i, 0), c)
    return strip, seen


def main():
    ap = argparse.ArgumentParser(description="Derive the dog's back view + walk strips.")
    ap.add_argument("--keep", action="store_true", help="skip outputs that already exist")
    args = ap.parse_args()

    def write(img, name):
        path = SPRITES / name
        if args.keep and path.exists():
            print(f"  skip (exists): {name}")
            return
        img.save(path)
        print(f"  wrote: {name}")

    side = Image.open(SPRITES / "dog_side.png").convert("RGBA")
    down = Image.open(SPRITES / "dog_down.png").convert("RGBA")
    for src, name in ((side, "dog_side.png"), (down, "dog_down.png")):
        if src.size != (CELL, CELL):
            raise SystemExit(f"{name} must be {CELL}x{CELL}, got {src.size}")

    up = make_up(down)
    write(up, "dog_up.png")
    write(make_side_walk(side), "dog_side_walk.png")
    write(make_facing_walk(down, "down"), "dog_down_walk.png")
    write(make_facing_walk(up, "up"), "dog_up_walk.png")

    TEMPLATES.mkdir(parents=True, exist_ok=True)
    for idle, facing in ((side, "side"), (down, "down"), (up, "up")):
        tpl, hip = make_sit_template(idle)
        tpl.save(TEMPLATES / f"dog_sit_{facing}_template.png")
        print(f"  wrote: templates/dog_sit_{facing}_template.png (hip=row{hip})")
    strip, tones = make_palette_strip(side, down)
    strip.save(TEMPLATES / "dog_palette.png")
    print(f"  wrote: templates/dog_palette.png ({len(tones)} colors)")

    print("Derived from dog_side.png + dog_down.png — those two were not modified.")
    print("dog_sit_*.png are hand-drawn and are never written by this script.")


if __name__ == "__main__":
    main()
