Function Get-ServiceInfo {

 param(
 [string[]]$ComputerName,
 [string]$ErrorLog="C:\Errors.txt"
 )


foreach ($computer in $computerName) {
    Try {
        $data = Get-WmiObject -Class Win32_Service -computername $Computer -Filter "State='Running'" -ErrorAction Stop

        foreach ($service in $data) {

            $hash=@{
            Computername=$data[0].Systemname
            Name=$service.name
            Displayname=$service.DisplayName
            }

            #get the associate process
            $process=Get-WMIObject -class Win32_Process -computername $Computer -Filter "ProcessID='$($service.processid)'" -ErrorAction Stop
            $hash.Add("ProcessName",$process.name)
            $hash.add("VMSize",$process.VirtualSize)
            $hash.Add("PeakPageFile",$process.PeakPageFileUsage)
            $hash.add("ThreadCount",$process.Threadcount)

                #create a custom object from the hash table
            New-Object -TypeName PSObject -Property $hash

        } #foreach service
                
        }
    Catch {
        #create an error message and log it
        $msg="$(Get-Date) Error getting service data $computer. $($_.Exception.Message)"
        $msg | Out-File -FilePath $Errorlog -append
    }
                   
} #foreach computer
    
}