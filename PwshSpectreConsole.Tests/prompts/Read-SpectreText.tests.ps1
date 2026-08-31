Describe "Read-SpectreText" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $testAnswerColor = $null
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::ResetTestHooks()
[PwshSpectreConsole.PowerShell.InvocationUtilities]::UseTestPromptResult = $true
        }

        It "prompts" {
            Read-SpectreText -Question (Get-RandomString)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.TextPrompt[string]]
        }

        It "prompts with a default answer" {
            Read-SpectreText -Question (Get-RandomString) -DefaultAnswer (Get-RandomString)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.TextPrompt[string]]
        }

        It "can allow an empty answer" {
            Read-SpectreText -Message "What?" -AllowEmpty
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.TextPrompt[string]]
        }

        It "can use a colored prompt" {
            $testAnswerColor = Get-RandomColor
            Read-SpectreText -Question (Get-RandomString) -AnswerColor $testAnswerColor
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::PromptCallCount | Should -Be 1
[PwshSpectreConsole.PowerShell.InvocationUtilities]::LastPrompt | Should -BeOfType [Spectre.Console.TextPrompt[string]]
        }
    }
}
