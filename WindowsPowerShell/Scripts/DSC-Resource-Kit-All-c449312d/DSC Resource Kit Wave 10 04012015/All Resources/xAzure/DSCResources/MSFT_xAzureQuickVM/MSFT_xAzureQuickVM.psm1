#region GET FUNCTION

function Get-TargetResource {
[CmdletBinding()]
[OutputType([HashTable])]
param (
[Parameter(Mandatory)][string]$Name,
[Parameter(Mandatory)][string]$ServiceName
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

#  Get-TargetResource -Name 'TestVM1' -ServiceName 'DSCCreatedService1' -Verbose
#  Expectation is a hashtable with properties of the VM, if it exists.

#endregion



#region SET FUNCTION

function Set-TargetResource {
[CmdletBinding()]
param(
[ValidateSet('Present','Absent')]
[string]$Ensure = 'Present',
[Parameter(Mandatory)][string]$Name,
[string]$ImageName,
[Parameter(Mandatory)][string]$ServiceName,
[bool]$Linux,
[string]$LinuxUser,
[bool]$Windows,
[string]$AdminUserName,
[string]$Password,
[string]$InstanceSize
)
    # Removing parameters from output
    $PSBoundParameters.Remove('Ensure') | out-null
    $PSBoundParameters.Remove('Debug') | out-null
    $PSBoundParameters.Remove('ErrorAction') | out-null

    switch ($Ensure) {
        'Present' {
            # Native Set cmdlet
            Write-Verbose "Creating VM `"$Name`" in Microsoft Azure."
            Write-Verbose 'Please be patient as the operation completes.'
            $CurrentSubscription = Get-AzureSubscription -Current
            Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
            New-AzureQuickVM @PSBoundParameters
            }
        'Absent' {
            # Native Set cmdlet
            Write-Verbose "Removing VM `"$Name`" from Azure."
            Write-Verbose 'Please be patient as the operation completes.'
            $CurrentSubscription = Get-AzureSubscription -Current
            Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
            Remove-AzureVM -Name $Name -ServiceName $ServiceName -DeleteVHD
            }
        }
    }
  
#  Set-TargetResource -Ensure 'Present' -Name 'TestVM1' -ImageName 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201404.01-en.us-127GB.vhd' -ServiceName 'DSCCreatedService1' -Windows $True -AdminUserName 'YOURADMINACCOUNTHERE' -Password 'YOURPASSWORDHERE'-Verbose
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
[string]$ImageName,
[Parameter(Mandatory)][string]$ServiceName,
[bool]$Linux,
[string]$LinuxUser,
[bool]$Windows,
[string]$AdminUserName,
[string]$Password,
[string]$InstanceSize
)
    # Output from Get-TargetResource
    $Get = Get-TargetResource -Name $Name -ServiceName $ServiceName -ErrorAction SilentlyContinue 

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

#  Test-TargetResource -Ensure 'Present' -Name 'TestVM1' -ServiceName 'DSCCreatedService1' -Verbose
#  Expectation is True or False based on whether the VM has been deployed, depending on Present/Absent.

#endregion

Export-ModuleMember -function *-TargetResource