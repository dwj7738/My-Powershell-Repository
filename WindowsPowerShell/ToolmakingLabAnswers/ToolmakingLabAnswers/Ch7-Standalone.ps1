function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [string[]]$ComputerName
    )

    foreach ($computer in $computerName) {
        $os = Get-WmiObject -class Win32_OperatingSystem -computerName $computer
        $cs = Get-WmiObject -class Win32_ComputerSystem  -computerName $computer
        $props = @{'ComputerName'=$computer
                   'LastBootTime'=($os.ConvertToDateTime($os.LastBootupTime))
                   'OSVersion'=$os.version
                   'Manufacturer'=$cs.manufacturer
                   'Model'=$cs.model
		   		}
        $obj = New-Object -TypeName PSObject -Property $props
        Write-Output $obj
    }
}

Get-SystemInfo -ComputerName localhost 
