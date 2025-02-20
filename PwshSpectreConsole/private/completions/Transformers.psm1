using module "..\models\SpectreChartItem.psm1"
using module "..\models\SpectreGridRow.psm1"
using namespace System.Management.Automation

class ColorTransformationAttribute : ArgumentTransformationAttribute {

    static [object] TransformItem([object]$inputData) {
        if ($InputData -is [Spectre.Console.Color]) {
            return $InputData
        }
        if ($InputData.StartsWith('#')) {
            $hexBytes = [System.Convert]::FromHexString($InputData.Substring(1))
            return [Spectre.Console.Color]::new($hexBytes[0], $hexBytes[1], $hexBytes[2])
        }
        if ($InputData -is [String]) {
            return [Spectre.Console.Color]::$InputData
        }
        throw [System.ArgumentException]::new("Cannot convert $($inputData.GetType().FullName) '$InputData' to [Spectre.Console.Color]")
    }

    [object] Transform([EngineIntrinsics]$engine, [object]$inputData) {
        return [ColorTransformationAttribute]::TransformItem($inputData)
    }
}

class TreeItemTransformationAttribute : ArgumentTransformationAttribute {

    static[object] TransformItem([object] $TreeItem) {
        $TransformedTreeItem = @{}

        if ($TreeItem -isnot [hashtable]) {
            throw "Input for Spectre Tree must be a hashtable with 'Value' (and the optional 'Children') keys"
        }

        if ($TreeItem.Keys -notcontains "Value" -and $TreeItem.Keys -notcontains "Label") {
            throw "Input for Spectre Tree must be a hashtable with 'Value' (and the optional 'Children') keys"
        }

        if ($TreeItem.Keys -contains "Value") {
            $TransformedTreeItem["Value"] = $TreeItem.Value
        } else {
            $TransformedTreeItem["Value"] = $TreeItem.Label
        }

        if ($null -eq $TransformedTreeItem["Value"]) {
            throw "Spectre tree value cannot be null"
        }

        $TransformedTreeItem["Children"] = @()

        if ($TreeItem.Keys -contains "Children") {
            if ($TreeItem.Children -isnot [array]) {
                throw "Children must be an array of tree items (hashtables with 'Value' and 'Children' keys)"
            }
            foreach ($child in $TreeItem.Children) {
                $TransformedTreeItem["Children"] += [TreeItemTransformationAttribute]::TransformItem($child)
            }
        }

        return $TransformedTreeItem
    }

    [object] Transform([EngineIntrinsics]$engine, [object]$inputData) {
        return [TreeItemTransformationAttribute]::TransformItem($inputData)
    }
}

class ColorThemeTransformationAttribute : ArgumentTransformationAttribute {
    [object] Transform([EngineIntrinsics]$engine, [object]$inputData) {
        if ($inputData -isnot [hashtable]) {
            throw "Color theme must be a hashtable of Spectre Console color names and values"
        }
        $outputData = @{}
        foreach ($color in $inputData.GetEnumerator()) {
            $colorValue = [ColorTransformationAttribute]::TransformItem($color.Value)
            if ($null -ne $colorValue) {
                $outputData[$color.Key] = $colorValue
            } else {
                $spectreColors = [Spectre.Console.Color] | Get-Member -Static -Type Properties | Select-Object -ExpandProperty Name
                throw "Invalid color value '$($color.Value)' for key '$($color.Key)' could not be mapped to one of the list of valid Spectre colors ['$($spectreColors -join ''', ''')']"
            }
        }
        return $outputData
    }
}

class RenderableTransformationAttribute : ArgumentTransformationAttribute {
    [object] Transform([EngineIntrinsics]$engine, [object]$inputData) {
        # Converting data from a Format-* cmdlet to a Spectre Console object is not supported as it's already formatted for console output by the default host
        if ($InputData.GetType().FullName -like "*Internal.Format*") {
            throw "Cannot convert PowerShell Format data to be Spectre Console compatible. This object has likely already been formatted with a Format-* cmdlet."
        }

        # These objects are already renderable
        if ($InputData -is [Spectre.Console.Rendering.Renderable]) {
            return $InputData
        }

        # Some stuff isn't a direct descendant of Renderable but can be rendered
        if ($InputData.GetType().GetInterfaces() | Select-Object -ExpandProperty Name | Where-Object { $_ -eq "IRenderable" }) {
            return $InputData
        }

        # For others just dump them as either strings formatted with markup which are easy to identify by the closing tag [/] or as plain text
        if ($InputData -like "*[/]*" -or $InputData -like "*:*:*") {
            try {
                $markup = [Spectre.Console.Markup]::new($InputData)
                return $markup
            } catch {
                throw @(
                    "`n`nYour input includes Spectre Console markup characters (see https://spectreconsole.net/markup).",
                    "Escape the special characters in the input before using it in a Spectre Console function using the Get-SpectreEscapedText function.",
                    "",
                    "  e.g. `$myEscapedInput = Get-SpectreEscapedText '$InputData'",
                    "`n"
                ) -join "`n"
            }
        } else {
            return [Spectre.Console.Text]::new(($InputData | Out-String -NoNewline))
        }
    }
}

class ChartItemTransformationAttribute : ArgumentTransformationAttribute {

    static [object] TransformItem([object]$inputData) {
        # These objects are already renderable
        if ($InputData -is [SpectreChartItem]) {
            return $InputData
        }

        if ($inputData -is [hashtable]) {
            if ($inputData.Keys -contains "Label" -and $inputData.Keys -contains "Value" -and $inputData.Keys -contains "Color") {
                return [SpectreChartItem]::new($inputData.Label, $inputData.Value, $inputData.Color)
            }
            throw "Hashtable must contain 'Label', 'Value', and 'Color' keys to be converted to a [SpectreChartItem]"
        }

        if ($inputData -is [PSCustomObject]) {
            if ($inputData.PSObject.Properties.Name -contains "Label" -and $inputData.PSObject.Properties.Name -contains "Value" -and $inputData.PSObject.Properties.Name -contains "Color") {
                return [SpectreChartItem]::new($inputData.Label, $inputData.Value, $inputData.Color)
            }
            throw "PSCustomObject must contain 'Label', 'Value', and 'Color' properties to be converted to a [SpectreChartItem]"
        }

        throw "Cannot convert $($inputData.GetType().FullName) to [SpectreChartItem]. Expected a hashtable or PSCustomObject with 'Label', 'Value', and 'Color' properties."
    }

    [object] Transform([EngineIntrinsics]$engine, [object]$inputData) {
        $outputData = @()
        foreach ($dataItem in $inputData) {
            $outputData += [ChartItemTransformationAttribute]::TransformItem($dataItem)
        }
        return $outputData
    }
}

class GridRowTransformationAttribute : ArgumentTransformationAttribute {

    static [object] TransformItem([object]$inputData) {
        # These objects are already renderable
        if ($InputData -is [SpectreGridRow]) {
            return $InputData
        }

        return [SpectreGridRow]::new($inputData)
    }

    [object] Transform([EngineIntrinsics]$engine, [object]$inputData) {
        $outputData = @()
        foreach ($dataItem in $inputData) {
            $outputData += [GridRowTransformationAttribute]::TransformItem($dataItem)
        }
        return $outputData
    }
}