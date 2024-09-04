using module "..\..\private\completions\Completers.psm1"
using module "..\..\private\completions\Transformers.psm1"

function Format-SpectreJson {
    <#
    .SYNOPSIS
    Formats an array of objects into a Spectre Console Json.
    Thanks to [trackd](https://github.com/trackd) for adding this.
    ![Spectre json example](/json.png)

    .DESCRIPTION
    This function takes an array of objects and converts them into Json using the Spectre Console Json Library.

    .PARAMETER Data
    The array of objects to be formatted into Json.

    .PARAMETER Depth
    The maximum depth of the Json. Default is defined by the version of powershell.

    .PARAMETER JsonStyle
    A hashtable of Spectre Console color names and values to style the Json output.
    e.g.
    @{
        MemberStyle    = "Yellow"
        BracesStyle    = "Red"
        BracketsStyle  = "Orange1"
        ColonStyle     = "White"
        CommaStyle     = "White"
        StringStyle    = "White"
        NumberStyle    = "Red"
        BooleanStyle   = "LightSkyBlue1"
        NullStyle      = "Gray"
    }

    .EXAMPLE
    $data = @(
        [pscustomobject]@{
            Name = "John"
            Age = 25
            City = "New York"
            IsEmployed = $true
            Salary = 10
            Hobbies = @("Reading", "Swimming")
            Address = @{
                Street = "123 Main St"
                ZipCode = $null
            }
        }
    )
    Format-SpectreJson -Data $data -Color "Green"
    .LINK
    https://pwshspectreconsole.com/reference/formatting/format-spectrejson/
    #>
    [Reflection.AssemblyMetadata("title", "Format-SpectreJson")]
    [cmdletbinding()]
    [OutputType([Spectre.Console.Json.JsonText], [Spectre.Console.Panel])]
    [Alias('fsj')]
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [object] $Data,
        [int] $Depth,
        [ValidateScript({ $_ -gt 0 -and $_ -le (Get-HostWidth) }, ErrorMessage = "Value '{0}' is invalid. Cannot be negative or exceed console width.")]
        [int] $Width,
        [ValidateScript({ $_ -gt 0 -and $_ -le (Get-HostHeight) }, ErrorMessage = "Value '{0}' is invalid. Cannot be negative or exceed console height.")]
        [int] $Height,
        [switch] $Expand,
        [ValidateSet([SpectreConsoleBoxBorder], ErrorMessage = "Value '{0}' is invalid. Try one of: {1}")]
        [string] $Border = "Rounded",
        [ValidateSpectreColorTheme()]
        [ColorThemeTransformationAttribute()]
        [hashtable] $JsonStyle = @{
            MemberStyle    = $script:AccentColor
            BracesStyle    = [Spectre.Console.Color]::Red
            BracketsStyle  = [Spectre.Console.Color]::SteelBlue3
            ColonStyle     = $script:AccentColor
            CommaStyle     = $script:AccentColor
            StringStyle    = [Spectre.Console.Color]::SandyBrown
            NumberStyle    = [Spectre.Console.Color]::MediumSpringGreen
            BooleanStyle   = [Spectre.Console.Color]::DarkCyan
            NullStyle      = $script:DefaultValueColor
        }
    )
    begin {
        $requiredJsonStyleKeys = @('MemberStyle', 'BracesStyle', 'BracketsStyle', 'ColonStyle', 'CommaStyle', 'StringStyle', 'NumberStyle', 'BooleanStyle', 'NullStyle')
        if ($null -ne ($requiredJsonStyleKeys | Where-Object { -Not $JsonStyle.Contains($_) })) {
            throw "JsonStyle must contain the following keys: $($requiredJsonStyleKeys -join ', ')"
        }

        $collector = [System.Collections.Generic.List[psobject]]::new()
        $splat = @{
            WarningAction = 'Ignore'
            ErrorAction   = 'Stop'
        }
        if ($Depth) {
            $splat.Depth = $Depth
        }
        $ht = [ordered]@{}
    }
    process {
        if ($MyInvocation.ExpectingInput) {
            if ($data -is [string] -And -Not [String]::IsNullOrEmpty($data)) {
                if ($data.pschildname -And $data.pschildname.EndSwith('.json')) {
                    # this is when someone does Get-Content file.json | Format-SpectreJson
                    if (-Not $ht.contains($data.pschildname)) {
                        $ht[$data.pschildname] = [System.Text.StringBuilder]::new()
                    }
                    return [void]$ht[$data.pschildname].AppendLine($data)
                }
                try {
                    if (-Not $ht.contains('InputString')) {
                        $ht['InputString'] = [System.Text.StringBuilder]::new()
                    }
                    Write-Debug "adding string to stringbuilder, $data"
                    return [void]$ht['InputString'].AppendLine($data.Trim())
                }
                catch {
                    Write-Debug "Failed to add string to stringbuilder, $_"
                    return $collector.add($data)
                }
            }
            if ($data -is [System.IO.FileSystemInfo]) {
                # if someone pipes a fileinfo object
                if ($data.Extension -eq '.json') {
                    Write-Debug "json file found, reading $($data.FullName)"
                    try {
                        return $ht[$data.Name] = Get-Content -Raw $data.FullName
                    }
                    catch {
                        Write-Debug "Failed to add $_"
                    }
                }
                return $collector.add(
                    [pscustomobject]@{
                        Name     = $data.Name
                        FullName = $data.FullName
                        Type     = $data.GetType().Name.TrimEnd('Info')
                    })
            }
            return $collector.add($data)
        }
        foreach ($item in $data) {
            Write-Debug "adding item from input"
            $collector.add($item)
        }
    }
    end {
        if ($ht.count) {
            foreach ($key in $ht.GetEnumerator()) {
                Write-Debug "converting json stream to object, $key"
                try {
                    $jsonObject = $ht[$key].ToString().Trim() | Out-String | ConvertFrom-Json -AsHashtable @splat
                    $collector.add($jsonObject)
                }
                catch {
                    Write-Debug "Failed to convert json to object: $key, $_"
                }
            }
        }
        if ($collector.Count -eq 0) {
            return
        }
        try {
            $json = [Spectre.Console.Json.JsonText]::new(($collector | ConvertTo-Json @splat))
        }
        catch {
            Write-Error "Failed to convert to json, $_" -ErrorAction Stop
        }

        $json.MemberStyle = [Spectre.Console.Style]::new($JsonStyle.MemberStyle)
        $json.BracesStyle = [Spectre.Console.Style]::new($JsonStyle.BracesStyle)
        $json.BracketsStyle = [Spectre.Console.Style]::new($JsonStyle.BracketsStyle)
        $json.ColonStyle = [Spectre.Console.Style]::new($JsonStyle.ColonStyle)
        $json.CommaStyle = [Spectre.Console.Style]::new($JsonStyle.CommaStyle)
        $json.StringStyle = [Spectre.Console.Style]::new($JsonStyle.StringStyle)
        $json.NumberStyle = [Spectre.Console.Style]::new($JsonStyle.NumberStyle)
        $json.BooleanStyle = [Spectre.Console.Style]::new($JsonStyle.BooleanStyle)
        $json.NullStyle = [Spectre.Console.Style]::new($JsonStyle.NullStyle)
        if ($NoBorder) {
            return $json
        }
        $panel = [Spectre.Console.Panel]::new($json)
        $panel.Border = [Spectre.Console.BoxBorder]::$Border
        $panel.BorderStyle = [Spectre.Console.Style]::new($Color)
        if ($Title) {
            $panel.Header = [Spectre.Console.PanelHeader]::new($Title)
        }
        if ($width) {
            $panel.Width = $Width
        }
        if ($height) {
            $panel.Height = $Height
        }
        if ($Expand) {
            $panel.Expand = $Expand
        }
        $panel
    }
}
