Function Get-RemoteSMBShare {

[cmdletbinding()]


Param ([string[]]$ComputerName)

Begin {
    Write-Verbose "Starting Get-RemoteSMBShare"
}
Process {

    Foreach ($computer in $computername) {
        Write-Verbose "Processing $computer"
        $shares = Invoke-Command -scriptblock {Get-SMBShare} -computername $computer
        $shares | Select-Object @{Name="Computername";Expression={$_.PSComputername}},
        Name,Path,Description
    } #foreach

}

End {
    Write-Verbose "Starting Get-RemoteSMBShare"
}

}


Get-RemoteSMBShare -computername localhost,localhost -verbose