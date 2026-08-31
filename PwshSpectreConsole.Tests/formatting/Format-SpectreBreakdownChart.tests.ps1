Describe "Format-SpectreBreakdownChart" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            $testWidth = Get-Random -Minimum 10 -Maximum 100
            $testData = @()
            for ($i = 0; $i -lt (Get-Random -Minimum 3 -Maximum 10); $i++) {
                $testData += Get-RandomChartItem
            }

            Set-SpectreTestConsole -TestConsole $testConsole

            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::GetHostWidthOverride = { $testWidth }.GetNewClosure()
        }

        It "Should create a bar chart with correct width" {
            $chart = Format-SpectreBreakdownChart -Data $testData -Width $testWidth
            $chart | Should -BeOfType [Spectre.Console.BreakdownChart]
            $chart | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should handle piped input correctly" {
            $chart = $testData | Format-SpectreBreakdownChart -Width $testWidth
            $chart | Should -BeOfType [Spectre.Console.BreakdownChart]
            $chart | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should handle single input correctly" {
            $testData = New-SpectreChartItem -Label (Get-RandomString) -Value (Get-Random -Minimum -100 -Maximum 100) -Color (Get-RandomColor)
            $chart = Format-SpectreBreakdownChart -Data $testData -Width $testWidth
            $chart | Should -BeOfType [Spectre.Console.BreakdownChart]
            $chart | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should handle no width and default to host width" {
            Set-SpectreTestConsole -TestConsole $testConsole
            $chart = Format-SpectreBreakdownChart -Data $testData
            $chart | Should -BeOfType [Spectre.Console.BreakdownChart]
            $chart | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should match the snapshot" {
            Set-SpectreTestConsole -TestConsole $testConsole
            $testWidth = 1
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::GetHostWidthOverride = { $testWidth }.GetNewClosure()
            Write-Debug "Setting test width to $testWidth"
            $testData = @(
                (New-SpectreChartItem -Label "Test 1" -Value 10 -Color "Turquoise2"),
                (New-SpectreChartItem -Label "Test 2" -Value 20 -Color "Turquoise2"),
                (New-SpectreChartItem -Label "Test 3" -Value 30 -Color "Turquoise2")
            )
            $chart = Format-SpectreBreakdownChart -Data $testData
            $chart | Should -BeOfType [Spectre.Console.BreakdownChart]
            $chart | Out-SpectreHost
            { Assert-OutputMatchesSnapshot -SnapshotName "Format-SpectreBreakdownChart" -Output $testConsole.Output } | Should -Not -Throw
        }
    }
}
