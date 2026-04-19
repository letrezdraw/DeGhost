param(
    [ValidateSet("safe", "aggressive", "god")]
    [string]$Tier = "safe"
)

$apps = @(
    "*Clipchamp*",
    "*Teams*",
    "*Weather*",
    "*News*",
    "*GetHelp*",
    "*GetStarted*",
    "*Feedback*"
)

if ($Tier -eq "aggressive" -or $Tier -eq "god") {
    $apps += @(
        "*MicrosoftSolitaireCollection*",
        "*MixedReality.Portal*",
        "*XboxApp*",
        "*XboxGamingOverlay*",
        "*YourPhone*",
        "*BingFinance*",
        "*BingSports*"
    )
}

if ($Tier -eq "god") {
    $apps += @(
        "*WindowsMaps*",
        "*OneConnect*",
        "*MicrosoftPeople*",
        "*ZuneMusic*",
        "*ZuneVideo*"
    )
}

$apps | Select-Object -Unique | ForEach-Object {
    Get-AppxPackage $_ | Remove-AppxPackage -ErrorAction SilentlyContinue
}
