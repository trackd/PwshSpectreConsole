Describe "Write-SpectreHost" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            $testMessage = Get-RandomString
            $testMessage | Out-Null
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::ResetTestHooks()
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::WriteMarkupOverride = {
                param($message, $justify, $noNewline, $passThru)
                if ($message -eq '') { $message = ' ' }
                if (-not $passThru -and -not $noNewline) {
                    $message += "`n"
                }
                $markup = [Spectre.Console.Markup]::new($message)
                $markup.Justification = $justify
                if ($passThru) { return $markup }
                $testConsole.Write($markup)
                return $null
            }.GetNewClosure()
        }

        It "writes a message" {
            Write-SpectreHost -Message $testMessage
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::WriteMarkupCallCount | Should -Be 1
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::LastMarkupMessage | Should -Be $testMessage
            $testConsole.Output.Split("`n").Count | Should -Be 2
        }

        It "accepts pipeline input" {
            $testMessage | Write-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::WriteMarkupCallCount | Should -Be 1
            $testConsole.Output.Split("`n").Count | Should -Be 2
        }

        It "handles nonewline" {
            Write-SpectreHost -Message $testMessage -NoNewline
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::WriteMarkupCallCount | Should -Be 1
            $testConsole.Output.Split("`n").Count | Should -Be 1
        }

        It "Should match the snapshot" {
            $testMessage = "[#00ff00]Hello[/], [DeepSkyBlue3_1]World![/] :smiling_face_with_sunglasses: Yay!"
            Write-SpectreHost $testMessage
            { Assert-OutputMatchesSnapshot -SnapshotName "Write-SpectreHost" -Output $testConsole.Output } | Should -Not -Throw
        }
    }
}
