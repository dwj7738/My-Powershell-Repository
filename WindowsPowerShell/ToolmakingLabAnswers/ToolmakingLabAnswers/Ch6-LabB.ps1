Function Get-VolumeInfo {

 param(
 [string[]]$ComputerName,
 [string]$ErrorLog="C:\Errors.txt"
 )


foreach ($computer in $computerName) {
    Try {
        $data = Get-WmiObject -Class Win32_Volume -computername $Computer -Filter "DriveType=3" -ErrorAction Stop
                
        Foreach ($drive in $data) {

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

    } #Try

    Catch {
        #create an error message and log it
        $msg="$(Get-Date) Error getting data from Win32_Volume on $computer. $($_.Exception.Message)"
        $msg | Out-File -FilePath $Errorlog -append
    }
} #foreach computer


}