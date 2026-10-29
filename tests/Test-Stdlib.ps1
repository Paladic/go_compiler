param([string]$ParserPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $projectRoot 'tools/Invoke-NativeTool.ps1')
if (!$ParserPath) { $ParserPath = Join-Path $projectRoot 'build/parser.exe' }
$goRoot = (& go env GOROOT).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Cannot locate the installed Go standard library.' }
$files = @(Get-ChildItem -LiteralPath (Join-Path $goRoot 'src') -Filter '*.go' -Recurse -File |
    Where-Object { $_.FullName -notmatch '[\\/]testdata[\\/]' })
$failures = @()
$counter = 0
foreach ($sourceFile in $files) {
    $counter++
    $result = Invoke-Tool $ParserPath @($sourceFile.FullName, '--check')
    if ($result.ExitCode -ne 0) {
        $failures += [pscustomobject]@{file=$sourceFile.FullName;code=$result.ExitCode;error=$result.StandardError}
        Write-Host "FAIL $($sourceFile.FullName)" -ForegroundColor Red
    }
    if ($counter % 1000 -eq 0) { Write-Host "Checked $counter / $($files.Count)" }
}
$report = [pscustomobject]@{total=$files.Count;passed=$files.Count-$failures.Count;failed=$failures.Count;failures=$failures}
$utf8 = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $projectRoot 'build/stdlib-report.json'),($report | ConvertTo-Json -Depth 6),$utf8)
Write-Host "Standard library: $($report.passed) / $($report.total)"
if ($failures.Count) { exit 1 }
