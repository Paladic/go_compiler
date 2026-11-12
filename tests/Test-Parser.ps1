param([string]$ParserPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (!$ParserPath) { $ParserPath = Join-Path $projectRoot 'build/parser.exe' }
$ParserPath = [IO.Path]::GetFullPath($ParserPath)
if (!(Test-Path -LiteralPath $ParserPath -PathType Leaf)) { throw 'Build the parser first: ./build.ps1' }
. (Join-Path $projectRoot 'tools/Invoke-NativeTool.ps1')
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$results = @()
$failed = 0
$syntaxCount = 0
$pendingCount = 0
foreach ($testCase in $manifest) {
    $sourcePath = Join-Path $PSScriptRoot $testCase.file
    $result = Invoke-Tool $ParserPath @($sourcePath, '--check')
    if ($testCase.stage -eq 'semantic') {
        $pendingCount++
        if ($result.ExitCode -notin @(0, 1)) {
            throw "Parser process failed for deferred input $($testCase.file): exit $($result.ExitCode)"
        }
        $results += [pscustomobject]@{
            file=$testCase.file;stage='semantic';passed=$null;status='pending'
            syntaxAccepted=($result.ExitCode -eq 0);reason=$testCase.reason;error=$result.StandardError
        }
        continue
    }
    $syntaxCount++
    $passed = if ($testCase.valid) {
        $result.ExitCode -eq 0 -and [string]::IsNullOrEmpty($result.StandardError)
    } else {
        $result.ExitCode -eq 1 -and $result.StandardError.StartsWith($sourcePath + ':')
    }
    if (!$passed) {
        $failed++
        Write-Host "FAIL $($testCase.file): exit $($result.ExitCode) $($result.StandardError)" -ForegroundColor Red
    }
    $results += [pscustomobject]@{file=$testCase.file;stage='syntax';passed=$passed;status=$(if ($passed) {'passed'} else {'failed'});error=$result.StandardError}
}
$report = [pscustomobject]@{total=$syntaxCount;passed=$syntaxCount-$failed;failed=$failed;pendingSemantic=$pendingCount;corpusTotal=$manifest.Count;results=$results}
$utf8 = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $projectRoot 'build/parser-report.json'),($report | ConvertTo-Json -Depth 6),$utf8)
Write-Host "Syntax tests: $($report.passed) / $($report.total)"
Write-Host "Deferred validation: $pendingCount (not implemented; not counted as passed)"
if ($failed) { exit 1 }
exit 0
