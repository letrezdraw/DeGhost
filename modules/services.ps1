sc stop SysMain
sc config SysMain start=disabled

sc stop DiagTrack
sc config DiagTrack start=disabled

reg add HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl /v Win32PrioritySeparation /t REG_DWORD /d 38 /f
