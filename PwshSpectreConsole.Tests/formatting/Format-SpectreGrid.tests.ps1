Describe "Format-SpectreGrid" {
    InModuleScope "PwshSpectreConsole" {

        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            Set-SpectreTestConsole -TestConsole $testConsole
        }

        It "Should format data in a grid" {
            $rows = 4
            $cols = 6

            $gridRows = @()
            for ($row = 1; $row -le $rows; $row++) {
                $columns = @()
                for ($col = 1; $col -le $cols; $col++) {
                    $columns += "Row $row, Col $col"
                }
                $gridRows += New-SpectreGridRow $columns
            }

            $renderable = $gridRows | Format-SpectreGrid
            $renderable | Should -BeOfType [Spectre.Console.Grid]
            $renderable | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            { Assert-OutputMatchesSnapshot -SnapshotName "Format-SpectreGrid" -Output $testConsole.Output } | Should -Not -Throw
        }
    }
}
