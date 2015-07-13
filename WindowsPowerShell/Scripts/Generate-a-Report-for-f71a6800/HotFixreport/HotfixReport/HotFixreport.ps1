###------------------------------###    
### Author : Biswajit Biswas-----###      
###--MCC, MCSA, MCTS, CCNA, SME--###    
###Email<bshwjt@gmail.com>-------###    
###------------------------------###    
###/////////..........\\\\\\\\\\\###    
###///////////.....\\\\\\\\\\\\\\###
function Hotfixreport { 
$computers = Get-Content C:\computers.txt   
$ErrorActionPreference = 'Stop'   
ForEach ($computer in $computers) {  
 
  try  
    { 
Get-HotFix -cn $computer | Select-Object PSComputerName,HotFixID,Description,InstalledBy,InstalledOn | FT -AutoSize 
  
    } 
 
catch  
 
    { 
Add-content $computer -path "$env:USERPROFILE\Desktop\Notreachable_Servers.txt"
    }  
} 
 
} 
Hotfixreport > "$env:USERPROFILE\Desktop\Hotfixreport.txt"
