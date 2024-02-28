@{
    Severity     = @(
        'Error'
        'Warning'
    )
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
        'PSDSC*'
        'PSReviewUnusedParameter'
        'PSUseDeclaredVarsMoreThanAssignments'
        'PSUseShouldProcessForStateChangingFunctions'
        'PSUseSingularNouns'
        'PSAvoidUsingInvokeExpression'
    )
    Rules        = @{
        # PSPlaceOpenBrace           = @{
        #     Enable             = $true
        #     OnSameLine         = $true
        #     NewLineAfter       = $true
        #     IgnoreOneLineBlock = $true
        # }

        # PSPlaceCloseBrace          = @{
        #     Enable             = $true
        #     NewLineAfter       = $true
        #     newlinebefore      = $false
        #     IgnoreOneLineBlock = $true
        #     NoEmptyLineBefore  = $false
        #     NoEmptyLineAfter   = $false
        # }

        PSUseConsistentIndentation = @{
            Enable              = $true
            Kind                = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            IndentationSize     = 4
        }

        # PSUseConsistentWhitespace  = @{
        #     Enable                          = $true
        #     # CheckInnerBrace                 = $true
        #     # CheckOpenBrace                  = $true
        #     # CheckOpenParen                  = $true
        #     # CheckOperator                   = $true
        #     # CheckPipe                       = $true
        #     CheckPipeForRedundantWhitespace = $true
        #     CheckSeparator                  = $true
        #     # CheckParameter                  = $true
        # }

        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }

        PSUseCorrectCasing         = @{
            Enable = $true
        }
    }
}
