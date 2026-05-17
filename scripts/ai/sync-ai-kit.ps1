#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Cross-platform sync (Windows / macOS / Linux) для копирования содержимого AI-kit
    (skills, subagents, policies, vendor configs) из submodule в корень сервисного репо.

.DESCRIPTION
    Использует только pwsh stdlib: Get-ChildItem, Copy-Item, Test-Path, Remove-Item.
    Совместимо с PowerShell 7+ (pwsh) на Windows, macOS, Linux.

.PARAMETER DryRun
    Если задано — печатает что будет скопировано, без записи на диск.

.PARAMETER KitPath
    Путь к корню kit (абсолютный или относительный к корню сервисного репо).
    Если не задан — берётся $env:AI_KIT_PATH, затем строка из scripts/ai/ai-kit.default-path,
    иначе fallback 'tiss.ai.kit.standart'.

.PARAMETER Exclude
    Дополнительные имена top-level элементов (файлы или папки) для исключения.
    Можно передавать несколько раз: -Exclude a -Exclude b.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$KitPath = "",
    [string[]]$Exclude = @()
)

$ErrorActionPreference = "Stop"

function Test-IsAbsolutePath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    return [System.IO.Path]::IsPathRooted($Path)
}

function Read-DefaultKitPath {
    param([string]$ScriptDir)
    $defaultFile = Join-Path $ScriptDir "ai-kit.default-path"
    if (-not (Test-Path $defaultFile)) { return $null }
    foreach ($line in Get-Content -Path $defaultFile) {
        $trimmed = $line.Trim()
        if (-not [string]::IsNullOrWhiteSpace($trimmed) -and -not $trimmed.StartsWith("#")) {
            return $trimmed
        }
    }
    return $null
}

function Read-ExcludeFile {
    param([string]$ScriptDir)
    $excludeFile = Join-Path $ScriptDir "ai-kit.sync-exclude.json"
    if (-not (Test-Path $excludeFile)) { return @() }
    try {
        $json = Get-Content -Path $excludeFile -Raw | ConvertFrom-Json
        if ($null -ne $json.excludeNames) {
            return @($json.excludeNames)
        }
    } catch {
        Write-Warning "Failed to parse exclude file: $excludeFile ($_)"
    }
    return @()
}

function Get-RepoRoot {
    param([string]$Fallback)
    try {
        $root = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($root)) {
            return $root.Trim()
        }
    } catch {}
    if (Test-Path $Fallback) { return (Resolve-Path $Fallback).Path }
    return $null
}

$scriptDir = Split-Path -Parent $PSCommandPath
$repoCandidate = (Resolve-Path (Join-Path $scriptDir ".." | Join-Path -ChildPath "..")).Path
$repoRoot = Get-RepoRoot -Fallback $repoCandidate

if (-not $repoRoot) {
    Write-Error "Not a git repository (git rev-parse --show-toplevel failed)."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($KitPath)) { $KitPath = $env:AI_KIT_PATH }
if ([string]::IsNullOrWhiteSpace($KitPath)) { $KitPath = Read-DefaultKitPath -ScriptDir $scriptDir }
if ([string]::IsNullOrWhiteSpace($KitPath)) { $KitPath = "tiss.ai.kit.standart" }

if (-not (Test-IsAbsolutePath $KitPath)) {
    $KitPath = Join-Path $repoRoot $KitPath
}
if (Test-Path $KitPath) {
    $KitPath = (Resolve-Path $KitPath).Path
}

if (-not (Test-Path $KitPath -PathType Container)) {
    Write-Error @"
Kit path not found: $KitPath
Options:
  1) git submodule add <kit-url> <folder> && git submodule update --init
  2) set AI_KIT_PATH or pass -KitPath (absolute or relative to repo root)
  3) edit scripts/ai/ai-kit.default-path with one non-comment line
"@
    exit 1
}

$builtinExcludes = @(".git", "scripts", "README.md")
$fileExcludes    = Read-ExcludeFile -ScriptDir $scriptDir
$excludeNames    = @($builtinExcludes + $fileExcludes + $Exclude) | Sort-Object -Unique

Write-Host "Repo root: $repoRoot"
Write-Host "Kit root:  $KitPath"
Write-Host ("Excluded top-level names: " + ($excludeNames -join ", "))
if ($DryRun) { Write-Host "DRY-RUN (no writes)" }

$found = 0
foreach ($entry in Get-ChildItem -Path $KitPath -Force) {
    if ($excludeNames -contains $entry.Name) { continue }
    $found++

    $srcFull = $entry.FullName
    $dstFull = Join-Path $repoRoot $entry.Name

    if ($entry.PSIsContainer) {
        if ($DryRun) {
            Write-Host "WOULD SYNC  $($entry.Name)  (DIR)  ->  $dstFull"
            continue
        }
        if (Test-Path $dstFull) { Remove-Item -Path $dstFull -Recurse -Force }
        Copy-Item -Path $srcFull -Destination $dstFull -Recurse -Force
        Write-Host "DIR   $($entry.Name)"
    } else {
        if ($DryRun) {
            Write-Host "WOULD SYNC  $($entry.Name)  (FILE)  ->  $dstFull"
            continue
        }
        Copy-Item -Path $srcFull -Destination $dstFull -Force
        Write-Host "FILE  $($entry.Name)"
    }
}

if ($found -eq 0) {
    Write-Warning "No items to copy (kit empty or all excluded)."
    exit 0
}

Write-Host "Done. Review git diff and commit if OK."
exit 0
