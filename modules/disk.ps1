param([string]$DryRun = $env:DEGHOST_DRYRUN)

. "$PSScriptRoot\log.ps1"

$dryRun = $DryRun -eq "true"

Write-Log "Applying disk optimizations..."

if ($dryRun) {
    Write-Log "[DRY RUN] Would enable TRIM, disable last-access timestamps, disable 8.3 filenames"
} else {
    # Enable TRIM
    fsutil behavior set DisableDeleteNotify 0 | Out-Null
    Write-Log "TRIM enabled"

    # Disable last-access timestamp (reduces write I/O)
    fsutil behavior set disablelastaccess 1 | Out-Null
    Write-Log "Last-access timestamps disabled"

    # Disable 8.3 filename creation
    fsutil behavior set disable8dot3 1 | Out-Null
    Write-Log "8.3 filenames disabled"

    # Detect drive type and apply specific tweaks
    try {
        $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq "0" } | Select-Object -First 1
        if ($disk.MediaType -match "SSD|NVMe|Solid") {
            Write-Log "SSD/NVMe detected – skipping defrag schedule"
            reg add "HKLM\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction" /v Enable /t REG_SZ /d N /f | Out-Null
        }
    } catch {
        Write-Log "Drive type detection skipped: $_" "WARN"
    }
}

Write-Log "Disk optimization complete"
