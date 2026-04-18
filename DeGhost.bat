@echo off
setlocal EnableDelayedExpansion
title DeGhost
cd /d "%~dp0"

:: ── Admin auto-elevation ───────────────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: ── Default settings (overridden by DeGhost.conf) ─────────────────────────
set cleanup=true
set debloat=true
set mode=balanced
set dryrun=false
set theme=green
set logging=true

:: ── Load config ───────────────────────────────────────────────────────────
if exist DeGhost.conf (
    for /f "eol=# tokens=1,2 delims==" %%a in (DeGhost.conf) do set %%a=%%b
)

:: ── Export settings for PowerShell modules ────────────────────────────────
set DEGHOST_DRYRUN=%dryrun%
set DEGHOST_LOGGING=%logging%
set DEGHOST_MODE=%mode%

:: ── Apply theme ───────────────────────────────────────────────────────────
call :applytheme

:: ── Create required directories ───────────────────────────────────────────
if not exist backup  mkdir backup
if not exist logs    mkdir logs
if not exist plugins mkdir plugins

:: ── Detect hardware ───────────────────────────────────────────────────────
powershell -ExecutionPolicy Bypass -File modules\detect.ps1 > detect.tmp 2>nul
for /f "tokens=1,2 delims==" %%a in (detect.tmp) do set %%a=%%b
del detect.tmp 2>nul

call :intro
call :warning

:: ═══════════════════════════════════════════════════════════════════════════
:menu
cls
echo.
echo  ==========================================
echo   DeGhost  ^|  Advanced Windows Optimizer
echo  ==========================================
echo.
echo   RAM:     %RAM%    ^|  CPU:  %CPU%
echo   GPU:     %GPU%    ^|  Drive: %DRIVETYPE%
echo   Windows: %WINVER%
echo   Drives:  %DRIVES%
if /i "%dryrun%"=="true" (
    echo.
    echo   [DRY RUN MODE - No changes will be made]
)
echo.
echo   1.  Full Optimize
echo   2.  Cleanup
echo   3.  Debloat
echo   4.  Gaming Mode
echo   5.  Workstation Mode
echo   6.  Custom Mix
echo   7.  Dry Run Preview
echo   8.  Restore
echo   9.  Benchmark
echo   10. Schedule Tasks
echo   11. Run Plugins
echo   12. Toggle Dry Run  [%dryrun%]
echo   13. Settings
echo   0.  Exit
echo.
set /p c=Choose option: 

if "%c%"=="1"  goto full
if "%c%"=="2"  goto cleanup
if "%c%"=="3"  goto debloat
if "%c%"=="4"  goto gaming
if "%c%"=="5"  goto workstation
if "%c%"=="6"  goto custom
if "%c%"=="7"  goto dryrunmode
if "%c%"=="8"  goto restore
if "%c%"=="9"  goto benchmark
if "%c%"=="10" goto schedule
if "%c%"=="11" goto plugins
if "%c%"=="12" goto toggledryrun
if "%c%"=="13" goto settings
if "%c%"=="0"  exit /b

goto menu

:: ── Option handlers ───────────────────────────────────────────────────────
:full
call :backup
call :close
call :run cleanup
call :run debloat
call :run services
call :run startup
call :run disk
call :run memory
call :run gaming
goto done

:cleanup
call :backup
call :close
call :run cleanup
goto done

:debloat
call :backup
call :run debloat
call :run startup
goto done

:gaming
call :backup
call :run services gaming
call :run gaming
call :run memory
goto done

:workstation
call :backup
call :run services workstation
call :run disk
call :run memory
goto done

:custom
cls
echo  ── Custom Mix Mode ──────────────────────────────
echo.
set /p do_cleanup=  Cleanup?            (y/n): 
set /p do_debloat=  Debloat?            (y/n): 
set /p do_gaming=   Gaming tweaks?      (y/n): 
set /p do_memory=   Memory optimization?(y/n): 
set /p do_disk=     Disk tweaks?        (y/n): 
set /p do_services= Service tweaks?     (y/n): 

call :backup
call :close

if /i "%do_cleanup%"=="y"   call :run cleanup
if /i "%do_debloat%"=="y"   call :run debloat
if /i "%do_gaming%"=="y"    call :run gaming
if /i "%do_memory%"=="y"    call :run memory
if /i "%do_disk%"=="y"      call :run disk
if /i "%do_services%"=="y"  call :run services

goto done

:dryrunmode
set DEGHOST_DRYRUN=true
call :run cleanup
call :run debloat
call :run services
call :run gaming
set DEGHOST_DRYRUN=%dryrun%
pause
goto menu

:restore
powershell -ExecutionPolicy Bypass -File modules\restore.ps1
pause
goto menu

:benchmark
powershell -ExecutionPolicy Bypass -File modules\benchmark.ps1
pause
goto menu

:schedule
powershell -ExecutionPolicy Bypass -File modules\scheduler.ps1
pause
goto menu

:plugins
cls
echo  ── Run Plugins ─────────────────────────────────
echo.
dir /b plugins\*.ps1 2>nul
echo.
set /p plugin=Enter plugin name (without .ps1) or ENTER to cancel: 
if "%plugin%"=="" goto menu
if exist plugins\%plugin%.ps1 (
    powershell -ExecutionPolicy Bypass -File plugins\%plugin%.ps1
) else (
    echo Plugin not found: %plugin%
)
pause
goto menu

:toggledryrun
if /i "%dryrun%"=="true" (
    set dryrun=false
) else (
    set dryrun=true
)
set DEGHOST_DRYRUN=%dryrun%
goto menu

:: ── Settings sub-menu ─────────────────────────────────────────────────────
:settings
cls
echo  ── Settings ────────────────────────────────────
echo.
echo   Mode:    %mode%
echo   Theme:   %theme%
echo   Dryrun:  %dryrun%
echo   Logging: %logging%
echo.
echo   1. Change mode   (gaming / workstation / balanced)
echo   2. Change theme  (green / red / dark / minimal)
echo   3. Toggle logging
echo   4. Save config
echo   0. Back
echo.
set /p s=Choose: 
if "%s%"=="1" goto setmode
if "%s%"=="2" goto settheme
if "%s%"=="3" goto togglelog
if "%s%"=="4" goto saveconfig
if "%s%"=="0" goto menu
goto settings

:setmode
set /p mode=  New mode (gaming/workstation/balanced): 
set DEGHOST_MODE=%mode%
goto settings

:settheme
set /p theme=  New theme (green/red/dark/minimal): 
call :applytheme
goto settings

:togglelog
if /i "%logging%"=="true" (
    set logging=false
) else (
    set logging=true
)
set DEGHOST_LOGGING=%logging%
goto settings

:saveconfig
(
    echo # DeGhost Configuration
    echo cleanup=%cleanup%
    echo debloat=%debloat%
    echo mode=%mode%
    echo dryrun=%dryrun%
    echo theme=%theme%
    echo logging=%logging%
) > DeGhost.conf
echo   Config saved to DeGhost.conf.
pause
goto settings

:: ── Subroutines ───────────────────────────────────────────────────────────
:run
powershell -ExecutionPolicy Bypass -File modules\%1.ps1 %2
exit /b

:backup
powershell -ExecutionPolicy Bypass -File modules\restore_point.ps1
exit /b

:close
taskkill /f /im chrome.exe  >nul 2>&1
taskkill /f /im discord.exe >nul 2>&1
taskkill /f /im Code.exe    >nul 2>&1
taskkill /f /im msedge.exe  >nul 2>&1
taskkill /f /im steam.exe   >nul 2>&1
exit /b

:applytheme
if /i "%theme%"=="green"   color 0A & exit /b
if /i "%theme%"=="red"     color 0C & exit /b
if /i "%theme%"=="dark"    color 08 & exit /b
if /i "%theme%"=="minimal" color 07 & exit /b
color 0A
exit /b

:intro
cls
echo.
echo   ==========================================
echo    DeGhost v2.0  ^|  Advanced Windows Optimizer
echo   ==========================================
echo.
echo   Initializing...
timeout /t 2 >nul
exit /b

:warning
cls
echo.
echo   ==========================================
echo    WARNING
echo   ==========================================
echo    DeGhost will optimize Windows.
echo    - Some apps will be closed
echo    - A backup and restore point will be made
echo    - Admin rights are active
echo   ==========================================
echo.
pause
exit /b

:done
echo.
echo   ==========================================
echo    Optimization Complete!
echo    Check logs\DeGhost.log for details.
echo   ==========================================
echo.
pause
goto menu
