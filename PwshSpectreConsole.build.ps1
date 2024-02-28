[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Debug'
)
$modulePath = [IO.Path]::Combine($PSScriptRoot, 'Module')
$manifestItem = Get-Item ([IO.Path]::Combine($modulePath, '*.psd1'))
$ModuleName = $manifestItem.BaseName
$psm1 = Join-Path $modulePath -ChildPath ($ModuleName + '.psm1')

$testModuleManifestSplat = @{
    Path          = $manifestItem.FullName
    ErrorAction   = 'Ignore'
    WarningAction = 'Ignore'
}

$Manifest = Test-ModuleManifest @testModuleManifestSplat
$Version = $Manifest.Version

$BuildPath = [IO.Path]::Combine($PSScriptRoot, 'output')
$CSharpPath = [IO.Path]::Combine($modulePath, 'source')
$isBinaryModule = Test-Path $CSharpPath
$ReleasePath = [IO.Path]::Combine($BuildPath, $ModuleName, $Version)
$UseNativeArguments = $PSVersionTable.PSVersion -gt '7.0'

task Clean {
    if (Test-Path $ReleasePath) {
        Remove-Item $ReleasePath -Recurse -Force
    }
    New-Item -ItemType Directory $ReleasePath | Out-Null
}
# Set-Alias MSBuild (Resolve-MSBuild)
# task Dependencies {

# }

# task BuildDocs {
#     $helpParams = @{
#         Path       = [IO.Path]::Combine($PSScriptRoot, 'docs', 'en-US')
#         OutputPath = [IO.Path]::Combine($ReleasePath, 'en-US')
#     }
#     New-ExternalHelp @helpParams | Out-Null
# }

task BuildPowerShell {
    $buildModuleSplat = @{
        SourcePath      = $modulePath
        OutputDirectory = $ReleasePath
        Encoding        = 'UTF8Bom'
        IgnoreAlias     = $true
    }
    # if (Test-Path $psm1) {
    #     $buildModuleSplat['Prefix'] = Get-Content $psm1 -Raw
    # }
    Build-Module @buildModuleSplat
}

task BuildManaged {
    Push-Location $CSharpPath
    $arguments = @(
        'publish'
        '--configuration', $Configuration
        '--verbosity', 'q'
        '-nologo'
        "-p:Version=$Version"
    )
    try {
        # $csproj = Get-Item ([IO.Path]::Combine($CSharpPath, '*.csproj'))
        [xml]$csharpProjectInfo = Get-Content ([IO.Path]::Combine($CSharpPath, $ModuleName + '.csproj'))
        # [xml]$csharpProjectInfo = Get-Content $csproj
        $targetFrameworks = @($csharpProjectInfo.Project.PropertyGroup.TargetFrameworks.Split(
                ';', [StringSplitOptions]::RemoveEmptyEntries))

        foreach ($framework in $targetFrameworks) {
            Write-Host "Compiling $($_.Name) for $framework"
            dotnet @arguments --framework $framework

            if ($LASTEXITCODE) {
                throw "Failed to compiled code for $framework"
            }
        }
    }
    finally {
        Pop-Location
    }
}



task CopyToRelease {
    [xml]$csharpProjectInfo = Get-Content ([IO.Path]::Combine($CSharpPath, $ModuleName + '.csproj'))
    $targetFrameworks = @($csharpProjectInfo.Project.PropertyGroup.TargetFrameworks.Split(
            ';', [StringSplitOptions]::RemoveEmptyEntries))

    foreach ($framework in $targetFrameworks) {
        $buildFolder = [IO.Path]::Combine($CSharpPath, 'bin', $Configuration, $framework, 'publish')
        $binFolder = [IO.Path]::Combine($ReleasePath, 'lib', $framework)
        if (-not (Test-Path -LiteralPath $binFolder)) {
            New-Item -Path $binFolder -ItemType Directory | Out-Null
        }
        Copy-Item ([IO.Path]::Combine($buildFolder, "*.dll")) -Destination $binFolder -Exclude "System.Management.Automation.*"
    }
}

task Analyze {
    $analyzerPath = [IO.Path]::Combine($PSScriptRoot, 'Tools', 'ScriptAnalyzerSettings.psd1')
    if (-not (Test-Path $analyzerPath)) {
        Write-Host 'No analyzer rules found, skipping...'
        return
    }

    $pssaSplat = @{
        Path        = $ReleasePath
        Settings    = $analyzerPath
        Recurse     = $true
        ErrorAction = 'SilentlyContinue'
        # Fix         = $true
        # Debug       = $true
        # verbose     = $true
    }
    $results = Invoke-ScriptAnalyzer @pssaSplat

    # if ($null -ne $results) {
    #     $results | Out-String
    #     throw 'Failed PsScriptAnalyzer tests, build failed'
    # }
}

task DoUnitTest {
    $testsPath = [IO.Path]::Combine($PSScriptRoot, 'Tests')
    if (-not (Test-Path -LiteralPath $testsPath)) {
        Write-Host 'No unit tests found, skipping...'
        return
    }

    $resultsPath = [IO.Path]::Combine($BuildPath, 'TestResults')
    if (-not (Test-Path -LiteralPath $resultsPath)) {
        New-Item $resultsPath -ItemType Directory -ErrorAction Stop | Out-Null
    }

    $tempResultsPath = [IO.Path]::Combine($resultsPath, 'TempUnit')
    if (Test-Path -LiteralPath $tempResultsPath) {
        Remove-Item -LiteralPath $tempResultsPath -Force -Recurse
    }
    New-Item -Path $tempResultsPath -ItemType Directory | Out-Null

    try {
        $runSettingsPrefix = 'DataCollectionRunSettings.DataCollectors.DataCollector.Configuration'
        $arguments = @(
            'test'
            $testsPath
            '--results-directory', $tempResultsPath
            if ($Configuration -eq 'Debug') {
                '--collect:"XPlat Code Coverage"'
                '--'
                "$runSettingsPrefix.Format=json"
                if ($UseNativeArguments) {
                    "$runSettingsPrefix.IncludeDirectory=`"$CSharpPath`""
                }
                else {
                    "$runSettingsPrefix.IncludeDirectory=\`"$CSharpPath\`""
                }
            }
        )

        Write-Host 'Running unit tests'
        dotnet @arguments

        if ($LASTEXITCODE) {
            throw 'Unit tests failed'
        }

        if ($Configuration -eq 'Debug') {
            Move-Item -Path $tempResultsPath/*/*.json -Destination $resultsPath/UnitCoverage.json -Force
        }
    }
    finally {
        Remove-Item -LiteralPath $tempResultsPath -Force -Recurse
    }
}

task DoTest {
    $testsPath = [IO.Path]::Combine($PSScriptRoot, 'Tests')
    if (-not (Test-Path $testsPath)) {
        Write-Host 'No Pester tests found, skipping...'
        return
    }

    $resultsPath = [IO.Path]::Combine($BuildPath, 'TestResults')
    if (-not (Test-Path $resultsPath)) {
        New-Item $resultsPath -ItemType Directory -ErrorAction Stop | Out-Null
    }

    Get-ChildItem -LiteralPath $resultsPath |
        Remove-Item -ErrorAction Stop -Force

    $pesterScript = [IO.Path]::Combine($PSScriptRoot, 'tools', 'PesterTest.ps1')

    $testArgs = @{
        TestPath    = $testsPath
        ResultPath  = $resultsPath
        SourceRoot  = $modulePath
        ReleasePath = $ReleasePath
    }

    & $pesterScript @testArgs
}

task Build -Jobs Clean, BuildManaged, BuildPowerShell, CopyToRelease
task Test -Jobs BuildManaged, Analyze, DoTest
task . Build
