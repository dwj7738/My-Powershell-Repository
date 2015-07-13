# Directions for use:
# Import this script using the Import-Module cmdlet
# All output is logged to the backup directory in the $($BackupDriveLetter):\VMBackup\Backup-VMs.log file
# Use the Backup-VMs cmdlet to begin the process
# 	Parameter BackupDriveLetter indicates the drive to put this backup onto. It must be mounted to the host running the script.
#	Parameter VMHost defines the host that contains the VMs you want to back up. If it's blank, then it just targets the host the script is running on
# 	Parameter VMNames defines the specific VMs you wish to backup, otherwise it'll back up all of them on the target host
#	Switch parameter ShutHostDownWhenFinished will cause the specified host (and any VMs running on it) to shut down upon completion of the backup
# Example:
# PS> Import-Module D:\Backup-VMs.ps1
# PS> Backup-VMs -BackupDriveLetter F -VMHost HyperVHost -VMNames mydevmachine,broker77

# ----------------------------------------------------------------------------
# Note that this script requires administrator privileges for proper execution
# ----------------------------------------------------------------------------

# Note that this script requires the following:
#
# PowerShell Management Library for Hyper-V (for the Get-VM and Export-VM cmdlets)
# This installs itself wherever you downloaded it - make sure the HyperV folder finds its way to somewhere in $env:PSModulePath
# http://pshyperv.codeplex.com/downloads/get/219013
#
# Windows PowerShell Pack (for the Copy-ToZip cmdlet)
# This installs to $home\Documents\WindowsPowerShell\Modules, make sure that this path is in $env:PSModulePath
# http://archive.msdn.microsoft.com/PowerShellPack/Release/ProjectReleases.aspx?ReleaseId=3341

# our one global variable is for logging
$Logfile = ""

Function Backup-VMs
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[parameter(Mandatory = $true)]
        [string]$BackupDriveLetter,			# $BackupDriveLetter:\VMBackups\$backupDate
		
		[ValidateNotNullOrEmpty()]
		[string]$VMHost,					# the host that holds the vms we wish to back up, otherwise the one running the script
		[string[]]$VMNames,					# if not specified, back up all of them
		[switch]$ShutHostDownWhenFinished	# when set, shuts down the target host, including any vms on it
	)
	process
	{
		# first, run a bunch of checks
		#region checks
		# check if the PowerShellPack modules are loaded
		$isPowerShellPackLoaded = Get-Module -Name PowerShellPack
		if (!$isPowerShellPackLoaded)
		{
			Write-Host "Attempting to load PowerShellPack modules..."
			Import-Module -Name PowerShellPack
			$isPowerShellPackLoaded = Get-Module -Name PowerShellPack
			if (!$isPowerShellPackLoaded)
			{
				Write-Host -ForegroundColor Red "Cannot load PowerShellPack module - terminating backup script."
				Break
			}
		}
		# check if the HyperV module is loaded
		$isHyperVModuleLoaded = Get-Module -Name HyperV
		if (!$isHyperVModuleLoaded)
		{
			Write-Host "Attempting to load HyperV module..."
			Import-Module -Name HyperV		
			$isHyperVModuleLoaded = Get-Module -Name HyperV
			if (!$isHyperVModuleLoaded)
			{
				Write-Host -ForegroundColor Red "Cannot load HyperV module - terminating backup script."
				Break
			}
		}
		# sanitize user input (F: will become F)
		if ($BackupDriveLetter -like "*:")
		{
			$BackupDriveLetter = $BackupDriveLetter -replace ".$"
		}
		# check to make sure the user specified a valid backup location
		if ((Test-Path "$($BackupDriveLetter):") -eq $false)
		{
			Write-Host -ForegroundColor Red "Drive $($BackupDriveLetter): does not exist - terminating backup script."
			Break
		}
		# if host was not speicified, use the host running the script
		if ($VMHost -eq "")
		{
			$VMHost = Hostname
		}
		# check to make sure the specified host is a vmhost
		if (!(Get-VMHost) -icontains $VMHost)
		{
			Write-Host -ForegroundColor Red "Host $($VMHost) is not listed in Get-VMHost - terminating backup script."
			Break
		}
		# check to make sure the specified host has any vms to back up
		if (!(Get-VM -Server $VMHost))
		{
			Write-Host -ForegroundColor Red "Host $($VMHost) does not appear to have any VMs running on it according to 'Get-VM -Server $($VMHost)'."
			Write-Host -ForegroundColor Yellow "This can be occur if PowerShell is not running with elevated privileges."
			Write-Host -ForegroundColor Yellow "Please make sure that you are running PowerShell with Administrator privileges and try again."
			Write-Host -ForegroundColor Red "Terminating backup script."
			Break
		}
		#endregion
		
		#region directory business
		# make our parent directory if needed
		if ((Test-Path "$($BackupDriveLetter):\VMBackup") -eq $false)
		{
			$parentDir = New-Item -Path "$($BackupDriveLetter):\VMBackup" -ItemType "directory"
			if ((Test-Path $parentDir) -eq $false)
			{
				Write-Host -ForegroundColor Red "Problem creating $parentDir - terminating backup script."
				Break
			}
		}
		
		# initialize our logfile
		$Logfile = "$($BackupDriveLetter):\VMBackup\Backup-VMs.log"
		if ((Test-Path $Logfile) -eq $false)
		{
			$newFile = New-Item -Path $Logfile -ItemType "file"
			if ((Test-Path $Logfile) -eq $false)
			{
				Write-Host -ForegroundColor Red "Problem creating $Logfile - terminating backup script."
				Break
			}
		}

		$backupDate = Get-Date -Format "yyyy-MM-dd"
		$destDir = "$($BackupDriveLetter):\VMBackup\$backupDate-$VMHost-backup\"
		
		# make our backup directory if needed
		if ((Test-Path $destDir) -eq $false)
		{
			$childDir = New-Item -Path $destDir -ItemType "directory"
			if ((Test-Path $childDir) -eq $false)
			{
				Write-Host -ForegroundColor Red "Problem creating $childDir - terminating backup script."
				Break
			}
		}
		#endregion
		
		Add-content -LiteralPath $Logfile -value "==================================================================================================="
		Add-content -LiteralPath $Logfile -value "==================================================================================================="
		# now that our checks are done, start backing up
		T -text "Starting Hyper-V virtual machine backup for host $VMHost at:"
		$dateTimeStart = date
		T -text "$($dateTimeStart)"
		T -text ""
		
		# export the vms to the destination
		ExportMyVms -VMHost $VMHost -Destination $destDir -VMNames $VMNames
		
		T -text ""
		T -text "Exporting finished"
		
		#region compression

		# get what we just backed up
		$sourceDirectory = Get-ChildItem $destDir
		
		if ($sourceDirectory)
		{
			# get the total size of all of the files we just backed up
			$sourceDirSize = Get-ChildItem $destDir -Recurse | Measure-Object -property length -sum -ErrorAction SilentlyContinue
			$sourceDirSize = ($sourceDirSize.sum / 1GB)
			
			# get how much free space is left on our backup drive
			$hostname = Hostname
			$backupDrive = Get-WmiObject win32_logicaldisk -ComputerName $hostname | Where-Object { $_.DeviceID -eq "$($BackupDriveLetter):" }
			$backupDriveFreeSpace = ($backupDrive.FreeSpace / 1GB)
			
			# tell the user what we've found
			$formattedBackupDriveFreeSpace = "{0:N2}" -f $backupDriveFreeSpace
			$formattedSourceDirSize = "{0:N2}" -f $sourceDirSize
			T -text "Checking free space for compression:"
			T -text "Drive $($BackupDriveLetter): has $formattedBackupDriveFreeSpace GB free on it, this backup took $formattedSourceDirSize GB"
			
			# check if we need to make any room for the next backup
			$downToOne = $false
			while (!$downToOne -and $sourceDirSize > $backupDriveFreeSpace)
			{
				# clear out the oldest backup if this is the case
				$backups = Get-ChildItem -Path "$($BackupDriveLetter):\VMBackup\" -include "*-backup.zip" -recurse -name
				$backups = [array]$backups | Sort-Object
				
				# make sure we aren't deleting the only directory!
				if ($backups.length -gt 1)
				{
					T -text "Removing the oldest backup [$($backups[0])] to clear up some more room"
					Remove-Item "$($BackupDriveLetter):\VMBackup\$($backups[0])" -Recurse -Force
					# now check again
					$backupDrive = Get-WmiObject win32_logicaldisk -ComputerName $hostname | Where-Object { $_.DeviceID -eq "$($BackupDriveLetter):" }
					$backupDriveFreeSpace = ($backupDrive.FreeSpace / 1GB)
					$formattedBackupDriveFreeSpace = "{0:N2}" -f $backupDriveFreeSpace
					T -text "Now we have $formattedBackupDriveFreeSpace GB of room"
				}
				else
				{
					# we're down to just one backup left, don't delete it!
					$downToOne = $true
				}
			}
			T -text "Compressing the backup..."
			# zip up everything we just did
			ZipFolder -directory $destDir -VMHost $VMHost
			
			$zipFileName = $destDir -replace ".$"
			$zipFileName = $zipFileName + ".zip"
			
			T -text "Backup [$($zipFileName)] created successfully"
			$destZipFileSize = (Get-ChildItem $zipFileName).Length / 1GB
			$formattedDestSize = "{0:N2}" -f $destZipFileSize
			T -text "Uncompressed size:`t$formattedSourceDirSize GB"
			T -text "Compressed size:  `t$formattedDestSize GB"
		}
		#endregion
					
		# delete the non-compressed directory, leaving just the compressed one
		Remove-Item $destDir -Recurse -Force
		
		T -text ""
		T -text "Finished backup of $VMHost at:"
		$dateTimeEnd = date
		T -text "$($dateTimeEnd)"
		$length = ($dateTimeEnd - $dateTimeStart).TotalMinutes
		$length = "{0:N2}" -f $length
		T -text "The operation took $length minutes"
		
		if ($ShutHostDownWhenFinished -eq $true)
		{
			T -text "Attempting to shut down host machine $VMHost"
			ShutdownTheHost -HostToShutDown $VMHost
		}
	}
}

## this function will shut down any vms running on the host executing this script and then shut down said host
Function ShutdownTheHost
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
        [string]$HostToShutDown
	)
	process
	{
		## Get a list of all VMs on $HostToShutDown
		$VMs = Get-VM -Server $HostToShutDown
		## only run through the list if there's anything in it
		if ($VMs)
		{
			## For each VM on Node, Save (if necessary), Export and Restore (if necessary)
			foreach ($VM in @($VMs))
			{
				$VMName = $VM.ElementName
				$summofvm = get-vmsummary $VMName
				$summhb = $summofvm.heartbeat
				$summes = $summofvm.enabledstate
				
				## Shutdown the VM if HeartBeat Service responds
				if ($summhb -eq "OK")
				{
					T -text ""
					T -text "HeartBeat Service for $VMName is responding $summhb, saving the machine state"
					
					Save-VM -VM $VMName -Server $VMHost -Force -Wait
				}
				## Checks to see if the VM is already stopped
				elseif (($summes -eq "Stopped") -or ($summes -eq "Suspended"))
				{
					T -text ""
					T -text "$VMName is $summes"
				}
				
				## If the HeartBeat service is not OK, aborting this VM
				elseif ($summhb -ne "OK" -and $summes -ne "Stopped")
				{
					T -text
					T -text "HeartBeat Service for $VMName is responding $summhb. Aborting save state."
				}
			}
			T -text "All VMs on $HostToShutDown shut down or suspended."
		}
		T -text "Shutting down machine $HostToShutDown..."
		Stop-Computer -ComputerName $HostToShutDown
	}
}

## the following three functions relating to zipping up a folder come from Jeremy Jameson
## http://www.technologytoolbox.com/blog/jjameson/archive/2012/02/28/zip-a-folder-using-powershell.aspx
## I have modified his approach to suit the multi-gigabyte files we'll be dealing with

function IsFileLocked(
    [string] $path)
{    
    [bool] $fileExists = Test-Path $path
    
    If ($fileExists -eq $false)
    {
        Throw "File does not exist (" + $path + ")"
    }
    
    [bool] $isFileLocked = $true

    $file = $null
    
    Try
    {
        $file = [IO.File]::Open(
            $path,
            [IO.FileMode]::Open,
            [IO.FileAccess]::Read,
            [IO.FileShare]::None)
            
        $isFileLocked = $false
    }
    Catch [IO.IOException]
    {
        If ($_.Exception.Message.EndsWith("it is being used by another process.") -eq $false)
        {
            Throw $_.Exception
        }
    }
    Finally
    {
        If ($file -ne $null)
        {
            $file.Close()
        }
    }
    
    return $isFileLocked
}
    
function WaitForZipOperationToFinish(
    [__ComObject] $zipFile,
    [int] $expectedNumberOfItemsInZipFile)
{
    T -text "Waiting for zip operation to finish on $($zipFile.Self.Path)..."
    Start-Sleep -Seconds 5 # ensure zip operation had time to start
    
	# wait for the operation to finish
	# the folder is locked while we're zipping stuff up
	[bool] $isFileLocked = IsFileLocked($zipFile.Self.Path)	
    while($isFileLocked)
    {
        Write-Host -NoNewLine "."
        Start-Sleep -Seconds 5
        
        $isFileLocked = IsFileLocked($zipFile.Self.Path)
    }
    
    T -text ""    
}

function ZipFolder(
    [IO.DirectoryInfo] $directory)
{    
	$backupFullName = $directory.FullName
	
    T -text ("Creating zip file for folder ($backupFullName)...")
    
    [IO.DirectoryInfo] $parentDir = $directory.Parent
    
    [string] $zipFileName
    
    If ($parentDir.FullName.EndsWith("\") -eq $true)
    {
        # e.g. $parentDir = "C:\"
        $zipFileName = $parentDir.FullName + $directory.Name + ".zip"
    }
    Else
    {
        $zipFileName = $parentDir.FullName + "\" + $directory.Name + ".zip"
    }
        
    Set-Content $zipFileName ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
        
    $shellApp = New-Object -ComObject Shell.Application
    $zipFile = $shellApp.NameSpace($zipFileName)

    If ($zipFile -eq $null)
    {
        T -text "Failed to get zip file object."
    }
    
    [int] $expectedCount = (Get-ChildItem $directory -Force -Recurse).Count
    $expectedCount += 1 # account for the top-level folder
    
	T -text "Copying $expectedCount items into file $zipFileName..."
	
    $zipFile.CopyHere($directory.FullName)

    # wait for CopyHere operation to complete
    WaitForZipOperationToFinish $zipFile $expectedCount
    
    T -text "Successfully created zip file for folder ($backupFullName)."
}

## Powershell Script to Shutdown and Export Hyper-V 2008 R2 VMs, one at a time.   
## Written by Stan Czerno
## http://www.czerno.com/default.asp?inc=/html/windows/hyperv/cluster/HyperV_Export_VMs.asp
## I have modified his approach to suit our purposes
Function ExportMyVms
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
        [string]$Destination,
		[string[]]$VMNames,
		[string]$VMHost
	)
	process
	{		
		## The script requires the PowerShell Management Library for Hyper-V for it to work. 

		## The PowerShell Management Library for Hyper-V can be downloaded at http://pshyperv.codeplex.com/
		## Be sure to read the documentation before using:
		## http://pshyperv.codeplex.com/releases/view/62842
		## http://pshyperv.codeplex.com/releases/view/38769

		## This is how I backup the VMs on my Two-Node Hyper-V Cluster. I can afford for my servers to be down while this is done and
		## some of my other resources are clustered so there is minimum down time.

		## I also do System State Backups, Exchange Backups and SQL Backups in addition.

		## This script can be used on a Stand-Alone Hyper-V Server as well.

		## Let me know if you have a better way of doing this as I am not a very good developer and new to Powershell.

		## Get a list of all VMs on Node
		if ($VMNames)
		{
			if (($VMNames.Length) -gt 1)
			{
				# pass in a multiple-element string array directly
				$VMs = Get-VM -Name $VMNames -Server $VMHost
			}
			else
			{
				# turn a single-element string array back into a string
				$VMNames = [string]$VMNames
				$VMs = Get-VM -Name "$VMNames" -Server $VMHost
			}
		}
		else
		{
			$VMs = Get-VM -Server $VMHost
		}
		
		## only run through the list if there's anything in it
		if ($VMs)
		{
			foreach ($VM in @($VMs))
			{
				$listOfVmNames += $VM.ElementName + ", "
			}
			$listOfVmNames = $listOfVmNames -replace "..$"
			T -text "Attempting to backup the following VMs:"
			T -text "$listOfVmNames"
			T -text ""
			Write-Host "Do not cancel the export process as it may cause unpredictable VM behavior" -ForegroundColor Yellow
			
			## For each VM on Node, Save (if necessary), Export and Restore (if necessary)
			foreach ($VM in @($VMs))
			{
				$VMName = $VM.ElementName
				$summofvm = get-vmsummary $VMName
				$summhb = $summofvm.heartbeat
				$summes = $summofvm.enabledstate
				$restartWhenDone = $false
				
				$doexport = "no"
				
				## Shutdown the VM if HeartBeat Service responds
				if ($summhb -eq "OK")
				{
					$doexport = "yes"
					T -text ""
					T -text "HeartBeat Service for $VMName is responding $summhb, saving the machine state"
					$restartWhenDone = $true
					
					Save-VM -VM $VMName -Server $VMHost -Force -Wait
				}
				## Checks to see if the VM is already stopped
				elseif (($summes -eq "Stopped") -or ($summes -eq "Suspended"))
				{
					$doexport = "yes"
					T -text ""
					T -text "$VMName is $summes, starting export"
				}
				
				## If the HeartBeat service is not OK, aborting this VM
				elseif ($summhb -ne "OK" -and $summes -ne "Stopped")
				{
					$doexport = "no"
					T -text
					T -text "HeartBeat Service for $VMName is responding $summhb. Save state and export aborted for $VMName"
				}
				
				$i = 1
				if ($doexport -eq "yes")
				{
					$VMState = get-vmsummary $VMName
					$VMEnabledState = $VMState.enabledstate
					
					if ($VMEnabledState -eq "Suspended" -or $VMEnabledState -eq "Stopped")
					{
						## If a folder already exists for the current VM, delete it.
						if ([IO.Directory]::Exists("$($Destination)\$($VMName)"))
						{
							[IO.Directory]::Delete("$($Destination)\$($VMName)", $True)
						}
						T -text "Exporting $VMName"
						
						## Begin export of the VM
						export-vm -VM $VMName -Server $VMHost -path $Destination -CopyState -Wait -Force -ErrorAction SilentlyContinue
						
						## check to ensure the export succeeded
						$exportedCount = (Get-ChildItem $Destination -Force -Recurse).Count
						
						## there should be way more than 5 elements in the destination - this is to account for empty folders
						if ($exportedCount -lt 5)
						{
					        T -text "***** Automated export failed for $VMName *****"
					        T -text "***** Manual export advised *****"
						}
						
						if ($restartWhenDone)
						{
							T -text "Restarting $VMName..."
							
							## Start the VM and wait for a Heartbeat with a 5 minute time-out
							Start-VM $VMName -HeartBeatTimeOut 300 -Wait
						}
					}
					else
					{
						T -text "Could not properly save state on VM $VMName, skipping this one and moving on."
					}
				}
			}
		}
		else
		{
			T -text "No VMs found to back up."
		}
	}
}

## This is just a hand-made wrapper function that mimics the Tee-Object cmdlet with less fuss
## Plus, it makes our log file prettier
Function T
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
        [string]$text
	)
	process
	{
		Write-Host "$text"
		$now = date
		$text = "$now`t: $text"
		Add-content -LiteralPath $Logfile -value $text
	}
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/qJ7HMiR1FlfQK4LRmDWuf4A
# fA2gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJkr4OGO8CPPLeLG
# kAXDSukM+N7YMA0GCSqGSIb3DQEBAQUABIIBAESknXR2yaE5BZVrlgHHhzRv8lPu
# /30BzCZDyb3THS9WZRiHBxmImfKvFXqsTe98hjMhNq6NTEbGpZq+u8GZ9z3oyQ36
# ol+PtIUHUgg36x+l32KWtv9rGsgV8Srb9BHCx1ZXeJkksc9at3MmneFUFfYm5YyZ
# KewtbNLLW2l67pt/baXvrriP+l/kwcth7zZy5c75gQesnTd350Qrw1C8yqdJiXWm
# sVkU5YpIff/FnroUnaXJbAHPIXxT2SA1nPYwlDIhA7SiKEOnpG8Ql67SLPJUuIct
# 8GauD2FGXulB+9IWIc4t+94mf793MWTRAqcDg6+OnbiCGZmfytNrQ8hA0xk=
# SIG # End signature block
