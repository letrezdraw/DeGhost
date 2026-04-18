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
        $osDriveLetter = (Get-CimInstance Win32_OperatingSystem).SystemDrive
        $ldtp = Get-CimInstance -Class Win32_LogicalDiskToPartition |
                Where-Object { $_.Dependent.DeviceID -eq $osDriveLetter } |
                Select-Object -First 1
        $diskNum = if ($ldtp -and $ldtp.Antecedent.DeviceID -match 'Disk #(\d+)') { $Matches[1] } else { $null }
        $physDisk = if ($diskNum -ne $null) {
            Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $diskNum } | Select-Object -First 1
        }
        if (-not $physDisk) { $physDisk = Get-PhysicalDisk | Select-Object -First 1 }
        if ($physDisk.MediaType -match "SSD|NVMe|Solid") {
            Write-Log "SSD/NVMe detected – skipping defrag schedule"
            reg add "HKLM\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction" /v Enable /t REG_SZ /d N /f | Out-Null
        }
    } catch {
        Write-Log "Drive type detection skipped: $_" "WARN"
    }
}

Write-Log "Disk optimization complete"
