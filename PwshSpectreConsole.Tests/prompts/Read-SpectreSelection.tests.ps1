Describe "Read-SpectreSelection" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $testTitle = Get-RandomString
            $testPageSize = Get-Random -Minimum 1 -Maximum 10
            $testColor = Get-RandomColor
            $itemToBeSelectedName = $null
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemToBeSelectedName
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::ResetTestHooks()
[PwshSpectreConsole.PowerShell.InvocationUtilities]::UseTestPromptResult = $true
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemToBeSelectedName
        }

        It "prompts" {
            Read-SpectreSelection -Title $testTitle -Choices (Get-RandomList) -PageSize $testPageSize -Color $testColor
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.SelectionPrompt[string]]
        }

        It "throws with duplicate labels" {
            { Read-SpectreSelection -Title $testTitle -Choices @("same", "same") -PageSize $testPageSize -Color $testColor } | Should -Throw
        }

        It "prompts with an object input" {
            $itemToBeSelectedName = Get-RandomString
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemToBeSelectedName
            $itemToBeSelected = [PSCustomObject]@{ ColumnToSelectFrom = $itemToBeSelectedName; Other = Get-RandomString }
            Read-SpectreSelection -Title $testTitle -ChoiceLabelProperty "ColumnToSelectFrom" -PageSize $testPageSize -Color $testColor -Choices @(
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString },
                $itemToBeSelected,
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString }
            ) | Should -Be $itemToBeSelected
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.SelectionPrompt[string]]
        }

        It "accepts pipeline input for choices" {
            $itemToBeSelectedName = Get-RandomString
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemToBeSelectedName
            $choices = @($itemToBeSelectedName) + (Get-RandomList)
            $choices | Read-SpectreSelection -Title $testTitle -PageSize $testPageSize -Color $testColor | Should -Be $itemToBeSelectedName
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.SelectionPrompt[string]]
        }

        It "accepts pipeline input for object choices with ChoiceLabelProperty" {
            $itemToBeSelectedName = Get-RandomString
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemToBeSelectedName
            $itemToBeSelected = [PSCustomObject]@{ ColumnToSelectFrom = $itemToBeSelectedName; Other = Get-RandomString }
            $choices = @(
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString },
                $itemToBeSelected,
                [PSCustomObject]@{ ColumnToSelectFrom = Get-RandomString; Other = Get-RandomString }
            )
            $choices | Read-SpectreSelection -Title $testTitle -ChoiceLabelProperty "ColumnToSelectFrom" -PageSize $testPageSize -Color $testColor | Should -Be $itemToBeSelected
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.SelectionPrompt[string]]
        }

        It "prompts with a scriptblock ChoiceLabelProperty" {
            $itemToBeSelectedName = "hello_42"
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemToBeSelectedName
            $itemToBeSelected = [PSCustomObject]@{ Name = "hello"; Id = 42 }
            Read-SpectreSelection -Title $testTitle -ChoiceLabelProperty { "$($_.Name)_$($_.Id)" } -PageSize $testPageSize -Color $testColor -Choices @(
                [PSCustomObject]@{ Name = "foo"; Id = 1 },
                $itemToBeSelected,
                [PSCustomObject]@{ Name = "bar"; Id = 2 }
            ) | Should -Be $itemToBeSelected
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.SelectionPrompt[string]]
        }

        It "accepts pipeline input with a scriptblock ChoiceLabelProperty" {
            $itemToBeSelectedName = "hello_42"
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $itemToBeSelectedName
            $itemToBeSelected = [PSCustomObject]@{ Name = "hello"; Id = 42 }
            $choices = @(
                [PSCustomObject]@{ Name = "foo"; Id = 1 },
                $itemToBeSelected,
                [PSCustomObject]@{ Name = "bar"; Id = 2 }
            )
            $choices | Read-SpectreSelection -Title $testTitle -ChoiceLabelProperty { "$($_.Name)_$($_.Id)" } -PageSize $testPageSize -Color $testColor | Should -Be $itemToBeSelected
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.SelectionPrompt[string]]
        }
    }
}
