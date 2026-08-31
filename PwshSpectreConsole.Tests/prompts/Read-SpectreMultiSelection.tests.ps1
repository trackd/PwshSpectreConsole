Describe "Read-SpectreMultiSelection" {
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
            $choices = (Get-RandomList) + $itemsToBeSelectedNames
            Read-SpectreMultiSelection -Title $testTitle -Choices $choices -PageSize $testPageSize -Color $testColor | Should -Be $itemsToBeSelectedNames
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }

        It "prompts and allows multiple selection" {
            $itemsToBeSelectedNames = @("toBeSelected", "also to be selected")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $choices = $itemsToBeSelectedNames + (Get-RandomList)
            Read-SpectreMultiSelection -Title $testTitle -Choices $choices -PageSize $testPageSize -Color $testColor | Should -Be $itemsToBeSelectedNames
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }

        It "throws with duplicate labels" {
            { Read-SpectreMultiSelection -Title $testTitle -Choices @("same", "same") -PageSize $testPageSize -Color $testColor } | Should -Throw
        }

        It "throws with object choices without a ChoiceLabelProperty" {
            $choices = @(
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString },
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString }
            )
            { Read-SpectreMultiSelection -Title $testTitle -Choices $choices -PageSize $testPageSize -Color $testColor } | Should -Throw
        }

        It "prompts with an object input and allows selection" {
            $itemsToBeSelectedNames = @("toBeSelected")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $itemToBeSelected = [PSCustomObject]@{ ColumnToSelectFrom = $itemsToBeSelectedNames[0]; Other = Get-RandomString }
            Read-SpectreMultiSelection -Title $testTitle -ChoiceLabelProperty "ColumnToSelectFrom" -PageSize $testPageSize -Color $testColor -Choices @(
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString },
                $itemToBeSelected,
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString }
            ) | Should -Be $itemToBeSelected
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }

        It "prompts with an object input and allows multiple selection" {
            $itemsToBeSelectedNames = @("toBeSelected", "also to be selected")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $itemToBeSelected = [PSCustomObject]@{ ColumnToSelectFrom = $itemsToBeSelectedNames[0]; Other = Get-RandomString }
            $anotherItemToBeSelected = [PSCustomObject]@{ ColumnToSelectFrom = $itemsToBeSelectedNames[1]; Other = Get-RandomString }
            Read-SpectreMultiSelection -Title $testTitle -ChoiceLabelProperty "ColumnToSelectFrom" -PageSize $testPageSize -Color $testColor -Choices @(
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString },
                $itemToBeSelected,
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString },
                $anotherItemToBeSelected
            ) | Should -Be @($itemToBeSelected, $anotherItemToBeSelected)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }

        It "accepts pipeline input for choices" {
            $itemsToBeSelectedNames = @("toBeSelected", "also to be selected")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $choices = $itemsToBeSelectedNames + (Get-RandomList)
            $choices | Read-SpectreMultiSelection -Title $testTitle -PageSize $testPageSize -Color $testColor | Should -Be $itemsToBeSelectedNames
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }

        It "accepts pipeline input for object choices with ChoiceLabelProperty" {
            $itemsToBeSelectedNames = @("toBeSelected", "also to be selected")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $itemToBeSelected = [PSCustomObject]@{ ColumnToSelectFrom = $itemsToBeSelectedNames[0]; Other = Get-RandomString }
            $anotherItemToBeSelected = [PSCustomObject]@{ ColumnToSelectFrom = $itemsToBeSelectedNames[1]; Other = Get-RandomString }
            $choices = @(
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString },
                $itemToBeSelected,
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString },
                $anotherItemToBeSelected
            )
            $choices | Read-SpectreMultiSelection -Title $testTitle -ChoiceLabelProperty "ColumnToSelectFrom" -PageSize $testPageSize -Color $testColor | Should -Be @($itemToBeSelected, $anotherItemToBeSelected)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }

        It "prompts with a scriptblock ChoiceLabelProperty" {
            $itemsToBeSelectedNames = @("hello_42", "world_99")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $itemToBeSelected = [PSCustomObject]@{ Name = "hello"; Id = 42 }
            $anotherItemToBeSelected = [PSCustomObject]@{ Name = "world"; Id = 99 }
            Read-SpectreMultiSelection -Title $testTitle -ChoiceLabelProperty { "$($_.Name)_$($_.Id)" } -PageSize $testPageSize -Color $testColor -Choices @(
                [PSCustomObject]@{ Name = "foo"; Id = 1 },
                $itemToBeSelected,
                [PSCustomObject]@{ Name = "bar"; Id = 2 },
                $anotherItemToBeSelected
            ) | Should -Be @($itemToBeSelected, $anotherItemToBeSelected)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }

        It "accepts pipeline input with a scriptblock ChoiceLabelProperty" {
            $itemsToBeSelectedNames = @("hello_42", "world_99")
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemsToBeSelectedNames
            $itemToBeSelected = [PSCustomObject]@{ Name = "hello"; Id = 42 }
            $anotherItemToBeSelected = [PSCustomObject]@{ Name = "world"; Id = 99 }
            $choices = @(
                [PSCustomObject]@{ Name = "foo"; Id = 1 },
                $itemToBeSelected,
                [PSCustomObject]@{ Name = "bar"; Id = 2 },
                $anotherItemToBeSelected
            )
            $choices | Read-SpectreMultiSelection -Title $testTitle -ChoiceLabelProperty { "$($_.Name)_$($_.Id)" } -PageSize $testPageSize -Color $testColor | Should -Be @($itemToBeSelected, $anotherItemToBeSelected)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.MultiSelectionPrompt[string]]
        }
    }
}
