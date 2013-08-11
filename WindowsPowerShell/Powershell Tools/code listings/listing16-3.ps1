$MOLErrorLogPreference = 'c:\mol-retries.txt'
$MOLConnectionString = "server=localhost\SQLEXPRESS;database=inventory;trusted_connection=True"

Import-Module MOLDatabase

function Get-MOLComputerNamesFromDatabase {
<#
.SYNOPSIS
Reads computer names from the MoL sample database,
placing them into the pipeline as strings.
#>
    Get-MOLDatabaseData -connectionString $MOLConnectionString `
                        -isSQLServer `
                        -query "SELECT computername FROM computers" 
}

function Set-MOLInventoryInDatabase {
<#
.SYNOPSIS
Accepts the output of Get-MOLSystemInfo and saves
the results back to the MoL sample database.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True)]
        [object[]]$inputObject
    )
    PROCESS {
        foreach ($obj in $inputobject) {
            $query = "UPDATE computers SET
                      osversion = '$($obj.osversion)',
                      spversion = '$($obj.spversion)',
                      manufacturer = '$($obj.manufacturer)',
                      model = '$($obj.model)'
                      WHERE computername = '$($obj.computername)'"
            Write-Verbose "Query will be $query"
            Invoke-MOLDatabaseQuery -connection $MOLConnectionString `
                                    -isSQLServer `
                                    -query $query
        }
    }
}

function Get-MOLSystemInfo {
<#
.SYNOPSIS
Retrieves key system version and model information
from one to ten computers.
.DESCRIPTION
Get-SystemInfo uses Windows Management Instrumentation
(WMI) to retrieve information from one or more computers.
Specify computers by name or by IP address.
.PARAMETER ComputerName
One or more computer names or IP addresses, up to a maximum
of 10.
.PARAMETER LogErrors
Specify this switch to create a text log file of computers
that could not be queried.
.PARAMETER ErrorLog
When used with -LogErrors, specifies the file path and name
to which failed computer names will be written. Defaults to
C:\Retry.txt.
.EXAMPLE
 Get-Content names.txt | Get-MOLSystemInfo
.EXAMPLE
 Get-MOLSystemInfo -ComputerName SERVER1,SERVER2
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage="Computer name or IP address")]
        [ValidateCount(1,10)]
        [Alias('hostname')]
        [string[]]$ComputerName,

        [string]$ErrorLog = $MOLErrorLogPreference,

        [switch]$LogErrors
    )
    BEGIN {
        Write-Verbose "Error log will be $ErrorLog"
    }
    PROCESS {
        Write-Verbose "Beginning PROCESS block"
        foreach ($computer in $computername) {
            Write-Verbose "Querying $computer"
            Try {
                $everything_ok = $true
                $os = Get-WmiObject -class Win32_OperatingSystem `
                                    -computerName $computer `
                                    -erroraction Stop
            } Catch {
                $everything_ok = $false
                Write-Warning "$computer failed"
                if ($LogErrors) {
                    $computer | Out-File $ErrorLog -Append
                    Write-Warning "Logged to $ErrorLog"
                }
            }

            if ($everything_ok) {
                $comp = Get-WmiObject -class Win32_ComputerSystem `
                                      -computerName $computer
                $bios = Get-WmiObject -class Win32_BIOS `
                                      -computerName $computer
                $props = @{'ComputerName'=$computer;
                           'OSVersion'=$os.version;
                           'SPVersion'=$os.servicepackmajorversion;
                           'BIOSSerial'=$bios.serialnumber;
                           'Manufacturer'=$comp.manufacturer;
                           'Model'=$comp.model}
                Write-Verbose "WMI queries complete"
                $obj = New-Object -TypeName PSObject -Property $props
                $obj.PSObject.TypeNames.Insert(0,'MOL.SystemInfo')
                Write-Output $obj
            }
        }
    }
    END {}
}

function Restart-MOLCimComputer {
    [CmdletBinding(SupportsShouldProcess=$True,
                   ConfirmImpact='High')]
    param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [string[]]$ComputerName
    )
    PROCESS {
        ForEach ($computer in $computername) {
            Invoke-CimMethod -ClassName Win32_OperatingSystem `
                             -MethodName Reboot `
                             -ComputerName $computer
        }
    }
}

function Set-MOLServicePassword {
    [CmdletBinding(SupportsShouldProcess=$True,
                   ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True)]
        [string[]]$ComputerName,

        [Parameter(Mandatory=$True)]
        [string]$ServiceName,

        [Parameter(Mandatory=$True)]
        [string]$NewPassword
    )
    PROCESS {
        foreach ($computer in $computername) {
            $svcs = Get-WmiObject -ComputerName $computer `
                                  -Filter "name='$servicename'" `
                                  -Class Win32_Service
            foreach ($svc in $svcs) {
                if ($psCmdlet.ShouldProcess("$svc on $computer")) {
                    $svc.Change($null,
                                $null,
                                $null,
                                $null,
                                $null,
                                $null,
                                $null,
                                $NewPassword) | Out-Null
                }
            }
        }
    }
}

Export-ModuleMember -Variable MOLErrorLogPreference
Export-ModuleMember -Function Get-MOLSystemInfo,
                              Get-MOLComputerNamesFromDatabase,
                              Set-MOLInventoryInDatabase,
                              Restart-CimComputer,
                              Set-MOLServicePassword
