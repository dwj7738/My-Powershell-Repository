#region GET FUNCTION

function Get-TargetResource {
[CmdletBinding()]
[OutputType([Hashtable])]
param (
[Parameter(Mandatory)][string]$VMName,
[Parameter(Mandatory)][string]$ServiceName,
[Parameter(Mandatory)][string]$ConfigurationArchive,
[Parameter(Mandatory)][string]$StorageAccountName
)

    $CurrentSubscription = Get-AzureSubscription -Current
    $VM = Get-AzureVM -ServiceName $ServiceName -Name $VMName
    $AgentDSCStatus = ($VM.ResourceExtensionStatusList | Where {$_.HandlerName -eq 'Microsoft.PowerShell.DSC'})
    $DscExtensionStatus = $VM | Get-AzureVMDscExtension -ErrorAction SilentlyContinue
    
    # Returning StorageAccountName input for troubleshooting purposes
    return @{
        VMName = $VM.Name
        ServiceName = $VM.ServiceName
        ConfigurationArchive = $DscExtensionStatus.ModulesUrl
        StorageAccountName = $StorageAccountName
        Version = $AgentDSCStatus.Version
        Timestamp = $AgentDSCStatus.ExtensionSettingStatus.TimestampUtc
        Status = $AgentDSCStatus.ExtensionSettingStatus.Status
        Code = $AgentDSCStatus.ExtensionSettingStatus.Code
        Message = $AgentDSCStatus.ExtensionSettingStatus.FormattedMessage.Message
        }

    }

#  Expectation is a hashtable with properties of the DSC Extension, if it exists.

#endregion



#region SET FUNCTION

function Set-TargetResource {
[CmdletBinding()]
param(
[Parameter(Mandatory)][string]$VMName,
[Parameter(Mandatory)][string]$ServiceName,
[Parameter(Mandatory)][string]$ConfigurationArchive,
[Parameter(Mandatory)][string]$StorageAccountName,
[Microsoft.Management.Infrastructure.CimInstance[]]$ConfigurationArgument,
[string]$ConfigurationDataPath,
[string]$Configuration,
[string]$ContainerName,
[bool]$Force,
[string]$ReferenceName,
[string]$StorageEndpointSuffix,
[string]$Version
)

    $CurrentSubscription = Get-AzureSubscription -Current
    $StorageKey = Get-AzureStorageKey -StorageAccountName $StorageAccountName
    $AzureStorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageKey.Primary -Protocol https

    $ExtensionParams = $PSBoundParameters
    $ExtensionParams.Add('ConfigurationName',$Configuration)
    If ($ConfigurationArgument) {$ExensionParams.ConfigurationArgument = Convert-KeyValuePairArrayToHashtable $ConfigurationArgument}
    $ExtensionParams.Add('StorageContext',$AzureStorageContext)
    $ExtensionParams.Remove('Configuration')
    $ExtensionParams.Remove('StorageAccountName')
    $ExtensionParams.Remove('VMName')
    $ExtensionParams.Remove('ServiceName')

    Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
    Write-Verbose "The Azure storage context is $AzureStorageContext"
    
    $VM = Get-AzureVM -ServiceName $ServiceName -Name $VMName

    Try {
        $VM | Set-AzureVMDscExtension @ExtensionParams
        }
    Catch {
        throw "Setting the DSC Extension failed with error: $_"
        }
    
    $VM | Update-AzureVM
    }
  
#  Expectation is the DSC script will be executed on the target VM

#endregion



#region TEST FUNCTION

function Test-TargetResource {
[CmdletBinding()]
[OutputType([Boolean])]
param(
[Parameter(Mandatory)][string]$VMName,
[Parameter(Mandatory)][string]$ServiceName,
[Parameter(Mandatory)][string]$ConfigurationArchive,
[Parameter(Mandatory)][string]$StorageAccountName,
[Microsoft.Management.Infrastructure.CimInstance[]]$ConfigurationArgument,
[string]$ConfigurationDataPath,
[string]$Configuration,
[string]$ContainerName,
[bool]$Force,
[string]$ReferenceName,
[string]$StorageEndpointSuffix,
[string]$Version
)

    $Get = Get-TargetResource -VMName $VMName -ServiceName $ServiceName -ConfigurationArchive $ConfigurationArchive -StorageAccountName $StorageAccountName
    
    if ($Get.ConfigurationArchive) { 
        $Archive = $Get.ConfigurationArchive.Split('/')[$Get.ConfigurationArchive.Split('/').count-1]
        }
    
    if ($Archive -eq $ConfigurationArchive -AND $Get.Status -eq 'Success') {
        Write-Verbose 'The DSC configuration is already applied to the VM.'
        return $true
        }

    write-verbose 'The VM does not have the DSC Extension enabled.'
    return $false
    }

#  Expectation is True or False based on whether the VM has been deployed, depending on Present/Absent.

#endregion



#region HELPER FUNCTIONS

# Converts CimInstance array of type KeyValuePair to hashtable
function Convert-KeyValuePairArrayToHashtable
{
param (
    [parameter(Mandatory = $true)]
    [Microsoft.Management.Infrastructure.CimInstance[]]
    $array
)

    $hashtable = @{}
    foreach($item in $array)
    {
        $hashtable += @{$item.Key = $item.Value}
    }

    return $hashtable
    }

#endregion


Export-ModuleMember -function *-TargetResource