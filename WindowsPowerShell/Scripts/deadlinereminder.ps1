# Command line parsing using named arguments

<# 
.Example deadlinereminder.ps1 -EndDate DD/MM/YY -Milestone "The End of the Fiscal Year"
#>

Param([String] $EndDate = "EndDate", [String] $MileStone = "MileStone")

# Function doing the date math
Function DeadLine([DateTime] $End, [String] $MileStone)

{

Write-Host("There are {0} days until {1}" -f (New-TimeSpan -End $End).Days, $MileStone)

}

# Main code
DeadLine (Get-Date $EndDate) $MileStone