$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$wrapper = Join-Path $repoRoot 'scripts\invoke-agy.ps1'
$testTempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
$fakeBin = Join-Path $testTempRoot "delegate-to-agy-fake-bin-$([guid]::NewGuid().ToString('N'))"
$originalPath = $env:PATH

New-Item -ItemType Directory -Path $fakeBin | Out-Null
$fakeSource = @'
using System;
using System.IO;
using System.Text;

public static class Program {
    private static string Json(string value) {
        return (value ?? "").Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "\\r").Replace("\n", "\\n");
    }

    public static int Main(string[] args) {
        var argvFile = Environment.GetEnvironmentVariable("FAKE_AGY_ARGV_FILE");
        if (!string.IsNullOrEmpty(argvFile)) {
            var encoded = new string[args.Length];
            for (var i = 0; i < args.Length; i++) encoded[i] = Convert.ToBase64String(Encoding.UTF8.GetBytes(args[i]));
            File.WriteAllLines(argvFile, encoded);
        }
        var status = Environment.GetEnvironmentVariable("FAKE_AGY_STATUS") ?? "SUCCESS";
        var response = Environment.GetEnvironmentVariable("FAKE_AGY_RESPONSE") ?? "";
        var error = Environment.GetEnvironmentVariable("FAKE_AGY_ERROR") ?? "";
        var raw = Environment.GetEnvironmentVariable("FAKE_AGY_RAW");
        if (!string.IsNullOrEmpty(raw)) Console.WriteLine(raw);
        else Console.WriteLine("{\"status\":\"" + Json(status) + "\",\"response\":\"" + Json(response) + "\",\"error\":\"" + Json(error) + "\",\"conversation_id\":\"00000000-0000-4000-8000-000000000001\",\"duration_seconds\":0,\"num_turns\":1}");
        int code;
        return int.TryParse(Environment.GetEnvironmentVariable("FAKE_AGY_EXIT"), out code) ? code : 0;
    }
}
'@
$fakeSourcePath = Join-Path $fakeBin 'agy.cs'
[System.IO.File]::WriteAllText($fakeSourcePath, $fakeSource)
& 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe' /nologo /target:exe "/out:$(Join-Path $fakeBin 'agy.exe')" $fakeSourcePath
if ($LASTEXITCODE -ne 0) { throw 'Failed to compile fake agy executable.' }

function Assert-Equal {
    param([object]$Actual, [object]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "$Message. Expected '$Expected', got '$Actual'." }
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Remove-TestDirectory {
    param([string]$Path, [string]$RequiredNamePrefix)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $tempPrefix = $testTempRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($tempPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
        -not [System.IO.Path]::GetFileName($fullPath).StartsWith($RequiredNamePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe test cleanup target: $fullPath"
    }
    if (Test-Path -LiteralPath $fullPath) { Remove-Item -LiteralPath $fullPath -Recurse -Force }
}

function Invoke-FakeCase {
    param(
        [string]$Name,
        [string]$Status,
        [string]$ErrorText,
        [int]$FakeExit,
        [string]$RawOutput = ''
    )

    $caseId = [guid]::NewGuid().ToString('N')
    $workspace = Join-Path $testTempRoot "agy-scratch-$caseId"
    $argvFile = Join-Path $testTempRoot "delegate-to-agy-argv-$caseId.json"
    New-Item -ItemType Directory -Path (Join-Path $workspace '.agy') | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $workspace 'input.txt'), 'input')
    $taskFile = Join-Path $workspace '.agy\task.json'
    [System.IO.File]::WriteAllText($taskFile, (@{
        schema_version = 1
        workspace_mode = 'scratch'
        kind = 'implement'
        objective = "Fake $Name case"
        acceptance_criteria = @('The fake case completes.')
        read_paths = @('input.txt')
        write_paths = @('output.txt')
        out_of_scope = @()
        timeout_seconds = 30
        conversation_id = $null
    } | ConvertTo-Json))

    try {
        $env:PATH = "$fakeBin;$originalPath"
        $env:FAKE_AGY_STATUS = $Status
        $env:FAKE_AGY_ERROR = $ErrorText
        $env:FAKE_AGY_RESPONSE = if ($Status -eq 'SUCCESS') { 'done' } else { '' }
        $env:FAKE_AGY_EXIT = [string]$FakeExit
        $env:FAKE_AGY_RAW = $RawOutput
        $env:FAKE_AGY_ARGV_FILE = $argvFile
        $output = @(& pwsh -NoProfile -File $wrapper -TaskFile $taskFile 2>&1)
        $exitCode = $LASTEXITCODE
        $receipt = Get-Content -LiteralPath (Join-Path $workspace '.agy\task.result.json') -Raw | ConvertFrom-Json
        $argv = @(Get-Content -LiteralPath $argvFile | ForEach-Object {
            [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_))
        })
        return [pscustomobject]@{ ExitCode = $exitCode; Receipt = $receipt; Argv = @($argv); Output = $output }
    } finally {
        $env:PATH = $originalPath
        Remove-Item Env:FAKE_AGY_STATUS, Env:FAKE_AGY_ERROR, Env:FAKE_AGY_RESPONSE, Env:FAKE_AGY_EXIT, Env:FAKE_AGY_RAW, Env:FAKE_AGY_ARGV_FILE -ErrorAction SilentlyContinue
        Remove-TestDirectory -Path $workspace -RequiredNamePrefix 'agy-scratch-'
        if (Test-Path -LiteralPath $argvFile) { Remove-Item -LiteralPath $argvFile -Force }
    }
}

try {
    $permission = Invoke-FakeCase -Name 'permission' -Status 'ERROR' -ErrorText 'git grep denied by sandbox permission' -FakeExit 1
    Assert-Equal $permission.ExitCode 4 'Permission denial wrapper exit code'
    Assert-Equal $permission.Receipt.category 'permission_denied' 'Permission denial category'
    Assert-Equal $permission.Receipt.retryable $false 'Permission denial retryability'
    Assert-True ($permission.Receipt.PSObject.Properties.Name -notcontains 'conversation_id') 'Failure receipts must omit raw conversation IDs.'
    Assert-True ($permission.Receipt.PSObject.Properties.Name -notcontains 'error') 'Failure receipts must omit raw AGY error text.'

    $unavailable = Invoke-FakeCase -Name 'unavailable' -Status 'ERROR' -ErrorText 'Sandbox backend is UNAVAILABLE (code 503)' -FakeExit 1
    Assert-Equal $unavailable.Receipt.category 'transient_unavailable' 'Unavailable category'
    Assert-Equal $unavailable.Receipt.retryable $true 'Unavailable retryability'

    $canceled = Invoke-FakeCase -Name 'canceled' -Status 'CANCELED' -ErrorText '' -FakeExit 1
    Assert-Equal $canceled.Receipt.category 'canceled' 'Canceled category'
    Assert-Equal $canceled.Receipt.retryable $false 'Canceled retryability'

    $timeout = Invoke-FakeCase -Name 'timeout' -Status 'TIMEOUT' -ErrorText 'sandbox operation timed out' -FakeExit 1
    Assert-Equal $timeout.Receipt.category 'timeout' 'Timeout category'
    Assert-Equal $timeout.Receipt.retryable $false 'Timeout retryability'

    $invalid = Invoke-FakeCase -Name 'invalid' -Status 'ERROR' -ErrorText '' -FakeExit 1 -RawOutput 'not-json'
    Assert-Equal $invalid.Receipt.category 'invalid_terminal_output' 'Invalid output category'
    Assert-Equal $invalid.Receipt.retryable $false 'Invalid output retryability'

    $success = Invoke-FakeCase -Name 'success' -Status 'SUCCESS' -ErrorText '' -FakeExit 0
    Assert-Equal $success.ExitCode 0 'Success wrapper exit code'
    Assert-Equal $success.Receipt.status 'SUCCESS' 'Success receipt status'
    Assert-True ($success.Argv -contains '--sandbox') 'The wrapper must retain AGY sandbox mode.'
    Assert-True ($success.Argv -notcontains '--dangerously-skip-permissions') 'The wrapper must not skip AGY permissions.'
    $promptIndex = [Array]::IndexOf($success.Argv, '-p') + 1
    Assert-True ($promptIndex -gt 0 -and $success.Argv[$promptIndex] -match 'Do not invoke shell, Git') 'The prompt must prohibit shell and Git commands.'

    Write-Output 'invoke-agy wrapper tests passed'
} finally {
    Remove-TestDirectory -Path $fakeBin -RequiredNamePrefix 'delegate-to-agy-fake-bin-'
}
