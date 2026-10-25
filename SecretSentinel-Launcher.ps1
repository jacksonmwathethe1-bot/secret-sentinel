$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
$project = $PSScriptRoot
$scanner = Join-Path $project "SecretSentinel.ps1"
$vault = "C:\Users\drmul\Digital Asset Vault\01-Apps and Websites"
while ($true) {
    Clear-Host
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "          SECRET SENTINEL" -ForegroundColor Cyan
    Write-Host "       Local Secret Scanner" -ForegroundColor Gray
    Write-Host "======================================"
    Write-Host ""
    Write-Host "  1. Scan this project"
    Write-Host "  2. Choose a folder with a window"
    Write-Host "  3. Scan my Apps and Websites vault"
    Write-Host "  4. Open latest CSV report"
    Write-Host "  5. Exit"
    Write-Host ""
    $choice = Read-Host "Choose an option (1-5)"
    if ($choice -eq "5") { break }
    switch ($choice) {
        "1" { $target = $project }
        "2" {
            $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $dialog.Description = "Choose a folder for Secret Sentinel to scan"
            $dialog.ShowNewFolderButton = $false
            $result = $dialog.ShowDialog()
            if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
                $dialog.Dispose()
                Write-Host "Folder selection cancelled." -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
                continue
            }
            $target = $dialog.SelectedPath
            $dialog.Dispose()
        }
        "3" { $target = $vault }
        "4" {
            $latest = Get-ChildItem -LiteralPath $project -Filter "SecretSentinel-Report-*.csv" -File |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1
            if ($latest) { Invoke-Item -LiteralPath $latest.FullName }
            else { Write-Host "No reports found in the project folder." -ForegroundColor Yellow }
            Read-Host "Press Enter to continue"
            continue
        }
        default {
            Write-Host "Invalid choice." -ForegroundColor Yellow
            Read-Host "Press Enter to continue"
            continue
        }
    }
    if (!(Test-Path -LiteralPath $target -PathType Container)) {
        Write-Host "Folder not found: $target" -ForegroundColor Red
    } else {
        Write-Host "`nScanning: $target" -ForegroundColor Green
        & $scanner -Root $target
    }
    Write-Host ""
    Read-Host "Press Enter to return to the menu"
}
