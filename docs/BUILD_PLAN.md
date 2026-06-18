# DeetsLife — build plan

The roadmap, technical side. **Art, layout, palette, and the data model are Aditya's calls.**
Each phase lists who does what. We do NOT scale until the Phase 2 vertical slice runs end to end.

---

## Phase 0 — foundations (mostly done in scaffold)

- [x] Project structure, CLAUDE.md, README
- [x] `.gitignore` + `.gitattributes` (Git LFS)
- [x] Data model sample + JSON Schema (`data/`)
- [x] `enrich_songs.py` (preview URLs + artwork)
- [x] Drop-in C# scaffolds (`unity-scripts/`)
- [ ] `git init`, `git lfs install`, first commit  ← run when you're ready
- [ ] Install Unity Hub + a Unity LTS editor with **URP** template
- [ ] Confirm Blender + Lightroom installed and exporting

## Phase 1 — data spine

- **You:** define the real eras and produce your song list (Apple Music export → your model).
  You own the schema; tell me the final field names.
- **Me:** adapt `enrich_songs.py` + the C# data classes to your final shape; run enrichment to
  produce `data/library.json` (with preview + artwork per song).
- **Exit:** a validated `library.json` that loads in a tiny console/Unity test.

## Phase 2 — VERTICAL SLICE (the gate)

One era, one room, one jukebox, ~5 records, one photo. Prove the whole pipeline once.

- **You (art):** model a jukebox in Blender (your style); make/choose the room; pick the 5 songs;
  grade one photo in Lightroom.
- **Me (tech):**
  - Set up the Unity URP project, scene, first-person controller, lighting.
  - Import pipeline: `.glb` export settings (scale 1u=1m), material rebuild in Unity.
  - Wire `SongDatabase` → `JukeboxController` → `AudioPreviewPlayer`; interaction (walk up + press E).
  - Emissive glow pulse on the jukebox; photo on a framed quad.
- **Exit:** walk up to the jukebox, cycle records, hear the 30s preview, see the photo. ✅

## Phase 3 — scale the content

- **You:** model/skin remaining jukeboxes + records; lay out all eras; grade photo sets.
- **Me:** data-driven instantiation (spawn a record per song from the library; swap label texture
  from `artworkUrl`); per-era zone loading; palette → lighting hookup.

## Phase 4 — gamification

- **You:** decide the mechanics and rules (what's fun, what's rewarded).
- **Me:** implement them in C# (e.g. collect/unlock records, era progression, "needle-drop" minigame,
  discovery achievements, a record you can carry to any jukebox).

## Phase 5 — visualizations

- **You:** decide what insight to surface and how it should look.
- **Me:** build the data viz (genre/era timelines, mood arcs) as 3D objects or in-world screens.

## Phase 6 — the film + ship

- **Me:** Cinemachine camera paths + Timeline choreography; Unity Recorder → mp4.
  Builds: Windows .exe and/or WebGL for sharing. Performance pass (lightmap bakes, LODs, draw calls).
- **You:** direct the camera, the cut, the music bed, the title cards.

---

## Standing technical guardrails

- Scale 1u = 1m = 1 Unity unit, everywhere.
- Blender→Unity via `.glb`; bake materials to PBR maps; finalize look in Unity.
- Audio = 30s preview URLs; never bundle full tracks.
- Git LFS for all binary assets; C# tracked normally.
- One source of truth: `data/library.json` shared by Python tooling and the C# loader.
