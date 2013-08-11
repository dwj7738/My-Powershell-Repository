# ------------------------------------------------------------------
# Title: Countdown Timer
# Author: Boe Prox
# Description: This is a script that will display a countdown based on the paramters used for the EndDate and Message written in PowerShell and XAML. You can specify an enddate, a message to go with the countdown, font size/color and whether a beep will be used when the countdown reaches 0 or
# Date Published: 25-Apr-2012 9:48:03 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Countdown-Timer-06ae1ce7
# Tags: WPF;Powershell;Timer
# ------------------------------------------------------------------

.\Start-CountDownTimer.ps1 -EndDate (Get-Date).AddDays(14)