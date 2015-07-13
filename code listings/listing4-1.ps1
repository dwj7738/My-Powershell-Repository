param(
    [string]$computerName = 'localhost'
)
Get-CimInstance -ClassName Win32_OperatingSystem `
                -ComputerName $computerName
