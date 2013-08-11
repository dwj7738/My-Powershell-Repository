Function Get-RemoteSMBShare {

[cmdletbinding()]


Param (
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a computername",
ValueFromPipeline=$True)]
[ValidateCount(1,5)]
[Alias('Hostname')]
[string[]]$ComputerName
)

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


# Section 15.3 Tests...
'localhost','localhost' | Get-RemoteSmbShare
Get-RemoteSmbShare –host localhost

# The following should prompt for a name; enter localhost
Get-RemoteSmbShare 

# The following should fail with an error
Get-RemoteSmbShare –Computer one,two,three,four,five,six,seven
