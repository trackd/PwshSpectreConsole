using module ".\completions\Transformers.psm1"

<#
.SYNOPSIS
Writes an object to the console using [Spectre.Console.AnsiConsole]::Write()

.DESCRIPTION
This function is required for mocking ansiconsole in unit tests that write objects to the console.

.PARAMETER RenderableObject
The renderable object to write to the console e.g. [Spectre.Console.BarChart]

.EXAMPLE
Write-SpectreConsoleOutput -Object "Hello, World!" -ForegroundColor Green -BackgroundColor Black
#>
function Write-AnsiConsole {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [RenderableTransformationAttribute()]
        [object] $RenderableObject,
        [switch] $CustomItemFormatter
    )
    # just always subtract 1 for formatting.
    [Spectre.Console.AnsiConsole]::Console.Profile.Width = $Host.UI.RawUI.BufferSize.Width - 1
    [Spectre.Console.AnsiConsole]::Render($RenderableObject)
}
