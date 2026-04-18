function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    if ($env:DEGHOST_LOGGING -ne "true") { return }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    $logPath = Join-Path (Get-Location).Path "logs\DeGhost.log"
    $logDir  = Split-Path $logPath -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
    Add-Content -Path $logPath -Value $entry -ErrorAction SilentlyContinue
    switch ($Level) {
        "ERROR" { Write-Host $entry -ForegroundColor Red }
        "WARN"  { Write-Host $entry -ForegroundColor Yellow }
        default { Write-Host $entry -ForegroundColor Cyan }
    }
}
