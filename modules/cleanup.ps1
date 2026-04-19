param(
    [ValidateSet("safe", "aggressive", "god")]
    [string]$Tier = "safe",
    [string]$IncludeSystemTemp = "true",
    [string]$IncludeUserCache = "true",
    [string]$IncludeWindowsUpdate = "false",
    [string]$IncludeCrashAndShader = "true",
    [string]$IncludeBrowserCache = "false",
    [string]$IncludeRecycleBin = "false",
    [string]$RunComponentCleanup = "false",
    [string]$DisableHibernation = "false",
    [string]$ClearShadowCopies = "false",
    [string]$RemoveOptionalFeatures = "false",
    [string]$ReportDirectory = "backup"
)

function ConvertTo-Bool {
    param(
        [string]$Value,
        [bool]$Default = $false
    )

    if ([string]::IsNullOrWhiteSpace($Value)) { return $Default }
    switch ($Value.Trim().ToLowerInvariant()) {
        "1" { return $true }
        "true" { return $true }
        "yes" { return $true }
        "y" { return $true }
        "on" { return $true }
        "0" { return $false }
        "false" { return $false }
        "no" { return $false }
        "n" { return $false }
        "off" { return $false }
        default { return $Default }
    }
}

function Get-PathSizeBytes {
    param([string]$Target)
    if ([string]::IsNullOrWhiteSpace($Target)) { return 0L }

    try {
        if ($Target -match '[\*\?]') {
            return [int64]((Get-ChildItem -Path $Target -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum)
        }

        if (-not (Test-Path -LiteralPath $Target)) { return 0L }
        $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
        if (-not $item) { return 0L }
        if ($item.PSIsContainer) {
            return [int64]((Get-ChildItem -LiteralPath $Target -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum)
        }
        return [int64]$item.Length
    } catch {
        return 0L
    }
}

function Remove-PathSafe {
    param(
        [string]$Target,
        [System.Collections.Generic.List[string]]$LockedPaths,
        [System.Collections.Generic.List[string]]$FailedPaths
    )

    if ([string]::IsNullOrWhiteSpace($Target)) { return }

    $removeErrors = @()
    try {
        if ($Target -match '[\*\?]') {
            Remove-Item -Path $Target -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +removeErrors
        } elseif (Test-Path -LiteralPath $Target) {
            Remove-Item -LiteralPath $Target -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +removeErrors
        }
    } catch {
        $removeErrors += $_
    }

    foreach ($err in $removeErrors) {
        $message = $err.Exception.Message
        if ($message -match '(?i)being used by another process|access to the path .* (is )?denied') {
            $LockedPaths.Add($Target)
        } else {
            $FailedPaths.Add($Target)
        }
    }
}

function Get-TopConsumerUsage {
    param([string]$SystemDrive)

    $targets = @(
        "$SystemDrive\Windows",
        "$SystemDrive\Users",
        "$SystemDrive\Program Files",
        "$SystemDrive\Program Files (x86)",
        "$SystemDrive\ProgramData",
        "$SystemDrive\pagefile.sys",
        "$SystemDrive\hiberfil.sys",
        "$SystemDrive\swapfile.sys"
    )

    $rows = foreach ($target in $targets) {
        if (-not (Test-Path -LiteralPath $target)) { continue }
        $size = Get-PathSizeBytes -Target $target
        if ($size -gt 0) {
            [pscustomobject]@{
                Path = $target
                SizeGB = [math]::Round($size / 1GB, 2)
            }
        }
    }

    return $rows | Sort-Object SizeGB -Descending
}

function Run-DeepAction {
    param(
        [string]$Name,
        [scriptblock]$Action,
        [System.Collections.Generic.List[string]]$ResultCollector
    )

    try {
        & $Action
        $ResultCollector.Add("${Name}: OK")
    } catch {
        $ResultCollector.Add("${Name}: FAILED - $($_.Exception.Message)")
    }
}

$systemDrive = if ($env:SystemDrive) { $env:SystemDrive } else { "C:" }
$beforeFree = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$systemDrive'" -ErrorAction SilentlyContinue).FreeSpace

$useSystemTemp = ConvertTo-Bool $IncludeSystemTemp $true
$useUserCache = ConvertTo-Bool $IncludeUserCache $true
$useWindowsUpdate = ConvertTo-Bool $IncludeWindowsUpdate $false
$useCrashAndShader = ConvertTo-Bool $IncludeCrashAndShader $true
$useBrowserCache = ConvertTo-Bool $IncludeBrowserCache $false
$useRecycleBin = ConvertTo-Bool $IncludeRecycleBin $false
$runComponentCleanup = ConvertTo-Bool $RunComponentCleanup $false
$disableHibernation = ConvertTo-Bool $DisableHibernation $false
$clearShadowCopies = ConvertTo-Bool $ClearShadowCopies $false
$removeOptionalFeatures = ConvertTo-Bool $RemoveOptionalFeatures $false

$categories = [ordered]@{
    "System Temp / Logs" = @(
        "${env:TEMP}\*",
        "${env:WINDIR}\Temp\*",
        "${env:WINDIR}\Logs\*",
        "${env:ProgramData}\Microsoft\Windows\WER\Temp\*"
    )
    "User Cache / Temp" = @(
        "${env:LOCALAPPDATA}\Temp\*",
        "${env:LOCALAPPDATA}\Packages\*\TempState\*",
        "${env:LOCALAPPDATA}\Microsoft\Windows\INetCache\*"
    )
    "Windows Update / Delivery Cache" = @(
        "${env:WINDIR}\SoftwareDistribution\Download\*",
        "${env:ProgramData}\Microsoft\Windows\DeliveryOptimization\Cache\*",
        "${env:LOCALAPPDATA}\Microsoft\Windows\DeliveryOptimization\Cache\*"
    )
    "Crash / Shader / Thumbnail Cache" = @(
        "${env:LOCALAPPDATA}\CrashDumps\*",
        "${env:LOCALAPPDATA}\D3DSCache\*",
        "${env:LOCALAPPDATA}\Microsoft\Windows\Explorer\thumbcache*.db",
        "${env:ProgramData}\Microsoft\Windows\WER\ReportArchive\*",
        "${env:ProgramData}\Microsoft\Windows\WER\ReportQueue\*"
    )
    "Browser Cache" = @(
        "${env:LOCALAPPDATA}\Google\Chrome\User Data\Default\Cache\*",
        "${env:LOCALAPPDATA}\Google\Chrome\User Data\Default\Code Cache\*",
        "${env:LOCALAPPDATA}\Microsoft\Edge\User Data\Default\Cache\*",
        "${env:LOCALAPPDATA}\Microsoft\Edge\User Data\Default\Code Cache\*",
        "${env:APPDATA}\Mozilla\Firefox\Profiles\*\cache2\entries\*"
    )
    "Vendor Cache" = @(
        "${env:LOCALAPPDATA}\NVIDIA\*",
        "${env:ProgramData}\NVIDIA Corporation\NV_Cache\*"
    )
}

if ($useRecycleBin) {
    $recycleTargets = @()
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $recycleTargets += (Join-Path -Path $_.Root -ChildPath "`$Recycle.Bin\*")
    }
    $categories["Recycle Bin"] = $recycleTargets
}

Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $root = $_.Root
    $categories["System Temp / Logs"] += "$root\Temp\*"
    $categories["System Temp / Logs"] += "$root\Cache\*"
    $categories["System Temp / Logs"] += "$root\Logs\*"
}

$selected = [ordered]@{}
if ($useSystemTemp) { $selected["System Temp / Logs"] = $categories["System Temp / Logs"] }
if ($useUserCache) { $selected["User Cache / Temp"] = $categories["User Cache / Temp"] }
if ($useWindowsUpdate) { $selected["Windows Update / Delivery Cache"] = $categories["Windows Update / Delivery Cache"] }
if ($useCrashAndShader) { $selected["Crash / Shader / Thumbnail Cache"] = $categories["Crash / Shader / Thumbnail Cache"] }
if ($useBrowserCache) { $selected["Browser Cache"] = $categories["Browser Cache"] }
$selected["Vendor Cache"] = $categories["Vendor Cache"]
if ($useRecycleBin -and $categories.Contains("Recycle Bin")) { $selected["Recycle Bin"] = $categories["Recycle Bin"] }

Write-Host "DeGhost cleanup profile: $Tier"
Write-Host ""
Write-Host "Top space consumers before cleanup:"
$topConsumers = Get-TopConsumerUsage -SystemDrive $systemDrive
if ($topConsumers) {
    $topConsumers | Select-Object -First 5 | ForEach-Object {
        Write-Host (" - {0}: {1} GB" -f $_.Path, $_.SizeGB)
    }
} else {
    Write-Host " - Not available"
}
Write-Host ""

$categoryBefore = @{}
foreach ($name in $selected.Keys) {
    $size = 0L
    foreach ($target in $selected[$name]) {
        $size += Get-PathSizeBytes -Target $target
    }
    $categoryBefore[$name] = $size
}

$lockedPaths = [System.Collections.Generic.List[string]]::new()
$failedPaths = [System.Collections.Generic.List[string]]::new()

foreach ($name in $selected.Keys) {
    Write-Host "Cleaning category: $name"
    foreach ($target in $selected[$name]) {
        Remove-PathSafe -Target $target -LockedPaths $lockedPaths -FailedPaths $failedPaths
    }
}

$deepActions = [System.Collections.Generic.List[string]]::new()
if ($runComponentCleanup) {
    Run-DeepAction -Name "Component cleanup (DISM)" -ResultCollector $deepActions -Action {
        Start-Process -FilePath dism.exe -ArgumentList "/Online", "/Cleanup-Image", "/StartComponentCleanup" -Wait -NoNewWindow
    }
}
if ($disableHibernation) {
    Run-DeepAction -Name "Disable hibernation" -ResultCollector $deepActions -Action {
        Start-Process -FilePath powercfg.exe -ArgumentList "-hibernate", "off" -Wait -NoNewWindow
    }
}
if ($clearShadowCopies) {
    Run-DeepAction -Name "Clear shadow copies" -ResultCollector $deepActions -Action {
        Start-Process -FilePath vssadmin.exe -ArgumentList "delete", "shadows", "/All", "/Quiet" -Wait -NoNewWindow
    }
}
if ($removeOptionalFeatures) {
    $featureList = @(
        "WorkFolders-Client",
        "Printing-XPSServices-Features",
        "MediaPlayback",
        "MSRDC-Infrastructure"
    )
    Run-DeepAction -Name "Disable optional features" -ResultCollector $deepActions -Action {
        foreach ($feature in $featureList) {
            Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

$categoryAfter = @{}
foreach ($name in $selected.Keys) {
    $size = 0L
    foreach ($target in $selected[$name]) {
        $size += Get-PathSizeBytes -Target $target
    }
    $categoryAfter[$name] = $size
}

$afterFree = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$systemDrive'" -ErrorAction SilentlyContinue).FreeSpace
$totalFreed = if ($beforeFree -and $afterFree -and $afterFree -gt $beforeFree) { $afterFree - $beforeFree } else { 0L }

Write-Host ""
Write-Host "Cleanup summary by category:"
$categoryReport = foreach ($name in $selected.Keys) {
    $beforeSize = [int64]$categoryBefore[$name]
    $afterSize = [int64]$categoryAfter[$name]
    $freedSize = [math]::Max(0, ($beforeSize - $afterSize))
    [pscustomobject]@{
        Category = $name
        BeforeGB = [math]::Round($beforeSize / 1GB, 2)
        AfterGB = [math]::Round($afterSize / 1GB, 2)
        FreedGB = [math]::Round($freedSize / 1GB, 2)
    }
}

$categoryReport | ForEach-Object {
    Write-Host (" - {0}: {1} GB -> {2} GB (freed {3} GB)" -f $_.Category, $_.BeforeGB, $_.AfterGB, $_.FreedGB)
}

if ($totalFreed -gt 0) {
    Write-Host ""
    Write-Host ("Total reclaimed on {0}: {1} GB" -f $systemDrive, [math]::Round($totalFreed / 1GB, 2))
} else {
    Write-Host ""
    Write-Host "No measurable free-space change on system drive."
}

if ($deepActions.Count -gt 0) {
    Write-Host ""
    Write-Host "Deep actions:"
    $deepActions | ForEach-Object { Write-Host " - $_" }
}

Write-Host ""
Write-Host ("Locked/skipped path attempts: {0}" -f $lockedPaths.Count)
Write-Host ("Failed path attempts: {0}" -f $failedPaths.Count)

$repoRoot = Split-Path -Parent $PSScriptRoot
$reportPathRoot = if ([System.IO.Path]::IsPathRooted($ReportDirectory)) { $ReportDirectory } else { Join-Path -Path $repoRoot -ChildPath $ReportDirectory }
if (-not (Test-Path -LiteralPath $reportPathRoot)) {
    New-Item -Path $reportPathRoot -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFile = Join-Path -Path $reportPathRoot -ChildPath ("cleanup-report-{0}.log" -f $timestamp)

$reportLines = @()
$reportLines += "DeGhost Cleanup Report"
$reportLines += "Timestamp: $(Get-Date -Format s)"
$reportLines += "Profile: $Tier"
$reportLines += "SystemDrive: $systemDrive"
$reportLines += "TotalReclaimedGB: $([math]::Round($totalFreed / 1GB, 2))"
$reportLines += ""
$reportLines += "CategoryReclaimGB:"
foreach ($line in $categoryReport) {
    $reportLines += " - $($line.Category): before=$($line.BeforeGB) after=$($line.AfterGB) freed=$($line.FreedGB)"
}
$reportLines += ""
$reportLines += "DeepActions:"
if ($deepActions.Count -eq 0) {
    $reportLines += " - none"
} else {
    foreach ($actionResult in $deepActions) { $reportLines += " - $actionResult" }
}
$reportLines += ""
$reportLines += "LockedPathCount: $($lockedPaths.Count)"
$reportLines += "FailedPathCount: $($failedPaths.Count)"
if ($lockedPaths.Count -gt 0) {
    $reportLines += "LockedPathSamples:"
    $lockedPaths | Select-Object -Unique -First 10 | ForEach-Object { $reportLines += " - $_" }
}
if ($failedPaths.Count -gt 0) {
    $reportLines += "FailedPathSamples:"
    $failedPaths | Select-Object -Unique -First 10 | ForEach-Object { $reportLines += " - $_" }
}

$reportLines | Set-Content -Path $reportFile -Encoding UTF8
Write-Host "Saved cleanup report: $reportFile"
