param (
$computername = 'localhost'
)
Get-WmiObject -class Win32_LogicalDisk -computername $computername `
-filter "drivetype=3" |
Sort-Object -property DeviceID |
Format-Table -property DeviceID,
@{l='FreeSpace(MB)';e={$_.FreeSpace / 1MB -as [int]}},
@{l='Size(GB';e={$_.Size / 1GB -as [int]}},
@{l='%Free';e={$_.FreeSpace / $_.Size * 100 -as [int]}}
