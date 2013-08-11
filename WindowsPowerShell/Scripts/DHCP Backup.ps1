<#
    DHCP Backups Powershell Script
    v1.1
    2012-06-04
    By VulcanX
 
    .SYNOPSIS
        This script will automate the backup of DHCP Databases and copy
        them into a DFS Store at the following link:
        \\domain.com\DHCP
        Each location has a seperate folder and once the backup
        completes a mail sent out if any errors occur.
        ***NB*** : This can only be run in AD Environments where there is 1 DHCP Server per site
    
    .USAGE & REQUIREMENTS
        1. Open Powershell (Start->Run->Powershell.exe) from the DHCP Server
        2. cd %ScriptLocation%
        3. .\DHCPBackup_v1.1
          
    .SCHEDULED TASK CONFIGURATION
        If you have your ExecutionPolicy set to RemoteSigned you will need to run the file with the
        following, to execute it from a UNC Path unless you sign it yourself.
            powershell.exe -ExecutionPolicy Bypass -File "\\domain.com\DHCP\DHCPBackup_v1.1.ps1"
       
     
***RECOVERY***

    Please use the following when recovering a failed DHCP Server/Scope:
    OPTION A:
    netsh dhcp server import "\\domain.com\DHCP\$SiteName\$Date\NetshExport" all
   
    DID NOT WORK IN TESTING!
    OPTION B:
    netsh exec "\\domain.com\DHCP\$SiteName\$Date\Dump.cfg"
       
    First and foremost always try use OPTION A as this will be able to run on any DHCP Server. OPTION B is a last resort
    if OPTION A didnt work.
    ***NB*** : OPTION B can only be run on the same server as what it was dumped from.
       
    .CHANGELOG
       
    v1.1 -  Changed the names in the DHCP DFS Share to reflect the site names
            When selecting which share location, it is based on which site the server is in
            Found a way to run the script from the DFS DHCP repository
            Script now uses dynamic methods allowing it to be more versatile
#>

# Clear Error Variable in case anything carried forward
$Error.Clear()

# Create Temporary DHCP Directory if does not exist
if((Test-Path -Path "C:\DHCPTemp") -ne $true)
{
	New-Item -Verbose "C:\DHCPTemp" -type directory
}

# Clear any stale Backups that may have been created previously
Remove-Item -Path "C:\DHCPTemp\*" -Force -Recurse

# Start logging all the changes to a file in C:\DHCPTemp\LogFile.txt
Start-Transcript -Path "C:\DHCPTemp\LogFile.txt"

# Store the hostname
$Hostname = hostname

# Get Date and Format correctly
$Date = Get-Date -Format yyyy.MM.dd

# Echo Date for the Transcript
$DateTime = Get-Date
Write-Host "Time and Date Script executed:`r`n$DateTime`r`n`r`n"

# Check if ActiveDirectory Module is Imported, if not Import Module for ActiveDirectory
# This also ensures that the server is a DC and will be able to be checked based on Site
$ADModule = Get-Module -ListAvailable | Where {$_.Name -like "ActiveDirectory"} | Select-Object -ExpandProperty Name
if ($ADModule -eq "ActiveDirectory")
{
	Import-Module ActiveDirectory
	Write-Host "Active Directory Module Present and Loaded!`r`n"
}
else
{
	Write-Host "Active Directory Module Not Available.`r`nExiting Script!`r`n"
	Stop-Transcript
	Send-MailMessage -From 'sysadm@domain.com' -To 'sysadm@domain.com' -Subject "DHCP Backup Error - $Hostname" `
	-Body "Good day Sysadm`r`n`r`nThe following DHCP Backup for $Hostname has run on $Date`r`n`r`nNo AD Module Present!`r`n`r`nThank you`r`nSysAdm" -SmtpServer 'smtp.domain.com'
	Exit
}

# Run Netsh Export for the DHCP Server Scopes and Config
Invoke-Command -Scriptblock {netsh dhcp server export "C:\DHCPTemp\NetshExport" all}
Write-Host "NetSh Export Completed!`r`n"

# Run NetSh Dump for the DHCP Server Config
Invoke-Command -Scriptblock {netsh dhcp server dump > "C:\DHCPTemp\Dump.cfg"}
Write-Host "NetSh Dump Completed!`r`n"

# Selecting correct location based on Site Name
$Site = Get-ADDomainController | Select -ExpandProperty Site

# List of the sites available ***NB*** UPDATE LIST IF NEW SITE IS SETUP
$SitesList = "Site1", "Site2", "Site3", "Site4", "Site5", "Site6", "Site6", "Site7"

# Creating the necessary folder to use with the copying of new Export
if($SitesList -contains "$Site")
{
	if((Test-Path -Path "\\domain.com\DHCP\$Site\$Date") -ne $true)
	{
		New-Item "\\domain.com\DHCP\$Site\$Date" -type directory
	}
	Stop-Transcript
	Copy -Force "C:\DHCPTemp\*" "\\domain.com\DHCP\$Site\$Date"
}
# If the Sitename is not detected it will then create a folder using the Hostname
else{
	echo "Site selected is not valid for this Domain Controllers DHCP Backup"
	if((Test-Path -Path "\\domain.com\DHCP\$Hostname\$Date") -ne $true)
	{
		New-Item "\\domain.com\DHCP\$Hostname\$Date" -type directory
	}
	Stop-Transcript
	Copy -Force "C:\DHCPTemp\*" "\\domain.com\DHCP\$Hostname\$Date"
}

# Echo $Error to a File otherwise its unable to be used correctly as an Array/Variable
$CheckErrors = $Error.Count -ne "0"
if ($CheckErrors -eq "True")
{
	echo $Error > "C:\DHCPTemp\Errors.txt"
	$GCError = Get-Content "C:\DHCPTemp\Errors.txt" # Without this there is no way to output the errors in the email correctly
	Send-MailMessage -From 'sysadm@domain.com' -To 'sysadm@domain.com' -Subject "DHCP Backup Error - $Hostname" `
	-Body "Good day Sysadm`r`n`r`nThe following DHCP Backup Failed for $Hostname $Date`r`n`r`n<ERROR>`r`n`r`n$GCError`r`n`r`n</ERROR>`r`n`r`nThank you`r`nSysAdm" -SmtpServer 'smtp.domain.com'
	Exit
}
# If no errors are detected it will proceed and end the powershell session
else
{
	Exit
}