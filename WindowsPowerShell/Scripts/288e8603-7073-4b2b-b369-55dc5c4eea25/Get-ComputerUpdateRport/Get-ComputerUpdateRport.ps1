<#
    .SYNOPSIS
        Get-ComputerUpdateRport
    .DESCRIPTION
        This script uses two functions to get a list of computers from ActiveDirectory and then query
        each computer for a list of pending updates. It then returns selected fields from that function
        to create the report.
    .PARAMETER ADSPath
        The LDAP URI where your computers are located.
    .EXAMPLE
        .\Get-ComputerUpdateReport -ADSPath "LDAP://DC=company,DC=com" |Export-Csv -Path .\Report.CSV
        
        Description
        -----------
        This example shows sending the output to a .CSV file.
    .EXAMPLE
        .\Get-ComputerUpdateReport -ADSPath "LDAP://DC=company,DC=com"
        
        ComputerName    : scm
        KBArticleIDs    : 2512827
        RebootRequired  : False
        Title           : Security Update for Microsoft Silverlight (KB2512827)
        IsDownloaded    : True
        Description     : This security update to Silverlight includes fixes outlined in KBs 2514842 and 25
                          12827.  This update is backward compatible with web applications built using prev
                          ious versions of Silverlight.
        MaxDownloadSize : 6284664
        SupportURL      : http://go.microsoft.com/fwlink/?LinkID=105787

        Description
        -----------
        This example shows sample output
    .NOTES
        ScriptName: Get-ComputerUpdateRport
        Created By: Jeff Patton
        Date Coded: August 9, 2011
        ScriptName is used to register events for this script
        LogName is used to determine which classic log to write to
    .LINK
        https://code.google.com/p/mod-posh/wiki/Get-ComputerUpdateReport
    .LINK
        https://code.google.com/p/mod-posh/wiki/ActiveDirectoryManagement
    .LINK
        https://code.google.com/p/mod-posh/wiki/ComputerManagemenet
#>
Param
    (
        [string]$ADSPath
    )
Begin
    {
        $ScriptName = $MyInvocation.MyCommand.ToString()
        $LogName = "Application"
        $ScriptPath = $MyInvocation.MyCommand.Path
        $Username = $env:USERDOMAIN + "\" + $env:USERNAME

        New-EventLog -Source $ScriptName -LogName $LogName -ErrorAction SilentlyContinue

        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nStarted: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "100" -EntryType "Information" -Message $Message 

        #	Dotsource in the functions you need.
        . .\includes\ActiveDirectoryManagement.ps1
        . .\includes\ComputerManagement.ps1
        
        $Servers = Get-ADObjects -ADSPath $ADSPath
        $UpdateReport = @()
    }
Process
    {
        foreach ($Server in $Servers)
        {
            Try
            {
                $Updates = Get-PendingUpdates -ComputerName $Server.Properties.name

                foreach ($Update in $Updates)
                {
                    If ($Update.SupportUrl -eq $null)
                    {
                        $SupportUrl = "N/A"
                        }
                    Else
                    {
                        If ($Update.SupportUrl -like "*support.microsoft.com*")
                        {
                            If ($Update.SupportUrl.Substring($Update.SupportUrl.Length-9,9) -eq "?LN=en-us")
                            {
                                $SupportUrl = "$($Update.SupportUrl.Substring(0,$Update.SupportUrl.Length-9))kb/$($Update.KBArticleIDs)?LN=en-us"
                                }
                            Else
                            {
                                If ($Update.SupportUrl.Substring($Update.SupportUrl.Length-1,1) -eq "/")
                                {
                                    $SupportUrl = "$($Update.SupportUrl)kb/$($Update.KBArticleIDs)"
                                    }
                                Else
                                {
                                    $SupportUrl = "$($Update.SupportUrl)/kb/$($Update.KBArticleIDs)"
                                    }
                                }
                            }

                        Else
                        {
                            $SupportUrl = $Update.SupportUrl
                            }
                        }
                    $TheseUpdates = New-Object -TypeName PSObject -Property @{
                        ComputerName = "$($Server.Properties.name)"
                        Title = $Update.Title
                        Description = $Update.Description
                        RebootRequired = $Update.RebootRequired
                        IsDownloaded = $Update.IsDownloaded
                        MaxDownloadSize = $Update.MaxDownloadSize
                        SupportURL = $SupportUrl
                        KBArticleIDs = "$($Update.KBArticleIDs)"
                        }
                    $UpdateReport += $TheseUpdates
                    }
                }
            Catch
            {
                }    
            }
    }
End
    {
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "100" -EntryType "Information" -Message $Message

        Return $UpdateReport
    }
