using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
// using System.Management.Automation.Host;
using System.IO;
using Spectre.Console;
using Spectre.Console.Rendering;


namespace PwshSpectreConsole
{
    public abstract class Transform
    {
        /// <summary>
        ///  https://github.com/dotnet/csharplang/issues/7400
        ///  https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/strings/
        /// </summary>
        private const string VT = @"(\u001b\[\d*(;\d+)*m)";
        private const string CSI = @"(\u001b\[\?\d+[hl])";
        private const string Link = @"(\u001b\]8;;.*?\u001b\\)";
        private const string ResetVT = "\u001b[0m";
        internal static readonly Regex VTRegex = new Regex($"{VT}", RegexOptions.Compiled);
        internal static readonly Regex Escapes = new Regex($"{VT}|{CSI}|{Link}", RegexOptions.Compiled);
        public class VtObject
        {
            public int Index { get; set; }
            public int Length { get; set; }
            public string Text { get; set; }
            public List<IVT> EscapeSequence { get; set; }
            public Hashtable Mapped { get; set; }

        }
        public class TextFragment
        {
            public int Index { get; set; }
            public int CleanIndex { get; set; }
            public int Length { get; set; }
            public string Text { get; set; }
            public string EscapeSequence { get; set; }
            public string Original { get; set; }
        }
#nullable enable
        public static string ToCleanString(string text, bool complete = false)
        {
            string? Cleanstring;
            if (complete)
            {
                Cleanstring = Escapes.Replace(text, string.Empty);
            }
            else
            {
                Cleanstring = VTRegex.Replace(text, string.Empty);
            }
            return Cleanstring;
        }
#nullable disable
        internal static Hashtable Map(List<IVT> input)
        {
            StringBuilder sb = new StringBuilder();
            Hashtable ht = new Hashtable
            {
                { "fg", Color.Default },
                { "bg", Color.Default },
            };
            foreach (IVT item in input)
            {
                switch (item)
                {
                    case VtCode vt:
                        if (vt.IsForeground)
                        {
                            ht["fg"] = vt.Color;
                        }
                        else
                        {
                            ht["bg"] = vt.Color;
                        }
                        break;
                    case Deco deco:
                        ht["decoration"] = deco.Decoration;
                        break;
                }
            }
            return ht;
        }
        public static List<TextFragment> GetTextFragments(string text)
        {
            string[] substrings = Escapes.Split(text);
            List<TextFragment> textFragments = new List<TextFragment>();
            int currentIndex = 0;
            int cleanIndex = 0;
            StringBuilder currentEscapeSequence = new StringBuilder();
            for (int i = 0; i < substrings.Length; i++)
            {
                string substring = substrings[i];
                if (Escapes.IsMatch(substring))
                {
                    currentEscapeSequence.Append(substring);
                }
                else
                {
                    if (!string.IsNullOrEmpty(substring))
                    {
                        TextFragment textFragment = new TextFragment
                        {
                            Index = currentIndex,
                            CleanIndex = cleanIndex,
                            Length = substring.Length,
                            Text = substring,
                            EscapeSequence = currentEscapeSequence.ToString(),
                            Original = currentEscapeSequence.ToString() + substring + ResetVT
                        };
                        textFragments.Add(textFragment);
                        cleanIndex += substring.Length;
                        currentEscapeSequence.Clear();
                    }
                }
                currentIndex += substring.Length;
            }
            return textFragments;
        }
        public static string Render(Renderable renderableObject)
        {
            using (var writer = new StringWriter())
            {
                var output = new AnsiConsoleOutput(writer);
                var settings = new AnsiConsoleSettings { Out = output };
                var console = AnsiConsole.Create(settings);
                console.Write(renderableObject);
                return writer.ToString();
            }
        }
        // public static object ToMarkUp(string input, bool AsString = false)
        // {
        //     string[] segments = Regex.Split(input, "(?=\u001b)");
        //     StringBuilder sb = new();
        //     Hashtable _previous = new();
        //     foreach (string str in segments)
        //     {
        //         if (string.IsNullOrEmpty(str))
        //         {
        //             continue;
        //         }
        //         List<IVT> lookup = Decoder.Parse(str);
        //         Hashtable ht = (Hashtable)Map(lookup);
        //         ht.Add("String", Transform.ToCleanString(str, true));

        //         if (string.IsNullOrEmpty((string)ht["String"]))
        //         {
        //             _previous = ht;
        //             continue;
        //         }
        //         if ((Color)ht["fg"] == Color.Default && _previous["fg"] != null)
        //         {
        //             ht["fg"] = _previous["fg"];
        //             _previous["fg"] = null;
        //         }
        //         if ((Color)ht["bg"] == Color.Default && _previous["bg"] != null)
        //         {
        //             ht["bg"] = _previous["bg"];
        //             _previous["bg"] = null;
        //         }
        //         if ((Decoration)ht["decoration"] == Decoration.None && _previous["decoration"] != null)
        //         {
        //             ht["decoration"] = _previous["decoration"];
        //             _previous["decoration"] = null;
        //         }
        //         Color fgColor = (Color)ht["fg"];
        //         Color bgColor = (Color)ht["bg"];
        //         if ((Decoration)ht["decoration"] != Decoration.None)
        //         {
        //             sb.Append($"[{(Decoration)ht["decoration"]} {fgColor.ToMarkup()} on {bgColor.ToMarkup()}]{(string)ht["String"]}[/]");
        //         }
        //         else
        //         {
        //             sb.Append($"[{fgColor.ToMarkup()} on {bgColor.ToMarkup()}]{(string)ht["String"]}[/]");
        //         }
        //         _previous.Clear();
        //     }
        //     if (AsString)
        //     {
        //         return sb.ToString();
        //     }
        //     return new Markup(sb.ToString());
        // }
        public static List<VtObject> MultiVT(string text)
        {
            string[] substrings = Escapes.Split(text);
            List<VtObject> vtObjects = new List<VtObject>();
            int cleanIndex = 0;
            StringBuilder currentEscapeSequence = new StringBuilder();
            for (int i = 0; i < substrings.Length; i++)
            {
                string substring = substrings[i];
                if (Escapes.IsMatch(substring))
                {
                    currentEscapeSequence.Append(substring);
                }
                else
                {
                    if (!string.IsNullOrEmpty(substring))
                    {
                        List<IVT> EscapeSequence = Decoder.Parse(currentEscapeSequence.ToString());
                        VtObject multiVTObject = new VtObject
                        {
                            Index = cleanIndex,
                            Length = substring.Length,
                            Text = substring,
                            EscapeSequence = EscapeSequence,
                            Mapped = Transform.Map(EscapeSequence)
                        };
                        vtObjects.Add(multiVTObject);
                        cleanIndex += substring.Length;
                        currentEscapeSequence.Clear();
                    }
                }
            }
            return vtObjects;
        }
        public static object FromVTToSpectre(string text, bool AsString = false)
        {
            List<VtObject> vtObjects = MultiVT(text);
            StringBuilder sb = new StringBuilder();
            foreach (VtObject vtObject in vtObjects)
            {
                Hashtable ht = vtObject.Mapped;
                Color fgColor = (Color)ht["fg"];
                Color bgColor = (Color)ht["bg"];
                Decoration? decoration = ht["decoration"] is null ? (Decoration?)null : (Decoration)ht["decoration"];
                if (fgColor == Color.Default && bgColor == Color.Default && decoration == Decoration.None)
                {
                    // [Markup]::new($String, [Style]::new($ht.fg, $ht.bg, $ht.decoration))
                    // sb.Append(vtObject.Text);
                    _markup = new Markup(vtObject.Text, new Style(fgColor, bgColor, decoration));
                    sb.append(_markup.ToMarkUp());
                    // dont inject `e]0m into the string.
                    continue;
                }
                if (decoration != null && decoration != Decoration.None)
                {
                    // decoration is set to something other than None.
                    // sb.Append($"[{decoration} {fgColor.ToMarkup()} on {bgColor.ToMarkup()}]{vtObject.Text}[/]");
                    _markup = new Markup(vtObject.Text, new Style(fgColor, bgColor, decoration));
                    sb.append(_markup.ToMarkUp());
                }
                else
                {
                    // no decoration is set.
                    // sb.Append($"[{fgColor.ToMarkup()} on {bgColor.ToMarkup()}]{vtObject.Text}[/]");
                    _markup = new Markup(vtObject.Text, new Style(fgColor, bgColor));
                    sb.append(_markup.ToMarkUp());
                }
            }
            if (AsString)
            {
                return sb.ToString();
            }
            return new Markup(sb.ToString());
        }

    }
}
