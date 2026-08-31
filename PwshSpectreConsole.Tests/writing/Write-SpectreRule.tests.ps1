Describe "Write-SpectreRule" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            [Spectre.Console.Testing.TestConsoleExtensions]::Width($testConsole, 140)
            $testColor = Get-RandomColor
            Write-Debug $testColor
            $justification = Get-RandomJustify
            Set-SpectreTestConsole -TestConsole $testConsole

            # Mock our new function for width suppor


            # Also mock Out-Host to prevent actual output to the console during tests
            Mock Out-Host { }
        }

        It "writes a rule" {
            $randomString = Get-RandomString
            Write-SpectreRule -Title $randomString -Alignment $justification -Color $testColor
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            $testConsole.Output | Should -BeLike "*$randomString*"
        }

        It "Should match the snapshot" {
            Set-SpectreTestConsole -TestConsole $testConsole
            $testTitle = "yo, this is a test rule"
            $justification = "Center"
            $testColor = "Red"

            Write-SpectreRule -Title $testTitle -Alignment $justification -Color $testColor

            { Assert-OutputMatchesSnapshot -SnapshotName "Write-SpectreRule" -Output $testConsole.Output } | Should -Not -Throw
        }

        It "should write a rule with a specific width" {
            $testTitle = "Fixed Width Rule"
            $testWidth = 4

            Write-SpectreRule -Title $testTitle -Alignment $justification -Color $testColor -Width $testWidth

            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::LastRenderWidth | Should -Be $testWidth
            Assert-MockCalled -CommandName "Out-Host" -Times 1 -Exactly
        }

        It "should write a rule with a percentage width" {
            $testTitle = "Half Width Rule"
            $testPercent = 5

            # Mock Console.WindowWidth to return a fixed value for testing
            Mock -CommandName Get-Variable -ParameterFilter { $Name -eq 'Host' } -MockWith {
                return @{
                    Value = @{
                        UI = @{
                            RawUI = @{
                                WindowSize = @{
                                    Width = 1
                                }
                            }
                        }
                    }
                }
            }

            Mock -CommandName Get-Member -ParameterFilter { $InputObject -eq [Console] -and $Name -eq 'WindowWidth' } -MockWith {
                return @{
                    Name = 'WindowWidth'
                    MemberType = 'Property'
                }
            }

            Mock -CommandName Get-Item -ParameterFilter { $Path -eq 'Variable:\Console' } -MockWith {
                return @{
                    Value = @{
                        WindowWidth = 1
                    }
                }
            }

            # Direct mock of [Console]::WindowWidth which doesn't work in Pester but demonstrates inten
            # Mock -CommandName [Console]::WindowWidth -MockWith { return 120 }

            $expectedWidth = [Math]::Floor([PwshSpectreConsole.PowerShell.ConsoleUtilities]::GetHostWidth() * ($testPercent / 100))

            # In a real scenario, we'd use:
            # [Console]::WindowWidth
            # But for the test, we'll just use 120 directly

            Write-SpectreRule -Title $testTitle -Alignment $justification -Color $testColor -WidthPercent $testPercen

            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::LastRenderWidth | Should -Be $expectedWidth
            Assert-MockCalled -CommandName "Out-Host" -Times 1 -Exactly
        }
    }
}
