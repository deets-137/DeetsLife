# DeetsLife build plan

Vertical slice first — nothing scales until the full loop works once.
**Art, layout, palette, and the data model are Aditya's calls.**

## Milestone 0 — Toolchain ✅ (scaffolded)

- [x] Godot 4 project (`game/`): isometric graybox room, walkable player, pixel-perfect
      rendering settings, input map.
- [x] Placeholder art + Libresprite templates (`scripts/make_placeholder_art.py`).
- [x] Audio pipeline: `enrich_songs.py` (iTunes lookup) + `fetch_previews.py`
      (m4a→ogg for Godot).
- [ ] Aditya: install Godot 4.4+, Libresprite, ffmpeg; open `game/`, walk the graybox.

## Milestone 1 — Data model (NEXT)

- [ ] Aditya defines the real model (eras, songs, photos, rooms, gamification hooks).
- [ ] Sync `docs/DATA_MODEL.md`, `data/library.sample.json`, both Python scripts.
- [ ] GDScript loader: parse `library.json` into typed objects at startup.

## Milestone 2 — The vertical slice

One room → one jukebox → ~5 records → one photo → walk up → interact → hear the
30s preview → see the photo.

- [ ] Jukebox prop (placeholder sprite) with `interact` prompt when near.
- [ ] Record-selection UI (era's songs, artwork, titles).
- [ ] `AudioStreamPlayer` playing the converted ogg previews.
- [ ] "Open in Apple Music →" / "hear it on deets.solutions →" via `OS.shell_open()`.
- [ ] Photo frame on the wall; interact opens the full-res photo overlay.

## Milestone 3 — First real era room

- [ ] Aditya art pass: floor/wall/prop tiles, jukebox sprite, caricature player
      (idle poses done; walk-cycle strips are placeholders awaiting a redraw),
      framed photos, era palette.
- [ ] Real songs for one era enriched + converted end-to-end.

## Milestone 4 — The museum

- [ ] Multiple era rooms; doorways with scene transitions.
- [ ] Museum structure (hub hall? chronological corridor? Aditya's call).
- [ ] Per-era ambience: palette, lighting/modulate, maybe era-specific props.

## Milestone 5 — Gamification + polish

- [ ] Collect/complete mechanics (find every record? unlock rooms?) — Aditya's design.
- [ ] Jukebox glow reacting to audio (shader/modulate driven by playback).
- [ ] Save state (visited rooms, played songs).

## Milestone 6 — Ship

- [ ] Export presets: Windows + macOS (+ itch.io page or R2-hosted web build, optional).
- [ ] DeetsLife page on deets.solutions with Apple Music embeds per era.
- [ ] Optional: recorded cinematic walkthrough.

## Deferred decisions

- Web build hosting: Cloudflare Pages can't serve files >25 MiB, so a web export needs
  R2 (same account, free tier) or an itch.io iframe embed. Decide at Milestone 6.
- Full-track playback (MusicKit, $99/yr dev account) — only ever viable on a web page,
  not in Godot. Previews + outbound links cover the need for now.
