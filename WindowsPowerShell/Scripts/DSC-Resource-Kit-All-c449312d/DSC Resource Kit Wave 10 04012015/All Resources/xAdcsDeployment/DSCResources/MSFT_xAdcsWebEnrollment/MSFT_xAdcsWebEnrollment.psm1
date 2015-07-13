#region Get Resource
Function Get-TargetResource
{
    [CmdletBinding()]
    param(
    [ValidateSet('Present','Absent')]
    [string]$Ensure = 'Present',
    [string]$CAConfig,
    [Parameter(Mandatory)]
    [pscredential]$Credential,
    [Parameter(Mandatory)]
    [string]$Name
    )

    $ADCSParams = if (!$CAConfig) {@{Credential = $Credential}} else  {@{CAConfig = $CAConfig; Credential = $Credential}}

    return @{Ensure = $Ensure
        Credential = $Credential
        IsCAWeb = Test-TargetResource @ADCSParams
    }
}
# Get-TargetResource -Name 'Test' -Credential (Get-Credential)
# Expected Outcome: Return a table of appropriate values.
#endregion

#region Set Resource
Function Set-TargetResource
{
    [CmdletBinding()]
    param(
    [ValidateSet('Present','Absent')]
    [string]$Ensure = 'Present',
    [string]$CAConfig,
    [Parameter(Mandatory)]
    [pscredential]$Credential,
    [Parameter(Mandatory)]
    [string]$Name
    )

    $ADCSParams = if (!$CAConfig) {@{Credential = $Credential}} else  {@{CAConfig = $CAConfig; Credential = $Credential}}

    switch ($Ensure) {
        'Present' {(Install-AdcsWebEnrollment @ADCSParams -Force).ErrorString}
        'Absent' {(Uninstall-AdcsWebEnrollment -Force).ErrorString}
        }
}
# Set-TargetResource -Name 'Test' -Credential (Get-Credential)
# Expected Outcome: Setup Certificate Services Web Enrollment on this node.
#endregion

#region Test Resource
Function Test-TargetResource
{
        [CmdletBinding()]
        param(
    [ValidateSet('Present','Absent')]
    [string]$Ensure = 'Present',
    [string]$CAConfig,
    [Parameter(Mandatory)]
    [pscredential]$Credential,
    [Parameter(Mandatory)]
    [string]$Name
    )

    $ADCSParams = if (!$CAConfig) {@{Credential = $Credential}} else  {@{CAConfig = $CAConfig; Credential = $Credential}}

    try{
        $test = Install-AdcsWebEnrollment @ADCSParams -WhatIf
        Switch ($Ensure) {
            'Present' {return $false}
            'Absent' {return $true}
            }
    }
    catch{
        Write-verbose $_
        Switch ($Ensure) {
            'Present' {return $true}
            'Absent' {return $false}
            }
    }
}
# Test-TargetResource -Name 'Test' -Credential (Get-Credential)
# Expected Outcome: Returns a boolean indicating whether Certificate Services Web Enrollment is installed on this node.
#endregion

Export-ModuleMember -Function *-TargetResource