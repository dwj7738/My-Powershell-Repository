Function Optimize-VMS
{
[CmdletBinding()]

Param(
    $VMnames
)



foreach($VMname in $VMnames){
    #Check if VM is running
    Write-Host "Checking $VMname"
    if((Get-VM -Name $VMname).State -like "off"){
    
    #Find the disks
    foreach($VHD in ((Get-VMHardDiskDrive -VMName $VMname).Path)){
        Write-Host "Working on $VHD, please wait"
        Write-Host "Current size $([math]::truncate($(Get-VHD -Path $VHD).FileSize/ 1GB)) GB"
        Mount-VHD -Path $VHD -NoDriveLetter -ReadOnly
        Optimize-VHD -Path $VHD -Mode Full
        Write-Host "Optimize size $([math]::truncate($(Get-VHD -Path $VHD).FileSize/ 1GB)) GB"
        Dismount-VHD -Path $VHD
        Write-Host ""
        }
    }
    else{Write-Warning "$VMname is not turned off, will not be fixed"
    Write-Host ""}
}
}