function Get-MACAddress { 
   Param(
   [Parameter(Mandatory=$true)]
   [string]$computerName = $env:computerName
   ) #end param
       
    $colItems = get-wmiobject -class "Win32_NetworkAdapterConfiguration" -computername $computername |Where{$_.IpEnabled -Match "True"}  
     
    foreach ($objItem in $colItems) {  
     
   # $objItem |select Description,MACAddress  
     return ($objitem.MACAddress)

    } 
} 

function Comp_Rename {
$name = Get-MACAddress -computerName localhost
$newname = "US-" + $name.Replace(":","")
$newname
$oldname = gc env:computername
$oldname
Rename-Computer -ComputerName $oldname -NewName $newname -WhatIf -Restart
}
