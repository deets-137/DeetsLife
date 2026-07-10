#!/usr/bin/env python3
"""
fetch_previews.py — download the 30s iTunes previews and convert them for Godot.

Godot can't decode AAC (.m4a), which is what Apple's preview URLs serve, so this
script downloads each song's `previewUrl` and converts it to Ogg Vorbis at
game/assets/audio/previews/<songId>.ogg — the path the in-game jukebox loads.

Run enrich_songs.py first so songs have previewUrl set.

Requires ffmpeg on PATH:
    Windows: winget install Gyan.FFmpeg    macOS: brew install ffmpeg

Usage:
    python fetch_previews.py ../data/library.json
    python fetch_previews.py ../data/library.json --force   # re-fetch everything
"""

import argparse
import json
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT_DIR = REPO / "game" / "assets" / "audio" / "previews"
CACHE_DIR = Path(__file__).with_name(".cache_previews")
USER_AGENT = "DeetsLife/1.0 (personal art project)"


def download(url, dest):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as resp:
        dest.write_bytes(resp.read())


def convert(src, dest, ffmpeg):
    subprocess.run(
        [ffmpeg, "-y", "-loglevel", "error", "-i", str(src),
         "-vn", "-c:a", "libvorbis", "-q:a", "5", str(dest)],
        check=True,
    )


def main():
    ap = argparse.ArgumentParser(description="Fetch iTunes previews and convert to ogg for Godot.")
    ap.add_argument("input", help="path to enriched library JSON")
    ap.add_argument("--force", action="store_true", help="re-download and re-convert existing files")
    args = ap.parse_args()

    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        sys.exit("ffmpeg not found on PATH. Windows: winget install Gyan.FFmpeg | macOS: brew install ffmpeg")

    library = json.loads(Path(args.input).read_text(encoding="utf-8"))
    songs = library.get("songs", [])
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    CACHE_DIR.mkdir(exist_ok=True)

    done = skipped = missing = failed = 0
    for i, song in enumerate(songs, 1):
        song_id, url = song.get("id"), song.get("previewUrl")
        if not song_id or not url:
            missing += 1
            continue

        ogg = OUT_DIR / f"{song_id}.ogg"
        if ogg.exists() and not args.force:
            skipped += 1
            continue

        m4a = CACHE_DIR / f"{song_id}.m4a"
        print(f"  > [{i}/{len(songs)}] {song.get('title')} — {song.get('artist')}")
        try:
            if not m4a.exists() or args.force:
                download(url, m4a)
            convert(m4a, ogg, ffmpeg)
            done += 1
        except Exception as exc:
            print(f"  ! failed for {song_id}: {exc}", file=sys.stderr)
            failed += 1

    print(f"\nDone. converted={done} skipped(existing)={skipped} no-preview={missing} failed={failed}")
    print(f"Oggs are in {OUT_DIR}")


if __name__ == "__main__":
    main()
