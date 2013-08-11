<#
.SYNOPSIS
   <A brief description of the script>
.DESCRIPTION
   <A detailed description of the script>
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>

function MySleep ($minutes)
 {
 $seconds2minutes = 6
 $seconds = $minutes * $seconds2minutes
  Write-Output "Pausing $minutes Minutes"
 for($i = 1; $i -lt $seconds; $i++ )
    {
       write-progress Progress -perc ($i / $seconds2minutes)
   Start-Sleep -Seconds 1
    }
 }
 
Write-host  "Startup Script"
$work = $env:startsystem
if ($env:Startsystem = "") {
setx startsystem 1
$work = $env:startsystem
}

Write-Host "The environment value is $work"
switch ($work)
{
2 {
    setx startsystem  3

Write-Output "Enviroment Variable is now: $env:startsystem"
Write-Output -InputObject "Execute Script #1 and Wait 5 Minutes"
    #start script1.ps1
write-output  -inputobject  "Pausing 5 Minutes"
    mysleep 5
write-output  -inputobject  "Shutting down the Machine"
    # shutdown -f -t1
 
        }
3 {
write-output  -inputobject  "Starting Script $work"
    #start script2.ps1
    mysleep 5
write-output  -inputobject  "Deleting Startup Script as it is all done and rebooting machine"
  setx startsystem ""
#    del startup.cmd
Write-Output -InputObject "Shutting Down the Computer"
#shutdown -f -t1
}
default {
    setx startsystem 2
    Write-Output "Enviroment Variable is now: $env:startsystem"
    Write-Output -InputObject "Install 2 prograns and reboot"
    #Start-Process c:\windows\system32\msiexec.exe install1.msi
    write-output  -inputobject  "Pausing 1 Minutes for Program 1 to Install"
    mysleep 1
   
   Write-Output  "Pausing 1 minute for Program 2 to install"
    #Start-Process c:\windows\system32\msiexec.exe install2.msi
    write-output  -inputobject  "Pausing 2 Minutes for Program 3 to install"
    #Start-Process c:\windows\system32\msiexec.exe install.msi
    MySleep 2
    #shutdown -f -t1
    Write-Output -InputObject "Rebooting..."
}

}

