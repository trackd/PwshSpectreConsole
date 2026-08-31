using System.Collections;

namespace PwshSpectreConsole.PowerShell;

public static class StyleUtilities {
    public static string[] MergeDefaults(IDictionary userStyle, IDictionary defaultStyle) {
        ArgumentNullException.ThrowIfNull(userStyle);
        ArgumentNullException.ThrowIfNull(defaultStyle);

        string[] invalidKeys = userStyle.Keys.Cast<object>()
            .Where(key => !defaultStyle.Contains(key))
            .Select(key => key.ToString() ?? string.Empty)
            .ToArray();

        foreach (DictionaryEntry entry in defaultStyle) {
            if (!userStyle.Contains(entry.Key)) {
                userStyle[entry.Key] = entry.Value;
            }
        }

        return invalidKeys;
    }
}
