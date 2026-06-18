#!/usr/bin/env python3
"""
enrich_songs.py — fill in 30s preview URLs + album artwork for the DeetsLife library.

Reads a library JSON ({ "eras": [...], "songs": [...] }), and for every song missing a
`previewUrl` / `artworkUrl` / `appleTrackId`, queries the public iTunes Search API
(no auth, free) by "<title> <artist>" and fills the fields in.

You own the data model — this script only touches the three lookup fields and never
overwrites values that are already set (unless --force).

Usage:
    python enrich_songs.py ../data/library.sample.json -o ../data/library.json
    python enrich_songs.py ../data/library.json --in-place --force

Notes:
- The iTunes Search API is rate-limited (~20 req/min). We sleep between calls and cache
  results in .cache_itunes.json so re-runs are cheap.
- artworkUrl is upscaled from the 100x100 the API returns to 600x600.
"""

import argparse
import json
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ITUNES_ENDPOINT = "https://itunes.apple.com/search"
CACHE_PATH = Path(__file__).with_name(".cache_itunes.json")
USER_AGENT = "DeetsLife/1.0 (personal art project)"


def load_cache():
    if CACHE_PATH.exists():
        try:
            return json.loads(CACHE_PATH.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return {}
    return {}


def save_cache(cache):
    CACHE_PATH.write_text(json.dumps(cache, indent=2, ensure_ascii=False), encoding="utf-8")


def itunes_lookup(title, artist, cache, sleep=3.0):
    """Return dict with previewUrl/artworkUrl/appleTrackId or None. Cached by query key."""
    term = f"{title} {artist}".strip()
    key = term.lower()
    if key in cache:
        return cache[key]

    params = urllib.parse.urlencode({"term": term, "entity": "song", "limit": 1})
    url = f"{ITUNES_ENDPOINT}?{params}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except Exception as exc:  # network, decode, HTTP — keep going, just skip this one
        print(f"  ! lookup failed for {term!r}: {exc}", file=sys.stderr)
        cache[key] = None
        return None
    finally:
        time.sleep(sleep)  # be polite to the API

    results = payload.get("results") or []
    if not results:
        cache[key] = None
        return None

    r = results[0]
    art = r.get("artworkUrl100") or ""
    result = {
        "previewUrl": r.get("previewUrl"),
        "artworkUrl": art.replace("100x100bb", "600x600bb") if art else None,
        "appleTrackId": r.get("trackId"),
        "matchedTitle": r.get("trackName"),
        "matchedArtist": r.get("artistName"),
    }
    cache[key] = result
    return result


def enrich(library, force=False, sleep=3.0):
    cache = load_cache()
    songs = library.get("songs", [])
    filled = skipped = missed = 0

    for i, song in enumerate(songs, 1):
        title, artist = song.get("title"), song.get("artist")
        if not title or not artist:
            print(f"  - [{i}/{len(songs)}] skipping, missing title/artist: {song.get('id')}")
            continue

        already = song.get("previewUrl") and song.get("artworkUrl")
        if already and not force:
            skipped += 1
            continue

        print(f"  > [{i}/{len(songs)}] {title} — {artist}")
        match = itunes_lookup(title, artist, cache, sleep=sleep)
        if not match:
            missed += 1
            continue

        # Only fill the lookup fields; never clobber your authored data.
        for field in ("previewUrl", "artworkUrl", "appleTrackId"):
            if force or not song.get(field):
                song[field] = match.get(field)
        filled += 1
        flag = "" if match.get("previewUrl") else "  (no preview available)"
        print(f"      matched: {match.get('matchedTitle')} — {match.get('matchedArtist')}{flag}")

    save_cache(cache)
    print(f"\nDone. filled={filled} skipped(existing)={skipped} no-match={missed}")
    return library


def main():
    ap = argparse.ArgumentParser(description="Enrich DeetsLife songs with iTunes preview + artwork.")
    ap.add_argument("input", help="path to library JSON")
    ap.add_argument("-o", "--output", help="output path (default: alongside input as library.json)")
    ap.add_argument("--in-place", action="store_true", help="overwrite the input file")
    ap.add_argument("--force", action="store_true", help="re-fetch even if fields are already set")
    ap.add_argument("--sleep", type=float, default=3.0, help="seconds between API calls (default 3)")
    args = ap.parse_args()

    in_path = Path(args.input)
    if not in_path.exists():
        ap.error(f"input not found: {in_path}")

    library = json.loads(in_path.read_text(encoding="utf-8"))
    if "songs" not in library:
        ap.error("expected an object with a 'songs' array (see data/library.sample.json)")

    enrich(library, force=args.force, sleep=args.sleep)

    if args.in_place:
        out_path = in_path
    elif args.output:
        out_path = Path(args.output)
    else:
        out_path = in_path.with_name("library.json")

    out_path.write_text(json.dumps(library, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
