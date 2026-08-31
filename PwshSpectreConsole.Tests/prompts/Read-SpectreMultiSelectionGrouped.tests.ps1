Describe "Read-SpectreMultiSelectionGrouped" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $testTitle = Get-RandomString
            $testPageSize = Get-Random -Minimum 1 -Maximum 10
            $testColor = Get-RandomColor
            $itemsToBeSelectedNames = $null
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::ResetTestHooks()
[PwshSpectreConsole.PowerShell.InvocationUtilities]::UseTestPromptResult = $true
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
        }

        It "prompts and allows selection" {
            $itemsToBeSelectedNames = @("toBeSelected")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $testChoices = @(Get-RandomList -Generator {
                    return @{
                        Name    = Get-RandomString
                        Choices = Get-RandomList
                    }
                })
            $testChoices += @{
                Name    = "Group with selection"
                Choices = @(Get-RandomList) + $itemsToBeSelectedNames
            }
            Read-SpectreMultiSelectionGrouped -Title $testTitle -Choices $testChoices -PageSize $testPageSize -Color $testColor | Should -Be $itemsToBeSelectedNames
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }

        It "prompts and allows multiple selection" {
            $itemsToBeSelectedNames = @("toBeSelected", "also to be selected")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $testChoices = @(Get-RandomList -Generator {
                    return @{
                        Name    = Get-RandomString
                        Choices = "toBeSelected" + (Get-RandomList)
                    }
                })
            $testChoices += @{
                Name    = "Group with selection"
                Choices = @(Get-RandomList) + "also to be selected"
            }
            Read-SpectreMultiSelectionGrouped -Title $testTitle -Choices $testChoices -PageSize $testPageSize -Color $testColor | Should -Be $itemsToBeSelectedNames
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }

        It "throws with duplicate labels" {
            { Read-SpectreMultiSelectionGrouped -Title $testTitle -Choices @("same", "same") -PageSize $testPageSize -Color $testColor } | Should -Throw
        }

        It "throws with object choices and no ChoiceLabelProperty" {
            $testChoices = Get-RandomList -Generator {
                return @{
                    Name    = Get-RandomString
                    Choices = (Get-RandomList -Generator {
                            [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString }
                        })
                }
            }
            { Read-SpectreMultiSelectionGrouped -Title $testTitle -Choices $testChoices -PageSize $testPageSize -Color $testColor } | Should -Throw
        }

        It "prompts with an object input and allows selection" {
            $itemsToBeSelectedNames = @("toBeSelected")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $itemToBeSelected = [PSCustomObject]@{ ColumnToSelectFrom = $itemsToBeSelectedNames[0]; Other = Get-RandomString }
            $testChoices = @(
                @{
                    Name    = Get-RandomString
                    Choices = @(Get-RandomList -Generator {
                            [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString }
                        }) + $itemToBeSelected
                }
            )
            Read-SpectreMultiSelectionGrouped -Title $testTitle -ChoiceLabelProperty "ColumnToSelectFrom" -Choices $testChoices -PageSize $testPageSize -Color $testColor | Should -Be $itemToBeSelected
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }

        It "prompts with an object input and allows multiple selection" {
            $itemsToBeSelectedNames = @("toBeSelected", "also to be selected")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $itemToBeSelected = [PSCustomObject]@{ ColumnToSelectFrom = $itemsToBeSelectedNames[0]; Other = Get-RandomString }
            $anotherItemToBeSelected = [PSCustomObject]@{ ColumnToSelectFrom = $itemsToBeSelectedNames[1]; Other = Get-RandomString }
            $testChoices = @(
                @{
                    Name    = Get-RandomString
                    Choices = @($itemToBeSelected) + (Get-RandomList -Generator {
                            [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString }
                        }) + $anotherItemToBeSelected
                }
            )
            Read-SpectreMultiSelectionGrouped -Title $testTitle -ChoiceLabelProperty "ColumnToSelectFrom" -Choices $testChoices -PageSize $testPageSize -Color $testColor | Should -Be @($itemToBeSelected, $anotherItemToBeSelected)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }

        It "prompts with a scriptblock ChoiceLabelProperty" {
            $itemsToBeSelectedNames = @("hello_42", "world_99")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $itemToBeSelected = [PSCustomObject]@{ Name = "hello"; Id = 42 }
            $anotherItemToBeSelected = [PSCustomObject]@{ Name = "world"; Id = 99 }
            $testChoices = @(
                @{
                    Name    = "Test Group"
                    Choices = @(
                        [PSCustomObject]@{ Name = "foo"; Id = 1 },
                        $itemToBeSelected,
                        [PSCustomObject]@{ Name = "bar"; Id = 2 },
                        $anotherItemToBeSelected
                    )
                }
            )
            Read-SpectreMultiSelectionGrouped -Title $testTitle -ChoiceLabelProperty { "$($_.Name)_$($_.Id)" } -Choices $testChoices -PageSize $testPageSize -Color $testColor | Should -Be @($itemToBeSelected, $anotherItemToBeSelected)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }
    }
}
