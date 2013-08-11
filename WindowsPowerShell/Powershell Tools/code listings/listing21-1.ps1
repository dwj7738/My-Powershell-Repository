function Get-OSInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string[]]$computerName
    )
    BEGIN {
        Write-Verbose "Starting Get-OSInfo"
    }
    PROCESS {
        ForEach ($computer in $computername) {
            try {
                $connected = $True
                Write-Verbose "Attempting $computer"
                $os = Get-WmiObject -ComputerName $computer `
                                    -class Win32_OperatingSystem `
                                    -EA Stop
            } catch {
                $connected = $false
                Write-Verbose "Connection to $computer failed"
            }
            if ($connected) {
                Write-Verbose "Connection to $computer succeeded"
                $cs = Get-WmiObject -ComputerName $computer `
                                    -class Win32_ComputerSystem
                $props = @{'ComputerName'=$computer;
                           'OSVersion'=$os.version;
                           'Manufacturer'=$cs.manufacturer;
                           'Model'=$cs.model}
                $obj = New-Object -TypeName PSObject -Property $props
                Write-Output $obj
            }
        }
    }
    END {
        Write-Verbose "Ending Get-OSInfo"
    }
}
