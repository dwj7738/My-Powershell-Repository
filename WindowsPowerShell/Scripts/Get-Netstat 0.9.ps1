$null, $null, $null, $null, $netstat = netstat -a -n -o
[regex]$regex = '\s+(?<Protocol>\S+)\s+(?<LocalAddress>\S+)\s+(?<RemoteAddress>\S+)\s+(?<State>\S+)\s+(?<PID>\S+)'

$netstat | ForEach-Object {
       if ( $_ -match $regex ) {
               $process = "" | Select-Object Protocol, LocalAddress, RemoteAddress,
State, PID
               $process.Protocol = $matches.Protocol
               $process.LocalAddress = $matches.LocalAddress
               $process.RemoteAddress = $matches.RemoteAddress
               $process.State = $matches.State
               $process.PID = $matches.PID
               $process
       }
}