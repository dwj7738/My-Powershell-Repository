#--------------------------------------------------------------------------------- 
#The sample scripts are not supported under any Microsoft standard support 
#program or service. The sample scripts are provided AS IS without warranty  
#of any kind. Microsoft further disclaims all implied warranties including,  
#without limitation, any implied warranties of merchantability or of fitness for 
#a particular purpose. The entire risk arising out of the use or performance of  
#the sample scripts and documentation remains with you. In no event shall 
#Microsoft, its authors, or anyone else involved in the creation, production, or 
#delivery of the scripts be liable for any damages whatsoever (including, 
#without limitation, damages for loss of business profits, business interruption, 
#loss of business information, or other pecuniary loss) arising out of the use 
#of or inability to use the sample scripts or documentation, even if Microsoft 
#has been advised of the possibility of such damages 
#--------------------------------------------------------------------------------- 

#requires -Version 2.0

Function Set-OSCAutomaticRestart
{
    #The script need to install Windows Update 2822241, check if the Windows update installed.
    $KB2822241 = Get-HotFix -Id 'KB2822241' -ErrorAction SilentlyContinue

    If ($KB2822241 -ne $null)
    {
        #Define a initial registry key path
        $RegKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows'

        #Check if registry path exist
        If(Test-Path -Path "$RegKey\WindowsUpdate")
        {
            If(Test-Path -Path "$RegKey\WindowsUpdate\AU")
            {
                $AutoRebootValue = (Get-ItemProperty -Path "$RegKey\WindowsUpdate\AU").AlwaysAutoRebootAtScheduledTime

                Switch ($AutoRebootValue)
                {
                    0     {Set-ItemProperty -Path "$RegKey\WindowsUpdate\AU" -Name AlwaysAutoRebootAtScheduledTime `
                           -Value 1 | Out-Null; Write-Host "Successfully enabled automatic Windows Update restarts."; break}

                    $null {New-ItemProperty -Path "$RegKey\WindowsUpdate\AU" -Name AlwaysAutoRebootAtScheduleTime `
                           -Value 1 -PropertyType DWord | Out-Null; Write-Host "Successfully enabled automatic Windows Update restarts."; break}
                    
                    Default {Write-Host "You have been enabled automatic Windows Update restarts."}
                }     
            }
            Else
            {
                 New-Item -Path "$RegKey\WindowsUpdate" -Name AU | Out-Null
                 New-ItemProperty -Path "$RegKey\WindowsUpdate\AU" -Name AlwaysAutoRebootAtScheduledTime `
                 -Value 1 -PropertyType Dword | Out-Null

                 Write-Host "Successfully enabled automatic Windows Update restarts."
            }
        }
        Else
        {
            New-Item -Path $RegKey -Name WindowsUpdate | Out-Null
            New-Item -Path "$RegKey\WindowsUpdate" -Name AU | Out-Null
            New-ItemProperty -Path "$RegKey\WindowsUpdate\AU" -Name AlwaysAutoRebootAtScheduledTime `
            -Value 1 -PropertyType Dword | Out-Null

            Write-Host "Successfully enabled automatic Windows Update restarts."
        }
    }
    Else
    {
        Write-Warning "You do not install Windows Update 2822241. To force automatic restarts only after you install Windows Update 2822241."
    }
}

Set-OSCAutomaticRestart