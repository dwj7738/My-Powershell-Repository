function Trace-Route             
{            
    <#
    .Synopsis
        Traces the route to a network destination
    .Description
        Traces the route to a network destination.  Wraps tracert.exe
    .Example
        Trace-Route -Url start-automating.com
    .Link
        http://tools.start-automating.com/Trace-Route
    #>            
    param(                
    # The URL to trace            
    [Parameter(Mandatory=$true)]            
    [Uri]$Url,            
    # The timeout for the request, in milliseconds            
    [Timespan]$Timeout = "0:0:0.25",            
    # The maximum number of hops for the trace route            
    [Int]$MaximumHops = 32            
    )            
                
    process {            
        Invoke-Expression "tracert -w $($timeOut.TotalMilliseconds) -h $MaximumHops $url" -ErrorAction SilentlyContinue |             
            Where-Object {            
                if ($_ -match "[.+]") {            
                    $destination             
                    try {            
                        $destination = [IpAddress]$_.Split("[]",[StringSplitOptions]"RemoveEmptyEntries")[-1]            
                    } catch {            
                        return $false            
                    }            
                }            
                $true               
            } |             
            Where-Object {            
                if ($_ -like "*Request timed out.*") {            
                    throw "Request timed Out"            
                }            
                return $true            
            } |             
            Where-Object {            
                $_ -like "*ms*"            
            } |            
            Foreach-Object {                            
                $chunks = $_ -split "  " | Where-Object { $_ }             
                $destAndip = $chunks[-1]            
                $dest, $ip = $destAndip.Replace("[", "").Replace("]","") -split " "            
                            
                if (-not $ip) {                                   
                    $ip = $dest            
                    $dest = ""                                    
                }            
                            
                $ip = @($ip)[0].Trim() -as [IPAddress]            
                            
            
                if ($chunks[1] -eq '*' -and $chunks[2] -eq '*' -and $chunks[3] -eq '*') {            
                    Write-Error "Request Timed Out"            
                    return            
                }            
                $trace = New-Object Object            
                $time1 = try { [Timespan]::FromMilliseconds($chunks[1].Replace("<","").Replace(" ms", ""))} catch {}            
                $time2 = try { [Timespan]::FromMilliseconds($chunks[1].Replace("<","").Replace(" ms", ""))} catch {}            
                $time3 = try { [Timespan]::FromMilliseconds($chunks[1].Replace("<","").Replace(" ms", ""))} catch {}            
                $trace |            
                    Add-Member NoteProperty HopNumber ($chunks[0].Trim() -as [uint32]) -PassThru |            
                    Add-Member NoteProperty Time1 $time1 -PassThru |            
                    Add-Member NoteProperty Time2 $time2 -PassThru |            
                    Add-Member NoteProperty Time3 $time3 -PassThru |            
                    Add-Member NoteProperty Ip $ip -PassThru |             
                    Add-Member NoteProperty Host $dest -PassThru |             
                    Add-Member NoteProperty DestinationUrl $url -PassThru |             
                    Add-Member NoteProperty DestinationIP $destination -PassThru              
                            
            }            
    }            
}          