$ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
$ram = [math]::Round($ram)

if ($ram -le 8){$ram="8GB"}
elseif ($ram -le 16){$ram="16GB"}
else {$ram="32GB+"}

$cpu=(Get-CimInstance Win32_Processor).Manufacturer
if($cpu -match "Intel"){$cpu="Intel"}
if($cpu -match "AMD"){$cpu="AMD"}

$drives=(Get-PSDrive -PSProvider FileSystem).Name -join ","

"RAM=$ram"
"CPU=$cpu"
"DRIVES=$drives"
