param([string]$DryRun = $env:DEGHOST_DRYRUN)

. "$PSScriptRoot\log.ps1"

$dryRun = $DryRun -eq "true"
$ramGB  = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)

Write-Log "RAM detected: ${ramGB}GB - selecting memory profile..."

if ($dryRun) {
    $profile = if ($ramGB -le 8) { "light (8GB)" } elseif ($ramGB -le 16) { "moderate (16GB)" } else { "aggressive (32GB+)" }
    Write-Log "[DRY RUN] Would apply $profile memory tweaks"
} elseif ($ramGB -le 8) {
    Write-Log "Applying light memory tweaks (8GB profile)..."
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache   /t REG_DWORD /d 0 /f | Out-Null
} elseif ($ramGB -le 16) {
    Write-Log "Applying moderate memory tweaks (16GB profile)..."
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache      /t REG_DWORD /d 0 /f | Out-Null
} else {
    Write-Log "Applying aggressive memory tweaks (32GB+ profile)..."
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache      /t REG_DWORD /d 1 /f | Out-Null
    try {
        $cs = Get-CimInstance Win32_ComputerSystem
        $cs | Set-CimInstance -Property @{ AutomaticManagedPagefile = $false } -ErrorAction SilentlyContinue
        Write-Log "Automatic managed pagefile disabled"
    } catch {
        Write-Log "Pagefile tweak skipped: $_" "WARN"
    }
}

Write-Log "Memory optimization complete"
