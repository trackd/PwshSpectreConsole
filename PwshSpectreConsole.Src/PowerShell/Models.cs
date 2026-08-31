using System.Collections;
using Spectre.Console;
using Spectre.Console.Rendering;

namespace PwshSpectreConsole;

/// <summary>
/// Represents an item displayed by a Spectre chart.
/// </summary>
public sealed class SpectreChartItem {
    public string Label { get; set; }
    public double Value { get; set; }
    public Color Color { get; set; }

    public SpectreChartItem(string label, double value, Color color) {
        Label = label;
        Value = value;
        Color = color;
    }
}

/// <summary>
/// Represents a row that can be added to a Spectre grid.
/// </summary>
public sealed class SpectreGridRow {
    private readonly Renderable[] _internalColumns;

    public SpectreGridRow(object? columns)
        : this(PowerShell.RenderableUtilities.AsObjectSequence(columns)) {
    }

    public SpectreGridRow(IEnumerable columns) {
        ArgumentNullException.ThrowIfNull(columns);
        _internalColumns = columns.Cast<object?>()
            .Select(PowerShell.RenderableUtilities.ToSingleRenderable)
            .ToArray();
    }

    public int Count() => _internalColumns.Length;

    public GridRow ToGridRow() => new(_internalColumns);
}
