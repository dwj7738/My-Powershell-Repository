<####################################################################################################################################################
 #  This script enables a user to diagnose errors caused by a DSC operation. In short, the following commands would help you diagnose errors
 #  To get the last 10 operations in DSC that show their Result status (failure , success)         : Get-xDscOperation
 #  To get a list of last n (say, 13) DSC operations                                             : Get-xDscOperation -Newest 13
 #  To see details of the last operation                                                         : Trace-xDscOperation
 #  TO view trace details of the third last operation run                                        : Trace-xDscOperation 3
 #  To view trace details of an operation with Job ID $jID                                       : Trace-xDscOperation -JobID $jID
 #  To View trace details of multiple computers                                                  : Trace-xDscOperation -ComputerName @("PN25113D0891","PN25113D0890") 
 #  To enable the debug event channel for DSC                                                    : Update-xDscEventLogStatus -Channel Debug -Status Enabled
 #  To enable the analytic event channel for DSC on another computer (say, with name ABC)        : Update-xDscEventLogStatus -Channel Analytic -Status Enabled -ComputerName ABC
 #  To disable the analytic event channel for DSC on another computer (say, with name ABC)       : Update-xDscEventLogStatus -Channel Analytic -Status Disabled -ComputerName ABC
 #####################################################################################################################################################>

#region Global variables

 $Script:DscVerboseEventIdsAndPropertyIndex = @{4100 = 3;4117 = 2;4098 = 3};
 $Script:DscLogName = "Microsoft-windows-dsc"
 $Script:RedirectOutput = $false
 $Script:TemporaryHtmLocation = "$env:TEMP/dscreport"
 $Script:SuccessResult = "Success"
 $Script:FailureResult = "Failure"
 $Script:ThisCredential = ""
 $Script:ThisComputerName = $env:COMPUTERNAME
 $Script:UsingComputerName = $false
 $Script:FormattingFile = "xDscDiagnosticsFormat.ps1xml"
 $Script:RunFirstTime = $true
 
#endregion

#region Cache for events
 $Script:LatestGroupedEvents = @{} #Hashtable of "Computername", "GroupedEvents"
 $Script:LatestEvent = @{}          #Hashtable of "ComputerName", "LatestEvent logged"

#endregion

#region Exported Functions

 <#####################################################################################################################################################
.SYNOPSIS 
Traces through any DSC operation selected from among all operations using its unique sequence ID (obtained from Get-xDscOperation), or from its unique Job ID

.DESCRIPTION
This function, when called, will look through all the event logs for DSC, and output the results in the form of an object, that contains the event type, event message, time created, computer name, job id, sequence number, and the event information. 


.PARAMETER SequenceId
Each operation in DSC has a certain Sequence ID, ordered by time of creation of these DSC operations. The sequence IDs can be obtained by running Get-xDscOperation
By mentioning a sequence ID, the trace of the corresponding DSC operation is output.

.PARAMETER JobId
The event viewer shows each DSC event start with a unique job ID for each operation. If this job id is specified with this parameter, then all diagnostic messages displayed are taken from the dsc operation pertaining to this job id.


.PARAMETER ComputerName
The names of computers in which you would like to trace the past DSC operations


.PARAMETER Credential
The credential needed to access the computers specified inside ComputerName parameters

.EXAMPLE
To Obtain the diagnostic information for the latest operation                : 
Trace-xDscOperation 
.EXAMPLE
To obtain the diagnostic information for the third latest operation          : 
Trace-xDscOperation -sequenceId 3
.EXAMPLE
To diagnose an operation with job Id 11112222-1111-1122-1122-111122221111    : 
Trace-xDscOperation -JobId 11112222-1111-1122-1122-111122221111
.EXAMPLE
To Get Logs from a remote computer                                           : 
Trace-xDscOperation -ComputerName XYZ -sequenceID 2

To Get logs from a remote computer with credentials                          : 
Trace-xDscOperation -Computername XYZ -Credential $mycredential -sequenceID 2

To get logs from multiple remote computers                                   : 
Trace-xDscOperation -ComputerName @("PN25113D0891" , "PN25113D0890")
Please note that to perform actions on the remote computer , have the firewall for remote configuration enabled. This can be done with the following command:
C:> New-NetFirewallRule -Name "Service RemoteAdmin" -Action Allow

#####################################################################################################################################################>
function Trace-xDscOperation
{
    
    [cmdletBinding()]
    param(
        [UInt32]$SequenceID = 1, #latest is by default
        [Guid]$JobId,
        [String[]]$ComputerName,
        [pscredential]$Credential)
    Add-ClassTypes
    if($ComputerName)
    {
        $Script:UsingComputerName = $true  
        $args = $PSBoundParameters
        $null = $args.Remove("ComputerName")
        $null = $args.Remove("Credential")
            
       foreach($thisComputerName in $ComputerName)
       {
            LogDscDiagnostics -Verbose "Gathering logs for Computer $thisComputerName ..."
            $Script:ThisComputerName = $thisComputerName
            $Script:ThisCredential = $Credential
            Trace-DscOperationInternal  @PSBoundParameters
            
       }
    }
    else
    {
        $Script:ThisComputerName = $env:COMPUTERNAME
        Trace-DscOperationInternal @PSBoundParameters
         $Script:UsingComputerName = $false  
    }
}
 
  <#####################################################################################################################################################
.SYNOPSIS 
Gives a list of all DSC operations that were executed . Each DSC operation has sequence Id information , and job id information
It returns a list of objects, each of which contain information on a distinct DSC operation . Here a DSC operation is referred to any single DSC execution, such as start-dscconfiguration, test-dscconfiguration etc. These will log events with a unique jobID (guid) identifying the DSC operation. 

When you run Get-xDscOperation, you will see a list of past DSC operations , and you could use the following details from the output to trace any of them individually.
- Job ID : By using this GUID, you can search for the events in Event viewer, or run Trace-xDscOperation -jobID <required Jobid> to obtain all event details of that operation
- Sequence Id : By using this identifier, you could run Trace-xDscOperation <sequenceId> to get all event details of that particular dsc operation.


.DESCRIPTION
This will list all the DSC operations that were run in the past in the computer. By Default, it will list last 10 operations. 

.PARAMETER Newest
By default 10 last DSC operations are pulled out from the event logs. To have more, you could use enter another number with this parameter.a PS Object with all the information output to the screen can be navigated by the user as required.


.EXAMPLE
PS C:\> Get-xDscOperation 20 #Lists last 20 operations
PS C:\> Get-xDscOperation -ComputerName @("XYZ" , "ABC") -Credential $cred #Lists operations for the array of computernames passed in.
#####################################################################################################################################################>

function Get-xDscOperation
{
    [cmdletBinding()]
    param(
        [UInt32]$Newest = 10, 
        [String[]]$ComputerName,
        [pscredential]$Credential)
    Add-ClassTypes
    if($ComputerName)
    {
        $Script:UsingComputerName = $true  
        $args = $PSBoundParameters
        $null = $args.Remove("ComputerName")
        $null = $args.Remove("Credential")
            
       foreach($thisComputerName in $ComputerName)
       {
            LogDscDiagnostics -Verbose "Gathering logs for Computer $thisComputerName"
            $Script:ThisComputerName = $thisComputerName
            $Script:ThisCredential = $Credential
            Get-DscOperationInternal  @PSBoundParameters
            
       }
    }
    else
    {
        $Script:ThisComputerName = $env:COMPUTERNAME
        Get-DscOperationInternal @PSBoundParameters
         $Script:UsingComputerName = $false  
    }

}

<#####################################################################################################################################################
.SYNOPSIS 
Sets any DSC Event log (Operational, analytic, debug )

.DESCRIPTION
This cmdlet will set a DSC log when run with Update-xDscEventLogStatus <channel Name>.

.PARAMETER Channel
Mandatory parameter : Name of the channel of the event log to be set - It has to be one of Operational, Analytic or debug

.PARAMETER Status
Mandatory Parameter : This is a string parameter which is either "Enabled" or "disabled" representing the required final status of the log channel. If this value is "enabled", then the channel is enabled.

.PARAMETER ComputerName
String parameter that can be used to set the event log channel on a remote computer . Note : It may need a credential

.PARAMETER Credential
Credential to be passed in so that the operation can be performed on the remote computer

.EXAMPLE
C:\PS> Update-xDscEventLogStatus "Analytic" -Status "Enabled"
C:\PS> Update-xDscEventLogStatus -Channel "Debug" -ComputerName "ABC" 
C:\PS> Update-xDscEventLogStatus -Channel "Debug" -ComputerName "ABC" -Status Disabled

#####################################################################################################################################################>
 function Update-xDscEventLogStatus
 {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Analytic' , 'Debug' , 'Operational')]
        [String]$Channel,

        [Parameter(Mandatory)]
        [ValidateSet('Enabled' , 'Disabled')]
        [String]$Status,

        [String]$ComputerName,

        [PSCredential]$Credential
    )

    $LogName = "Microsoft-Windows-Dsc"
    $statusEnabled = $false
	$eventLogFullName = "$LogName/$Channel"
    if($Status -eq "Enabled")
    {
            $statusEnabled = $true
    }
    #Form the basic command which will enable/disable any event log
    $commandToExecute = "wevtutil set-log $eventLogFullName /e:$statusEnabled /q:$statusEnabled   "
    
    LogDscDiagnostics -Verbose "Changing status of the log $eventLogFullName to $Status"
    #If there is no computer name specified, just invoke the command in the same computer
    if(!$ComputerName)
    {
            
        Invoke-Expression $commandToExecute
    }
    else
    {

        #For any other computer, invoke command.
        $scriptToSetChannel = [Scriptblock]::Create($commandToExecute)
            
        if($Credential)
        {
            Invoke-Command -ScriptBlock $scriptToSetChannel -ComputerName $ComputerName  -Credential $Credential
        }
        else
        {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptToSetChannel
        }
    }
    LogDscDiagnostics -Verbose "The $Channel event log has been $Status. "
    

 }
#endregion

#region FunctionTools

#Function to Output errors, verbose messages or warning
function LogDscDiagnostics
{
    param($text , [Switch]$Error , [Switch]$Verbose ,  [Switch]$Warning)
    $formattedText = "XDscDiagnostics : $text"
    if($Error)
    {
        Write-Error   $formattedText
    }
    elseif($Verbose)
    {
        Write-Verbose $formattedText
    }
    
    elseif($Warning)
    {
        Write-Warning $formattedText
    }

}
function Add-ClassTypes
{
    #We don't want to add the same types again and again.
    if($Script:RunFirstTime)
    {
        $pathToFormattingFile = (Join-Path  $PSScriptRoot $Script:FormattingFile)
        $ClassDefinitionGroupedEvents = @"
            using System;
            using System.Globalization;
            using System.Collections;
            namespace Microsoft.PowerShell.xDscDiagnostics
            {
                public class GroupedEvents {
                        public int SequenceId;
                        public System.DateTime TimeCreated;
                        public string ComputerName;
                        public Guid? JobID = null;
                        public System.Array AllEvents;
                        public int NumberOfEvents;
                        public System.Array AnalyticEvents;
                        public System.Array DebugEvents;
                        public System.Array NonVerboseEvents;
                        public System.Array VerboseEvents;
                        public System.Array OperationalEvents;
                        public System.Array ErrorEvents;
                        public System.Array WarningEvents;
                        public string Result;
                        
                   }
            }
"@
        $ClassDefinitionTraceOutput = @"
               using System;
               using System.Globalization;
               namespace Microsoft.PowerShell.xDscDiagnostics
               {
                   public enum EventType {
                        DEBUG,
                        ANALYTIC,
                        OPERATIONAL,
                        ERROR,
                        VERBOSE
                   }
                   public class TraceOutput {
                        public EventType EventType;
                        public System.DateTime TimeCreated;
                        public string Message;
                        public string ComputerName;
                        public Guid? JobID = null;
                        public int SequenceID;
                        public System.Diagnostics.Eventing.Reader.EventRecord Event;
                   }
               }
              
"@
        Add-Type -Language CSharp -TypeDefinition $ClassDefinitionGroupedEvents
        Add-Type -Language CSharp -TypeDefinition $ClassDefinitionTraceOutput
        #Update-TypeData -TypeName TraceOutput -DefaultDisplayPropertySet EventType, TimeCreated, Message 
        Update-FormatData  -PrependPath $pathToFormattingFile 
        
        $Script:RunFirstTime = $false; #So it doesnt do it the second time.
    }
}

function Get-AllGroupedDscEvents
{
    $groupedEvents = $null
    $latestEvent = Get-LatestEvent
    LogDscDiagnostics -Verbose "Collecting all events from the DSC logs"
    if($Script:LatestEvent[$Script:ThisComputerName])
    {
        #Check if there were any differences between the latest event and the latest event in th ecache
        $compareResult = Compare-Object $Script:LatestEvent[$Script:ThisComputerName] $latestEvent -Property TimeCreated, Message
        #Compare object result will be null if they're both equal
        if(($compareResult -eq $null) -and $Script:LatestGroupedEvents[$Script:ThisComputerName])
        {
            # this means no new events were generated and you can use the event cache.
            $groupedEvents = $Script:LatestGroupedEvents[$Script:ThisComputerName]
            return $groupedEvents
        }
        
    }
    #if cache needs to be replaced, it will not return in the previous line and will come here.
        
        #Save it to cache
    $allEvents = Get-AllDscEvents
    if(!$allEvents)
    {
        LogDscDiagnostics -Error "Error : Could not find any events. Either a DSC operation has not been run, or the event logs are turned off . Please ensure the event logs are turned on in DSC. To set an event log, run the command wevtutil Set-Log <channelName> /e:true, example: wevtutil set-log 'Microsoft-Windows-Dsc/Operational' /e:true /q:true"
        return
    }
    $groupedEvents = $allEvents | Group {$_.Properties[0].Value} 
    
    $Script:LatestEvent[$Script:ThisComputerName] = $latestEvent
    $Script:LatestGroupedEvents[$Script:ThisComputerName] = $groupedEvents
    

    #group based on their Job Ids
    return $groupedEvents
}

#Wrapper over Get-WinEvent, that will call into a computer if required.
 function Get-WinEvent
 {
    $resultArray = ""
    try
    {
         if($Script:UsingComputerName)
        {
        
            if($Script:ThisCredential)
            {
                $resultArray = Microsoft.PowerShell.Diagnostics\Get-WinEvent @args -ComputerName $Script:ThisComputerName -Credential $Script:ThisCredential
            }
            else
            {
                $resultArray = Microsoft.PowerShell.Diagnostics\Get-WinEvent @args -ComputerName $Script:ThisComputerName
            }
        }
    
        else
        {
           $resultArray = Microsoft.PowerShell.Diagnostics\Get-WinEvent @args
        }
    }
    catch
    {
        LogDscDiagnostics -Error "Get-Winevent failed with error : $_ "
        throw "Cannot read events from computer $Script:ThisComputerName. Please check if the firewall is enabled. Run this command in the remote machine to enable firewall for remote administration : New-NetFirewallRule -Name 'Service RemoteAdmin' -Action Allow "
    }
    return $resultArray

}
 #Gets the JOB ID of the most recently executed script.
 function Get-DscLatestJobId
 {
    
    #Collect operational events , they're ordered from newest to oldest.
    
    $allEvents = Get-WinEvent -LogName "$Script:DscLogName/operational" -MaxEvents 2 -ea Ignore
    if($allEvents -eq $null)
    {
        return "NOJOBID"
    }
    $latestEvent = $allEvents[0] #Since it extracts it in a sorted order.

    #Extract just the jobId from the string like : Job : {<jobid>}
    #$jobInfo = (((($latestEvent.Message -split (":",2))[0] -split "job {")[1]) -split "}")[0]
    $jobInfo = $latestEvent.Properties[0].value
        
    return $jobInfo.ToString()
 }
 function Get-LatestEvent
 {
    $allEvents = Get-WinEvent -LogName "$Script:DscLogName/operational" -MaxEvents 2 -ea Ignore
    if($allEvents -eq $null)
    {
        return "NOEVENT"
    }
    $latestEvent = $allEvents[0] #Since it extracts it in a sorted order.
    return $latestEvent
 }
 #Function to get all dsc events in the event log - not exposed by the module
 function Get-AllDscEvents
 {
    #If you want a specific channel events, run it as Get-AllDscEvents 
    param
    (  
       [string[]]$ChannelType = @("Debug" , "Analytic" , "Operational") ,
       $OtherParameters = @{}
       
    )
    if($ChannelType.ToLower().Contains("operational")) 
    { 
        
        $operationalEvents = Get-WinEvent -LogName "$Script:DscLogName/operational"  @OtherParameters -ea Ignore
        $allEvents = $operationalEvents
    
    }
    if($ChannelType.ToLower().Contains("analytic"))
    {
        $analyticEvents = Get-WinEvent -LogName "$Script:DscLogName/analytic" -Oldest  -ea Ignore @OtherParameters
        if($analyticEvents -ne $null)    
        { 

                #Convert to an array type before adding another type - to avoid the error "Method invocation failed with no op_addition operator"
                $allEvents = [System.Array]$allEvents + $analyticEvents
            
        }
        
    }

    if($ChannelType.ToLower().Contains("debug"))
    {
        $debugEvents = Get-WinEvent -LogName "$Script:DscLogName/debug" -Oldest -ea Ignore @OtherParameters
        if($debugEvents -ne $null)    
        { 
                $allEvents = [System.Array]$allEvents + $debugEvents
                         
        }
    }
    
    return $allEvents
 }


 #  Function to prompt the user to set an event log, for the channel passed in as parameter
 #
 function Test-DscEventLogStatus
 {
    param($Channel = "Analytic")
    $LogDetails = Get-WinEvent -ListLog "$Script:DscLogName/$Channel"
    if($($LogDetails.IsEnabled))
    {
        return $true
    }
    LogDscDiagnostics -Warning "The $Channel log is not enabled. To enable it, please run the following command: `n        Update-xDscEventLogStatus -Channel $Channel -Status Enabled `nFor more help on this cmdlet run Get-Help Update-xDscEventLogStatus"
        
    return $false

 }

 #This function gets all the DSC runs that are recorded into the event log.
 function Get-SingleDscOperation
 {
    #If you specify a sequence ID, then the diagnosis will be for that sequence ID.
    param(
          [Uint32]$indexInArray = 0,
          [Guid]$JobId
          )

    #Get all events 
    $groupedEvents = Get-AllGroupedDscEvents
    if(!$groupedEvents)
    {
        return
    }
    #If there is a job ID present, ignore the IndexInArray, search based on jobID
    if($JobId)
    {
        LogDscDiagnostics -Verbose "Looking at Event Trace for the given Job ID $JobId"
        $indexInArray = 0;
        foreach($eventGroup in $groupedEvents)
        {

            #Check if the Job ID is present in any 
            if($($eventGroup.Name) -match $JobId)
            {
                break;
            }
            $indexInArray ++
        }
        if($indexInArray -ge $groupedEvents.Count)
        {

            #This means the job id doesn't exist
            LogDscDiagnostics -Error "The Job ID Entered $JobId, does not exist among the dsc operations. To get a list of previously run DSC operations, run this command : Get-xDscOperation"
            return
        }
    }
    $requiredRecord = $groupedEvents[$indexInArray]
    if($requiredRecord -eq $null)
    {
        LogDscDiagnostics -Error "Could not obtain the required record! "
        return
    }
    $errorText = "[None]"
    $thisRunsOutputEvents = Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $requiredRecord -index $indexInArray
        
    $thisRunsOutputEvents

 }
  
 function Split-SingleDscGroupedRecord
 {
    param(
    $singleRecordInGroupedEvents,
    $index)
            
            #$singleOutputRecord = New-Object psobject 
            $status = $Script:SuccessResult
            $errorEvents = @()
            $col_AllEvents = @()
            $col_verboseEvents = @()
            $col_analyticEvents = @()
            $col_debugEvents = @()
            $col_operationalEvents = @()
            $col_warningEvents = @()
            $col_nonVerboseEvents = @()

            #We want to now add a column for each event that says "staus as success or failure"
            $oneGroup = $singleRecordInGroupedEvents.Group
            $column_Time = $oneGroup[0].TimeCreated
            $oneGroup| %{
                $thisEvent = $_
                $thisType = ""
                $timeCreatedOfEvent = $_.TimeCreated
               
                if($_.level -eq 2) #which means there's an error
                {
                    $status = "$Script:FailureResult"
                    $errorEvents += $_
                    $thisType= [Microsoft.PowerShell.xDscDiagnostics.EventType]::ERROR
                    
                }
                elseif($_.LevelDisplayName -like "warning") { $col_warningEvents += $_ }
                if($_.ContainerLog.endsWith("operational")) 
                { 
                    $col_operationalEvents += $_ ; 
                    $col_nonVerboseEvents += $_ 

                    #Only if its not an error message, mark it as OPerational tag
                    if(!$thisType)
                    {$thisType = [Microsoft.PowerShell.xDscDiagnostics.EventType]::OPERATIONAL}
                }
                elseif($_.ContainerLog.endsWith("debug")) { $col_debugEvents += $_ ; $thisType = [Microsoft.PowerShell.xDscDiagnostics.EventType]::DEBUG }
                elseif($_.ContainerLog.endsWith("analytic")) 
                { 
                    $col_analyticEvents += $_  
                    if($_.Id -in $Script:DscVerboseEventIdsAndPropertyIndex.Keys)
                    {
                        $col_verboseEvents += $_
                        $thisType = [Microsoft.PowerShell.xDscDiagnostics.EventType]::VERBOSE
                    
                    }
                    else
                    {
                        $col_nonVerboseEvents += $_
                        $thisType = [Microsoft.PowerShell.xDscDiagnostics.EventType]::ANALYTIC
                    
                    }
                }
                $eventMessageFromEvent = Get-MessageFromEvent $thisEvent -verboseType
                #Add event with its tag 

                $thisObject= New-Object PSobject -Property @{TimeCreated = $timeCreatedOfEvent; EventType = $thisType; Event = $thisEvent; Message = $eventMessageFromEvent}
                $defaultProperties = @('TimeCreated' , 'Message' , 'EventType')
                $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet' , [string[]]$defaultProperties)
                $defaultMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
                $thisObject | Add-Member MemberSet PSStandardMembers $defaultMembers

                $col_AllEvents  += $thisObject
                
            }

            $jobIdWithoutParenthesis = ($($singleRecordInGroupedEvents.Name).split('{}'))[1] #Remove paranthesis that comes in the job id
            if(!$jobIdWithoutParenthesis) {$jobIdWithoutParenthesis = $null}

            $singleOutputRecord = New-Object Microsoft.PowerShell.xDscDiagnostics.GroupedEvents -property @{
                   SequenceID = $index;
                   ComputerName = $Script:ThisComputerName;
                   JobId = $jobIdWithoutParenthesis;
                   TimeCreated = $column_Time;
                   Result = $status;
                   NumberOfEvents = $singleRecordInGroupedEvents.Count;}
            
            $singleOutputRecord.AllEvents = $col_AllEvents | Sort-Object TimeCreated;
            $singleOutputRecord.AnalyticEvents = $col_analyticEvents ;
            $singleOutputRecord.WarningEvents = $col_warningEvents | Sort-Object TimeCreated ;
            $singleOutputRecord.OperationalEvents = $col_operationalEvents;
            $singleOutputRecord.DebugEvents = $col_debugEvents ;
            $singleOutputRecord.VerboseEvents = $col_verboseEvents  ;
            $singleOutputRecord.NonVerboseEvents = $col_nonVerboseEvents | Sort-Object TimeCreated;
            $singleOutputRecord.ErrorEvents = $errorEvents;
            
            return $singleOutputRecord
 }

 function Get-MessageFromEvent($EventRecord , [switch]$verboseType)
 {
    
    #You need to remove the job ID and send back the message
    if($EventRecord.Id -in $Script:DscVerboseEventIdsAndPropertyIndex.Keys -and $verboseType)
    {
        $requiredIndex = $Script:DscVerboseEventIdsAndPropertyIndex[$($EventRecord.Id)]
        return $EventRecord.Properties[$requiredIndex].Value
    }
    
    $NonJobIdText = ($EventRecord.Message -split([Environment]::NewLine , 2))[1]

   
    return $NonJobIdText
    
 }


 function Get-DscErrorMessage
 {
    param(<#[System.Diagnostics.Eventing.Reader.EventRecord[]]#>$ErrorRecords)
    $cimErrorId = 4131
    
    $errorText = ""
    foreach($Record in $ErrorRecords)
    {
        #go through each record, and get the single error message required for that record.
        $outputErrorMessage = Get-SingleRelevantErrorMessage -errorEvent $Record
        if($Record.Id -eq $cimErrorId)
        {
            $errorText = "$outputErrorMessage $errorText"
        }
        else
        {
            $errorText = "$errorText $outputErrorMessage"
        }
    }
    return  $errorText

}
 
 function Get-SingleRelevantErrorMessage(<#[System.Diagnostics.Eventing.Reader.EventRecord]#>$errorEvent)
 {
    $requiredPropertyIndex = @{4116 = 2;
                         4131 = 1;
                         4183 = -1;#means full message
                         4129 = -1;
                         4192 = -1;
                         4193 = -1;
                         4194 = -1;
                         4185 = -1;
                         4097 = 6;
                         4103 = 5;
                         4104 = 4}
    $cimErrorId = 4131
    $errorText = ""
    $outputErrorMessage = ""
    $eventId = $errorEvent.Id
    $propertyIndex = $requiredPropertyIndex[$eventId]
    if($propertyIndex -ne -1)
    {

        #This means You need just the property from the indices hash
        $outputErrorMessage = $errorEvent.Properties[$propertyIndex].Value

    }
    else
    {
        $outputErrorMessage = Get-MessageFromEvent -EventRecord $errorEvent
    }
    return $outputErrorMessage
    
}

 function Trace-DscOperationInternal
 {
    [cmdletBinding()]
    param(
        [UInt32]$SequenceID = 1, #latest is by default
        [Guid]$JobId
        
        )
    

    #region VariableChecks
    $indexInArray = ($SequenceId-1); #Since it is indexed from 0

    if($indexInArray -lt 0)
    {
        LogDscDiagnostics -Error "Please enter a valid Sequence ID . All sequence IDs can be seen after running command Get-xDscOperation . " -ForegroundColor Red
        return
    } 
    $null = Test-DscEventLogStatus -Channel "Analytic" 
    $null = Test-DscEventLogStatus -Channel "Debug"
    
    #endregion

    #First get the whole object set of that operation
    $thisRUnsOutputEvents = ""
    if(!$JobId)
    {
        $thisRunsOutputEvents = Get-SingleDscOperation -IndexInArray $indexInArray 
    }
    else
    {
        $thisRunsOutputEvents = Get-SingleDscOperation -IndexInArray $indexInArray -JobId $JobId
    }
    if(!$thisRunsOutputEvents)
    {
        return;
    }

    #Now we play with it.
    $result=$thisRunsOutputEvents.Result

        #Parse the error events and store them in error text.
        $errorEvents  = $thisRunsOutputEvents.ErrorEvents 
        $errorText = Get-DscErrorMessage -ErrorRecords  $errorEvents 
        
       #Now Get all logs which are non verbose 
        $nonVerboseMessages = @()
       
        $allEventMessageObject = @()
        $thisRunsOutputEvents.AllEvents | %{
                                $ThisEvent = $_.Event
                                $ThisMessage = $_.Message
                                $ThisType = $_.EventType
                                $ThisTimeCreated = $_.TimeCreated
                                #Save a hashtable as a message value 
                                if(!$thisRunsOutputEvents.JobId) {$thisJobId = $null}
                                else {$thisJobId = $thisRunsOutputEvents.JobId}
                                $allEventMessageObject += New-Object Microsoft.PowerShell.xDscDiagnostics.TraceOutput -Property @{EventType = $ThisType;TimeCreated = $ThisTimeCreated;Message = $ThisMessage;ComputerName = $Script:ThisComputerName;JobID = $thisJobId;SequenceID = $SequenceID;Event = $ThisEvent}
                                
                            } 
               
        return $allEventMessageObject
        
}

 #Internal function called by Get-xDscOperation
 function Get-DscOperationInternal()
 {
    param
    ([UInt32]$Newest = 10)
        #Groupo all events
        $groupedEvents = Get-AllGroupedDscEvents
    
        $DiagnosedGroup = $groupedEvents

        #Define the type that you want the output in
       
        $index = 1
        foreach($singleRecordInGroupedEvents in $DiagnosedGroup)
        {
            $singleOutputRecord = Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $singleRecordInGroupedEvents -index $index
            $singleOutputRecord
            if($index -ge $Newest)
            {
                break;
            }
            $index++
              
        }
 }
 
#endregion
 
 function Clear-DscDiagnosticsCache
 {
    LogDscDiagnostics -Verbose "Clearing Diagnostics Cache"
    $Script:LatestGroupedEvents = @{}
    $Script:LatestEvent = @{}

 }
 
Export-ModuleMember -Function Trace-xDscOperation, Get-xDscOperation, Update-xDscEventLogStatus