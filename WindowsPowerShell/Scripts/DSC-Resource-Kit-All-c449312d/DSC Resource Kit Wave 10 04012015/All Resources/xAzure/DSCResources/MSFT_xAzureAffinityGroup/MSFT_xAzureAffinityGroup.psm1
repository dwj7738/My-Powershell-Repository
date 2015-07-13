#region GET FUNCTION

function Get-TargetResource {
[CmdletBinding()]
[OutputType([Hashtable])]
param (
[Parameter(Mandatory)][string]$Location,
[Parameter(Mandatory)][string]$Name,
[string]$Description,
[string]$Label
)
    $CurrentSubscription = Get-AzureSubscription -Current
    Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"

    # Native Get cmdlet
    $Get = Get-AzureAffinityGroup -Name $Name -ErrorAction SilentlyContinue
    
    # Build Hashtable from native cmdlet values
    $out = @{
            'Ensure' = If ($Get.Name -eq $Name) {'Present'} Else {'Absent'}
            'Location' = $Get.Location
            'Name' = $Get.Name
            'Description' = $Get.Description
            'Label' = $Get.Label
            }
    $out
    }

#  Get-TargetResource 'West US' 'TestVMWestUS1' 'West US Affinity Group for Test Virtual Machines' 'TestVMWestUS1' -Verbose
#  Expectation is a hashtable with properties of the affinity group, if it exists.

#endregion



#region SET FUNCTION

function Set-TargetResource {
[CmdletBinding()]
param(
[ValidateSet('Present','Absent')]
[string]$Ensure = 'Present',
[Parameter(Mandatory)][string]$Location,
[Parameter(Mandatory)][string]$Name,
[string]$Description,
[string]$Label
)
    switch ($Ensure) {
        'Present' {
            # Validate whether New or Set is required
            $Get = Get-TargetResource -Location $Location -Name $Name -ErrorAction SilentlyContinue 
            
            $PSBoundParameters.Remove('Ensure') | out-null

            if ($Get.Name -eq $Name) {
                # Native Set cmdlet
                $PSBoundParameters.Remove('Location') | out-null
                Write-Verbose "Setting properties of existing Affinity Group: `"$Name`""
                Write-Verbose 'Please be patient as the operation completes.'
                $CurrentSubscription = Get-AzureSubscription -Current
                Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                Set-AzureAffinityGroup @PSBoundParameters
                }
            else {
                # Native New cmdlet
                Write-Verbose "Creating new Affinity Group: `"$Name`""
                Write-Verbose 'Please be patient as the operation completes.'
                $CurrentSubscription = Get-AzureSubscription -Current
                Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                New-AzureAffinityGroup @PSBoundParameters
                }
            }
        'Absent' {
            Remove-AzureAffinityGroup $Name
            }
        }
    }

#  Set-TargetResource 'Present' 'West US' 'TestVMWestUS1' 'West US Affinity Group for Test Virtual Machines' 'TestVMWestUS1' -Verbose
#  Expectation is the affinity group will be created, set, or removed.  Validate using Get-AzureAffinityGroup.

#endregion



#region TEST FUNCTION

function Test-TargetResource {
[CmdletBinding()]
[OutputType([Boolean])]
param(
[ValidateSet('Present','Absent')]
[string]$Ensure,
[Parameter(Mandatory)][string]$Location,
[Parameter(Mandatory)][string]$Name,
[string]$Description,
[string]$Label
)

    # Output from Get-TargetResource
    $Get = Get-TargetResource -Location $Location -Name $Name -ErrorAction SilentlyContinue 

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

#  Test-TargetResource 'Present' 'West US' 'TestVMWestUS1' 'West US Affinity Group for Test Virtual Machines' 'TestVMWestUS1' -Verbose
#  Expectation is True or False based on whether the affinity group has been deployed, depending on Present/Absent.

#endregion

Export-ModuleMember -function *-TargetResource