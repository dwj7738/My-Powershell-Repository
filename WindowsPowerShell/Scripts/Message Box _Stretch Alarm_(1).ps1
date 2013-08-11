# --------------------------------- Meta Information for Microsoft Script Explorer for Windows PowerShell V1.0 ---------------------------------
# Title: Message Box "Stretch Alarm"
# Author: Craig.B
# Description: I found sitting and starring at a computer screen too long causes stress, so I wrote this simple Stretch Alarm to remind me to get up for a minute and strech. I created a Schedule Task to Run at Logon to start the script with the following actions: Powershell.exe -WindowStyle 
# Date Published: 02-Nov-2011 10:15:51 AM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Message-Box-Stretch-Alarm-5dd116a5
# ------------------------------------------------------------------

### Configured in Scheduled Task to Run at Logon.
### Scheduled Task Actions: Powershell.exe -WindowStyle "Hidden" -noprofile -file c:\scripts\StretchAlarm.ps1

# Function: Displays the attention message box & checks to see if the user clicks the ok button.  
function Show-MessageBox ($title, $msg) {      
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null  
    [Windows.Forms.MessageBox]::Show($msg, $title, [Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information, [System.Windows.Forms.MessageBoxDefaultButton]::Button1, [System.Windows.Forms.MessageBoxOptions]::DefaultDesktopOnly) | Out-Null      
}  
# Wait X minutes then show message and play sound, repeat every X minutes once OK pressed - Loop until end of day.
Do
{
$waitMinutes = 30
$startTime = get-date
$endTime   = $startTime.addMinutes($waitMinutes)
$timeSpan = new-timespan $startTime $endTime
Start-Sleep $timeSpan.TotalSeconds

# Play System Sound
[system.media.systemsounds]::Exclamation.play()
# Display Message
Show-MessageBox Reminder "Time to Stretch"
}
# Loop until 6pm
Until ($startTime.hour -eq 18)