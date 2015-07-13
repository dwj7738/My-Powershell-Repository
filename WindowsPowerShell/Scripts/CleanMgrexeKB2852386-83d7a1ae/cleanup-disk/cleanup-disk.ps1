<#----------------------------------------------------------------------------
LEGAL DISCLAIMER 
This Sample Code is provided for the purpose of illustration only and is not 
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY 
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER 
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a 
nonexclusive, royalty-free right to use and modify the Sample Code and to 
reproduce and distribute the object code form of the Sample Code, provided 
that You agree: (i) to not use Our name, logo, or trademarks to market Your 
software product in which the Sample Code is embedded; (ii) to include a valid 
copyright notice on Your software product in which the Sample Code is embedded; 
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and 
against any claims or lawsuits, including attorneys’ fees, that arise or result 
from the use or distribution of the Sample Code. 
  
This posting is provided "AS IS" with no warranties, and confers no rights. Use 
of included script samples are subject to the terms specified 
at http://www.microsoft.com/info/cpyright.htm. 


Author: Tom Moser, PFE
Date: 5/13/2014
Update1: 9/23/2014

Version 1.0
-Initial Release

Version 1.1
-Bug fixes
    -Remove Ink and Handwriting Feature
    -Fix typos in KB
    -Change test to see if hotfix is installed
-Thanks to all of the Script Center commenters for feedback!


Usage: .\Cleanup-Disk.Ps1 [-NoReboot] [-LogPath <String>]

Switch: NoReboot - Specify this switch ONLY if you DO NOT want the server to reboot
        post update. It is recommendend that you do NOT use this switch.

        LogPath - Specify this parameter with a log location to write out the script log.
                  Will default to log.txt in the script directory.

Notes: In order to schedule the script successfully, the name must remain Cleanup-Disk.ps1.
       The log file will contain all relevent information - no console output should be expected. 

Summary:
    This script requires KB2852386.

    The script itself will perform the following:
        -Verify the KB is installed 
        -Install the Desktop Experience feature 
        -Install a scheduled task that restarts the script 60 seconds after reboot 
        -Reboot, if necessary 
        -Update registry keys for cleanmgr.exe to run. 
        -Run cleanmgr.exe 
        -Reboot 
        -Remove Desktop Experience 
        -Reboot 
        -Remove scheduled task 
        -Exit 

-----------------------------------------------------------------------------#>
#Requires -RunAsAdministrator 
#Requires -Module ServerManager


Param([string]$LogPath="$(join-path $(split-path -parent $MyInvocation.MyCommand.Definition) log.txt)",      
      [switch]$NoReboot=$false)


if((get-hotfix KB2852386).HotFixID -ne "KB2852386")
{
    Write-Error "KB2852386 is required for script. Please install hotfix and re-run."
    Exit
}


#Reg Paths/Vars
Set-Variable -Name ScriptRegKey -Value "HKLM:\Software\WinSXSCleanup" -Option Constant
Set-Variable -Name ScriptRegValueName -Value "Phase" -Option Constant
Set-Variable -Name ScriptSageValueName -Value "SageSet" -Option Constant
Set-Variable -Name ScriptSpaceBeforeValue -Value "SpaceBefore" -Option Constant
Set-Variable -Name SchTaskName -Value "CleanMgr Task Cleanup" -Option Constant
Set-Variable -Name ScriptDEStatusatStart -Value "DEInstalledAtStart" -Option Constant
Set-Variable -Name ScriptInkStatusAtStart -Value "InkInstalledAtStart" -Option Constant
Set-Variable -Name UpdateCleanupPath -value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup" -Option Constant
Set-Variable -Name ServicePackCleanupPath -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup" -Option Constant
Set-Variable -Name VolumeCachesPath -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches" -Option Constant
Set-Variable -Name StateFlagClean -Value 2 -Option Constant
Set-Variable -Name StateFlagNoAction -Value 0 -Option Constant

$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#Phase Constants
Set-Variable -Name PhaseInit -Value -1 -Option Constant
Set-Variable -Name PhaseStarted -Value 0 -Option Constant
Set-Variable -Name PhaseDEInstalled -Value 1 -Option Constant
Set-Variable -Name PhaseSageSetComplete -Value 2 -Option Constant
Set-Variable -Name PhaseSageRunStarted -Value 3 -Option Constant
Set-Variable -Name PhaseSageRunComplete -Value 4 -Option Constant
Set-Variable -Name PhaseDERemoved -Value 5 -Option Constant
Set-Variable -Name PhaseTaskRemoved -Value 6 -Option Constant

#import-module
Import-Module ServerManager

#read state value, use switch statement

Function DateStamp
{
    return "$(Get-Date -UFormat %Y%m%d-%H%M%S):"
}

Function LogEntry([string]$LogData)
{
    Add-Content $LogPath "$(DateStamp) $LogData"
}

Function GetCurrentState
{
   return (Get-ItemProperty -Path $ScriptRegKey -Name $ScriptRegValueName -ErrorAction SilentlyContinue).Phase
}

Function CreateScheduledTask
{
    Param([string]$ScriptPath, 
          [string]$TaskName,
          [string]$fLogPath,
          [string]$fNoReboot=$false)
    try
    {
        $Scheduler = New-Object -ComObject "Schedule.Service"
        $Scheduler.Connect("Localhost")
        $root = $Scheduler.GetFolder("\")
        $newTask = $Scheduler.NewTask(0)
        $newTask.RegistrationInfo.Author = $TaskName
        $newTask.RegistrationInfo.Description = ""
        $newtask.Settings.StartWhenAvailable = $true
        $trigger = $newTask.Triggers.Create(8) #Trigger at boot
        $trigger.Delay = "PT60S"
        $trigger.Id = "LogonTriggerId"
        $newTask.Principal.UserId = "NT AUTHORITY\SYSTEM"
        $newTask.Principal.RunLevel = 1
        $newTask.Principal.LogonType = 5

        $action = $newtask.Actions.Create(0)
        $action.Path = "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe"
        
        if($fNoReboot -eq $true)
        {
            $action.Arguments = "-command `"$(join-path $ScriptPath cleanup-disk.ps1)`" -LogPath `"$fLogPath`" -NoReboot -NonInteractive -NoLogo -Version 2"
        }
        else
        {
            $action.Arguments = "-command `"$(join-path $ScriptPath cleanup-disk.ps1)`" -LogPath `"$fLogPath`" -NonInteractive -NoLogo -Version 2"
        }

        $root.RegisterTaskDefinition("CleanMgr Cleanup Task", $newTask, 6, "NT AUTHORITY\SYSTEM", $null , 4)
    }
    catch
    {
        LogEntry "Failed to register scheduled task." 
        LogEntry $Error[0].Exception
        throw "Failed to register scheduled task..."
    }
}
Function DeleteScheduledTask
{
    Param([string]$TaskName)
    c:\windows\system32\schtasks.exe /delete /TN "CleanMgr Cleanup Task" /f
}

Function CheckPendingReboot
{
    return Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"    
}


if(Test-Path $ScriptRegKey)
{
    $CurrentState = GetCurrentState
}
else
{
    $CurrentState = $PhaseInit
}

if(($CurrentState -eq $PhaseInit) -and (CheckPendingReboot -eq $true))
{
    Write-Host -ForegroundColor 'Red' "Reboot pending. Please reboot system and rerun script."
    LogEntry "*** Reboot pending during initial phase. Reboot and rerun script!"
}


LogEntry "CurrentState: $CurrentState"
LogEntry "NoReboot Flag: $NoReboot"

do
{
    LogEntry "**** Current State: $CurrentState"

    #Evalute current state against all possibilities.
    Switch($CurrentState)
    {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
    
    $PhaseInit
    {        
        LogEntry "Switch: Null"

        try
        {   
            #Calculate and log freespace        
            $FreeSpace = (Get-WmiObject win32_logicaldisk | where { $_.DeviceID -eq $env:SystemDrive }).FreeSpace
            if((Test-Path $ScriptRegKey) -eq $false)
            {
                New-Item -Path $ScriptRegKey
            }
            Set-ItemProperty -Path $ScriptRegKey -Name $ScriptSpaceBeforeValue -Value $FreeSpace
            LogEntry "PhaseInit: Current Free Space: $([Math]::Round(($FreeSpace / 1GB),2))GB"
            
             #Check to see if DE is already installed.            #If yes, set reg key to 1, else 0. Used to prevent DE from uninstalling unintentionally.            if((Get-WindowsFeature Desktop-Experience).Installed -eq $true)            {                Set-ItemProperty -Path $ScriptRegKey -name $ScriptDEStatusAtStart -Value 1            }            else            {                Set-ItemProperty -Path $ScriptRegKey -name $ScriptDEStatusAtStart -Value 0            }

            if((Get-WindowsFeature Ink-Handwriting).Installed -eq $true)
            {
                Set-ItemProperty -Path $ScriptRegKey -Name $ScriptInkStatusAtStart -Value 1
            }
            else
            {
                Set-ItemProperty -Path $ScriptRegKey -Name $ScriptInkStatusAtStart -Value 0
            }

            
            #Start Installing DE                        
            LogEntry "Feature: Installing Desktop Experience." 
            $FeatureResult = Add-WindowsFeature Desktop-Experience
            LogEntry "PhaseInit: Feature: ExitCode: $($FeatureResult.ExitCode)"
            LogEntry "PhaseInit: Feature: RestartRequired: $($FeatureResult.RestartNeeded)"
            LogEntry "PhaseInit: Feature: Success: $($FeatureResult.Success)"

            #If DE fails, throw error. 
            if($FeatureResult.Success -eq $false -and $FeatureResult.RestartNeeded -eq "No")
            {
                throw "PhaseInit: Failed to install Desktop Experience. This is a required feature for WinSXS Cleanup."
            }
           
            #If DE exists with no change needed or success, update reg keys. Reboot if required. Create task.
            elseif($FeatureResult.ExitCode -eq "NoChangeNeeded" -or ($FeatureResult.Success))
            {
                LogEntry "PhaseInit: Feature: Desktop Experience Installed. Updating $ScriptRegKey\$ScriptRegValueName to $PhaseStarted"
                #New-Item $ScriptRegKey -Force
                New-ItemProperty -Path $ScriptRegKey -Name $ScriptRegValueName -Value $PhaseStarted -Force
                
                if($NoReboot -eq $false -and $FeatureResult.RestartNeeded -eq "Yes")
                {                    
                    LogEntry "PhastInit: Creating Scheduled Task..."
                    CreateScheduledTask -ScriptPath $ScriptPath -TaskName $SchTaskName -fLogPath $LogPath 
                    LogEntry "PhaseInit: Created Scheduled Task $SchTaskName"                    
                    $CurrentState = GetCurrentState
                    Restart-Computer
                    Sleep 10
                }
                elseif($FeatureResult.ExitCode -eq "NoChangeNeeded")
                {
                    LogEntry "DE Already Installed. No reboot required."
                    LogEntry "PhastInit: Creating Scheduled Task..."
                    CreateScheduledTask -ScriptPath "$ScriptPath" -TaskName $SchTaskName -fLogPath $LogPath -fNoReboot "`$$NoReboot"
                    LogEntry "PhaseInit: Created Scheduled Task $SchTaskName"

                    $CurrentState = GetCurrentState
                }                
                else
                {
                    CreateScheduledTask -ScriptPath "$ScriptPath" -TaskName $SchTaskName -fLogPath $LogPath -fNoReboot "`$$NoReboot"
                    LogEntry "Phaseinit: Restart switch not specified. Please manually reboot the server to continue cleanup."
                    Exit
                }
            }
        }
        
        catch
        {
            LogEntry $error[0]
            exit
        }

        break
    }           

    $PhaseStarted
    {
      LogEntry "PhaseStarted: Verifying DE installation..."
      if((Get-WindowsFeature Desktop-Experience).Installed -eq $true) #check for pending reboot
      {
        LogEntry "PhaseStarted: DE Installed. Moving to PhaseDEInstalled."
        Set-ItemProperty -Path $ScriptRegKey -Name $ScriptRegValueName -Value $PhaseDEInstalled
      }
      Else
      {
        LogEntry "PhaseStarted: DE not installed. Resetting phase to null."
        New-ItemProperty -Path $ScriptRegKey -Name $ScriptRegValueName -Value $null
      }

      $CurrentState = GetCurrentState
      break
    }

    $PhaseDEInstalled
    {
        try
        {
            LogEntry "PhaseDEInstalled: Starting PhaseDEInstalled..."
            LogEntry "PhaseDEInstalled: Setting SagetSet..."
            #use static SageSet Value. Insert in to registry.
            $SageSet = "0010"
            Set-Variable -Name StateFlags -Value "StateFlags$SageSet" -Option Constant          
            LogEntry "PhaseDEInstalled: SageSet complete."
            LogEntry "PhaseDEInstalled: Setting VolumeCaches reg keys..."
            #Set all VolumeCache keys to StateFlags = 0 to prevent cleanup. After, set the proper keys to 2 to allow cleanup.
            $SubKeys = Get-Childitem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches
            Foreach ($Key in $SubKeys)
            {
                Set-ItemProperty -Path $Key.PSPath -Name $StateFlags -Value $StateFlagNoAction
            }

            LogEntry "PhaseDEInstalled: VolumeCaches keys set."
            LogEntry "PhaseDEInstalled: Setting UPdate and Service Pack Keys..."
            #Set all script reg values for persistence through reboots.
            Set-ItemProperty -Path $ScriptRegKey -Name $ScriptSageValueName -Value $SageSet
            Set-ItemProperty -Path $UpdateCleanUpPath -Name $StateFlags -Value $StateFlagClean
            Set-ItemProperty -Path $ServicePackCleanUpPath -Name $StateFlags -Value $StateFlagClean                                                                
            LogEntry "PhaseDEInstalled: Done." 

            #Update state key
            Set-ItemProperty -Path $ScriptRegKey -Name $ScriptRegValueName -Value $PhaseSageSetComplete
            $CurrentState = GetCurrentState
            LogEntry "PhaseDEInstalled: Complete."
        }
        
        catch
        {
            LogEntry "PhaseDEInstalled: Failed to update reg keys."
            LogEntry $Error[0].Exception
        }
        break
    }

    $PhaseSageSetComplete
    {
        LogEntry "PhaseSageSetComplete: Starting cleanmgr."
        try
        {
            $SageSet = (Get-ItemProperty -Path $ScriptRegKey -Name $ScriptSageValueName).SageSet
                        
            LogEntry "PhaseSageSetComplete: CleanMgr.exe running... "            
            $StartTime = Get-Date
            &"C:\Windows\System32\Cleanmgr.exe" + " /sagerun:$SageSet"            
            Wait-Process cleanmgr
            $EndTime = Get-Date
            LogEntry "PhaseSageSetComplete: CleanMgr.exe complete..."
            LogEntry "PhaseSageSetComplete: Seconds Elapsed: $((New-TimeSpan $StartTime $EndTime).TotalSeconds)"
            LogEntry "PhaseSageSetComplete: Updating State..."
            Set-ItemProperty -Path $ScriptRegKey -Name $ScriptRegValueName -Value $PhaseSageRunComplete
            $CurrentState = GetCurrentState
            LogEntry "PhaseSageSetComplete: Complete."
        }

        catch
        {
            LogEntry "PhaseSageSetComplete: ERROR."            
            LogEntry $Error[0].Exception
        }    
        break    
    }

    $PhaseSageRunComplete
    {
        try
        {   
            $DEStatusInit = (Get-ItemProperty -Path $ScriptRegKey -Name $ScriptDEStatusAtStart)."$ScriptDEStatusAtStart"
            $InkStatusInit = (Get-ItemProperty -Path $scriptRegKey -Name $ScriptInkStatusAtStart)."$ScriptInkStatusAtStart"

            LogEntry "PhaseSageRunComplete: Starting PhaseSageRunComplete."
            LogEntry "PhaseSageRunComplete: Getting DE Status."
            
            $DEStatus = (Get-WindowsFeature Desktop-Experience).Installed
            $InkStatus = (Get-WindowsFeature Ink-Handwriting).Installed

            if($DEStatus -and $DEStatusInit -eq 0)
            {
                $RemoveDE = $true
            }
            else
            {
                $RemoveDE = $false
            }

            if($InkStatus -and $InkStatusInit -eq 0)
            {
               $RemoveInk = $true
            }
            else
            {
                $RemoveInk = $false
            }

            LogEntry "PhaseSageRunComplete: DEInstalled = $DEStatus"
            LogEntry "PhaseSageRunComplete: DEStatus at Start was $DEStatusInit"
            LogEntry "PhaseSageRunComplete: RemoveDE is $RemoveDE"
            LogEntry "PhaseSageRunComplete: InkInstalled = $InkStatus"
            LogEntry "PhaseSageRunComplete: InkStatus at start was $InkStatusInit"
            LogEntry "PhaseSageRunComplete: RemoveInk is $RemoveInk"            


            #if($DEStatusInit -eq 1)
            if($RemoveDE -eq $false)
            {
                LogEntry "PhaseSageRunComplete: DE removal not required. Continuing..."
                Set-ItemProperty -Path $ScriptRegKey -Name $ScriptRegValueName -Value $PhaseDERemoved
                $CurrentState = GetCurrentState
            }

            #remove DE if it was not installed                       
            if($RemoveDE -eq $true)
            {                
                if($RemoveInk -eq $true)
                {       
                    LogEntry "PhaseSageRunComplete: Removing DE and Ink-Handwriting"             
                    $DEFeatureResult = (Remove-WindowsFeature Desktop-Experience,Ink-Handwriting)                                    
                }
                else
                {
                    LogEntry "PhaseSageRunComplete: Removing only DE."
                    $DEFeatureResult = (Remove-WindowsFeature Desktop-Experience)                   
                }
                           
                if($NoReboot -eq $false -and $DEFeatureResult.Success -and $DEFeatureResult.RestartNeeded -eq "Yes")
                {
                    LogEntry "PhaseSageRunComplete: Result: $($DEFeatureResult.Success)"
                    LogEntry "PhaseSageRunComplete: RestartNeeded: $($DEFeatureResult.RestartNeeded)"
                    LogEntry "PhaseSageRunComplete: Feature removed successfully."
                   
                    if($RemoveInk -eq $false)
                    { 
                        LogEntry "PhaseSageRunComplete: Rebooting..."
                        Restart-Computer -Force
                        Sleep 10
                    }
                    else
                    {
                        LogEntry "PhaseSageRunComplete: Postponing reboot to remove Ink-Handwriting..."
                    }
                   
                }
                elseif(($NoReboot -eq $false) -and ($DEFeatureResult.Success -eq $false) -and ($DEFeatureResult.RestartNeeded -eq "Yes"))
                {
                    LogEntry "PhaseSageRunComplete: Result: $($DEFeatureResult.Success)"
                    LogEntry "PhaseSageRunComplete: RestartNeeded: $($DEFeatureResult.RestartNeeded)"
                    LogEntry "PhaseSageRunComplete: Reboot already pending. Rebooting..."
                    LogEntry "PhaseSageRunComplete: Rebooting..."
                    Restart-Computer -Force
                    Sleep 10
                }
                Else
                {    
                    LogEntry "PhaseSageRunComplete: Result: $($DEFeatureResult.Success)"
                    LogEntry "PhaseSageRunComplete: RestartNeeded: $($DEFeatureResult.RestartNeeded)"                
                    LogEntry "Reboot Required: *** MANUAL REBOOT REQUIRED ***"
                    Exit
                }
            }
            elseif($DEStatus -eq $false -and $DEStatusInit -eq 0)
            {
                #DE removed, update status
                LogEntry "PhaseSageRunComplete: DE Removed. Updating status..."
                Set-ItemProperty -Path $ScriptRegKey -Name $ScriptRegValueName -Value $PhaseDERemoved
            }
            else
            {      
                LogEntry "PhaseSageRunComplete: ERROR."            
                LogEntry $Error[0].Exception
            }

            if($RemoveInk -eq $true -and $RemoveDE -eq $false)
            {
                LogEntry "PhaseSageRunComplete: Removing Ink-Handwriting"
                $InkFeatureResult = (Remove-WindowsFeature Ink-Handwriting)

                if($NoReboot -eq $false -and $InkFeatureResult.Success -and $InkFeatureResult.RestartNeeded -eq "Yes")
                {
                    LogEntry "PhaseSageRunComplete: Result: $($InkFeatureResult.Success)"
                    LogEntry "PhaseSageRunComplete: RestartNeeded: $($InkFeatureResult.RestartNeeded)"
                    LogEntry "PhaseSageRunComplete: Feature removed successfully."
                    LogEntry "PhaseSageRunComplete: Rebooting..."
                    Restart-Computer -Force
                    Sleep 10
                }
                
                elseif(($NoReboot -eq $false) -and ($InkFeatureResult.Success -eq $false) -and ($InkFeatureResult.RestartNeeded -eq "Yes"))
                {
                    LogEntry "PhaseSageRunComplete: Result: $($InkFeatureResult.Success)"
                    LogEntry "PhaseSageRunComplete: RestartNeeded: $($InkFeatureResult.RestartNeeded)"
                    LogEntry "PhaseSageRunComplete: Reboot already pending. Rebooting..."
                    LogEntry "PhaseSageRunComplete: Rebooting..."
                    Restart-Computer -Force
                    Sleep 10
                }
                else
                {    
                    LogEntry "PhaseSageRunComplete: Result: $($DEFeatureResult.Success)"
                    LogEntry "PhaseSageRunComplete: RestartNeeded: $($DEFeatureResult.RestartNeeded)"                
                    LogEntry "Reboot Required: *** MANUAL REBOOT REQUIRED ***"
                    Exit
                }              
            }
            elseif(($InkStatus -eq $false -and $InkStatusInit -eq 0) -or ($InkStatus -eq $true -and $InkStatusInit -eq 1))
            {
                #Ink removed, update status
                LogEntry "PhaseSageRunComplete: Ink Removed. Updating status..."
                Set-ItemProperty -Path $ScriptRegKey -Name $ScriptRegValueName -Value $PhaseDERemoved
            }          
            else
            {      
                LogEntry "PhaseSageRunComplete: Error removing Ink-Handwriting."            
                LogEntry $Error[0].Exception
            }

            $CurrentState = GetCurrentState

        }

        catch
        {
            LogEntry "PhaseSageRunComplete: Caught Exception."
            LogEntry "$($Error[0].Exception)"
        } 
        break       
    }

    $PhaseDERemoved
    {
        try
        {
            #Retrieving initial space
            $SpaceAtStart = (Get-ItemProperty -Path $ScriptRegKey -Name $ScriptSpaceBeforeValue)."$ScriptSpaceBeforeValue"

            #remove reg key                        
            LogEntry "PhaseDERemoved: Removing Script Reg Key."
            Remove-Item $ScriptRegKey            
            $CurrentState = $PhaseTaskRemoved
        }

        catch
        {
            LogEntry "PhaseDERemoved: ERROR."            
            LogEntry $Error[0].Exception
        }
        break
    }

   
    }

#Prevents infinite loops consuming resources.
Sleep 1

} until ($CurrentState -eq $PhaseTaskRemoved)

if($CurrentState -eq $PhaseTaskRemoved)
{
    try
    {
        LogEntry "PhaseTaskRemoved: Removing Scheduled Task"
        DeleteScheduledTask -TaskName $SchTaskName
        LogEntry "PhaseTaskRemoved: Scheduled Task Deleted."
        LogEntry "PhaseTaskRemoved: Script Complete."

        $CurrentSpace = (Get-WmiObject win32_logicaldisk | where { $_.DeviceID -eq $env:SystemDrive }).FreeSpace
        LogEntry "PhaseTaskRemoved: Current Disk Space: $([Math]::Round(($CurrentSpace / 1GB),2)) GB"
        
        $Savings = [Math]::Round(((($CurrentSpace / $SpaceAtStart) - 1) * 100),2)

$message = @"
****** CleanMgr complete.
****** Starting Free Space: $SpaceAtStart
****** Current Free Space: $CurrentSpace
****** Savings: $Savings%
****** Exiting.
"@

        LogEntry $message
   }

   catch
   {
    LogEntry "PhaseTaskRemoved: Error during PhaseTaskRemoved..."
    LogEntry $Error[0].Exception
   }

   Exit
}