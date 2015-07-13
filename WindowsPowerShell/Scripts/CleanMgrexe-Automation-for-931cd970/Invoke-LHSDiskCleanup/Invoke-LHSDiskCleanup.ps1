<#
  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************
#> 
Function Invoke-LHSDiskCleanup
{
<#
.SYNOPSIS
    Invoke Disk cleanup on local or remote Windows Server 2008R2.

.DESCRIPTION
    Invoke Disk cleanup on local or remote Windows Server 2008R2 using WMI and dotNet.
    Without the need to Install the Desktop Experience feature (by creating Reg Key structure 'CLSID'). 
    This script requires KB2852386. Run with Admin rights

    This Script supports only Win Server 2008R2 English and German OS Versions

    The following Elements are going to be cleaned up by default,
    each Element can be set to $True/$False in #region Settings :

        'Active Setup Temp Folders', 
        'Downloaded Program Files', 
        'Internet Cache Files', 
        'Offline Pages Files', 
        'Previous Installations', 
        'Recycle Bin',
        'Service Pack Cleanup', 
        'System error memory dump files', 
        'System error minidump files', 
        'Temporary Setup Files',
        'Thumbnail Cache',
        'Update Cleanup', 
        'Upgrade Discarded Files', 
        'Windows Error Reporting Archive Files',
        'Windows Error Reporting Queue Files', 
        'Windows Error Reporting System Archive Files', 
        'Windows Error Reporting System Queue Files', 
        'Windows Upgrade Log Files'


.PARAMETER ComputerName
    The computer name to run disk Cleanup. 
    Default to local Computer

.EXAMPLE
    Invoke-LHSDiskCleanup

    To run disk cleanup on the local computer.

.EXAMPLE
    Invoke-LHSDiskCleanup -ComputerName Server1 -Verbose

    To run disk cleanup on 'Server1' with detailed output info

.INPUTS
    System.String, you can pipe ComputerNames to this Function

.OUTPUTS
    None to the pipeline.

.NOTES
    The Disk Cleanup executable file cleanmgr.exe and the associated Disk Cleanup button 
    are not present in Windows Server® 2008 or in Windows Server® 2008 R2 by default.

    In order to use cleanmgr.exe you’ll need to copy two files that are already 
    present on the server, cleanmgr.exe and cleanmgr.exe.mui.
    
    For an English OS, moving cleanmgr.exe and cleanmgr.exe.mui into the correct directories 
    from within winsxs:
    Copy-Item "C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe" C:\Windows\system32
    Copy-Item "C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_en-us_b9cb6194b257cc63\cleanmgr.exe.mui" C:\Windows\System32\en-US
 
    If you have a Server OS which is NOT en-US, then the MUI file probably needs to be 
    copied into the matching subfolder. Otherwise the process will load, but offer no UI at all. 


    NOTE: on Servers where there is nothing to cleanup, the Free space in GB After the cleanup is ~ 100 MB less
        than before. The reason is that a logfile is created under c:\Windows\Logs\CBS\CBS.log which is
        about 100MB big in size. After a reboot this file is only about 4KB big in size and will increase again.
        (Component Based Servicing)
    

    Note (PL): I found out that copying these files does not enable all disk cleanup feature. 
    Options for 'System error memory dump files' or 'System error minidump files' are not available. 
    If you install the 'Desktop Experience', all these options are available. For more Info see
    Automating Disk Cleanup Tool in Windows.docx.

    'System error memory dump files' are stored under C:\Windows\memory.dmp
    'System error minidump files' are stored under C:\Windows\Minidump\021115-19078-01.dmp

    (PL)To make it work copy the following files
    1.	C:\Windows\winsxs\amd64_microsoft-windows-dataclen_31bf3856ad364e35_6.1.7600.16385_none_529b2718ad26c095\dataclen.dll
        Should go in  %systemroot%\System32
    2.	C:\Windows\winsxs\amd64_microsoft-windows-dataclen.resources_31bf3856ad364e35_6.1.7600.16385_de-de_704bd9d247dc15d7\dataclen.dll.mui  
        Should go in  %systemroot%\System32\de-DE 
        For an English system ist should go in %systemroot%\System32\en-US
    3.	Export the following Registry structure from a Computer with Desktop Experience enabled, and import it:
        HKEY_CLASSES_ROOT\CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}
        (it works also exporting it from a Win 7 and import it to a win 2008R2)



    AUTHOR  : Pasquale Lantella 
    LASTEDIT: 19.05.2015
    Version : 1.1
        Added Hashtable for folder Names which will be cleaned. Each folder can now be enabled/disabled.
    Version : 1.2
        Added Copy file of dataclen.dll,dataclen.dll.mui
        Added Create Registry Key structure: HKEY_CLASSES_ROOT\CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}
    KEYWORDS: Disk Cleanup

.LINK
    Disk Cleanup option on drive’s general properties and cleanmgr.exe is not present in 
    Windows Server 2008 or Windows Server 2008 R2 by default
    https://technet.microsoft.com/en-us/library/ff630161%28v=ws.10%29.aspx

.LINK
    Disk Cleanup Wizard addon lets users delete outdated Windows updates on Windows 7 SP1 
    or Windows Server 2008 R2 SP1 
    https://support.microsoft.com/en-us/kb/2852386

.LINK
    Automating Disk Cleanup Tool in Windows 
    https://support.microsoft.com/en-us/kb/253597/en-us

.LINK
    Creating a Disk Cleanup Handler
    http://msdn.microsoft.com/en-us/library/bb776782.aspx

#Requires -Version 2.0
#>
   
[cmdletbinding(  
    ConfirmImpact = 'low',
    SupportsShouldProcess = $false
)]  

[OutputType('None')] 

Param(
    [Parameter(ParameterSetName='Default', Position=0,Mandatory=$False,ValueFromPipeline=$True,
        HelpMessage='A computer name. The default is the local computer.')]
	[alias("CN")]
	[string]$ComputerName = $Env:COMPUTERNAME
)

BEGIN {

    Set-StrictMode -Version Latest
    ${CmdletName} = $Pscmdlet.MyInvocation.MyCommand.Name


#region Settings    
    $RegHive = 'LocalMachine'
    $RegPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
    $RegValueName = 'StateFlags0032'

    #Folders Names for Win 2008R2 which will been cleaned. Veryfied in Registry (EN/GER)
    $TempFolders = @{
        'Active Setup Temp Folders' = $true; 
        'Downloaded Program Files' = $true; 
        'Internet Cache Files' = $true;  
        'Offline Pages Files' = $true;  
        'Previous Installations' = $true;  
        'Recycle Bin' = $true; 
        'Service Pack Cleanup' = $true;  
        'System error memory dump files' = $true;  
        'System error minidump files' = $true;  
        'Temporary Setup Files' = $true; 
        'Thumbnail Cache' = $true; 
        'Update Cleanup' = $true;  
        'Upgrade Discarded Files' = $true;  
        'Windows Error Reporting Archive Files' = $true; 
        'Windows Error Reporting Queue Files' = $true;  
        'Windows Error Reporting System Archive Files' = $true;  
        'Windows Error Reporting System Queue Files' = $true;  
        'Windows Upgrade Log Files' = $true;  
    } 


#endregion Settings


#region functions

function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()

    (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}



function Test-RegSubKey
{
# Function: Test-RegSubKey
# Description: Test the existence of the registry key
# Return Value: True/false respectively
	param(
		[string]$ComputerName = ".",
		[string]$hive,
		[string]$keyName
	)

	$hives = [enum]::getnames([Microsoft.Win32.RegistryHive])

	if($hives -notcontains $hive){
		write-error "Invalid hive value";
		return;
	}
	
	$regHive = [Microsoft.Win32.RegistryHive]$hive;
	$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($regHive,$ComputerName);
	$subKey = $regKey.OpenSubKey($keyName);

	if(!$subKey){$false}  else {$true}
}


function New-RegSubKey
{
# Function: New-RegSubKey
# Description: Create the registry key
# Return Value: True/false respectively

	param(
		[string]$ComputerName = ".",
		[string]$hive,
		[string]$keyName
	)

	$hives = [enum]::getnames([Microsoft.Win32.RegistryHive])

	if($hives -notcontains $hive){
		write-error "Invalid hive value";
		return;
	}
	
	$regHive = [Microsoft.Win32.RegistryHive]$hive;
	$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($regHive,$ComputerName);
	[void]$regKey.CreateSubKey($keyName);
	
	if($?) {$true} else {$false}
}

function Test-RegValue
{
# Function: Test-RegValue
# Description: Test the existence of the registry value
# Return Value: True/false respectively
	param(
		[string]$ComputerName = $env:COMPUTERNAME,
		[string]$hive,
		[string]$keyName,
		[string]$valueName
	)

	$hives = [enum]::getnames([Microsoft.Win32.RegistryHive])

	if($hives -notcontains $hive)
    {
		write-error "Invalid hive value";
		return;
	}
	
	$regHive = [Microsoft.Win32.RegistryHive]$hive;
	$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($regHive,$ComputerName);
	$subKey = $regKey.OpenSubKey($keyName);
	
	if(!$subKey)
    {
		write-error "The specified registry key does not exist.";
		return;
	}
	
	$regVal=$subKey.GetValue($valueName);
	if(!$regVal){$false} else {$true}
}#end function Test-RegValue



function Set-RegDefault
{
# Function: Set-RegDefault
# Description: Set the registry default value
# Return Value: True/false respectively

	param(
		[string]$ComputerName = ".",
		[string]$hive,
		[string]$keyName,
        [ValidateSet('String','ExpandString','DWord')]
        [string]$Type,
		$value	
	)
	
	$hives = [enum]::getnames([Microsoft.Win32.RegistryHive])

	if($hives -notcontains $hive){
		write-error "Invalid hive value";
		return;
	}
	
	$regHive = [Microsoft.Win32.RegistryHive]$hive;
	$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($regHive,$ComputerName);
	$subKey = $regKey.OpenSubKey($keyName,$true);

	if(!$subKey){
		write-error "The specified registry key does not exist.";
		return;
	}

    Switch ($Type)
    {
	    'String' {#$regKey.SetValue($null, $value,[Microsoft.Win32.RegistryValueKind]::String);
	            $subKey.SetValue($null, $value,[Microsoft.Win32.RegistryValueKind]::String);}

        'ExpandString' { $subKey.SetValue($null, $value,[Microsoft.Win32.RegistryValueKind]::ExpandString); }

        'DWord' { $subKey.SetValue($null, $value,[Microsoft.Win32.RegistryValueKind]::DWord); }
    
	}
	if($?) {$true} else {$false}
}



function Set-RegString
{
# Function: Set-RegString
# Description: Create/Update the specified registry string value
# Return Value: True/false respectively
	param(
		[string]$ComputerName = ".",
		[string]$hive,
		[string]$keyName,
		[string]$valueName,
		[string]$value	
	)
	
	$hives = [enum]::getnames([Microsoft.Win32.RegistryHive])

	if($hives -notcontains $hive){
		write-error "Invalid hive value";
		return;
	}
	
	$regHive = [Microsoft.Win32.RegistryHive]$hive;
	$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($regHive,$ComputerName);
	$subKey = $regKey.OpenSubKey($keyName,$true);

	if(!$subKey){
		write-error "The specified registry key does not exist.";
		return;
	}
	
	$subKey.SetValue($valueName, $value, [Microsoft.Win32.RegistryValueKind]::String);
	if($?) {$true} else {$false}
}


function Set-RegDWord
{
# Function: Set-RegDWord
# Description: Create/Update the registry value (REG_DWORD)
# Return Value: True/false respectively
	param(
		[string]$ComputerName = $env:COMPUTERNAME,
		[string]$hive,
		[string]$keyName,
		[string]$valueName,
		[double]$value	
	)

	$hives = [enum]::getnames([Microsoft.Win32.RegistryHive])

	if($hives -notcontains $hive)
    {
		write-error "Invalid hive value";
		return;
	}
	$regHive = [Microsoft.Win32.RegistryHive]$hive;
	$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($regHive,$ComputerName);
	$subKey = $regKey.OpenSubKey($keyName,$true);

	if(!$subKey){
		write-error "The specified registry key does not exist.";
		return;
	}
	
	$subKey.SetValue($valueName, $value,[Microsoft.Win32.RegistryValueKind]::DWord);
	if($?) {$true} else {$false}
}#end function Set-RegDWord

#endregion functions


} # end BEGIN

PROCESS {

    If (-not (Test-IsAdmin)) { Write-Warning "This script requires Admin rights." ; return}

    IF (Test-Connection -ComputerName $ComputerName -count 2 -quiet) 
    {    
        Try
        {    
            # ensure we're running on Windows Server 2008R2 
            $OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -Property Version, ProductType, OSLanguage -ErrorAction Stop
            If (($OS.Version -like '6.1*') -and ($OS.ProductType -eq 3))
            {
                Write-Verbose "Windows Server 2008R2 detected" -Verbose
                Try{Get-HotFix -ComputerName $ComputerName -Id kb2852386 -ErrorAction Stop | Out-Null}
                Catch {Write-Warning "KB2852386 is required. Please install hotfix and re-run.";return}

                Switch ($OS.OSLanguage)
                {
                    '1031' { Write-Verbose "OS = German"
             
                            Copy-Item "\\$ComputerName\C$\Windows\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe" "\\$ComputerName\C$\Windows\system32" -ErrorAction Stop
                            Copy-Item "\\$ComputerName\C$\Windows\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_de-de_10da8b9bc379c09e\cleanmgr.exe.mui" "\\$ComputerName\C$\Windows\System32\de-DE" -ErrorAction Stop

                            Copy-Item "\\$ComputerName\C$\Windows\winsxs\amd64_microsoft-windows-dataclen_31bf3856ad364e35_6.1.7600.16385_none_529b2718ad26c095\dataclen.dll" "\\$ComputerName\C$\Windows\system32" -ErrorAction Stop
                            Copy-Item "\\$ComputerName\C$\Windows\winsxs\amd64_microsoft-windows-dataclen.resources_31bf3856ad364e35_6.1.7600.16385_de-de_704bd9d247dc15d7\dataclen.dll.mui" "\\$ComputerName\C$\Windows\System32\de-DE" -ErrorAction Stop
                        }
                    '1033' { Write-Verbose "OS = English_US"
    
                            Copy-Item "\\$ComputerName\C$\Windows\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe" "\\$ComputerName\C$\Windows\system32" -ErrorAction Stop
                            Copy-Item "\\$ComputerName\C$\Windows\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_en-us_b9cb6194b257cc63\cleanmgr.exe.mui" "\\$ComputerName\C$\Windows\System32\en-US" -ErrorAction Stop

                            Copy-Item "\\$ComputerName\c$\windows\winsxs\amd64_microsoft-windows-dataclen_31bf3856ad364e35_6.1.7600.16385_none_529b2718ad26c095\dataclen.dll" "\\$ComputerName\C$\Windows\system32" -ErrorAction Stop
                            Copy-Item "\\$ComputerName\c$\windows\winsxs\amd64_microsoft-windows-dataclen.resources_31bf3856ad364e35_6.1.7600.16385_en-us_193cafcb36ba219c\dataclen.dll.mui" "\\$ComputerName\C$\Windows\System32\en-US" -ErrorAction Stop
                         }
                    Default { Write-Warning "OS Language [$($OS.OSLanguage)] not Supported for this Script"; return }
                }

            }
            Else
            {
                Write-Warning "This script is for Windows Server 2008R2 only"
                return
            }

            ($TempFolders.GetEnumerator() | Sort-Object Name) | Out-String | Write-Verbose 

#region Reg_CLSID
            # save the current Setting
            $DefaultErrorActionPreference = $ErrorActionPreference.ToString()
            $ErrorActionPreference = 'Stop'  
             
            # create Registry CLSID structure for Disk Cleanup Manager
            If (-not (Test-RegSubKey -ComputerName $ComputerName -hive 'ClassesRoot' -keyName 'CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}'))
            {

                Write-Verbose "Creating RegKey \\$ComputerName\HKEY_CLASSES_ROOT\CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6} ..."
                New-RegSubKey -ComputerName $ComputerName -hive 'ClassesRoot' -keyName 'CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}'

                Write-Verbose "Creating RegKey \\$ComputerName\HKEY_CLASSES_ROOT\CLSID\{C1060E7E-7939-44A5-99C3-A6DCCD92AED0}\InProcServer32 ..."
                New-RegSubKey -ComputerName $ComputerName -hive 'ClassesRoot' -keyName 'CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}\InProcServer32'

                Write-Verbose "Creating Default RegValue at \\$ComputerName\HKEY_CLASSES_ROOT\CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6} ..."
                # Reg_SZ
                Set-RegDefault -ComputerName $ComputerName -hive 'ClassesRoot' -keyName 'CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}' -Type String -value 'Data Driven Cleaner' 

                Write-Verbose "Creating Default RegValue at \\$ComputerName\HKEY_CLASSES_ROOT\CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}\InProcServer32 ..."
                # Reg_EXPAND_SZ
                Set-RegDefault -ComputerName $ComputerName -hive 'ClassesRoot' -keyName 'CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}\InProcServer32' -Type ExpandString -value '%SystemRoot%\System32\DATACLEN.DLL' 

                 Write-Verbose "Creating 'Apartment' RegValue at \\$ComputerName\HKEY_CLASSES_ROOT\CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}\InProcServer32 ..."
                # Reg_SZ
                Set-RegString -ComputerName $ComputerName -hive 'ClassesRoot' -keyName 'CLSID\{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}\InProcServer32' -valueName 'ThreadingModel' -value 'Apartment'

            }
            # Reset to Default
            $ErrorActionPreference = $DefaultErrorActionPreference 
#endregion Reg_CLSID


#region Reg_StateFlags
            #Set StateFlags setting for each item of disk cleanup utility
            foreach ($TemFolder in ($TempFolders.GetEnumerator() | Sort-Object Name).Key)
            {
                $RegKey = $RegPath + "\" + $TemFolder
                
                If ($TempFolders.$TemFolder)
                {
                    #Include this handler when this profile is run.
                    If (-Not (Set-RegDWord -ComputerName $ComputerName -hive $RegHive -keyName $RegKey -valueName $RegValueName -value 2))
                    {
                        Write-Error "Could not set RegValue \\$ComputerName\$RegHive\$RegKey\$RegValueName"
                        return
                    }
                }
                Else
                {
                    # Do not run this handler when this profile is run.
                    If (-Not (Set-RegDWord -ComputerName $ComputerName -hive $RegHive -keyName $RegKey -valueName $RegValueName -value 0))
                    {
                        Write-Error "Could not set RegValue \\$ComputerName\$RegHive\$RegKey\$RegValueName"
                        return
                    }
                }

             } #end foreach ($TemFolder in $TempFolders)
#endregion Reg_StateFlags

            #Capture current free disk space on Drive C:
            $FreespaceBefore = (Get-WmiObject -Class win32_logicaldisk -ComputerName $ComputerName -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB

    
            # Invoke cleanmgr.exe on local or remote Computer
            $WMIParam = @{
                Path = 'Win32_Process';
                ComputerName = $ComputerName;	
                Name = 'Create';
                ArgumentList = 'cleanmgr.exe /sagerun:32'; 
            }
            Try 
            {
                Invoke-WmiMethod @WMIParam -ErrorAction Stop | Out-Null
            } 
            Catch 
            {
                Write-Warning ("{0}: {1}" -f $ComputerName,$_.Exception.Message)
                return
            }

            do 
            {
                Write-Host "waiting for cleanmgr to complete. . ."
                start-sleep 5
            } while ((Get-WmiObject -Class win32_process -ComputerName $ComputerName | Where-Object {$_.processname -eq 'cleanmgr.exe'} | measure).count)

            #Capture free disk space after cleanmgr on Drive C:
            $FreespaceAfter = (Get-WmiObject -Class win32_logicaldisk -ComputerName $ComputerName -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB

            Write-Host " "    
            "Free Space in GB Before: {0:N3}" -f $FreespaceBefore
            "Free Space in GB After : {0:N3}" -f $FreespaceAfter                
    
            Write-Host  "Disk Cleanup was successfully" -ForegroundColor Green 

         }
         Catch
         {
            Write-Error ("{0}: {1}" -f $ComputerName,$_.Exception.Message)
         }   

    } 
    Else 
    {
        Write-Warning "\\$ComputerName DO NOT reply to ping" 
    } # end IF (Test-Connection -ComputerName $ComputerName -count 2 -quiet)    

} # end PROCESS

END { Write-Verbose "Function ${CmdletName} finished." }

} # end Function Invoke-LHSDiskCleanup      
             









