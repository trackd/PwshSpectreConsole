Describe "Invoke-SpectreLive" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $writer = [System.IO.StringWriter]::new()
            $output = [Spectre.Console.AnsiConsoleOutput]::new($writer)
            $settings = [Spectre.Console.AnsiConsoleSettings]::new()
            $settings.Out = $output
            [Spectre.Console.AnsiConsole]::Console = [Spectre.Console.AnsiConsole]::Create($settings)
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::ResetTestHooks()
            [PwshSpectreConsole.PowerShell.InvocationUtilities]::LiveOverride = {
                param($data, $scriptBlock)
                $data | Should -BeOfType [Spectre.Console.Rendering.Renderable]
                $scriptBlock | Should -BeOfType [scriptblock]
                & $scriptBlock $null
            }
        }

        AfterEach {
            $settings = [Spectre.Console.AnsiConsoleSettings]::new()
            $settings.Out = [Spectre.Console.AnsiConsoleOutput]::new([System.Console]::Out)
            [Spectre.Console.AnsiConsole]::Console = [Spectre.Console.AnsiConsole]::Create($settings)
        }

        It "executes the scriptblock for the basic case" {
            $table = @{ Name = "Test"; Value = "Value" } | Format-SpectreTable
            Invoke-SpectreLive -Data $table -ScriptBlock {
                param (
                    $Context
                )
                return 1
            } | Should -Be 1
        }

        It "executes the scriptblock with background jobs" {
            $table = @{ Name = "Test"; Value = "Value" } | Format-SpectreTable
            Invoke-SpectreLive -Data $table -ScriptBlock {
                param (
                    $Context
                )
                return 1
            } | Should -Be 1
        }

    }
}
