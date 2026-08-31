Describe "Invoke-SpectreCommandWithStatus" -Tag "integration" {
    InModuleScope "PwshSpectreConsole" {

        BeforeEach {
            $testTitle = Get-RandomString
            $testSpinner = Get-RandomSpinner
            $testColor = Get-RandomColor
            Write-Debug $testTitle
            Write-Debug $testSpinner
            Write-Debug $testColor

            $writer = [System.IO.StringWriter]::new()
            $output = [Spectre.Console.AnsiConsoleOutput]::new($writer)
            $settings = [Spectre.Console.AnsiConsoleSettings]::new()
            $settings.Out = $output
            [Spectre.Console.AnsiConsole]::Console = [Spectre.Console.AnsiConsole]::Create($settings)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::ResetTestHooks()
        }

        AfterEach {
            $settings = [Spectre.Console.AnsiConsoleSettings]::new()
            $settings.Out = [Spectre.Console.AnsiConsoleOutput]::new([System.Console]::Out)
            [Spectre.Console.AnsiConsole]::Console = [Spectre.Console.AnsiConsole]::Create($settings)
        }

        It "executes the scriptblock for the basic case" {
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::ResetTestHooks()
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::StatusOverride = {
                param($title, $spinner, $spinnerStyle, $scriptBlock)
                $title | Should -Be $testTitle
                $spinner.GetType().Name | Should -BeLike "*$testSpinner*"
                $spinnerStyle.Foreground.ToMarkup() | Should -Be $testColor
                $scriptBlock | Should -BeOfType [scriptblock]

                & $scriptBlock
            }.GetNewClosure()
            Invoke-SpectreCommandWithStatus -Title $testTitle -Spinner $testSpinner -Color $testColor -ScriptBlock {
                return 1
            } | Should -Be 1
        }

        It "executes the scriptblock without mocking" {
            Invoke-SpectreCommandWithStatus -Title $testTitle -Spinner $testSpinner -Color $testColor -ScriptBlock {
                Start-Sleep -Seconds 1
                return 1
            } | Should -Be 1
        }
    }
}
