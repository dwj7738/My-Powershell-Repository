Param($machine)
 if ($machine -eq $null) {
    write-Warning ('Syntax pshinfo computername')
    write-Warning ('Defaulting to local computer')
    $machine = "localhost"}


function GetComputerInfo{
    Param($mc)
    if ($mc -eq $null) {
    write-Warning ('Syntax pshinfo computername')
    write-Warning ('Defaulting to local computer')
    $mc = "localhost"}
    # Ping the machine to see if it is online
    $online=PingMachine $mc
    if ($online -eq $true)
    {
        # Ping Success

        # ComputerSystem info
        $CompInfo = Get-WmiObject Win32_ComputerSystem -comp $mc

        # OS info
        $OSInfo = Get-WmiObject Win32_OperatingSystem -comp $mc

        # Serial No
        $BiosInfo = Get-WmiObject Win32_BIOS -comp $mc

        # CPU Info
        $CPUInfo = Get-WmiObject Win32_Processor -comp $mc

        # Create custom Object
        $myobj = "" | Select-Object Name,Domain,Model,MachineSN,OS,ServicePack,WindowsSN,Uptime,RAM,Disk
        $myobj.Name = $CompInfo.Name
        $myobj.Domain = $CompInfo.Domain
        $myobj.Model = $CompInfo.Model
        $myobj.MachineSN = $BiosInfo.SerialNumber
        $myobj.OS = $OSInfo.Caption
        $myobj.ServicePack = $OSInfo.servicepackmajorversion
        $myobj.WindowsSN = $OSInfo.SerialNumber
        $myobj.uptime = (Get-Date) - [System.DateTime]::ParseExact($OSInfo.LastBootUpTime.Split(".")[0],'yyyyMMddHHmmss',$null)
        $myobj.uptime = "$($myobj.uptime.Days) days, $($myobj.uptime.Hours) hours," +`
          " $($myobj.uptime.Minutes) minutes, $($myobj.uptime.Seconds) seconds" 

        $myobj.RAM = "{0:n2} GB" -f ($CompInfo.TotalPhysicalMemory/1gb)
        $myobj.Disk = GetDriveInfo $mc

        #Return Custom Object"
        $myobj
    }
    else
    {
        # Ping Failed!
        Write-Host "Error: $mc not Pingable" -fore RED
    }
}

function GetDriveInfo{
    Param($comp)
    # Get disk sizes
    $logicalDisk = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $comp
    foreach($disk in $logicalDisk)
    {
        $diskObj = "" | Select-Object Disk,Size,FreeSpace
        $diskObj.Disk = $disk.DeviceID
        $diskObj.Size = "{0:n0} GB" -f (($disk | Measure-Object -Property Size -Sum).sum/1gb)
        $diskObj.FreeSpace = "{0:n0} GB" -f (($disk | Measure-Object -Property FreeSpace -Sum).sum/1gb)

        $text = "{0}  {1}  Free: {2}" -f $diskObj.Disk,$diskObj.size,$diskObj.Freespace
        $msg += $text + [char]13 + [char]10 
    }
    $msg
}

function PingMachine {
   Param([string]$machinename)
   $pingresult = Get-WmiObject win32_pingstatus -f "address='$machinename'"
   if($pingresult.statuscode -eq 0) {$true} else {$false}
}

# Main - run all the functions
GetComputerInfo ($machine)
