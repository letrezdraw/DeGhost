param([string]$DryRun = $env:DEGHOST_DRYRUN)

. "$PSScriptRoot\log.ps1"

$dryRun = $DryRun -eq "true"

Write-Log "Optimizing startup..."

if ($dryRun) {
    Write-Log "[DRY RUN] Would remove startup delay, disable Teams/Edge/Discord/Spotify/AdobeCC auto-start"
} else {
    # Remove startup delay
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f | Out-Null
    Write-Log "Startup delay removed"

    # Disable Edge startup boost / prelaunch
    reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main"         /v AllowPrelaunch       /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\TabPreloader" /v PreventTabPreloading /t REG_DWORD /d 1 /f | Out-Null
    Write-Log "Edge startup boost disabled"

    # Disable Teams auto-start
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "com.squirrel.Teams.Teams" /f 2>$null | Out-Null
    Write-Log "Teams startup disabled"

    # Disable Discord auto-start
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Discord" /f 2>$null | Out-Null
    Write-Log "Discord startup disabled"

    # Disable Spotify auto-start
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Spotify" /f 2>$null | Out-Null
    Write-Log "Spotify startup disabled"

    # Disable Adobe Creative Cloud auto-start
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "AdobeGCInvoker-1.0" /f 2>$null | Out-Null
    Write-Log "Adobe CC startup disabled"
}

Write-Log "Startup optimization complete"
