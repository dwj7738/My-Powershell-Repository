#region GET FUNCTION

function Get-TargetResource {
[CmdletBinding()]
[OutputType([Hashtable])]
param (
[Parameter(Mandatory)][string]$AzureSubscriptionName
)
    # Native Get cmdlet
    $Get = Get-AzureSubscription -Current -ErrorAction SilentlyContinue

    # Build Hashtable
    @{
        'Ensure' = If ($Get.SubscriptionName -eq $AzureSubscriptionName) {'Present'} Else {'Absent'}
        'AzureSubscriptionName' = $Get.SubscriptionName
    }

    }

#  Get-TargetResource -AzureSubscriptionName 'Visual Studio Ultimate with MSDN' -Verbose
#  Expectation is hashtable with subscription id, if it is registered

#endregion



#region SET FUNCTION

function Set-TargetResource {
[CmdletBinding()]
param(
[ValidateSet('Present','Absent')]
[string]$Ensure = 'Present',
[Parameter(Mandatory)][string]$AzureSubscriptionName,
[string]$AzurePublishSettingsFile
)
    switch ($Ensure) {
        'Present' {
            if ($WhatIfPreference -eq $true) {
            Write-Verbose 'What if:The Azure subscription ID is (SubscriptionID)'
                }
            else {
                Import-AzurePublishSettingsFile -PublishSettingsFile $AzurePublishSettingsFile -ErrorAction SilentlyContinue
                Select-AzureSubscription -SubscriptionName $AzureSubscriptionName -Current -ErrorAction SilentlyContinue
                $CurrentSubscription = Get-AzureSubscription -Current
                Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                }        
            }
        'Absent' {
            Remove-AzureSubscription -SubscriptionName $AzureSubscriptionName -Force -ErrorAction SilentlyContinue
            }
        }
    }

#  Set-TargetResource -Ensure 'Absent' -AzureSubscriptionName 'Visual Studio Ultimate with MSDN' -AzurePublishSettingsFile 'C:\Azure\MSDN.publishsettings' -Verbose
#  Expectation is subscription woul dbe registered and set as current.  Validate using Get-AzureSubscription.

#endregion



#region TEST FUNCTION

function Test-TargetResource {
[CmdletBinding()]
[OutputType([Boolean])]
param(
[ValidateSet('Present','Absent')]
[string]$Ensure = 'Present',
[Parameter(Mandatory)][string]$AzureSubscriptionName,
[string]$AzurePublishSettingsFile
)
    # Output from Get-TargetResource
    $Get = Get-TargetResource -AzureSubscriptionName $AzureSubscriptionName -ErrorAction SilentlyContinue 

    # Compare
    switch ($Ensure) {
        'Present'{$bool = $true}
        'Absent'{$bool = $false}
        }

    if ($AzureSubscriptionName -ne $Get.AzureSubscriptionName) {
            switch ($Ensure) {
                'Present'{$bool = $false}
                'Absent'{$bool = $true}
                }
            write-verbose 'Azure Subscription not set to Current.'
        }

    $bool
    }

#  Test-TargetResource -Ensure 'Present' -AzureSubscriptionName 'Visual Studio Ultimate with MSDN' -AzurePublishSettingsFile 'C:\Azure\MSDN.publishsettings' -Verbose
#  Expectation is boolean value representing whether subscription has been registered, depending on Present/Absent.

#endregion

Export-ModuleMember -function *-TargetResource