sc.exe stop SysMain
sc.exe config SysMain start= disabled

sc.exe stop DiagTrack
sc.exe config DiagTrack start= disabled

reg add HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl /v Win32PrioritySeparation /t REG_DWORD /d 38 /f
