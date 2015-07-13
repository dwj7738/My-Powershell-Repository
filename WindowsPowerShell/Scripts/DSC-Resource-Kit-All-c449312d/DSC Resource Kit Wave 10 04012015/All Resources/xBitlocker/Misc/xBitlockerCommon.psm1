#A common function used to enable Bitlocker on a disk.
function EnableBitlocker
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$MountPoint,

        [ValidateSet("PasswordProtector","RecoveryPasswordProtector","StartupKeyProtector","TpmProtector")]
		[parameter(Mandatory = $true)]
		[System.String]
		$PrimaryProtector,

		[System.String]
		$AdAccountOrGroup,

		[System.Boolean]
		$AdAccountOrGroupProtector,

		[System.Boolean]
		$AllowImmediateReboot = $false,

		[System.Boolean]
		$AutoUnlock = $false,

		[ValidateSet("Aes128","Aes256")]
		[System.String]
		$EncryptionMethod,

		[System.Boolean]
		$HardwareEncryption,

		[System.Management.Automation.PSCredential]
		$Password,

		[System.Boolean]
		$PasswordProtector,

		[System.Management.Automation.PSCredential]
		$Pin,

		[System.String]
		$RecoveryKeyPath,

		[System.Boolean]
		$RecoveryKeyProtector,

		[System.Boolean]
		$RecoveryPasswordProtector,

		[System.Boolean]
		$Service,

		[System.Boolean]
		$SkipHardwareTest,

		[System.String]
		$StartupKeyPath,

		[System.Boolean]
		$StartupKeyProtector,

		[System.Boolean]
		$TpmProtector,

		[System.Boolean]
		$UsedSpaceOnly,

        $VerbosePreference
	)

    Write-Verbose "Beginning processing of MountPoint: $($MountPoint)"

    $blv = Get-BitLockerVolume -MountPoint $MountPoint -ErrorAction SilentlyContinue

    if ($blv -ne $null)
    {
        if ($PSBoundParameters.ContainsKey("TpmProtector") -and $PrimaryProtector -ne "TpmProtector")
        {
            throw "If TpmProtector is used, it must be the PrimaryProtector."
        }

        if ($PSBoundParameters.ContainsKey("Pin") -and !($PSBoundParameters.ContainsKey("TpmProtector")))
        {
            throw "A TpmProtector must be used if Pin is used."
        }
    
        if ($PSBoundParameters.ContainsKey("AdAccountOrGroupProtector") -and $PrimaryProtector -notlike "AdAccountOrGroupProtector" -and !(ContainsKeyProtector -Type "AdAccountOrGroup" -KeyProtectorCollection $blv.KeyProtector))
        {
            Write-Verbose "Adding AdAccountOrGroupProtector"
            Add-BitLockerKeyProtector -MountPoint $MountPoint -AdAccountOrGroupProtector -AdAccountOrGroup $AdAccountOrGroup
        }

        if ($PSBoundParameters.ContainsKey("PasswordProtector") -and $PrimaryProtector -notlike "PasswordProtector" -and !(ContainsKeyProtector -Type "Password" -KeyProtectorCollection $blv.KeyProtector))
        {
            Write-Verbose "Adding PasswordProtector"
            Add-BitLockerKeyProtector -MountPoint $MountPoint -PasswordProtector -Password $Password.Password
        }

        if ($PSBoundParameters.ContainsKey("RecoveryKeyProtector") -and $PrimaryProtector -notlike "RecoveryKeyProtector" -and !(ContainsKeyProtector -Type "ExternalKey" -KeyProtectorCollection $blv.KeyProtector))
        {
            Write-Verbose "Adding RecoveryKeyProtector"
            Add-BitLockerKeyProtector -MountPoint $MountPoint -RecoveryKeyProtector -RecoveryKeyPath $RecoveryKeyPath
        }

        if ($PSBoundParameters.ContainsKey("RecoveryPasswordProtector") -and $PrimaryProtector -notlike "RecoveryPasswordProtector" -and !(ContainsKeyProtector -Type "RecoveryPassword" -KeyProtectorCollection $blv.KeyProtector))
        {
            Write-Verbose "Adding RecoveryPasswordProtector"
            Add-BitLockerKeyProtector -MountPoint $MountPoint -RecoveryPasswordProtector
        }

        if ($PSBoundParameters.ContainsKey("StartupKeyProtector") -and $PrimaryProtector -notlike "TpmProtector" -and $PrimaryProtector -notlike "StartupKeyProtector" -and !(ContainsKeyProtector -Type "ExternalKey" -KeyProtectorCollection $blv.KeyProtector))
        {
            Write-Verbose "Adding StartupKeyProtector"
            Add-BitLockerKeyProtector -MountPoint $MountPoint -StartupKeyProtector -StartupKeyPath $StartupKeyPath
        }

        if ($PSBoundParameters.ContainsKey("TpmProtector") -and $PrimaryProtector -notlike "TpmProtector" -and !(ContainsKeyProtector -Type "Tpm" -KeyProtectorCollection $blv.KeyProtector -StartsWith $true))
        {
            Write-Verbose "Adding TpmProtector"
            Add-BitLockerKeyProtector -MountPoint $MountPoint -TpmProtector $TpmProtector
        }

        #Now enable Bitlocker with the primary key protector
        if ($blv.VolumeStatus -eq "FullyDecrypted")
        {
            #First add non-key related parameters
            $params = @{}
            $params.Add("MountPoint", $MountPoint)

            if ($PSBoundParameters.ContainsKey("EncryptionMethod"))
            {
                $params.Add("EncryptionMethod", $EncryptionMethod)
            }

            if ($PSBoundParameters.ContainsKey("HardwareEncryption"))
            {
                $params.Add("HardwareEncryption", $true)
            }

            if ($PSBoundParameters.ContainsKey("Service"))
            {
                $params.Add("Service", $true)
            }

            if ($PSBoundParameters.ContainsKey("SkipHardwareTest"))
            {
                $params.Add("SkipHardwareTest", $true)
            }

            if ($PSBoundParameters.ContainsKey("UsedSpaceOnly"))
            {
                $params.Add("UsedSpaceOnly", $true)
            }

            #Now add the primary protector
            $handledTpmAlready = $false

            #Deal with a couple one off cases
            if ($PSBoundParameters.ContainsKey("Pin"))
            {
                $handledTpmAlready = $true

                $params.Add("Pin", $Pin.Password)
                
                if ($PSBoundParameters.ContainsKey("StartupKeyProtector"))
                {
                    $params.Add("TpmAndPinAndStartupKeyProtector", $true)
                    $params.Add("StartupKeyPath", $StartupKeyPath)
                }
                else
                {
                    $params.Add("TpmAndPinProtector", $true)
                }
            }

            if ($PSBoundParameters.ContainsKey("StartupKeyProtector") -and $PrimaryProtector -like "TpmProtector" -and $handledTpmAlready -eq $false)
            {
                $handledTpmAlready = $true

                $params.Add("TpmAndStartupKeyProtector", $true)
                $params.Add("StartupKeyPath", $StartupKeyPath)                
            }


            #Now deal with the standard primary protectors
            if ($PrimaryProtector -like "PasswordProtector")
            {
                $params.Add("PasswordProtector", $true)
                $params.Add("Password", $Password.Password)
            }
            elseif ($PrimaryProtector -like "RecoveryPasswordProtector")
            {
                $params.Add("RecoveryPasswordProtector", $true)
            }
            elseif ($PrimaryProtector -like "StartupKeyProtector")
            {
                $params.Add("StartupKeyProtector", $true)
                $params.Add("StartupKeyPath", $StartupKeyPath)
            }
            elseif ($PrimaryProtector -like "TpmProtector" -and $handledTpmAlready -eq $false)
            {
                $params.Add("TpmProtector", $true)
            }

            #Run Enable-Bitlocker
            Write-Verbose "Running Enable-Bitlocker"

            $newBlv = Enable-Bitlocker @params

            #Check if the Enable succeeded
            if ($newBlv -ne $null)
            {
                if ($blv.VolumeType -eq "OperatingSystem") #Only initiate reboot if this is an OS drive
                {
					$global:DSCMachineStatus = 1

                    if ($AllowImmediateReboot -eq $true)
                    {
                        Write-Verbose "Forcing an immediate reboot of the computer in 30 seconds"

						Start-Sleep -Seconds 30
                        Restart-Computer -Force
                    }
                }
            }
            else
            {
                throw "Failed to successfully enable Bitlocker on MountPoint $($MountPoint)"
            }

            #Finally, enable AutoUnlock if requested
            if ($AutoUnlock -eq $true -and $blv.VolumeType -ne "OperatingSystem")
            {
                Enable-BitlockerAutoUnlock -MountPoint $MountPoint
            }
        }
    }
    else
    {
        throw "Unable to find Bitlocker Volume associated with Mount Point '$($MountPoint)'"
    }
}

#A common function used to test if Bitlocker is enabled on a disk with the appropriate settings
function TestBitlocker
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$MountPoint,

        [ValidateSet("PasswordProtector","RecoveryPasswordProtector","StartupKeyProtector","TpmProtector")]
		[parameter(Mandatory = $true)]
		[System.String]
		$PrimaryProtector,

		[System.String]
		$AdAccountOrGroup,

		[System.Boolean]
		$AdAccountOrGroupProtector,

		[System.Boolean]
		$AllowImmediateReboot = $false,

		[System.Boolean]
		$AutoUnlock = $false,

		[ValidateSet("Aes128","Aes256")]
		[System.String]
		$EncryptionMethod,

		[System.Boolean]
		$HardwareEncryption,

		[System.Management.Automation.PSCredential]
		$Password,

		[System.Boolean]
		$PasswordProtector,

		[System.Management.Automation.PSCredential]
		$Pin,

		[System.String]
		$RecoveryKeyPath,

		[System.Boolean]
		$RecoveryKeyProtector,

		[System.Boolean]
		$RecoveryPasswordProtector,

		[System.Boolean]
		$Service,

		[System.Boolean]
		$SkipHardwareTest,

		[System.String]
		$StartupKeyPath,

		[System.Boolean]
		$StartupKeyProtector,

		[System.Boolean]
		$TpmProtector,

		[System.Boolean]
		$UsedSpaceOnly,

        $VerbosePreference
	)

	$blv = Get-BitLockerVolume -MountPoint $MountPoint -ErrorAction SilentlyContinue

    if ($blv -eq $null)
    {
        Write-Verbose "Unable to locate MountPoint: $($MountPoint)"
        return $false
    }
    elseif ($blv.KeyProtector -eq $null -or $blv.KeyProtector.Count -eq 0)
    {
        Write-Verbose "No key protectors on MountPoint: $($MountPoint)"
        return $false
    }
    elseif ($AutoUnlock -eq $true -and $blv.AutoUnlockEnabled -ne $true)
    {
        Write-Verbose "AutoUnlock is not enabled for MountPoint: $($MountPoint)"
        return $false
    }
    else
    {
        if ($PSBoundParameters.ContainsKey("AdAccountOrGroupProtector") -and !(ContainsKeyProtector -Type "AdAccountOrGroup" -KeyProtectorCollection $blv.KeyProtector))
        {
            Write-Verbose "MountPoint '$($MountPoint) 'does not have AdAccountOrGroupProtector (AdAccountOrGroup)"
            return $false
        }

        if ($PSBoundParameters.ContainsKey("PasswordProtector") -and !(ContainsKeyProtector -Type "Password" -KeyProtectorCollection $blv.KeyProtector))
        {
            Write-Verbose "MountPoint '$($MountPoint) 'does not have PasswordProtector (Password)"
            return $false
        }

        if ($PSBoundParameters.ContainsKey("Pin") -and !(ContainsKeyProtector -Type "TpmPin" -KeyProtectorCollection $blv.KeyProtector -StartsWith $true))
        {
            Write-Verbose "MountPoint '$($MountPoint) 'does not have TpmPin assigned."
            return $false            
        }

        if ($PSBoundParameters.ContainsKey("RecoveryKeyProtector") -and !(ContainsKeyProtector -Type "ExternalKey" -KeyProtectorCollection $blv.KeyProtector))
        {
            Write-Verbose "MountPoint '$($MountPoint) 'does not have RecoveryKeyProtector (ExternalKey)"
            return $false
        }

        if ($PSBoundParameters.ContainsKey("RecoveryPasswordProtector") -and !(ContainsKeyProtector -Type "RecoveryPassword" -KeyProtectorCollection $blv.KeyProtector))
        {
            Write-Verbose "MountPoint '$($MountPoint) 'does not have RecoveryPasswordProtector (RecoveryPassword)"
            return $false
        }

        if ($PSBoundParameters.ContainsKey("StartupKeyProtector"))
        {
            if ($PrimaryProtector -notlike "TpmProtector")
            {
                if (!(ContainsKeyProtector -Type "ExternalKey" -KeyProtectorCollection $blv.KeyProtector))
                {
                    Write-Verbose "MountPoint '$($MountPoint) 'does not have StartupKeyProtector (ExternalKey)"
                    return $false
                }
            }
            else #TpmProtector is primary
            {
                if(!(ContainsKeyProtector -Type "Tpm" -KeyProtectorCollection $blv.KeyProtector -StartsWith $true) -and !(ContainsKeyProtector -Type "StartupKey" -KeyProtectorCollection $blv.KeyProtector -Contains $true))
                {
                    Write-Verbose "MountPoint '$($MountPoint) 'does not have TPM + StartupKey protector."
                    return $false
                }          
            }
        }

        if ($PSBoundParameters.ContainsKey("TpmProtector") -and !(ContainsKeyProtector -Type "Tpm" -KeyProtectorCollection $blv.KeyProtector -StartsWith $true))
        {
            Write-Verbose "MountPoint '$($MountPoint) 'does not have TpmProtector"
            return $false
        }
    }

    return $true
}

#Ensures that required Bitlocker prereqs are installed 
function CheckForPreReqs
{
    $hasAllPreReqs = $true

    $blFeature = Get-WindowsFeature BitLocker
    $blAdminToolsFeature = Get-WindowsFeature RSAT-Feature-Tools-BitLocker
    $blAdminToolsRemoteFeature = Get-WindowsFeature RSAT-Feature-Tools-BitLocker-RemoteAdminTool

    if ($blFeature.InstallState -ne "Installed")
    {
        $hasAllPreReqs = $false

        Write-Error "The Bitlocker feature needs to be installed before the xBitlocker module can be used"
    }

    if ($blAdminToolsFeature.InstallState -ne "Installed")
    {
        $hasAllPreReqs = $false

        Write-Error "The RSAT-Feature-Tools-BitLocker feature needs to be installed before the xBitlocker module can be used"
    }

    if ($blAdminToolsRemoteFeature.InstallState -ne "Installed")
    {
        $hasAllPreReqs = $false

        Write-Error "The RSAT-Feature-Tools-BitLocker-RemoteAdminTool feature needs to be installed before the xBitlocker module can be used"
    }

    if ($hasAllPreReqs -eq $false)
    {
        throw "Required Bitlocker features need to be installed before xBitlocker can be used"
    }
}

#Checks whether the KeyProtectorCollection returned from Get-BitlockerVolume contains the specified key protector type
function ContainsKeyProtector
{
    param([string]$Type, $KeyProtectorCollection, [bool]$StartsWith = $false, [bool]$EndsWith = $false, [bool]$Contains = $false)

    if ($KeyProtectorCollection -ne $null)
    {
        foreach ($keyProtector in $KeyProtectorCollection)
        {
            if ($keyProtector.KeyProtectorType -eq $Type)
            {
                return $true
            }
            elseif ($StartsWith -eq $true -and $keyProtector.KeyProtectorType.ToString().StartsWith($Type))
            {
                return $true
            }
            elseif ($EndsWith -eq $true -and $keyProtector.KeyProtectorType.ToString().EndsWith($Type))
            {
                return $true
            }
            elseif ($Contains -eq $true -and $keyProtector.KeyProtectorType.ToString().Contains($Type))
            {
                return $true
            }
        }
    }

    return $false
}

#Takes $PSBoundParameters from another function and adds in the keys and values from the given Hashtable
function AddParameters
{
    param($PSBoundParametersIn, [Hashtable]$ParamsToAdd)

    foreach ($key in $ParamsToAdd.Keys)
    {
        if (!($PSBoundParametersIn.ContainsKey($key))) #Key doesn't exist, so add it with value
        {
            $PSBoundParametersIn.Add($key, $ParamsToAdd[$key]) | Out-Null
        }
        else #Key already exists, so just replace the value
        {
            $PSBoundParametersIn[$key] = $ParamsToAdd[$key]
        }
    }
}

#Takes $PSBoundParameters from another function. If ParamsToRemove is specified, it will remove each param.
#If ParamsToKeep is specified, everything but those params will be removed. If both ParamsToRemove and ParamsToKeep
#are specified, only ParamsToKeep will be used.
function RemoveParameters
{
    param($PSBoundParametersIn, [string[]]$ParamsToKeep, [string[]]$ParamsToRemove)

    if ($ParamsToKeep -ne $null -and $ParamsToKeep.Count -gt 0)
    {
        [string[]]$ParamsToRemove = @()

        $lowerParamsToKeep = StringArrayToLower -Array $ParamsToKeep

        foreach ($key in $PSBoundParametersIn.Keys)
        {
            if (!($lowerParamsToKeep.Contains($key.ToLower())))
            {
                $ParamsToRemove += $key
            }
        }
    }

    if ($ParamsToRemove -ne $null -and $ParamsToRemove.Count -gt 0)
    {
        foreach ($param in $ParamsToRemove)
        {
            $PSBoundParametersIn.Remove($param) | Out-Null
        }
    }
}

Export-ModuleMember -Function *