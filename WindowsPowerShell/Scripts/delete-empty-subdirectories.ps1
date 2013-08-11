
$StartingPoint = "c:\Windows\system32\windowspowershell\v1.0\Modules"

while (Get-ChildItem $StartingPoint -recurse | where {!@(Get-ChildItem -force $_.fullname)} | Test-Path) {
    Get-ChildItem $StartingPoint -recurse | where {!@(Get-ChildItem -force $_.fullname)} | Remove-Item
}

