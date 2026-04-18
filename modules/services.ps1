param(
    [string]$Profile = $env:DEGHOST_MODE,
    [string]$DryRun  = $env:DEGHOST_DRYRUN
)

. "$PSScriptRoot\log.ps1"

$dryRun = $DryRun -eq "true"
if (-not $Profile) { $Profile = "balanced" }

# Service lists per profile
$gamingServices     = @("SysMain","DiagTrack","MapsBroker","RetailDemo","WSearch","Fax","XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc","WMPNetworkSvc")
$workstationServices = @("DiagTrack","MapsBroker","RetailDemo","Fax","WMPNetworkSvc","XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc")
$balancedServices   = @("DiagTrack","MapsBroker","RetailDemo","Fax")

$services = switch ($Profile) {
    "gaming"      { $gamingServices }
    "workstation" { $workstationServices }
    default       { $balancedServices }
}

Write-Log "Applying service profile: $Profile"

foreach ($svc in $services) {
    if ($dryRun) {
        Write-Log "[DRY RUN] Would disable service: $svc"
    } else {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            Stop-Service  $svc -Force -ErrorAction SilentlyContinue
            Set-Service   $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Log "Disabled service: $svc"
        }
    }
}

Write-Log "Service profile applied: $Profile"
