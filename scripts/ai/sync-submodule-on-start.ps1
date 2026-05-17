#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Cross-platform submodule auto-update at session start.

.DESCRIPTION
    Fast-forwards 'tiss.ai.kit.standart' submodule to upstream when:
    - submodule is a git repository
    - current branch has an upstream
    - local HEAD is an ancestor of upstream (no diverged history, no local commits)

    Skips silently otherwise and always finishes with '{}' on stdout so vendor
    hooks (Cursor / Codex / Claude) can parse the result. Diagnostic lines go to stderr.

    Works on Windows, macOS, Linux under PowerShell 7+ (pwsh).
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

function Write-Log {
    param([string]$Message)
    [Console]::Error.WriteLine("sync-submodule-on-start: $Message")
}

function Write-Done {
    Write-Output "{}"
}

function Get-RepoRoot {
    param([string]$Fallback)
    try {
        $root = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($root)) {
            return $root.Trim()
        }
    } catch {}
    return $Fallback
}

$scriptDir = Split-Path -Parent $PSCommandPath
$scriptRepoRoot = (Resolve-Path (Join-Path $scriptDir ".." | Join-Path -ChildPath "..")).Path
$repoRoot = Get-RepoRoot -Fallback $scriptRepoRoot

$submodulePath = Join-Path $repoRoot "tiss.ai.kit.standart"
if (-not (Test-Path (Join-Path $submodulePath ".git"))) {
    $repoRoot = $scriptRepoRoot
    $submodulePath = Join-Path $repoRoot "tiss.ai.kit.standart"
}

$syncScriptPath = Join-Path $repoRoot "scripts/ai/sync-ai-kit.ps1"
if (-not (Test-Path $syncScriptPath)) {
    $syncScriptPath = Join-Path $submodulePath "scripts/ai/sync-ai-kit.ps1"
}

if (-not (Test-Path $submodulePath -PathType Container)) {
    Write-Log "submodule directory not found: $submodulePath"
    Write-Done
    exit 0
}

git -C $submodulePath rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Log "submodule directory is not a git repository: $submodulePath"
    Write-Done
    exit 0
}

git -C $submodulePath fetch --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Log "failed to fetch remote changes"
    Write-Done
    exit 0
}

$upstream = (git -C $submodulePath rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($upstream)) {
    Write-Log "current submodule branch has no upstream"
    Write-Done
    exit 0
}

$localHead  = (git -C $submodulePath rev-parse HEAD 2>$null).Trim()
$remoteHead = (git -C $submodulePath rev-parse $upstream 2>$null).Trim()
$baseHead   = (git -C $submodulePath merge-base HEAD $upstream 2>$null).Trim()

if ($localHead -eq $remoteHead) {
    Write-Log "submodule is already up to date"
    Write-Done
    exit 0
}

if ($localHead -ne $baseHead) {
    Write-Log "submodule has local commits or diverged history; skipping automatic pull"
    Write-Done
    exit 0
}

git -C $submodulePath pull --ff-only --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Log "failed to fast-forward submodule"
    Write-Done
    exit 0
}

if (-not (Test-Path $syncScriptPath)) {
    Write-Log "sync script not found: $syncScriptPath"
    Write-Done
    exit 0
}

Write-Log "running sync script: $syncScriptPath -DryRun"
& pwsh -NoProfile -File $syncScriptPath -DryRun 1>&2
if ($LASTEXITCODE -ne 0) {
    Write-Log "sync script failed"
}

Write-Done
exit 0
