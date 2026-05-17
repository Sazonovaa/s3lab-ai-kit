$ErrorActionPreference = "Stop"

$repoRoot = & git rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
    throw "Run this script inside a Git repository."
}

$hooksDirectory = Join-Path $repoRoot ".git\hooks"
if (-not (Test-Path -LiteralPath $hooksDirectory)) {
    New-Item -ItemType Directory -Force -Path $hooksDirectory | Out-Null
}

$hookPath = Join-Path $hooksDirectory "pre-commit"
$hookContent = @(
    '#!/bin/sh',
    'REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0',
    'VALIDATOR="$REPO_ROOT/scripts/validations/validate-crlf.ps1"',
    '',
    'if command -v pwsh >/dev/null 2>&1; then',
    '  pwsh -NoProfile -ExecutionPolicy Bypass -File "$VALIDATOR"',
    'elif command -v powershell.exe >/dev/null 2>&1; then',
    '  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$VALIDATOR"',
    'else',
    '  echo "PowerShell is required to validate CRLF before commit." >&2',
    '  exit 1',
    'fi',
    '',
    'exit $?'
) -join "`n"

Set-Content -LiteralPath $hookPath -Value $hookContent -Encoding ASCII -NoNewline

$chmod = Get-Command chmod -ErrorAction SilentlyContinue
if ($chmod) {
    & chmod +x $hookPath
}

Write-Host "Installed Git pre-commit hook: $hookPath"
