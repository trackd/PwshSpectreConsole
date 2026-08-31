Describe "New-SpectreLayout" {
    InModuleScope "PwshSpectreConsole" {

        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            Set-SpectreTestConsole -TestConsole $testConsole
        }

        It "Should generate a layout" {
            $panel1 = "what" | Format-SpectrePanel -Header "panel 1 (align bottom right)" -Expand -Color Green
            $panel2 = "hello row 2" | Format-SpectrePanel -Header "panel 2" -Expand -Color Blue
            $panel3 = "test" | Format-SpectreAligned | Format-SpectrePanel -Header "panel 3 (align middle center)" -Expand -Color Yellow

            $row1 = New-SpectreLayout -Name "row1" -Data $panel1 -Ratio 1
            $row2 = New-SpectreLayout -Name "row2" -Columns @($panel2, $panel3) -Ratio 2
            $renderable = New-SpectreLayout -Name "root" -Rows @($row1, $row2)

            $renderable | Should -BeOfType [Spectre.Console.Layout]

            $renderable | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            { Assert-OutputMatchesSnapshot -SnapshotName "New-SpectreLayout" -Output $testConsole.Output } | Should -Not -Throw

        }
    }
}
