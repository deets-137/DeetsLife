# Data model (you own this)

This documents the *current sample shape*. It's a starting point — rename, add, or drop fields
as your real Apple Music data dictates, then tell me the final names so I sync the Python tooling
and the C# loader.

Root is an **object** (not an array) so Unity's `JsonUtility` can parse it:

```jsonc
{
  "meta":  { ... },          // free-form
  "eras":  [ Era,  ... ],
  "songs": [ Song, ... ]
}
```

### Era
| field   | type            | notes                                   |
|---------|-----------------|-----------------------------------------|
| id      | string          | stable key, referenced by songs.eraId   |
| title   | string          | display name                            |
| start   | string (date)   | ISO `YYYY-MM-DD`                        |
| end     | string \| null  | null = ongoing                          |
| blurb   | string          | short description                       |
| palette | string[]        | hex colors; can drive per-era lighting  |

### Song
| field        | type            | filled by        | notes                              |
|--------------|-----------------|------------------|------------------------------------|
| id           | string          | you              | stable key                         |
| title        | string          | you              | required for lookup                |
| artist       | string          | you              | required for lookup                |
| album        | string          | you              |                                    |
| eraId        | string          | you              | which era this belongs to          |
| dateAdded    | string \| null  | you (Apple data) | ISO date                           |
| songOfTheDay | string \| null  | you              | ISO date if it was a SOTD          |
| previewUrl   | string \| null  | `enrich_songs.py`| 30s clip                           |
| artworkUrl   | string \| null  | `enrich_songs.py`| 600x600                            |
| appleTrackId | int \| null     | `enrich_songs.py`| iTunes/Apple track id              |

**Contract:** the enrichment tool only fills `previewUrl`, `artworkUrl`, `appleTrackId`, and never
overwrites your authored fields (unless `--force`). The C# field names in `unity-scripts/Song.cs`
must match these keys exactly.
