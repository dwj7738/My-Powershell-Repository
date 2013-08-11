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

.PARAMETER ErrorLog
Specify a path to a file to log errors. The default is C:\Errors.txt

.EXAMPLE
PS C:\> Get-VolumeInfo Server01

Run the command and query Server01.

.EXAMPLE
PS C:\> get-content c:\work\computers.txt | Get-VolumeInfo -errorlog c:\logs\errors.txt

This expression will go through a list of computernames and pipe each name
to the command. Computernames that can't be accessed will be written to
the log file.

#>
[cmdletbinding()]

 param(
 [Parameter(Position=0,ValueFromPipeline=$True)]
 [ValidateNotNullorEmpty()]
 [string[]]$ComputerName,
 [string]$ErrorLog="C:\Errors.txt",
  [switch]$LogErrors
 )

Begin {
    Write-Verbose "Starting Get-VolumeInfo"
 }

Process {
    foreach ($computer in $computerName) {
        Write-Verbose "Getting data from $computer"
        Try {
            $data = Get-WmiObject -Class Win32_Volume -computername $Computer -Filter "DriveType=3" -ErrorAction Stop
                
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
                $obj=New-Object -TypeName PSObject -Property $hash
				#Add a type name to the object
				$obj.PSObject.TypeNames.Insert(0,'MOL.DiskInfo')
			
				Write-Output $obj
				
            } #foreach

            #clear $data for next computer
            Remove-Variable -Name data

        } #Try

        Catch {
            #create an error message 
            $msg="Failed to get volume information from $computer. $($_.Exception.Message)"
            Write-Error $msg 

            Write-Verbose "Logging errors to $errorlog"
            $computer | Out-File -FilePath $Errorlog -append
        }
    } #foreach computer
} #Process

 End {
    Write-Verbose "Ending Get-VolumeInfo"
 }
}

Update-FormatData –prepend C:\CustomViewB.format.ps1xml
Get-VolumeInfo localhost