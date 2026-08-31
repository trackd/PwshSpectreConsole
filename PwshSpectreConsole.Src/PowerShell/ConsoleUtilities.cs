using System.Collections;
using System.Management.Automation;
using Spectre.Console;
using Spectre.Console.Rendering;

namespace PwshSpectreConsole.PowerShell;

public static class ConsoleUtilities {
    private static readonly StringWriter Writer = new(CultureInfo.InvariantCulture);
    private static readonly IAnsiConsole RenderConsole = CreateRenderConsole();

    public static Func<IRenderable, bool, bool, int, string?>? RenderOverride { get; set; }
    public static Func<IRenderable, int, bool, string?>? RenderWithWidthOverride { get; set; }
    public static Func<int>? GetHostWidthOverride { get; set; }
    public static Func<string?, Justify, bool, bool, object?>? WriteMarkupOverride { get; set; }
    public static Action? ClearInputQueueOverride { get; set; }
    public static Func<ConsoleKeyInfo>? ReadKeyOverride { get; set; }
    public static IRenderable? LastRenderable { get; private set; }
    public static int RenderCallCount { get; private set; }
    public static int? LastRenderWidth { get; private set; }
    public static int ReadKeyCallCount { get; private set; }
    public static int WriteMarkupCallCount { get; private set; }
    public static string? LastMarkupMessage { get; private set; }

    public static int GetHostWidth() => GetHostWidthOverride?.Invoke() ?? AnsiConsole.Profile.Width;

    public static int GetHostHeight() {
        try {
            return System.Console.WindowHeight;
        }
        catch (IOException) {
            return 0;
        }
    }

    public static void EnsureDimensions(int defaultWidth = 80, int defaultHeight = 24) {
        if (AnsiConsole.Console.Profile.Width <= 0) AnsiConsole.Console.Profile.Width = defaultWidth;
        if (AnsiConsole.Console.Profile.Height <= 0) AnsiConsole.Console.Profile.Height = defaultHeight;
    }

    public static string? Render(IRenderable renderable, bool recording, bool customItemFormatter, int bufferWidth) {
        ArgumentNullException.ThrowIfNull(renderable);
        LastRenderable = renderable;
        RenderCallCount++;
        if (RenderOverride is not null) return RenderOverride(renderable, recording, customItemFormatter, bufferWidth);
        if (recording) {
            AnsiConsole.Write(renderable);
            return null;
        }

        RenderConsole.Profile.Width = Math.Max(1, bufferWidth - (customItemFormatter ? 1 : 0));
        RenderConsole.Write(renderable);
        string output = Writer.ToString().TrimEnd();
        _ = Writer.GetStringBuilder().Clear();
        return output;
    }

    public static string? RenderWithWidth(IRenderable renderable, int maxWidth, bool recording) {
        ArgumentNullException.ThrowIfNull(renderable);
        ArgumentOutOfRangeException.ThrowIfLessThan(maxWidth, 1);
        LastRenderable = renderable;
        LastRenderWidth = maxWidth;
        RenderCallCount++;
        if (RenderWithWidthOverride is not null) return RenderWithWidthOverride(renderable, maxWidth, recording);
        if (recording) {
            int originalRecordingWidth = AnsiConsole.Console.Profile.Width;
            try {
                AnsiConsole.Console.Profile.Width = maxWidth;
                AnsiConsole.Write(renderable);
            }
            finally {
                AnsiConsole.Console.Profile.Width = originalRecordingWidth;
            }
            return null;
        }

        int originalWidth = RenderConsole.Profile.Width;
        try {
            RenderConsole.Profile.Width = maxWidth;
            RenderConsole.Write(renderable);
            string output = Writer.ToString().TrimEnd();
            _ = Writer.GetStringBuilder().Clear();
            return output;
        }
        finally {
            RenderConsole.Profile.Width = originalWidth;
        }
    }

    public static bool RequiresDirectHostOutput(string? output, bool customItemFormatter)
        => customItemFormatter && output is not null
            && (output.Contains("P0;1q", StringComparison.Ordinal) || output.Contains("]8;id=", StringComparison.Ordinal));

    public static object? WriteMarkup(string? message, Justify justify, bool noNewline, bool passThru) {
        WriteMarkupCallCount++;
        LastMarkupMessage = message;
        if (WriteMarkupOverride is not null) return WriteMarkupOverride(message, justify, noNewline, passThru);
        message ??= string.Empty;
        if (message.Length == 0) message = " ";
        if (!passThru && !noNewline) message += Environment.NewLine;
        var markup = new Markup(message) { Justification = justify };
        if (passThru) return markup;
        AnsiConsole.Write(markup);
        return null;
    }

    public static FigletFont ReadFigletFont(string? path) {
        if (string.IsNullOrEmpty(path)) return FigletFont.Default;
        string fullPath = Path.GetFullPath(path);
        if (!File.Exists(fullPath)) {
            throw new FileNotFoundException($"The specified Figlet font file '{path}' does not exist", path);
        }
        return FigletFont.Load(fullPath);
    }

    public static bool IsScalar(object? value) {
        if (value is null) return false;
        if (value is string || value.GetType().IsValueType) return true;
        IEnumerator? enumerator = LanguagePrimitives.GetEnumerator(value);
        if (enumerator is null || !enumerator.MoveNext()) return false;
        object? first = enumerator.Current;
        return first is string || first?.GetType().IsValueType == true;
    }

    public static void ClearInputQueue() {
        if (ClearInputQueueOverride is not null) {
            ClearInputQueueOverride();
            return;
        }
        while (System.Console.KeyAvailable) _ = System.Console.ReadKey(true);
    }

    public static ConsoleKeyInfo ReadKey() {
        ReadKeyCallCount++;
        return ReadKeyOverride is null ? System.Console.ReadKey(true) : ReadKeyOverride();
    }

    public static void SetCursorPosition(int x, int y) => System.Console.SetCursorPosition(x, y);

    public static bool TerminalSupportsSixel() {
        try {
            return Compatibility.TerminalSupportsSixel();
        }
        catch (Exception) {
            return false;
        }
    }

    public static void ResetTestHooks() {
        RenderOverride = null;
        RenderWithWidthOverride = null;
        GetHostWidthOverride = null;
        WriteMarkupOverride = null;
        ClearInputQueueOverride = null;
        ReadKeyOverride = null;
        LastRenderable = null;
        RenderCallCount = 0;
        LastRenderWidth = null;
        ReadKeyCallCount = 0;
        WriteMarkupCallCount = 0;
        LastMarkupMessage = null;
    }

    private static IAnsiConsole CreateRenderConsole() {
        var settings = new AnsiConsoleSettings { Out = new AnsiConsoleOutput(Writer) };
        return AnsiConsole.Create(settings);
    }
}
