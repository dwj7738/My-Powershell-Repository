function Set-MOLServicePassword {
    [CmdletBinding(SupportsShouldProcess=$True,
                   ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True)]
        [string[]]$ComputerName,

        [Parameter(Mandatory=$True)]
        [string]$ServiceName,

        [Parameter(Mandatory=$True)]
        [string]$NewPassword
    )
    PROCESS {
        foreach ($computer in $computername) {
            $svcs = Get-WmiObject -ComputerName $computer `
                                  -Filter "name='$servicename'" `
                                  -Class Win32_Service
            foreach ($svc in $svcs) {
                if ($psCmdlet.ShouldProcess("$svc on $computer")) {
                    $svc.Change($null,
                                $null,
                                $null,
                                $null,
                                $null,
                                $null,
                                $null,
                                $NewPassword) | Out-Null
                }
            }
        }
    }
}

Export-ModuleMember -Variable MOLErrorLogPreference
Export-ModuleMember -Function Get-MOLSystemInfo,
                              Get-MOLComputerNamesFromDatabase,
                              Set-MOLInventoryInDatabase,
                              Restart-CimComputer,
                              Set-MOLServicePassword
