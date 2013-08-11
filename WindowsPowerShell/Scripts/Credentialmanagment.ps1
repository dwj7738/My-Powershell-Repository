#STORED CREDENTIAL CODE

$AdminName = Read-Host "Enter your Admin AD username"

$CredsFile = "C:\$AdminName-PowershellCreds.txt"

$FileExists = Test-Path $CredsFile

if  ($FileExists -eq $false) {

    Write-Host 'Credential file not found. Enter your password:' -ForegroundColor Red

    Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File $CredsFile

    $password = get-content $CredsFile | convertto-securestring

    $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist domain\$AdminName,$password}

else

    {Write-Host 'Using your stored credential file' -ForegroundColor Green

    $password = get-content $CredsFile | convertto-securestring

    $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist domain\$AdminName,$password}

sleep 2

Write-Host 'Connecting to Active Directory'

#Establishes connection to Active Directory and Exchange with the specified user acccount and password.

Connect-QADService -Service 'server' -Credential $Cred -ErrorAction Stop | out-Null

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://server.fqdn.com/PowerShell/ -Credential $Cred -Authentication Kerberos -ErrorAction SilentlyContinue

Import-PSSession $Session -ErrorAction SilentlyContinue -AllowClobber

if(!$?)

    {write-host "Failed importing the exchange pssession, exiting!"

    exit}

#END OF STORED CREDENTIAL CODE

