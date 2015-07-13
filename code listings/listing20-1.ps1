function Get-DetailedSystemInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string[]]$computerName
    )
    PROCESS {
        foreach ($computer in $computerName) {
            $params = @{'computerName'=$computer;         #A
                        'class'='Win32_OperatingSystem'}  #A
            $os = Get-WmiObject @params                   #A

            $params = @{'computerName'=$computer;         #B
                        'class'='Win32_LogicalDisk';      #B
                        'filter'='drivetype=3'}           #B
            $disks = Get-WmiObject @params                #B
            
            $diskobjs = @()                               #C
            foreach ($disk in $disks) { 
                $diskprops = @{'Drive'=$disk.DeviceID;    #D
                               'Size'=$disk.size;         
                               'Free'=$disk.freespace}    
                $diskobj = new-object -Type PSObject -Property $diskprops
                $diskobjs += $diskobj                     #E
            }

            $mainprops = @{'ComputerName'=$computer;    #F
                           'Disks'=$diskobjs;
                           'OSVersion'=$os.version;
                           'SPVersion'=$os.servicepackmajorversion}
            $mainobject = New-Object -Type PSOBject -Property $mainprops
            Write-Output $mainobject
        }
    }
}

Get-DetailedSystemInfo -computerName localhost,DONJONES1D96
