using System.Collections;
using System.Collections.Specialized;
using System.Management.Automation;
using Spectre.Console;
using Spectre.Console.Rendering;

namespace PwshSpectreConsole.PowerShell;

public static class TableUtilities {
    private const string RenderablePrefix = "RENDERABLE__";

    public static PSObject ConvertHashtableToRenderSafePSObject(IDictionary input, IDictionary renderables) {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(renderables);
        var result = new PSObject();

        foreach (DictionaryEntry item in input) {
            object? value = item.Value;
            if (value is IDictionary nested) {
                value = ConvertHashtableToRenderSafePSObject(nested, renderables);
            }
            else if (value is Renderable renderable) {
                string key = $"{RenderablePrefix}{Guid.NewGuid():D}";
                renderables[key] = renderable;
                value = key;
            }

            result.Properties.Add(new PSNoteProperty(item.Key.ToString()!, value));
        }

        return result;
    }

    public static OrderedDictionary? GetHeader(object formatStartData) {
        ArgumentNullException.ThrowIfNull(formatStartData);
        object baseObject = formatStartData is PSObject wrapper ? wrapper.BaseObject : formatStartData;
        if (!string.Equals(baseObject.GetType().Name, "FormatStartData", StringComparison.Ordinal)) {
            return null;
        }

        object? shapeInfo = GetProperty(formatStartData, "shapeinfo");
        object? columnList = GetProperty(shapeInfo, "tablecolumninfolist");
        if (columnList is null) return null;

        var properties = new OrderedDictionary(StringComparer.OrdinalIgnoreCase);
        foreach (object column in RenderableUtilities.AsObjectSequence(columnList)) {
            string? label = GetProperty(column, "Label")?.ToString();
            string? propertyName = GetProperty(column, "propertyName")?.ToString();
            string name = string.IsNullOrEmpty(label) ? propertyName ?? string.Empty : label;
            int width = LanguagePrimitives.ConvertTo<int>(GetProperty(column, "width"));

            properties[name] = new Hashtable(StringComparer.OrdinalIgnoreCase) {
                ["Label"] = name,
                ["Width"] = width,
                // The PowerShell implementation compared the formatter's internal enum
                // directly with integer hashtable keys, so generated columns retained
                // Spectre's default (left) alignment.
                ["Alignment"] = "undefined",
                ["HeaderMatchesProperty"] = GetProperty(column, "HeaderMatchesProperty")
            };
        }

        return properties.Count == 0 ? null : properties;
    }

    public static Table AddColumns(
        Table table,
        OrderedDictionary? formatData,
        string? title,
        Color color,
        bool scalar,
        bool wrap) {
        ArgumentNullException.ThrowIfNull(table);
        if (scalar) {
            _ = table.AddColumn($"[{color.ToMarkup()}]{(string.IsNullOrEmpty(title) ? "Value" : title)}[/]");
            TableColumn column = table.Columns[^1];
            column.NoWrap = !wrap;
            return table;
        }

        if (formatData is null) return table;
        foreach (DictionaryEntry entry in formatData) {
            object lookup = entry.Value!;
            string label = GetProperty(lookup, "Label")?.ToString() ?? string.Empty;
            _ = table.AddColumn($"[{color.ToMarkup()}]{label}[/]");
            TableColumn column = table.Columns[^1];
            column.Padding = new Padding(1, 0, 1, 0);
            int width = LanguagePrimitives.ConvertTo<int>(GetProperty(lookup, "Width"));
            if (width > 0) column.Width = width;
            string alignment = GetProperty(lookup, "Alignment")?.ToString() ?? "undefined";
            if (!string.Equals(alignment, "undefined", StringComparison.OrdinalIgnoreCase)
                && Enum.TryParse(alignment, true, out Justify justify)) {
                column.Alignment = justify;
            }
            column.NoWrap = !wrap;
        }

        return table;
    }

    public static Renderable NewCell(object? cellData, Color color, bool allowMarkup) {
        if (cellData is Renderable renderable) return renderable;
        string text = cellData?.ToString() ?? string.Empty;
        if (string.IsNullOrEmpty(text)) text = " ";
        Style style = new(color);
        return allowMarkup ? new Markup(text, style) : new Text(text, style);
    }

    public static Renderable[] NewRow(object entry, Color color, bool allowMarkup, bool scalar, IDictionary renderables) {
        ArgumentNullException.ThrowIfNull(entry);
        ArgumentNullException.ThrowIfNull(renderables);
        if (scalar) {
            object value = ResolveRenderable(entry, renderables);
            return [NewCell(value, color, allowMarkup)];
        }

        var rows = new List<Renderable>();
        foreach (object cellValue in RenderableUtilities.AsObjectSequence(entry)) {
            if (string.IsNullOrEmpty(cellValue?.ToString())) {
                rows.Add(NewCell(null, color, allowMarkup));
                continue;
            }

            string cellText = cellValue.ToString()!;
            if (cellText.Contains('\x1b')) {
                SpanParagraph? paragraph = VTParser.ToSpanParagraph(cellText);
                if (paragraph is not null) {
                    paragraph.SingleLineOverride = true;
                    rows.Add(paragraph);
                }
                continue;
            }

            rows.Add(NewCell(ResolveRenderable(cellValue, renderables), color, allowMarkup));
        }

        return rows.ToArray();
    }

    private static object ResolveRenderable(object value, IDictionary renderables) {
        string name = value.ToString() ?? string.Empty;
        return name.StartsWith(RenderablePrefix, StringComparison.Ordinal) && renderables.Contains(name)
            ? renderables[name]!
            : value;
    }

    private static object? GetProperty(object? value, string name) {
        if (value is null) return null;
        if (value is IDictionary dictionary && dictionary.Contains(name)) return dictionary[name];
        return PSObject.AsPSObject(value).Properties[name]?.Value;
    }
}
