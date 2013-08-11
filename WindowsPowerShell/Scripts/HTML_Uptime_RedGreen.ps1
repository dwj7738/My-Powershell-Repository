# ----------------------------------------------------------------------------- 
# Script: HTML_Uptime_RedGreen.ps1 
# Author: ed wilson, msft 
# Date: 08/07/2012 15:11:03 
# Keywords: Scripting Techniques, Web Pages and HTAs 
# comments: added freespace to the script  
# Get-Wmiobject, New-Object, Get-Date, Convertto-HTML, Invoke-Item 
# HSG-8-7-2012, HSG-8-8-2012, HSG-8-9-2012, HSG-8-10-2012, HSG-8-11-2012 
# HSG-8-12-2012 
# ----------------------------------------------------------------------------- 
Param( 
  [string]$path = "c:\fso\RedGreenUpTime.html", 
  [array]$servers = @("dc1","s2k8r2e","ts01","davidjohnson-w7") 
) 
 
Function Get-UpTime 
{ Param ([string[]]$servers) 
  Foreach ($s in $servers)  
   {  
  
     if(Test-Connection -ComputerName $s -Quiet -BufferSize 16 -Count 1) 
       { 
       $s
       $os = Get-WmiObject -class win32_OperatingSystem -computername $s  
       New-Object psobject -Property @{computer=$s; 
       uptime = (get-date) - $os.converttodatetime($os.lastbootuptime)} 
        } 
      ELSE 
       { New-Object psobject -Property @{computer=$s; uptime = "DOWN"} } 
    } #end foreach S 
 } #end function Get-Uptime 
 
 
# Entry Point *** 
 
$style = @" 
  
 BODY{background-color:AntiqueWhite;} 
 TABLE{border-width: 1px;border-style: solid;border-color: Black;border-collapse: collapse;} 
 TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:DarkSalmon} 
"@ 
 
$precontent = @" 
 <h1>Server Uptime Report</h1> 
 <h2>The following report was run on $(get-date)</h2> 
"@

Remove-Item $path
 
$i = 0 
 
Foreach( $server in $servers) 
 { 
   $uptime = Get-UpTime -servers $server  
   $uptime
   $rtn = New-Variable -Name "$server" -PassThru 
   $rtn
   if ($uptime -eq "DOWN")  
     { $uptime.uptime -eq "DOWN" 
       $upstyleRed = $style + "`r`nTD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:Red} " 
       $rtn.value = $uptime | ConvertTo-Html -As Table -Fragment  -PreContent $upstyleRed | Out-String 
       }  
   else 
    {  $uptime -eq "DOWN" 
       $upstyleGreen = $style + "`r`nTD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:Green} </style>" 
       $rtn.value = $uptime | ConvertTo-Html -As Table -Fragment  -PreContent $upstyleGreen | Out-String 
       }  
 
    [array]$frags+=$rtn.Name 
    $i++ 
} 
 
$fragments = foreach($f in $frags) { Get-Variable $f | select -ExpandProperty value } 
ConvertTo-Html -PreContent $precontent -PostContent $fragments >> $path  
Invoke-Item $path 