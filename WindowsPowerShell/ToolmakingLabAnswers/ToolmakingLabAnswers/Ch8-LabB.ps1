
Function Get-VolumeInfo {

[cmdletbinding()]

 param(
 [Parameter(Position=0,ValueFromPipeline=$True)]
 [ValidateNotNullorEmpty()]
 [string[]]$ComputerName
 )

Begin {
    Write-Verbose "Starting Get-VolumeInfo"
 }

Process {
   foreach ($computer in $computerName) {
    Write-Verbose "Getting volume data from $computer"
    $data = Get-WmiObject -Class Win32_Volume -computername $Computer -Filter "DriveType=3" 
                
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
        New-Object -TypeName PSObject -Property $hash
    } #foreach

    #clear $data for next computer
    Remove-Variable -Name data

} #foreach computer

} #Process

End {
    Write-Verbose "Ending Get-VolumeInfo"
 }
}

"localhost" | Get-VolumeInfo -verbose