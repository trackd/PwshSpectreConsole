Describe "Format-SpectreTextPath" {
    InModuleScope "PwshSpectreConsole" {

        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            Set-SpectreTestConsole -TestConsole $testConsole
        }

        It "Should format a path" {
            $renderable = Format-SpectreTextPath -Path "C:\Windows\System32\cmd.exe"
            $renderable | Should -BeOfType [PwshSpectreConsole.Render.SpectreTextPath]
            $renderable | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            { Assert-OutputMatchesSnapshot -SnapshotName "Format-SpectreTextPath" -Output $testConsole.Output } | Should -Not -Throw
        }

        It "Should format with a custom format" {
            $renderable = Format-SpectreTextPath -Path "C:\Windows\System32\cmd.exe" -PathStyle @{
                RootColor      = [Spectre.Console.Color]::Cyan2
                SeparatorColor = [Spectre.Console.Color]::Aqua
                StemColor      = [Spectre.Console.Color]::Orange1
                LeafColor      = [Spectre.Console.Color]::HotPink
            }
            $renderable | Should -BeOfType [PwshSpectreConsole.Render.SpectreTextPath]
            $renderable | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            { Assert-OutputMatchesSnapshot -SnapshotName "Format-SpectreTextPathCustom" -Output $testConsole.Output } | Should -Not -Throw
        }
    }
}
