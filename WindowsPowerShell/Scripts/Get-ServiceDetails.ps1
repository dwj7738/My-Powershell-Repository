<#
 .Synopsis
  Provide a report on all SvcHost processes and embedded services.

 .Description
  Gets the details on all services running inside of SvcHost processes along with memory
  consumption, page faults and command lines.

 .Parameter computer
  The machine to test. Defaults to the current machine.

 .Parameter outHTML

  A switch. Will return a HTML formatted output of the process & service details.

 .Parameter outGrid
  A switch. Will return a GridView formatted output of the process & service details.

 .INPUTS
  None. You cannot pipe objects to Invoke-Task.
 .OUTPUTS
  A collection of PSObjects containing the details of each service.

 .Example
   Get-ServiceDetails
   Gets the details for the current machine as a PSObject collection.

 .Example
   Get-ServiceDetails "SERVER-001"
   Gets the details for the given machine as a PSObject collection.

 .Example
   Get-ServiceDetails -outHTML
   Gets the details for the current machine as a PSObject collection and also displays the details in
   the current browser as an HTML formatted file. This file is also persisted to the current folder.

 .Example
   Get-ServiceDetails -outGrid
   Gets the details for the current machine as a PSObject collection and also displays the details in
   a GridView.
#>

param (
    [string]$computer = ".",
    [switch]$outHTML,
    [switch]$outGrid
)

$results = (Get-WmiObject -Class Win32_Process -ComputerName $computer -Filter "Name='svchost.exe'" | % {
    $process = $_
    Get-WmiObject -Class Win32_Service -ComputerName $computer -Filter "ProcessId=$($_.ProcessId)" | % {
        New-Object PSObject -Property @{ProcessId=$process.ProcessId;
                                        CommittedMemory=$process.WS;
                                        PageFaults=$process.PageFaults;
                                        CommandLine=$_.PathName;
                                        ServiceName=$_.Name;
                                        State=$_.State;
                                        DisplayName=$_.DisplayName;
                                        StartMode=$_.StartMode}
    }
})
if ($outHTML)
{
    $results | ConvertTo-Html | Out-File ".\temp.html"
    & .\temp.html
}

if ($outGrid) {
    $results | Out-GridView
	}

 

$results