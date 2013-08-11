
Function Get-VolumeInfo {

[cmdletbinding()]

 param( [string[]]$ComputerName )

foreach ($computer in $computerName) {
   
    $data = Get-WmiObject -Class Win32_Volume -computername $Computer -Filter "DriveType=3" 
                
    Foreach ($drive in $data) {

        #format size and freespace in GB to 2 decimal points
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

}

Get-VolumeInfo -ComputerName localhost