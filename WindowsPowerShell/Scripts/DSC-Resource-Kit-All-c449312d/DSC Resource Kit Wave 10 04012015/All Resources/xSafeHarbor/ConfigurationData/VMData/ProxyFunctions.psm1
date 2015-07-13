function Get-SMBShare
{
    param
    (       
        [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [string[]]$Name,

        [Parameter(Position=2, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [string[]]$ScopeName,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [bool[]]$Scoped,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [bool[]]$ContinuouslyAvailable,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [Microsoft.PowerShell.Cmdletization.GeneratedTypes.SmbShare.ShareState[]]$ShareState,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [Microsoft.PowerShell.Cmdletization.GeneratedTypes.SmbShare.FolderEnumerationMode[]]$FolderEnumerationMode,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [Microsoft.PowerShell.Cmdletization.GeneratedTypes.SmbShare.CachingMode[]]$CachingMode,
        
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [uint32[]]$ConcurrentUserLimit,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [Microsoft.PowerShell.Cmdletization.GeneratedTypes.SmbShare.AvailabilityType[]]$AvailabilityType,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [uint32[]]$CaTimeout,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Cmdletization.GeneratedTypes.SmbShare.SmbInstance]$SmbInstance,

        [Parameter(Mandatory)]
        [Alias('Session')]
        [ValidateScript({Test-ShareComputer -ComputerName $_})]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,

        [int]$ThrottleLimit,

        [switch]$AsJob
    )

    $PSBoundParameters.Add("Special",$false)

    SmbShare\Get-SmbShare @PSBoundParameters
}

function New-SMBShare
{
    param
    (
        [switch]$Temporary,

        [bool]$ContinuouslyAvailable,

        [ValidateNotNull()]
        [AllowEmptyString()]
        [string]$Description,

        [ValidateNotNull()]
        [uint32]$ConcurrentUserLimit,

        [ValidateNotNull()]
        [uint32]$CATimeout,
        
        [Parameter(Mandatory, Position=2, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory, Position=1, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScopeName,

        [bool]$EncryptData,

        [Parameter(Mandatory)]
        [Alias('Session')]
        [ValidateScript({Test-ShareComputer -ComputerName $_})]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,

        [int]$ThrottleLimit,

        [switch]$AsJob
    )

    # Add code for Access parameters - FullAccess, ChangeAccess, ReadAccess, NoAccess
    $PSBoundParameters.Add("FullAccess",(Get-ShareUser -ShareName $Name -ComputerName $CimSession))
    $PSBoundParameters.Add("FolderEnumerationMode", "AccessBased")
    $PSBoundParameters.Add("CachingMode","None")
    $PSBoundParameters.Add("EncryptData",$true)

    SmbShare\New-SmbShare @PSBoundParameters
}

function Remove-SMBShare
{
    param
    (
        [Parameter(Mandatory, Position=1, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(Position=2, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [string[]]$ScopeName,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Cmdletization.GeneratedTypes.SmbShare.SmbInstance]$SmbInstance,

        [switch]$Force,

        [Parameter(Mandatory)]
        [Alias('Session')]
        [ValidateScript({Test-ShareComputer -ComputerName $_})]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,

        [int]$ThrottleLimit,

        [switch]$AsJob,

        [switch]$PassThru
    )

    SmbShare\Remove-SmbShare @PSBoundParameters
}

function Test-ShareComputer
{
    param
    (
        [String]$ComputerName
    )
    $ComputerName -in (Import-Csv $PSScriptRoot\Permission.csv).Computer
}

function Get-ShareUser
{
    param
    (
        [String]$ShareName,
        [String]$ComputerName
    )

    (Import-Csv $PSScriptRoot\Permission.csv | Where-Object{($_.share -eq $ShareName) -and ($_.computer -eq $ComputerName)}).User
}

Export-ModuleMember -Function Get-SmbShare,New-SmbShare,Remove-SmbShare