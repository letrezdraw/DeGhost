$apps=@(
    "*Clipchamp*",
    "*Teams*",
    "*Weather*",
    "*News*",
    "*GetHelp*",
    "*GetStarted*",
    "*Feedback*"
)

foreach($a in $apps){
    Get-AppxPackage $a | Remove-AppxPackage -ErrorAction SilentlyContinue
}
