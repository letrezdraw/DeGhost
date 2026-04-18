reg add HKCU\System\GameConfigStore /v GameDVR_Enabled /t REG_DWORD /d 0 /f

reg add HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile /v NetworkThrottlingIndex /t REG_DWORD /d ffffffff /f

powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
