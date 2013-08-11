<#
    .SYNOPSIS
        Return free space on disk
    .DESCRIPTION
        This script works in conjunction with an Event Trigger on the System
        event on our file servers. This script queries the System log for 
        EventID 2013, and returns the drive letter from the most recent 
        event. 
        
        This should be the same event that triggered this script to
        run in the first place.
        
        It outputs an XML file to the StorageReports directory which exists 
        on both nodes of the file server cluster.
    .PARAMETER FileName
        The fully qualified path and filename for the report.
    .EXAMPLE
        Get-FreeDiskSpace.ps1
        
        Description
        -----------
        This is the only syntax for this script.
    .NOTES
        ScriptName: Get-FreeDiskSpace.ps1
        Created By: Jeff Patton
        Date Coded: July 12, 2011
        ScriptName is used to register events for this script
        LogName is used to determine which classic log to write to
    .LINK
        https://code.google.com/p/mod-posh/wiki/Get-FreeDiskSpace
#>
Param
    (
        $FileName = "DiskSpace-$((get-date -format "yyyMMdd-hhmmss")).xml"
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
    }
Process
    {
        $Event2013 = Get-WinEvent -LogName System |Where-Object {$_.id -eq 2013}
       # if ($Event2013.Count -le 0) OR ($Event2013.Count -eq "NULL"))
       # {
       #     $LowDisk = ($Event2013.Message.TrimStart("The ")).TrimEnd(" disk is at or near capacity.  You may need to delete some files.")
       #     }
       # else
       # {
       #     $LowDisk = ($Event2013[0].Message.TrimStart("The ")).TrimEnd(" disk is at or near capacity.  You may need to delete some files.")
       #     }

        $DiskSpace = [math]::round(((Get-WmiObject -Class win32_LogicalDisk |Where-Object{$_.DeviceId -eq $LowDisk}).FreeSpace /1024 /1024 /1024),3)

        $Report = New-Object -TypeName PSObject -Property @{
            Drive = $LowDisk
            FreeSpace = $DiskSpace
            }
    }
End
    {
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "100" -EntryType "Information" -Message $Message
        Export-Clixml -Path "C:\StorageReports\$($FileName)" -InputObject $Report
    }