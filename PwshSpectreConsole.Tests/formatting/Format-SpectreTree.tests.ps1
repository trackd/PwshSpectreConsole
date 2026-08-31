Describe "Format-SpectreTree" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            [Spectre.Console.Testing.TestConsoleExtensions]::Width($testConsole, 140)
            $testGuide = Get-RandomTreeGuide
            $testColor = Get-RandomColor

            Set-SpectreTestConsole -TestConsole $testConsole
        }

        It "Should create a Tree" {
            $tree = Get-RandomTree | Format-SpectreTree -Guide $testGuide -Color $testColor
            $tree | Should -BeOfType [Spectre.Console.Tree]
            $tree | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should match the snapshot" {
            Set-SpectreTestConsole -TestConsole $testConsole
            $testData = @{
                Value    = "Root"
                Children = @(
                    @{
                        Value    = "Child 1"
                        Children = @(
                            @{
                                Value    = "Grandchild 1"
                                Children = @(
                                    @{
                                        Value = "Great Grandchild 1"
                                    },
                                    @{
                                        Value = "Great Grandchild 2"
                                    },
                                    @{
                                        Value = "Great Grandchild 3"
                                    }
                                )
                            }
                        )
                    },
                    @{
                        Value = "Child 2"
                    }
                )
            }

            $testGuide = "BoldLine"
            $testColor = "DeepPink2"
            $tree = $testData | Format-SpectreTree -Guide $testGuide -Color $testColor
            $tree | Should -BeOfType [Spectre.Console.Tree]
            $tree | Out-SpectreHost
            { Assert-OutputMatchesSnapshot -SnapshotName "Format-SpectreTree" -Output $testConsole.Output } | Should -Not -Throw
        }
    }
}
