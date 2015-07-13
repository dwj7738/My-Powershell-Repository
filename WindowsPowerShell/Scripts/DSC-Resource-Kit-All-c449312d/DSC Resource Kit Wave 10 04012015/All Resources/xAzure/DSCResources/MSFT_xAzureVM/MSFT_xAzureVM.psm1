#region GET FUNCTION

function Get-TargetResource {
[CmdletBinding()]
[OutputType([Hashtable])]
param (
[Parameter(Mandatory)][string]$Name,
[Parameter(Mandatory)][string]$ImageName,
[Parameter(Mandatory)][string]$ServiceName,
[Parameter(Mandatory)][string]$StorageAccountName
)
    $CurrentSubscription = Get-AzureSubscription -Current
    Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
   
    # Native Get cmdlet
    $Get = Get-AzureVM -Name $Name -ServiceName $ServiceName

    # Build Hashtable from native cmdlet values
    @{
        'Ensure' = If ($Get.Name -eq $Name) {'Present'} Else {'Absent'}
        'Name' = $Get.Name
        'ServiceName' = $Get.ServiceName
     }

    }

#  Get-TargetResource -Name 'TestVM1' -ServiceName 'testvmservice1' -storageaccountname 'testvmstorage1' -ImageName 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201404.01-en.us-127GB.vhd' -Verbose
#  Expectation is a hashtable with properties of the VM, if it exists.

#endregion



#region SET FUNCTION

function Set-TargetResource {
[CmdletBinding()]
param(
[ValidateSet('Present','Absent')]
[string]$Ensure = 'Present',
[Parameter(Mandatory)][string]$Name,
[Parameter(Mandatory)][string]$ImageName,
[Parameter(Mandatory)][string]$ServiceName,
[Parameter(Mandatory)][string]$StorageAccountName,
[string]$InstanceSize = 'Medium',
[bool]$Linux,
[bool]$Windows,
[pscredential]$Credential,
[string]$ExtensionContainerName,
[string]$ExtensionFileList,
[string]$ExtensionScriptName
)
    # Removing parameters from output
    $PSBoundParameters.Remove('Ensure') | out-null
    $PSBoundParameters.Remove('Debug') | out-null
    $PSBoundParameters.Remove('ErrorAction') | out-null

    switch ($Ensure) {
        'Present' {
            Write-Verbose "Creating VM `"$Name`" in Microsoft Azure."
            Write-Verbose 'Please be patient as the operation completes.'

            # Create VM COnfig
            $VM = New-AzureVMConfig -Name $Name -InstanceSize $InstanceSize -ImageName $ImageName -MediaLocation "http://$StorageAccountName.blob.core.windows.net/vhds/$Name.vhd"
            
            # Set OS Switch
            if ($Windows -eq $true) {Add-AzureProvisioningConfig -VM $VM -AdminUserName $Credential.UserName –Password $Credential.GetNetworkCredential().Password -Windows}
            else {Add-AzureProvisioningConfig -VM $VM -LinuxUser $Credential.UserName –Password $Credential.GetNetworkCredential().Password -Linux}

            if ($ExtensionContainerName -ne '') {
                # VM Agent
                $ExtensionFileList = $ExtensionFileList.Split(',')
                Set-AzureVMCustomScriptExtension -ContainerName $ExtensionContainerName -FileName $ExtensionFileList -VM $VM -Run $ExtensionScriptName
                }
            
            # Native cmdlet for new VM
            
            $CurrentSubscription = Get-AzureSubscription -Current
            $CurrentSubscription.CurrentStorageAccountName = $StorageAccountName
            Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
            Write-Verbose "The Azure storage account is $($CurrentSubscription.CurrentStorageAccountName)"

            New-AzureVM -VMs $VM –ServiceName $ServiceName
            }
        'Absent' {
            # Native Remove cmdlet
            Write-Verbose "Removing VM `"$Name`" from Azure."
            Write-Verbose 'Please be patient as the operation completes.'
            
            $CurrentSubscription = Get-AzureSubscription -Current
            Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
            Remove-AzureVM -Name $Name -ServiceName $ServiceName -DeleteVHD
            }
        }
    }
  
#  Set-TargetResource -Ensure 'Present' -Name 'TestVM1' -ServiceName 'testvmsservice1' -storageaccountname 'testvmstorage1' -ImageName 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201404.01-en.us-127GB.vhd' -windows $true -Verbose
#  Expectation is the VM will be created, set, or removed.  Validate using Get-AzureVM.

#endregion



#region TEST FUNCTION

function Test-TargetResource {
[CmdletBinding()]
[OutputType([Boolean])]
param(
[ValidateSet('Present','Absent')]
[string]$Ensure = 'Present',
[Parameter(Mandatory)][string]$Name,
[Parameter(Mandatory)][string]$ImageName,
[Parameter(Mandatory)][string]$ServiceName,
[Parameter(Mandatory)][string]$StorageAccountName,
[string]$InstanceSize,
[bool]$Linux,
[bool]$Windows,
[pscredential]$Credential,
[string]$ExtensionContainerName,
[string]$ExtensionFileList,
[string]$ExtensionScriptName
)
    # Output from Get-TargetResource
    $Get = Get-TargetResource -Name $Name -ServiceName $ServiceName -ImageName $ImageName -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue 

    switch ($Ensure) {
        'Present'{$bool = $true}
        'Absent'{$bool = $false}
        }

    if ($Name -ne $Get.Name -AND $ServiceName -ne $Get.ServiceName) {
        switch ($Ensure) {
            'Present'{$bool = $false}
            'Absent'{$bool = $true}
            }
        write-verbose 'The VM could not be found in Azure.'
        }

    $bool
    }

#  Test-TargetResource -Ensure 'Absent' -Name 'TestVM1' -ServiceName 'testvmservice1' -storageaccountname 'testvmstorage1' -ImageName 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201404.01-en.us-127GB.vhd' -windows $true -Verbose
#  Expectation is True or False based on whether the VM has been deployed, depending on Present/Absent.

#endregion

Export-ModuleMember -function *-TargetResource