#PowerShell Script Containing Function Used to Retrieve All Windows Updates from a Local Computer
#Developer: Andrew Saraceni (saraceni@wharton.upenn.edu)
#Date: 2/9/15

#Requires -Version 2.0

function Get-WindowsUpdate
{
    <#
    .SYNOPSIS
    Retrieves all Windows updates from a local computer.
    .DESCRIPTION
    Gathers and builds a proper PSObject of all installed Windows 
    updates, hotfixes, etc.  Specifically, this includes updates to 
    both native components of the OS, and non-native (e.g. Microsoft 
    Office).  Each update is viewable by an associated array index, 
    with property values viewable via dot syntax.
    .EXAMPLE
    Get-WindowsUpdate
    Retrieve all Windows updates from the local computer.
    .NOTES
    Properties of each update were obtained/derived from the 
    following IUpdateHistoryEntry interface:

    https://msdn.microsoft.com/en-us/library/windows/desktop/aa386400(v=vs.85).aspx

    The following property values are not included in the cmdlet 
    output due to either often returning null or little useful 
    information, or their ComObject data being unboxed to more 
    visible property values:

    Categories
    ServiceID
    UninstallationSteps
    UpdateIdentity

    Additionally, updates retrieved via this cmdlet include only 
    those installed through Windows Update, Microsoft Update, or 
    the Automatic Updates feature.  Updates installed via 
    enterprise update management systems (e.g. WSUS) are included, 
    however manually installed updates are not included.

    More information can be found at the following link:
    http://social.technet.microsoft.com/wiki/contents/articles/4197.how-to-list-all-of-the-windows-and-software-updates-applied-to-a-computer.aspx
    #>
    
    [CmdletBinding()]
    param()
    
    $updateOperation = @{
        1 = "Installation"
        2 = "Uninstallation"
    }

    $operationResultCode = @{
        0 = "NotStarted"
        1 = "InProgress"
        2 = "Succeeded"
        3 = "SucceededWithErrors"
        4 = "Failed"
        5 = "Aborted"
    }
        
    $serverSelection = @{
        0 = "Default"
        1 = "ManagedServer"
        2 = "WindowsUpdate"
        3 = "Others"
    }

    $updateSession = New-Object -ComObject Microsoft.Update.Session

    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $historyCount = $updateSearcher.GetTotalHistoryCount()
    $comObjects = $updateSearcher.QueryHistory(0, $historyCount)

    $windowsUpdates = New-Object -TypeName System.Collections.ArrayList

    foreach ($comObject in $comObjects)
    {
        $updateProperties = @{
            ClientApplicationID = $comObject.ClientApplicationID
            Date = $comObject.Date
            Description = $comObject.Description
            HResult = $comObject.HResult
            Operation = $updateOperation.Get_Item($($comObject.Operation))
            ResultCode = $operationResultCode.Get_Item($($comObject.ResultCode))
            RevisionNumber = $comObject.UpdateIdentity.RevisionNumber
            ServerSelection = $serverSelection.Get_Item($($comObject.ServerSelection))
            SupportURL = $comObject.SupportUrl
            Title = $comObject.Title
            UninstallationNotes = $comObject.UninstallationNotes
            UnmappedResultCode = $comObject.UnmappedResultCode
            UpdateID = $comObject.UpdateIdentity.UpdateID
        }
            
        $windowsUpdate = New-Object -TypeName PSObject -Property $updateProperties
        [Void]$windowsUpdates.Add($windowsUpdate)
    }

    return $windowsUpdates
}