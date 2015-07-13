
Param (
	[ValidateSet("Install","Uninstall")] 
	[string]$DeploymentType = "Install",
	[ValidateSet("Interactive","Silent","NonInteractive")]
	[string]$DeployMode = "silent",
	[switch] $AllowRebootPassThru = $False,
	[switch] $TerminalServerMode = $false,
    [switch] $ForceRestartMode = $True,
    [Parameter(Mandatory=$true)]
    [int] $Updatesince = 1
)

#*===============================================
#* VARIABLE DECLARATION
Try {
#*===============================================

#*===============================================
# Variables: Application

$appVendor = "UOA"
$appName = "Install or Uninstall Windows Updates"
$appVersion = [version]"1.0"
$appArch = ""
$appLang = "EN"
$appRevision = "01"
$appScriptVersion = "1.0.0"
$appScriptDate = "02/07/2014"
$appScriptAuthor = "Topaz Paul"

#*===============================================
# Variables: Script - Do not modify this section

$deployAppScriptFriendlyName = "Deploy Application"
$deployAppScriptVersion = [version]"3.1.2"
$deployAppScriptDate = "04/30/2014"
$deployAppScriptParameters = $psBoundParameters

# Variables: Environment
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
# Dot source the App Deploy Toolkit Functions
."$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
."$scriptDirectory\SupportFiles\Get-ApplicationInfo.ps1"
."$scriptDirectory\SupportFiles\Get-PendingReboot.ps1"
."$scriptDirectory\SupportFiles\Get-ScheduledTask.ps1"
."$scriptDirectory\SupportFiles\Get-UOAHotfix.ps1"


#*===============================================
#* END VARIABLE DECLARATION
#*===============================================

#*===============================================
#* PRE-INSTALLATION
If ($deploymentType -ne "uninstall") { $installPhase = "Pre-Installation"
#*===============================================

function Get-WIAStatusValue($value)
{
   switch -exact ($value)
   {
      0   {"NotStarted"}
      1   {"InProgress"}
      2   {"Succeeded"}
      3   {"SucceededWithErrors"}
      4   {"Failed"}
      5   {"Aborted"}
   } 
}

#*===============================================
#* INSTALLATION 
$installPhase = "Installation"
#*===============================================

    # Is reboot pending
    
    if ($(Get-PendingReboot).RebootPending) {  
        
            Write-Log "The system is pending reboot from a previous install or uninstall."
        
    }
    

    # Prompt the user if not silent mode:
    
    Show-InstallationWelcome -AllowDefer -DeferTimes 3 -CloseAppsCountdown "120"
    
    # Show Progress Message (with the default message)
    
    Show-InstallationProgress -StatusMessage "Installing Security Updates. Please Wait..." 
    
    if ((Get-Service -Name wuauserv).Status -ne "Running"){
    
        Write-Log "WSUS Service is stopped: Restarting the service"
        
        Set-Service  wuauserv -StartupType Automatic
        
        Start-Service -name wuauserv
    }

	$needsReboot = $false
    
	$UpdateSession = New-Object -ComObject Microsoft.Update.Session
    
	$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
 
	Write-Log " - Searching for Updates"
    
	$SearchResult = ($UpdateSearcher.Search("IsAssigned=1 and IsHidden=0 and IsInstalled=0")).Updates
    
    Write-Log "$($SearchResult.Count) updates in total. But checking for assigned updates in the last $Updatesince days."

    $SearchResult = $SearchResult | Where-Object {$_.LastDeploymentChangeTime -gt ((Get-Date).Adddays(-$Updatesince))}
    
    if (!($SearchResult)) {
    
        Write-Log "0 updates have been assigned to this machine in the last $Updatesince days."
        
        Exit-Script -ExitCode 0
    
    }
    
    Write-Log "$($SearchResult.Count) updates in the last $Updatesince days. Starting to install $($SearchResult.Count) updates..."
    
    $SearchResult = $SearchResult | Sort-Object LastDeploymentChangeTime -Descending # Sort updates
    
 
	foreach($Update in $SearchResult) {
    
		# Add Update to Collection
		$UpdatesCollection = New-Object -ComObject Microsoft.Update.UpdateColl
        
		if ( $Update.EulaAccepted -eq 0 ) { $Update.AcceptEula() }
        
		$UpdatesCollection.Add($Update)
 
		# Download
		Write-Log " + Downloading - $($Update.Title)"
        
		$UpdatesDownloader = $UpdateSession.CreateUpdateDownloader()
        
		$UpdatesDownloader.Updates = $UpdatesCollection
        
        $UpdatesDownloader.Priority = 3
        
		$DownloadResult = $UpdatesDownloader.Download()
        
		$Message = "   - Download {0}" -f (Get-WIAStatusValue $DownloadResult.ResultCode)
        
		Write-Log "$message" 
 
		# Install
		Write-Log "   - Installing Update"
        
		$UpdatesInstaller = $UpdateSession.CreateUpdateInstaller()
        
		$UpdatesInstaller.Updates = $UpdatesCollection
        
		$InstallResult = $UpdatesInstaller.Install()
        
		$Message = "   - Install {0}" -f (Get-WIAStatusValue $DownloadResult.ResultCode)
        
		Write-Log "$message"
 
		$needsReboot = $installResult.rebootRequired
        
        if ((Get-Service -Name wuauserv).Status -ne "Running"){
        
            Write-Log "WSUS Service is stopped: Restarting the service"
            
            Set-Service  wuauserv -StartupType Automatic
            
            Start-Service -name wuauserv
        }
        
	}
 
	if (($needsReboot) -or ($(Get-PendingReboot).RebootPending)) {
    
        Write-Log "Reboot required: One or more of the installed update(s) require a reboot"
        
        if ($DeployMode -match "silent") {
        
            Write-Log "Deployment mode is SILENT. Forcing a reboot without any notification"
        
            restart-computer -Force
        
        } else {
        
            Write-Log "Deployment mode is INTERACTIVE. The script Will notify user about the reboot"
        
            Show-InstallationRestartPrompt -Countdownseconds 600 -CountdownNoHideSeconds 60
        
        }
	}

#*===============================================
#* POST-INSTALLATION
$installPhase = "Post-Installation"
#*===============================================
 
       

#*===============================================
#* UNINSTALLATION
} ElseIf ($deploymentType -eq "uninstall") { $installPhase = "Uninstallation"
#*===============================================

    # Prompt the user to close the following applications if they are running:
    
    Show-InstallationWelcome -AllowDefer -DeferTimes 3 -CloseAppsCountdown "120"
    
    # Show Progress Message (with a message to indicate the application is being uninstalled)
    
    Show-InstallationProgress -StatusMessage "Uninstalling Security Updates. Please Wait..." 
    
    if ((Get-Service -Name wuauserv).Status -ne "Running"){
    
        Write-Log "WSUS Service is stopped: Restarting the service"
        
        Set-Service  wuauserv -StartupType Automatic
        
        Start-Service -name wuauserv
    }
    
    $Updates = ((New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()).Search("IsInstalled = 1").Updates # Retrieve installed updates
    
    Write-Log "$($Updates.Count) updates total"

    #$Updates = $Updates | Where-Object {$_.LastDeploymentChangeTime -gt ((Get-Date).Adddays(-$Updatesince))}
    
    $Updates = Get-UOAHotfix|Where-Object {$_.Installedon -gt ((Get-Date).Adddays(-$Updatesince))}
    
    $Updates = $Updates | Sort-Object Installedon -Descending # Sort updates
    
     if (!($Updates)) {
    
        Write-Log "0 updates have been installed on this machine in the last $Updatesince days."
        
        Exit-Script -ExitCode 0
    
    }
    
    Write-Log "$($Updates.Count) updates in the last $Updatesince days. Starting to Uninstall $($Updates.Count) updates..."

    Foreach($Update in $Updates) {
    
        if ((Get-Service -Name wuauserv).Status -ne "Running"){
        
            Write-Log "WSUS Service is stopped: Restarting the service"
            
            Set-Service  wuauserv -StartupType Automatic
            
            Start-Service -name wuauserv
        }
    
    	$ID = $($Update.HotFixID -replace 'KB', '')

    	Write-Log "Removing KB$ID"

    	Invoke-Expression "wusa.exe /uninstall /kb:$ID /quiet /log /norestart"

    	while (@(Get-Process wusa -ErrorAction SilentlyContinue).Count -ne 0) { Start-Sleep 1 }
    }
    
    
    if ($(Get-PendingReboot).RebootPending) {
    
        Write-Log "Reboot required: One or more of the Uninstalled update(s) require a reboot"
        
        if ($DeployMode -match "silent") {
        
            Write-Log "Deployment mode is SILENT. Forcing a reboot without any notification"
        
            restart-computer -Force
        
        } else {
        
            Write-Log "Deployment mode is INTERACTIVE. The script Will notify user about the reboot"
        
            Show-InstallationRestartPrompt -Countdownseconds 600 -CountdownNoHideSeconds 60
        
        }
	}
     

#*===============================================
#* END SCRIPT BODY
} } Catch {$exceptionMessage = "$($_.Exception.Message) `($($_.ScriptStackTrace)`)"; Write-Log "$exceptionMessage"; Exit-Script -ExitCode 1} # Catch any errors in this script 

Exit-Script -ExitCode 0 # Otherwise call the Exit-Script function to perform final cleanup operations
#*===============================================