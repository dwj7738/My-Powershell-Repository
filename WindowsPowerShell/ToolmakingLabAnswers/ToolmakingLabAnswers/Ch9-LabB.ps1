Function Get-VolumeInfo {

<#
.SYNOPSIS
Get information about fixed volumes

.DESCRIPTION
This command will query a remote computer and return information about fixed
volumes. The function will ignore network, optical and other removable drives.

.PARAMETER Computername
The name of a computer to query. The account you use to run this function
should have admin rights on that computer.

.EXAMPLE
PS C:\> Get-VolumeInfo Server01

Run the command and query Server01.

.EXAMPLE
PS C:\> get-content c:\work\computers.txt | Get-VolumeInfo 

This expression will go through a list of computernames and pipe each name
to the command. 

#>
[cmdletbinding()]

 param(
 [Parameter(Position=0,ValueFromPipeline=$True)]
 [ValidateNotNullorEmpty()]
 [string[]]$ComputerName
 )

Begin {
    Write-Verbose "Starting Get-VolumeInfo"
 }

Process {
    foreach ($computer in $computerName) {
   
    $data = Get-WmiObject -Class Win32_Volume -computername $Computer -Filter "DriveType=3" 
                
    Foreach ($drive in $data) {
		Write-Verbose "Processing volume $($drive.name)"
        #format size and freespace
        $Size="{0:N2}" -f ($drive.capacity/1GB)
        $Freespace="{0:N2}" -f ($drive.Freespace/1GB)

        #Define a hashtable to be used for property names and values
        $hash=@{
            Computername=$drive.SystemName
            Drive=$drive.Name
            FreeSpace=$Freespace
            Size=$Size
        }

        #create a custom object from the hash table
        New-Object -TypeName PSObject -Property $hash
    } #foreach

    #clear $data for next computer
    Remove-Variable -Name data

  } #foreach computer 
}#Process

 End {
    Write-Verbose "Ending Get-VolumeInfo"
 }
}

help Get-VolumeInfo -full