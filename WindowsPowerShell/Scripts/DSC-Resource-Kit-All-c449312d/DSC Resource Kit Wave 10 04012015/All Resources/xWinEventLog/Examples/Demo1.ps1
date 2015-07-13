cls

$before = Get-WinEvent -ListLog "Microsoft-Windows-MSPaint/Admin" 
configuration Demo1
{
    Import-DscResource -module xWinEventLog

    xWinEventLog Demo1
    {
        LogName            = "Microsoft-Windows-MSPaint/Admin"
        IsEnabled          = $true
        LogMode            = "AutoBackup"
        MaximumSizeInBytes = 20mb
    }
}

Demo1 -OutputPath $env:temp

Start-DscConfiguration -Path $env:temp -ComputerName localhost -Verbose -wait -debug


$after = Get-WinEvent -ListLog "Microsoft-Windows-MSPaint/Admin" 
$before,$after | format-table -AutoSize LogName,IsEnabled,MaximumSizeInBytes,ProviderLatency,LogMode
Get-DscConfiguration 
#EOF
