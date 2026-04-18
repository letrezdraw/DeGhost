. "$PSScriptRoot\log.ps1"

Write-Host ""
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "       DeGhost Benchmark" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# CPU benchmark
Write-Host "Running CPU benchmark..." -ForegroundColor Yellow
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$n = 0; for ($i = 1; $i -le 1000000; $i++) { $n += $i }
$sw.Stop()
$cpuMs = $sw.ElapsedMilliseconds
Write-Host "  CPU compute (1M ops): ${cpuMs}ms"

# RAM info
$totalRam = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
$freeRam  = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 0)
Write-Host "  RAM: ${totalRam}GB total, ${freeRam}MB free"

# CPU load
$cpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
Write-Host "  CPU load: ${cpuLoad}%"

# Disk write benchmark (10 MB)
Write-Host "Running disk benchmark..." -ForegroundColor Yellow
$testFile = "$env:TEMP\deghost_bench.tmp"
try {
    $data = [byte[]]::new(10MB)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    [System.IO.File]::WriteAllBytes($testFile, $data)
    $sw.Stop()
    $writeMs = [math]::Max($sw.ElapsedMilliseconds, 1)
    $speedMBs = [math]::Round(10 / ($writeMs / 1000), 0)
    Write-Host "  Disk write speed: ${speedMBs} MB/s"
} catch {
    Write-Host "  Disk benchmark skipped: $_" -ForegroundColor Yellow
    $speedMBs = 0
} finally {
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
}

# System uptime
$os = Get-CimInstance Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
Write-Host "  Uptime: $([math]::Floor($uptime.TotalHours))h $($uptime.Minutes)m"

# Drive info
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
foreach ($d in $drives) {
    $usedGB = [math]::Round($d.Used / 1GB, 1)
    $freeGB = [math]::Round($d.Free / 1GB, 1)
    Write-Host "  Drive $($d.Name): ${usedGB}GB used, ${freeGB}GB free"
}

Write-Host ""
Write-Log "Benchmark complete - CPU: ${cpuMs}ms, Disk: ${speedMBs} MB/s, RAM free: ${freeRam}MB"
Write-Host "Results saved to logs\DeGhost.log" -ForegroundColor Green
