$ErrorActionPreference = 'Stop'
$Scanner = 'C:\Users\drmul\Digital Asset Vault\01-Apps and Websites\Secret Sentinel\SecretSentinel.ps1'
$PowerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$TempRoot = Join-Path ([IO.Path]::GetTempPath()) ('SS-Test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
try {
    $Sample = Join-Path $TempRoot 'sample.ps1'
    Set-Content -LiteralPath $Sample -Value @(
        '$example = "ordinary application code"'
        'Write-Output "Hello, world"'
    )
    Write-Host 'TEST 1: Scanner launches...' -ForegroundColor Cyan
    $Output = & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $Scanner -Root $TempRoot 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Scanner failed with exit code $LASTEXITCODE"
    }
    Write-Host 'PASS: Scanner launched.' -ForegroundColor Green
    Write-Host 'TEST 2: Clean sample does not trigger selected secret rules...' -ForegroundColor Cyan
    if ($Output -match 'AWS access key|GitHub token|Slack token|Stripe live key|Google API key|Possible API token|Possible hardcoded password') {
        throw 'Clean sample produced a suspicious finding.'
    }
    Write-Host 'PASS: No selected secret-pattern false positives.' -ForegroundColor Green
    Write-Host 'VALIDATION COMPLETE' -ForegroundColor Green
}
finally {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

