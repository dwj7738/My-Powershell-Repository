$MOLErrorLogPreference = 'c:\mol-retries.txt'  #A

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
                   HelpMessage="Computer name or IP address")]
        [ValidateCount(1,10)]
        [Alias('hostname')]
        [string[]]$ComputerName,

        [string]$ErrorLog = $MOLErrorLogPreference,  #B

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
Export-ModuleMember -Variable MOLErrorLogPreference  #C
Export-ModuleMember -Function Get-MOLSystemInfo
