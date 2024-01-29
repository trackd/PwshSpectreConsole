function Write-TableCell {
    [cmdletbinding()]
    param(
        [string] $String,
        [Switch] $AllowMarkup
    )
    if ($AllowMarkup) {
        return [Spectre.Console.Markup]::new($String)
    }
    return [Spectre.Console.Text]::new($String)
}
