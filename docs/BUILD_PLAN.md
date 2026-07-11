# DeetsLife build plan

Vertical slice first — nothing scales until one full interaction loop works.
**Art, layout, palette, and the data model are Aditya's calls.**

> ## ⚠ The roadmap below is on hold
>
> Music is out of scope and the vision is being reworked. Milestones 1–6 were written for
> the music-museum direction: eras, jukeboxes, 30s previews. **Don't build against them.**
> They're kept as a record of what the plumbing was shaped for, not as a plan.
>
> The next real step is Aditya defining what the game is becoming. Once there's a subject,
> Milestone 2 gets rewritten around whatever the new interaction loop turns out to be.

## Milestone 0 — Toolchain ✅

- [x] Godot 4 project (`game/`): isometric graybox room, walkable player, pixel-perfect
      rendering settings, input map.
- [x] Dog: hand-drawn idles, walk strips and sit poses; breadcrumb follower (`dog.gd`).
- [x] Hand-drawn player art + walk cycles.
- [x] Placeholder art + Libresprite templates. *(Generator deleted; templates are
      committed in `art/templates/`.)*
- [x] Audio pipeline: iTunes lookup + m4a→ogg conversion. *(Deleted with `scripts/`.)*

## Milestone 0.5 — Multi-room graybox map ✅ (July 2026)

Aditya directed the layout; built and verified headless.

- [x] Six-space map, data-driven in `ROOMS` in `game/scripts/room.gd`: 5×3 entry
      (welcome mat + spawn, bottom-right), doors at both ends of the NE wall into 5×5
      rooms A and B, middle door onto a 1×5 hall to back room D (5×5), NW-wall door
      into 3×3 room C (flush with A).
- [x] Real collision: `SegmentShape2D` walls/boundaries + `move_and_slide` (replaced
      point-checks that clipped).
- [x] Wall Y-sort fix: walls render as 16px strips so sprites never draw through them.
- [x] Per-room drop-in art folders `game/assets/rooms/<room>/`, incl. optional
      doorframe slots (specs: PIXEL_ART_GUIDE § Per-room assets).
- [ ] **Aditya art pass:** floors, walls, mat, doorframes, room by room.

## Milestone 0.6 — Mahjong corner in room C 🚧

A 1×1 table on C's center tile, four quarter-tile stools tucked to its sides.
Colliders match footprints so the stool edges seal against the table (smaller
colliders left corner pockets the player could wedge into). Data-driven in `PROPS`
in `room.gd`; art contract in PIXEL_ART_GUIDE § Props.

- [x] Table + stools placed, collided, Y-sorted; walk lanes verified headless.
- [x] Cluster sealed: colliders bumped to footprint size after the wedge bug;
      re-verified headless (16-angle push probe + full lap of the table).
- [x] Wall-hung art plumbing (`WALL_ART` in `room.gd`): three graybox frames in C —
      portrait + landscape on the NW wall, portrait mid-NE wall. 64×112 overlays,
      contract in PIXEL_ART_GUIDE § Per-room assets.
- [x] Aditya: draw `mahjong_table.png` + `mahjong_chair.png` over the graybox.
- [ ] Aditya: draw the three `room_c/art_*.png` framed pieces over the graybox.
- [ ] Sitting: needs player sit poses (`sit_down/up/side`) — draw them with the next
      player-sprite batch (more characters than just Aditya's likeness), then wire
      interact-to-sit: stool collider off, sprite snaps to the seat.
- [ ] The game itself: interact at the table → camera zooms in and a tabletop scene
      opens (mahjong board + 4 action buttons). Separate art project; not started.

## Milestone 0.7 — Character pipeline 🚧

Characters are folders of PNGs; new ones need only their idle poses drawn. Feeds the
two directions Aditya has voiced: simple online multiplayer (P2P, one Discord friend
hosts, ≤16 players, custom characters shipped as PNG folders on join) and the
wardrobe / character creator (draw over a template in-game, derivations automated).

- [x] Folder-per-character rigs (`deets/`, `happy/`) + convention loader
      (`character_sprites.gd`): filename = animation, frame count from strip width.
- [x] Derivation tool (`tools/derive_character.gd`): idle poses in → walk/sit frames
      out, colors transferred through a reference rig's hand-drawn animation; part
      hints (`derive_hints.json`) keep e.g. a tail its own color; never overwrites
      any file. Proven by `lucky/` (cream dog, beige tail, derived from `happy`).
- [ ] Multiplayer walk-together slice: host + join + see each other move (authority
      in player.gd, MultiplayerSpawner, local-only camera, UPnP port open).
- [ ] Character transfer on join (rig PNGs are a few KB; build SpriteFrames from
      received buffers).
- [ ] Wardrobe: in-game station (entry-room corner), template start, import first,
      pixel editor later. Waits on Aditya's direction for the flow.

## Milestone 1 — What is this game? (ONGOING)

- [ ] **Aditya defines the new direction** — arriving as concrete build requests
      (the map above was the first) rather than a spec. Don't assume a subject.
- [ ] Decide whether any data model is needed at all, and what it carries.
- [ ] Rewrite Milestone 2 around the real interaction loop.

---

*Everything past this line predates the rework. Kept for reference; not a plan.*

## ~~Milestone 2 — The vertical slice~~ (void)

One room → one jukebox → ~5 records → one photo → walk up → interact → hear the
30s preview → see the photo.

- [ ] Jukebox prop with `interact` prompt when near.
- [ ] Record-selection UI (era's songs, artwork, titles).
- [ ] `AudioStreamPlayer` playing the converted ogg previews.
- [ ] "Open in Apple Music →" via `OS.shell_open()`.
- [ ] Photo frame on the wall; interact opens the full-res photo overlay.

The photo-frame and `interact`-prompt work is the part most likely to survive the rework —
neither depends on music.

## ~~Milestone 3 — First real era room~~ (deferred)

- [ ] Aditya art pass: floor/wall/prop tiles, era palette, framed photos.
- [ ] Real songs for one era enriched + converted end-to-end.

## ~~Milestone 4 — The museum~~ (deferred)

- [ ] Multiple rooms; doorways with scene transitions. *(A single-scene multi-room
      version now exists — Milestone 0.5; transitions only matter if the map outgrows
      one scene.)*
- [ ] Per-room ambience: palette, lighting/modulate, props.

Room-to-room transitions are subject-agnostic and likely still wanted.

## ~~Milestone 5 — Gamification + polish~~ (deferred)

- [ ] Collect/complete mechanics — Aditya's design.
- [ ] Save state (visited rooms).

## Milestone 6 — Ship

- [ ] Export presets: Windows + macOS (+ itch.io page or R2-hosted web build, optional).
- [ ] Optional: recorded cinematic walkthrough.

## Deferred decisions

- Web build hosting: Cloudflare Pages can't serve files >25 MiB, so a web export needs
  R2 (same account, free tier) or an itch.io iframe embed. Decide at Milestone 6.
- **If music ever comes back:** previews only, never bundled full tracks. Godot cannot
  decode AAC/`.m4a`, so Apple's preview URLs must be converted to Ogg Vorbis (ffmpeg).
  Full-track playback needs MusicKit ($99/yr) and only ever works on a web page, not in
  Godot. `git checkout cff5a68 -- scripts/` restores `enrich_songs.py` and
  `fetch_previews.py`, which did exactly this.
