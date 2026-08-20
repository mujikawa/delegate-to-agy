[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Convert-ToStarlarkString {
    param([string]$Value)
    return $Value.Replace('\', '\\').Replace('"', '\"')
}

$userProfile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
$codexRoot = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
    Join-Path $userProfile '.codex'
} else {
    [System.IO.Path]::GetFullPath($env:CODEX_HOME)
}

$wrapperPath = [System.IO.Path]::GetFullPath((Join-Path $codexRoot 'skills\delegate-to-agy\scripts\invoke-agy.ps1'))
if (-not (Test-Path -LiteralPath $wrapperPath -PathType Leaf)) {
    throw "Install the delegate-to-agy skill before generating its rule: $wrapperPath"
}

$sampleTask = 'C:\linked-worktree\.agy\task.json'
$matchCommand = '"' + $wrapperPath + '" -TaskFile "' + $sampleTask + '"'
$validateCommand = $matchCommand + ' -ValidateOnly'
$backupCommand = '"' + $wrapperPath + '.bak" -TaskFile "' + $sampleTask + '"'
$escapedWrapper = Convert-ToStarlarkString $wrapperPath
$escapedMatch = Convert-ToStarlarkString $matchCommand
$escapedValidate = Convert-ToStarlarkString $validateCommand
$escapedBackup = Convert-ToStarlarkString $backupCommand

$ruleText = @"
prefix_rule(
    pattern = ["$escapedWrapper"],
    decision = "allow",
    justification = "Allow only the validated delegate-to-agy wrapper to access AGY credentials and network services outside the Codex sandbox.",
    match = [
        "$escapedMatch",
        "$escapedValidate",
    ],
    not_match = [
        "agy -p arbitrary",
        "$escapedBackup",
    ],
)
"@

if (-not $Apply) {
    [Console]::Out.WriteLine($ruleText)
    [Console]::Error.WriteLine('Preview only. Re-run with -Apply to install the rule.')
    exit 0
}

$rulesDirectory = Join-Path $codexRoot 'rules'
$rulePath = Join-Path $rulesDirectory 'delegate-to-agy.rules'
[void](New-Item -ItemType Directory -Force -Path $rulesDirectory)
[System.IO.File]::WriteAllText($rulePath, $ruleText, [System.Text.UTF8Encoding]::new($false))

$codexCommand = Get-Command codex -ErrorAction Stop | Select-Object -First 1
& $codexCommand.Source execpolicy check --rules $rulePath -- $wrapperPath -TaskFile $sampleTask | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Installed rule failed validation: $rulePath"
}

[Console]::Out.WriteLine("Installed and validated: $rulePath")
[Console]::Out.WriteLine('Restart Codex to load the rule.')
