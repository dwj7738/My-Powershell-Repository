## ==================================================================================
## Title       : Find All Domain Computers Not In SCCM
## Description : Finds all computers in a domain AD that have an entry in the DNS, but
##				 are not found in SCCM.  
##				 Allows selection of the correct domain in a  multi-domain environment.
##				 
## Author      : C.Perry
## Date        : 21/2/2012
## Input       : 	
## Output      : A text file of server names not found in SCCM.
##				 Found server names with IP addressare written to the console along with error messages
## Usage	   : PS> .\CompareAllComputersInADwithSCCM.ps1
## Notes	   : Not tested with multi-site SCCM instances
## Tag		   : .NET Framework, AD, DNS, SQL Query
## Change log  :
## ==================================================================================
cls 
Function Select-Item 
{	<# 
    .Synopsis        Allows the user to select simple items, returns a number to indicate the selected item. 
    .Description 
        Produces a list on the screen with a caption followed by a message, the options are then
		displayed one after the other, and the user can one. 
        Note that help text is not supported in this version. 
    .Example 
        PS> select-item -Caption "Configuring RemoteDesktop" -Message "Do you want to: " -choice "&Disable Remote Desktop",           "&Enable Remote Desktop","&Cancel"  -default 1       Will display the following 
          Configuring RemoteDesktop           Do you want to:           [D] Disable Remote Desktop  [E] Enable Remote Desktop  [C] Cancel  [?] Help (default is "E"): 
    .Parameter Choicelist 
        An array of strings, each one is possible choice. The hot key in each choice must be prefixed with an & sign 
    .Parameter Default 
        The zero based item in the array which will be the default choice if the user hits enter. 
    .Parameter Caption 
        The First line of text displayed 
    .Parameter Message 
        The Second line of text displayed     #> 
	Param( [String[]]$choiceList, 
		[String]$Caption, 
		[String]$Message, 
		[int]$default = 0 
	) 
	$choicedesc = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription] 
	$choiceList | foreach { $choicedesc.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $_))} 
	$Host.ui.PromptForChoice($caption, $message, $choicedesc, $default) 
} 
cls
#Get Domain info
$domain = select-item -Caption "Domain Selection" -Message "Please select a domain: " `
-choice "&1 Application Domain", "&2 Construction Domain", "&3 Development Domain", "&4 Production Domain", "&5 Porting Domain", "&6 Pre-Production Domain", "&7 Cancel" -default 6
switch ($domain) 
{
	0 {$domain = "application.domain";$ServerInstance = "appserver";$Database = "SMS_APP"} 
	1 {$domain = "construction.domain";$ServerInstance = "constructserver";$Database = "SMS_CON"}
	2 {$domain = "development.domain";$ServerInstance = "devserver";$Database = "SMS_DEV"} 
	3 {$domain = "production.domain";$ServerInstance = "prodserver";$Database = "SMS_PRD"} 
	4 {$domain = "porting.domain";$ServerInstance = "portserver";$Database = "SMS_POR"} 
	5 {$domain = "preproduction.domain";$ServerInstance = "preprodserver";$Database = "SMS_PPD"} 
	6 {$domain = "Cancel"} 
	default {$domain = "Cancel"}
}

If ($domain -eq "Cancel")
{
	echo "Cancel selected"
	exit
}

#get all computer objects in selected SCCM 

$ConnectionTimeout = 30
# SQL Query to return the names of all computer objects in the respective SCCM system
$Query = "select Name0 from v_R_System order by Name0"
$QueryTimeout = 120

$conn = new-object System.Data.SqlClient.SQLConnection
$ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout
$conn.ConnectionString = $ConnectionString
$conn.Open()
$cmd = new-object system.Data.SqlClient.SqlCommand($Query,$conn)
$cmd.CommandTimeout=$QueryTimeout
$ds = New-Object system.Data.DataSet
$da = New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
[void]$da.fill($ds)
$conn.Close()
#create the domain context object
$context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$domain)
#get the domain object
$dom = [system.directoryservices.activedirectory.domain]::GetDomain($context)
#$dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 

$outfile = "C:\TEMP\" + $domain + ".ADComputers_NotIn_SCCM.txt" 
$Header = "Computer objects from the " + $domain + " AD not in SCCM" 
$Header | Out-File $outfile
#$dom # Debug line
#go to the root of the Domain
$root = $dom.GetDirectoryEntry()
#$root = [ADSI]''
#create the AD Directory Searcher object
$searcher = new-object System.DirectoryServices.DirectorySearcher($root)
#get all computer objects that have an operating system listed
$filter = "(&(objectClass=Computer)(operatingSystem=*))"
$searcher.filter = $filter
$searcher.pageSize=1000
$colProplist = "name"
foreach ($j in $colPropList){$searcher.PropertiesToLoad.Add($j)}
#get all matching computers
$colResults = $searcher.FindAll()
#interate through results
foreach ($objResult in $colResults)
{	$objItem = $objResult.Properties
	[string]$nm = $objItem.name
	#query DNS using the hostname to get the IP Address
	Try
	{
		$ip = ([System.Net.Dns]::GetHostaddresses($nm.split('.')[0]))[0].ipaddresstostring
		$op = $nm + ", " + $ip 
		$Item = $ds.Tables[0].rows | where-Object {$_.Name0 -eq $nm}
		If ($Item)
		{			#If found
			echo $op
		}#endIf found
		Else
		{			#If not  found
			$Wha = $nm + ", - Computer not found in SCCM " + $_.Exception.Message
			$nm | Out-File $outfile -Append
			write-host -backgroundcolor Red -foregroundcolor Black $Wha 
		}#endIf not found
	}
	Catch
	{
		$exceptionType = $_.Exception.GetType()
		if ($exceptionType -match 'System.Management.Automation.MethodInvocation')
		{			#IfExc
			#Attempt to access an non existant computer
			$Wha = $nm + ", - Computer not found in DNS " + $_.Exception.Message
			write-host -backgroundcolor Yellow -foregroundcolor Black $Wha 
		}#endIfExc
		Else 
		{
			$Wha = $nm + " " + $_.Exception.Message
			write-host -backgroundcolor DarkCyan -foregroundcolor White $Wha 
		}
	}

}
#number of matching computers
$objResult.count