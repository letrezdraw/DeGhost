param([string]$DryRun = $env:DEGHOST_DRYRUN)

. "$PSScriptRoot\log.ps1"

$dryRun = $DryRun -eq "true"

Write-Log "Applying gaming optimizations..."

if ($dryRun) {
    $tweaks = @(
        "Disable GameDVR",
        "Enable Auto Game Mode",
        "Disable network throttling",
        "Enable GPU hardware scheduling (HAGS)",
        "Optimize CPU scheduler (Win32PrioritySeparation=38)",
        "Disable background apps",
        "Disable power throttling",
        "Optimize timer resolution",
        "Apply Ultimate Performance power plan"
    )
    foreach ($t in $tweaks) { Write-Log "[DRY RUN] Would apply: $t" }
} else {
    # Disable GameDVR
    reg add "HKCU\System\GameConfigStore"         /v GameDVR_Enabled    /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\Software\Microsoft\GameBar"     /v AllowAutoGameMode  /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\Software\Microsoft\GameBar"     /v AutoGameModeEnabled /t REG_DWORD /d 1 /f | Out-Null
    Write-Log "GameDVR disabled, Auto Game Mode enabled"

    # Network throttling
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness  /t REG_DWORD /d 0          /f | Out-Null
    Write-Log "Network throttling disabled"

    # GPU Hardware-Accelerated Scheduling
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f | Out-Null
    Write-Log "GPU hardware scheduling enabled"

    # CPU Scheduler – foreground boost
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f | Out-Null
    Write-Log "CPU scheduler optimized (Win32PrioritySeparation=38)"

    # Disable background apps
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f | Out-Null
    Write-Log "Background apps disabled"

    # Input latency – disable power throttling
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f | Out-Null
    Write-Log "Power throttling disabled"

    # Input latency – timer resolution
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f | Out-Null
    Write-Log "Timer resolution optimized"

    # Ultimate Performance power plan
    try {
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
        $guidLine = powercfg -list | Where-Object { $_ -match "Ultimate" } | Select-Object -First 1
        if ($guidLine -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
            powercfg -setactive $Matches[1] | Out-Null
        }
        Write-Log "Ultimate Performance power plan applied"
    } catch {
        Write-Log "Power plan tweak skipped: $_" "WARN"
    }
}

Write-Log "Gaming optimization complete"
