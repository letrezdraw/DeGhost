Write-Host Cleaning...

Get-PSDrive -PSProvider FileSystem | ForEach-Object {

    $drive=$_.Root

    Remove-Item "$drive\Temp" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$drive\Cache" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$drive\Logs" -Recurse -Force -ErrorAction SilentlyContinue

}

Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\D3DSCache" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\NVIDIA" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host Done
