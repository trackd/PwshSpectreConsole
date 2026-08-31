Describe "Format-SpectreBarChart" {
    InModuleScope "PwshSpectreConsole" {

        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            $testWidth = Get-Random -Minimum 10 -Maximum 100
            $testTitle = "Test Chart $([guid]::NewGuid())"
            $testData = @()
            for ($i = 0; $i -lt (Get-Random -Minimum 3 -Maximum 10); $i++) {
                $testData += New-SpectreChartItem -Label (Get-RandomString) -Value (Get-Random -Minimum -100 -Maximum 100) -Color (Get-RandomColor)
            }

            Set-SpectreTestConsole -TestConsole $testConsole

            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::GetHostWidthOverride = { $testWidth }.GetNewClosure()
        }

        It "Should create a bar chart with correct width" {
            $chart = Format-SpectreBarChart -Data $testData -Title $testTitle -Width $testWidth
            $chart | Should -BeOfType [Spectre.Console.BarChart]
            $chart | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should handle piped input correctly" {
            $chart = $testData | Format-SpectreBarChart -Title $testTitle -Width $testWidth
            $chart | Should -BeOfType [Spectre.Console.BarChart]
            $chart | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should handle single input correctly" {
            $testData = New-SpectreChartItem -Label (Get-RandomString) -Value (Get-Random -Minimum -100 -Maximum 100) -Color (Get-RandomColor)
            $chart = Format-SpectreBarChart -Data $testData -Title $testTitle -Width $testWidth
            $chart | Should -BeOfType [Spectre.Console.BarChart]
            $chart | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should handle no title" {
            Set-SpectreTestConsole -TestConsole $testConsole
            $chart = Format-SpectreBarChart -Data $testData -Width $testWidth
            $chart | Should -BeOfType [Spectre.Console.BarChart]
            $chart | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should handle no width and default to host width" {
            Set-SpectreTestConsole -TestConsole $testConsole
            $chart = Format-SpectreBarChart -Data $testData
            $chart | Should -BeOfType [Spectre.Console.BarChart]
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
                (New-SpectreChartItem -Label "Test 2" -Value 20 -Color "#ff0000"),
                (New-SpectreChartItem -Label "Test 3" -Value 30 -Color "Turquoise2")
            )
            $chart = Format-SpectreBarChart -Data $testData
            $chart | Should -BeOfType [Spectre.Console.BarChart]
            $chart | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            { Assert-OutputMatchesSnapshot -SnapshotName "Format-SpectreBarChart" -Output $testConsole.Output } | Should -Not -Throw
        }
    }
}
