#region GET FUNCTION

function Get-TargetResource {
[CmdletBinding()]
[OutputType([Hashtable])]
param (
[Parameter(Mandatory)][string]$AffinityGroup,
[Parameter(Mandatory)][string]$StorageAccountName,
[string]$Container,
[string]$Folder,
[string]$Label
)
    $CurrentSubscription = Get-AzureSubscription -Current
    $CurrentSubscription.CurrentStorageAccountName = $StorageAccountName
    Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
    Write-Verbose "The Azure storage account is $($CurrentSubscription.CurrentStorageAccountName)"

    # Native Get cmdlet
    $Get = Get-AzureStorageAccount -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue
    if ($Get -ne $null -AND $Container -ne '') {
        $StorageKey = Get-AzureStorageKey -StorageAccountName $StorageAccountName
        $AzureStorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageKey.Primary -Protocol Https
        
        $GetContainer = Get-AzureStorageContainer -Name $Container -Context $AzureStorageContext -ErrorAction SilentlyContinue | % Name
        
        if ($Folder){
            $GetFolder = Get-Item $Folder -ErrorAction SilentlyContinue | % FullName
            }
        }

    # Build Hashtable from cmdlet values
    @{
        'Ensure' = If ($Get.StorageAccountName -eq $StorageAccountName) {'Present'} Else {'Absent'}
        'AffinityGroup' = $Get.AffinityGroup
        'StorageAccountName' = $Get.StorageAccountName
        'Container' = $GetContainer
        'Folder' = $GetFolder
        'Label' = $Get.Label
    }

 }

#  Get-TargetResource 'TestVMWestUS1' 'testvmstorage1' -Container 'scriptextensionfiles' -folder 'c:\Azure\scriptextensionfiles' -Verbose
#  Expectation is a hashtable with properties of the storage account, if it exists.

#endregion



#region SET FUNCTION

function Set-TargetResource {
[CmdletBinding()]
param(
[ValidateSet('Present','Absent')]
[string]$Ensure = 'Present',
[Parameter(Mandatory)][string]$AffinityGroup,
[Parameter(Mandatory)][string]$StorageAccountName,
[string]$Container,
[string]$Folder,
[string]$Label
)

    switch ($Ensure) {
        'Present' {
            # Native Test for name conflict
            $CurrentSubscription = Get-AzureSubscription -Current
            Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
            $TestAzureStorageName = Test-AzureName -Name $StorageAccountName -Storage

            # Test storage account name for Azure requirements, lowercase, no special characters, and between 3 and 24 characters
            $AzureStorageNameRequirements = ($StorageAccountName -cmatch ‘^[a-z\d]+$’)
            if ($AzureStorageNameRequirements -eq $False) {
                Write-Error 'The Storage Account Name does not meet requirements of 3-24 characters, lower case letters, and numbers.'
                }

            # Validate whether New or Set is required
            $Get = Get-TargetResource -AffinityGroup $AffinityGroup -StorageAccountName $StorageAccountName -Container $Container -Folder $Folder -Label $Label -ErrorAction SilentlyContinue 

            if ($Get.StorageAccountName -eq $StorageAccountName) {
                # Storage already exists.  Verify Configuration with native Set cmdlet
                $CurrentSubscription = Get-AzureSubscription -Current
                Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                Set-AzureStorageAccount -StorageAccountName $StorageAccountName -Label $Label
                
                # Assign current storage account name
                Set-AzureSubscription -SubscriptionName $CurrentSubscription.SubscriptionName -CurrentStorageAccountName $StorageAccountName
                $CurrentSubscription = Get-AzureSubscription -Current
                Write-verbose "Azure Storage Account Name: $($CurrentSubscription.CurrentStorageAccountName)"
                
                # Create Storage Context
                $StorageKey = Get-AzureStorageKey -StorageAccountName $StorageAccountName
                $AzureStorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageKey.Primary

                # If Container does not exist, re-create it
                if ($Get.Container -notcontains $Container) {
                    Write-Verbose "Creating container: $Container"
                    New-AzureStorageContainer -Name $Container -Context $AzureStorageContext
                    }

                # If files should be uploaded and are newer locally, update files
                if ($Folder) {
                    foreach ($File in (Get-ChildItem -Path $Folder)) {
                        $Blob = Get-AzureStorageBlob -Context $AzureStorageContext -Container $Container -Blob $File.Name -ErrorAction SilentlyContinue
                        if (!$Blob -OR $File.LastWriteTime -gt $Blob.LastModified.DateTime) {
                            Write-Verbose "Uploading file: $($File.FUllName)"
                            Set-AzureStorageBlobContent -Context $AzureStorageContext -Container $Container -File $File.FullName -Force
                            }
                        }
                    }
                }
            else {
                # Creating storage account using native New cmdlet
                if ($TestAzureStorageName -eq $False){
                    Write-Verbose "Creating Storage Account `"$StorageAccountName`" in Microsoft Azure."
                    Write-Verbose 'Please be patient as the operation completes.'
                    $CurrentSubscription = Get-AzureSubscription -Current
                    Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                    New-AzureStorageAccount -StorageAccountName $StorageAccountName -Label $Label -AffinityGroup $AffinityGroup
                    
                    # Assign current storage account name
                    Set-AzureSubscription -SubscriptionName $CurrentSubscription.SubscriptionName -CurrentStorageAccountName $StorageAccountName
                    $CurrentSubscription = Get-AzureSubscription -Current
                    Write-verbose "Azure Storage Account Name: $($CurrentSubscription.CurrentStorageAccountName)"

                    # Wait for creation to finish
                    $Status = (Get-AzureStorageAccount -StorageAccountName $StorageAccountName).StorageAccountStatus
                    While ($Status -ne 'Created') {
                        start-sleep 3
                        $Status = (Get-AzureStorageAccount -StorageAccountName $StorageAccountName).StorageAccountStatus
                        }

                    # Create Storage Context
                    $StorageKey = Get-AzureStorageKey -StorageAccountName $StorageAccountName
                    $AzureStorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageKey.Primary

                    # Create container
                    Write-Verbose "Creating container: $Container"
                    New-AzureStorageContainer -Name $Container -Context $AzureStorageContext
                    
                    # Upload files if needed
                    if ($Folder) {
                        foreach ($File in (Get-ChildItem -Path $Folder)) {
                            Write-Verbose "Uploading file: $File"
                            Set-AzureStorageBlobContent -Context $AzureStorageContext -Container $Container -File $File.FullName -Force
                            }
                        }

                  if ($TestAzureStorageName -ne $False) {
                        # Test failed due to conflict or the name was invalid
                        Write-Error "Unable to create Storage Account, the name `"$StorageAccountName`" is invalid or already in use"
                        }
                }
            }
        }

        'Absent' {
            $CurrentSubscription = Get-AzureSubscription -Current
            Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                               
            # Create Storage Context
            $StorageKey = Get-AzureStorageKey -StorageAccountName $StorageAccountName
            $AzureStorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageKey.Primary -Protocol Https

            # Remove each item in containers
            $Containers = Get-AzureStorageContainer -Context $AzureStorageContext
            foreach ($ContainerItem in $Containers) {
                Write-Verbose "Removing Container `"$($ContainerItem.Name)`""
                $LeaseStatus = $ContainerItem.CloudBlobContainer.Properties.LeaseStatus
                #Wait for Remove operation to complete
                While ($LeaseStatus -eq 'Locked') {
                    Start-Sleep 5
                    $LeaseStatus = (Get-AzureStorageContainer -Name $ContainerItem.Name -Context $AzureStorageContext).CloudBlobContainer.Properties.LeaseStatus
                    }
                # Remove containers
                Remove-AzureStorageContainer -Context $AzureStorageContext -Name $ContainerItem.Name -Force
                }
            # Remove Storage Account
            Remove-AzureStorageAccount -StorageAccountName $StorageAccountName
            }
        }
    }

#  Set-TargetResource 'Present' 'TestVMWestUS1' 'testvmstorage1' -Container 'scriptextensionfiles' -folder 'c:\Azure\scriptextensionfiles' -Verbose
#  Expectation is the storage account will be created, set, or removed.  Validate using Get-AzureStorageAccount.

#endregion



#region TEST FUNCTION

function Test-TargetResource {
[CmdletBinding()]
[OutputType([Boolean])]
param(
[ValidateSet('Present','Absent')]
[string]$Ensure = 'Present',
[Parameter(Mandatory)][string]$AffinityGroup,
[Parameter(Mandatory)][string]$StorageAccountName,
[string]$Container,
[string]$Folder,
[string]$Label
)
    # Output from Get-TargetResource
    $Get = Get-TargetResource -AffinityGroup $AffinityGroup -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue 

    $CurrentAccountSet = (Get-AzureSubscription -Current).CurrentStorageAccountName -eq $StorageAccountName

    # Compare dictionary and hash table
    switch ($Ensure) {
        'Present'{
            $bool = $true
            $bool = $CurrentAccountSet
            }
        'Absent'{
            $bool = $false
            $bool = !$CurrentAccountSet
            }
        }

    @('AffinityGroup','StorageAccountName','Container','Folder','Local') | % {
    if ($PSBoundParameters[$_] -ne $Get[$_]) {
            switch ($Ensure) {
                'Present'{$bool = $false}
                'Absent'{$bool = $true}
                }
            write-verbose "$($_): $($PSBoundParameters[$_]) -ne `"$($Get[$_])`""
            }
        }

    $bool
    }

#  Test-TargetResource 'Present' 'TestVMWestUS1' 'testvmstorage1' -Container 'scriptextensionfiles' -folder 'c:\Azure\scriptextensionfiles' -Verbose
#  Expectation is True or False based on whether the storage account has been deployed, depending on Present/Absent.

#endregion

Export-ModuleMember -function *-TargetResource