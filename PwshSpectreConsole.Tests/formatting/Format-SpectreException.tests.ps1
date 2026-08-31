Describe "Format-SpectreException" {
    InModuleScope "PwshSpectreConsole" {

        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            Set-SpectreTestConsole -TestConsole $testConsole
        }

        It "Should format an error record" {
            try {
                Get-ChildItem -BadParam -ErrorAction Stop
            } catch {
                $_ | Should -BeOfType [System.Management.Automation.ErrorRecord]
                $renderable = $_ | Format-SpectreException -ExceptionFormat ShortenEverything
            }
            $renderable | Should -BeOfType [Spectre.Console.Rows]
            $renderable | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            { Assert-OutputMatchesSnapshot -SnapshotName "Format-SpectreException" -Output $testConsole.Output } | Should -Not -Throw
        }

        It "Should format an exception" {
            $testException = [System.Exception]::new("Test exception")
            $renderable = Format-SpectreException -Exception $testException -ExceptionFormat ShortenEverything
            $renderable | Should -BeOfType [Spectre.Console.Rows]
            $renderable | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should format an exception with custom styles" {
            try {
                Get-ChildItem -BadParam -ErrorAction Stop
            } catch {
                $_ | Should -BeOfType [System.Management.Automation.ErrorRecord]
                $renderable = Format-SpectreException -Exception $_ -ExceptionFormat ShortenEverything -ExceptionStyle @{
                    Message        = "Red"
                    Exception      = "White"
                    Method         = [Spectre.Console.Color]::Pink3
                    ParameterType  = "Grey69"
                    ParameterName  = "Silver"
                    Parenthesis    = "#ff0000"
                    Path           = [Spectre.Console.Color]::Pink3
                    LineNumber     = "Blue"
                    Dimmed         = "Grey"
                    NonEmphasized  = "Red"
                }
            }

            $renderable | Should -BeOfType [Spectre.Console.Rows]
            $renderable | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            { Assert-OutputMatchesSnapshot -SnapshotName "Format-SpectreException.CustomStyles" -Output $testConsole.Output } | Should -Not -Throw
        }
    }
}
