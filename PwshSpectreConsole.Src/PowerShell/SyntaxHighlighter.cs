using System.Management.Automation.Language;

namespace PwshSpectreConsole.PowerShell;

public static class SyntaxHighlighter {
    private const string Reset = "\u001b[0m";

    private static readonly Dictionary<string, Theme> Themes = new(StringComparer.OrdinalIgnoreCase) {
        ["Github"] = new(
            Function: new Rgb(255, 123, 114), Generic: new Rgb(199, 159, 252), String: new Rgb(143, 185, 221),
            Variable: new Rgb(255, 255, 255), Identifier: new Rgb(110, 174, 231), Number: new Rgb(255, 255, 255),
            Keyword: new Rgb(255, 123, 114), Default: new Rgb(200, 200, 200), Foreground: new Rgb(102, 102, 102),
            Background: new Rgb(35, 35, 35), Highlight: new Rgb(231, 72, 86)),
        ["Matrix"] = new(
            Function: new Rgb(255, 255, 255), Generic: new Rgb(113, 255, 96), String: new Rgb(202, 255, 194),
            Variable: new Rgb(200, 255, 200), Identifier: new Rgb(131, 193, 26), Number: new Rgb(255, 255, 255),
            Keyword: new Rgb(40, 220, 20), Default: new Rgb(0, 120, 0), Foreground: new Rgb(102, 190, 102),
            Background: new Rgb(15, 45, 15), Highlight: new Rgb(255, 221, 0))
    };

    public static void WriteHeader(string language, int windowWidth) {
        language ??= "pwsh";
        int padding = Math.Max(0, windowWidth - language.Length);
        var original = System.Console.ForegroundColor;
        try {
            System.Console.ForegroundColor = ConsoleColor.DarkGray;
            System.Console.WriteLine(new string(' ', padding) + language);
        }
        finally {
            System.Console.ForegroundColor = original;
        }
    }

    public static void WriteCodeblock(
        string text,
        bool showLineNumbers,
        bool syntaxHighlight,
        IEnumerable<IScriptExtent>? highlightExtents,
        IEnumerable<int>? highlightLines,
        string themeName,
        int windowWidth) {
        ArgumentNullException.ThrowIfNull(text);
        if (!Themes.TryGetValue(themeName, out Theme? theme)) {
            throw new ArgumentException("Theme must be either 'Github' or 'Matrix'.", nameof(themeName));
        }

        string[] lines = text.Split('\n');
        int gutterSize = showLineNumbers ? lines.Length.ToString(CultureInfo.InvariantCulture).Length + 1 : 0;
        int codeWidth = Math.Max(1, windowWidth - gutterSize);
        Token[] parsedTokens;
        _ = Parser.ParseInput(text, out parsedTokens, out _);
        ILookup<int, DisplayToken> lineTokens = ExpandTokens(parsedTokens)
            .Where(token => !string.IsNullOrWhiteSpace(token.Text))
            .ToLookup(token => token.Line);
        ILookup<int, IScriptExtent> lineExtents = (highlightExtents ?? [])
            .ToLookup(extent => extent.StartLineNumber);
        var highlightedLines = new HashSet<int>(highlightLines ?? []);

        bool initialCursorVisible = true;
        try {
            if (OperatingSystem.IsWindows()) initialCursorVisible = System.Console.CursorVisible;
            System.Console.CursorVisible = false;
            for (int index = 0; index < lines.Length; index++) {
                int lineNumber = index + 1;
                string line = lines[index].TrimEnd('\r');
                string gutter = showLineNumbers ? lineNumber.ToString(CultureInfo.InvariantCulture).PadLeft(gutterSize - 1) + " " : string.Empty;
                int wrappedLineCount = Math.Max(1, (int)Math.Ceiling(line.Length / (double)codeWidth));
                string background = theme.Foreground.ForegroundEscape + gutter + theme.Background.BackgroundEscape + new string(' ', codeWidth) + Reset;
                System.Console.WriteLine(background + string.Concat(Enumerable.Repeat(new string(' ', gutterSize) + theme.Background.BackgroundEscape + new string(' ', codeWidth) + Reset, wrappedLineCount - 1)));
                int terminalLine = System.Console.CursorTop - wrappedLineCount;
                bool highlightLine = highlightedLines.Contains(lineNumber);

                foreach (DisplayToken token in lineTokens[lineNumber]) {
                    WriteToken(token.Text, token.Column, terminalLine, gutterSize, codeWidth,
                        highlightLine ? theme.Highlight : GetTokenColor(token.Kind, token.Flags, theme), theme.Background);
                }
                foreach (IScriptExtent extent in lineExtents[lineNumber]) {
                    WriteToken(extent.Text, extent.StartColumnNumber, terminalLine, gutterSize, codeWidth, theme.Highlight, theme.Background);
                }
            }
        }
        finally {
            System.Console.CursorVisible = initialCursorVisible;
        }
    }

    private static IEnumerable<DisplayToken> ExpandTokens(IEnumerable<Token>? tokens) {
        if (tokens is null) yield break;
        foreach (Token token in tokens) {
            string[] tokenLines = token.Text.Split('\n');
            for (int index = 0; index < tokenLines.Length; index++) {
                yield return new DisplayToken(tokenLines[index], token.Extent.StartLineNumber + index,
                    index == 0 ? token.Extent.StartColumnNumber : 1, token.Kind, token.TokenFlags);
            }
            if (token is StringExpandableToken expandable) {
                foreach (DisplayToken nested in ExpandTokens(expandable.NestedTokens)) yield return nested;
            }
        }
    }

    private static Rgb GetTokenColor(TokenKind kind, TokenFlags flags, Theme theme) {
        string flagText = flags.ToString();
        if (flagText.Contains("operator", StringComparison.OrdinalIgnoreCase)
            || flagText.Contains("keyword", StringComparison.OrdinalIgnoreCase)) return theme.Keyword;
        return kind switch {
            TokenKind.Function => theme.Function,
            TokenKind.Generic => theme.Generic,
            TokenKind.StringExpandable or TokenKind.StringLiteral or TokenKind.HereStringExpandable or TokenKind.HereStringLiteral => theme.String,
            TokenKind.Variable or TokenKind.SplattedVariable => theme.Variable,
            TokenKind.Identifier => theme.Identifier,
            TokenKind.Number => theme.Number,
            _ => theme.Default
        };
    }

    private static void WriteToken(string text, int column, int terminalLine, int gutterSize, int consoleWidth, Rgb foreground, Rgb background) {
        if (string.IsNullOrEmpty(text)) return;
        int columnIndex = Math.Max(0, column - 1);
        int wrappedLine = columnIndex / consoleWidth;
        int x = (columnIndex % consoleWidth) + gutterSize;
        int offset = 0;
        while (offset < text.Length) {
            int available = offset == 0 ? consoleWidth - (x - gutterSize) : consoleWidth;
            int length = Math.Min(available, text.Length - offset);
            System.Console.SetCursorPosition(offset == 0 ? x : gutterSize, terminalLine + wrappedLine);
            System.Console.Write(foreground.ForegroundEscape);
            System.Console.Write(background.BackgroundEscape);
            System.Console.Out.Write(text.AsSpan(offset, length));
            System.Console.Write(Reset);
            offset += length;
            wrappedLine++;
        }
        System.Console.SetCursorPosition(0, Math.Max(System.Console.CursorTop, terminalLine + wrappedLine));
    }

    private sealed record Theme(Rgb Function, Rgb Generic, Rgb String, Rgb Variable, Rgb Identifier, Rgb Number,
        Rgb Keyword, Rgb Default, Rgb Foreground, Rgb Background, Rgb Highlight);
    private sealed record DisplayToken(string Text, int Line, int Column, TokenKind Kind, TokenFlags Flags);
    private readonly record struct Rgb(byte R, byte G, byte B) {
        public string ForegroundEscape => $"\u001b[38;2;{R};{G};{B}m";
        public string BackgroundEscape => $"\u001b[48;2;{R};{G};{B}m";
    }
}
