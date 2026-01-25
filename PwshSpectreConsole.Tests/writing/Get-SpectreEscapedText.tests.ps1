BeforeAll {
    if (-Not (Get-Module PwshSpectreConsole)) {
        $ModulePath = Join-Path $PSScriptRoot ".." ".." "PwshSpectreConsole" "PwshSpectreConsole.psd1"
        Import-Module $ModulePath
    }
    if (-Not (Get-Module TestHelpers)) {
        $TestHelpersPath = Join-Path $PSScriptRoot ".." "TestHelpers.psm1"
        Import-Module $TestHelpersPath
    }
}

Describe "Get-SpectreEscapedText" {
    InModuleScope "PwshSpectreConsole" {

        It "formats a busted string" {
            Get-SpectreEscapedText -Text "][[][]]][[][][][" | Should -Be "]][[[[]][[]]]]]][[[[]][[]][[]][["
        }

        It "handles pipelined input" {
            "[[][]]][[][][]" | Get-SpectreEscapedText | Should -Be "[[[[]][[]]]]]][[[[]][[]][[]]"
        }

        It "leaves emoji alone, unfortunately these aren't escaped in spectre console" {
            "[[][]]][[]:zany_face:[][]" | Get-SpectreEscapedText | Should -Be "[[[[]][[]]]]]][[[[]]:zany_face:[[]][[]]"
        }
    }
}
