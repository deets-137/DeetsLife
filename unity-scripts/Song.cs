using System;

namespace DeetsLife
{
    /// <summary>
    /// One song. Mirrors a song object in data/library.json. Field names MUST match the JSON keys
    /// for Unity's JsonUtility to populate them. You own the data model — if you add/rename a field
    /// in the JSON, add/rename it here too.
    /// </summary>
    [Serializable]
    public class Song
    {
        public string id;
        public string title;
        public string artist;
        public string album;
        public string eraId;
        public string dateAdded;      // ISO yyyy-MM-dd
        public string songOfTheDay;   // ISO date or null
        public string previewUrl;     // 30s clip (filled by enrich_songs.py)
        public string artworkUrl;
        public long appleTrackId;
    }
}
