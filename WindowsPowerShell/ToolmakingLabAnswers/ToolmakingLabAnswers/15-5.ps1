Function Get-RemoteSMBShare {

<#
.SYNOPSIS
Get SMB share information
.DESCRIPTION
This command uses the SMBShare module that is available on Windows 8 and
Windows Server 2012 to query for shared folders. This command uses
PowerShell remoting. Any remote computer you query must have remoting
enabled and be running Windows 8 or Windows Server 2012.
.PARAMETER Computername
The name of the remote computer to query. This parameter has an
alias of 'Hostname'.
.PARAMETER ErrorFile
The filename and path to log failed computers. The default is C:\Errors.txt
.EXAMPLE
PS C:\> Get-RemoteSMBShare -Computer SERVER12

Get SMBShares from SERVER12
.EXAMPLE
PS C:\> get-content computers.txt | Get-SMBRemoteShare

Pipe names from computers.txt to the command and list remote SMB
shares.

#>

[cmdletbinding()]


Param (
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a computername",
ValueFromPipeline=$True)]
[ValidateCount(1,5)]
[Alias('Hostname')]
[string[]]$ComputerName,
[string]$ErrorFile="C:\Errors.txt"
)

Begin {
    Write-Verbose "Starting Get-RemoteSMBShare"
}
Process {

    Foreach ($computer in $computername) {
        Write-Verbose "Processing $computer"
        Try {
            $shares = Invoke-Command -scriptblock {Get-SMBShare} -computername $computer -ErrorAction Stop
            $shares | Select-Object @{Name="Computername";Expression={$_.PSComputername}},
            Name,Path,Description -ErrorAction Stop
        }
        Catch {
            Write-Verbose "Logging errors to $ErrorFile"
            $Computer | Out-File -FilePath $ErrorFile -Append
            Write-Warning "Failed to retrieve SMBShares from $Computer"
        }

    } #foreach

}

End {
    Write-Verbose "Starting Get-RemoteSMBShare"
}

}

Get-RemoteSmbShare –computer localhost,NOTONLINE,localhost 