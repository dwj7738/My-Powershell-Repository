Import-Module grouppolicy
#region ConfigBlock
# What domain are we going to backup GPOs for?
$domain = "mydomain.com"
# Where are we going to store the backups?
$gpoBackupRootDir = "c:\gpoBackups"
# As I plan to do a new backup set each month I'll setup the directory names to reflect
# the year and month in a nice sortable way.
# Set this up and format to your liking, I prefer $gpoBackupRootDir\yyyy-MM
$backupDir = "$gpoBackupRootDir\{0:yyyy-MM}" -f (Get-Date)

# Perform a full backup how often? Day/Week/Month/Year?
#$fullBackupFrequency = "Day"
#$fullBackupFrequency = "Week"
$fullBackupFrequency = "Month"
#$fullBackupFrequency = "Year"

# Perform Incremental backups how often?  Hour/Day/Week/Month?
$IncBackupFreqency = "Hour"
# $IncBackupFreqency = "Day"
# $IncBackupFreqency = "Week"
# $IncBackupFreqency = "Month"

# How many full sets to keep?
# Alternatively, how far back do we keep our backup sets?
$numKeepBackupSets = 12

# On what day do we want to consider the start of Week?
#$startOfWeek = "Sunday"
$startOfWeek = "Monday"
#$startOfWeek = "Tuesday"
#$startOfWeek = "Wednesday"
#$startOfWeek = "Thursday"
#$startOfWeek = "Friday"
#$startOfWeek = "Saturday"

# On what day do we want to consider the start of Month?
$startOfMonth = 1

# On what day do we want to consider the start of Year?
$startOfYear = 1

#endregion

$currentDateTime = Get-Date
$doFull = $false
$doInc = $false

# Does our backup directory exist?
# If not attempt to create it and fail the script with an approprate error
if (-not (Test-Path $backupDir))
{
	try 
	{
		New-Item -ItemType Directory -Path $backupDir
	}
	catch
	{
		Throw $("Could not create directory $backupDir")
	}
}

# If we're here then our backup directory is in good shape
# Check if we need to run a full backup or not
#  if we do, then run it
if ( Test-Path $backupDir\LastFullTimestamp.xml )
{
	# Import the timestamp from the last recorded complete full
	$lastFullTimestamp = Import-Clixml $backupDir\LastFullTimestamp.xml
	# check to see if the timestamp is valid, if not then delete it and run a full
	if ( $lastFullTimestamp -isnot [datetime] )
	{
		$doFull = $true
		Remove-Item $backupDir\LastFullTimestamp.xml
	}
	else # $lastfulltimestamp is or can be boxed/cast into [datetime]
	{
		# determine how long it has been since the last recorded full
		$fullDelta = $currentDateTime - $lastFullTimestamp
		switch ($fullBackupFrequency)
		{
			Day
			{
				if ( $fullDelta.days -gt 0 )
				{
					$doFull = $true
				}
			}
			Week
			{
				if ( ($currentDateTime.dayOfWeek -eq [DayOfWeek]$startOfWeek) `
					-or ($fullDelta.days -gt 7) )
				{
					$doFull = $true
				}
			}
			Month
			{
				if ( ($currentDateTime.day -eq $startOfMonth) `
					-or ($fullDelta.days -gt 30) )
				{
					$doFull = $true
				}
			}
			Year
			{
				if ( ($currentDateTime.dayofyear -eq $startOfYear) `
					-or ($fullDelta.days -gt 365) )
				{
					$doFull = $true
				}
			}
		}
	}
}
else # There is no recorded last completed full so we want to run one
{
	$doFull = $true
}

if ($doFull)
{
	# Run Backup of All GPOs in domain
	$GPOs = Get-GPO -domain $domain -All
	foreach ($GPO in $GPOs)
	{
		$GPOBackup = Backup-GPO $GPO.DisplayName -Path $backupDir
		# First build the Report path, then generate a report of the backed up settings.
		$ReportPath = $backupDir + "\" + $GPO.ModificationTime.Year + "-" + $GPO.ModificationTime.Month + "-" + $GPO.ModificationTime.Day + "_" + $GPO.Displayname + "_" + $GPOBackup.Id + ".html"
		Get-GPOReport -Name $GPO.DisplayName -path $ReportPath -ReportType HTML 
	}
	Export-Clixml -Path $backupDir\LastFullTimestamp.xml -InputObject ($currentDateTime)
}
else # If we're not running a full check if we need to run an incremental backup
{
	if ( Test-Path $backupDir\LastIncTimestamp.xml )
	{
		# Import the timestamp from the last recorded complete Incremental
		$lastIncTimestamp = Import-Clixml $backupDir\LastIncTimestamp.xml
		# check to see if the timestamp is valid, if not then delete it and run an inc
		if ( $lastIncTimestamp -isnot [datetime] )
		{
			# Import the timestamp from the last recorded complete full
			# If we're here then the timestamp is valid. It is checked earlier and if it fails
			# or doesn't exist then we run a full and will never get here.
			# determine how long it has been since the last recorded full
			$lastFullTimestamp = Import-Clixml $backupDir\LastFullTimestamp.xml
			$IncDelta = $currentDateTime - $lastFullTimestamp
			$doInc = $true
			Remove-Item $backupDir\LastIncTimestamp.xml
		}
		else # $lastIncTimestamp is or can be boxed/cast into [datetime]
		{
			# determine how long it has been since the last recorded full
			$IncDelta = $currentDateTime - $lastIncTimestamp
		}
	}
	else # There is no recorded last Incremental
	{
		# Import the timestamp from the last recorded complete full
		# If we're here then the timestamp is valid. It is checked earlier and if it fails
		# or doesn't exist then we run a full and will never get here.
		# determine how long it has been since the last recorded full
		$lastFullTimestamp = Import-Clixml $backupDir\LastFullTimestamp.xml
		$IncDelta = $currentDateTime - $lastFullTimestamp
	}
	# If we have already determined to run an Inc we want to skip this part
	if ($doInc -eq $false)
	{
		switch ($IncBackupFreqency)
		{
			Hour
			{
				if ($IncDelta.hours -gt 0)
				{
					$doInc = $true
				}
			}
			Day
			{
				if ($IncDelta.days -gt 0)
				{
					$doInc = $true
				}
			}
			Week
			{
				if ( ($currentDateTime.dayOfWeek -eq [DayOfWeek]$startOfWeek) `
					-or ($IncDelta.days -gt 7) )
				{
					$doInc = $true
				}
			}
			Month
			{
				if ( ($currentDateTime.day -eq $startOfMonth) `
					-or ($IncDelta.days -gt 30) )
				{
					$doInc = $true
				}
			}
		}
	}
	# Time to check our Incremental flag and run the backup if we need to
	if ($doInc)
	{
		# Run Incremental Backup
		$GPOs = Get-GPO -domain $domain -All | Where-Object { $_.modificationTime -gt ($currentDateTime - $incDelta) }
		foreach ($GPO in $GPOs)
		{
			$GPOBackup = Backup-GPO $GPO.DisplayName -Path $backupDir
			# First build the Report path, then generate a report of the backed up settings.
			$ReportPath = $backupDir + "\" + $GPO.ModificationTime.Year + "-" + $GPO.ModificationTime.Month + "-" + $GPO.ModificationTime.Day + "_" + $GPO.Displayname + ".html"
			Get-GPOReport -Name $GPO.DisplayName -path $ReportPath -ReportType HTML 
		}
		Export-Clixml -Path $backupDir\LastIncTimestamp.xml -InputObject ($currentDateTime)
	}
}
#TODO: Cleanup old backup sets