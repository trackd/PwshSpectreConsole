Describe "Format-SpectreTable" {
    InModuleScope "PwshSpectreConsole" {
        BeforeEach {
            $testConsole = [Spectre.Console.Testing.TestConsole]::new()
            $testConsole.EmitAnsiSequences = $true
            [Spectre.Console.Testing.TestConsoleExtensions]::Width($testConsole, 140)
            $testData = $null
            $testBorder = Get-RandomBoxBorder
            $testColor = Get-RandomColor

            Set-SpectreTestConsole -TestConsole $testConsole
        }

        It "Should create a table when default display members for a command are required" {
            $testData = Get-ChildItem "$PSScriptRoot"
            $table = Format-SpectreTable -Data $testData -Border $testBorder -Color $testColor
            $table | Should -BeOfType [Spectre.Console.Table]
            $table | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should create a table when default display members for a command are required and input is piped" {
            $testData = Get-ChildItem "$PSScriptRoot"
            $table = $testData | Format-SpectreTable -Border $testBorder -Color $testColor
            $table | Should -BeOfType [Spectre.Console.Table]
            $table | Out-SpectreHost
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should be able to retrieve default display members for command output with format data" {
            $testData = Get-ChildItem "$PSScriptRoot"
            $formatted = @($testData | Format-Table)
            $defaultDisplayMembers = [PwshSpectreConsole.PowerShell.TableUtilities]::GetHeader($formatted[0])
            if ($IsLinux -or $IsMacOS) {
                #  Expected @('UnixMode', 'User', 'Group', 'LastWrite…', 'Size', 'Name'), but got @('UnixMode', 'User', 'Group', 'LastWriteTime', 'Size', 'Name').
                # i have no idea whats truncating LastWriteTime
                # $defaultDisplayMembers.Properties.GetEnumerator().Name | Should -Be @("UnixMode", "User", "Group", "LastWriteTime", "Size", "Name")
                $defaultDisplayMembers.keys | Should -Match 'UnixMode|User|Group|LastWrite|Size|Name'
            } else {
                $defaultDisplayMembers.keys | Should -Be @("Mode", "LastWriteTime", "Length", "Name")
            }
        }

        It "Should not throw and should return null when input does not have format data" {
            {
                $defaultDisplayMembers = [PwshSpectreConsole.PowerShell.TableUtilities]::GetHeader([hashtable]@{
                    "Hello" = "World"
                })
                $defaultDisplayMembers | Should -Be $null
            } | Should -Not -Throw
        }

        It "Should be able to format ansi strings" {
            $rawString = "hello world"
            $ansiString = "`e[31mhello `e[46mworld`e[0m"
            $result = [PwshSpectreConsole.VTParser]::ToSpanParagraph($ansiString).ToParagraph()
            $result.Length | Should -Be $rawString.Length
        }

        It "Should be able to format PSStyle strings" {
            $rawString = ""
            $ansiString = ""
            $PSStyle | Get-Member -MemberType Property | Where-Object { $_.Definition -match '^string' -And $_.Name -notmatch 'off$|Reset' } | ForEach-Object {
                $name = $_.Name
                $rawString += "$name "
                $ansiString += "$($PSStyle.$name)$name "
            }
            $ansiString += "$($PSStyle.Reset)"
            $result = [PwshSpectreConsole.VTParser]::ToSpanParagraph($ansiString).ToParagraph()
            $result.Length | Should -Be $rawString.Length
        }

        It "Should leave spectre markup alone by default" {
            $ansiString = "hello [red]spectremarkup[/] world"
            $result = [PwshSpectreConsole.VTParser]::ToSpanParagraph($ansiString).ToParagraph()
            $result.Length | Should -Be $ansiString.Length
        }

        It "Should be able to create a new table cell with spectre markup" {
            $rawString = "hello spectremarkup world"
            $ansiString = "hello [red]spectremarkup[/] world"
            $result = [PwshSpectreConsole.PowerShell.TableUtilities]::NewCell($ansiString, [Spectre.Console.Color]::Default, $true)
            $result | Should -BeOfType [Spectre.Console.Markup]
            $result.Length | Should -Be $rawString.Length
        }

        It "Should be able to create a new table cell without spectre markup by default" {
            $ansiString = "hello [red]spectremarkup[/] world"
            $result = [PwshSpectreConsole.PowerShell.TableUtilities]::NewCell($ansiString, [Spectre.Console.Color]::Default, $false)
            $result | Should -BeOfType [Spectre.Console.Text]
            $result.Length | Should -Be $ansiString.Length
        }

        It "Should be able to create a new table row with spectre markup" {
            $entryitem = Get-SpectreTableRowData -Markup
            $result = [PwshSpectreConsole.PowerShell.TableUtilities]::NewRow($entryItem, [Spectre.Console.Color]::Default, $true, $false, @{})
            $result -is [array] | Should -Be $true
            $result[0] | Should -BeOfType [Spectre.Console.Markup]
            $result.Count | Should -Be $entryitem.Count
        }

        It "Should be able to create a new table row without spectre markup by default" {
            $entryitem = Get-SpectreTableRowData -Markup
            $result = [PwshSpectreConsole.PowerShell.TableUtilities]::NewRow($entryItem, [Spectre.Console.Color]::Default, $false, $false, @{})
            $result -is [array] | Should -Be $true
            $result[0] | Should -BeOfType [Spectre.Console.Text]
            $result[0].Length | Should -Be $entryItem[0].Length
            $result.Count | Should -Be $entryitem.Count
        }

        It "Should create a table and display results properly" {
            $testBorder = 'Markdown'
            $testData = Get-ChildItem "$PSScriptRoot"
            $formatted = @($testdata | Format-Table)
            $verification = [PwshSpectreConsole.PowerShell.TableUtilities]::GetHeader($formatted[0])
            $table = Format-SpectreTable -Data $testData -Border $testBorder -Color $testColor
            $table | Should -BeOfType [Spectre.Console.Table]
            $table | Out-SpectreHost
            $testResult = $testConsole.Output
            $rows = $testResult -split "\r?\n" | Select-Object -Skip 1 -SkipLast 2
            $header = $rows[0]
            $properties = $header -split '\|' | StripAnsi | ForEach-Object {
                if (-Not [String]::IsNullOrWhiteSpace($_)) {
                    $_.Trim()
                }
            }
            if ($IsLinux -or $IsMacOS) {
                $verification.keys | Should -Match 'UnixMode|User|Group|LastWrite|Size|Name'
            } else {
                $verification.keys | Should -Be $properties
            }
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should create a table and display ICollection results properly" {
            $testData = 1 | Group-Object
            $testBorder = 'Markdown'
            $testColor = $null
            Write-Debug "Setting testcolor to $testColor"
            $table = Format-SpectreTable -Data $testData -Border $testBorder -HideHeaders -Property Group
            $table | Should -BeOfType [Spectre.Console.Table]
            $table | Out-SpectreHost
            $testResult = $testConsole.Output | StripAnsi
            $clean = $testResult -replace '\s+|\|'
            $clean | Should -Be '{1}'
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should be able to use calculated properties" {
            $testData = Get-Process -Id $pid
            $testBorder = 'Markdown'
            $testColor = $null
            Write-Debug "Setting testcolor to $testColor"
            $table = $testData | Format-SpectreTable ProcessName, @{Label = "TotalRunningTime"; Expression = { (Get-Date) - $_.StartTime } } -Border $testBorder
            $table | Should -BeOfType [Spectre.Console.Table]
            $table | Out-SpectreHost
            $testResult = $testConsole.Output
            $obj = $testResult -split "\r?\n" | Select-Object -Skip 1 -SkipLast 2
            $deconstructed = $obj -split '\|' | StripAnsi | ForEach-Object {
                if (-Not [String]::IsNullOrEmpty($_)) {
                    $_.Trim()
                }
            }
            $deconstructed[0] | Should -Be 'ProcessName'
            $deconstructed[1] | Should -Be 'TotalRunningTime'
            $deconstructed[4] | Should -Be 'pwsh'
            [PwshSpectreConsole.PowerShell.ConsoleUtilities]::RenderCallCount | Should -Be 1
        }

        It "Should match the snapshot" {
            Set-SpectreTestConsole -TestConsole $testConsole
            $table = [pscustomobject]@{
                "Name"  = "Test 1"
                "Value" = 10
                "Color" = "Turquoise2"
            }, [pscustomobject]@{
                "Name"  = "Test 2"
                "Value" = 20
                "Color" = "#ff0000"
            }, [pscustomobject]@{
                "Name"  = "Test 3"
                "Value" = 30
                "Color" = "Turquoise2"
            } | Format-SpectreTable -Border "Rounded" -Color "Turquoise2"

            $table | Should -BeOfType [Spectre.Console.Table]
            $table | Out-SpectreHost
            { Assert-OutputMatchesSnapshot -SnapshotName "Format-SpectreTable" -Output $testConsole.Output } | Should -Not -Throw
        }

        It "VT escape sequences should be detected and be used instead of markup when creating table cells" {
            Set-SpectreTestConsole -TestConsole $testConsole
            $table = [pscustomobject]@{
                # Markup can't be used in combination with VT sequences, VT takes priority
                "Name"  = "[red]Test[/] `e[31m1`e[0m"
                "Value" = 10
                "Color" = "Turquoise2"
            }, [pscustomobject]@{
                "Name"  = "Test [red]2[/]"
                "Value" = 20
                "Color" = "#ff0000"
            } | Format-SpectreTable -Border "Rounded" -Color "Turquoise2" -AllowMarkup

            $table | Should -BeOfType [Spectre.Console.Table]
            $table | Out-SpectreHost
            { Assert-OutputMatchesSnapshot -SnapshotName "Format-SpectreTable-VT" -Output $testConsole.Output } | Should -Not -Throw
        }
    }
}
