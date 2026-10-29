function ConvertTo-WindowsArgument {
    param([AllowEmptyString()][string]$Argument)

    # Windows argv: double backslashes before quotes and before the closing quote.
    $escaped = $Argument -replace '(\\*)"', '$1$1\"'
    $escaped = $escaped -replace '(\\+)$', '$1$1'
    return '"' + $escaped + '"'
}

function Invoke-Tool {
    param([string]$Executable, [string[]]$ToolArguments)

    $process = New-Object Diagnostics.Process
    try {
        $start = $process.StartInfo
        $start.FileName = $Executable
        $start.Arguments = ($ToolArguments | ForEach-Object { ConvertTo-WindowsArgument $_ }) -join ' '
        $start.WorkingDirectory = (Get-Location).ProviderPath
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $start.RedirectStandardOutput = $true
        $start.RedirectStandardError = $true
        $start.StandardOutputEncoding = [Text.Encoding]::UTF8
        $start.StandardErrorEncoding = [Text.Encoding]::UTF8

        # Read both streams concurrently; PowerShell 5.1 must not format stderr as ErrorRecord.
        [void]$process.Start()
        $outputTask = $process.StandardOutput.ReadToEndAsync()
        $errorTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        [void]$outputTask.GetAwaiter().GetResult()
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StandardError = $errorTask.GetAwaiter().GetResult()
        }
    } finally {
        $process.Dispose()
    }
}
