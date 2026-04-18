function Show-Progress {
    param([string]$Activity, [int]$DurationMs = 2000)
    $steps = 20
    $delay = [math]::Max([math]::Floor($DurationMs / $steps), 1)
    for ($i = 0; $i -le 100; $i += 5) {
        Write-Progress -Activity $Activity -PercentComplete $i
        Start-Sleep -Milliseconds $delay
    }
    Write-Progress -Activity $Activity -Completed
}

function Write-Typewriter {
    param([string]$Text, [int]$DelayMs = 15)
    $Text.ToCharArray() | ForEach-Object {
        Write-Host -NoNewline $_
        Start-Sleep -Milliseconds $DelayMs
    }
    Write-Host ""
}

function Show-Header {
    param([string]$Title = "DeGhost")
    Write-Host ""
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host "   $Title" -ForegroundColor Cyan
    Write-Host "   Advanced Windows Optimizer" -ForegroundColor Cyan
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host ""
}

# Run as standalone: Show-Progress / Write-Typewriter when called with params
param(
    [string]$msg  = "",
    [string]$text = ""
)

if ($msg)  { Show-Progress   -Activity $msg }
if ($text) { Write-Typewriter -Text     $text }
