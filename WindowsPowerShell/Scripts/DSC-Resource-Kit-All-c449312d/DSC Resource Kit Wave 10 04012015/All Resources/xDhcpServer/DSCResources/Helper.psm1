# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
RoleNotFound            = Please ensure that the PowerShell module for role {0} is installed
InvalidIPAddressFormat  = Value of {0} property is not in a valid IP address format. Specify a valid IP address format and try again.
InvalidIPAddressFamily = The IP address {0} is not a valid {1} address. Specify a valid IP addess in {1} format and try again.
InvalidTimeSpanFormat  = Value of {0} property is not in a valid timespan format. Specify the timespan in days.hrs:mins:secs format and try again.
'@
}

# Internal function to throw terminating error with specified errroCategory, errorId and errorMessage
function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String]$errorId,
        
        [Parameter(Mandatory)]
        [String]$errorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory]$errorCategory
    )
    
    $exception = New-Object System.InvalidOperationException $errorMessage 
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
}

# Internal function to translate a string to valid IPAddress format
function Get-ValidIPAddress
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$ipString,

        [Parameter(Mandatory)]
        [ValidateSet('IPv4')]
        [String]$AddressFamily,

        [Parameter(Mandatory)]
        [string]$parameterName
    )

    $ipAddressFamily = ''
    if($AddressFamily -eq 'IPv4')
    { 
        $ipAddressFamily = 'InterNetwork'
    }
    else
    {
        $ipAddressFamily = 'InterNetworkV6'
    }

    [System.Net.IPAddress]$ipAddress = $null
    $result = [System.Net.IPAddress]::TryParse($ipString, [ref]$ipAddress)
    if(-not $result)
    {
        $errorMsg = $($LocalizedData.InvalidIPAddressFormat) -f $parameterName
        New-TerminatingError -errorId 'NotValidIPAddress' -errorMessage $errorMsg -errorCategory InvalidType
    }

    if($ipAddress.AddressFamily -ne $ipAddressFamily)
    {
        $errorMsg = $($LocalizedData.InvalidIPAddressFamily) -f $ipAddress,$AddressFamily
        New-TerminatingError -errorId 'InvalidIPAddressFamily' -errorMessage $errorMsg -errorCategory SyntaxError
    } 
    
    $ipAddress
}

# Internal function to assert if the role specific module is installed or not
function Assert-Module
{
    [CmdletBinding()]
    param
    (
        [string]$moduleName = 'DHCPServer'
    )

    if(! (Get-Module -Name $moduleName -ListAvailable))
    {
        $errorMsg = $($LocalizedData.RoleNotFound) -f $moduleName
        New-TerminatingError -errorId 'ModuleNotFound' -errorMessage $errorMsg -errorCategory ObjectNotFound
    }
}

# Internal function to write verbose messages for collection of properties
function Write-PropertyMessage
{
    param
    (
        [Parameter(Mandatory)]
        [Hashtable]$Parameters,

        [Parameter(Mandatory)]
        [String[]]$KeysToSkip,

        [Parameter(Mandatory)]
        [String]$MessageTemplate
    )

    foreach($key in $parameters.keys)
    {
        if($keysToSkip -notcontains $key)
        {
            $msg = $MessageTemplate -f $key,$parameters[$key]
            Write-Verbose -Message $msg
        }
    }
}

# Internal function to translate a string to valid IPAddress format
function Get-ValidTimeSpan
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$tsString,

        [Parameter(Mandatory)]
        [string]$parameterName
    )

    [System.TimeSpan]$timeSpan = New-TimeSpan
    $result = [System.TimeSpan]::TryParse($tsString, [ref]$timeSpan)
    if(-not $result)
    {
        $errorMsg = $($LocalizedData.InvalidTimeSpanFormat) -f $parameterName
        New-TerminatingError -errorId 'NotValidTimeSpan' -errorMessage $errorMsg -errorCategory InvalidType
    }

    $timeSpan
}