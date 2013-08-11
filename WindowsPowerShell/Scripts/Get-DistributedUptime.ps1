##############################################################################
##
## Get-DistributedUptime
##
##############################################################################
 
<#
 
.SYNOPSIS
 
Retrieves the uptime information (as of 8:00 AM local time) for the list of
computers defined in the $computers variable. Output is stored in a
date-stamped CSV file in the "My Documents" folder, with a name ending in
"_Uptime.csv".
 
.EXAMPLE
 
Get-DistributedUptime
 
#>
 
param(
    ## Overwrites the output file, if it exists
    [Parameter()]
    [Switch] $Force
)
 
## Set up common configuration options and constants
$reportStart = Get-Date -Hour 8 -Minute 0 -Second 0
$outputPath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) `
    ("{0:yyyyddMM}_Uptime.csv" -f $reportStart)
 
## See if the file exists. If it does (and the user has not specified -Force),
## then exit because the script has already been run today.
if(Test-Path $outputPath)
{
    if(-not $Force)
    {
        Write-Verbose "$outputPath already exists. Exiting"
        return
    }
    else
    {
        Remove-Item $outputPath
    }
}
 
## Get the list of computers. If desired, this list could be ready from
## a test file as well:
## $computers = Get-Content computers.txt
$computers = "DAVIDJOHNSON-W7","S2K8R2E","ALPHA1","DC1","DC2"
 
## Start the job to process all of the computers. This makes 32
## connections at a time, by default.
$j = Get-WmiObject Win32_OperatingSystem -ComputerName $computers -AsJob
 
## While the job is running, process its output
do
{
    ## Wait for some output, then retrieve the new output
    $output = @(Wait-Job $j | Receive-Job)
 
    foreach($result in $output)
    {
        ## We got a result, start processing it
        Write-Progress -Activity "Processing" -Status $result.PSComputerName
 
        ## Convert the DMTF date to a .NET Date
        $lastbootupTime = $result.ConvertToDateTime($result.LastBootUpTime)
 
        ## Subtract the time the report run started. If the system
        ## booted after the report started, ignore that for today.
        $uptimeUntilReportStart = $reportStart - $lastbootupTime
        if($uptimeUntilReportStart -lt 0)
        {
            $uptimeUntilReportStart = New-TimeSpan
        }
 
        ## Generate the output object that we're about to put
        ## into the CSV. Add a call to Select-Object at the end
        ## so that we can ensure the order.
        $outputObject = New-Object PSObject -Property @{
            ComputerName = $result.PSComputerName;
            Days = $uptimeUntilReportStart.Days;
            Hours = $uptimeUntilReportStart.Hours;
            Minutes = $uptimeUntilReportStart.Minutes;
            Seconds = $uptimeUntilReportStart.Seconds;
            Date = "{0:M/dd/yyyy}" -f $reportStart
        } | Select ComputerName, Days, Hours, Minutes, Seconds, Date
 
        Write-Verbose $outputObject
 
        ## Append it to the CSV. If the CSV doesn't exist, create it and
        ## PowerShell will create the header as well.
        if(-not (Test-Path $outputPath))
        {
            $outputObject | Export-Csv $outputPath -NoTypeInformation
        }
        else
        {
            ## Otherwise, just append the data to the file. Lines
            ## zero and one that we are skipping are the header
            ## and type information.
            ($outputObject | ConvertTo-Csv)[2]  >> $outputPath
        }
    }
} while($output)
