
Function Get-ServiceInfo {

<#
.SYNOPSIS
Get service information

.DESCRIPTION
This command will query a remote computer for running services and write
a custom object to the pipeline that includes service details as well as
a few key properties from the associated process. You must run this command
with credentials that have admin rights on any remote computers.

.PARAMETER Computername
The name of a computer to query. The account you use to run this function
should have admin rights on that computer.

.EXAMPLE
PS C:\> Get-ServiceInfo Server01

Run the command and query Server01.

.EXAMPLE
PS C:\> get-content c:\work\computers.txt | Get-ServiceInfo 

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
    Write-Verbose "Starting Get-ServiceInfo"
 }

 Process {

  foreach ($computer in $computerName) {
	Write-Verbose "Getting services from $computer"
			
    $data = Get-WmiObject -Class Win32_Service -computername $Computer -Filter "State='Running'" 

    foreach ($service in $data) {
		Write-Verbose "Processing service $($service.name)"
        $hash=@{
        Computername=$data[0].Systemname
        Name=$service.name
        Displayname=$service.DisplayName
        }

        #get the associated process
        $process=Get-WMIObject -class Win32_Process -computername $Computer -Filter "ProcessID='$($service.processid)'" 
        $hash.Add("ProcessName",$process.name)
        $hash.add("VMSize",$process.VirtualSize)
        $hash.Add("PeakPageFile",$process.PeakPageFileUsage)
        $hash.add("ThreadCount",$process.Threadcount)

        #create a custom object from the hash table
        New-Object -TypeName PSObject -Property $hash

    } #foreach service
 
   } #foreach computer
} #process

End {
    Write-Verbose "Ending Get-ServiceInfo"
 }
    
}

help Get-ServiceInfo -full