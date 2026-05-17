$ErrorActionPreference = "Stop"

function Get-GitOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    $output = & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed"
    }

    return $output
}

function Test-HasLfWithoutCr {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]] $Bytes
    )

    for ($index = 0; $index -lt $Bytes.Length; $index++) {
        if ($Bytes[$index] -eq 10 -and ($index -eq 0 -or $Bytes[$index - 1] -ne 13)) {
            return $true
        }
    }

    return $false
}

$repoRoot = Get-GitOutput -Arguments @("rev-parse", "--show-toplevel")
if (-not $repoRoot) {
    exit 0
}

Set-Location $repoRoot

$stagedFiles = Get-GitOutput -Arguments @("diff", "--cached", "--name-only", "--diff-filter=ACMR")
if (-not $stagedFiles) {
    exit 0
}

$violations = New-Object System.Collections.Generic.List[string]

foreach ($file in $stagedFiles) {
    if ([string]::IsNullOrWhiteSpace($file)) {
        continue
    }

    $numstat = Get-GitOutput -Arguments @("diff", "--cached", "--numstat", "--", $file)
    if ($numstat -match "^\s*-\s+-\s+") {
        continue
    }

    $fullPath = Join-Path $repoRoot $file
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        continue
    }

    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    if ($bytes -contains 0) {
        continue
    }

    if (Test-HasLfWithoutCr -Bytes $bytes) {
        $violations.Add($file)
    }
}

if ($violations.Count -gt 0) {
    Write-Error "CRLF validation failed. Staged text files with LF-only line endings: $($violations -join ', ')"
    Write-Error "Convert these files to CRLF before commit."
    exit 1
}

exit 0
