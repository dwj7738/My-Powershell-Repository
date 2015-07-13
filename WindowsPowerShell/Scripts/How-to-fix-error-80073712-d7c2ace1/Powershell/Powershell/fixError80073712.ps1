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

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

#Get OS information
$version = Get-WmiObject -Class “Win32_OperatingSystem”
$item = Get-HotFix -Id KB2919355 -ErrorAction SilentlyContinue
#Check if OS is Windows 8 or RT
If($version.Caption -match "Microsoft Windows 8")
{
    #64Bit
    If($version.OSArchitecture -eq "64-bit")
    {
        if($item)
        {
            Dism /online /remove-package /packagename:Package_for_KB2919355~31bf3856ad364e35~amd64~~6.3.1.14
        }
    }
    #32Bit
    ElseIf($version.OSArchitecture -eq "64-bit")
    {
        if($item)
        {
            Dism /online /remove-package /packagename:Package_for_KB2919355~31bf3856ad364e35~x86~~6.3.1.14
        }
    }

    Dism /Online /Cleanup-image /Restorehealth

    Dism /online /cleanup-image /startcomponentcleanup

    Write-Host "Operation Done. Run Windows Update again and try to re-install KB2919355. If this script still fail to resolve your error, please contact Microsoft Support."
}
#Windows RT
ElseIf($version.Caption -match "Microsoft Windows RT")
{
    if($item)
    {
        Dism /online /remove-package /packagename:Package_for_KB2919355~31bf3856ad364e35~arm~~6.3.1.14
    }
    Dism /Online /Cleanup-image /Restorehealth

    Dism /online /cleanup-image /startcomponentcleanup

    Write-Host "Operation Done. Run Windows Update again and try to re-install KB2919355. If this script still fail to resolve your error, please contact Microsoft Support."
}
Else
{
    Write-Warning "Please run the script on Windows RT or 8"
}

cmd /c pause 