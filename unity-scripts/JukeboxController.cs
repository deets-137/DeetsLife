using UnityEngine;

namespace DeetsLife
{
    /// <summary>
    /// Interaction hub. Bound to a jukebox GameObject for one era. When the player interacts
    /// (raycast + key, trigger, or UI), it picks a song from its era and plays the preview,
    /// and pulses an emissive material so the jukebox "lights up" with the music.
    ///
    /// This is a SCAFFOLD — wiring (input system, UI, song selection UX) is intentionally minimal
    /// and meant to be shaped around your design. Art (the model, the materials) is yours.
    /// </summary>
    public class JukeboxController : MonoBehaviour
    {
        [Header("Wiring")]
        public SongDatabase database;
        public AudioPreviewPlayer player;
        [Tooltip("Which era this jukebox belongs to (matches an era id in the data).")]
        public string eraId;

        [Header("Glow (emissive)")]
        [Tooltip("Renderer whose material has an _EmissionColor to pulse with audio.")]
        public Renderer glowRenderer;
        public Color glowColor = Color.cyan;
        public float glowStrength = 2f;

        Material _glowMat;
        int _songIndex = -1;
        Song[] _songs;

        void Start()
        {
            if (database == null) database = FindObjectOfType<SongDatabase>();
            if (player == null) player = GetComponent<AudioPreviewPlayer>();

            _songs = System.Linq.Enumerable.ToArray(database.SongsInEra(eraId));
            if (glowRenderer != null)
            {
                _glowMat = glowRenderer.material;       // instance, safe to modify
                _glowMat.EnableKeyword("_EMISSION");
            }
            Debug.Log($"[Jukebox:{eraId}] {_songs.Length} songs loaded.");
        }

        /// <summary>Call from your interaction system (raycast+E, trigger, button, etc.).</summary>
        public void Interact()
        {
            if (_songs == null || _songs.Length == 0) return;
            _songIndex = (_songIndex + 1) % _songs.Length;   // simple "next track" for now
            var song = _songs[_songIndex];
            Debug.Log($"[Jukebox:{eraId}] Playing {song.title} — {song.artist}");
            player?.Play(song.previewUrl);
        }

        void Update()
        {
            if (_glowMat == null) return;
            // Pulse emission with current audio loudness (placeholder: simple sine until you
            // wire AudioSource.GetSpectrumData / GetOutputData for real reactivity).
            float pulse = (Mathf.Sin(Time.time * 6f) * 0.5f + 0.5f) * glowStrength;
            _glowMat.SetColor("_EmissionColor", glowColor * pulse);
        }
    }
}
