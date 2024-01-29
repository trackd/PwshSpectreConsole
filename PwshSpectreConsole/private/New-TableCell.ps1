function New-TableCell {
    <#
    if ($String -is [System.Collections.ICollection]) {
        $value = $String | ForEach-Object {
            if ($_.Name) {
                $_.Name
            } elseif ($_.Id) {
                $_.Id
            } elseif ($_.keys) {
                $_.keys
            } else {
                $_
            }
        } | Join-String -Separator ', '
    #>
    [cmdletbinding()]
    param(
        $String,
        [Switch]$AllowMarkup
    )
    Write-Debug "Module: $($ExecutionContext.SessionState.Module.Name) Command: $($MyInvocation.MyCommand.Name) Param: $($PSBoundParameters.GetEnumerator())"
    $splat = @{
        AllowMarkup = $AllowMarkup
    }
    if ([System.Management.Automation.LanguagePrimitives]::IsObjectEnumerable($String)) {
        Write-Debug "New-TableCell $($String.Gettype().Name), [ICollection]-ish type best effort guess, $String"
        $propertyMap = @{
            'ServiceController' = 'Name'
            'ProcessThread'     = 'Id'
            'FileVersionInfo'   = 'FileVersion'
            'ModuleInfo'        = 'ModuleName'
            'FileInfo'          = 'Name'
            'DirectoryInfo'     = 'Name'
            # Add more mappings as needed
        }
        $Value = foreach ($item in $String) {
            if ($propertyMap.containskey($item.GetType().Name)) {
                # we have a mapping
                $propertyName = $propertyMap[$item.GetType().Name]
            }
            if ($propertyName -and $item.psobject.Properties[$propertyName]) {
                # if we have a property name, and the item has that property
                $item.psobject.Properties[$propertyName].Value
            } elseif ($item -is [System.ValueType]) {
                # Handle value types
                Write-Debug "[ICollection] ValueType, $($item)"
                $item
            } else {
                # try and find a property that makes sense.
                # https://github.com/PowerShell/PowerShell/blob/master/src/System.Management.Automation/FormatAndOutput/common/Utilities/MshObjectUtil.cs#L63-L65
                $knownPatterns = 'name', 'id', 'key', '*key', '*name', '*id'
                foreach ($pattern in $knownPatterns) {
                    $test = $item.psobject.Properties.Match($pattern)
                    if ($test) {
                        Write-Debug "[ICollection] $pattern, $($test.Value), $($item.GetType().Name)"
                        # $found = $true
                        $test.Value
                        break
                    }
                }
                if (-not $test) {
                    if ($item.GetType().GetMethod('ToString', [type[]]@()).DeclaringType -ne [object]) {
                        # if the item has a ToString method that is not inherited from object, use that.
                        Write-Debug "[ICollection] ToString"
                        $item.ToString()
                    } else {
                        # give up, just return the item.
                        $item
                    }
                }
            }
        }
        Write-TableCell ($value -join ', ') @splat
    } elseif ([String]::IsNullOrEmpty($String)) {
        Write-TableCell ' ' @splat
    } elseif (-Not [String]::IsNullOrEmpty($String.ToString())) {
        Write-TableCell $String.ToString() @splat
    } else {
        Write-TableCell $String @splat
    }
}
