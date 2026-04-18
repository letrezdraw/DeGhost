param($msg)

for ($i=0; $i -le 100; $i+=5){
    Write-Progress -Activity $msg -PercentComplete $i
    Start-Sleep -Milliseconds 20
}

param($text)

$text.ToCharArray() | ForEach-Object {
    Write-Host -NoNewline $_
    Start-Sleep -Milliseconds 15
}

Write-Host ""
