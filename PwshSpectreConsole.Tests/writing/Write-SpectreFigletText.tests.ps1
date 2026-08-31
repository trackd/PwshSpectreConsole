Describe "Write-SpectreFigletText" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            [Spectre.Console.Testing.TestConsoleExtensions]::Width($testConsole, 180)
            $testColor = Get-RandomColor
            $testAlignment = Get-RandomJustify
            Set-SpectreTestConsole -TestConsole $testConsole
        }

        It "writes figlet text" {
            Write-SpectreFigletText -Text (Get-RandomString) -Alignment $testAlignment -Color $testColor
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "throws when the font file isn't found" {
            { Write-SpectreFigletText -FigletFontPath "notfound.flf" } | Should -Throw
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 0
        }

        It "Should match the snapshot" {
            Set-SpectreTestConsole -TestConsole $testConsole
            $testTitle = "f i glett"
            $testAlignment = "Center"
            $testColor = "DarkSeaGreen1_1"

            Write-SpectreFigletText -Text $testTitle -Alignment $testAlignment -Color $testColor

            { Assert-OutputMatchesSnapshot -SnapshotName "Write-SpectreFigletText" -Output $testConsole.Output } | Should -Not -Throw
        }
    }
}
