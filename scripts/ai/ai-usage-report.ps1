param(
    [string]$LogPath = "",

    [int]$LastDays = 30
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($LogPath)) {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $LogPath = Join-Path $repoRoot "logs/ai-usage.jsonl"
}

if (-not (Test-Path $LogPath)) {
    Write-Output "No AI usage log found: $LogPath"
    exit 0
}

$from = (Get-Date).ToUniversalTime().AddDays(-1 * $LastDays)
$events = Get-Content -Path $LogPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { $_ | ConvertFrom-Json } |
    Where-Object { [datetime]$_.timestampUtc -ge $from }

if (-not $events) {
    Write-Output "No AI usage events for the last $LastDays days."
    exit 0
}

Write-Output "AI usage events for the last $LastDays days"
Write-Output ""

$events |
    Group-Object vendor, event |
    Sort-Object Count -Descending |
    ForEach-Object {
        $name = $_.Name -replace ", ", " / "
        Write-Output ("{0}: {1}" -f $name, $_.Count)
    }
