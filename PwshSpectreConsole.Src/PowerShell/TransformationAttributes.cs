using System.Collections;
using System.Management.Automation;
using Spectre.Console;
using Spectre.Console.Rendering;

namespace PwshSpectreConsole;

public sealed class ColorTransformationAttribute : ArgumentTransformationAttribute {
    public static object TransformItem(object inputData)
        => PowerShell.ColorUtilities.ToColor(inputData);

    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
        => TransformItem(inputData);
}

public sealed class StyleTransformationAttribute : ArgumentTransformationAttribute {
    public static object TransformItem(object inputData) {
        return inputData switch {
            Style style => style,
            Color color => new Style(color),
            string value => Style.Parse(value),
            _ => throw new ArgumentException($"Cannot convert {inputData.GetType().FullName} '{inputData}' to [Spectre.Console.Style]")
        };
    }

    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
        => TransformItem(inputData);
}

public sealed class TreeItemTransformationAttribute : ArgumentTransformationAttribute {
    public static object TransformItem(object treeItem)
        => PowerShell.TreeUtilities.TransformTreeItem(treeItem);

    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
        => TransformItem(inputData);
}

public sealed class ColorThemeTransformationAttribute : ArgumentTransformationAttribute {
    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData) {
        if (inputData is not Hashtable input) {
            throw new ArgumentException("Color theme must be a hashtable of Spectre Console color names and values");
        }

        var output = new Hashtable(StringComparer.OrdinalIgnoreCase);
        foreach (DictionaryEntry entry in input) {
            output[entry.Key] = StyleTransformationAttribute.TransformItem(entry.Value!);
        }

        return output;
    }
}

public sealed class RenderableTransformationAttribute : ArgumentTransformationAttribute {
    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
        => PowerShell.RenderableUtilities.Transform(inputData);
}

public sealed class ChartItemTransformationAttribute : ArgumentTransformationAttribute {
    public static SpectreChartItem TransformItem(object inputData) {
        if (inputData is SpectreChartItem item) {
            return item;
        }

        if (inputData is Hashtable hashtable) {
            if (hashtable.ContainsKey("Label") && hashtable.ContainsKey("Value") && hashtable.ContainsKey("Color")) {
                return CreateItem(hashtable["Label"], hashtable["Value"], hashtable["Color"]);
            }

            throw new ArgumentException("Hashtable must contain 'Label', 'Value', and 'Color' keys to be converted to a [SpectreChartItem]");
        }

        PSObject psObject = PSObject.AsPSObject(inputData);
        if (psObject.Properties["Label"] is not null && psObject.Properties["Value"] is not null && psObject.Properties["Color"] is not null) {
            return CreateItem(psObject.Properties["Label"].Value, psObject.Properties["Value"].Value, psObject.Properties["Color"].Value);
        }

        if (inputData is PSCustomObject) {
            throw new ArgumentException("PSCustomObject must contain 'Label', 'Value', and 'Color' properties to be converted to a [SpectreChartItem]");
        }

        throw new ArgumentException($"Cannot convert {inputData.GetType().FullName} to [SpectreChartItem]. Expected a hashtable or PSCustomObject with 'Label', 'Value', and 'Color' properties.");
    }

    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
        => PowerShell.RenderableUtilities.AsObjectSequence(inputData)
            .Select(TransformItem)
            .ToArray();

    private static SpectreChartItem CreateItem(object? label, object? value, object? color) {
        string itemLabel = LanguagePrimitives.ConvertTo<string>(label);
        double itemValue = LanguagePrimitives.ConvertTo<double>(value);
        Color itemColor = (Color)ColorTransformationAttribute.TransformItem(color!);
        return new SpectreChartItem(itemLabel, itemValue, itemColor);
    }
}

public sealed class GridRowTransformationAttribute : ArgumentTransformationAttribute {
    public static SpectreGridRow TransformItem(object inputData) {
        object value = inputData is PSObject psObject ? psObject.BaseObject : inputData;
        return value as SpectreGridRow ?? new SpectreGridRow(value);
    }

    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
        => PowerShell.RenderableUtilities.AsObjectSequence(inputData)
            .Select(TransformItem)
            .ToArray();
}
