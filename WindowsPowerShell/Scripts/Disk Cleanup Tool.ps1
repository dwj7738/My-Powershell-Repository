#+-------------------------------------------------------------------+  
#| = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = |  
#|{>/-------------------------------------------------------------\<}|           
#|: | Author:  Aman Dhally                                                   
#| :| Email:   amandhally@gmail.com
#| :| Web:	www.amandhally.net/blog
#| :| blog: http://newdelhipowershellusergroup.blogspot.com/
#| :|
#|: | Purpose: 													   
#| :|       Clean lapopt using removing un-wantede files 
#|: |           						                         
#|: |                                Date: 23-02-2012             
#| :| 					/^(o.o)^\    Version: 2       
#|{>\-------------------------------------------------------------/<}|
#| = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = |
#+-------------------------------------------------------------------+


#### Variables ####

$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace(0xA)
$Lenovo = "C:\Program Files\Lenovo\System Update\session\*"
$temp = get-ChildItem "env:\TEMP"
$temp2 = $temp.Value
$swtools = "c:\SWTOOLS\*"
$WinTemp = "c:\Windows\Temp\*"

#1# Remove Lenovo not wanted Setup Files | You must keep system, temp, QuestResponse.xml and updates.ser ##
#Remove-Item -Recurse  -Path $Lenovo -Exclude system,temp,updates.ser,"*.xml"   -Verbose -Force 

#2# Remove temp files located in "C:\Users\USERNAME\AppData\Local\Temp"
write-Host "Removing Junk files in $temp2." -ForegroundColor Magenta 
Remove-Item -Recurse "$temp2\*" -Force -Verbose

#3# Remove Item in c:\Swtools folder excluding Checkpoint,landesk,useradmin folder ... remove  -what if it if you want to do it ..
# write-Host "Emptying $swtools folder." 
#Remove-Item -Recurse $swtools   -Verbose -Force -WhatIf

#4#	Empty Recycle Bin # http://demonictalkingskull.com/2010/06/empty-users-recycle-bin-with-powershell-and-gpo/
write-Host "Emptying Recycle Bin." -ForegroundColor Cyan 
$objFolder.items() | %{ remove-item $_.path -Recurse -Confirm:$false}

#5# Remove Windows Temp Directory 
write-Host "Removing Junk files in $WinTemp." -ForegroundColor Green
Remove-Item -Recurse $WinTemp -Force 

#6# Running Disk Clean up Tool 
write-Host "Finally now , Running Windows disk Clean up Tool" -ForegroundColor Cyan
cleanmgr /sagerun:1 | out-Null 

$([char]7)
Sleep 1 
$([char]7)
Sleep 1 

write-Host "I finished the cleanup task,Bye Bye " -ForegroundColor Yellow 
##### End of the Script #####