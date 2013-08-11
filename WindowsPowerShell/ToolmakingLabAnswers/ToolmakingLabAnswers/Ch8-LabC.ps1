
Function Get-ServiceInfo {

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

"localhost" | Get-ServiceInfo -verbose