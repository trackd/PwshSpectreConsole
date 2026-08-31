Describe "Read-SpectreConfirm" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $choices = @("y", "n")
            $testDefaultAnswer = "y"
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $testDefaultAnswer
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::ResetTestHooks()
[PwshSpectreConsole.PowerShell.InvocationUtilities]::UseTestPromptResult = $true
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $testDefaultAnswer
        }

        It "prompts" {
            Read-SpectreConfirm -Prompt (Get-RandomString)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.TextPrompt[string]]
        }

        It "prompts with a default answer" {
            $testDefaultAnswer = Get-RandomChoice $choices
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $testDefaultAnswer
            $expectedAnswer = ($testDefaultAnswer -eq "y") ? $true : $false
            $thisAnswer = Read-SpectreConfirm -Prompt (Get-RandomString) -DefaultAnswer $testDefaultAnswer
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.TextPrompt[string]]
            $thisAnswer | Should -Be $expectedAnswer
        }

        It "writes success message" {
            $confirmSuccess = Get-RandomString
            Mock Write-SpectreHost {
                $Message | Should -Be $confirmSuccess
            }
            Read-SpectreConfirm -Prompt (Get-RandomString) -ConfirmSuccess $confirmSuccess -DefaultAnswer (Get-RandomChoice $choices)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.TextPrompt[string]]
            Assert-MockCalled -CommandName "Write-SpectreHost" -Times 1 -Exactly
        }

        It "writes failure message" {
            $confirmFailure = Get-RandomString
            $testDefaultAnswer = "n"
[PwshSpectreConsole.PowerShell.InvocationUtilities]::TestPromptResult = $testDefaultAnswer
            $testDefaultAnswer | Out-Null
            Mock Write-SpectreHost {
                $Message | Should -Be $confirmFailure
            }
            Read-SpectreConfirm -Prompt (Get-RandomString) -ConfirmFailure $confirmFailure -DefaultAnswer (Get-RandomChoice $choices)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.TextPrompt[string]]
            Assert-MockCalled -CommandName "Write-SpectreHost" -Times 1 -Exactly
        }

        It "accepts color" {
            $testColor = Get-RandomColor
            Read-SpectreConfirm -Prompt (Get-RandomString) -Color $testColor
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.TextPrompt[string]]
        }
    }
}
