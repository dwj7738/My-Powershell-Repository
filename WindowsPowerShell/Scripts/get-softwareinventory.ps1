<#

	Script	: Software Inventory 
	Purpose	: List of all software installed on a computer
    Based on the original work by Aman Dhally, posted at
    http://powershell.com/cs/media/p/18510.aspx
    V1 - 8/21/2012 - Aman Dhally
    V2 - 7/17/2013 - Eliminated redundant calls and cleaned up HTML, Bob McCoy

#>

#variables
$DebugPreference = "SilentlyContinue"
$UserName = (Get-Item Env:\USERNAME).Value
$ComputerName = (Get-Item Env:\COMPUTERNAME).Value
$FileName = (Join-Path -Path ((Get-ChildItem Env:\USERPROFILE).value) -ChildPath $ComputerName) + ".html"

# HTML Style
$style = @"
<style>
BODY{background-color:Lavender}
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse}
TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:thistle}
TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:PaleGoldenrod}
</style>
"@

# Remove old report if it exists
if (Test-Path -Path $FileName) 
{
    Remove-Item $FileName
	Write-Debug "$FileName removed"
}

# Run command 
Get-WmiObject win32_Product -ComputerName $ComputerName | 
    Select Name,Version,PackageName,Installdate,Vendor | 
    Sort Installdate -Descending | 
    ConvertTo-Html -Head "<title>Software Information for $ComputerName</title>`n$style" `
         -PreContent "<h1>Computer Name: $ComputerName</h1><h2>Software Installed</h2>" `
         -PostContent "Report generated on $(get-date) by $UserName on computer $ComputerName" |
         Out-File -FilePath $FileName
    							 
# View the file 
	Write-Debug "File saved $FileName"
	Invoke-Item -Path $FileName 

# Finis
