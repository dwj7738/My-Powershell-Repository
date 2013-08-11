function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [string[]]$ComputerName,

        [string]$ErrorLog
    )
    BEGIN {}
    PROCESS {
        Write-Output $ComputerName
        Write-Output $ErrorLog
    }
    END {}
}
