<#
.SYNOPSIS 
Gets Computer info Stuff from Places.
.EXAMPLE
Get-CompInfo -computername localhost
.EXAMPLE
Get-CompInfo -comp one,two,three
.EXAMPLE
get-content names.txt | get-CompINfo
.PARAMETER computername
One or more computer names. Or IP Address's.  Whatever..
.DESCRIPTION
Using a wmi query this retrieves the  Bios Serial Number, Computer Name, Model, OSVersion, Manufactuerer
#>
function Get-OSInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)]
        [string[]] $ComputerName,
        [string] $errorlogpath = "c:\temp\oops.txt"
        )

    BEGIN{}
    PROCESS{
    foreach ($computer in $ComputerName){
        Write-Verbose "About to Query $computer"
        Write-Debug "$computer is next..."
       try{
        $everything_ok = $true
        $os = Get-WmiObject -Class win32_operatingsystem -ComputerName $computer `
                                -ErrorVariable MyErr -ErrorAction Stop
        } 
        catch {
                $everything_ok = $false
                Write-Verbose "$computer failed, boss. Logging to $errorlogpath"
                Write-Verbose "Error was $MyErr"
                $computer | out-file $errorlogpath -Append
                }
        if($everything_ok) {
            $bios = Get-WmiObject -Class win32_bios -ComputerName $computer
            $cs = Get-WmiObject -Class win32_computersystem -ComputerName $computer
                $props = @{'ComputerName' = $computer;
                'OSVersion'= $os.version;
                'BIOSSerial' = $bios.serialnumber;
                'Model' = $cs.model;
                'Manufacturer' = $cs.manufacturer}
            $obj = New-Object -TypeName PSObject -Property $props
            Write-Debug "About to spew output..."
            Write-Output $obj
            }
        }
    }
    END {}
}