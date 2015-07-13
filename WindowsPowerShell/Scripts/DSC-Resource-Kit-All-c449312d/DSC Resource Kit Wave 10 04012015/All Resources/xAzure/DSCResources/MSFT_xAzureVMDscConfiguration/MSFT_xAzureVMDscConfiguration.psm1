# Purpose:
# Resource to Publish a Dsc Configuration archive to Azure storage

#region GET

function Get-TargetResource {
[CmdletBinding()]
[OutputType([Hashtable])]
param(

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,

    [string]$ContainerName = 'windows-powershell-dsc',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigurationPath,

    [ValidateNotNullOrEmpty()]
    [string]$AzureSubscriptionName,

    [ValidateNotNullOrEmpty()]
    [string]$AzurePublishSettingsPath

) 

    if ($AzureSubscriptionName -and $AzurePublishSettingsPath)
    {
        Write-Verbose "Azure Publish Settings provided. AzureSubscriptionName = $AzureSubscriptionName,  AzurePublishSettingsPath = $AzurePublishSettingsPath"
        Import-AzurePublishSettingsFile $AzurePublishSettingsPath
        Set-AzureSubscription -SubscriptionName $AzureSubscriptionName
    }

    Write-Verbose "Storage Account Name = $StorageAccountName"
    $storageAccountKey = (Get-AzureStorageKey $StorageAccountName).Primary
    $Script:StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKey -Protocol https

    Write-Verbose "ConfigurationPath = $ConfigurationPath"
    $Script:ConfigFileName = [IO.Path]::GetFileName($ConfigurationPath)
    
    $storageBlobArchive = Get-AzureStorageBlob -Blob "$Script:ConfigFileName.zip" -Container $ContainerName -Context  $Script:StorageContext -ErrorAction SilentlyContinue
    $blobUri = $($storageBlobArchive.ICloudBlob.Uri.AbsoluteUri)

    Write-Verbose "Blob Uri is $blobUri"

    $returnValue = @{
		BlobUri = $blobUri
	    }

	return $returnValue    

    }

#endregion


#region SET

function Set-TargetResource {
[CmdletBinding()]
param(

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,

    [ValidateSet('Present','Absent')]
    [string]$Ensure = 'Present',

    [string]$ContainerName = 'windows-powershell-dsc',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigurationPath,

    [ValidateNotNullOrEmpty()]
    [string]$AzureSubscriptionName,

    [ValidateNotNullOrEmpty()]
    [string]$AzurePublishSettingsPath

)

    switch ($Ensure) {
        'Present'
            {   
                Write-Verbose "Ensure is set to $Ensure. Calling Publish-AzureVMDscConfiguration to create the Configuration and Resource archive in Storage `"$($Script:StorageContext.StorageAccountName)`""
                Publish-AzureVMDscConfiguration -ConfigurationPath $ConfigurationPath -StorageContext $Script:StorageContext -Force -Verbose
            }
    
        'Absent'
            {   
                Write-Verbose "Ensure is set to $Ensure. Calling Remove-AzureStorageBlob to remove the Blob from Storage `"$($Script:StorageContext.StorageAccountName)`""
                Remove-AzureStorageBlob -Blob "$Script:ConfigFileName.zip" -Container $ContainerName -Force
            }
        }   

    }
  
#endregion


#region TEST

function Test-TargetResource {
[CmdletBinding()]
[OutputType([Boolean])]
param(

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,

    [ValidateSet('Present','Absent')]
    [string]$Ensure = 'Present',

    [string]$ContainerName = 'windows-powershell-dsc',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigurationPath,

    [ValidateNotNullOrEmpty()]
    [string]$AzureSubscriptionName,

    [ValidateNotNullOrEmpty()]
    [string]$AzurePublishSettingsPath

)
    Write-Verbose "Invoke Get-TargetResource to obtain the Absolute Uri to the Blob"
    $parameters = @{}
    $parameters["StorageAccountName"] = $StorageAccountName
    $parameters["ContainerName"] = $ContainerName
    $parameters["ConfigurationPath"] = $ConfigurationPath
    
    if($AzureSubscriptionName)
    {
        $parameters["AzureSubscriptionName"] = $AzureSubscriptionName
    }

    if($AzurePublishSettingsPath)
    {
        $parameters["AzurePublishSettingsPath"] = $AzurePublishSettingsPath
    }

    $blobUriObj = Get-TargetResource @parameters
    
    switch ($Ensure) {
        'Present'
            {  
                if (-not $($blobUriObj.BlobUri))
                {
                    Write-Verbose "Ensure is set to $Ensure. But the archive is absent in Storage. We need to Publish the archive to Storage"
                    return $false
                }
            }
        'Absent'
            {  
                if ($($blobUriObj.BlobUri))
                {
                    Write-Verbose "Ensure is set to $Ensure. But the archive is present in Storage. We need to Remove the archive from Storage"
                    return $false
                }
            }
        }

    return $true
   
    }

#endregion


Export-ModuleMember -function *-TargetResource