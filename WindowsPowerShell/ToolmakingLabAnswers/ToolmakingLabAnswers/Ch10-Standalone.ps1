function Get-SystemInfo {
<#
.SYNOPSIS
Gets critical system info from one or more computers.
.DESCRIPTION
This command uses WMI, and can accept computer names, CNAME aliases,
and IP addresses. WMI must be enabled and you must run this
with admin rights for any remote computer.
.PARAMETER Computername
One or more names or IP addresses to query.
.EXAMPLE
Get-SystemInfo -computername localhost
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,
        [switch]$logErrors
    )
    BEGIN {
        if (Test-Path c:\errors.txt) {
            del c:\errors.txt
        }
    }
    PROCESS {
        foreach ($computer in $computerName) {
            WWrite-Verbose "Getting WMI data from $computer"
            try {
                $continue = $true
                $os = Get-WmiObject -class Win32_OperatingSystem -computerName $computer -ErrorAction Stop
            } catch {
                $continue = $false
                $computer | Out-File c:\errors.txt -append
                Write-Error "$computer failed"
            }
            if ($continue) {
                $cs = Get-WmiObject -class Win32_ComputerSystem   -computerName $computer
                $props = @{'ComputerName'=$computer;
                           'LastBootTime'=($os.ConvertToDateTime($os.LastBootupTime));
                           'OSVersion'=$os.version;
                           'Manufacturer'=$cs.manufacturer;
                           'Model'=$cs.model
				}
                $obj = New-Object -TypeName PSObject -Property $props
                Write-Output $obj
            }
        }
    }
}

Get-SystemInfo -computername localhost,NOTONLINE,localhost -logerrors
