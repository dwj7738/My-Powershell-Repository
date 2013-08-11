### Morning Check of Agent Jobs
### Runs through the servers on       domains but not      domains
### Emails DBAs

$xl = new-object -comobject excel.application
$xl.Visible = $true
$wb = $xl.Workbooks.Add()
$ws = $wb.Worksheets.Item(1)
$date = Get-Date -format f
$Filename = ( get-date ).ToString('ddMMMyyyHHmm')

$cells = $ws.Cells

$cells.item(1,3).font.bold=$True
$cells.item(1,3).font.size=18
$cells.item(1,3)="Back Up Report $date"
$cells.item(5,9)="Last Job Run Older than 1 Day"
$cells.item(5,8).Interior.ColorIndex = 43
$cells.item(4,9)="Last Job Run Older than 7 Days"
$cells.item(4,8).Interior.ColorIndex = 53
$cells.item(7,9)="Successful Job"
$cells.item(7,8).Interior.ColorIndex = 4
$cells.item(8,9)="Failed Job"
$cells.item(8,8).Interior.ColorIndex = 3
$cells.item(9,9)="Job Status Unknown"
$cells.item(9,8).Interior.ColorIndex = 46


#define some variables to control navigation
$row = 3
$col = 2

#insert column headings

$cells.item($row,$col)="Server"
$cells.item($row,$col).font.size=16
$Cells.item($row,$col).Columnwidth = 10
$col++
$cells.item($row,$col)="Job Name"
$cells.item($row,$col).font.size=16
$Cells.item($row,$col).Columnwidth = 40
$col++
$cells.item($row,$col)="Enabled?"
$cells.item($row,$col).font.size=16 
$Cells.item($row,$col).Columnwidth = 15
$col++ 
$cells.item($row,$col)="Outcome"
$cells.item($row,$col).font.size=16
$Cells.item($row,$col).Columnwidth = 12
$col++
$cells.item($row,$col)="Last Run Time"
$cells.item($row,$col).font.size=16 
$Cells.item($row,$col).Columnwidth = 15
$col++


# Load SMO extension
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null;

# Get List of sql servers to check
$sqlservers = Get-Content "c:\sqlservers.txt";

# Loop through each sql server 
foreach($sqlserver in $sqlservers)
{
	# Create an SMO Server object
	$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver;

	# Jobs counts
	$totalJobCount = $srv.JobServer.Jobs.Count;
	$failedCount = 0;
	$successCount = 0;

	# Loop through each job on the server
	foreach($job in $srv.JobServer.Jobs)
	{

		$jobName = $job.Name;
		$jobEnabled = $job.IsEnabled;
		#if($jobEnabled -eq "True")
		#{ $colourenabled = "2"}
		if($jobEnabled -eq "FALSE")
		{			$colourenabled = "2"}
		else {$colourenabled = "48" } 
		$jobLastRunOutcome = $job.LastRunOutcome;
		$Time = $job.LastRunDate ;
		# Set write text to red for Failed jobs
		if($jobLastRunOutcome -eq "Failed")
		{			$colour = "3"}
		# Set write text to grey for Unknown jobs
		Elseif($jobLastRunOutcome -eq "Unknown")
		{			$colour = "46"} 

		else {$Colour ="4"} 
		$row++
		$col = 2
		$cells.item($Row,$col)=$sqlserver
		#$cells.item($Row,$col).Interior.ColorIndex = $colour
		$col++
		$cells.item($Row,$col)=$jobName
		$col++
		$cells.item($Row,$col)=$jobEnabled 
		#Set colour of cell for UnEnabled Jobs to Grey

		$cells.item($Row,$col).Interior.ColorIndex = $colourEnabled
		if ($colourenabled -eq "48") 
		{
			$cells.item($Row ,1 ).Interior.ColorIndex = 48
			$cells.item($Row ,2 ).Interior.ColorIndex = 48
			$cells.item($Row ,3 ).Interior.ColorIndex = 48
			$cells.item($Row ,4 ).Interior.ColorIndex = 48
			$cells.item($Row ,5 ).Interior.ColorIndex = 48
			$cells.item($Row ,6 ).Interior.ColorIndex = 48
			$cells.item($Row ,7 ).Interior.ColorIndex = 48
		} 
		$col++
		$cells.item($Row,$col)="$jobLastRunOutcome"
		$cells.item($Row,$col).Interior.ColorIndex = $colour
		if ($colourenabled -eq "48") 
		{			$cells.item($Row,$col).Interior.ColorIndex = 48}
		$col++
		$cells.item($Row,$col)=$Time 
		If($Time -lt ($(Get-Date).AddDays(-1)))
		{			$cells.item($Row,$col).Interior.ColorIndex = 43}
		If($Time -lt ($(Get-Date).AddDays(-7)))
		{			$cells.item($Row,$col).Interior.ColorIndex = 53} 

	}
	$row++
	$row++
	$ws.rows.item($Row).Interior.ColorIndex = 6
	$row++
	$ws.rows.item($Row).Interior.ColorIndex = 6
	$row++
}


$wb.Saveas("C:\Scripts\ExcelBackups\$filename.xlsx")
$xl.quit()

### Script on XP does not have either of the following lines and works fine
### Tried both
### ps excel | kill
### [System.Runtime.Interopservices.Marshal]::ReleaseComObject($xl)


Send-MailMessage -To "XXXXXX", "XXXX@XXXXX" -Attachment "C:\Scripts\ExcelBackups\$filename.xlsx" -Subject "SQL Jobs Daily Report" ?From "DatabaseBackupAutoEmailer@XXXXXXXX" -SmtpServer "XXXXXX" -Body "Please see attachment for SQL Jobs Report <br><br> Note " ?BodyAsHtml