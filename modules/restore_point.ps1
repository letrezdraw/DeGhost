. "$PSScriptRoot\log.ps1"

$backupDir = Join-Path (Get-Location).Path "backup"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }

# System restore point
Write-Log "Creating system restore point..."
try {
    Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "DeGhost Pre-Optimization" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Log "System restore point created"
} catch {
    Write-Log "Restore point skipped (System Protection may be off): $_" "WARN"
}

# Registry backup
Write-Log "Backing up registry..."
Start-Process reg -ArgumentList "export HKLM `"$backupDir\hklm.reg`" /y" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
Start-Process reg -ArgumentList "export HKCU `"$backupDir\hkcu.reg`" /y" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
Write-Log "Registry backed up to $backupDir"

# Services backup
Write-Log "Backing up services..."
try {
    Get-Service | Select-Object Name, StartType | Export-Csv "$backupDir\services.csv" -NoTypeInformation
    Write-Log "Services backed up to $backupDir\services.csv"
} catch {
    Write-Log "Service backup failed: $_" "WARN"
}

Write-Log "Backup complete"
