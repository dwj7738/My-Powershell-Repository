$msgTable = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
        attempting = Attempting
        connectionTo = Connection to
        failed = failed
        succeeded = succeeded
        starting = Starting Get-OSInfo
        ending = Ending Get-OSInfo
'@
}
Import-LocalizedData -BindingVariable $msgTable  #1

function Get-OSInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string[]]$computerName
    )
    BEGIN {
        Write-Verbose $msgTable.starting
    }
    PROCESS {
        ForEach ($computer in $computername) {
            try {
                $connected = $True
                Write-Verbose "$($msgTable.attempting) $computer"
                $os = Get-WmiObject -ComputerName $computer `
                                    -class Win32_OperatingSystem `
                                    -EA Stop
            } catch {
                $connected = $false
                Write-Verbose "$($msgTable.connectionTo) $computer $($msgTable.failed)"
            }
            if ($connected) {
                Write-Verbose "$($msgTable.connectionTo) to $computer $($msgTable.succeeded)"
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
        Write-Verbose $msgTable.ending
    }
}

Export-ModuleMember -function "Get-OSInfo"
