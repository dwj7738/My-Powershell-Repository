# Here is a snippet that verifies a local user account. Simply submit a username and a password. You get back either $true or $false:
$username = 'Administrator' 
$password = 'P@ssw0rd'  
$computer = $env:COMPUTERNAME  
Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
$obj = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine', $computer) 
$obj.ValidateCredentials($username, $password)  

