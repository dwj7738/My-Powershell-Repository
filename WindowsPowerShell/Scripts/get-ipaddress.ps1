# 
# Start of Script 
# 
   
# Get Networking Adapter Configuration 
$Computer = "." 
$IPconfigset = Get-WmiObject Win32_NetworkAdapterConfiguration 
   
# Iterate and get IP address 
$count = 0 
foreach ($IPConfig in $IPConfigSet) { 
   if ($Ipconfig.IPaddress) { 
      foreach ($addr in $Ipconfig.Ipaddress) { 
      "IP Address   : {0}" -f  $addr; 
      $count++  
      } 
   } 
} 
if ($count -eq 0) {"No IP addresses found"} 
else {"$Count IP addresses found on this system"} 
# End of Script  