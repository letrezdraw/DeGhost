# DeGhost Plugin: Example
# Copy this file and rename it to add your own optimizations.

. "$PSScriptRoot\..\modules\log.ps1"

$dryRun = $env:DEGHOST_DRYRUN -eq "true"

Write-Log "Example plugin starting..."

if ($dryRun) {
    Write-Log "[DRY RUN] Would run example optimizations"
    Write-Host "Dry-run: no changes made." -ForegroundColor Yellow
} else {
    Write-Host "Example plugin running. Replace this with your custom logic." -ForegroundColor Cyan
    # Add your optimization steps here, e.g.:
    # Remove-Item "$env:LOCALAPPDATA\MyApp\Cache" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Log "Example plugin complete"
