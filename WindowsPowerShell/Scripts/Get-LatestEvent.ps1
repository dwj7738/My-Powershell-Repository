 
<# 
.Synopsis 
    Gets today's latest event from enabled event logs.

.Description 
    This script gets the latest event for today from each of the enabled logs. 
    You can specify a computer name to fetch the events from remote computer. 
   The wildcard '*' is supported for computer name.
    The events can be filtered in ID or the severity level.
    NOTE: For the script to get events from remote computers the firewall exception
    for 'Remote Event Log Management (RPC)' has to be enabled on remote computers
    and the user should have privileges to query the event logs.

.Parameter ComputerName
    The name of one or more remote computers to query. Wildcards are permitted.

.Example 
    PS C:\> .\Get-LatestEvent.ps1

    Gets today's latest event from enabled event logs on the local machine.

.Example 
    PS C:\> .\Get-LatestEvent.ps1 -Id 1006
    Gets today's latest event from local machine with event Id 1006.

.Example 
   PS C:\> .\Get-LatestEvent.ps1 -Severity Error
    Gets today's latest event from enabled event logs on the local machine whose 
    severity level is 'Error'(2).

.Example
    PS C:\> .\Get-LatestEvent.ps1 -ComputerName server02
    Gets today's latest event from enabled event logs on the remote machine server02.
.Example
    PS C:\> .\Get-LatestEvent.ps1 -ComputerName server02, server05
    Gets today's latest event from enabled event logs on the remote machines server02 
    and server05.
.Example
    PS C:\> .\Get-LatestEvent.ps1 -ComputerName server*
    Gets today's latest event from enabled event logs on the remote machines in the 
    domain, name matching 'server*'.

#>

 

param(
      [Parameter(Mandatory=$false, Position=0)] 
      [ValidateNotNullOrEmpty()] 
      [System.String[]]
      $ComputerName = @('localhost'),
      [Parameter(Mandatory=$false)]
      [System.Int32[]]
      $Id,
      [Parameter(Mandatory=$false)]
      [System.Diagnostics.Eventing.Reader.StandardEventLevel[]]
     $Severity
)
# This function queries the AD DS to resolve the computer name.
# =============================================================================
function Get-ComputerName {
param(
      [Parameter(Mandatory=$true, Position=0)] 
      [ValidateNotNullOrEmpty()] 
      [System.String]
      $ComputerName
)
      $filter = "(&(objectCategory=Computer)(name=$ComputerName))"
      $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
      $root = [ADSI]"GC://$($domain.Name)"
      $searcher = new-Object System.DirectoryServices.DirectorySearcher($root, $filter)
      $searcher.PropertiesToLoad.Add("name") | Out-Null
      $searcher.FindAll() | Foreach-Object {$computer = $_.Properties; $computer.name}
}

# This function queries the remote computer for today's latest event.
# =============================================================================
function Get-TodaysLatestEvent {
param(
    [Parameter(Mandatory=$true, Position=0)] 
    [ValidateNotNullOrEmpty()] 
    [System.String]
    $ComputerName
)
$enabledLogs = Get-WinEvent -ListLog * -ComputerName $ComputerName | Where-Object {$_.IsEnabled} | ForEach-Object {$_.LogName}
      $filter = @{}
      if (${script:Id}) { $filter['ID'] = ${script:Id} }
      if (${script:Severity}) { $filter['Level'] = (${script:Severity} | %{$_.Value__})}
      foreach ($logName in $enabledLogs)
      {
            $filter['LogName'] = $logName
            Get-WinEvent -FilterHashtable $filter -MaxEvents 1 -ComputerName $ComputerName -ErrorAction SilentlyContinue | Where-Object {$_.TimeCreated.Date -eq [DateTime]::Today}
     }
}
# We loop in here for each computer name specified and query for the events.
# =============================================================================
foreach ($name in $ComputerName)
{
      if ($name -ne 'localhost')
      {
            $ResolvedComputerNames = Get-ComputerName $name
            if (($ResolvedComputerNames -eq $null) -and ($name -notmatch '\*'))
            {
                  Write-Error "Specified Computer '$name' does not exist!"
                  continue
            }
      }
      else
      {
            $ResolvedComputerNames = $name
      }
     
      $ResolvedComputerNames | ForEach-Object {Get-TodaysLatestEvent $_}
}