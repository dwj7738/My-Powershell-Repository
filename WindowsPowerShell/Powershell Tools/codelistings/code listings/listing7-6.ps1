function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [string[]]$ComputerName,

        [string]$ErrorLog
    )
    BEGIN {
        Write-Output "Log name is $errorlog"
    }
    PROCESS {
        foreach ($computer in $computername) {
            $os = Get-WmiObject -class Win32_OperatingSystem `
                                -computerName $computer
            $comp = Get-WmiObject -class Win32_ComputerSystem `
                                  -computerName $computer
            $bios = Get-WmiObject -class Win32_BIOS `
                                  -computerName $computer
            
        }
    }
    END {}
}
