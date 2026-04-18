param([string]$DryRun = $env:DEGHOST_DRYRUN)

. "$PSScriptRoot\log.ps1"

$dryRun    = $DryRun -eq "true"
$script:spaceFreed = 0

function Remove-Path {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    if ($dryRun) {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum).Sum
        Write-Log "[DRY RUN] Would delete: $Path ($([math]::Round($size/1MB,2)) MB)"
        return
    }
    try {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum).Sum
        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
        $script:spaceFreed += $size
        Write-Log "Cleaned: $Path ($([math]::Round($size/1MB,2)) MB)"
    } catch {
        Write-Log "Could not clean $Path : $_" "WARN"
    }
}

Write-Log "Starting cleanup..."

# Multi-drive temp/cache/log cleanup
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $drive = $_.Root
    Remove-Path "$drive\Temp"
    Remove-Path "$drive\Cache"
    Remove-Path "$drive\Logs"
}

# Windows temp / prefetch / thumbnail / inet cache
Remove-Path "$env:TEMP"
Remove-Path "$env:SystemRoot\Temp"
Remove-Path "$env:SystemRoot\Prefetch"
Remove-Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
Remove-Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"

# GPU cache cleanup (auto-detected)
$gpuName = (Get-CimInstance Win32_VideoController |
            Where-Object { $_.Name -notmatch "Microsoft|Remote" } |
            Select-Object -First 1).Name

if ($gpuName -match "NVIDIA") {
    Write-Log "Cleaning NVIDIA cache..."
    Remove-Path "$env:LOCALAPPDATA\NVIDIA\DXCache"
    Remove-Path "$env:LOCALAPPDATA\NVIDIA\GLCache"
    Remove-Path "$env:LOCALAPPDATA\D3DSCache"
    Remove-Path "$env:APPDATA\NVIDIA"
}
if ($gpuName -match "AMD|Radeon") {
    Write-Log "Cleaning AMD cache..."
    Remove-Path "$env:LOCALAPPDATA\AMD\DxCache"
    Remove-Path "$env:TEMP\AMD"
}

# App-aware cleaning
$appPaths = [ordered]@{
    "Adobe"         = @(
        "$env:APPDATA\Adobe\Common\Media Cache Files",
        "$env:LOCALAPPDATA\Adobe\Adobe Substance 3D Painter\Adobe Substance 3D Painter\cache"
    )
    "Blender"       = @("$env:APPDATA\Blender Foundation\Blender\cache")
    "Maya"          = @("$env:USERPROFILE\Documents\maya\projects\default\cache")
    "AndroidStudio" = @(
        "$env:LOCALAPPDATA\Android\Sdk\.android\cache",
        "$env:USERPROFILE\.gradle\caches"
    )
    "VSCode"        = @(
        "$env:APPDATA\Code\Cache",
        "$env:APPDATA\Code\CachedData",
        "$env:APPDATA\Code\logs"
    )
    "Epic"          = @(
        "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache",
        "$env:LOCALAPPDATA\UnrealEngine\Common\DerivedDataCache"
    )
    "FiveM"         = @("$env:LOCALAPPDATA\FiveM\FiveM.app\cache")
    "Discord"       = @(
        "$env:APPDATA\discord\Cache",
        "$env:APPDATA\discord\Code Cache"
    )
    "Steam"         = @("$env:LOCALAPPDATA\Steam\htmlcache")
    "Spotify"       = @(
        "$env:APPDATA\Spotify\Data",
        "$env:LOCALAPPDATA\Spotify\Storage"
    )
    "Chrome"        = @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache")
    "Edge"          = @("$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache")
}

foreach ($app in $appPaths.Keys) {
    $paths     = $appPaths[$app]
    $installed = $paths | Where-Object { Test-Path $_ }
    if ($installed) {
        Write-Log "Cleaning $app cache..."
        $paths | ForEach-Object { Remove-Path $_ }
    }
}

$freedMB = [math]::Round($spaceFreed / 1MB, 2)
Write-Log "Cleanup complete. Space freed: $freedMB MB"
