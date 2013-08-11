<#
	.SYNOPSIS
		List users in specified local group
	.DESCRIPTION
		Created: March 17, 2011 Jeff Patton
		This script searches ActiveDirectory for computers. It then queries each computer for the list of users who 
		are in the local Administrators group.
	.PARAMETER ADSPath
		The LDAP URI of the container you wish to pull computers from.
	.PARAMETER GroupName
		The name of the local group to pull membership pfrom.
	.EXAMPLE
		find-localadmins "LDAP://OU=Workstations,DC=company,DC=com"
	.NOTES
		You will need to run this script as an administrator or disable UAC to update the event-log
		You will need to have at least Read permissions in the AD container in order to get a list of computers.
	.LINK
		http://scripts.patton-tech.com/wiki/PowerShell/Production/FindLocalAdmins
#>

Param
	(
		[Parameter(Mandatory=$true)]
		[string]$ADSPath,
		[Parameter(Mandatory=$true)]
		[string]$GroupName
	)	
Begin
    {
        $ScriptName = $MyInvocation.MyCommand.ToString()
        $LogName = "Application"
        $ScriptPath = $MyInvocation.MyCommand.Path
        $Username = $env:USERDOMAIN + "\" + $env:USERNAME

        New-EventLog -Source $ScriptName -LogName $LogName -ErrorAction SilentlyContinue
        	
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nStarted: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "100" -EntryType "Information" -Message $Message 
        	
        #	Dotsource in the AD functions
        . .\includes\ActiveDirectoryManagement.ps1
    }
Process
    {    	
    	$computers = Get-ADObjects $ADSPath
    	
    	foreach ($computer in $computers)
    		{
    			if ($computer -eq $null){}
    			else
    				{
    					$groups = Get-LocalGroupMembers $computer.Properties.name $GroupName
    					If ($groups -ne $null)
    						{
    							write-host "Accounts with membership in $GroupName on: " $computer.Properties.name
    							$groups | Format-Table -autosize
    						}
    				}
    		}
	}
End
    {    
    	$Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
    	Write-EventLog -LogName $LogName -Source $ScriptName -EventID "100" -EntryType "Information" -Message $Message	
    }