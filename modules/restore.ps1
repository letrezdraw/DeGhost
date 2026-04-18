. "$PSScriptRoot\log.ps1"

$backupDir = Join-Path (Get-Location).Path "backup"

Write-Host ""
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "       DeGhost Restore" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Restore Registry (HKLM + HKCU)"
Write-Host "2. Restore Services"
Write-Host "3. Open System Restore"
Write-Host "4. Undo Gaming Tweaks"
Write-Host "0. Back"
Write-Host ""

$choice = Read-Host "Choose"

switch ($choice) {
    "1" {
        Write-Log "Restoring registry..."
        if (Test-Path "$backupDir\hklm.reg") {
            reg import "$backupDir\hklm.reg" 2>$null
            Write-Log "HKLM registry restored"
        } else {
            Write-Log "No HKLM backup found" "WARN"
        }
        if (Test-Path "$backupDir\hkcu.reg") {
            reg import "$backupDir\hkcu.reg" 2>$null
            Write-Log "HKCU registry restored"
        } else {
            Write-Log "No HKCU backup found" "WARN"
        }
    }
    "2" {
        Write-Log "Restoring services..."
        if (Test-Path "$backupDir\services.csv") {
            $services = Import-Csv "$backupDir\services.csv"
            foreach ($svc in $services) {
                $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
                if ($s) {
                    $startType = switch ($svc.StartType) {
                        "Automatic" { "auto"     }
                        "Manual"    { "demand"   }
                        "Disabled"  { "disabled" }
                        default     { "demand"   }
                    }
                    sc.exe config $svc.Name start=$startType 2>$null | Out-Null
                    Write-Log "Restored service: $($svc.Name) -> $($svc.StartType)"
                }
            }
        } else {
            Write-Log "No service backup found" "WARN"
        }
    }
    "3" {
        Write-Log "Opening System Restore UI..."
        Start-Process rstrui.exe
    }
    "4" {
        Write-Log "Undoing gaming tweaks..."
        reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 2 /f | Out-Null
        reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /f 2>$null | Out-Null
        reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /f 2>$null | Out-Null
        Write-Log "Gaming tweaks undone"
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
