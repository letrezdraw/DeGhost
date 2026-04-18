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
    $osDriveLetter = (Get-CimInstance Win32_OperatingSystem).SystemDrive  # e.g. "C:"
    # Walk logical -> partition -> physical disk
    $ldtp = Get-CimInstance -Class Win32_LogicalDiskToPartition |
            Where-Object { $_.Dependent.DeviceID -eq $osDriveLetter } |
            Select-Object -First 1
    $diskNum = if ($ldtp) {
        $partPath = $ldtp.Antecedent.DeviceID           # "Disk #0, Partition #0"
        if ($partPath -match 'Disk #(\d+)') { $Matches[1] } else { $null }
    }
    $physDisk = if ($diskNum -ne $null) {
        Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $diskNum } | Select-Object -First 1
    }
    if (-not $physDisk) { $physDisk = Get-PhysicalDisk | Select-Object -First 1 }
    if ($physDisk.MediaType -match "NVMe")          { $driveType = "NVMe" }
    elseif ($physDisk.MediaType -match "SSD|Solid") { $driveType = "SSD"  }
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
