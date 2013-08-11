function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [Alias('hostname')]
        [string[]]$ComputerName,

        [string]$ErrorLog = 'c:\retry.txt'
    )
    BEGIN {
        Write-Verbose "Error log will be $ErrorLog"
    }
    PROCESS {
        foreach ($computer in $computername) {
            Write-Verbose "Querying $computer"
            $os = Get-WmiObject -class Win32_OperatingSystem `
                                -computerName $computer
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
            Write-Output $obj
        }
    }
    END {}
}

'localhost','localhost' | Get-SystemInfo
