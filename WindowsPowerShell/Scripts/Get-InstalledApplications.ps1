# ------------------------------------------------------------------
# Title: Get-InstalledApplications.ps1
# Author: Lars Jostein Silihagen
# Description: Get a list of installed applications based on uninstall information in Registry and creates a WQL-query for each installed application.
# Date Published: 19-Mar-2012 5:06:46 AM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Get-InstalledApplicationsps-e2aee784
# Tags: SCCM;Applications;Configuration Manager
# Rating: 4 rated by 1
# ------------------------------------------------------------------

<#
    .SYNOPSIS
        Get a list of installed applications based on uninstall information in Registry and creates
		a WQL-query for each installed application.
		
		The Objects retuned:
		 - AppName
		 - AppVersion
		 - AppVendor
		 - UninstallString
		 - AppGui
		 - WQLQuery
					
    .PARAMETER ComputerName
		Name of the machine to retrieve data from 
          
    .EXAMPLE
        Get a list of installed applications on local computer:
        
		Get-InstalledApplications.ps1  
		
		AppName         : Aruba Networks Virtual Intranet Access
		AppVersion      : 2.0.1.0.30205
		AppVendor       : Aruba Networks
		UninstallString : MsiExec.exe /X{F5CE8021-D68C-44A9-A69E-14725B63212D}
		AppGUID         : {F5CE8021-D68C-44A9-A69E-14725B63212D}
		WQLQuery        : SELECT * FROM Win32Reg_AddRemovePrograms WHERE Displayname LIKE 'Aruba Networks Virtual Intranet Access 2.0.1.0.30205' AND Version LIKE '2.0.1.0.30205'
	
	.EXAMPLE
		Get application name and WQL-query for installed applications on remote computer:
		
		Get-InstalledApplications.ps1 -ComputerName <ComputerName> | select AppName, WQLquery | Format-List
		AppName  : Aruba Networks Virtual Intranet Access
		WQLQuery : SELECT * FROM Win32Reg_AddRemovePrograms WHERE Displayname LIKE 'Aruba Networks Virtual Intranet Access 2.0.1.0.30205' AND Version LIKE '2.0.1.0.30205'

	.NOTES 
		AUTHOR:    Lars Jostein SIlihagen 
		BLOG:      http://blog.silihagen.net 
		LASTEDIT:  19.03.2012
		You have a royalty-free right to use, modify, reproduce, and 
		distribute this script file in any way you find useful, provided that 
		you agree that the creator, owner above has no warranty, obligations, 
		or liability for such use. 
#>


[cmdletbinding()]
param
(
	[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	[string[]]$ComputerName = $env:computername            
)            
begin 
{
$ErrorActionPreference = "SilentlyContinue"
	# Registry	
	$UninstallRegKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
}            
process 
{
	foreach($Computer in $ComputerName) 
	{
   		# Test computer connection
		if (Test-Connection -ComputerName $Computer -Count 1 -ea 0)
		{
			$HKLM = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computer)
			$UninstallRef = $HKLM.OpenSubKey($UninstallRegKey)
			$Applications = $UninstallRef.GetSubKeyNames()            

   			foreach ($App in $Applications) 
			{
    			$AppRegistryKey  = $UninstallRegKey + "\\" + $App
    			$AppDetails = $HKLM.OpenSubKey($AppRegistryKey)
    			$AppGUID = $App
    			$AppDisplayName = $($AppDetails.GetValue("DisplayName"))
    			$AppVersion = $($AppDetails.GetValue("DisplayVersion"))
    			$AppPublisher = $($AppDetails.GetValue("Publisher"))
    			$AppUninstall = $($AppDetails.GetValue("UninstallString"))
    
				if (!$AppDisplayName) 
				{ 
					continue 
				}
			    # App information
				$OutputObj = New-Object -TypeName PSobject
 				$OutputObj | Add-Member -MemberType NoteProperty -Name AppName -Value $AppDisplayName
    			$OutputObj | Add-Member -MemberType NoteProperty -Name AppVersion -Value $AppVersion
    			$OutputObj | Add-Member -MemberType NoteProperty -Name AppVendor -Value $AppPublisher
 				$OutputObj | Add-Member -MemberType NoteProperty -Name UninstallString -Value $AppUninstall
    			$OutputObj | Add-Member -MemberType NoteProperty -Name AppGUID -Value $AppGUID    			
				
				# AMD64 or X86 App?
				$GetWmiClass =  Get-WmiObject -Class "Win32reg_addRemovePrograms" -ComputerName $Computer | Select Displayname
				if ($GetWmiClass)
				{
					foreach ($DispName in $GetWmiClass)
					{
						If ($DispName.Displayname -eq $AppDisplayName)					
						{
							#x86
							$WMIType = "Win32Reg_AddRemovePrograms"	
						}
						else
						{
							#AMD64
							$WMIType = "Win32Reg_AddRemovePrograms64"	
						}
					}
				
					#WQL query
					$WqlQuery = "SELECT * FROM " + $WMIType + " WHERE Displayname LIKE '" + $AppDisplayName + "' AND Version LIKE '" + $AppVersion + "'"
										
					#Test WQL query
					$TestWQLQuery = Get-WmiObject -query $WQLQuery -ComputerName $Computer
					if ($TestWQLQuery)
					{
						#WQL-query verifyed
						$OutputObj | Add-Member -MemberType NoteProperty -Name WQLQuery -Value $WqlQuery 
						$OutputObj
					}
					else
					{
						# error in WMI query
						$OutputObj | Add-Member -MemberType NoteProperty -Name WQLQuery -Value "Error testing WQL query."	
						$OutputObj
					}
				}
				else
				{
					# error connection WMI
					$OutputObj | Add-Member -MemberType NoteProperty -Name WQLQuery -Value "Error: Can't determine WQL-query. Error in WMI-connection for computer: " $Computer
					$OutputObj
				}
   			}
  		}
		else
		{
			Write-host -BackgroundColor Black -ForegroundColor Red "Error: Can not reach the machine: " $Computer 
			Write-host -BackgroundColor Black -ForegroundColor Red "Quit PowerShell script"
		}
 	}
}            
end {}