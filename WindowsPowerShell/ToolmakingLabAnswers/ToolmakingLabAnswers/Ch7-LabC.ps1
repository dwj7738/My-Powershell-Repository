
Function Get-ServiceInfo {

[cmdletbinding()]

 param( [string[]]$ComputerName )

foreach ($computer in $computerName) {
    $data = Get-WmiObject -Class Win32_Service -computername $Computer -Filter "State='Running'" 

    foreach ($service in $data) {

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

}

Get-ServiceInfo -ComputerName localhost