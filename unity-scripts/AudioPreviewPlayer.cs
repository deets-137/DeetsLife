using System.Collections;
using UnityEngine;
using UnityEngine.Networking;

namespace DeetsLife
{
    /// <summary>
    /// Streams and plays a 30s preview URL through an AudioSource. Requires an AudioSource on the
    /// same GameObject (added automatically). Call Play(previewUrl).
    ///
    /// Note: for a built/WebGL player, streaming from Apple's CDN needs network access at runtime.
    /// For an offline/exhibit build, pre-download previews and load them locally instead.
    /// </summary>
    [RequireComponent(typeof(AudioSource))]
    public class AudioPreviewPlayer : MonoBehaviour
    {
        AudioSource _source;
        Coroutine _loading;

        void Awake() => _source = GetComponent<AudioSource>();

        public void Play(string previewUrl)
        {
            if (string.IsNullOrEmpty(previewUrl))
            {
                Debug.LogWarning("[AudioPreviewPlayer] No preview URL for this song.");
                return;
            }
            if (_loading != null) StopCoroutine(_loading);
            _loading = StartCoroutine(LoadAndPlay(previewUrl));
        }

        public void Stop()
        {
            if (_loading != null) StopCoroutine(_loading);
            _source.Stop();
        }

        IEnumerator LoadAndPlay(string url)
        {
            // Apple previews are .m4a — AudioType.UNKNOWN lets Unity sniff it; MPEG also works for many.
            using var req = UnityWebRequestMultimedia.GetAudioClip(url, AudioType.UNKNOWN);
            yield return req.SendWebRequest();

            if (req.result != UnityWebRequest.Result.Success)
            {
                Debug.LogError($"[AudioPreviewPlayer] Failed to load clip: {req.error}");
                yield break;
            }

            var clip = DownloadHandlerAudioClip.GetContent(req);
            _source.clip = clip;
            _source.Play();
        }
    }
}
