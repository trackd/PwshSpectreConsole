Describe "Format-SpectrePanel" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            [Spectre.Console.Testing.TestConsoleExtensions]::Width($testConsole, 80)
            $testTitle = Get-RandomString -MinimumLength 5 -MaximumLength 10
            $testBorder = Get-RandomBoxBorder -MustNotBeNone
            $testExpand = $false
            $testColor = Get-RandomColor

            Set-SpectreTestConsole -TestConsole $testConsole
        }

        It "Should create a panel" {
            $randomString = Get-RandomString
            $panel = Format-SpectrePanel -Data $randomString -Title $testTitle -Border $testBorder -Color $testColor
            $panel | Should -BeOfType [Spectre.Console.Panel]
            $panel | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            $testConsole.Output | Should -BeLike "*$randomString*"
            $testConsole.Output | Should -BeLike "*$testTitle*"
        }

        It "Should create an expanded panel" {
            $testExpand = $true
            $randomString = Get-RandomString
            $panel = Format-SpectrePanel -Data $randomString -Title $testTitle -Border $testBorder -Expand:$testExpand -Color $testColor
            $panel | Should -BeOfType [Spectre.Console.Panel]
            $panel | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            $testConsole.Output | Should -BeLike "*$randomString*"
            $testConsole.Output | Should -BeLike "*$testTitle*"
        }

        It "Should match the snapshot" {
            Set-SpectreTestConsole -TestConsole $testConsole
            $panel = Format-SpectrePanel -Data "This is a test panel" -Title "Test title" -Border "Rounded" -Color "Turquoise2"
            $panel | Should -BeOfType [Spectre.Console.Panel]
            $panel | Out-SpectreHost
            { Assert-OutputMatchesSnapshot -SnapshotName "Format-SpectrePanel" -Output $testConsole.Output } | Should -Not -Throw
        }
    }
}
