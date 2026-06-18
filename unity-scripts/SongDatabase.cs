using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace DeetsLife
{
    /// <summary>
    /// Loads data/library.json (placed in a Resources/ folder, or assigned in the inspector)
    /// and exposes lookups by era. Drop this on a single persistent GameObject (e.g. "GameManager").
    ///
    /// Setup: put library.json in Assets/Resources/ and set `resourceName` to "library"
    /// (no extension), OR drag a TextAsset into `libraryJson`.
    /// </summary>
    public class SongDatabase : MonoBehaviour
    {
        [Tooltip("Optional: drag library.json (as a TextAsset) here.")]
        public TextAsset libraryJson;

        [Tooltip("If no TextAsset assigned, load this from a Resources/ folder (no extension).")]
        public string resourceName = "library";

        public Library Library { get; private set; }

        // JsonUtility cannot parse a top-level array, so the root is an object with named arrays.
        [System.Serializable]
        public class Library
        {
            public Era[] eras;
            public Song[] songs;
        }

        void Awake()
        {
            string json = libraryJson != null
                ? libraryJson.text
                : Resources.Load<TextAsset>(resourceName)?.text;

            if (string.IsNullOrEmpty(json))
            {
                Debug.LogError($"[SongDatabase] No library JSON found (resource '{resourceName}').");
                Library = new Library { eras = new Era[0], songs = new Song[0] };
                return;
            }

            Library = JsonUtility.FromJson<Library>(json);
            Debug.Log($"[SongDatabase] Loaded {Library.eras.Length} eras, {Library.songs.Length} songs.");
        }

        public IEnumerable<Song> SongsInEra(string eraId) =>
            Library.songs.Where(s => s.eraId == eraId);

        public Era GetEra(string eraId) =>
            Library.eras.FirstOrDefault(e => e.id == eraId);
    }
}
