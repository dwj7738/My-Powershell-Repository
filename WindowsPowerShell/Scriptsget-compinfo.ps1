[CmdletBinding()]
param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$True)]
    [string[]] $ComputerName
    )

BEGIN{}
PROCESS{
foreach ($computer in $ComputerName){
    $os = Get-WmiObject -Class win32_operatingsystem -ComputerName $computer
    $bios = Get-WmiObject -Class win32_bios -ComputerName $computer
    $cs = Get-WmiObject -Class win32_computersystem -ComputerName $computer
        $props = @{'ComputerName' = $computer;
        'OSVersion'= $os.version;
        'BIOSSerial' = $bios.serialnumber;
        'Model' = $cs.model;
        'Manufacturer' = $cs.manufacturer}
    $obj = New-Object -TypeName PSObject -Property $props
    Write-Output $obj

}
}
END {}