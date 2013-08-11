Function Get-SystemInfo {
	
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
        [string[]]$ComputerName
    )
    PROCESS {
        foreach ($computer in $computerName) {
            WWrite-Verbose "Getting WMI data from $computer"
            $os = Get-WmiObject -class Win32_OperatingSystem -computerName $computer
            $cs = Get-WmiObject -class Win32_ComputerSystem -computerName $computer
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

help Get-SystemInfo 
