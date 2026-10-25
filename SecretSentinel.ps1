param(
    [string]$Root = (Get-Location).Path
)
$ErrorActionPreference = "Stop"
$patterns = @(
    @{ Name = "AWS access key"; Severity = "Critical"; Regex = '\bAKIA[0-9A-Z]{16}\b' },
    @{ Name = "Google API key"; Severity = "Critical"; Regex = '\bAIza[0-9A-Za-z_-]{35}\b' },
    @{ Name = "GitHub token"; Severity = "Critical"; Regex = '\bgh[pousr]_[A-Za-z0-9_]{20,}\b|\bgithub_pat_[A-Za-z0-9_]{20,}\b' },
    @{ Name = "Slack token"; Severity = "Critical"; Regex = '\bxox[baprs]-[A-Za-z0-9-]{10,}\b' },
    @{ Name = "Stripe live key"; Severity = "Critical"; Regex = '\b(?:sk|rk)_live_[A-Za-z0-9]{16,}\b' },
    @{ Name = "Private key header"; Severity = "Critical"; Regex = '-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----' },
    @{ Name = "Possible API token"; Severity = "Warning"; Regex = '(?i)\b(api[_-]?key|access[_-]?token|secret[_-]?key)\s*[:=]\s*["''][^"'']{8,}["'']' },
    @{ Name = "Possible hardcoded password"; Severity = "Warning"; Regex = '(?i)\b(password|passwd|pwd)\s*[:=]\s*["''][^"'']{4,}["'']' }
)
$extensions = @(
    ".py", ".js", ".jsx", ".ts", ".tsx", ".java", ".kt", ".kts",
    ".go", ".rs", ".php", ".rb", ".env", ".json", ".yaml", ".yml",
    ".toml", ".properties", ".xml", ".sh", ".ps1", ".sql",
    ".tf", ".config"
)
$skipDirs = @(
    ".git", ".gradle", ".idea", ".venv", "venv", "node_modules",
    "build", "dist", "out", "__pycache__", ".next", "target"
)
$rootPath = (Resolve-Path -LiteralPath $Root).Path
$findings = [System.Collections.Generic.List[object]]::new()
$scanned = 0
$unreadable = 0
Write-Host "`n=== SECRET SENTINEL ===" -ForegroundColor Cyan
Write-Host "Folder: $rootPath"
$files = Get-ChildItem -LiteralPath $rootPath -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Length -le 2MB -and
        $extensions -contains $_.Extension.ToLowerInvariant() -and
        -not ($_.FullName.Substring($rootPath.Length).Split([IO.Path]::DirectorySeparatorChar) |
            Where-Object { $skipDirs -contains $_ })
    }
$totalFiles = @($files).Count
$fileIndex = 0
foreach ($file in $files) {
    $fileIndex++
    $percent = if ($totalFiles -gt 0) {
        [int](($fileIndex / $totalFiles) * 100)
    } else {
        100
    }
    Write-Progress -Activity "Secret Sentinel scanning files" `
        -Status "$fileIndex of $totalFiles files" `
        -PercentComplete $percent
    try {
        $lines = @(Get-Content -LiteralPath $file.FullName -ErrorAction Stop)
        $scanned++
        for ($i = 0; $i -lt $lines.Count; $i++) {
            foreach ($pattern in $patterns) {
                if ($lines[$i] -match $pattern.Regex) {
                    $relative = $file.FullName.Substring($rootPath.Length).TrimStart('\')
                    $findings.Add([PSCustomObject]@{
                        File = $relative
                        Line = $i + 1
                        Type = $pattern.Name; Severity = $pattern.Severity
                    })
                }
            }
        }
    }
    catch {
        $unreadable++
    }
}
Write-Progress -Activity "Secret Sentinel scanning files" -Completed
Write-Host "Files scanned: $scanned"
Write-Host "Unreadable files: $unreadable`n"
if ($findings.Count -gt 0) {
    $findings |
        Sort-Object Severity, File, Line, Type -Unique |
        Format-Table Severity, File, Line, Type -AutoSize
    $report = Join-Path $rootPath (
        "SecretSentinel-Report-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss")
    )
    $findings |
        Sort-Object Severity, File, Line, Type -Unique |
        Export-Csv -LiteralPath $report -NoTypeInformation -Encoding UTF8
    $uniqueFindings = @($findings | Sort-Object Severity, File, Line, Type -Unique)
    $criticalCount = @($uniqueFindings | Where-Object Severity -eq "Critical").Count
    $warningCount = @($uniqueFindings | Where-Object Severity -eq "Warning").Count
    Write-Host "`n=== SEVERITY SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Critical findings: $criticalCount" -ForegroundColor Red
    Write-Host "Warnings:          $warningCount" -ForegroundColor Yellow
    Write-Host "Total findings:    $($uniqueFindings.Count)" -ForegroundColor White
    Write-Host "CSV report saved to: $report" -ForegroundColor Green
}
else {
    Write-Host "No matches found."
}
Write-Host "Note: heuristic matches can be false positives."
Write-Host "Secret values are not included in the report."





