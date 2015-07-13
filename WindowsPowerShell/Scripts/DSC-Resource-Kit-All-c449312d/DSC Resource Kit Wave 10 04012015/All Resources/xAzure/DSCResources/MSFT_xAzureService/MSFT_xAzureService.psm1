#region GET FUNCTION

function Get-TargetResource {
[CmdletBinding()]
[OutputType([HashTable])]
param (
[ValidateSet('Present','Absent')]
[string]$Ensure = 'Present',
[Parameter(Mandatory)][string]$AffinityGroup,
[Parameter(Mandatory)][string]$ServiceName,
[string]$Description,
[string]$Label
)
    $CurrentSubscription = Get-AzureSubscription -Current
    Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"

    # Native Get cmdlet
    $Get = Get-AzureService $ServiceName -ErrorAction SilentlyContinue

    # Build Hashtable from native cmdlet values
    @{
        'Ensure' = If ($Get.ServiceName -eq $ServiceName) {'Present'} Else {'Absent'}
        'AffinityGroup' = $Get.AffinityGroup
        'ServiceName' = $Get.ServiceName
        'Description' = $Get.Description
        'Label' = $Get.Label
    }

    }

#  Get-TargetResource 'Present' 'TestVMsWestUS1' 'testvmsservice1' 'Test Service created for Test Virtual Machines 1' 'Test VMs Service 1' -Verbose
#  Expectation is a hashtable with properties of the service, if it exists.

#endregion



#region SET FUNCTION

function Set-TargetResource {
[CmdletBinding()]
param(
[ValidateSet('Present','Absent')]
[string]$Ensure = 'Present',
[Parameter(Mandatory)][string]$AffinityGroup,
[Parameter(Mandatory)][string]$ServiceName,
[string]$Description,
[string]$Label
)
    $CurrentSubscription = Get-AzureSubscription -Current
    Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"

    # Removing parameters from output
    $PSBoundParameters.Remove('Debug') | out-null
    $PSBoundParameters.Remove('ErrorAction') | out-null

    switch ($Ensure) {
        'Present' {
            #Native test for name conflict
            $TestAzureServiceName = Test-AzureName -Name $ServiceName -Service

            # Validate whether New or Set is required
            $Get = Get-TargetResource -AffinityGroup $AffinityGroup -ServiceName $ServiceName -ErrorAction SilentlyContinue 
            $PSBoundParameters.Remove('Ensure') | out-null

            if ($Get.ServiceName -eq $ServiceName) {
                # Native Set cmdlet
                $PSBoundParameters.Remove('AffinityGroup') | out-null
                Write-Verbose "Setting properties of Azure Service: `"$ServiceName`""
                Write-Verbose 'Please be patient as the operation completes.'
                $CurrentSubscription = Get-AzureSubscription -Current
                Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                Set-AzureService @PSBoundParameters
                }
            else{
                # Native New cmdlet
                if ($TestAzureServiceName -eq $False){
                    Write-Verbose "Creating new Azure Service: `"$ServiceName`""
                    Write-Verbose 'Please be patient as the operation completes.'
                    $CurrentSubscription = Get-AzureSubscription -Current
                    Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                    New-AzureService @PSBoundParameters
                    }
                else {
                    Write-Error "Unable to create Service, the name `"$ServiceName`" is already in use"
                    }
                }
            }
        'Absent' {
            $CurrentSubscription = Get-AzureSubscription -Current
            Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
            Remove-AzureService -ServiceName $ServiceName -Force
            }
        }
    }

#  Set-TargetResource 'Present' 'TestVMsWestUS1' 'testvmsservice1' 'Test Service created for Test Virtual Machines 1' 'Test VMs Service 1' -Verbose
#  Expectation is the service will be created, set, or removed.  Validate using Get-AzureService.

#endregion



#region TEST FUNCTION

function Test-TargetResource {
[CmdletBinding()]
[OutputType([Boolean])]
param(
[ValidateSet('Present','Absent')]
[string]$Ensure = 'Present',
[Parameter(Mandatory)][string]$AffinityGroup,
[Parameter(Mandatory)][string]$ServiceName,
[string]$Description,
[string]$Label
)
    $Get = Get-TargetResource -AffinityGroup $AffinityGroup -ServiceName $ServiceName -ErrorAction SilentlyContinue 

    # Removing Cmdlet parameters from output
    $PSBoundParameters.Remove('Ensure') | out-null
    $PSBoundParameters.Remove('Verbose') | out-null
    $PSBoundParameters.Remove('Debug') | out-null
    $PSBoundParameters.Remove('ErrorAction') | out-null

    # Compare dictionary and hash table
    switch ($Ensure) {
        'Present'{$bool = $true}
        'Absent'{$bool = $false}
        }

    $PSBoundParameters.keys | % {
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

#  Test-TargetResource 'Present' 'TestVMsWestUS1' 'testvmsservice1' 'Test Service created for Test Virtual Machines 1' 'Test VMs Service 1' -Verbose
#  Expectation is True or False based on whether the service has been deployed, depending on Present/Absent.

#endregion

Export-ModuleMember -function *-TargetResource