function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName
    )
    PROCESS {
        foreach ($computer in $computerName) {
            Write-Verbose "Getting WMI data from $computer"
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

'localhost','localhost' | Get-SystemInfo -verbose
