@echo off
setlocal EnableDelayedExpansion
title DeGhost
color 0A
mode con cols=80 lines=30 >nul 2>&1

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
echo   [8] Exit
echo.
echo ================================================================================
set /p c=Select an option [1-8]: 

if "%c%"=="1" goto full
if "%c%"=="2" goto cleanup
if "%c%"=="3" goto debloat
if "%c%"=="4" goto gaming
if "%c%"=="5" goto workstation
if "%c%"=="6" goto custom
if "%c%"=="7" goto restore
if "%c%"=="8" exit

echo Invalid option: "%c%"
timeout /t 2 >nul
goto menu

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
set /p a=
echo Debloat? y/n
set /p b=
echo Optimize? y/n
set /p c=

call :backup
call :close

if /i "%a%"=="y" call :run cleanup
if /i "%b%"=="y" call :run debloat
if /i "%c%"=="y" call :run services

goto done

:restore
powershell -ExecutionPolicy Bypass -File modules\restore.ps1
pause
goto menu

:run
powershell -ExecutionPolicy Bypass -File modules\%1.ps1
exit /b

:backup
reg export HKLM backup\hklm.reg /y >nul
reg export HKCU backup\hkcu.reg /y >nul
exit /b

:close
taskkill /f /im chrome.exe >nul 2>&1
taskkill /f /im discord.exe >nul 2>&1
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
