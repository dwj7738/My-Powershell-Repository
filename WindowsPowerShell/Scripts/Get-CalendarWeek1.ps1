# Get-CalendarWeek by Holger Adam
# Simple function to retrieve the calendar week to a given or the current date.

function Get-CalendarWeek {
	param(
		$Date
	)

	# check date input
	if ($Date -eq $null)
	{
		$Date = Get-Date
	}

	# get current culture object
	$Culture = [System.Globalization.CultureInfo]::CurrentCulture

	# retrieve calendar week
	$Culture.Calendar.GetWeekOfYear($Date, $Culture.DateTimeFormat.CalendarWeekRule, $Culture.DateTimeFormat.FirstDayOfWeek)
}