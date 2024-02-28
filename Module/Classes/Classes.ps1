class ValidateSpectreColor : System.Management.Automation.ValidateArgumentsAttribute {
    ValidateSpectreColor() : base() { }
    [void]Validate([object] $Color, [System.Management.Automation.EngineIntrinsics]$EngineIntrinsics) {
        # Handle hex colors
        if ($Color -match '^#[A-Fa-f0-9]{6}$') {
            return
        }
        # Handle an explicitly defined spectre color object
        if ($Color -is [Spectre.Console.Color]) {
            return
        }
        $spectreColors = [Spectre.Console.Color] | Get-Member -Static -Type Properties | Select-Object -ExpandProperty Name
        $result = $spectreColors -contains $Color
        if ($result -eq $false) {
            throw "'$Color' is not in the list of valid Spectre colors ['$($spectreColors -join ''', ''')']"
        }
    }
}

class ArgumentCompletionsSpectreColors : System.Management.Automation.ArgumentCompleterAttribute {
    ArgumentCompletionsSpectreColors() : base({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            $options = [Spectre.Console.Color] | Get-Member -Static -Type Properties | Select-Object -ExpandProperty Name
            return $options | Where-Object { $_ -like "$wordToComplete*" }
        }) { }
}

class SpectreConsoleTableBorder : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        $lookup = [Spectre.Console.TableBorder] | Get-Member -Static -MemberType Properties | Select-Object -ExpandProperty Name
        return $lookup
    }
}

class SpectreConsoleBoxBorder : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        $lookup = [Spectre.Console.BoxBorder] | Get-Member -Static -MemberType Properties | Select-Object -ExpandProperty Name
        return $lookup
    }
}

class SpectreConsoleJustify : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        $lookup = [Spectre.Console.Justify].GetEnumNames()
        return $lookup
    }
}

class SpectreConsoleSpinner : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        $lookup = [Spectre.Console.Spinner+Known] | Get-Member -Static -MemberType Properties | Select-Object -ExpandProperty Name
        return $lookup
    }
}

class SpectreConsoleTreeGuide : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        $lookup = [Spectre.Console.TreeGuide] | Get-Member -Static -MemberType Properties | Select-Object -ExpandProperty Name
        return $lookup
    }
}
class ColorTransformationAttribute : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engine, [object]$inputData) {
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
        throw [System.ArgumentException]::new("Cannot convert '$InputData' to [Spectre.Console.Color]")
    }
}
class SpectreChartItem
{
    [string] $Label
    [double] $Value
    [Spectre.Console.Color] $Color

    SpectreChartItem([string] $Label, [double] $Value, [Spectre.Console.Color] $Color) {
        $this.Label = $Label
        $this.Value = $Value
        $this.Color = $Color
    }
}
