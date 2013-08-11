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

.PARAMETER ErrorLog
Specify a path to a file to log errors. The default is C:\Errors.txt

.PARAMETER LogErrors
If specified, computer names that can't be accessed will be logged 
to the file specified by -Errorlog.

.EXAMPLE
PS C:\> Get-ServiceInfo Server01

Run the command and query Server01.

.EXAMPLE
PS C:\> get-content c:\work\computers.txt | Get-ServiceInfo -logerrors

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
    Write-Verbose "Starting Get-ServiceInfo"

    #if -LogErrors and error log exists, delete it.
    if ( (Test-Path -path $errorLog) -AND $LogErrors) {
        Write-Verbose "Removing $errorlog"
        Remove-Item $errorlog
    }
 }

 Process {

    foreach ($computer in $computerName) {
		Write-Verbose "Getting services from $computer"
       
        Try {
            $data = Get-WmiObject -Class Win32_Service -computername $Computer -Filter "State='Running'" -ErrorAction Stop

            foreach ($service in $data) {
				Write-Verbose "Processing service $($service.name)"
                $hash=@{
                Computername=$data[0].Systemname
                Name=$service.name
                Displayname=$service.DisplayName
                }

                #get the associated process
                Write-Verbose "Getting process for $($service.name)"
                $process=Get-WMIObject -class Win32_Process -computername $Computer -Filter "ProcessID='$($service.processid)'" -ErrorAction Stop
                $hash.Add("ProcessName",$process.name)
                $hash.add("VMSize",$process.VirtualSize)
                $hash.Add("PeakPageFile",$process.PeakPageFileUsage)
                $hash.add("ThreadCount",$process.Threadcount)

                #create a custom object from the hash table
                $obj=New-Object -TypeName PSObject -Property $hash
				#add a type name to the custom object
        		$obj.PSObject.TypeNames.Insert(0,'MOL.ServiceProcessInfo')
			
				Write-Output $obj

            } #foreach service
                
            }
        Catch {
            #create an error message 
            $msg="Failed to get service data from $computer. $($_.Exception.Message)"
            Write-Error $msg 

            if ($LogErrors) {
				Write-Verbose "Logging errors to $errorlog"
            	$computer | Out-File -FilePath $Errorlog -append
            }
        }
                   
    } #foreach computer

} #process

End {
    Write-Verbose "Ending Get-ServiceInfo"
 }
    
}

Update-FormatData –prepend C:\CustomViewC.format.ps1xml

Get-ServiceInfo -ComputerName "localhost"
Get-ServiceInfo -ComputerName "localhost" | format-list
