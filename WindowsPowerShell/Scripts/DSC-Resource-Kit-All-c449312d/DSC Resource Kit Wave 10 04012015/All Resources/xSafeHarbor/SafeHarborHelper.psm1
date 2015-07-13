function ValidateResult
{
    param
    (
        [Parameter(Mandatory)]
        $actualResult,
        [Parameter(Mandatory)]
        $expectedResult,
        [Parameter(Mandatory)]
        [string]$successMsg,
        [Parameter(Mandatory)]
        [string]$errorMsg
    )

    if($actualResult -eq $expectedResult)
    {
        $successMsg
    }
    else
    {
        throw $errorMsg
    }
}

function Get-VMIPAddress
{
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Switch]$SupportsIPV6
    )

    $IPAddressCount = 1
    if($SupportsIPV6) {$IPAddressCount = 2}

    while((Get-VMNetworkAdapter -VMName $Name).ipaddresses.count -lt $IPAddressCount)
    {
        Write-Verbose -Message "Waiting for IP Address of $Name ..." -Verbose
        Start-Sleep -Seconds 3;
    }
    ((Get-VMNetworkAdapter -VMName $Name).ipaddresses)[0]
}

function Get-ADUserSid
{
    param
    (
        [Parameter(Mandatory)]
        [String]$VMName,

        [Parameter(Mandatory)]
        [String]$UserName,

        [Parameter(Mandatory)]
        [PSCredential]$VMCredential
    )

    (Invoke-Command -ComputerName (Get-VMIPAddress -Name $VMName)  -Credential $VMCredential -ScriptBlock {
        Get-ADUser -Identity $using:UserName
    }).SID
}

function Set-SafeHarborUserCreds
{
    param ([PSCredential[]]$Credentials)

    $clixmlLocation    = "$PSScriptRoot\ConfigurationData\VMData"

    $CORPAdministrator = "Corporate\Administrator"
    $CORPAdminFile     = "$clixmlLocation\CORPDomainCred.CliXml"
    $CORPUser          = "Corporate\User1"
    $CORPUserFile      = "$clixmlLocation\CORPUserCred.CliXml"
    $CORPPapa          = "Corporate\Papa"
    $CORPPapaFile      = "$clixmlLocation\CORPPapaCred.CliXml"
    $CORPDeptHead      = "Corporate\DeptHead"
    $CORPDeptHeadFile  = "$clixmlLocation\CORPDeptHeadCred.CliXml"

    $SHAdministrator   = "Safeharbor\Administrator"
    $SHAdminFile       = "$clixmlLocation\SHDomainCred.CliXml"
    $SHMata            = "Safeharbor\Mata"
    $SHMataFile        = "$clixmlLocation\SHMataCred.CliXml"

    $DHCPAdmin         = "DHCPServer\Administrator"
    $DHCPAdminFile     = "$clixmlLocation\DHCPSrvCred.CliXml"

    $UserCredFileMap = @{
        $CORPAdministrator = $CORPAdminFile
        $CORPUser          = $CORPUserFile
        $CORPPapa          = $CORPPapaFile
        $CORPDeptHead      = $CORPDeptHeadFile
        $SHAdministrator   = $SHAdminFile
        $SHMata            = $SHMataFile
        $DHCPAdmin         = $DHCPAdminFile
    }

    # Check if SafeHarbor user credentials are supplied from outside.
    if($Credentials.Count -eq $UserCredFileMap.Count) {
        foreach ($userCred in $Credentials) {
            # Check if it is a Valid user. 
            $user = $userCred.UserName
            if(-not $UserCredFileMap[$userCred.UserName]) {
                throw "$user is not a valid SafeHarbor user."
            }

            $securePassWord = $userCred.Password
            New-Object System.Management.Automation.PSCredential ($user, $securePassWord) | Export-Clixml $UserCredFileMap[$user] -Force
        }

        return
    }

    # Check if serialized creds are going to work
    foreach ($user in $UserCredFileMap.Keys)
    {
        Write-Verbose -Message "Checking if the $user creds were serialized on localhost ..."

        # Check for Cred file
        Try {
            $null = Import-Clixml $UserCredFileMap[$user]
            Write-Verbose -Message "$user creds were serialized on localhost"
        }
        # Create the serialized version and overwrite existing file
        Catch
        {
            Write-Verbose -Message "Either serialized $user creds are not present or were not serialized on localhost."
            Get-Credential $user | Export-Clixml $UserCredFileMap[$user] -Force
        }
    }
}

function Get-SafeHarborUserCreds
{
    param ([String]$UserName)

    $clixmlLocation = "$PSScriptRoot\ConfigurationData\VMData"
    $userCredFiles = Get-ChildItem -Path $clixmlLocation -Filter *.clixml

    foreach ($cliXml in $userCredFiles) {
        $userCreds = Import-Clixml ($cliXml.FullName)
        if($userCreds.UserName -eq $UserName) {
            return $userCreds
        }
    }

    Throw "$UserName is not a valid SafeHarbor user."
}

function Get-DscResourceModulePath
{
    param(
        [Parameter(Mandatory)]
        [string] $DscResourceName)

    $dscResource = Get-DscResource $DscResourceName
    $dscResource.Module.ModuleBase
}

function Test-DscResourcesForSHScenario
{
    $installedDscResources = Get-DscResource
    $installedDscResourcesMap = @{}
    $shDscResourcesMap = @{
        "xIPAddress"        = "2.1"
        "xFirewall"         = "2.1"
        "xComputer"         = "1.2"
        "xDhcpServerScope"  = "1.0"
        "xDhcpServerOption" = "1.0"
        "xDhcpServerReservation"  = "1.0"
        "xDnsServerZoneTransfer"  = "1.0"
        "xDnsServerSecondaryZone" = "1.0"
        "xADDomain"         = "2.0"
        "xADDomainTrust"    = "2.0"
        "xADUser"           = "2.0"
        "xDSCWebService"    = "3.0.0.0"
        "xPSEndpoint"       = "3.0.0.0"
        "xVHD"              = "2.1.1"
        "xVhdFile"          = "2.1.1"
        "xVMHyperV"         = "2.1.1"
        "xVMSwitch"         = "2.1.1"
        "WaitForAll"        = "1.0"
    }

    foreach ($dscResource in $installedDscResources) {
        if(-not [string]::IsNullOrEmpty($dscResource.Module)) {
            $moduleVersion = $dscResource.Module.Version.ToString()
        }
        $installedDscResourcesMap.Add($dscResource.Name, $moduleVersion)
    }

    foreach ($shDscResource in $shDscResourcesMap.Keys) {
        # Check the requirec Dsc resources for SafeHarbor are installed on the Hyper-V Host. 
        if( [string]::IsNullOrEmpty($installedDscResourcesMap[$shDscResource]) -or
            ($installedDscResourcesMap[$shDscResource] -lt $shDscResourcesMap[$shDscResource])) {
            throw "$shDscResource Resource is not present, please make sure all the required DSC Resource are installed on Hyper-V Host."
        }
    }
}