using System.Collections;
using System.Management.Automation;
using Spectre.Console;
using Spectre.Console.Rendering;

namespace PwshSpectreConsole.PowerShell;

public static class RenderableUtilities {
    public static object Transform(object inputData) {
        ArgumentNullException.ThrowIfNull(inputData);
        inputData = Unwrap(inputData) ?? throw new ArgumentNullException(nameof(inputData));
        string typeName = inputData.GetType().FullName ?? string.Empty;
        if (typeName.Contains("Internal.Format", StringComparison.Ordinal)) {
            throw new ArgumentException("Cannot convert PowerShell Format data to be Spectre Console compatible. This object has likely already been formatted with a Format-* cmdlet.");
        }

        if (inputData is IRenderable) {
            return inputData;
        }

        string text = ToPowerShellString(inputData);
        if (LooksLikeMarkup(text)) {
            try {
                return new Markup(text);
            }
            catch (Exception exception) when (exception is InvalidOperationException or ArgumentException) {
                throw new ArgumentException(string.Join(Environment.NewLine, [
                    string.Empty,
                    string.Empty,
                    "Your input includes Spectre Console markup characters (see https://spectreconsole.net/markup).",
                    "Escape the special characters in the input before using it in a Spectre Console function using the Get-SpectreEscapedText function.",
                    string.Empty,
                    $"  e.g. $myEscapedInput = Get-SpectreEscapedText '{text}'",
                    string.Empty
                ]), exception);
            }
        }

        return new Text(text);
    }

    public static Renderable[] ToRenderables(object? inputData) {
        if (inputData is object[] array) {
            return array.SelectMany(ToRenderables).ToArray();
        }

        return [ToSingleRenderable(inputData)];
    }

    public static Renderable ToSingleRenderable(object? inputData) {
        inputData = Unwrap(inputData);
        if (inputData is Renderable renderable) {
            return renderable;
        }

        string text = ToPowerShellString(inputData).TrimEnd();
        return text.Contains("[/]", StringComparison.Ordinal)
            ? new Markup(text)
            : new Text(text);
    }

    public static IEnumerable<object> AsObjectSequence(object? inputData) {
        if (inputData is null) {
            yield break;
        }

        IEnumerator? enumerator = LanguagePrimitives.GetEnumerator(inputData);
        if (enumerator is null) {
            yield return inputData;
            yield break;
        }

        while (enumerator.MoveNext()) {
            if (enumerator.Current is not null) {
                yield return enumerator.Current;
            }
        }
    }

    private static bool LooksLikeMarkup(string value)
        => value.Contains("[/]", StringComparison.Ordinal) || value.Count(character => character == ':') >= 2;

    private static string ToPowerShellString(object? value) {
        if (value is null) return string.Empty;
        return value switch {
            string text => text,
            PSObject psObject => psObject.ToString(),
            _ => value.ToString() ?? string.Empty
        };
    }

    private static object? Unwrap(object? value)
        => value is PSObject psObject ? psObject.BaseObject : value;
}
