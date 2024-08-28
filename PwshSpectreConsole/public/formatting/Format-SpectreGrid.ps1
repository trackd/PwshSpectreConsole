using module "..\..\private\completions\Transformers.psm1"

function Format-SpectreGrid {
    <#
    .SYNOPSIS
    Formats data into a Spectre Console grid.

    .DESCRIPTION
    Formats data into a Spectre Console grid. The grid can be used to display data in a tabular format but it's not as flexible as the Layout widget.  
    See https://spectreconsole.net/widgets/grid for more information.

    .EXAMPLE
    Format-SpectreGrid -Data @("hello", "I", "am"), @("a", "grid", "of"), @("rows", "using", "spectre")

    .EXAMPLE
    $rows = 4
    $cols = 6
    
    $gridRows = @()
    for ($row = 1; $row -le $rows; $row++) {
        $columns = @()
        for ($col = 1; $col -le $cols; $col++) {
            $columns += "Row $row, Col $col" | Format-SpectrePanel
        }
        $gridRows += New-SpectreGridRow $columns
    }
    
    $gridRows | Format-SpectreGrid
    #>
    [Reflection.AssemblyMetadata("title", "Format-SpectreGrid")]
    param (
        [Parameter(ValueFromPipeline, Mandatory)]
        [GridRowTransformationAttribute()]
        [object]$Data,
        [int] $Width
    )

    begin {
        $grid = [Spectre.Console.Grid]::new()
        $columnsSet = $false
        if ($Width) {
            $grid.Width = $Width
        }
        $grid.Alignment = [Spectre.Console.Justify]::$Justify
        $grid = $grid.AddColumn()
    }

    process {
        if ($Data -is [array]) {
            foreach ($row in $Data) {
                if (!$columnsSet) {
                    0..($row.Count() - 1) | ForEach-Object {
                        $grid = $grid.AddColumn()
                    }
                    $columnsSet = $true
                }
                $grid = $grid.AddRow($row.ToGridRow())
            }
        } else {
            if (!$columnsSet) {
                0..($row.Count() - 1) | ForEach-Object {
                    $grid = $grid.AddColumn()
                }
                $columnsSet = $true
            }
            $grid = $grid.AddRow($Data.ToGridRow())
        }
    }
    
    end {
        return $grid
    }
}
