function Restart-MOLCimComputer {
    [CmdletBinding(SupportsShouldProcess=$True,
                   ConfirmImpact='High')]
    param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [string[]]$ComputerName
    )
    PROCESS {
        ForEach ($computer in $computername) {
            Invoke-CimMethod -ClassName Win32_OperatingSystem `
                             -MethodName Reboot `
                             -ComputerName $computer
        }
    }
}

Export-ModuleMember -Variable MOLErrorLogPreference
Export-ModuleMember -Function Get-MOLSystemInfo,
                              Get-MOLComputerNamesFromDatabase,
                              Set-MOLInventoryInDatabase,
                              Restart-MOLCimComputer
