param([string]$DryRun = $env:DEGHOST_DRYRUN)

. "$PSScriptRoot\log.ps1"

$dryRun = $DryRun -eq "true"

Write-Log "Starting debloat..."

# Apps to remove (keeps Store, Xbox, drivers)
$apps = @(
    "*Clipchamp*",
    "*Teams*",
    "*Weather*",
    "*News*",
    "*GetHelp*",
    "*GetStarted*",
    "*Feedback*",
    "*BingSearch*",
    "*MixedReality*",
    "*Messaging*",
    "*3DViewer*",
    "*Print3D*",
    "*Solitaire*",
    "*ZuneVideo*",
    "*ZuneMusic*",
    "*Maps*",
    "*Alarms*",
    "*Wallet*",
    "*People*",
    "*YourPhone*",
    "*Cortana*",
    "*549981C3F5F10*"
)

foreach ($a in $apps) {
    if ($dryRun) {
        $pkg = Get-AppxPackage $a -ErrorAction SilentlyContinue
        if ($pkg) { Write-Log "[DRY RUN] Would remove: $($pkg.Name)" }
    } else {
        $pkg = Get-AppxPackage $a -ErrorAction SilentlyContinue
        if ($pkg) {
            Write-Log "Removing: $($pkg.Name)"
            Remove-AppxPackage $pkg -ErrorAction SilentlyContinue
        }
    }
}

# Disable Copilot
if ($dryRun) {
    Write-Log "[DRY RUN] Would disable Copilot and Widgets"
} else {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null
    Write-Log "Copilot disabled"

    # Disable Widgets / News and Interests
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f | Out-Null
    Write-Log "Widgets/News disabled"
}

Write-Log "Debloat complete"
