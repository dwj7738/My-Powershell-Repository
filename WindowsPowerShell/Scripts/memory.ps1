#################################################################################
# ActiveXperts Network Monitor PowerShell script, � ActiveXperts Software B.V.
# For more information about ActiveXperts Network Monitor, visit the ActiveXperts 
# Network Monitor web site at http://www.activexperts.com
#################################################################################
# Modified by David Johnson (ve3ofa - experts-exchange)

# Script:
#     Memory.ps1
# Description:
#     Checks memory usage on a (remote) computer
# Parameters:
#     1) strComputer (string)  - Hostname or IP address of the computer you want to monitor
#     2) strFlagFree (string)  - Either "free" or "used"
#     3) numLimitMB (number)   - Limit, in MB
#   # Usage:
#     .\Memory.ps1 "" " | used>" MBs " | <>"
# Sample:
#     .\Memory.ps1 "localhost" "free" 50
#     .\Memory.ps1 "localhost" "used" 50
#################################################################################
# We have 6 types of Messageboxes in Powershell -
#
#0: 	OK
#1: 	OK Cancel
#2: 	Abort Retry Ignore
#3: 	Yes No Cancel
#4: 	Yes No
#5: 	Retry Cancel

# Parameters
param
  (
    [string]$strComputer,
    [string]$strFlagFree,
    [int]$numLimitMB,
    [string]$strAltCredentials
  )

cls

# Check paramters input
if( ([string]$strComputer -eq "") -or ([string]$strFlagFree -eq "") -or ($numLimitMB -eq "") )
  {
    echo "UNCERTAIN: Invalid number of parameters - Usage: .\memory.ps1  computername ["free","used"] Memory[in MB]"
    exit
  }

# Create object
    $objMem = Get-WmiObject -ComputerName $strComputer -Class Win32_OperatingSystem

#################################################################################
# The script itself
#################################################################################
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null

if( $objMem -eq $null )
  {
    $res = "UNCERTAIN: Unable to connect. Please make sure that PowerShell and WMI are both installed on the monitered system. Also check your credentials"
    [System.Windows.Forms.MessageBox]::Show($res, "Status",0)
     
    exit
  }

$freeMB = [math]::round( ( $objMem.FreePhysicalMemory / 1024 ), 0 )
$totalMB = [math]::round( ( $objMem.TotalVisibleMemorySize / 1024 ), 0 )
$usedMB = $totalMB - $freeMB

#echo "freeMB: " $freeMB
#echo "totalMB: " $totalMB
#echo "used: " $usedMB
#[System.Windows.Forms.MessageBox]::Show("Free MB: $freemb TotalMB $totalMB Used: $usedMB", "Status",0)
# Free memory
if( $strFlagFree -eq "free" )
  {
    if( $freeMB -gt $numLimitMB )
      {
    [System.Windows.Forms.MessageBox]::Show($res, "Status",0)

        $res = "SUCCESS: Free physical memory=[" + $freeMB + " MB], minimum required=[" + $numLimitMB + " MB] DATA:" + $freeMB
         [System.Windows.Forms.MessageBox]::Show($res, "Status",0)
      }
    else
      {
        $res = "ERROR: Free physical memory=[" + $freeMB + " MB]" + "`n" + "DATA:  Minimum required=[" + $numLimitMB + " MB]" + "`n" + "DATA:" + $freeMB  + "`n" + " Please Use another Server"
    [System.Windows.Forms.MessageBox]::Show($res, "ERROR",1)     
      }
   
    exit
  }

# Used memory
if( $strFlagFree -eq "used" )
  {
    if( $usedMB -lt $numLimitMB )
      {
        $res = "SUCCESS: Used physical memory=[" + $usedMB + " MB], maximum allowed=[" + $numLimitMB + " MB] DATA: " + $usedMB 
      }
    else
      {
        $res = "ERROR: Used physical memory=[" + $usedMB + " MB], maximum allowed=[" + $numLimitMB + " MB]" + "`n" + "DATA: " + $usedMB 
        [System.Windows.Forms.MessageBox]::Show($res, "Error",1)
      }
    
    exit
  }