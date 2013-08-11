# This powershell script is attached to a job and run at system start-up.
# It registers for SPM events and writes to a specifically created classic
# system event log that captures storage spaces events and information.
#
# Author: Tobias Klima
# Organization: Microsoft
# Last Updated: July 25, 2012
# Code Segments adapted from: Bruce Langworthy, Himanshu Kale

$LogName = "SpaceCommand Events"

# Registers for SPM Events, specifically: Arrival, Departure, Alert, and Modification.
function Register-SPMEvent
(
    [switch]$RegisterArrival,
    [switch]$RegisterDeparture,
    [switch]$RegisterAlert,
    [switch]$RegisterModification
)
{
    $SPMNamespace = "root\microsoft\windows\storage"
    if($RegisterArrival)
    {
       register-wmievent -namespace $SPMNamespace -class MSFT_StorageArrivalEvent -SourceIdentifier SPMArrival
       Write-Host "Arrival Registration Complete" -ForegroundColor Yellow
    }
    if($RegisterDeparture)
    {
       register-wmievent -namespace $SPMNamespace -class MSFT_StorageDepartureEvent -SourceIdentifier SPMDeparture
       Write-Host "Departure Registration Complete" -ForegroundColor Yellow
    }
    if($RegisterAlert)
    {
       register-wmievent -namespace $SPMNamespace -class MSFT_StorageAlertEvent -SourceIdentifier SPMAlert
       Write-Host "Alert Registration Complete" -ForegroundColor Yellow
    }
    if($RegisterModification)
    {
       register-wmievent -namespace $SPMNamespace -class MSFT_StorageModificationEvent -SourceIdentifier SPMModification
       Write-Host "Modification Registration Complete" -ForegroundColor Yellow
    }
}

# Returns all events in the queue
function Get-SPMEvent
(
    [switch]$SPMArrival,
    [switch]$SPMDeparture,
    [switch]$SPMAlert,
    [switch]$SPMModification
)
{
        if($SPMArrival)
        {
           return Get-Event -SourceIdentifier SPMArrival -ErrorAction SilentlyContinue
        }

        if($SPMDeparture)
        {
           return Get-Event -SourceIdentifier SPMDeparture -ErrorAction SilentlyContinue
        }

        if($SPMAlert)
        {
           return Get-Event -SourceIdentifier SPMAlert -ErrorAction SilentlyContinue
        }

        if($SPMModification)
        {
           return Get-Event -SourceIdentifier SPMModification -ErrorAction SilentlyContinue
        }
}

# Checks for the presence of pool, space or physical disk in the SourceClass field and constructs a corresponding message
function Create-Message
(
    $Event
)
{
    # Create a standard Message
    $Message = "Event Class: " + $Event.__Class + "`r" + "Affected Resource: " + $Event.SourceClassName + "`r" + "Resource ObjectId: " + $Event.SourceObjectId

    $ID = "`"" + $Event.SourceObjectId + "`""

    if($Event.SourceClassName -eq "MSFT_StoragePool")
    {
        $Resource = Get-StoragePool | ? {$_.ObjectId -eq $Event.SourceObjectId}
        $Message += "`r" + "Storage Pool Friendly Name: "     + $Resource.FriendlyName
        $Message += "`r" + "Storage Pool HealthStatus: "      + $Resource.HealthStatus
        $Message += "`r" + "Storage Pool OperationalStatus: " + $Resource.OperationalStatus

        return $Message
    }
    elseif($Event.SourceClassName -eq "MSFT_VirtualDisk")
    {
        $Resource = Get-VirtualDisk | ? {$_.ObjectId -eq $Event.SourceObjectId}
        $Message += "`r" + "Storage Space Friendly Name: "     + $Resource.FriendlyName
        $Message += "`r" + "Storage Space HealthStatus: "      + $Resource.HealthStatus
        $Message += "`r" + "Storage Space OperationalStatus: " + $Resource.OperationalStatus

        return $Message
    }
    elseif($Event.SourceClassName -eq "MSFT_PhysicalDisk")
    {
        $Resource = Get-PhysicalDisk | ? {$_.ObjectId -eq $Event.SourceObjectId}
        $Message += "`r" + "Physical Disk Friendly Name: "     + $Resource.FriendlyName
        $Message += "`r" + "Physical Disk HealthStatus: "      + $Resource.HealthStatus
        $Message += "`r" + "Physical Disk OperationalStatus: " + $Resource.OperationalStatus
        $Message += "`r" + "Note: A physical disk's ObjectID may change upon addition or removal from a storage pool."

        return $Message
    }
    else
    {
        return $Message
    }
}

# Register for SPM events
Register-SPMEvent -RegisterArrival
Register-SPMEvent -RegisterDeparture
Register-SPMEvent -RegisterAlert
Register-SPMEvent -RegisterModification

# Periodically check for SPM events and write them to the log if new events exist.
while($true)
{
    # Update the "Daily" Job Trigger to run again in half an hour
    Get-ScheduledJob -Name "SpaceCommand Event Monitor" | Get-JobTrigger -TriggerId 2 | Set-JobTrigger -Daily -At (Get-Date).AddMinutes(30)

    $Arrival = Get-SPMEvent -SPMArrival
    $Departure = Get-SPMEvent -SPMDeparture
    $Alert = Get-SPMEvent -SPMAlert
    $Modification = Get-SPMEvent -SPMModification

    # Get the most recent arrival events
    if($Arrival.count -gt 0)
    {
        # Get the arrival time of the most recent arrival event
        $RecentArrival = $Arrival | ? {$_.TimeGenerated -gt $TimeStamp}

        if($RecentArrival.count -gt 0)
        {
            # Loop through the events returned and write them to the log
            foreach($Event in $RecentArrival)
            {
                $Identifier = $Event.EventIdentifier

                # Convert to NewEvent
                $Event = $Event | % {$_.SourceEventArgs.NewEvent}

                # Create a Message
                $Message = Create-Message -Event $Event

                Write-EventLog -LogName $LogName -Source "SpaceCommand Events" -EventId 1 -ComputerName $Event.__Server -Message $Message
            }
        }
    }
    
    if($Departure.count -gt 0)
    {
        # Get the departure time of the most recent departure event
        $RecentDeparture = $Departure | ? {$_.TimeGenerated -gt $TimeStamp}

        if($RecentDeparture.count -gt 0)
        {
            # Loop through the events returned and write them to the log
            foreach($Event in $RecentDeparture)
            {
                $Identifier = $Event.EventIdentifier

                # Convert to NewEvent
                 $Event = $Event | % {$_.SourceEventArgs.NewEvent}

                # Create a Message
                $Message = Create-Message -Event $Event

                Write-EventLog -LogName $LogName -Source "SpaceCommand Events" -EventId 2 -ComputerName $Event.__Server -Message $Message
            }
        }
    }

    if($Alert.count -gt 0)
    {
        # Get the Alert time of the most recent Alert event
        $RecentAlert = $Alert | ? {$_.TimeGenerated -gt $TimeStamp}

        if($RecentAlert.count -gt 0)
        {
            # Loop through the events returned and write them to the log
            foreach($Event in $RecentAlert)
            {
                $Identifier = $Event.EventIdentifier

                # Convert to NewEvent
                $Event = $Event | % {$_.SourceEventArgs.NewEvent}

                # Create a Message
                $Message = Create-Message -Event $Event

                Write-EventLog -LogName $LogName -Source "SpaceCommand Events" -EventId 3 -ComputerName $Event.__Server -Message $Message
            }
        }
    }

    if($Modification.count -gt 0)
    {
        # Get the Modification time of the most recent modification event
        $RecentModification = $Modification | ? {$_.TimeGenerated -gt $TimeStamp}

        if($RecentModification.count -gt 0)
        {
            # Loop through the events returned and write them to the log
            foreach($Event in $RecentModification)
            {
                $Identifier = $Event.EventIdentifier

                # Convert to NewEvent
                $Event = $Event | % {$_.SourceEventArgs.NewEvent}

                # Create a Message
                $Message = Create-Message -Event $Event

                Write-EventLog -LogName $LogName -Source "SpaceCommand Events" -EventId 4 -ComputerName $Event.__Server -Message $Message
            }
        }
    }

    $TimeStamp = Get-Date

    sleep 60
}
