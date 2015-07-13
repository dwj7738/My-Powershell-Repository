###------------------------------###   
### Author : Biswajit Biswas-----###     
###--MCC, MCSA, MCTS, CCNA, SME--###   
###Email<bshwjt@gmail.com>-------###   
###------------------------------###   
###/////////..........\\\\\\\\\\\###   
###///////////.....\\\\\\\\\\\\\\### 
Function HotfixReport { 
      [CmdletBinding()] 
      Param( 
            [Parameter(Mandatory=$True,                       ValueFromPipeline=$True,                       ValueFromPipelinebyPropertyName=$True)]      [string[]]$computername = 'Get-Content C:\computers.txt',
      [string]$logfile            )  
PROCESS { 
      Foreach ($computer in $computername) { 
               

            try {
                  Get-HotFix -cn $computer | Select-Object PSComputerName,HotFixID,Description,InstalledBy,InstalledOn | FT -AutoSize                  
            } catch { 
                                    "$computer - is not reachable" | Out-File $logfile -append 
            } #end of catch     
           } 
          } 
         } 
          
Get-Content C:\computers.txt | HotfixReport -logfile "$env:USERPROFILE\Desktop\Error.log" > "$env:USERPROFILE\Desktop\Hotfixreport.txt"
