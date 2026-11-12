param([string]$ParserPath, [switch]$ExportTrees)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (!$ParserPath) { $ParserPath = Join-Path $projectRoot 'build/parser.exe' }
$ParserPath = [IO.Path]::GetFullPath($ParserPath)
if (!(Test-Path -LiteralPath $ParserPath -PathType Leaf)) { throw 'Build the parser first: ./build.ps1' }
. (Join-Path $projectRoot 'tools/Invoke-NativeTool.ps1')

$utf8 = New-Object Text.UTF8Encoding($false)
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json

function Write-TreeIndex {
    param([string]$Path, [array]$Cases)

    $statusLabels = @{
        tree = 'Построено дерево'
        semantic = 'Ожидает семантической проверки'
        'ast-error' = 'Отклонено проверкой AST'
        'syntax-error' = 'Разбор остановился'
    }
    $rows = foreach ($case in ($Cases | Sort-Object file)) {
        $file = [Net.WebUtility]::HtmlEncode($case.file)
        $page = [Net.WebUtility]::HtmlEncode($case.page)
        $label = $statusLabels[$case.status]
        '<tr data-status="{0}"><td><a href="{1}"><code>{2}</code></a></td><td>{3}</td><td><a href="../../tests/{2}">Исходник</a></td></tr>' -f $case.status, $page, $file, $label
    }
    $html = @"
<!doctype html>
<html lang="ru">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Деревья тестов Go</title>
<style>
:root { color-scheme: light dark; --line: light-dark(#cbd5e1,#3b4655); }
body { margin: auto; padding: 2rem 1.25rem 4rem; max-width: 70rem; font: 16px/1.5 Inter,system-ui,sans-serif; background: Canvas; color: CanvasText; }
h1 { margin: .6rem 0; font-size: clamp(1.6rem,4vw,2.4rem); }
.filters { display: flex; flex-wrap: wrap; gap: .7rem 1rem; align-items: center; margin: 1.3rem 0; }
input, select { font: inherit; padding: .35rem; max-width: 100%; }
.table { overflow: auto; }
table { width: 100%; border-collapse: collapse; }
th, td { text-align: left; padding: .45rem .65rem; border-bottom: 1px solid var(--line); }
code { overflow-wrap: anywhere; }
</style>
<main>
<a href="../AST.html">Обзор AST и запуск парсера</a>
<h1>Деревья тестов Go</h1>
<p>Откройте тест, чтобы увидеть граф узлов или место ошибки в исходнике.</p>
<div class="filters">
<label>Имя файла <input type="search" id="query" placeholder="Например, switch"></label>
<label>Результат <select id="status">
<option value="">Все</option>
<option value="tree">Построено дерево</option>
<option value="semantic">Ожидает семантической проверки</option>
<option value="ast-error">Отклонено проверкой AST</option>
<option value="syntax-error">Разбор остановился</option>
</select></label>
<output id="count" aria-live="polite">$($Cases.Count) из $($Cases.Count)</output>
</div>
<div class="table"><table>
<thead><tr><th>Тест</th><th>Результат</th><th>Файл .go</th></tr></thead>
<tbody>
$($rows -join [Environment]::NewLine)
</tbody>
</table></div>
</main>
<script>
const rows = [...document.querySelectorAll("tbody tr")];
const query = document.getElementById("query");
const status = document.getElementById("status");
function filter() {
  const name = query.value.trim().toLowerCase();
  let visible = 0;
  for (const row of rows) {
    row.hidden = !row.cells[0].textContent.toLowerCase().includes(name)
      || (status.value && row.dataset.status !== status.value);
    if (!row.hidden) visible++;
  }
  document.getElementById("count").textContent = visible + " из " + rows.length;
}
query.addEventListener("input", filter);
status.addEventListener("change", filter);
</script>
</html>
"@
    [IO.File]::WriteAllText($Path, $html, $utf8)
}

$staging = $null
$pages = @()
Push-Location $projectRoot
try {
    if ($ExportTrees) {
        $staging = Join-Path $projectRoot ('build/tree-export-' + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $staging | Out-Null
    }

    $results = foreach ($testCase in $manifest) {
        $sourcePath = if ($ExportTrees) { 'tests/' + $testCase.file } else { Join-Path $PSScriptRoot $testCase.file }
        $toolArguments = @($sourcePath, '--check')
        if ($ExportTrees) {
            $tempPage = Join-Path $staging ($pages.Count.ToString() + '.html')
            $toolArguments += @('--html', $tempPage)
        }
        $result = Invoke-Tool $ParserPath $toolArguments
        $stage = if ($testCase.stage) { $testCase.stage } else { 'syntax' }
        $passed = if ($testCase.valid) {
            $result.ExitCode -eq 0 -and [string]::IsNullOrEmpty($result.StandardError)
        } else {
            $result.ExitCode -eq 1 -and $result.StandardError.StartsWith($sourcePath + ':')
        }
        if ($ExportTrees) {
            $passed = $passed -and (Test-Path -LiteralPath $tempPage -PathType Leaf)
            $status = if ($stage -eq 'semantic') { 'semantic' }
                      elseif ($testCase.valid) { 'tree' }
                      elseif ($stage -eq 'ast') { 'ast-error' }
                      else { 'syntax-error' }
            $page = [IO.Path]::ChangeExtension(($testCase.file -replace '^valid/', ''), '.html')
            $pages += [pscustomobject]@{ file=$testCase.file; status=$status; page=$page; temporary=$tempPage }
        }
        if (!$passed) {
            Write-Host "FAIL $($testCase.file): exit $($result.ExitCode) $($result.StandardError)" -ForegroundColor Red
        }
        [pscustomobject]@{ file=$testCase.file; stage=$stage; parserPassed=$passed; error=$result.StandardError }
    }

    $syntax = @($results | Where-Object stage -eq syntax)
    $ast = @($results | Where-Object stage -eq ast)
    $pending = @($results | Where-Object stage -eq semantic)
    $failed = @($results | Where-Object { !$_.parserPassed }).Count
    $report = [pscustomobject]@{
        corpusTotal=$manifest.Count
        failed=$failed
        pendingSemantic=$pending.Count
        results=$results
    }
    [IO.File]::WriteAllText((Join-Path $projectRoot 'build/parser-report.json'), ($report | ConvertTo-Json -Depth 6), $utf8)
    Write-Host "Syntax tests: $(@($syntax | Where-Object parserPassed).Count) / $($syntax.Count)"
    Write-Host "AST validation tests: $(@($ast | Where-Object parserPassed).Count) / $($ast.Count)"
    Write-Host "Semantic cases: $($pending.Count) (parser acceptance checked, semantic analysis pending)"
    if ($failed) { exit 1 }

    if ($ExportTrees) {
        $treeRoot = Join-Path $projectRoot 'docs/trees'
        New-Item -ItemType Directory -Path (Join-Path $treeRoot 'invalid') -Force | Out-Null
        foreach ($case in $pages) {
            Move-Item -LiteralPath $case.temporary -Destination (Join-Path $treeRoot $case.page) -Force
        }
        Write-TreeIndex (Join-Path $treeRoot 'index.html') $pages
        Write-Host "Exported $($pages.Count) pages to docs/trees/index.html"
    }
} finally {
    Pop-Location
    if ($staging -and (Test-Path -LiteralPath $staging -PathType Container)) {
        Get-ChildItem -LiteralPath $staging -File | ForEach-Object { Remove-Item -LiteralPath $_.FullName }
        Remove-Item -LiteralPath $staging
    }
}
exit 0
