Describe "Read-SpectrePause" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $testMessage = $null
            Mock Write-SpectreHost -Verifiable -ParameterFilter { $Message -eq $testMessage }
            Mock Write-SpectreHost { }
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::ResetTestHooks()
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::ClearInputQueueOverride = { }
            Mock Write-Host
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::ReadKeyOverride = {
                $enter = [System.ConsoleKey]::Enter
                return [System.ConsoleKeyInfo]::new([char]$enter.value__, $enter, $false, $false, $false)
            }
        }

        It "displays" {
            Read-SpectrePause
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::ReadKeyCallCount | Should -Be 1
        }

        It "displays a custom message" {
            $testMessage = Get-RandomString
            Write-Debug $testMessage
            Read-SpectrePause -Message $testMessage
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::ReadKeyCallCount | Should -Be 1
            Should -InvokeVerifiable
        }
    }
}
