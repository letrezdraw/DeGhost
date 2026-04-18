# RAM
$ramGB    = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$ramLabel = if     ($ramGB -le 8)  { "8GB"   }
            elseif ($ramGB -le 16) { "16GB"  }
            elseif ($ramGB -le 32) { "32GB"  }
            else                   { "64GB+" }

# CPU
$cpuObj   = Get-CimInstance Win32_Processor
$cpuLabel = if      ($cpuObj.Manufacturer -match "Intel") { "Intel" }
            elseif  ($cpuObj.Manufacturer -match "AMD")   { "AMD"   }
            else    { "Unknown" }

# GPU
$gpuObj   = Get-CimInstance Win32_VideoController |
            Where-Object { $_.Name -notmatch "Microsoft|Remote" } |
            Select-Object -First 1
$gpuLabel = if      ($gpuObj.Name -match "NVIDIA")       { "NVIDIA" }
            elseif  ($gpuObj.Name -match "AMD|Radeon")   { "AMD"    }
            elseif  ($gpuObj.Name -match "Intel")        { "Intel"  }
            elseif  ($gpuObj)                            { ($gpuObj.Name -split " ")[0] }
            else    { "Unknown" }

# Drive type (system drive)
$driveType = "HDD"
try {
    $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq "0" } | Select-Object -First 1
    if ($disk.MediaType -match "NVMe")            { $driveType = "NVMe" }
    elseif ($disk.MediaType -match "SSD|Solid")   { $driveType = "SSD"  }
} catch {}

# Windows version
$winVer = (Get-CimInstance Win32_OperatingSystem).Caption -replace "^Microsoft Windows ",""

# All drive letters
$drives = (Get-PSDrive -PSProvider FileSystem).Name -join ","

"RAM=$ramLabel"
"RAMGB=$ramGB"
"CPU=$cpuLabel"
"GPU=$gpuLabel"
"DRIVETYPE=$driveType"
"WINVER=$winVer"
"DRIVES=$drives"
