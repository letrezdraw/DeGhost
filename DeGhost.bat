@echo off
setlocal EnableDelayedExpansion
title DeGhost
color 0A

cd /d "%~dp0"

if not exist backup mkdir backup

call :intro
call :warning

powershell -ExecutionPolicy Bypass -File modules\detect.ps1 > detect.tmp
for /f "tokens=1,2 delims==" %%a in (detect.tmp) do set %%a=%%b
del detect.tmp

:menu
cls
echo ================================================================================
echo                          D E G H O S T   C O N S O L E
echo ================================================================================
echo.
echo   System Snapshot
echo   - RAM   : %RAM%
echo   - CPU   : %CPU%
echo   - Drive : %DRIVES%
echo.
echo   [1] Full Optimize
echo   [2] Cleanup
echo   [3] Debloat
echo   [4] Gaming Mode
echo   [5] Workstation Mode
echo   [6] Custom
echo   [7] Restore
echo   [8] God Mode
echo   [9] Exit
echo.
echo ================================================================================
set /p sel=Select an option [1-9]: 

if "%sel%"=="1" goto full
if "%sel%"=="2" goto cleanup
if "%sel%"=="3" goto debloat
if "%sel%"=="4" goto gaming
if "%sel%"=="5" goto workstation
if "%sel%"=="6" goto custom
if "%sel%"=="7" goto restore
if "%sel%"=="8" goto godmode
if "%sel%"=="9" exit

echo Invalid option: "%sel%". Please select 1-9.
pause
goto menu

:full
call :backup
call :close
call :prepareCleanupProfile
if errorlevel 1 goto menu
call :runCleanup
call :runDebloat
call :run services
call :run startup
call :run disk
call :run memory
call :run gaming
goto done

:cleanup
call :backup
call :close
call :prepareCleanupProfile
if errorlevel 1 goto menu
call :runCleanup
goto done

:debloat
call :backup
call :selectProfile
call :runDebloat
goto done

:gaming
call :backup
call :run services
call :run gaming
call :run memory
goto done

:workstation
call :backup
call :run services
call :run disk
call :run memory
goto done

:custom
echo.
echo Custom mode - choose modules to run.
echo Cleanup? y/n
set /p customCleanup=
echo Debloat? y/n
set /p customDebloat=
echo Optimize services? y/n
set /p customServices=

call :backup
call :close

if /i "%customCleanup%"=="y" (
    call :prepareCleanupProfile
    if errorlevel 1 goto menu
    call :runCleanup
)
if /i "%customDebloat%"=="y" (
    call :selectProfile
    call :runDebloat
)
if /i "%customServices%"=="y" call :run services

goto done

:godmode
call :backup
call :close
call :prepareCleanupProfile god
if errorlevel 1 goto menu
call :runCleanup
call :runDebloat
call :run services
call :run startup
call :run disk
call :run memory
call :run gaming
goto done

:restore
powershell -ExecutionPolicy Bypass -File modules\restore.ps1
pause
goto menu

:run
powershell -ExecutionPolicy Bypass -File modules\%1.ps1
exit /b

:runCleanup
powershell -ExecutionPolicy Bypass -File modules\cleanup.ps1 -Tier "%PROFILE%" -IncludeSystemTemp "%INCLUDE_SYSTEM_TEMP%" -IncludeUserCache "%INCLUDE_USER_CACHE%" -IncludeWindowsUpdate "%INCLUDE_WINDOWS_UPDATE%" -IncludeCrashAndShader "%INCLUDE_CRASH_AND_SHADER%" -IncludeBrowserCache "%INCLUDE_BROWSER_CACHE%" -IncludeRecycleBin "%INCLUDE_RECYCLE_BIN%" -RunComponentCleanup "%RUN_COMPONENT_CLEANUP%" -DisableHibernation "%DISABLE_HIBERNATION%" -ClearShadowCopies "%CLEAR_SHADOW_COPIES%" -RemoveOptionalFeatures "%REMOVE_OPTIONAL_FEATURES%" -ReportDirectory "backup"
exit /b

:runDebloat
powershell -ExecutionPolicy Bypass -File modules\debloat.ps1 -Tier "%PROFILE%"
exit /b

:prepareCleanupProfile
if "%~1"=="" (
    call :selectProfile
) else (
    set "PROFILE=%~1"
)
call :setProfileDefaults

echo.
call :promptYN CUSTOMIZE_CLEANUP "Customize cleanup categories" N
if /i "%CUSTOMIZE_CLEANUP%"=="true" call :customizeCleanup

if /i "%PROFILE%"=="god" (
    call :promptYN RUN_COMPONENT_CLEANUP "Run WinSxS component cleanup (DISM)" Y
    call :promptYN DISABLE_HIBERNATION "Disable hibernation (removes hiberfil.sys)" N
    call :promptYN CLEAR_SHADOW_COPIES "Delete old shadow copies" N
    call :promptYN REMOVE_OPTIONAL_FEATURES "Disable optional Windows features" N

    echo.
    echo GOD MODE can remove important system data and optional features.
    echo Type CONFIRM to continue.
    set /p godConfirm=
    if /i not "%godConfirm%"=="CONFIRM" (
        echo God Mode cancelled.
        pause
        exit /b 1
    )

    powershell -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'DeGhost Pre-GodMode' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1
)
exit /b 0

:selectProfile
echo.
echo Cleanup profile presets:
echo   [1] Safe       - low-risk temp/cache cleanup
echo   [2] Aggressive - deeper cache/log/update cleanup
echo   [3] God Mode   - maximum cleanup with destructive options
set /p profileSel=Choose profile [1-3]:
if "%profileSel%"=="1" set "PROFILE=safe" & exit /b
if "%profileSel%"=="2" set "PROFILE=aggressive" & exit /b
if "%profileSel%"=="3" set "PROFILE=god" & exit /b
echo Invalid profile. Defaulting to Safe.
set "PROFILE=safe"
exit /b

:setProfileDefaults
set "INCLUDE_SYSTEM_TEMP=true"
set "INCLUDE_USER_CACHE=true"
set "INCLUDE_WINDOWS_UPDATE=false"
set "INCLUDE_CRASH_AND_SHADER=true"
set "INCLUDE_BROWSER_CACHE=false"
set "INCLUDE_RECYCLE_BIN=false"
set "RUN_COMPONENT_CLEANUP=false"
set "DISABLE_HIBERNATION=false"
set "CLEAR_SHADOW_COPIES=false"
set "REMOVE_OPTIONAL_FEATURES=false"

if /i "%PROFILE%"=="aggressive" (
    set "INCLUDE_WINDOWS_UPDATE=true"
    set "INCLUDE_BROWSER_CACHE=true"
    set "INCLUDE_RECYCLE_BIN=true"
)
if /i "%PROFILE%"=="god" (
    set "INCLUDE_WINDOWS_UPDATE=true"
    set "INCLUDE_BROWSER_CACHE=true"
    set "INCLUDE_RECYCLE_BIN=true"
)
exit /b

:customizeCleanup
echo.
echo Cleanup category toggles:
call :promptYN INCLUDE_SYSTEM_TEMP "System temp/cache/logs" Y
call :promptYN INCLUDE_USER_CACHE "User app cache/temp files" Y
call :promptYN INCLUDE_WINDOWS_UPDATE "Windows Update and delivery cache" N
call :promptYN INCLUDE_CRASH_AND_SHADER "Crash dumps, shader and thumbnail cache" Y
call :promptYN INCLUDE_BROWSER_CACHE "Browser caches" N
call :promptYN INCLUDE_RECYCLE_BIN "Recycle bin content" N
exit /b

:promptYN
set "ans="
set /p "ans=%~2 (y/n, default %~3): "
if "%ans%"=="" (
    if /i "%~3"=="Y" (set "%~1=true") else (set "%~1=false")
    exit /b
)
if /i "%ans%"=="y" set "%~1=true" & exit /b
if /i "%ans%"=="n" set "%~1=false" & exit /b
echo Please enter y or n.
call :promptYN %1 "%~2" %3
exit /b

:backup
reg export HKLM backup\hklm.reg /y >nul
reg export HKCU backup\hkcu.reg /y >nul
exit /b

:close
taskkill /f /im chrome.exe >nul 2>&1
taskkill /f /im discord.exe >nul 2>&1
rem Intentionally do not kill Code.exe to avoid closing the host terminal/session.
taskkill /f /im msedge.exe >nul 2>&1
exit /b

:intro
cls
set "dots="
for /l %%i in (1,1,3) do (
    set "dots=!dots!."
    timeout /t 1 >nul
    cls
    echo Initializing DeGhost !dots!
)
exit /b

:warning
cls
echo This will optimize Windows
echo Apps will be closed
echo Continue?
pause
exit /b

:done
echo.
echo Complete
pause
goto menu
