param($text)

$text.ToCharArray() | ForEach-Object {
    Write-Host -NoNewline $_
    Start-Sleep -Milliseconds 15
}

Write-Host ""
