Write-Host "Cleaning..."

function Remove-PathSafe {
    param([string]$Target)
    if ([string]::IsNullOrWhiteSpace($Target)) { return }

    $items = Get-Item -LiteralPath $Target -ErrorAction SilentlyContinue
    if ($items) {
        $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Remove-Item -Path $Target -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$systemDrive = if ($env:SystemDrive) { $env:SystemDrive } else { "C:" }
$before = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$systemDrive'" -ErrorAction SilentlyContinue).FreeSpace

Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $drive = $_.Root
    Remove-PathSafe "$drive\Temp"
    Remove-PathSafe "$drive\Cache"
    Remove-PathSafe "$drive\Logs"
    $recycleBinPath = Join-Path -Path $drive -ChildPath "`$Recycle.Bin\*"
    Remove-PathSafe $recycleBinPath
}

$cleanupTargets = @(
    "$env:TEMP\*",
    "$env:WINDIR\Temp\*",
    "$env:LOCALAPPDATA\Temp\*",
    "$env:LOCALAPPDATA\D3DSCache\*",
    "$env:LOCALAPPDATA\NVIDIA\*",
    "$env:LOCALAPPDATA\CrashDumps\*",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*.db",
    "$env:LOCALAPPDATA\Microsoft\Windows\DeliveryOptimization\Cache\*",
    "$env:ProgramData\Microsoft\Windows\WER\ReportArchive\*",
    "$env:ProgramData\Microsoft\Windows\WER\ReportQueue\*",
    "$env:ProgramData\NVIDIA Corporation\NV_Cache\*"
)

foreach ($target in $cleanupTargets) {
    Remove-PathSafe $target
}

$after = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$systemDrive'" -ErrorAction SilentlyContinue).FreeSpace
if ($before -and $after -and $after -gt $before) {
    $freedGB = [math]::Round(($after - $before) / 1GB, 2)
    Write-Host "Done. Freed about $freedGB GB on $systemDrive."
} elseif ($before -and $after) {
    Write-Host "Done. No measurable free-space change on $systemDrive."
} else {
    Write-Host "Done."
}
