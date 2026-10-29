param([switch]$DebugBuild, [switch]$Test)
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    $bison = Get-Command win_bison,bison -ErrorAction SilentlyContinue | Select-Object -First 1
    $flex = Get-Command win_flex,flex -ErrorAction SilentlyContinue | Select-Object -First 1
    if (!$bison -or !$flex) { throw 'Flex/Bison commands were not found in PATH.' }

    New-Item -ItemType Directory -Path build/generated -Force | Out-Null
    & $bison.Source -Wall -Werror=conflicts-sr -Werror=conflicts-rr -d -o build/generated/parser.tab.cpp parser/parser.y
    if ($LASTEXITCODE -ne 0) { throw 'Bison failed.' }
    & $flex.Source -o build/generated/scanner.cpp lexer/lexer.l
    if ($LASTEXITCODE -ne 0) { throw 'Flex failed.' }

    $sources = @(
        'parser/main.cpp',
        'parser/Parser.cpp',
        'build/generated/parser.tab.cpp',
        'build/generated/scanner.cpp',
        'lexer/LexerSupport.cpp'
    )

    $flags = @('-std=c++17','-Wall','-Wextra','-static','-Iparser','-Ilexer','-Ibuild/generated')
    if ($DebugBuild) { $flags += @('-O0','-g') } else { $flags += '-O2' }
    & g++ @flags @sources -lshell32 '-Wl,--stack,16777216' -o build/parser.exe
    if ($LASTEXITCODE -ne 0) { throw 'C++ compilation failed.' }
    Write-Host 'Built build/parser.exe'
    if ($Test) {
        $testSources = @('tests/ParserStateTests.cpp') + @($sources | Where-Object { $_ -ne 'parser/main.cpp' })
        & g++ @flags @testSources -lshell32 '-Wl,--stack,16777216' -o build/parser-tests.exe
        if ($LASTEXITCODE -ne 0) { throw 'C++ test compilation failed.' }
        & ./build/parser-tests.exe
        if ($LASTEXITCODE -ne 0) { throw 'C++ tests failed.' }
    }
} finally {
    Pop-Location
}
