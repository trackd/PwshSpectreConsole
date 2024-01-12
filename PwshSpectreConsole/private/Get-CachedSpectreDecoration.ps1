function Get-CachedSpectreDecoration {
    [cmdletbinding()]
    param($InputObject)
    # [regex]::Matches($string,'\x1B\[[0-?]*[ -/]*[@-~]').Value | Get-AnsiEscapeSequence
    [regex]::Matches($InputObject,'\x1B\[[0-?]*[ -/]*[@-~]').Value -join '' | ForEach-Object {
        if ($script:VTCache.ContainsKey($_)) {
            Write-Debug "Cache hit: $($_.length)"
            return $script:VTCache[$_]
        }
        $parsedCodes = [PwshSpectreConsole.VTCodes.Parser]::Parse($_)
        $script:VTCache[$_] = $parsedCodes
        return $parsedCodes
    }
}
