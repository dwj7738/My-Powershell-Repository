$servername = "win7-vm"
$CredsFile = "C:\test\win7-vm.cred"
{Write-Host 'Using your stored credential file' -ForegroundColor Green
$password = get-content $CredsFile | convertto-securestring
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName,$password}

Invoke-Command -ComputerName win7-vm -Credential $Cred -ScriptBlock {
Start-Process "powershell" -ArgumentList "& 'cmd.exe'"
write-host ("hello world")
Start-Sleep -Seconds 5
Start-Process -Wait -FilePath \\davidjohnson-w8\downloads\7z922-x64.msi

 }
                                  