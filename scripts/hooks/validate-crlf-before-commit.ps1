param(
    [Parameter(Mandatory = $true)]
    [string] $HookInputPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $HookInputPath)) {
    Write-Output '{ "permission": "allow" }'
    exit 0
}

$rawInput = Get-Content -LiteralPath $HookInputPath -Raw
if ([string]::IsNullOrWhiteSpace($rawInput)) {
    Write-Output '{ "permission": "allow" }'
    exit 0
}

try {
    $payload = $rawInput | ConvertFrom-Json
} catch {
    Write-Output '{ "permission": "allow" }'
    exit 0
}

$command = ""
if ($payload.PSObject.Properties.Name -contains "command") {
    $command = [string] $payload.command
} elseif ($payload.PSObject.Properties.Name -contains "Command") {
    $command = [string] $payload.Command
} elseif ($payload.PSObject.Properties.Name -contains "tool_input" -and $payload.tool_input.PSObject.Properties.Name -contains "command") {
    $command = [string] $payload.tool_input.command
} elseif ($payload.PSObject.Properties.Name -contains "toolInput" -and $payload.toolInput.PSObject.Properties.Name -contains "command") {
    $command = [string] $payload.toolInput.command
}

if ($command -notmatch "(?i)(^|[;&|]\s*)git(\.exe)?\s+commit(\s|$)") {
    Write-Output '{ "permission": "allow" }'
    exit 0
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$validatorPath = Join-Path $repoRoot "scripts\validations\validate-crlf.ps1"

if (-not (Test-Path -LiteralPath $validatorPath)) {
    Write-Output '{ "permission": "deny", "user_message": "Commit blocked: CRLF validator was not found.", "agent_message": "CRLF validator script is missing." }'
    exit 2
}

Set-Location $repoRoot
& powershell -NoProfile -ExecutionPolicy Bypass -File $validatorPath
if ($LASTEXITCODE -ne 0) {
    Write-Output '{ "permission": "deny", "user_message": "Commit blocked: staged text files must use CRLF line endings.", "agent_message": "Run scripts/validations/validate-crlf.ps1 for the list of files with LF-only line endings." }'
    exit 2
}

Write-Output '{ "permission": "allow" }'
exit 0
