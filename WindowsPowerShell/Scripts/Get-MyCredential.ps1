#Get-myCredendial.ps1
Param($user,$file)
$password = Get-Content $file | ConvertTo-SecureString 
$credential = New-Object System.Management.Automation.PsCredential($user,$password)
$user
$credential
