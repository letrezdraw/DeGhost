. "$PSScriptRoot\log.ps1"

$batPath = Join-Path (Get-Location).Path "DeGhost.bat"

Write-Host ""
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "     DeGhost Scheduler" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Create Weekly Cleanup Task"
Write-Host "2. Create Monthly Deep Clean Task"
Write-Host "3. Show DeGhost Tasks"
Write-Host "4. Remove All DeGhost Tasks"
Write-Host "0. Back"
Write-Host ""

$choice = Read-Host "Choose"

$idleSettings = New-ScheduledTaskSettingsSet -RunOnlyIfIdle -IdleDuration (New-TimeSpan -Minutes 5) -StopIfGoingOffIdle

switch ($choice) {
    "1" {
        Write-Log "Creating weekly cleanup task..."
        try {
            $action  = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$batPath`""
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00"
            Register-ScheduledTask -TaskName "DeGhost Weekly Cleanup" -Action $action -Trigger $trigger -Settings $idleSettings -RunLevel Highest -Force | Out-Null
            Write-Log "Weekly cleanup task created (Sundays at 03:00)"
            Write-Host "Weekly cleanup task created." -ForegroundColor Green
        } catch {
            Write-Log "Failed to create task: $_" "ERROR"
        }
    }
    "2" {
        Write-Log "Creating monthly deep clean task..."
        try {
            $action  = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$batPath`""
            $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At "03:00"
            Register-ScheduledTask -TaskName "DeGhost Monthly Deep Clean" -Action $action -Trigger $trigger -Settings $idleSettings -RunLevel Highest -Force | Out-Null
            Write-Log "Monthly deep clean task created (1st of month at 03:00)"
            Write-Host "Monthly deep clean task created." -ForegroundColor Green
        } catch {
            Write-Log "Failed to create task: $_" "ERROR"
        }
    }
    "3" {
        $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "DeGhost*" }
        if ($tasks) {
            Write-Host "DeGhost scheduled tasks:" -ForegroundColor Yellow
            $tasks | ForEach-Object { Write-Host "  $($_.TaskName) - $($_.State)" }
        } else {
            Write-Host "No DeGhost scheduled tasks found." -ForegroundColor Yellow
        }
    }
    "4" {
        Unregister-ScheduledTask -TaskName "DeGhost Weekly Cleanup"   -Confirm:$false -ErrorAction SilentlyContinue
        Unregister-ScheduledTask -TaskName "DeGhost Monthly Deep Clean" -Confirm:$false -ErrorAction SilentlyContinue
        Write-Log "All DeGhost scheduled tasks removed"
        Write-Host "All DeGhost tasks removed." -ForegroundColor Green
    }
}

Write-Host ""
