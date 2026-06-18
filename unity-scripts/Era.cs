using System;

namespace DeetsLife
{
    /// <summary>One era/chapter. Mirrors an era object in data/library.json.</summary>
    [Serializable]
    public class Era
    {
        public string id;
        public string title;
        public string start;   // ISO yyyy-MM-dd
        public string end;     // ISO date or null (ongoing)
        public string blurb;
        public string[] palette;  // hex strings, e.g. "#1a1a2e"
    }
}
