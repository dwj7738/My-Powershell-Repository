function Invoke-WindowsUpdate
{
    <#
    .EXTERNALHELP Microsoft.PowerShell.Workflow.ServiceCore.dll-help.xml
    #>
    [CmdletBinding(
    DefaultParameterSetName='Install',
    SupportsShouldProcess=$True,
    ConfirmImpact='High')]

    PARAM(

        [Parameter(ParameterSetName='Install')]
        [switch]
        $Force,

        [Parameter(ParameterSetName='Install')]
        [switch]
        $Reboot,

        [Parameter(ParameterSetName='DownloadOnly')]
        [switch]
        $DownloadOnly

    )

    Begin
    {
        #Check for pending reboot status
        $RebootRequired = (New-Object -ComObject "Microsoft.Update.SystemInfo").rebootrequired

        #Admin Rights Check
        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        $isAdmin = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        if(!$isAdmin){Write-Warning "PHASE 0 (PRE-CHECKS): Cmdlet is not being run with Administrative Priveledges.`n`t`t If the cmdlet does not function as expected, try running with Administrative Rights"}

        #Check if reboot is pending and if parameter set is NOT DownloadOnly
        if($RebootRequired -and !$DownloadOnly)
        {
            Write-Warning "PHASE 0 (PRE-CHECKS): A reboot is currently pending.`n`t`t If the -Force parameter is not set, updates will only be downloaded"

            #Check for -Force switch parameter
            if($Force)
            {
                Write-Verbose "PHASE 0 (PRE-CHECKS): -Force parameter is set.`n`t`t Update installs will be attempted"
            }
            else
            {
                Write-Warning "PHASE 0 (PRE-CHECKS): -Force parameter is NOT set.`n`t`t Updates will only be downloaded"
                $DownloadOnly = $True
            }
        }

        #Create Windows Update Session, Searcher, Downloader, and Installer Com Objects
        $WUSession = new-object -ComObject Microsoft.Update.Session
        $WUSearcher = $WUSession.CreateUpdateSearcher()
        $WUDownloader = $WUSession.CreateUpdateDownloader() #Bug doesn't allow this to be run remotely
        $WUInstaller = $WUSession.CreateUpdateInstaller() #Bug doesn't allow this to be run remotely
        $WUUpdateCollection = New-Object -ComObject Microsoft.Update.UpdateColl

        $Return = New-Object PSObject -Property @{
            AttemptedDownloads = New-Object -ComObject Microsoft.Update.UpdateColl
            AttemptedInstalls = New-Object -ComObject Microsoft.Update.UpdateColl
            SuccessfulDownloads = New-Object -ComObject Microsoft.Update.UpdateColl
            SuccessfulInstalls = New-Object -ComObject Microsoft.Update.UpdateColl
            UnsuccessfulDownloads = New-Object -ComObject Microsoft.Update.UpdateColl
            UnsuccessfulInstalls = New-Object -ComObject Microsoft.Update.UpdateColl
        }
        
        if(!(Get-TypeData ResultCode))
        {
            Add-Type -TypeDefinition @"
            public enum ResultCode
            {
               NotStarted = 0,
               InProgress = 1,
               Succeeded = 2,
               SucceededWithErrors = 3,
               Failed = 4,
               Aborted = 5
            }
"@
        }
    }#end Begin

    Process
    {

    #######################
    # DOWNLOAD PHASE BEGIN
    #region downloadphase
    #######################

        #Function to download udpates
        function DownloadUpdates
        {
            Write-Verbose "PHASE I (DOWNLOAD): Downloading Available Update(s)"

            $Return.AttemptedDownloads = $WUDLUpdates

            Foreach($Update in $WUDLUpdates)
            {
                Write-Progress -Id 0 -Activity "Downloading Updates" -Status "Downloading KB$($Update.KBArticleIDs)" -CurrentOperation "Description: $($Update.description)" -PercentComplete ((($count++)/($UpdateCount))*100)

                #Clear Update Collection ; Add download to download collection ; Add download to Downloader
                $WUUpdateCollection.Clear()
                $WUUpdateCollection.Add($Update) | out-null
                $WUDownloader.Updates = $WUUpdateCollection

                #Run downloader to Download undownloaded download :-)
                $WUDownloadResults = $WUDownloader.Download()

                if($WUDownloadResults.resultcode -ne [ResultCode]::Succeeded)
                {
                    Write-Warning "PHASE I (DOWNLOAD): The Windows Update Downloader Returned a Result of $([ResultCode]$WUDownloadResults.ResultCode) for $($Update.KBArticleIDs).`n`t`t Update may not have downloaded correctly"
                    $Return.UnsuccessfulDownloads.Add($Update) | Out-Null
                }
                else
                {
                    Write-Verbose "PHASE I (DOWNLOAD): Update $count of $UpdateCount has been downloaded successfully"

                    $Return.SuccessfulDownloads.Add($Update) | Out-Null
                }
            }
            Write-Progress -Id 0 -Activity 'Downloading Updates' -Completed
        }

        try
        {
            Write-Verbose "PHASE I (DOWNLOAD): Checking for Available Updates to Download"

            #Search for updates that haven't been installed
            $WUSearchResults = $WUSearcher.Search("IsInstalled=0")

            #Check to make sure Searcher succeeded
            if($WUSearchResults.ResultCode -ne [ResultCode]::Succeeded)
            {
                #Determine Terminating v Non-Terminating response
                if($WUSearchResults.ResultCode -eq [ResultCode]::SucceededWithErrors)
                {
                    Write-Error "PHASE I (DOWNLOAD): Windows Update Searcher Returned a Result of 'SucceededWithErrors.'`n`t`t Windows Update process may not work as expected"
                }
                else
                {
                    Throw "PHASE I (DOWNLOAD): Windows Update Searcher Returned a Result of $([ResultCode]$WUSearchResults.ResultCode).`n`t`t Terminating Cmdlet"
                }
            }

            #Gather updates that haven't been downloaded
            $WUDLUpdates = $WUSearchResults.Updates | ?{$_.IsDownloaded -eq $false}

            Write-Debug "`$WUDLUpdates.count = $($WUDLUpdates.count)"

            #Check to see if/how many updates need to be downloaded
            if($WUDLUpdates.count -eq 0)
            {
                Write-Verbose "PHASE I (DOWNLOAD): No New Updates Available for Download"
                Write-Verbose "PHASE I (DOWNLOAD): Moving to Next Phase"
            }
            #Windows Update returns a null value when there is only 1 update! WTH, MS!
            elseif($WUDLUpdates.count -eq $null)
            {
                Write-Verbose "PHASE I (DOWNLOAD): 1 New Update(s) Available for Download"
                $UpdateCount = 1

                #Run function to download updates
                DownloadUpdates
            }
            else
            {
                Write-Verbose "PHASE I (DOWNLOAD): $($WUDLUpdates.count) New Update(s) Available for Download"
                $UpdateCount = $WUDLUpdates.count

                #Run function to download updates
                DownloadUpdates
            }
        }
        catch
        {
            Write-Warning "Error Detected"
            Return $Error[0]
            $Error[0]
            break
        }
        finally
        {
            Write-Verbose "PHASE I (DOWNLOAD): Download Phase Complete"
        }

        

    #######################
    #endregion
    # DOWNLOAD PHASE END
    #######################

    #######################
    # INSTALL PHASE BEGIN
    #region installphase
    #######################

        #Function to install udpates
        function InstallUpdates
        {
            if($Force -or $PSCmdlet.ShouldContinue("Install Pending Updates?","$UpdateCount Windows Updates are Pending Installation"))
            {
                Write-Verbose "PHASE II (INSTALL): Installing Available Updates"

                $Return.AttemptedInstalls = $WUInstallUpdates

                Foreach($Update in $WUInstallUpdates)
                {
                    Write-Progress -Id 1 -Activity "Installing Updates" -Status "Installing KB$($Update.KBArticleIDs)" -CurrentOperation "Description: $($Update.description)" -PercentComplete ((($count++)/($UpdateCount))*100)

                    #Clear Update Collection ; Add update to install collection ; Add update to Installer
                    $WUUpdateCollection.Clear()
                    $WUUpdateCollection.Add($Update) | out-null
                    $WUInstaller.Updates = $WUUpdateCollection

                    #Run Installer to install uninstalled installs :-)
                    $WUInstallResults = $WUInstaller.Install()

                    if($WUInstallResults.resultcode -ne [ResultCode]::Succeeded)
                    {
                        Write-Warning "The Windows Update Installer Returned a Result of $([ResultCode]$WUInstallResults.ResultCode) for $($Update.KBArticleIDs)`n`t`t Update may not have installed correctly"
                        $Return.UnsuccessfulInstalls.Add($Update) | Out-Null
                    }
                    else
                    {
                        Write-Verbose "PHASE II (INSTALL): Update $count of $UpdateCount has been installed successfully"
                        $Return.SuccessfulInstalls.Add($Update) | Out-Null
                    }
                }
                Write-Progress -Id 1 -Activity 'Installing Updates' -Completed
            }
            else
            {
                Throw "PHASE II (INSTALL): Installation Canceled - ShouldContinue not Confirmed"
            }
        }

        if(!$DownloadOnly)
        {
            try
            {
                Write-Verbose "PHASE II (INSTALL): Checking for Available Updates to Install"

                #Search for updates that haven't been installed
                $WUSearchResults = $WUSearcher.Search("IsInstalled=0")

                #Check to make sure Searcher succeeded
                if($WUSearchResults.ResultCode -ne [ResultCode]::Succeeded)
                {
                    #Determine Terminating v Non-Terminating response
                    if($WUSearchResults.ResultCode -eq [ResultCode]::SucceededWithErrors)
                    {
                        Write-Error "PHASE II (INSTALL): Windows Update Searcher Returned a Result of 'SucceededWithErrors.'`n`t`t Windows Update process may not work as expected"
                    }
                    else
                    {
                        Throw "PHASE II (INSTALL): Windows Update Searcher Returned a Result of $([ResultCode]$WUSearchResults.ResultCode).`n`t`t Terminating Script"
                    }
                }

                #Gather any updates that haven't been installed
                $WUInstallUpdates = $WUSearchResults.Updates | ?{$_.isdownloaded -eq $true}

                #Check to see if/how many updates need to be installed
                if($WUInstallUpdates.count -eq 0)
                {
                    Write-Verbose "PHASE II (INSTALL): No New Updates Available for Install"
                    Write-Verbose "PHASE II (INSTALL): Moving to Next Phase"
                }
                #Windows Update returns a null value when there is only 1 update! WTH, MS!
                elseif($WUInstallUpdates.count -eq $null)
                {
                    Write-Verbose "PHASE II (INSTALL): 1 New Update(s) Available for Install"
                    $UpdateCount = 1

                    InstallUpdates
                }
                else
                {
                    Write-Verbose "PHASE II (INSTALL): $($WUInstallUpdates.count) New Update(s) Available for Install"
                    $UpdateCount = $WUInstallUpdates.count

                    InstallUpdates
                }
            }
            catch
            {
                Write-Warning "Error Detected"
                Return $Error[0]
                $Error[0]
                break
            }
            finally
            {
                Write-Verbose "PHASE II (INSTALL): Install Phase Complete"
            }
        }
        else
        {
            Write-Verbose "PHASE II (INSTALL): The DownloadOnly switch is set.`n`t`t Skipping Installation Phase"
        }

    #######################
    #endregion
    # INSTALL PHASE END
    #######################

    }#End Process

    End
    {
        #Check for pending reboot status
        $RebootRequired = (New-Object -ComObject "Microsoft.Update.SystemInfo").rebootrequired

        #Change ending behavior depending on -Reboot switch
        if($Reboot -and $RebootRequired)
        {
            Write-Verbose "PHASE III (REBOOT): -Reboot parameter is set.`n`t`t Rebooting system"
            Restart-Computer -Force
            Return $Return
        }
        else
        {
            Write-Verbose "PHASE III (CLEANUP): Cmdlet complete"
            Return $Return
        }
    }
}

Export-ModuleMember -Function Invoke-WindowsUpdate