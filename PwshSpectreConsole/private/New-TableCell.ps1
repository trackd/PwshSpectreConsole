function New-TableCell {
    [cmdletbinding()]
    param(
        $String,
        [Switch]$AllowMarkup
    )
    Write-Debug "Module: $($ExecutionContext.SessionState.Module.Name) Command: $($MyInvocation.MyCommand.Name) Param: $($PSBoundParameters.GetEnumerator())"
    if ([System.Management.Automation.LanguagePrimitives]::IsObjectEnumerable($String)) {
        Write-Debug "New-TableCell $($String.Gettype().Name), [ICollection]-ish type best effort guess, $String"
        # https://github.com/PowerShell/PowerShell/blob/master/src/System.Management.Automation/FormatAndOutput/common/Utilities/MshObjectUtil.cs#L63-L65
        $Value = foreach ($item in $String) {
            if ($item.name) {
                $item.name
            } elseif ($item.id) {
                $item.id
            } elseif ($item.key) {
                $item.key
            } elseif ($item.psobject.Properties.Match('*key')) {
                $item.psobject.properties.value
            } elseif ($item.psobject.Properties.Match('*name')) {
                $item.psobject.properties.value
            } elseif ($item.psobject.Properties.Match('*id')) {
                $item.psobject.properties.value
            } elseif ($item.GetType().GetMethod('ToString', [type[]]@()).DeclaringType -ne [object]) {
                $item.ToString()
            } else {
                $item
            }
        }
        if ($AllowMarkup) {
            return [Spectre.Console.Markup]::new($value -join ', ')
        }
        return [Spectre.Console.Text]::new($value -join ', ')
    }
    if ([String]::IsNullOrEmpty($String)) {
        if ($AllowMarkup) {
            return [Spectre.Console.Markup]::new(' ')
        }
        return [Spectre.Console.Text]::new(' ')
    }
    if (-Not [String]::IsNullOrEmpty($String.ToString())) {
        if ($AllowMarkup) {
            Write-Debug "New-TableCell ToString(), Markup, $($String.ToString())"
            return [Spectre.Console.Markup]::new($String.ToString())
        }
        Write-Debug "New-TableCell ToString(), Text, $($String.ToString())"
        return [Spectre.Console.Text]::new($String.ToString())
    }
    # just coerce to string.
    if ($AllowMarkup) {
        Write-Debug "New-TableCell [String], markup, $([String]$String)"
        return [Spectre.Console.Markup]::new([String]$String)
    }
    Write-Debug "New-TableCell [String], Text, $([String]$String)"
    return [Spectre.Console.Text]::new([String]$String)
}
