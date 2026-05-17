param(
    [Parameter(Mandatory = $true)]
    [string]$Vendor,

    [Parameter(Mandatory = $true)]
    [string]$Event,

    [string]$Result = "",

    [string]$Skill = "",

    [string]$Subagent = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$logDirectory = Join-Path $repoRoot "logs"
$logPath = Join-Path $logDirectory "ai-usage.jsonl"

New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

$entry = [ordered]@{
    timestampUtc = (Get-Date).ToUniversalTime().ToString("o")
    vendor = $Vendor
    event = $Event
}

if (-not [string]::IsNullOrWhiteSpace($Result)) {
    $entry.result = $Result
}

if (-not [string]::IsNullOrWhiteSpace($Skill)) {
    $entry.skill = $Skill
}

if (-not [string]::IsNullOrWhiteSpace($Subagent)) {
    $entry.subagent = $Subagent
}

($entry | ConvertTo-Json -Compress) | Add-Content -Path $logPath -Encoding UTF8
