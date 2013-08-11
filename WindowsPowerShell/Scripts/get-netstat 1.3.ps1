$netstat = netstat -a -n -o | where-object { $_ -match "(UDP|TCP)" }
[regex]$regexTCP = '(?<Protocol>\S+)\s+((?<LAddress>(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?))|(?<LAddress>\[?[0-9a-fA-f]{0,4}(\:([0-9a-fA-f]{0,4})){1,7}\%?\d?\]))\:(?<Lport>\d+)\s+((?<Raddress>(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?))|(?<RAddress>\[?[0-9a-fA-f]{0,4}(\:([0-9a-fA-f]{0,4})){1,7}\%?\d?\]))\:(?<RPort>\d+)\s+(?<State>\w+)\s+(?<PID>\d+$)'

[regex]$regexUDP = '(?<Protocol>\S+)\s+((?<LAddress>(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?))|(?<LAddress>\[?[0-9a-fA-f]{0,4}(\:([0-9a-fA-f]{0,4})){1,7}\%?\d?\]))\:(?<Lport>\d+)\s+(?<RAddress>\*)\:(?<RPort>\*)\s+(?<PID>\d+)'

foreach ($net in $netstat)
{
[psobject]$process = "" | Select-Object Protocol, LocalAddress, Localport, RemoteAddress, Remoteport, State, PID, ProcessName

    switch -regex ($net.Trim())
    {
        $regexTCP
        {          
            $process.Protocol = $matches.Protocol
            $process.LocalAddress = $matches.LAddress
            $process.Localport = $matches.LPort
            $process.RemoteAddress = $matches.RAddress
            $process.Remoteport = $matches.RPort
            $process.State = $matches.State
            $process.PID = [int]$matches.PID
            $process.ProcessName = ( Get-Process -Id $matches.PID -EA SilentlyContinue ).ProcessName
        }
        $regexUDP
        {          
            $process.Protocol = $matches.Protocol
            $process.LocalAddress = $matches.LAddress
            $process.Localport = $matches.LPort
            $process.RemoteAddress = $matches.RAddress
            $process.Remoteport = $matches.RPort
            $process.State = $matches.State
            $process.PID = [int]$matches.PID
            $process.ProcessName = ( Get-Process -Id $matches.PID -EA SilentlyContinue ).ProcessName
        }
    }
$process
}