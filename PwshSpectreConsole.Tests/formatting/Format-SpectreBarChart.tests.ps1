# Import the module to be tested/
BeforeAll {
    Import-Module "$PSScriptRoot\..\..\PwshSpectreConsole\PwshSpectreConsole.psm1" -Force
}

Describe "Format-SpectreBarChart" {
    InModuleScope "PwshSpectreConsole" {
        Context "WhenThingsHappen" {
            BeforeEach {
                Mock Write-AnsiConsole {}

                Mock Convert-ToSpectreColor {}
            }

            It "Should create a bar chart with correct width" {
                $data = @(
                    @{ Label = "Apples"; Value = 10; Color = "Green" },
                    @{ Label = "Oranges"; Value = 5; Color = "Yellow" },
                    @{ Label = "Bananas"; Value = 3; Color = "Red" }
                )
                Format-SpectreBarChart -Data $data -Title "Fruit Sales" -Width 50
                Assert-MockCalled -CommandName "Write-AnsiConsole" -Times 1 -Exactly
            }

            It "Should handle single item data correctly" {
                $data = @{ Label = "Apples"; Value = 10; Color = "Green" }
                Format-SpectreBarChart -Data $data -Title "Fruit Sales" -Width 50
                Assert-MockCalled Write-AnsiConsole -Times 1 -Exactly
            }
        }
    }
}