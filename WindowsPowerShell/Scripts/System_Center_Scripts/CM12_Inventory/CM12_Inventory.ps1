<#
.SYNOPSIS
	Creates a complete inventory of a Microsoft System Center 2012 Configuration Manager SP1 CU1 hierarchy using Microsoft Word.
.DESCRIPTION
	Creates a complete inventory of a Microsoft System Center 2012 Configuration Manager SP1 CU1 hierarchy using Microsoft Word and PowerShell.
	Creates a Word document named after the customer's name.
	Document includes a Cover Page, Table of Contents and Footer.
.PARAMETER SMSProvider
    FQDN of a SMS Provider in this hierarchy. 
    This parameter is mandatory!
    This parameter has an alias of MP.
.PARAMETER CompanyName
	Company Name to use for the Cover Page.  
	Default value is contained in HKCU:\Software\Microsoft\Office\Common\UserInfo\CompanyName or
	HKCU:\Software\Microsoft\Office\Common\UserInfo\Company, whichever is populated on the 
	computer running the script.
	This parameter has an alias of CN.
.PARAMETER CoverPage
	What Microsoft Word Cover Page to use.
	(default cover pages in Word en-US)
	Valid input is:
		Alphabet (Word 2007/2010. Works)
		Annual (Word 2007/2010. Doesn't really work well for this report)
		Austere (Word 2007/2010. Works)
		Austin (Word 2010/2013. Doesn't work in 2013, mostly works in 2007/2010 but Subtitle/Subject & Author fields need to me moved after title box is moved up)
		Banded (Word 2013. Works)
		Conservative (Word 2007/2010. Works)
		Contrast (Word 2007/2010. Works)
		Cubicles (Word 2007/2010. Works)
		Exposure (Word 2007/2010. Works if you like looking sideways)
		Facet (Word 2013. Works)
		Filigree (Word 2013. Works)
		Grid (Word 2010/2013.Works in 2010)
		Integral (Word 2013. Works)
		Ion (Dark) (Word 2013. Top date doesn't fit, box needs to be manually resized or font changed to 8 point)
		Ion (Light) (Word 2013. Top date doesn't fit, box needs to be manually resized or font changed to 8 point)
		Mod (Word 2007/2010. Works)
		Motion (Word 2007/2010/2013. Works if top date is manually changed to 36 point)
		Newsprint (Word 2010. Works but date is not populated)
		Perspective (Word 2010. Works)
		Pinstripes (Word 2007/2010. Works)
		Puzzle (Word 2007/2010. Top date doesn't fit, box needs to be manually resized or font changed to 14 point)
		Retrospect (Word 2013. Works)
		Semaphore (Word 2013. Works)
		Sideline (Word 2007/2010/2013. Doesn't work in 2013, works in 2007/2010)
		Slice (Dark) (Word 2013. Doesn't work)
		Slice (Light) (Word 2013. Doesn't work)
		Stacks (Word 2007/2010. Works)
		Tiles (Word 2007/2010. Date doesn't fit unless changed to 26 point)
		Transcend (Word 2007/2010. Works)
		ViewMaster (Word 2013. Works)
		Whisp (Word 2013. Works)
	Default value is Motion.
	This parameter has an alias of CP.
.PARAMETER UserName
	User name to use for the Cover Page and Footer.
	Default value is contained in $env:username
	This parameter has an alias of UN.
.PARAMETER ListAllInformation
    This parameter is a switch. If you use this switch, then you will get a lot more information regarding packages, applications, user and device collections.
    This parameter has an alias of LA.
.EXAMPLE
	PS C:\PSScript > .\CM12_Inventory.ps1 -SMSProvider CM12.do.local
	
	Will use all default values.
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\CompanyName="David O'Brienr" or
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\Company="David O'Brien"
	$env:username = adobrien

	David O'Brien for the Company Name.
	Motion for the Cover Page format.
	adobrien for the User Name.
    CM12.do.local for the SMS Provder.
.EXAMPLE
	PS C:\PSScript > .\CM12_Inventory.ps1 -SMSProvider CM12.do.local -ListAllInformation
	
	Will use all default values.
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\CompanyName="David O'Brien" or
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\Company="David O'Brien"
	$env:username = adobrien

	David O'Brien for the Company Name.
	Motion for the Cover Page format.
	adobrien for the User Name.
    CM12.do.local for the SMS Provider.
    Will give you more information, because of the ListAllInformation switch.
.EXAMPLE
	PS C:\PSScript > .\CM12_Inventory.ps1 -SMSProvider CM12.do.local -verbose
	
	Will use all default values.
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\CompanyName="David O'Brien" or
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\Company="David O'Brien"
	$env:username = adobrien

	David O'Brien for the Company Name.
	Motion for the Cover Page format.
	adobrien for the User Name.
	Will display verbose messages as the script is running.
.EXAMPLE
	PS C:\PSScript > .\CM12_Inventory.ps1 -SMSProvider CM12.do.local -CompanyName "David's company" -CoverPage "Motion" -UserName "David O'Brien"

	Will use:
		David's company for the Company Name.
		Motion for the Cover Page format.
		David O'Brien for the User Name.
        CM12.do.local for the SMS Provider.
.INPUTS
	None.  You cannot pipe objects to this script.
.OUTPUTS
	No objects are output from this script.  This script creates a Word document.
.LINK
	http://www.david-obrien.net
.NOTES
	NAME: CM12_Inventory.ps1
	VERSION: 0.3
	AUTHOR: David O'Brien (former script by Carl Webster! www.carlwebster.com ! with a lot of help from Michael B. Smith and Jeff Wouters)
	LASTEDIT: June 19, 2013
    Change history:
        19.06.2013: added error checks, bitness of powershell process, has powershell module been loaded? (version 0.1)
        09.08.2013: corrected some spelling and grammar mistakes, added more error and sanity checks, added DP disk info  (version 0.2)
        11.08.2013: replaced Parameter "ManagementPoint" with "SMSProvider", replaced Word indenting with with bullet points
        13.08.2013: removed Parameter "SiteCode", evaluating it inside the script, parameter validation for SMS Provider, checking Site version running against and resulting bitness for cmdlets (version 0.3)
.REMARKS
	To see the examples, type: "Get-Help .\CM12_Inventory.ps1 -examples".
	For more information, type: "Get-Help .\CM12_Inventory.ps1 -detailed".
#>


[CmdletBinding( SupportsShouldProcess = $False, ConfirmImpact = "None", DefaultParameterSetName = "" ) ]

osition = 0, 
	Mandatory=$true )
	] 
	[AParam(	
    
    [parameter(
	Plias("SMS")]
    [ValidateScript({
        $ping = New-Object System.Net.NetworkInformation.Ping
        $ping.Send("$_", 5000)})]
	[ValidateNotNullOrEmpty()]
	[string]$SMSProvider="",
    
	[parameter(
	Position = 1, 
	Mandatory=$false )
	] 
	[Alias("CP")]
	[ValidateNotNullOrEmpty()]
	[string]$CoverPage="Motion", 

	[parameter(
	Position = 2, 
	Mandatory=$false )
	] 
	[Alias("UN")]
	[ValidateNotNullOrEmpty()]
	[string]$UserName=$env:username,

    [parameter(
	Position = 3, 
	Mandatory=$false )
	] 
	[Alias("CN")]
	[ValidateNotNullOrEmpty()]
	[string]$CompanyName=$env:username,

    [parameter(
	Position = 4, 
	Mandatory=$false )
	] 
	[Alias("LA")]
	[ValidateNotNullOrEmpty()]
	[switch]$ListAllInformation
)

	
Set-StrictMode -Version 2
#$ErrorActionPreference = "silentlycontinue"

#check Bitness script is running in, since CM12 Version 5.00.7884.1000 (CM12 R2), Powershell cmdlets can be run from x64
$CMSession = New-PSSession -ComputerName $SMSProvider
$Version = Invoke-Command -Session $CMSession -ScriptBlock { Get-ItemProperty -Path HKLM:\Software\Microsoft\SMS\Setup -Name "Full Version"}
if (-not ($Version.'Full Version' -ge '5.00.7884.1000') -and ([Environment]::Is64BitProcess))
    {
        Write-Error "This script needs to be run from a 32-bit (x86) powershell. Please execute the script again."
        exit 1
    }

Function ValidateCoverPage
#by Carl Webster! www.carlwebster.com
{
	Param( [int]$xWordVersion, [string]$xCP )
	
	$xArray = ""
	If( $xWordVersion -eq 15)
	{
		#word 2013
		$xArray = ("Austin", "Banded", "Facet", "Filigree", "Grid", "Integral", "Ion (Dark)", "Ion (Light)", "Motion", "Retrospect", "Semaphore", "Sideline", "Slice (Dark)", "Slice (Light)", "ViewMaster", "Whisp")
	}
	ElseIf( $xWordVersion -eq 14)
	{
		#word 2010
		$xArray = ("Alphabet", "Annual", "Austere", "Austin", "Conservative", "Contrast", "Cubicles", "Exposure", "Grid", "Mod", "Motion", "Newsprint", "Perspective", "Pinstripes", "Puzzle", "Sideline", "Stacks", "Tiles", "Transcend")
	}
	ElseIf( $xWordVersion -eq 12)
	{
		#word 2007
		$xArray = ("Alphabet", "Annual", "Austere", "Conservative", "Contrast", "Cubicles", "Exposure", "Mod", "Motion", "Pinstripes", "Puzzle", "Sideline", "Stacks", "Tiles", "Transcend" )
	}
	
	If ($xArray -contains $xCP)
	{
		Return $True
	}
	Else
	{
		Return $False
	}
}
Function ValidateCompanyName
{
	$xResult = Test-RegistryValue "HKCU:\Software\Microsoft\Office\Common\UserInfo" "CompanyName"
	If($xResult)
	{
		Return Get-RegistryValue "HKCU:\Software\Microsoft\Office\Common\UserInfo" "CompanyName"
	}
	Else
	{
		$xResult = Test-RegistryValue "HKCU:\Software\Microsoft\Office\Common\UserInfo" "Company"
		If($xResult)
		{
			Return Get-RegistryValue "HKCU:\Software\Microsoft\Office\Common\UserInfo" "Company"
		}
		Else
		{
			Return ""
		}
	}
}

#http://stackoverflow.com/questions/5648931/test-if-registry-value-exists
# This function just gets $true or $false
function Test-RegistryValue($path, $name)
{
    $key = Get-Item -LiteralPath $path -EA 0
    $key -and $null -ne $key.GetValue($name, $null)
}

# Gets the specified registry value or $null if it is missing
function Get-RegistryValue($path, $name)
{
    $key = Get-Item -LiteralPath $path -EA 0
    if ($key) {
        $key.GetValue($name, $null)
    }
} 
Function WriteWordLine
#function created by Ryan Revord
#@rsrevord on Twitter
#function created to make output to Word easy in this script
{
	Param( [int]$style=0, [int]$tabs = 0, [string]$name = '', [string]$value = '', [string]$newline = "'n", [switch]$nonewline, [switch]$bold)
	$output=""
	#Build output style
	
    switch ($style)
	    {
		    0 {$Selection.Style = "No Spacing"}
		    1 {$Selection.Style = "Heading 1"}
		    2 {$Selection.Style = "Heading 2"}
		    3 {$Selection.Style = "Heading 3"}
		    Default {$Selection.Style = "No Spacing"}
	    }

	<##build # of tabs
	While( $tabs -gt 0 ) { 
		$output += "`t"; $tabs--; 
	}
    #>
	# Rather than indenting text, let's apply a bullet style instead
    If($tabs -gt 1) {
        $Selection.Style = "List Bullet $tabs"
    }
	
	#output the rest of the parameters.
	$output += $name + $value
    
    if ($bold)
        {
            $Selection.Font.Bold = 1
        }
    else
        {
	        $Selection.Font.Bold = 0
        }

	$Selection.TypeText($output)
    
	#test for new WriteWordLine 0.
	If($nonewline){
		# Do nothing.
	} Else {
		$Selection.TypeParagraph()
	}   
}

Function _SetDocumentProperty 
{
	#jeff hicks
	Param([object]$Properties,[string]$Name,[string]$Value)
	#get the property object
	$prop=$properties | foreach { 
		$propname=$_.GetType().InvokeMember("Name","GetProperty",$null,$_,$null)
		if ($propname -eq $Name) 
		{
			Return $_
		}
	} #foreach

	#set the value
	$Prop.GetType().InvokeMember("Value","SetProperty",$null,$prop,$Value)
}

write-verbose "Setting up Word"
#these values were attained from 
#http://groovy.codehaus.org/modules/scriptom/1.6.0/scriptom-office-2K3-tlb/apidocs/
#http://msdn.microsoft.com/en-us/library/office/aa211923(v=office.11).aspx
$wdAlignPageNumberRight = 2
$wdColorGray15 = 14277081
$wdColorAutomatic = -16777216
$wdFormatDocument = 0
$wdMove = 0
$wdSeekMainDocument = 0
$wdSeekPrimaryFooter = 4
$wdStory = 6

write-verbose "Validate company name"
#only validate CompanyName if the field is blank
If([String]::IsNullOrEmpty($CompanyName))
{
	$CompanyName = ValidateCompanyName
	If([String]::IsNullOrEmpty($CompanyName))
	{
		write-error "Company Name cannot be blank.  Check HKCU:\Software\Microsoft\Office\Common\UserInfo for Company or CompanyName value.  Script cannot continue."
		$Word.Quit()
		exit
	}
}

$Word = New-Object -comobject "Word.Application"
$WordVersion = [int] $Word.Version
If( $WordVersion -eq 15)
{
	write-verbose "Running Microsoft Word 2013"
	$WordProduct = "Word 2013"
}
Elseif ( $WordVersion -eq 14)
{
	write-verbose "Running Microsoft Word 2010"
	$WordProduct = "Word 2010"
}
Elseif ( $WordVersion -eq 12)
{
	write-verbose "Running Microsoft Word 2007"
	$WordProduct = "Word 2007"
}
Elseif ( $WordVersion -eq 11)
{
	write-verbose "Running Microsoft Word 2003"
	Write-error "This script does not work with Word 2003. Script will end."
	$word.quit()
	exit
}
Else
{
	Write-error "You are running an untested or unsupported version of Microsoft Word.  Script will end.  Please send info on your version of Word to webster@carlwebster.com"
	$word.quit()
	exit
}
$Word.Visible = $true
write-verbose "Load Word Templates"
$CoverPagesExist = $False
$word.Templates.LoadBuildingBlocks() | Out-Null
If ( $WordVersion -eq 12)
{
	#word 2007
	$BuildingBlocks=$word.Templates | Where {$_.name -eq "Building Blocks.dotx"}
}
Else
{
	#word 2010/2013
	$BuildingBlocks=$word.Templates | Where {$_.name -eq "Built-In Building Blocks.dotx"}
}

If($BuildingBlocks -ne $Null)
{
	$CoverPagesExist = $True
	$part=$BuildingBlocks.BuildingBlockEntries.Item($CoverPage)
}
Else
{
	$CoverPagesExist = $False
}

write-verbose "Create empty word doc"
$Doc = $Word.Documents.Add()
$global:Selection = $Word.Selection

#Disable Spell and Grammer Check to resolve issue and improve performance (from Pat Coughlin)
write-verbose "disable spell checking"
$Word.Options.CheckGrammarAsYouType=$false
$Word.Options.CheckSpellingAsYouType=$false

If($CoverPagesExist)
{
	#insert new page, getting ready for table of contents
	write-verbose "insert new page, getting ready for table of contents"
	$part.Insert($selection.Range,$True) | out-null
	$selection.InsertNewPage()

	#table of contents
	write-verbose "table of contents"
	$toc=$BuildingBlocks.BuildingBlockEntries.Item("Automatic Table 2")
	$toc.insert($selection.Range,$True) | out-null
}
Else
{
	write-verbose "Cover Pages are not installed."
	write-warning "Cover Pages are not installed so this report will not have a cover page."
	write-verbose "Table of Contents are not installed."
	write-warning "Table of Contents are not installed so this report will not have a Table of Contents."
}

#set the footer
write-verbose "set the footer"
[string]$footertext="Report created by $username"

#get the footer
write-verbose "get the footer and format font"
$doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekPrimaryFooter
#get the footer and format font
$footers=$doc.Sections.Last.Footers
foreach ($footer in $footers) 
{
	if ($footer.exists) 
	{
		$footer.range.Font.name="Calibri"
		$footer.range.Font.size=8
		$footer.range.Font.Italic=$True
		$footer.range.Font.Bold=$True
	}
} #end Foreach
write-verbose "Footer text"
$selection.HeaderFooter.Range.Text=$footerText

#add page numbering
write-verbose "add page numbering"
$selection.HeaderFooter.PageNumbers.Add($wdAlignPageNumberRight) | Out-Null

#return focus to main document
write-verbose "return focus to main document"
$doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument

#move to the end of the current document
write-verbose "move to the end of the current document"
$selection.EndKey($wdStory,$wdMove) | Out-Null
#end of Jeff Hicks 

Function Convert-NormalDateToConfigMgrDate {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$starttime
    )

    return [System.Management.ManagementDateTimeconverter]::ToDateTime($starttime)
}

Function Read-ScheduleToken {

$SMS_ScheduleMethods = "SMS_ScheduleMethods"
$class_SMS_ScheduleMethods = [wmiclass]""
$class_SMS_ScheduleMethods.psbase.Path ="ROOT\SMS\Site_$($SiteCode):$($SMS_ScheduleMethods)"
        
$script:ScheduleString = $class_SMS_ScheduleMethods.ReadFromString($ServiceWindow.ServiceWindowSchedules)
return $ScheduleString
}

Function Convert-WeekDay {
[CmdletBinding()]
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Day
    )
### day of week
switch ($Day)
    {
        1 {$weekday = "Sunday"}
        2 {$weekday = "Monday"}
        3 {$weekday = "Tuesday"}
        4 {$weekday = "Wednesday"}
        5 {$weekday = "Thursday"}
        6 {$weekday = "Friday"}
        7 {$weekday = "Saturday"}
    }
return $weekday
}

Function Convert-Time {
param (
[int]$time
)
$min = $time % 60
if ($min -le 9) {$min = "0$($min)" }
$hrs = [Math]::Truncate($time/60)

$NewTime = "$($hrs):$($min)"
return $NewTime
}

Function Get-SiteCode
{
    $wqlQuery = “SELECT * FROM SMS_ProviderLocation”
    $a = Get-WmiObject -Query $wqlQuery -Namespace “root\sms” -ComputerName $SMSProvider
    $a | ForEach-Object {
        if($_.ProviderForLocalSite)
            {
                $script:SiteCode = $_.SiteCode
            }
    }
return $SiteCode
}

$SiteCode = Get-SiteCode

##################### MAIN SCRIPT STARTS HERE #######################

$LocationBeforeExecution = Get-Location

$selection.InsertNewPage() | Out-Null
$scriptDirectory = Split-Path $myInvocation.MyCommand.Path

$Title="System Center 2012 Configuration Manager inventory report for Customer $($CompanyName)"
$filename="$($scriptDirectory)\$($CompanyName).docx"

#Import the CM12 Powershell cmdlets
if (-not (Test-Path -Path $SiteCode))
    {
        Write-Verbose "CM12 module has not been imported yet, will import it now."
        Import-Module ($env:SMS_ADMIN_UI_PATH.Substring(0,$env:SMS_ADMIN_UI_PATH.Length – 5) + '\ConfigurationManager.psd1') | Out-Null
    }
#CM12 cmdlets need to be run from the CM12 drive
Set-Location "$($SiteCode):" | Out-Null
if (-not (Get-PSDrive -Name $SiteCode))
    {
        Write-Error "There was a problem loading the Configuration Manager powershell module and accessing the site's PSDrive."
        exit 1
    }

#### Administration
#### Site Configuration

WriteWordLine 1 0 "Summary of all Sites in this Hierarchy"
Write-Verbose "Getting Site Information"
$CMSites = Get-CMSite

$CAS = $CMSites | Where-Object {$_.Type -eq "4"}
$StandAlonePrimarySites = $CMSites | Where-Object {$_.Type -eq "2"}
$ChildPrimarySites = $CMSites | Where-Object {$_.Type -eq "3"}
$SecondarySites = $CMSites | Where-Object {$_.Type -eq "1"}

if (-not [string]::IsNullOrEmpty($CAS))
    {
        WriteWordLine 0 1 "The following Central Administration Site is installed:"
        $Table = $Null
        $TableRange = $Null
        $TableRange = $doc.Application.Selection.Range
		$Columns = 3
        [int]$Rows = $CAS.count + 1
		$Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
		$table.Style = "Table Grid"
		$table.Borders.InsideLineStyle = 1
		$table.Borders.OutsideLineStyle = 1
		[int]$xRow = 1
		$Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,1).Range.Font.Bold = $True
		$Table.Cell($xRow,1).Range.Font.Size = "10"
		$Table.Cell($xRow,1).Range.Text = "Site Name"
		$Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,2).Range.Font.Bold = $True
		$Table.Cell($xRow,2).Range.Font.Size = "10"
		$Table.Cell($xRow,2).Range.Text = "Site Code"
        $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,3).Range.Font.Bold = $True
		$Table.Cell($xRow,3).Range.Font.Size = "10"
		$Table.Cell($xRow,3).Range.Text = "Version"                      
        $xRow++							
		$Table.Cell($xRow,1).Range.Font.Size = "10"
		$Table.Cell($xRow,1).Range.Text = $CAS.SiteName
		$Table.Cell($xRow,2).Range.Font.Size = "10"
		$Table.Cell($xRow,2).Range.Text = $CAS.SiteCode
		$Table.Cell($xRow,3).Range.Font.Size = "10"
		$Table.Cell($xRow,3).Range.Text = $CAS.Version
		
		$Table.Rows.SetLeftIndent(50,1) | Out-Null
		$table.AutoFitBehavior(1) | Out-Null

		#return focus back to document
		write-verbose "return focus back to document"
        $selection.EndOf(15) | Out-Null        $selection.MoveDown() | Out-Null
		$doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
        #move to the end of the current document
		write-verbose "move to the end of the current document"
		$selection.EndKey($wdStory,$wdMove) | Out-Null
		WriteWordLine 0 0 ""
    }

if (-not [string]::IsNullOrEmpty($ChildPrimarySites))
    {
        Write-Verbose "Enumerating all Primary Sites"
        WriteWordLine 0 1 "The following Primary Sites are installed:"
        $Table = $Null
        $TableRange = $Null
        $TableRange = $doc.Application.Selection.Range
		$Columns = 3
        [int]$Rows = $ChildPrimarySites.count + 1
		$Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
		$table.Style = "Table Grid"
		$table.Borders.InsideLineStyle = 1
		$table.Borders.OutsideLineStyle = 1
		[int]$xRow = 1
		$Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,1).Range.Font.Bold = $True
		$Table.Cell($xRow,1).Range.Font.Size = "10"
		$Table.Cell($xRow,1).Range.Text = "Site Name"
		$Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,2).Range.Font.Bold = $True
		$Table.Cell($xRow,2).Range.Font.Size = "10"
		$Table.Cell($xRow,2).Range.Text = "Site Code"
        $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,3).Range.Font.Bold = $True
		$Table.Cell($xRow,3).Range.Font.Size = "10"
		$Table.Cell($xRow,3).Range.Text = "Version"                      
        foreach ($ChildPrimarySite in $ChildPrimarySites)
            {
                $xRow++							
		        $Table.Cell($xRow,1).Range.Font.Size = "10"
		        $Table.Cell($xRow,1).Range.Text = $ChildPrimarySite.SiteName
		        $Table.Cell($xRow,2).Range.Font.Size = "10"
		        $Table.Cell($xRow,2).Range.Text = $ChildPrimarySite.SiteCode
                $Table.Cell($xRow,3).Range.Font.Size = "10"
		        $Table.Cell($xRow,3).Range.Text = $ChildPrimarySite.Version
            }				
		$Table.Rows.SetLeftIndent(50,1) | Out-Null
		$table.AutoFitBehavior(1) | Out-Null
 
		#return focus back to document
		write-verbose "return focus back to document"
        $selection.EndOf(15) | Out-Null        $selection.MoveDown() | Out-Null
		$doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
        #move to the end of the current document
		write-verbose "move to the end of the current document"
		$selection.EndKey($wdStory,$wdMove) | Out-Null
		WriteWordLine 0 0 ""
    }

if (-not [string]::IsNullOrEmpty($StandAlonePrimarySites))
    {
        Write-Verbose "Enumerating all standalone Primary Sites."
        WriteWordLine 0 1 "The following Primary Sites are installed:"
        $Table = $Null
        $TableRange = $Null
        $TableRange = $doc.Application.Selection.Range
		$Columns = 3
        [int]$Rows = $StandAlonePrimarySites.count + 1
		$Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
		$table.Style = "Table Grid"
		$table.Borders.InsideLineStyle = 1
		$table.Borders.OutsideLineStyle = 1
		[int]$xRow = 1
		$Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,1).Range.Font.Bold = $True
		$Table.Cell($xRow,1).Range.Font.Size = "10"
		$Table.Cell($xRow,1).Range.Text = "Site Name"
		$Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,2).Range.Font.Bold = $True
		$Table.Cell($xRow,2).Range.Font.Size = "10"
		$Table.Cell($xRow,2).Range.Text = "Site Code"
        $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,3).Range.Font.Bold = $True
		$Table.Cell($xRow,3).Range.Font.Size = "10"
		$Table.Cell($xRow,3).Range.Text = "Version"                      
        $xRow++
		$Table.Cell($xRow,1).Range.Font.Size = "10"
		$Table.Cell($xRow,1).Range.Text = $StandAlonePrimarySites.SiteName
		$Table.Cell($xRow,2).Range.Font.Size = "10"
		$Table.Cell($xRow,2).Range.Text = $StandAlonePrimarySites.SiteCode
        $Table.Cell($xRow,3).Range.Font.Size = "10"
		$Table.Cell($xRow,3).Range.Text = $StandAlonePrimarySites.Version				
		$Table.Rows.SetLeftIndent(50,1) | Out-Null
		$table.AutoFitBehavior(1) | Out-Null

		#return focus back to document
		write-verbose "return focus back to document"
        $selection.EndOf(15) | Out-Null        $selection.MoveDown() | Out-Null
		$doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
        #move to the end of the current document
		write-verbose "move to the end of the current document"
		$selection.EndKey($wdStory,$wdMove) | Out-Null
		WriteWordLine 0 0 ""
    }
if (-not [string]::IsNullOrEmpty($SecondarySites))
    {
        Write-Verbose "Enumerating all secondary sites."
        WriteWordLine 0 1 "The following Secondary Sites are installed:"
        $Table = $Null
        $TableRange = $Null
        $TableRange = $doc.Application.Selection.Range
		$Columns = 3
        [int]$Rows = $SecondarySites.count + 1
		$Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
		$table.Style = "Table Grid"
		$table.Borders.InsideLineStyle = 1
		$table.Borders.OutsideLineStyle = 1
		[int]$xRow = 1
		$Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,1).Range.Font.Bold = $True
		$Table.Cell($xRow,1).Range.Font.Size = "10"
		$Table.Cell($xRow,1).Range.Text = "Site Name"
		$Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,2).Range.Font.Bold = $True
		$Table.Cell($xRow,2).Range.Font.Size = "10"
		$Table.Cell($xRow,2).Range.Text = "Site Code"
        $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
		$Table.Cell($xRow,3).Range.Font.Bold = $True
		$Table.Cell($xRow,3).Range.Font.Size = "10"
		$Table.Cell($xRow,3).Range.Text = "Version"                      
        foreach ($SecondarySite in $SecondarySites)
            {
                $xRow++
		        $Table.Cell($xRow,1).Range.Font.Size = "10"
		        $Table.Cell($xRow,1).Range.Text = $SecondarySite.SiteName
		        $Table.Cell($xRow,2).Range.Font.Size = "10"
		        $Table.Cell($xRow,2).Range.Text = $SecondarySite.SiteCode
                $Table.Cell($xRow,3).Range.Font.Size = "10"
		        $Table.Cell($xRow,3).Range.Text = $SecondarySite.Version
            }				
		$Table.Rows.SetLeftIndent(50,1) | Out-Null
		$table.AutoFitBehavior(1) | Out-Null

		#return focus back to document
		write-verbose "return focus back to document"
        $selection.EndOf(15) | Out-Null        $selection.MoveDown() | Out-Null
		$doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
        #move to the end of the current document
		write-verbose "move to the end of the current document"
		$selection.EndKey($wdStory,$wdMove) | Out-Null
		WriteWordLine 0 0 ""
    }

foreach ($CMSite in $CMSites)
    {
            Write-Verbose "Checking each site's configuration."
            WriteWordLine 1 0 "Configuration Summary for Site $($CMSite.SiteCode)"
            WriteWordLine 0 0 ""   
            $SiteMaintenanceTasks = Get-CMSiteMaintenanceTask -SiteCode $CMSite.SiteCode
            WriteWordLine 2 1 "Site Maintenance Tasks for Site $($CMSite.SiteCode)"
            $Table = $Null
            $TableRange = $Null
            $TableRange = $doc.Application.Selection.Range
			$Columns = 2
            [int]$Rows = $SiteMaintenanceTasks.count + 1
			$Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
			$table.Style = "Table Grid"
			$table.Borders.InsideLineStyle = 1
			$table.Borders.OutsideLineStyle = 1
			[int]$xRow = 1
			$Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
			$Table.Cell($xRow,1).Range.Font.Bold = $True
			$Table.Cell($xRow,1).Range.Font.Size = "10"
			$Table.Cell($xRow,1).Range.Text = "Task Name"
			$Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
			$Table.Cell($xRow,2).Range.Font.Bold = $True
			$Table.Cell($xRow,2).Range.Font.Size = "10"
			$Table.Cell($xRow,2).Range.Text = "State"                                  
            foreach ($SiteMaintenanceTask in $SiteMaintenanceTasks)
				{
					$xRow++							
					$Table.Cell($xRow,1).Range.Font.Size = "10"
					$Table.Cell($xRow,1).Range.Text = $SiteMaintenanceTask.TaskName
					$Table.Cell($xRow,2).Range.Font.Size = "10"
					$Table.Cell($xRow,2).Range.Text = $SiteMaintenanceTask.Enabled
				}
				
			$Table.Rows.SetLeftIndent(50,1) | Out-Null
			$table.AutoFitBehavior(1) | Out-Null

			#return focus back to document
			write-verbose "return focus back to document"
            $selection.EndOf(15) | Out-Null            $selection.MoveDown() | Out-Null
			$doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument

            $CMManagementPoints = Get-CMManagementPoint -SiteCode $CMSite.SiteCode
            WriteWordLine 2 1 "Summary of Management Points for Site $($CMSite.SiteCode)"
            foreach ($CMManagementPoint in $CMManagementPoints)
                {
                    Write-Verbose "Management Point: $($CMManagementPoint)"
                    $CMMPServerName = $CMManagementPoint.NetworkOSPath.Split("\\")[2]
                    WriteWordLine 0 1 "$($CMMPServerName)"
                }

    WriteWordLine 2 1 "Summary of Distribution Points for Site $($CMSite.SiteCode)"
    $CMDistributionPoints = Get-CMDistributionPoint -SiteCode $CMSite.SiteCode
    foreach ($CMDistributionPoint in $CMDistributionPoints)
        {
            $CMDPServerName = $CMDistributionPoint.NetworkOSPath.Split("\\")[2]
            Write-Verbose "Found DP: $($CMDPServerName)"
            WriteWordLine 0 1 "$($CMDPServerName)" -bold
            
            WriteWordLine 0 2 "Disk information:"
            $Parts = Get-WmiObject win32_LogicalDisk -ComputerName $CMDPServerName -Filter "DriveType = '3'"
            $DPSession = New-PSSession -ComputerName $CMDPServerName
            foreach ($Part in $Parts)
                {
                    WriteWordLine 0 2 "Partition $($Part.DeviceID)" -bold
                    if (Invoke-Command -Session $DPSession -ArgumentList $Part -ScriptBlock {Test-Path (Join-Path $args[0].DeviceID no_sms_on_drive.sms)})
                        {
                            WriteWordLine 0 3 "no_sms_on_drive.sms file found on partition root. This drive will not be considered as Content Library."
                        }
                    $Size = ""
                    $Size = $Part.Size / 1024 / 1024 / 1024
                    $Freesize = ""
                    $Freesize = $Part.FreeSpace / 1024 / 1024 /1024

                    WriteWordLine 0 3 "$([MATH]::Round($Size,2)) GB Size"
                    WriteWordLine 0 3 "$([MATH]::Round($Freesize,2)) GB Free Space"
                }

            WriteWordLine 0 2 "Hardware Info:" -bold
            $Capacity = ""
            Get-WmiObject win32_physicalmemory -ComputerName $CMDPServerName | foreach {$Capacity += $_.Capacity}
            $TotalMemory = $Capacity / 1024 / 1024 / 1024
            WriteWordLine 0 3 "This server has a total of $($TotalMemory) GB RAM."

            $DPInfo = $CMDistributionPoint.Props
            $IsPXE = ($DPInfo | where {$_.PropertyName -eq "IsPXE"}).Value
            $UnknownMachines = ($DPInfo | where {$_.PropertyName -eq "SupportUnknownMachines"}).Value
            switch ($IsPXE)
                {
                    1 
                        {
                            WriteWordLine 0 2 "PXE Enabled"
                            switch ($UnknownMachines)
                                {
                                    1 { WriteWordLine 0 2 "Supports unknown machines: true" }
                                    0 { WriteWordLine 0 2 "Supports unknown machines: false" }
                                }
                        }
                    0
                        {
                            WriteWordLine 0 2 "PXE disabled"
                        }
                }

            $DPGroupMembers = $Null
            $DPGroupIDs = $Null
            $DPGroupMembers = Get-WmiObject -class SMS_DPGroupMembers -Namespace root\sms\site_$SiteCode -ComputerName $SMSProvider | Where-Object {$_.DPNALPath -ilike "*$($CMDPServerName)*"}
            if (-not [string]::IsNullOrEmpty($DPGroupMembers))
                {
                    $DPGroupIDs = $DPGroupMembers.GroupID
                }
            
            #enumerating DP Group Membership
            if (-not [string]::IsNullOrEmpty($DPGroupIDs))
                {
                    WriteWordLine 0 1 "This Distribution Point is a member of the following DP Groups:"
                    foreach ($DPGroupID in $DPGroupIDs)
                        {
                            $DPGroupName = (Get-CMDistributionPointGroup -Id "$($DPGroupID)").Name
                            WriteWordLine 0 2 "$($DPGroupName)"
                        }
                }
            else
                {
                    WriteWordLine 0 1 "This Distribution Point is not a member of any DP Group."
                }
        }

    #enumerating Software Update Points
    Write-Verbose "Enumerating all Software Update Points"
    WriteWordLine 2 1 "Summary of Software Update Point Servers for Site $($CMSite.SiteCode)"
    #$CMSUPs = Get-WmiObject -Class sms_sci_sysresuse -Namespace root\sms\site_$($CMSite.SiteCode) -ComputerName $CMMPServerName | Where-Object {$_.rolename -eq "SMS Software Update Point"}
    $CMSUPs = Get-CMSoftwareUpdatePoint | Where-Object {$_.SiteCode -eq "$($CMSite.SiteCode)"}
    if (-not [string]::IsNullOrEmpty($CMSUPs))
        {
            foreach ($CMSUP in $CMSUPs)
                {
                    $CMSUPServerName = $CMSUP.NetworkOSPath.split("\\")[2]
                    Write-Verbose "Found SUP: $($CMSUPServerName)"
                    WriteWordLine 0 1 "$($CMSUPServerName)"
                    $Table = $Null
                    $TableRange = $Null
                    $TableRange = $doc.Application.Selection.Range
			        $Columns = 4
                    [int]$Rows = $($CMSUP.Props).count + 1
			        $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
			        $table.Style = "Table Grid"
			        $table.Borders.InsideLineStyle = 1
			        $table.Borders.OutsideLineStyle = 1
			        [int]$xRow = 1
			        $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
			        $Table.Cell($xRow,1).Range.Font.Bold = $True
			        $Table.Cell($xRow,1).Range.Font.Size = "10"
			        $Table.Cell($xRow,1).Range.Text = "Property Name"
			        $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
			        $Table.Cell($xRow,2).Range.Font.Bold = $True
			        $Table.Cell($xRow,2).Range.Font.Size = "10"
			        $Table.Cell($xRow,2).Range.Text = "Value"
			        $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
			        $Table.Cell($xRow,3).Range.Font.Bold = $True
			        $Table.Cell($xRow,3).Range.Font.Size = "10"
			        $Table.Cell($xRow,3).Range.Text = "Value 1" 
			        $Table.Cell($xRow,4).Shading.BackgroundPatternColor = $wdColorGray15
			        $Table.Cell($xRow,4).Range.Font.Bold = $True
			        $Table.Cell($xRow,4).Range.Font.Size = "10"
			        $Table.Cell($xRow,4).Range.Text = "Value 2"                                  
                    foreach ($SUPProp in $CMSUP.Props)
				        {
					        $xRow++							
					        $Table.Cell($xRow,1).Range.Font.Size = "10"
					        $Table.Cell($xRow,1).Range.Text = $SUPProp.PropertyName
					        $Table.Cell($xRow,2).Range.Font.Size = "10"
					        $Table.Cell($xRow,2).Range.Text = $SUPProp.Value
					        $Table.Cell($xRow,3).Range.Font.Size = "10"
					        $Table.Cell($xRow,3).Range.Text = $SUPProp.Value1
					        $Table.Cell($xRow,4).Range.Font.Size = "10"
					        $Table.Cell($xRow,4).Range.Text = $SUPProp.Value2
				        }
				
			        $Table.Rows.SetLeftIndent(50,1) | Out-Null
			        $table.AutoFitBehavior(1) | Out-Null

			        #return focus back to document
			        write-verbose "return focus back to document"
                    $selection.EndOf(15) | Out-Null                    $selection.MoveDown() | Out-Null
			        $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
                   
                    
                }
        }
    else
        {
            WriteWordLine 0 1 "This site has no Software Update Points installed."
        }
}

##### Hierarchy wide configuration
WriteWordLine 1 0 "Summary of Hierarchy Wide Configuration"

### enumerating Boundaries
Write-Verbose "Enumerating all Site Boundaries"
WriteWordLine 2 0 "Summary of Site Boundaries"

$Boundaries = Get-CMBoundary
    if (-not [string]::IsNullOrEmpty($Boundaries))
        {
            $Table = $Null
            $TableRange = $Null
            $TableRange = $doc.Application.Selection.Range
	        $Columns = 5
            [int]$Rows = $Boundaries.count + 1
	        $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
	        $table.Style = "Table Grid"
	        $table.Borders.InsideLineStyle = 1
	        $table.Borders.OutsideLineStyle = 1
	        [int]$xRow = 1
	        $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
	        $Table.Cell($xRow,1).Range.Font.Bold = $True
	        $Table.Cell($xRow,1).Range.Font.Size = "10"
	        $Table.Cell($xRow,1).Range.Text = "Boundary Name"
	        $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
	        $Table.Cell($xRow,2).Range.Font.Bold = $True
	        $Table.Cell($xRow,2).Range.Font.Size = "10"
	        $Table.Cell($xRow,2).Range.Text = "Boundary Type"
            $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
	        $Table.Cell($xRow,3).Range.Font.Bold = $True
	        $Table.Cell($xRow,3).Range.Font.Size = "10"
	        $Table.Cell($xRow,3).Range.Text = "Associated Site Systems"
            $Table.Cell($xRow,4).Shading.BackgroundPatternColor = $wdColorGray15
	        $Table.Cell($xRow,4).Range.Font.Bold = $True
	        $Table.Cell($xRow,4).Range.Font.Size = "10"
	        $Table.Cell($xRow,4).Range.Text = "Value" 
            $Table.Cell($xRow,5).Shading.BackgroundPatternColor = $wdColorGray15
	        $Table.Cell($xRow,5).Range.Font.Bold = $True
	        $Table.Cell($xRow,5).Range.Font.Size = "10"
	        $Table.Cell($xRow,5).Range.Text = "Assigned Site"                                  
            foreach ($Boundary in $Boundaries)
		        {
			        $BoundarySiteSystems = $Null
                    $xRow++							
			        $Table.Cell($xRow,1).Range.Font.Size = "10"
			        $Table.Cell($xRow,1).Range.Text = $Boundary.DisplayName
                    switch ($Boundary.BoundaryType)
                        {
                            0 { $BoundaryType = "IP Subnet" }
                            1 { $BoundaryType = "Active Directory Site" }
                            2 { $BoundaryType = "IPv6 Prefix" }
                            3 { $BoundaryType = "IP Range" }
                        }
                    $Table.Cell($xRow,2).Range.Font.Size = "10"
			        $Table.Cell($xRow,2).Range.Text = $BoundaryType
                    $Table.Cell($xRow,3).Range.Font.Size = "10"
			        $BoundarySiteSystems = $Null
                    $NamesOfBoundarySiteSystems = $Null
                    if (-not [string]::IsNullOrEmpty($Boundary.SiteSystems))
                        {
                            ForEach-Object -Begin {$BoundarySiteSystems= $Boundary.SiteSystems} -Process {$NamesOfBoundarySiteSystems += $BoundarySiteSystems.split(",")} -End {$NamesOfBoundarySiteSystems} | Out-Null
                        }
                    else 
                        {
                            $NamesOfBoundarySiteSystems = "n/a"
                        }
                    $Table.Cell($xRow,3).Range.Text = $NamesOfBoundarySiteSystems
                    $Table.Cell($xRow,4).Range.Font.Size = "10"
			        $Table.Cell($xRow,4).Range.Text = $Boundary.Value
                    $Table.Cell($xRow,5).Range.Font.Size = "10"
			        $Table.Cell($xRow,5).Range.Text = $Boundary.DefaultSiteCode
		        }
				
	        $Table.Rows.SetLeftIndent(50,1) | Out-Null
	        $table.AutoFitBehavior(1) | Out-Null

	        #return focus back to document
	        write-verbose "return focus back to document"
            $selection.EndOf(15) | Out-Null            $selection.MoveDown() | Out-Null
	        $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
        }

### enumerating all Boundary Groups and their members
Write-Verbose "Enumerating all Boundary Groups and their members"

$BoundaryGroups = Get-CMBoundaryGroup
WriteWordLine 2 0 "Summary of Site Boundary Groups"
if (-not [string]::IsNullOrEmpty($BoundaryGroups))
    {
        foreach ($BoundaryGroup in $BoundaryGroups)
            {
                WriteWordLine 0 1 "$($BoundaryGroup.Name)" -bold
                WriteWordLine 0 2 "Description: $($BoundaryGroup.Description)"

                if ($BoundaryGroup.SiteSystemCount -gt 0)
                    {
                        $MemberIDs = (Get-WmiObject -Class SMS_BoundaryGroupMembers -Namespace root\sms\site_$SiteCode -ComputerName $SMSProvider | Where-Object {$_.GroupID -eq "$($BoundaryGroup.GroupID)"}).BoundaryID
                        foreach ($MemberID in $MemberIDs)
                            {
                                $MemberName = (Get-CMBoundary -Id $MemberID).DisplayName
                                WriteWordLine 0 2 "Member names: $($MemberName)"
                            }
                    }
                else
                    {
                        WriteWordLine 0 2 "There are no Site Systems associated to this Boundary Group."
                    }
            }
    }
else
    {
        WriteWordLine 0 1 "There are no Boundary Groups configured. It is mandatory to configure a Boundary Group in order for CM12 to work properly."
    }

### enumerating Client Policies
Write-Verbose "Enumerating all Client/Device Settings"
WriteWordLine 2 0 "Summary of Custom Client Device Settings"

$AllClientSettings = Get-CMClientSetting | Where-Object {$_.SettingsID -ne "0"}
foreach ($ClientSetting in $AllClientSettings)
    {
        WriteWordLine 0 1 "Client Settings Name: $($ClientSetting.Name)" -bold
        WriteWordLine 0 2 "Client Settings Description: $($ClientSetting.Description)"
        WriteWordLine 0 2 "Client Settings ID: $($ClientSetting.SettingsID)"
        WriteWordLine 0 2 "Client Settings Priority: $($ClientSetting.Priority)"
        if ($ClientSetting.Type -eq "1")
            {
                WriteWordLine 0 2 "This is a custom client Device Setting."
            }
        else
            {
                WriteWordLine 0 2 "This is a custom client User Setting."
            }
        WriteWordLine 0 1 "Configurations"
        foreach ($AgentConfig in $ClientSetting.AgentConfigurations)
            {
                try
                    {
                        switch ($AgentConfig.AgentID)
                            {
                                1
                                    {
                                        WriteWordLine 0 2 "Compliance Settings"
                                        WriteWordLine 0 2 "Enable compliance evaluation on clients: $($AgentConfig.Enabled)"
                                        WriteWordLine 0 2 "Enable user data and profiles: $($AgentConfig.EnableUserStateManagement)"
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                2
                                    {
                                        WriteWordLine 0 2 "Software Inventory"
                                        WriteWordLine 0 2 "Enable software inventory on clients: $($AgentConfig.Enabled)"
                                        WriteWordLine 0 2 "Schedule software inventory and file collection: " -nonewline
                                        $Schedule = Convert-CMSchedule -ScheduleString $AgentConfig.Schedule
                                        if ($Schedule.DaySpan -gt 0)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.DaySpan) days effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.HourSpan -gt 0)
                                            {
                                                 WriteWordLine 0 0 " Occurs every $($Schedule.HourSpan) hours effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.MinuteSpan -gt 0)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.MinuteSpan) minutes effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfWeeks)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.ForNumberOfWeeks) weeks on $(Convert-WeekDay $Schedule.Day) effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfMonths)
                                            {
                                                if ($Schedule.MonthDay -gt 0)
                                                    {
                                                        WriteWordLine 0 0 " Occurs on day $($Schedule.MonthDay) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.MonthDay -eq 0)
                                                    {
                                                        WriteWordLine 0 0 " Occurs the last day of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.WeekOrder -gt 0)
                                                    {
                                                        switch ($Schedule.WeekOrder)
                                                            {
                                                                0 {$order = "last"}
                                                                1 {$order = "first"}
                                                                2 {$order = "second"}
                                                                3 {$order = "third"}
                                                                4 {$order = "fourth"}
                                                            }
                                                        WriteWordLine 0 0 " Occurs the $($order) $(Convert-WeekDay $Schedule.Day) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                            }
                                        WriteWordLine 0 2 "Inventory reporting detail: " -nonewline
                                        switch ($AgentConfig.ReportOptions)
                                            {
                                                1 { WriteWordLine 0 0 "Product only" }
                                                2 { WriteWordLine 0 0 "File only" }
                                                7 { WriteWordLine 0 0 "Full details" }
                                            }
                                
                                        WriteWordLine 0 2 "Inventory these file types: "
                                        if ($AgentConfig.InventoriableTypes)
                                            {
                                                WriteWordLine 0 3 "$($AgentConfig.InventoriableTypes)"
                                            }
                                        if ($AgentConfig.Path)
                                            {                               
                                                WriteWordLine 0 3 "$($AgentConfig.Path)"
                                            }
                                        if (($AgentConfig.InventoriableTypes) -and ($AgentConfig.ExcludeWindirAndSubfolders -eq "true"))
                                            {
                                                WriteWordLine 0 3 "Exclude WinDir and Subfolders"
                                            }
                                        else 
                                            {
                                                WriteWordLine 0 3 "Do not exclude WinDir and Subfolders"
                                            }
                                 
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                3
                                    {
                                        WriteWordLine 0 2 "Remote Tools"
                                        WriteWordLine 0 2 "Enable Remote Control on clients: " -nonewline
                                        switch ($AgentConfig.FirewallExceptionProfiles)
                                            {
                                                0 { WriteWordLine 0 0 "Disabled" }
                                                8 { WriteWordLine 0 0 "Enabled: No Firewall Profile." }
                                                9 { WriteWordLine 0 2 "Enabled: Public." }
                                                10 { WriteWordLine 0 2 "Enabled: Private." }
                                                11 { WriteWordLine 0 2 "Enabled: Private, Public." }
                                                12 { WriteWordLine 0 2 "Enabled: Domain." }
                                                13 { WriteWordLine 0 2 "Enabled: Domain, Public." }
                                                14 { WriteWordLine 0 2 "Enabled: Domain, Private." }
                                                15 { WriteWordLine 0 2 "Enabled: Domain, Private, Public." }
                                            }
                                        WriteWordLine 0 2 "Users can change policy or notification settings in Software Center: $($AgentConfig.AllowClientChange)"
                                        WriteWordLine 0 2 "Allow Remote Control of an unattended computer: $($AgentConfig.AllowRemCtrlToUnattended)"
                                        WriteWordLine 0 2 "Prompt user for Remote Control permission: $($AgentConfig.PermissionRequired)"
                                        WriteWordLine 0 2 "Grant Remote Control permission to local Administrators group: $($AgentConfig.AllowLocalAdminToDoRemoteControl)"
                                        WriteWordLine 0 2 "Access level allowed: " -nonewline
                                        switch ($AgentConfig.AccessLevel)
                                            {
                                                0 { WriteWordLine 0 0 "No access" }
                                                1 { WriteWordLine 0 0 "View only" }
                                                2 { WriteWordLine 0 0 "Full Control" }
                                            }
                                        WriteWordLine 0 2 "Permitted viewers of Remote Control and Remote Assistance:"
                                        foreach ($Viewer in $AgentConfig.PermittedViewers)
                                            {
                                                WriteWordLine 0 3 "$($Viewer)"
                                            }
                                        WriteWordLine 0 2 "Show session notification icon on taskbar: $($AgentConfig.RemCtrlTaskbarIcon)"
                                        WriteWordLine 0 2 "Show session connection bar: $($AgentConfig.RemCtrlConnectionBar)"
                                        WriteWordLine 0 2 "Play a sound on client: " -nonewline
                                        Switch ($AgentConfig.AudibleSignal)
                                            {
                                                0 { WriteWordLine 0 0 "None." }
                                                1 { WriteWordLine 0 0 "Beginning and end of session." }
                                                2 { WriteWordLine 0 0 "Repeatedly during session." }
                                            }
                                        WriteWordLine 0 2 "Manage unsolicited Remote Assistance settings: $($AgentConfig.ManageRA)"
                                        WriteWordLine 0 2 "Manage solicited Remote Assistance settings: $($AgentConfig.EnforceRAandTSSettings)"
                                        WriteWordLine 0 2 "Level of access for Remote Assistance: " -nonewline
                                        if (($AgentConfig.AllowRAUnsolicitedView -ne "True") -and ($AgentConfig.AllowRAUnsolicitedControl -ne "True"))
                                            {
                                                WriteWordLine 0 0 "None."
                                            }
                                        elseif (($AgentConfig.AllowRAUnsolicitedView -eq "True") -and ($AgentConfig.AllowRAUnsolicitedControl -ne "True"))
                                            {
                                                WriteWordLine 0 0 "Remote viewing."
                                            }
                                        elseif (($AgentConfig.AllowRAUnsolicitedView -eq "True") -and ($AgentConfig.AllowRAUnsolicitedControl -eq "True"))
                                            {
                                                WriteWordLine 0 0 "Full Control."
                                            }
                                        WriteWordLine 0 2 "Manage Remote Desktop settings: $($AgentConfig.ManageTS)"
                                        if ($AgentConfig.ManageTS -eq "True")
                                            {
                                                WriteWordLine 0 2 "Allow permitted viewers to connect by using Remote Desktop connection: $($AgentConfig.EnableTS)"
                                                WriteWordLine 0 2 "Require network level authentication on computers that run Windows Vista operating system and later versions: $($AgentConfig.TSUserAuthentication)"
                                            }
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                4
                                    {
                                        WriteWordLine 0 2 "Computer Agent"
                                        WriteWordLine 0 2 "Deployment deadline greater than 24 hours, remind user every (hours): $([string]($AgentConfig.ReminderInterval) / 60 / 60)"
                                        WriteWordLine 0 2 "Deployment deadline less than 24 hours, remind user every (hours): $([string]($AgentConfig.DayReminderInterval) / 60 / 60)"
                                        WriteWordLine 0 2 "Deployment deadline less than 1 hour, remind user every (minutes): $([string]($AgentConfig.HourReminderInterval) / 60)"
                                        WriteWordLine 0 2 "Default application catalog website point: $($AgentConfig.PortalUrl)"
                                        WriteWordLine 0 2 "Add default Application Catalog website to Internet Explorer trusted sites zone: $($AgentConfig.AddPortalToTrustedSiteList)"
                                        WriteWordLine 0 2 "Allow Silverlight applications to run in elevated trust mode: $($AgentConfig.AllowPortalToHaveElevatedTrust)"
                                        WriteWordLine 0 2 "Organization name displayed in Software Center: $($AgentConfig.BrandingTitle)"
                                        switch ($AgentConfig.InstallRestriction)
                                            {
                                                0 { $InstallRestriction = "All Users" }
                                                1 { $InstallRestriction = "Only Administrators" }
                                                3 { $InstallRestriction = "Only Administrators and primary Users"}
                                                4 { $InstallRestriction = "No users" }
                                            }
                                        WriteWordLine 0 2 "Install Permissions: $($InstallRestriction)"
                                        Switch ($AgentConfig.SuspendBitLocker)
                                            {
                                                0 { $SuspendBitlocker = "Never" }
                                                1 { $SuspendBitlocker = "Always" }
                                            }
                                        WriteWordLine 0 2 "Suspend Bitlocker PIN entry on restart: $($SuspendBitlocker)"
                                        Switch ($AgentConfig.EnableThirdPartyOrchestration)
                                            {
                                                0 { $EnableThirdPartyTool = "No" }
                                                1 { $EnableThirdPartyTool = "Yes" }
                                            }
                                        WriteWordLine 0 2 "Additional software manages the deployment of applications and software updates: $($EnableThirdPartyTool)"
                                        Switch ($AgentConfig.PowerShellExecutionPolicy)
                                            {
                                                0 { $ExecutionPolicy = "All signed" }
                                                1 { $ExecutionPolicy = "Bypass" }
                                                2 { $ExecutionPolicy = "Restricted" }
                                            }
                                        WriteWordLine 0 2 "Powershell execution policy: $($ExecutionPolicy)"
                                        switch ($AgentConfig.DisplayNewProgramNotification)
                                            {
                                                False { $DisplayNotifications = "No" }
                                                True { $DisplayNotifications = "Yes" }
                                            }
                                        WriteWordLine 0 2 "Show notifications for new deployments: $($DisplayNotifications)"
                                        switch ($AgentConfig.DisableGlobalRandomization)
                                            {
                                                False { $DisableGlobalRandomization = "No" }
                                                True { $DisableGlobalRandomization = "Yes" }
                                            }
                                        WriteWordLine 0 2 "Disable deadline randomization: $($DisableGlobalRandomization)"
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                5
                                    {
                                        WriteWordLine 0 2 "Network Access Protection (NAP)"
                                        WriteWordLine 0 2 "Enable Network Access Protection on clients: $($AgentConfig.Enabled)"
                                        WriteWordLine 0 2 "Use UTC (Universal Time Coordinated) for evaluation time: $($AgentConfig.EffectiveTimeinUTC)"
                                        WriteWordLine 0 2 "Require a new scan for each evaluation: $($AgentConfig.ForceScan)"
                                        WriteWordLine 0 2 "NAP re-evaluation schedule:" -nonewline
                                        $Schedule = Convert-CMSchedule -ScheduleString $AgentConfig.ComputeComplianceSchedule
                                        if ($Schedule.DaySpan -gt 0)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.DaySpan) days effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.HourSpan -gt 0)
                                            {
                                                 WriteWordLine 0 0 " Occurs every $($Schedule.HourSpan) hours effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.MinuteSpan -gt 0)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.MinuteSpan) minutes effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfWeeks)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.ForNumberOfWeeks) weeks on $(Convert-WeekDay $Schedule.Day) effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfMonths)
                                            {
                                                if ($Schedule.MonthDay -gt 0)
                                                    {
                                                        WriteWordLine 0 0 " Occurs on day $($Schedule.MonthDay) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.MonthDay -eq 0)
                                                    {
                                                        WriteWordLine 0 0 " Occurs the last day of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.WeekOrder -gt 0)
                                                    {
                                                        switch ($Schedule.WeekOrder)
                                                            {
                                                                0 {$order = "last"}
                                                                1 {$order = "first"}
                                                                2 {$order = "second"}
                                                                3 {$order = "third"}
                                                                4 {$order = "fourth"}
                                                            }
                                                        WriteWordLine 0 0 " Occurs the $($order) $(Convert-WeekDay $Schedule.Day) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                            }
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                8
                                    {
                                        WriteWordLine 0 2 "Software Metering"
                                        WriteWordLine 0 2 "Enable software metering on clients: $($AgentConfig.Enabled)"
                                        WriteWordLine 0 2 "Schedule data collection: " -nonewline
                                        $Schedule = Convert-CMSchedule -ScheduleString $AgentConfig.DataCollectionSchedule
                                        if ($Schedule.DaySpan -gt 0)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.DaySpan) days effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.HourSpan -gt 0)
                                            {
                                                 WriteWordLine 0 0 " Occurs every $($Schedule.HourSpan) hours effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.MinuteSpan -gt 0)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.MinuteSpan) minutes effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfWeeks)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.ForNumberOfWeeks) weeks on $(Convert-WeekDay $Schedule.Day) effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfMonths)
                                            {
                                                if ($Schedule.MonthDay -gt 0)
                                                    {
                                                        WriteWordLine 0 0 " Occurs on day $($Schedule.MonthDay) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.MonthDay -eq 0)
                                                    {
                                                        WriteWordLine 0 0 " Occurs the last day of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.WeekOrder -gt 0)
                                                    {
                                                        switch ($Schedule.WeekOrder)
                                                            {
                                                                0 {$order = "last"}
                                                                1 {$order = "first"}
                                                                2 {$order = "second"}
                                                                3 {$order = "third"}
                                                                4 {$order = "fourth"}
                                                            }
                                                        WriteWordLine 0 0 " Occurs the $($order) $(Convert-WeekDay $Schedule.Day) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                            }
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                9
                                    {
                                        WriteWordLine 0 2 "Software Updates"
                                        WriteWordLine 0 2 "Enable software updates on clients: $($AgentConfig.Enabled)"
                                        WriteWordLine 0 2 "Software Update scan schedule: " -nonewline
                                        $Schedule = Convert-CMSchedule -ScheduleString $AgentConfig.ScanSchedule
                                        if ($Schedule.DaySpan -gt 0)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.DaySpan) days effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.HourSpan -gt 0)
                                            {
                                                 WriteWordLine 0 0 " Occurs every $($Schedule.HourSpan) hours effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.MinuteSpan -gt 0)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.MinuteSpan) minutes effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfWeeks)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.ForNumberOfWeeks) weeks on $(Convert-WeekDay $Schedule.Day) effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfMonths)
                                            {
                                                if ($Schedule.MonthDay -gt 0)
                                                    {
                                                        WriteWordLine 0 0 " Occurs on day $($Schedule.MonthDay) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.MonthDay -eq 0)
                                                    {
                                                        WriteWordLine 0 0 " Occurs the last day of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.WeekOrder -gt 0)
                                                    {
                                                        switch ($Schedule.WeekOrder)
                                                            {
                                                                0 {$order = "last"}
                                                                1 {$order = "first"}
                                                                2 {$order = "second"}
                                                                3 {$order = "third"}
                                                                4 {$order = "fourth"}
                                                            }
                                                        WriteWordLine 0 0 " Occurs the $($order) $(Convert-WeekDay $Schedule.Day) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                            }
                                        WriteWordLine 0 2 "Schedule deployment re-evaluation: " -nonewline
                                        $Schedule = Convert-CMSchedule -ScheduleString $AgentConfig.EvaluationSchedule
                                        if ($Schedule.DaySpan -gt 0)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.DaySpan) days effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.HourSpan -gt 0)
                                            {
                                                 WriteWordLine 0 0 " Occurs every $($Schedule.HourSpan) hours effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.MinuteSpan -gt 0)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.MinuteSpan) minutes effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfWeeks)
                                            {
                                                WriteWordLine 0 0 " Occurs every $($Schedule.ForNumberOfWeeks) weeks on $(Convert-WeekDay $Schedule.Day) effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfMonths)
                                            {
                                                if ($Schedule.MonthDay -gt 0)
                                                    {
                                                        WriteWordLine 0 0 " Occurs on day $($Schedule.MonthDay) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.MonthDay -eq 0)
                                                    {
                                                        WriteWordLine 0 0 " Occurs the last day of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.WeekOrder -gt 0)
                                                    {
                                                        switch ($Schedule.WeekOrder)
                                                            {
                                                                0 {$order = "last"}
                                                                1 {$order = "first"}
                                                                2 {$order = "second"}
                                                                3 {$order = "third"}
                                                                4 {$order = "fourth"}
                                                            }
                                                        WriteWordLine 0 0 " Occurs the $($order) $(Convert-WeekDay $Schedule.Day) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                            }
                                        WriteWordLine 0 2 "When any software update deployment deadline is reached, install all other software update deployments with deadline coming within a specified period of time: " -nonewline
                                        if ($AgentConfig.AssignmentBatchingTimeout -eq "0")
                                            {
                                                WriteWordLine 0 0 "No."
                                            }
                                        else 
                                            {
                                                WriteWordLine 0 0 "Yes."    
                                                WriteWordLine 0 2 "Period of time for which all pending deployments with deadline in this time will also be installed: " -nonewline
                                                if ($AgentConfig.AssignmentBatchingTimeout -le "82800")
                                                    {
                                                        $hours = [string]$AgentConfig.AssignmentBatchingTimeout / 60 / 60 
                                                        WriteWordLine 0 0 "$($hours) hours"
                                                    }
                                                else 
                                                    {
                                                        $days = [string]$AgentConfig.AssignmentBatchingTimeout / 60 / 60 / 24
                                                        WriteWordLine 0 0 "$($days) days"
                                                    }
                                            }

                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                10
                                    {
                                        WriteWordLine 0 2 "User and Device Affinity"
                                        WriteWordLine 0 2 "User device affinity usage threshold (minutes): $($AgentConfig.ConsoleMinutes)"
                                        WriteWordLine 0 2 "User device affinity usage threshold (days): $($AgentConfig.IntervalDays)"
                                        WriteWordLine 0 2 "Automatically configure user device affinity from usage data: " -nonewline 
                                        if ($AgentConfig.AutoApproveAffinity -eq "0")
                                            {
                                                WriteWordLine 0 0 "No"
                                            }
                                        else
                                            {
                                                WriteWordLine 0 0 "Yes"
                                            }
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                11
                                    {
                                        WriteWordLine 0 2 "Background Intelligent Transfer"
                                        WriteWordLine 0 2 "Limit the maximum network bandwidth for BITS background transfers: $($AgentConfig.EnableBitsMaxBandwidth)"
                                        WriteWordLine 0 2 "Throttling window start time: $($AgentConfig.MaxBandwidthValidFrom)"
                                        WriteWordLine 0 2 "Throttling window end time: $($AgentConfig.MaxBandwidthValidTo)"
                                        WriteWordLine 0 2 "Maximum transfer rate during throttling window (kbps): $($AgentConfig.MaxTransferRateOnSchedule)"
                                        WriteWordLine 0 2 "Allow BITS downloads outside the throttling window: $($AgentConfig.EnableDownloadOffSchedule)"
                                        WriteWordLine 0 2 "Maximum transfer rate outside the throttling window (Kbps): $($AgentConfig.MaxTransferRateOffSchedule)"
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                12
                                    {
                                        WriteWordLine 0 2 "Enrollment"
                                        WriteWordLine 0 2 "Allow users to enroll mobile devices and Mac computers: " -nonewline
                                        if ($AgentConfig.EnableDeviceEnrollment -eq "0")
                                            {
                                                WriteWordLine 0 0 "No"
                                            }
                                        else
                                            {
                                                WriteWordLine 0 0 "Yes"
                                            }
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                13
                                    {
                                        WriteWordLine 0 2 "Client Policy"
                                        WriteWordLine 0 2 "Client policy polling interval (minutes): $($AgentConfig.PolicyRequestAssignmentTimeout)"
                                        WriteWordLine 0 2 "Enable user policy on clients: $($AgentConfig.PolicyEnableUserPolicyPolling)"
                                        WriteWordLine 0 2 "Enable user policy requests from Internet clients: $($AgentConfig.PolicyEnableUserPolicyOnInternet)"
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                15
                                    {
                                        WriteWordLine 0 2 "Hardware Inventory"
                                        WriteWordLine 0 2 "Enable hardware inventory on clients: $($AgentConfig.Enabled)"
                                        $Schedule = Convert-CMSchedule -ScheduleString $AgentConfig.Schedule
                                        if ($Schedule.DaySpan -gt 0)
                                            {
                                                WriteWordLine 0 2 "Hardware inventory schedule: Occurs every $($Schedule.DaySpan) days effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.HourSpan -gt 0)
                                            {
                                                 WriteWordLine 0 2 "Hardware inventory schedule: Occurs every $($Schedule.HourSpan) hours effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.MinuteSpan -gt 0)
                                            {
                                                WriteWordLine 0 2 "Hardware inventory schedule: Occurs every $($Schedule.MinuteSpan) minutes effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfWeeks)
                                            {
                                                WriteWordLine 0 2 "Hardware inventory schedule: Occurs every $($Schedule.ForNumberOfWeeks) weeks on $(Convert-WeekDay $Schedule.Day) effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfMonths)
                                            {
                                                if ($Schedule.MonthDay -gt 0)
                                                    {
                                                        WriteWordLine 0 2 "Hardware inventory schedule: Occurs on day $($Schedule.MonthDay) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.MonthDay -eq 0)
                                                    {
                                                        WriteWordLine 0 2 "Hardware inventory schedule: Occurs on last day of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.WeekOrder -gt 0)
                                                    {
                                                        switch ($Schedule.WeekOrder)
                                                            {
                                                                0 {$order = "last"}
                                                                1 {$order = "first"}
                                                                2 {$order = "second"}
                                                                3 {$order = "third"}
                                                                4 {$order = "fourth"}
                                                            }
                                                        WriteWordLine 0 2 "Hardware inventory schedule: Occurs the $($order) $(Convert-WeekDay $Schedule.Day) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                            }
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                16 
                                    {
                                        WriteWordLine 0 2 "State Messaging"
                                        WriteWordLine 0 2 "State message reporting cycle (minutes): $($AgentConfig.BulkSendInterval)"
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                17
                                    {
                                        WriteWordLine 0 2 "Software Deployment"
                                        $Schedule = Convert-CMSchedule -ScheduleString $AgentConfig.EvaluationSchedule
                                        if ($Schedule.DaySpan -gt 0)
                                            {
                                                WriteWordLine 0 2 "Schedule re-evaluation for deployments: Occurs every $($Schedule.DaySpan) days effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.HourSpan -gt 0)
                                            {
                                                 WriteWordLine 0 2 "Schedule re-evaluation for deployments: Occurs every $($Schedule.HourSpan) hours effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.MinuteSpan -gt 0)
                                            {
                                                WriteWordLine 0 2 "Schedule re-evaluation for deployments: Occurs every $($Schedule.MinuteSpan) minutes effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfWeeks)
                                            {
                                                WriteWordLine 0 2 "Schedule re-evaluation for deployments: Occurs every $($Schedule.ForNumberOfWeeks) weeks on $(Convert-WeekDay $Schedule.Day) effective $($Schedule.StartTime)"
                                            }
                                        elseif ($Schedule.ForNumberOfMonths)
                                            {
                                                if ($Schedule.MonthDay -gt 0)
                                                    {
                                                        WriteWordLine 0 2 "Schedule re-evaluation for deployments: Occurs on day $($Schedule.MonthDay) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.MonthDay -eq 0)
                                                    {
                                                        WriteWordLine 0 2 "Schedule re-evaluation for deployments: Occurs on last day of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                                elseif ($Schedule.WeekOrder -gt 0)
                                                    {
                                                        switch ($Schedule.WeekOrder)
                                                            {
                                                                0 {$order = "last"}
                                                                1 {$order = "first"}
                                                                2 {$order = "second"}
                                                                3 {$order = "third"}
                                                                4 {$order = "fourth"}
                                                            }
                                                        WriteWordLine 0 2 "Schedule re-evaluation for deployments: Occurs the $($order) $(Convert-WeekDay $Schedule.Day) of every $($Schedule.ForNumberOfMonths) months effective $($Schedule.StartTime)"
                                                    }
                                            }
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                18
                                    {
                                        WriteWordLine 0 2 "Power Management"
                                        WriteWordLine 0 2 "Allow power management of clients: $($AgentConfig.Enabled)"
                                        WriteWordLine 0 2 "Allow users to exclude their device from power management: $($AgentConfig.AllowUserToOptOutFromPowerPlan)"
                                        WriteWordLine 0 2 "Enable wake-up proxy: $($AgentConfig.EnableWakeupProxy)"
                                        if ($AgentConfig.EnableWakeupProxy -eq "True")
                                            {
                                                WriteWordLine 0 2 "Wake-up proxy port number (UDP): $($AgentConfig.Port)"
                                                WriteWordLine 0 2 "Wake On LAN port number (UDP): $($AgentConfig.WolPort)"
                                                WriteWordLine 0 2 "Windows Firewall exception for wake-up proxy: " -nonewline
                                                switch ($AgentConfig.WakeupProxyFirewallFlags)
                                                    {
                                                        0 { WriteWordLine 0 2 "disabled" }
                                                        9 { WriteWordLine 0 2 "Enabled: Public." }
                                                        10 { WriteWordLine 0 2 "Enabled: Private." }
                                                        11 { WriteWordLine 0 2 "Enabled: Private, Public." }
                                                        12 { WriteWordLine 0 2 "Enabled: Domain." }
                                                        13 { WriteWordLine 0 2 "Enabled: Domain, Public." }
                                                        14 { WriteWordLine 0 2 "Enabled: Domain, Private." }
                                                        15 { WriteWordLine 0 2 "Enabled: Domain, Private, Public." }
                                                    }
                                                WriteWordLine 0 2 "IPv6 prefixes if required for DirectAccess or other intervening network devices. Use a comma to specifiy multiple entries: $($AgentConfig.WakeupProxyDirectAccessPrefixList)"
                                            }
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                20
                                    {
                                        WriteWordLine 0 2 "Endpoint Protection"
                                        WriteWordLine 0 2 "Manage Endpoint Protection client on client computers: $($AgentConfig.EnableEP)"
                                        WriteWordLine 0 2 "Install Endpoint Protection client on client computers: $($AgentConfig.InstallSCEPClient)"
                                        WriteWordLine 0 2 "Automatically remove previously installed antimalware software before Endpoint Protection is installed: $($AgentConfig.Remove3rdParty)"
                                        WriteWordLine 0 2 "Allow Endpoint Protection client installation and restarts outside maintenance windows. Maintenance windows must be at least 30 minutes long for client installation: $($AgentConfig.OverrideMaintenanceWindow)"
                                        WriteWordLine 0 2 "For Windows Embedded devices with write filters, commit Endpoint Protection client installation (requires restart): $($AgentConfig.PersistInstallation)"
                                        WriteWordLine 0 2 "Suppress any required computer restarts after the Endpoint Protection client is installed: $($AgentConfig.SuppressReboot)"
                                        WriteWordLine 0 2 "Allowed period of time users can postpone a required restart to complete the Endpoint Protection installation (hours): $($AgentConfig.ForceRebootPeriod)"
                                        WriteWordLine 0 2 "Disable alternate sources (such as Microsoft Windows Update, Microsoft Windows Server Update Services, or UNC shares) for the initial definition update on client computers: $($AgentConfig.DisableFirstSignatureUpdate)"
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                21
                                    {
                                        WriteWordLine 0 2 "Computer Restart"
                                        WriteWordLine 0 2 "Display a temporary notification to the user that indicates the interval before the user is logged of or the computer restarts (minutes): $($AgentConfig.RebootLogoffNotificationCountdownDuration)"
                                        WriteWordLine 0 2 "Display a dialog box that the user cannot close, which displays the countdown interval before the user is logged of or the computer restarts (minutes): $([string]$AgentConfig.RebootLogoffNotificationFinalWindow / 60)"
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                22
                                    {
                                        WriteWordLine 0 2 "Cloud Services"
                                        WriteWordLine 0 2 "Allow access to Cloud Distribution Point: $($AgentConfig.AllowCloudDP)"
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 0 "---------------------"
                                    }
                                23
                                    {
                                        WriteWordLine 0 2 "Metered Internet Connections"
                                        switch ($AgentConfig.MeteredNetworkUsage)
                                            {
                                                1 { $Usage = "Allow" }
                                                2 { $Usage = "Limit" }
                                                4 { $Usage = "Block" }
                                            }
                                        WriteWordLine 0 2 "Specifiy how clients communicate on metered network connections: $($Usage)"
                                        WriteWordLine 0 0 ""
                                    }

                            }
            }
        catch [System.Management.Automation.PropertyNotFoundException] 
            {
                WriteWordLine 0 0 ""
            }
    }
}
#### Security
Write-Verbose "Collecting all administrative users"
WriteWordLine 2 0 "Administrative Users"
$Admins = Get-CMAdministrativeUser

    WriteWordLine 0 1 "Enumerating administrative users:"
    $Table = $Null
    $TableRange = $Null
    $TableRange = $doc.Application.Selection.Range
	$Columns = 5
    [int]$Rows = $Admins.count + 1
	write-verbose "add Admin properties to table"
	$Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
	$table.Style = "Table Grid"
	$table.Borders.InsideLineStyle = 1
	$table.Borders.OutsideLineStyle = 1
	[int]$xRow = 1
	write-verbose "format first row with column headings"
	$Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
	$Table.Cell($xRow,1).Range.Font.Bold = $True
	$Table.Cell($xRow,1).Range.Font.Size = "10"
	$Table.Cell($xRow,1).Range.Text = "Account name"
	$Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
	$Table.Cell($xRow,2).Range.Font.Bold = $True
	$Table.Cell($xRow,2).Range.Font.Size = "10"
	$Table.Cell($xRow,2).Range.Text = "Account Type"
	$Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
	$Table.Cell($xRow,3).Range.Font.Bold = $True
	$Table.Cell($xRow,3).Range.Font.Size = "10"
	$Table.Cell($xRow,3).Range.Text = "Security Roles"
    $Table.Cell($xRow,4).Shading.BackgroundPatternColor = $wdColorGray15
	$Table.Cell($xRow,4).Range.Font.Bold = $True
	$Table.Cell($xRow,4).Range.Font.Size = "10"
	$Table.Cell($xRow,4).Range.Text = "Security Scopes"
    $Table.Cell($xRow,5).Shading.BackgroundPatternColor = $wdColorGray15
	$Table.Cell($xRow,5).Range.Font.Bold = $True
	$Table.Cell($xRow,5).Range.Font.Size = "10"
	$Table.Cell($xRow,5).Range.Text = "Collections"                      
    foreach ($Admin in $Admins)
		{
			$xRow++							
			$Table.Cell($xRow,1).Range.Font.Size = "10"
			$Table.Cell($xRow,1).Range.Text = $Admin.LogonName
			$Table.Cell($xRow,2).Range.Font.Size = "10"
            switch ($Admin.AccountType)
                {
                    0 { $Table.Cell($xRow,2).Range.Text = "User" }
                    1 { $Table.Cell($xRow,2).Range.Text = "Group" }
                    2 { $Table.Cell($xRow,2).Range.Text = "Machine" } 
                } 
			$Table.Cell($xRow,3).Range.Font.Size = "10"
			$Table.Cell($xRow,3).Range.Text = $Admin.RoleNames
            $Table.Cell($xRow,4).Range.Font.Size = "10"
			$Table.Cell($xRow,4).Range.Text = $Admin.CategoryNames
            $Table.Cell($xRow,5).Range.Font.Size = "10"
			$Table.Cell($xRow,5).Range.Text = $Admin.CollectionNames
		}
				
	$Table.Rows.SetLeftIndent(50,1) | Out-Null
	$table.AutoFitBehavior(1) | Out-Null

	#return focus back to document
	write-verbose "return focus back to document"
	$doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
    
#move to the end of the current document
write-verbose "move to the end of the current document"
$selection.EndKey($wdStory,$wdMove) | Out-Null
WriteWordLine 0 0 ""

#### enumerating all custom Security roles
Write-Verbose "enumerating all custom build security roles"
WriteWordLine 2 0 "Custom Security Roles"
$SecurityRoles = Get-CMSecurityRole | Where-Object {-not $_.IsBuiltIn}
if (-not [string]::IsNullOrEmpty($SecurityRoles ))
    {
        WriteWordLine 0 1 "Enumerating all custom build security roles:"
        $Table = $Null
        $TableRange = $Null
        $TableRange = $doc.Application.Selection.Range
	    $Columns = 5
        [int]$Rows = $SecurityRoles.count + 1
	    write-verbose "add security role properties to table"
	    $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
	    $table.Style = "Table Grid"
	    $table.Borders.InsideLineStyle = 1
	    $table.Borders.OutsideLineStyle = 1
	    [int]$xRow = 1
	    write-verbose "format first row with column headings"
	    $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
	    $Table.Cell($xRow,1).Range.Font.Bold = $True
	    $Table.Cell($xRow,1).Range.Font.Size = "10"
	    $Table.Cell($xRow,1).Range.Text = "Name"
	    $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
	    $Table.Cell($xRow,2).Range.Font.Bold = $True
	    $Table.Cell($xRow,2).Range.Font.Size = "10"
	    $Table.Cell($xRow,2).Range.Text = "Description"
	    $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
	    $Table.Cell($xRow,3).Range.Font.Bold = $True
	    $Table.Cell($xRow,3).Range.Font.Size = "10"
	    $Table.Cell($xRow,3).Range.Text = "Copied from"
        $Table.Cell($xRow,4).Shading.BackgroundPatternColor = $wdColorGray15
	    $Table.Cell($xRow,4).Range.Font.Bold = $True
	    $Table.Cell($xRow,4).Range.Font.Size = "10"
	    $Table.Cell($xRow,4).Range.Text = "Members"
        $Table.Cell($xRow,5).Shading.BackgroundPatternColor = $wdColorGray15
	    $Table.Cell($xRow,5).Range.Font.Bold = $True
	    $Table.Cell($xRow,5).Range.Font.Size = "10"
	    $Table.Cell($xRow,5).Range.Text = "Role ID"                      
        foreach ($SecurityRole in $SecurityRoles)
		    {
			    $xRow++							
			    $Table.Cell($xRow,1).Range.Font.Size = "10"
			    $Table.Cell($xRow,1).Range.Text = $SecurityRole.RoleName
			    $Table.Cell($xRow,2).Range.Font.Size = "10"
                $Table.Cell($xRow,2).Range.Text = $SecurityRole.RoleDescription
			    $Table.Cell($xRow,3).Range.Font.Size = "10"
			    $Table.Cell($xRow,3).Range.Text = (Get-CMSecurityRole -Id $SecurityRole.CopiedFromID).RoleName
                $Table.Cell($xRow,4).Range.Font.Size = "10"
                if ($SecurityRole.NumberOfAdmins -gt 0)
			        {
                        $Table.Cell($xRow,4).Range.Text = (Get-CMAdministrativeUser | Where-Object {$_.Roles -ilike "$($SecurityRole.RoleID)"}).LogonName
                    }
                $Table.Cell($xRow,5).Range.Font.Size = "10"
			    $Table.Cell($xRow,5).Range.Text = $SecurityRole.RoleID
		    }
				
	    $Table.Rows.SetLeftIndent(30,1) | Out-Null
	    $table.AutoFitBehavior(1) | Out-Null

	    #return focus back to document
	    write-verbose "return focus back to document"
	    $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
    
        #move to the end of the current document
        write-verbose "move to the end of the current document"
        $selection.EndKey($wdStory,$wdMove) | Out-Null
        WriteWordLine 0 0 ""
    }
else
    {
        WriteWordLine 0 1 "There are no custom built security roles."
    }

#### Used Accounts
Write-Verbose "Enumerating all used accounts"
WriteWordLine 2 0 "Configured Accounts"
$Accounts = Get-CMAccount
WriteWordLine 0 1 "Enumerating all accounts used for specific tasks."
    $Table = $Null
    $TableRange = $Null
    $TableRange = $doc.Application.Selection.Range
	$Columns = 3
    [int]$Rows = $Accounts.count + 1
	write-verbose "add security role properties to table"
	$Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
	$table.Style = "Table Grid"
	$table.Borders.InsideLineStyle = 1
	$table.Borders.OutsideLineStyle = 1
	[int]$xRow = 1
	write-verbose "format first row with column headings"
	$Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
	$Table.Cell($xRow,1).Range.Font.Bold = $True
	$Table.Cell($xRow,1).Range.Font.Size = "10"
	$Table.Cell($xRow,1).Range.Text = "User Name"
	$Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
	$Table.Cell($xRow,2).Range.Font.Bold = $True
	$Table.Cell($xRow,2).Range.Font.Size = "10"
	$Table.Cell($xRow,2).Range.Text = "Account Usage"
	$Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
	$Table.Cell($xRow,3).Range.Font.Bold = $True
	$Table.Cell($xRow,3).Range.Font.Size = "10"
	$Table.Cell($xRow,3).Range.Text = "Site Code"                     
    foreach ($Account in $Accounts)
		{
			$xRow++							
			$Table.Cell($xRow,1).Range.Font.Size = "10"
			$Table.Cell($xRow,1).Range.Text = $Account.UserName
			$Table.Cell($xRow,2).Range.Font.Size = "10"
            $Table.Cell($xRow,2).Range.Text = $Account.AccountUsage
			$Table.Cell($xRow,3).Range.Font.Size = "10"
			$Table.Cell($xRow,3).Range.Text = $Account.SiteCode
		}
				
	$Table.Rows.SetLeftIndent(30,1) | Out-Null
	$table.AutoFitBehavior(1) | Out-Null

	#return focus back to document
	write-verbose "return focus back to document"
	$doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
    
#move to the end of the current document
write-verbose "move to the end of the current document"
$selection.EndKey($wdStory,$wdMove) | Out-Null
WriteWordLine 0 0 ""
############################################################################################

####
#### Assets and Compliance
####
Write-Verbose "Done with Administration, next Assets and Compliance"
WriteWordLine 1 0 "Assets and Compliance"

#### enumerating all User Collections
WriteWordLine 2 0 "Summary of User Collections"
$UserCollections = Get-CMUserCollection
if ($ListAllInformation)
    {
        foreach ($UserCollection in $UserCollections)
            {
                Write-Verbose "Found User Collection: $($UserCollection.Name)"
                WriteWordLine 0 1 "Collection Name: $($UserCollection.Name)" -bold
                WriteWordLine 0 1 "Collection ID: $($UserCollection.CollectionID)"
                WriteWordLine 0 1 "Total count of members: $($UserCollection.MemberCount)"
                WriteWordLine 0 1 "Limited to User Collection: $($UserCollection.LimitToCollectionName) / $($UserCollection.LimitToCollectionID)"
                WriteWordLine 0 0 ""
            }
    }
else
    {
     WriteWordLine 0 1 "There are $($UserCollections.count) User Collections." 
    }

####
#### enumerating all Device Collections
WriteWordLine 2 0 "Summary of Device Collections"
$DeviceCollections = Get-CMDeviceCollection
if ($ListAllInformation)
    {
        foreach ($DeviceCollection in $DeviceCollections)
            {
                Write-Verbose "Found Device Collection: $($DeviceCollection.Name)"
                WriteWordLine 0 1 "Collection Name: $($DeviceCollection.Name)" -bold
                WriteWordLine 0 1 "Collection ID: $($DeviceCollection.CollectionID)"
                WriteWordLine 0 1 "Total count of members: $($DeviceCollection.MemberCount)"
                WriteWordLine 0 1 "Limited to Device Collection: $($DeviceCollection.LimitToCollectionName) / $($DeviceCollection.LimitToCollectionID)"
                $CollSettings = Get-WmiObject -Class SMS_CollectionSettings -Namespace root\sms\site_$SiteCode -ComputerName $SMSProvider | Where-Object {$_.CollectionID -eq "$($DeviceCollection.CollectionID)"}
                if (-not [String]::IsNullOrEmpty($CollSettings))
                    {
                        $CollSettings = [wmi]$CollSettings.__PATH
                        $ServiceWindows = $($CollSettings.ServiceWindows)
                        if (-not [string]::IsNullOrEmpty($ServiceWindows))
                            {
                                #$ServiceWindows
                                WriteWordLine 0 2 "Checking Maintenance Windows on Collection:" 
                                #$ServiceWindows = [wmi]$ServiceWindows.__PATH
                        
                                foreach ($ServiceWindow in $ServiceWindows)
                                    {
                
                                        $ScheduleString = Read-ScheduleToken
                                        $startTime = $ScheduleString.TokenData.starttime
                                        $startTime = Convert-NormalDateToConfigMgrDate -starttime $startTime
                                        WriteWordLine 0 3 "Maintenance window name: $($ServiceWindow.Name)"
                                        switch ($ServiceWindow.ServiceWindowType)
                                            {
                                                0 {WriteWordLine 0 3 "This is a Task Sequence maintenance window"}
                                                1 {WriteWordLine 0 3 "This is a general maintenance window"}                        
                                            }   
                                        switch ($ServiceWindow.RecurrenceType)
                                            {
                                                1 {WriteWordLine 0 3 "This maintenance window occurs only once on $($startTime) and lasts for $($ScheduleString.TokenData.HourDuration) hour(s) and $($ScheduleString.TokenData.MinuteDuration) minute(s)."}
                                                2 
                                                    {
                                                        if ($ScheduleString.TokenData.DaySpan -eq "1")
                                                            {
                                                                $daily = "daily"
                                                            }
                                                        else
                                                            {
                                                                $daily = "every $($ScheduleString.TokenData.DaySpan) days"
                                                            }
                        
                                                        WriteWordLine 0 3 "This maintenance window occurs $($daily)."
                                                    }
                                                3 
                                                    {                                              
                                                        WriteWordLine 0 3 "This maintenance window occurs every $($ScheduleString.TokenData.ForNumberofWeeks) week(s) on $(Convert-WeekDay $ScheduleString.TokenData.Day) and lasts $($ScheduleString.TokenData.HourDuration) hour(s) and $($ScheduleString.TokenData.MinuteDuration) minute(s) starting on $($startTime)."
                                                    }
                                                4 
                                                    {
                                                        switch ($ScheduleString.TokenData.weekorder)
                                                            {
                                                                0 {$order = "last"}
                                                                1 {$order = "first"}
                                                                2 {$order = "second"}
                                                                3 {$order = "third"}
                                                                4 {$order = "fourth"}
                                                            }
                                                        WriteWordLine 0 3 "This maintenance window occurs every $($ScheduleString.TokenData.ForNumberofMonths) month(s) on every $($order) $(Convert-WeekDay $ScheduleString.TokenData.Day)"
                                                    }

                                                5 
                                                    {
                                                        if ($ScheduleString.TokenData.MonthDay -eq "0")
                                                            { 
                                                                $DayOfMonth = "the last day of the month"
                                                            }
                                                        else
                                                            {
                                                                $DayOfMonth = "day $($ScheduleString.TokenData.MonthDay)"
                                                            }
                                                        WriteWordLine 0 3 "This maintenance window occurs every $($ScheduleString.TokenData.ForNumberofMonths) month(s) on $($DayOfMonth)."
                                                        WriteWordLine 0 3 "It lasts $($ScheduleString.TokenData.HourDuration) hours and $($ScheduleString.TokenData.MinuteDuration) minutes."
                                                    }
                                            }
                                        switch ($ServiceWindow.IsEnabled)
                                            {
                                                true {WriteWordLine 0 3 "The maintenance window is enabled"}
                                                false {WriteWordLine 0 3 "The maintenance window is disabled"}
                                            }
                                    }
                            }
                        else
                            {
                                WriteWordLine 0 2 "No maintenance windows configured on this collection."
                            }
                    }  
                        try
                            {
                                $CollVars = $CollSettings.CollectionVariables               
                                if (-not [string]::IsNullOrEmpty($CollVars))
                                    {
                                        WriteWordLine 0 1 "Enumerating device collection variables:"
                                        $Table = $Null
                                        $TableRange = $Null
                                        $TableRange = $doc.Application.Selection.Range
				                        $Columns = 3
                                        [int]$Rows = $CollVars.count + 1
				                        write-verbose "add Collection variables to table"
				                        $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
				                        $table.Style = "Table Grid"
				                        $table.Borders.InsideLineStyle = 1
				                        $table.Borders.OutsideLineStyle = 1
				                        [int]$xRow = 1
				                        write-verbose "format first row with column headings"
				                        $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
				                        $Table.Cell($xRow,1).Range.Font.Bold = $True
				                        $Table.Cell($xRow,1).Range.Font.Size = "10"
				                        $Table.Cell($xRow,1).Range.Text = "Variable name"
				                        $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
				                        $Table.Cell($xRow,2).Range.Font.Bold = $True
				                        $Table.Cell($xRow,2).Range.Font.Size = "10"
				                        $Table.Cell($xRow,2).Range.Text = "Value"
				                        $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
				                        $Table.Cell($xRow,3).Range.Font.Bold = $True
				                        $Table.Cell($xRow,3).Range.Font.Size = "10"
				                        $Table.Cell($xRow,3).Range.Text = "Is Masked"                      
                                        foreach ($CollVar in $CollVars)
				                            {
					                            $xRow++							
					                            $Table.Cell($xRow,1).Range.Font.Size = "10"
					                            $Table.Cell($xRow,1).Range.Text = $CollVar.Name
					                            $Table.Cell($xRow,2).Range.Font.Size = "10"
					                            $Table.Cell($xRow,2).Range.Text = $CollVar.Value
					                            $Table.Cell($xRow,3).Range.Font.Size = "10"
					                            $Table.Cell($xRow,3).Range.Text = $CollVar.IsMasked
					                        }
				
				                        $Table.Rows.SetLeftIndent(50,1) | Out-Null
				                        $table.AutoFitBehavior(1) | Out-Null

				                        #return focus back to document
				                        write-verbose "return focus back to document"
				                        $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
                                        #move to the end of the current document
				                        write-verbose "move to the end of the current document"
				                        $selection.EndKey($wdStory,$wdMove) | Out-Null
				                        WriteWordLine 0 0 ""
                                    }
                                else 
                                    {
                                        WriteWordLine 0 1 "Enumerating device collection variables: No device collection variables configured!"
                                    }
                        }
                    catch [System.Management.Automation.PropertyNotFoundException] 
                            {
                                WriteWordLine 0 0 ""
                            }
            ### enumerating the Collection Membership Rules
                    $QueryRules = $Null
                    $DirectRules = $Null
                    $CollectionRules = $DeviceCollection.CollectionRules
                    try 
                        {
                            $DirectRules = $CollectionRules | where {$_.ResourceID} -ErrorAction SilentlyContinue
                        }
                    catch [System.Management.Automation.PropertyNotFoundException] 
                            {
                                WriteWordLine 0 0 ""
                            }
                    try
                        {
                            $QueryRules = $CollectionRules | where {$_.QueryExpression} -ErrorAction SilentlyContinue                            
                        }
                    catch [System.Management.Automation.PropertyNotFoundException] 
                        {
                            WriteWordLine 0 0 ""
                        }
            if ($QueryRules)
                    {
                        WriteWordLine 0 1 "Enumerating device collection query membership rules:"
                        $Table = $Null
                        $TableRange = $Null
                        $TableRange = $doc.Application.Selection.Range
				        $Columns = 3
                        [int]$Rows = $CollectionRules.count + 1
				        write-verbose "add Collection variables to table"
				        $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
				        $table.Style = "Table Grid"
				        $table.Borders.InsideLineStyle = 1
				        $table.Borders.OutsideLineStyle = 1
				        [int]$xRow = 1
				        write-verbose "format first row with column headings"
				        $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
				        $Table.Cell($xRow,1).Range.Font.Bold = $True
				        $Table.Cell($xRow,1).Range.Font.Size = "10"
				        $Table.Cell($xRow,1).Range.Text = "Query name"
				        $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
				        $Table.Cell($xRow,2).Range.Font.Bold = $True
				        $Table.Cell($xRow,2).Range.Font.Size = "10"
				        $Table.Cell($xRow,2).Range.Text = "Query Expression"
				        $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
				        $Table.Cell($xRow,3).Range.Font.Bold = $True
				        $Table.Cell($xRow,3).Range.Font.Size = "10"
				        $Table.Cell($xRow,3).Range.Text = "Query ID"
                        foreach ($QueryRule in $QueryRules)
                            {
                                $xRow++							
					            $Table.Cell($xRow,1).Range.Font.Size = "10"
					            $Table.Cell($xRow,1).Range.Text = $QueryRule.RuleName
					            $Table.Cell($xRow,2).Range.Font.Size = "10"
					            $Table.Cell($xRow,2).Range.Text = $QueryRule.QueryExpression
					            $Table.Cell($xRow,3).Range.Font.Size = "10"
					            $Table.Cell($xRow,3).Range.Text = $QueryRule.QueryID    
                            }				
				        $Table.Rows.SetLeftIndent(50,1) | Out-Null
				        $table.AutoFitBehavior(1) | Out-Null
				        #return focus back to document
				        write-verbose "return focus back to document"
				        $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
                        #move to the end of the current document
			            write-verbose "move to the end of the current document"
			            $selection.EndKey($wdStory,$wdMove) | Out-Null
			            WriteWordLine 0 0 ""
                    }
            if ($DirectRules)
                    {
                            WriteWordLine 0 1 "Enumerating device collection direct membership rules:"
                            $Table = $Null
                            $TableRange = $Null
                            $TableRange = $doc.Application.Selection.Range
				            $Columns = 2
                            [int]$Rows = $CollectionRules.count + 1
				            write-verbose "add Collection variables to table"
				            $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
				            $table.Style = "Table Grid"
				            $table.Borders.InsideLineStyle = 1
				            $table.Borders.OutsideLineStyle = 1
				            [int]$xRow = 1
				            write-verbose "format first row with column headings"
				            $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
				            $Table.Cell($xRow,1).Range.Font.Bold = $True
				            $Table.Cell($xRow,1).Range.Font.Size = "10"
				            $Table.Cell($xRow,1).Range.Text = "Resource name"
				            $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
				            $Table.Cell($xRow,2).Range.Font.Bold = $True
				            $Table.Cell($xRow,2).Range.Font.Size = "10"
				            $Table.Cell($xRow,2).Range.Text = "Resource ID"
                            foreach ($DirectRule in $DirectRules)
                                {
                                    $xRow++							
					                $Table.Cell($xRow,1).Range.Font.Size = "10"
					                $Table.Cell($xRow,1).Range.Text = $DirectRule.RuleName
					                $Table.Cell($xRow,2).Range.Font.Size = "10"
					                $Table.Cell($xRow,2).Range.Text = $DirectRule.ResourceID   
                                }				
				            $Table.Rows.SetLeftIndent(50,1) | Out-Null
				            $table.AutoFitBehavior(1) | Out-Null
				            #return focus back to document
				            write-verbose "return focus back to document"
				            $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
                            #move to the end of the current document
			                write-verbose "move to the end of the current document"
			                $selection.EndKey($wdStory,$wdMove) | Out-Null
			                WriteWordLine 0 0 ""
                    }
                else 
                    {
                        WriteWordLine 0 1 "Enumerating device collection membership rules: No device collection direct membership rules configured!"
                    }
    
			        #move to the end of the current document
			        write-verbose "move to the end of the current document"
			        $selection.EndKey($wdStory,$wdMove) | Out-Null
			        WriteWordLine 0 0 ""
            }
    }

else
    {
        WriteWordLine 0 1 "There are $($DeviceCollections.count) Device collections."
    }

Write-Verbose "Working on Compliance Settings"
WriteWordLine 2 0 "Compliance Settings"
WriteWordLine 0 0 ""
WriteWordLine 3 0 "Configuration Items"

$CIs = Get-CMConfigurationItem
    WriteWordLine 0 1 "Enumerating Configuration Items:"
    $Table = $Null
    $TableRange = $Null
    $TableRange = $doc.Application.Selection.Range
    $Columns = 4
    [int]$Rows = $CIs.count + 1
    write-verbose "add configuration items to table"
    $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
    $table.Style = "Table Grid"
    $table.Borders.InsideLineStyle = 1
    $table.Borders.OutsideLineStyle = 1
    [int]$xRow = 1
    write-verbose "format first row with column headings"
    $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
    $Table.Cell($xRow,1).Range.Font.Bold = $True
    $Table.Cell($xRow,1).Range.Font.Size = "10"
    $Table.Cell($xRow,1).Range.Text = "Name"
    $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
    $Table.Cell($xRow,2).Range.Font.Bold = $True
    $Table.Cell($xRow,2).Range.Font.Size = "10"
    $Table.Cell($xRow,2).Range.Text = "Last modified"
    $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
    $Table.Cell($xRow,3).Range.Font.Bold = $True
    $Table.Cell($xRow,3).Range.Font.Size = "10"
    $Table.Cell($xRow,3).Range.Text = "Last modified by"
    $Table.Cell($xRow,4).Shading.BackgroundPatternColor = $wdColorGray15
    $Table.Cell($xRow,4).Range.Font.Bold = $True
    $Table.Cell($xRow,4).Range.Font.Size = "10"
    $Table.Cell($xRow,4).Range.Text = "CI ID"
    foreach ($CI in $CIs)
        {
            $xRow++							
		    $Table.Cell($xRow,1).Range.Font.Size = "10"
		    $Table.Cell($xRow,1).Range.Text = $CI.LocalizedDisplayName
		    $Table.Cell($xRow,2).Range.Font.Size = "10"
		    $Table.Cell($xRow,2).Range.Text = $CI.DateLastModified
            $Table.Cell($xRow,3).Range.Font.Size = "10"
		    $Table.Cell($xRow,3).Range.Text = $CI.LastModifiedBy
            $Table.Cell($xRow,4).Range.Font.Size = "10"
		    $Table.Cell($xRow,4).Range.Text = $CI.CI_ID   
        }				
    $Table.Rows.SetLeftIndent(50,1) | Out-Null
    $table.AutoFitBehavior(1) | Out-Null
    #return focus back to document
    write-verbose "return focus back to document"
    $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
    #move to the end of the current document
    write-verbose "move to the end of the current document"
    $selection.EndKey($wdStory,$wdMove) | Out-Null
    WriteWordLine 0 0 ""
    
    #move to the end of the current document
    write-verbose "move to the end of the current document"
    $selection.EndKey($wdStory,$wdMove) | Out-Null
    WriteWordLine 0 0 ""

WriteWordLine 3 0 "Configuration Baselines"
$CBs = Get-CMBaseline
if (-not [string]::IsNullOrEmpty($CBs))
    {
        WriteWordLine 0 1 "Enumerating Configuration Baselines:"
        $Table = $Null
        $TableRange = $Null
        $TableRange = $doc.Application.Selection.Range
        $Columns = 4
        [int]$Rows = $CBs.count + 1
        write-verbose "add configuration items to table"
        $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
        $table.Style = "Table Grid"
        $table.Borders.InsideLineStyle = 1
        $table.Borders.OutsideLineStyle = 1
        [int]$xRow = 1
        write-verbose "format first row with column headings"
        $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,1).Range.Font.Bold = $True
        $Table.Cell($xRow,1).Range.Font.Size = "10"
        $Table.Cell($xRow,1).Range.Text = "Name"
        $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,2).Range.Font.Bold = $True
        $Table.Cell($xRow,2).Range.Font.Size = "10"
        $Table.Cell($xRow,2).Range.Text = "Last modified"
        $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,3).Range.Font.Bold = $True
        $Table.Cell($xRow,3).Range.Font.Size = "10"
        $Table.Cell($xRow,3).Range.Text = "Last modified by"
        $Table.Cell($xRow,4).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,4).Range.Font.Bold = $True
        $Table.Cell($xRow,4).Range.Font.Size = "10"
        $Table.Cell($xRow,4).Range.Text = "CI ID"
        foreach ($CB in $CBs)
            {
                $xRow++							
		        $Table.Cell($xRow,1).Range.Font.Size = "10"
		        $Table.Cell($xRow,1).Range.Text = $CB.LocalizedDisplayName
		        $Table.Cell($xRow,2).Range.Font.Size = "10"
		        $Table.Cell($xRow,2).Range.Text = $CB.DateLastModified
                $Table.Cell($xRow,3).Range.Font.Size = "10"
		        $Table.Cell($xRow,3).Range.Text = $CB.LastModifiedBy
                $Table.Cell($xRow,4).Range.Font.Size = "10"
		        $Table.Cell($xRow,4).Range.Text = $CB.CI_ID   
            }				
        $Table.Rows.SetLeftIndent(50,1) | Out-Null
        $table.AutoFitBehavior(1) | Out-Null
        #return focus back to document
        write-verbose "return focus back to document"
        $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
        #move to the end of the current document
        write-verbose "move to the end of the current document"
        $selection.EndKey($wdStory,$wdMove) | Out-Null
        WriteWordLine 0 0 ""
    
        #move to the end of the current document
        write-verbose "move to the end of the current document"
        $selection.EndKey($wdStory,$wdMove) | Out-Null
        WriteWordLine 0 0 ""
    }
else
    {
        WriteWordLine 0 1 "There are no Configuration Baselines configured."
    }

### User Data and Profiles
Write-Verbose "Working on User Data and Profiles"
WriteWordLine 3 0 "User Data and Profiles"
$UserDataProfiles = Get-CMUserDataAndProfileConfigurationItem
if (-not [string]::IsNullOrEmpty($UserDataProfiles))
    {
        WriteWordLine 0 1 "Enumerating User Data and Profiles:"
        $Table = $Null
        $TableRange = $Null
        $TableRange = $doc.Application.Selection.Range
        $Columns = 4
        [int]$Rows = $UserDataProfiles.count + 1
        write-verbose "add configuration items to table"
        $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
        $table.Style = "Table Grid"
        $table.Borders.InsideLineStyle = 1
        $table.Borders.OutsideLineStyle = 1
        [int]$xRow = 1
        write-verbose "format first row with column headings"
        $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,1).Range.Font.Bold = $True
        $Table.Cell($xRow,1).Range.Font.Size = "10"
        $Table.Cell($xRow,1).Range.Text = "Name"
        $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,2).Range.Font.Bold = $True
        $Table.Cell($xRow,2).Range.Font.Size = "10"
        $Table.Cell($xRow,2).Range.Text = "Last modified"
        $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,3).Range.Font.Bold = $True
        $Table.Cell($xRow,3).Range.Font.Size = "10"
        $Table.Cell($xRow,3).Range.Text = "Last modified by"
        $Table.Cell($xRow,4).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,4).Range.Font.Bold = $True
        $Table.Cell($xRow,4).Range.Font.Size = "10"
        $Table.Cell($xRow,4).Range.Text = "CI ID"
        foreach ($UserDataProfile in $UserDataProfiles)
            {
                $xRow++							
		        $Table.Cell($xRow,1).Range.Font.Size = "10"
		        $Table.Cell($xRow,1).Range.Text = $UserDataProfile.LocalizedDisplayName
		        $Table.Cell($xRow,2).Range.Font.Size = "10"
		        $Table.Cell($xRow,2).Range.Text = $UserDataProfile.DateLastModified
                $Table.Cell($xRow,3).Range.Font.Size = "10"
		        $Table.Cell($xRow,3).Range.Text = $UserDataProfile.LastModifiedBy
                $Table.Cell($xRow,4).Range.Font.Size = "10"
		        $Table.Cell($xRow,4).Range.Text = $UserDataProfile.CI_ID   
            }				
        $Table.Rows.SetLeftIndent(50,1) | Out-Null
        $table.AutoFitBehavior(1) | Out-Null
        #return focus back to document
        write-verbose "return focus back to document"
        $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
        #move to the end of the current document
        write-verbose "move to the end of the current document"
        $selection.EndKey($wdStory,$wdMove) | Out-Null
        WriteWordLine 0 0 ""
    
        #move to the end of the current document
        write-verbose "move to the end of the current document"
        $selection.EndKey($wdStory,$wdMove) | Out-Null
        WriteWordLine 0 0 ""
    }
else
    {
        WriteWordLine 0 1 "There are no User Data and Profile configurations configured."
    }


Write-Verbose "Working on Endpoint Protection"
WriteWordLine 2 0 "Endpoint Protection"

WriteWordLine 3 0 "Antimalware Policies"
$AntiMalwarePolicies = Get-CMAntimalwarePolicy
if (-not [string]::IsNullOrEmpty($AntiMalwarePolicies))
    {
        foreach ($AntiMalwarePolicy in $AntiMalwarePolicies)
            {
                if ($AntiMalwarePolicy.Name -eq "Default Client Antimalware Policy")
                    {
                        $AgentConfig = $AntiMalwarePolicy.AgentConfiguration
                        WriteWordLine 0 1 "$($AntiMalwarePolicy.Name)" -bold
                        WriteWordLine 0 1 "Description: $($AntiMalwarePolicy.Description)"
                        WriteWordLine 0 2 "Scheduled Scans" -bold
                        WriteWordLine 0 3 "Run a scheduled scan on client computers: $($AgentConfig.EnableScheduledScan)"
                        if ($AgentConfig.EnableScheduledScan)
                            {
                                switch ($AgentConfig.ScheduledScanType)
                                    {
                                        1 { $ScheduledScanType = "Quick Scan" }
                                        2 { $ScheduledScanType = "Full Scan" }
                                    }
                                WriteWordLine 0 3 "Scan type: $($ScheduledScanType)"
                                WriteWordLine 0 3 "Scan day: $(Convert-WeekDay $AgentConfig.ScheduledScanWeekDay)"
                                WriteWordLine 0 3 "Scan time: $(Convert-Time -time $AgentConfig.ScheduledScanTime)"
                                WriteWordLine 0 3 "Run a daily quick scan on client computers: $($AgentConfig.EnableQuickDailyScan)"
                                WriteWordLine 0 3 "Daily quick scan schedule time: $(Convert-Time -time $AgentConfig.ScheduledScanQuickTime)"
                                WriteWordLine 0 3 "Check for the latest definition updates before running a scan: $($AgentConfig.CheckLatestDefinition)"
                                WriteWordLine 0 3 "Start a scheduled scan only when the computer is idle: $($AgentConfig.ScanWhenClientNotInUse)"
                                WriteWordLine 0 3 "Force a scan of the selected scan type if client computer is offline during two or more scheduled scans: $($AgentConfig.EnableCatchupScan)"
                                WriteWordLine 0 3 "Limit CPU usage during scans to (%): $($AgentConfig.LimitCPUUsage)"
                            }
                        WriteWordLine 0 0 ""
                        WriteWordLine 0 2 "Scan settings" -bold
                        WriteWordLine 0 3 "Scan email and email attachments: $($AgentConfig.ScanEmail)"
                        WriteWordLine 0 3 "Scan removable storage devices such as USB drives: $($AgentConfig.ScanRemovableStorage)"
                        WriteWordLine 0 3 "Scan network drives when running a full scan: $($AgentConfig.ScanNetworkDrives)"
                        WriteWordLine 0 3 "Scan archived files: $($AgentConfig.ScanArchivedFiles)"
                        WriteWordLine 0 3 "Allow users to configure CPU usage during scans: $($AgentConfig.AllowClientUserConfigLimitCPUUsage)"
                        WriteWordLine 0 3 "User control of scheduled scans: " -nonewline
                        switch ($AgentConfig.ScheduledScanUserControl)
                            {
                                0 { WriteWordLine 0 0 "No control" }
                                1 { WriteWordLine 0 0 "Scan time only" }
                                2 { WriteWordLine 0 0 "Full control" }
                            }
                        WriteWordLine 0 2 "Default Actions" -bold
                        WriteWordLine 0 3 "Severe threats: " -nonewline
                        switch ($AgentConfig.DefaultActionSevere)
                            {
                                0 { WriteWordLine 0 0 "Recommended" }
                                2 { WriteWordLine 0 0 "Quarantine" }
                                3 { WriteWordLine 0 0 "Remove" }
                                6 { WriteWordLine 0 0 "Allow" }
                            }
                        WriteWordLine 0 3 "High threats: " -nonewline
                        switch ($AgentConfig.DefaultActionSevere)
                            {
                                0 { WriteWordLine 0 0 "Recommended" }
                                2 { WriteWordLine 0 0 "Quarantine" }
                                3 { WriteWordLine 0 0 "Remove" }
                                6 { WriteWordLine 0 0 "Allow" }
                            }
                        WriteWordLine 0 3 "Medium threats: " -nonewline
                        switch ($AgentConfig.DefaultActionSevere)
                            {
                                0 { WriteWordLine 0 0 "Recommended" }
                                2 { WriteWordLine 0 0 "Quarantine" }
                                3 { WriteWordLine 0 0 "Remove" }
                                6 { WriteWordLine 0 0 "Allow" }
                            }
                        WriteWordLine 0 3 "Low threats: " -nonewline
                        switch ($AgentConfig.DefaultActionSevere)
                            {
                                0 { WriteWordLine 0 0 "Recommended" }
                                2 { WriteWordLine 0 0 "Quarantine" }
                                3 { WriteWordLine 0 0 "Remove" }
                                6 { WriteWordLine 0 0 "Allow" }
                            }
                        WriteWordLine 0 2 "Real-time protection" -bold
                        WriteWordLine 0 3 "Enable real-time protection: $($AgentConfig.RealtimeProtectionOn)"
                        WriteWordLine 0 3 "Monitor file and program activity on your computer: $($AgentConfig.MonitorFileProgramActivity)"
                        WriteWordLine 0 3 "Scan system files: " -nonewline
                        switch ($AgentConfig.RealtimeScanOption)
                            {
                                0 { WriteWordLine 0 0 "Scan incoming and outgoing files" }
                                1 { WriteWordLine 0 0 "Scan incoming files only" }
                                2 { WriteWordLine 0 0 "Scan outgoing files only" }
                            }
                        WriteWordLine 0 2 "Exclusion settings" -bold
                        WriteWordLine 0 3 "Excluded files and folders: "
                        foreach ($ExcludedFileFolder in $AgentConfig.ExcludedFilePaths)
                            {
                                WriteWordLine 0 4 "$($ExcludedFileFolder)"
                            }
                        WriteWordLine 0 3 "Excluded file types: "
                        foreach ($ExcludedFileType in $AgentConfig.ExcludedFileTypes)
                            {
                                WriteWordLine 0 4 "$($ExcludedFileType)"
                            }
                        WriteWordLine 0 3 "Excluded processes: "
                        foreach ($ExcludedProcess in $AgentConfig.ExcludedProcesses)
                            {
                                WriteWordLine 0 4 "$($ExcludedProcess)"
                            }
                        WriteWordLine 0 2 "Advanced" -bold
                        WriteWordLine 0 3 "Create a system restore point before computers are cleaned: $($AgentConfig.CreateSystemRestorePointBeforeClean)"
                        WriteWordLine 0 3 "Disable the client user interface: $($AgentConfig.DisableClientUI)"
                        WriteWordLine 0 3 "Show notifications messages on the client computer when the user needs to run a full scan, update definitions, or run Windows Defender Offline: $($AgentConfig.ShowNotificationMessages)"
                        WriteWordLine 0 3 "Delete quarantined files after (days): $($AgentConfig.DeleteQuarantinedFilesPeriod)"
                        WriteWordLine 0 3 "Allow users to configure the setting for quarantined file deletion: $($AgentConfig.AllowUserConfigQuarantinedFileDeletionPeriod)"
                        WriteWordLine 0 3 "Allow users to exclude file and folders, file types and processes: $($AgentConfig.AllowUserAddExcludes)"
                        WriteWordLine 0 3 "Allow all users to view the full History results: $($AgentConfig.AllowUserViewHistory)"
                        WriteWordLine 0 3 "Enable reparse point scanning: $($AgentConfig.EnableReparsePointScanning)"
                        WriteWordLine 0 3 "Randomize scheduled scan and definition update start time (within 30 minutes): $($AgentConfig.RandomizeScheduledScanStartTime)"
        
                        WriteWordLine 0 2 "Threat overrides" -bold
                        if (-not [string]::IsNullOrEmpty($AgentConfig.ThreatName))
                            {
                                WriteWordLine 0 3 "Threat name and override action: Threats specified."
                            }
                        WriteWordLine 0 2 "Microsoft Active Protection Service" -bold
                        WriteWordLine 0 3 "Microsoft Active Protection Service membership type: " -nonewline
                        switch ($AgentConfig.JoinSpyNet)
                            {
                                0 { WriteWordLine 0 0 "Do not join MAPS" }
                                1 { WriteWordLine 0 0 "Basic membership" }
                                2 { WriteWordLine 0 0 "Advanced membership" }
                            }
                        WriteWordLine 0 3 "Allow users to modify Microsoft Active Protection Service settings: $($AgentConfig.AllowUserChangeSpyNetSettings)"

                        WriteWordLine 0 2 "Definition Updates" -bold
                        WriteWordLine 0 3 "Check for Endpoint Protection definitions at a specific interval (hours): (0 disable check on interval) $($AgentConfig.SignatureUpdateInterval)"
                        WriteWordLine 0 3 "Check for Endpoint Protection definitions daily at: (Only configurable if interval-based check is disabled) $(Convert-Time -time $AgentConfig.SignatureUpdateTime)"
                        WriteWordLine 0 3 "Force a definition update if the client computer is offline for more than two consecutive scheduled updates: $($AgentConfig.EnableSignatureUpdateCatchupInterval)"
                        WriteWordLine 0 3 "Set sources and order for Endpoint Protection definition updates: "
                        foreach ($Fallback in $AgentConfig.FallbackOrder)
                            {
                                WriteWordLine 0 3 "$($Fallback)"
                            }
                        WriteWordLine 0 3 "If Configuration Manager is used as a source for definition updates, clients will only update from alternative sources if definition is older than (hours): $($AgentConfig.AuGracePeriod / 60)"
                        WriteWordLine 0 3 "If UNC file shares are selected as a definition update source, specify the UNC paths:" 
                        foreach ($UNCShare in $AgentConfig.DefinitionUpdateFileSharesSources)
                            {
                                WriteWordLine 0 4 "$($UNCShare)"
                            }
                    }
            else
                {
                    $AgentConfig_custom = $AntiMalwarePolicy.AgentConfigurations
                    WriteWordLine 0 1 "$($AntiMalwarePolicy.Name)" -bold
                    WriteWordLine 0 1 "Description: $($AntiMalwarePolicy.Description)"
                    foreach ($Agentconfig in $AgentConfig_custom)
                        {
                            switch ($AgentConfig.AgentID)
                                {
                                    201 
                                        {
                                            WriteWordLine 0 2 "Scheduled Scans" -bold
                                            WriteWordLine 0 2 "Run a scheduled scan on client computers: $($AgentConfig.EnableScheduledScan)"
                                            if ($AgentConfig.EnableScheduledScan)
                                                {
                                                    switch ($AgentConfig.ScheduledScanType)
                                                        {
                                                            1 { $ScheduledScanType = "Quick Scan" }
                                                            2 { $ScheduledScanType = "Full Scan" }
                                                        }
                                                    WriteWordLine 0 3 "Scan type: $($ScheduledScanType)"
                                                    WriteWordLine 0 3 "Scan day: $(Convert-WeekDay $AgentConfig.ScheduledScanWeekDay)"
                                                    WriteWordLine 0 3 "Scan time: $(Convert-Time -time $AgentConfig.ScheduledScanTime)"
                                                    WriteWordLine 0 3 "Run a daily quick scan on client computers: $($AgentConfig.EnableQuickDailyScan)"
                                                    WriteWordLine 0 3 "Daily quick scan schedule time: $(Convert-Time -time $AgentConfig.ScheduledScanQuickTime)"
                                                    WriteWordLine 0 3 "Check for the latest definition updates before running a scan: $($AgentConfig.CheckLatestDefinition)"
                                                    WriteWordLine 0 3 "Start a scheduled scan only when the computer is idle: $($AgentConfig.ScanWhenClientNotInUse)"
                                                    WriteWordLine 0 3 "Force a scan of the selected scan type if client computer is offline during two or more scheduled scans: $($AgentConfig.EnableCatchupScan)"
                                                    WriteWordLine 0 3 "Limit CPU usage during scans to (%): $($AgentConfig.LimitCPUUsage)"
                                                }
                                        }
                                    202
                                        {
                                            WriteWordLine 0 2 "Default Actions" -bold
                                            WriteWordLine 0 3 "Severe threats: " -nonewline
                                            switch ($AgentConfig.DefaultActionSevere)
                                                {
                                                    0 { WriteWordLine 0 0 "Recommended" }
                                                    2 { WriteWordLine 0 0 "Quarantine" }
                                                    3 { WriteWordLine 0 0 "Remove" }
                                                    6 { WriteWordLine 0 0 "Allow" }
                                                }
                                            WriteWordLine 0 3 "High threats: " -nonewline
                                            switch ($AgentConfig.DefaultActionSevere)
                                                {
                                                    0 { WriteWordLine 0 0 "Recommended" }
                                                    2 { WriteWordLine 0 0 "Quarantine" }
                                                    3 { WriteWordLine 0 0 "Remove" }
                                                    6 { WriteWordLine 0 0 "Allow" }
                                                }
                                            WriteWordLine 0 3 "Medium threats: " -nonewline
                                            switch ($AgentConfig.DefaultActionSevere)
                                                {
                                                    0 { WriteWordLine 0 0 "Recommended" }
                                                    2 { WriteWordLine 0 0 "Quarantine" }
                                                    3 { WriteWordLine 0 0 "Remove" }
                                                    6 { WriteWordLine 0 0 "Allow" }
                                                }
                                            WriteWordLine 0 3 "Low threats: " -nonewline
                                            switch ($AgentConfig.DefaultActionSevere)
                                                {
                                                    0 { WriteWordLine 0 0 "Recommended" }
                                                    2 { WriteWordLine 0 0 "Quarantine" }
                                                    3 { WriteWordLine 0 0 "Remove" }
                                                    6 { WriteWordLine 0 0 "Allow" }
                                                }                                           
                                        }
                                    203
                                        {
                                            WriteWordLine 0 2 "Exclusion settings" -bold
                                            WriteWordLine 0 3 "Excluded files and folders: "
                                            foreach ($ExcludedFileFolder in $AgentConfig.ExcludedFilePaths)
                                                {
                                                    WriteWordLine 0 4 "$($ExcludedFileFolder)"
                                                }
                                            WriteWordLine 0 3 "Excluded file types: "
                                            foreach ($ExcludedFileType in $AgentConfig.ExcludedFileTypes)
                                                {
                                                    WriteWordLine 0 4 "$($ExcludedFileType)"
                                                }
                                            WriteWordLine 0 3 "Excluded processes: "
                                            foreach ($ExcludedProcess in $AgentConfig.ExcludedProcesses)
                                                {
                                                    WriteWordLine 0 4 "$($ExcludedProcess)"
                                                }                                            
                                        }
                                    204
                                        {
                                            WriteWordLine 0 2 "Real-time protection" -bold
                                            WriteWordLine 0 3 "Enable real-time protection: $($AgentConfig.RealtimeProtectionOn)"
                                            WriteWordLine 0 3 "Monitor file and program activity on your computer: $($AgentConfig.MonitorFileProgramActivity)"
                                            WriteWordLine 0 3 "Scan system files: " -nonewline
                                            switch ($AgentConfig.RealtimeScanOption)
                                                {
                                                    0 { WriteWordLine 0 0 "Scan incoming and outgoing files" }
                                                    1 { WriteWordLine 0 0 "Scan incoming files only" }
                                                    2 { WriteWordLine 0 0 "Scan outgoing files only" }
                                                }                                            
                                        }
                                    205
                                        {
                                            WriteWordLine 0 2 "Advanced" -bold
                                            WriteWordLine 0 3 "Create a system restore point before computers are cleaned: $($AgentConfig.CreateSystemRestorePointBeforeClean)"
                                            WriteWordLine 0 3 "Disable the client user interface: $($AgentConfig.DisableClientUI)"
                                            WriteWordLine 0 3 "Show notifications messages on the client computer when the user needs to run a full scan, update definitions, or run Windows Defender Offline: $($AgentConfig.ShowNotificationMessages)"
                                            WriteWordLine 0 3 "Delete quarantined files after (days): $($AgentConfig.DeleteQuarantinedFilesPeriod)"
                                            WriteWordLine 0 3 "Allow users to configure the setting for quarantined file deletion: $($AgentConfig.AllowUserConfigQuarantinedFileDeletionPeriod)"
                                            WriteWordLine 0 3 "Allow users to exclude file and folders, file types and processes: $($AgentConfig.AllowUserAddExcludes)"
                                            WriteWordLine 0 3 "Allow all users to view the full History results: $($AgentConfig.AllowUserViewHistory)"
                                            WriteWordLine 0 3 "Enable reparse point scanning: $($AgentConfig.EnableReparsePointScanning)"
                                            WriteWordLine 0 3 "Randomize scheduled scan and definition update start time (within 30 minutes): $($AgentConfig.RandomizeScheduledScanStartTime)"                                            
                                        }
                                    206
                                        {
                                            
                                        }
                                    207
                                        {
                                            WriteWordLine 0 2 "Microsoft Active Protection Service" -bold
                                            WriteWordLine 0 3 "Microsoft Active Protection Service membership type: " -nonewline
                                            switch ($AgentConfig.JoinSpyNet)
                                                {
                                                    0 { WriteWordLine 0 0 "Do not join MAPS" }
                                                    1 { WriteWordLine 0 0 "Basic membership" }
                                                    2 { WriteWordLine 0 0 "Advanced membership" }
                                                }
                                            WriteWordLine 0 3 "Allow users to modify Microsoft Active Protection Service settings: $($AgentConfig.AllowUserChangeSpyNetSettings)"                                            
                                        }
                                    208
                                        {
                                            WriteWordLine 0 2 "Definition Updates" -bold
                                            WriteWordLine 0 3 "Check for Endpoint Protection definitions at a specific interval (hours): (0 disable check on interval) $($AgentConfig.SignatureUpdateInterval)"
                                            WriteWordLine 0 3 "Check for Endpoint Protection definitions daily at: (Only configurable if interval-based check is disabled) $(Convert-Time -time $AgentConfig.SignatureUpdateTime)"
                                            WriteWordLine 0 3 "Force a definition update if the client computer is offline for more than two consecutive scheduled updates: $($AgentConfig.EnableSignatureUpdateCatchupInterval)"
                                            WriteWordLine 0 3 "Set sources and order for Endpoint Protection definition updates: "
                                            foreach ($Fallback in $AgentConfig.FallbackOrder)
                                                {
                                                    WriteWordLine 0 4 "$($Fallback)"
                                                }
                                            WriteWordLine 0 3 "If Configuration Manager is used as a source for definition updates, clients will only update from alternative sources if definition is older than (hours): $($AgentConfig.AuGracePeriod / 60)"
                                            WriteWordLine 0 3 "If UNC file shares are selected as a definition update source, specify the UNC paths:" 
                                            foreach ($UNCShare in $AgentConfig.DefinitionUpdateFileSharesSources)
                                                {
                                                    WriteWordLine 0 4 "$($UNCShare)"
                                                }
                                        }
                                    209
                                        {
                                            WriteWordLine 0 2 "Scan settings" -bold
                                            WriteWordLine 0 3 "Scan email and email attachments: $($AgentConfig.ScanEmail)"
                                            WriteWordLine 0 3 "Scan removable storage devices such as USB drives: $($AgentConfig.ScanRemovableStorage)"
                                            WriteWordLine 0 3 "Scan network drives when running a full scan: $($AgentConfig.ScanNetworkDrives)"
                                            WriteWordLine 0 3 "Scan archived files: $($AgentConfig.ScanArchivedFiles)"
                                            WriteWordLine 0 3 "Allow users to configure CPU usage during scans: $($AgentConfig.AllowClientUserConfigLimitCPUUsage)"
                                            WriteWordLine 0 3 "User control of scheduled scans: " -nonewline
                                            switch ($AgentConfig.ScheduledScanUserControl)
                                                {
                                                    0 { WriteWordLine 0 0 "No control" }
                                                    1 { WriteWordLine 0 0 "Scan time only" }
                                                    2 { WriteWordLine 0 0 "Full control" }
                                                }
                                        }
                                }
                        }
                }
        }
    }
else
    {
        WriteWordLine 0 1 "There are no Anti Malware Policies configured."
    }

WriteWordLine 0 0 ""

Write-Verbose "Working on Windows Firewall Policies"
WriteWordLine 3 0 "Windows Firewall Policies"

$FirewallPolicies = Get-CMWindowsFirewallPolicy
if (-not [string]::IsNullOrEmpty($FirewallPolicies))
    {
        WriteWordLine 0 1 "Enumerating Windows Firewall Policies:"
        $Table = $Null
        $TableRange = $Null
        $TableRange = $doc.Application.Selection.Range
        $Columns = 4
        [int]$Rows = $FirewallPolicies.count + 1
        write-verbose "add configuration items to table"
        $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
        $table.Style = "Table Grid"
        $table.Borders.InsideLineStyle = 1
        $table.Borders.OutsideLineStyle = 1
        [int]$xRow = 1
        write-verbose "format first row with column headings"
        $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,1).Range.Font.Bold = $True
        $Table.Cell($xRow,1).Range.Font.Size = "10"
        $Table.Cell($xRow,1).Range.Text = "Name"
        $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,2).Range.Font.Bold = $True
        $Table.Cell($xRow,2).Range.Font.Size = "10"
        $Table.Cell($xRow,2).Range.Text = "Last modified"
        $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,3).Range.Font.Bold = $True
        $Table.Cell($xRow,3).Range.Font.Size = "10"
        $Table.Cell($xRow,3).Range.Text = "Last modified by"
        $Table.Cell($xRow,4).Shading.BackgroundPatternColor = $wdColorGray15
        $Table.Cell($xRow,4).Range.Font.Bold = $True
        $Table.Cell($xRow,4).Range.Font.Size = "10"
        $Table.Cell($xRow,4).Range.Text = "CI ID"
        foreach ($FirewallPolicy in $FirewallPolicies)
            {
                $xRow++							
		        $Table.Cell($xRow,1).Range.Font.Size = "10"
		        $Table.Cell($xRow,1).Range.Text = $FirewallPolicy.LocalizedDisplayName
		        $Table.Cell($xRow,2).Range.Font.Size = "10"
		        $Table.Cell($xRow,2).Range.Text = $FirewallPolicy.DateLastModified
                $Table.Cell($xRow,3).Range.Font.Size = "10"
		        $Table.Cell($xRow,3).Range.Text = $FirewallPolicy.LastModifiedBy
                $Table.Cell($xRow,4).Range.Font.Size = "10"
		        $Table.Cell($xRow,4).Range.Text = $FirewallPolicy.CI_ID   
            }				
        $Table.Rows.SetLeftIndent(50,1) | Out-Null
        $table.AutoFitBehavior(1) | Out-Null
        #return focus back to document
        write-verbose "return focus back to document"
        $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
        #move to the end of the current document
        write-verbose "move to the end of the current document"
        $selection.EndKey($wdStory,$wdMove) | Out-Null
        WriteWordLine 0 0 ""
    
        #move to the end of the current document
        write-verbose "move to the end of the current document"
        $selection.EndKey($wdStory,$wdMove) | Out-Null
        WriteWordLine 0 0 ""
    }
else
    {
        WriteWordLine 0 1 "There are no Windows Firewall policies configured."
    }
    

#####
##### finished with Assets and Compliance, moving on to Software Library
#####
        Write-Verbose "Finished with Assets and Compliance, moving on to Software Library"
        WriteWordLine 1 0 "Software Library"

##### Applications
        
        WriteWordLine 2 0 "Applications"
        WriteWordLine 0 0 ""
        $Applications = Get-CMApplication
        if ($ListAllInformation)
            {
                if (-not [string]::IsNullOrEmpty($Applications))
                    {
                        WriteWordLine 0 1 "The following Applications are configured in this site:"
                        foreach ($Application in $Applications)
                            {
                        Write-Verbose "Found App: $($Application.LocalizedDisplayName)"
                        WriteWordLine 0 2 "$($Application.LocalizedDisplayName)" -bold
                        WriteWordLine 0 3 "Created by: $($Application.CreatedBy)"
                        WriteWordLine 0 3 "Date created: $($Application.DateCreated)"
                        WriteWordLine 0 3 "PackageID: $($Application.PackageID)"
                        $DTs = Get-CMDeploymentType -ApplicationName "$($Application.LocalizedDisplayName)"
                        if (-not [string]::IsNullOrEmpty($DTs))
                            {
                                $Table = $Null
                                $TableRange = $Null
                                $TableRange = $doc.Application.Selection.Range
				                $Columns = 2
                                [int]$Rows = $DTs.count + 1
				                write-verbose "add Deployment Types to table"
				                $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
				                $table.Style = "Table Grid"
				                $table.Borders.InsideLineStyle = 1
				                $table.Borders.OutsideLineStyle = 1
				                [int]$xRow = 1
				                write-verbose "format first row with column headings"
				                $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
				                $Table.Cell($xRow,1).Range.Font.Bold = $True
				                $Table.Cell($xRow,1).Range.Font.Size = "10"
				                $Table.Cell($xRow,1).Range.Text = "Deployment Type name"
				                $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
				                $Table.Cell($xRow,2).Range.Font.Bold = $True
				                $Table.Cell($xRow,2).Range.Font.Size = "10"
				                $Table.Cell($xRow,2).Range.Text = "Technology"
                                foreach ($DT in $DTs)
                                    {
                                        $xRow++							
					                    $Table.Cell($xRow,1).Range.Font.Size = "10"
					                    $Table.Cell($xRow,1).Range.Text = $DT.LocalizedDisplayName
					                    $Table.Cell($xRow,2).Range.Font.Size = "10"
					                    $Table.Cell($xRow,2).Range.Text = $DT.Technology   
                                    }				
				                $Table.Rows.SetLeftIndent(50,1) | Out-Null
				                $table.AutoFitBehavior(1) | Out-Null
				                #return focus back to document
				                write-verbose "return focus back to document"
				                $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
                                #move to the end of the current document
			                    write-verbose "move to the end of the current document"
			                    $selection.EndKey($wdStory,$wdMove) | Out-Null
			                    WriteWordLine 0 0 ""
                           
                         }
                        else
                            {
                                WriteWordLine 0 3 "There are no Deployment Types configured for this Application."
                            }
                    }
                    }
                else
                    {
                        WriteWordLine 0 1 "There are no Applications configured in this site."
                    }
            }
        elseif ($Applications)
            {
                WriteWordLine 0 1 "There are $($Applications.count) applications configured."
            }
            else
                {
                    WriteWordLine 0 1 "There are no applications configured."
                }

##### Packages
        
        WriteWordLine 2 0 "Packages"
        WriteWordLine 0 0 ""
        $Packages = Get-CMPackage
        if ($ListAllInformation)
            {
                if (-not [string]::IsNullOrEmpty($Packages))
                    {
                        WriteWordLine 0 1 "The following Packages are configured in this site:"
                        foreach ($Package in $Packages)
                        {
                        WriteWordLine 0 0 ""
                        WriteWordLine 0 2 "$($Package.Name)" -bold
                        WriteWordLine 0 3 "Description: $($Package.Description)"
                        WriteWordLine 0 3 "PackageID: $($Package.PackageID)"
                        $Programs = Get-CMProgram -PackageId $($Package.PackageID)
                        if (-not [string]::IsNullOrEmpty($Programs))
                            {
                                WriteWordLine 0 3 "The Package has the following Programs configured:"
                                $Table = $Null
                                $TableRange = $Null
                                $TableRange = $doc.Application.Selection.Range
				                $Columns = 3
                                [int]$Rows = $Programs.count + 1
				                write-verbose "add Collection variables to table"
				                $Table = $doc.Tables.Add($TableRange, $Rows, $Columns)
				                $table.Style = "Table Grid"
				                $table.Borders.InsideLineStyle = 1
				                $table.Borders.OutsideLineStyle = 1
				                [int]$xRow = 1
				                write-verbose "format first row with column headings"
				                $Table.Cell($xRow,1).Shading.BackgroundPatternColor = $wdColorGray15
				                $Table.Cell($xRow,1).Range.Font.Bold = $True
				                $Table.Cell($xRow,1).Range.Font.Size = "10"
				                $Table.Cell($xRow,1).Range.Text = "Package Name"
				                $Table.Cell($xRow,2).Shading.BackgroundPatternColor = $wdColorGray15
				                $Table.Cell($xRow,2).Range.Font.Bold = $True
				                $Table.Cell($xRow,2).Range.Font.Size = "10"
				                $Table.Cell($xRow,2).Range.Text = "Program Name"
                                $Table.Cell($xRow,3).Shading.BackgroundPatternColor = $wdColorGray15
				                $Table.Cell($xRow,3).Range.Font.Bold = $True
				                $Table.Cell($xRow,3).Range.Font.Size = "10"
				                $Table.Cell($xRow,3).Range.Text = "Command Line"
                                foreach ($Program in $Programs)
                                    {
                                        $xRow++							
					                    $Table.Cell($xRow,1).Range.Font.Size = "10"
					                    $Table.Cell($xRow,1).Range.Text = $Program.PackageName
					                    $Table.Cell($xRow,2).Range.Font.Size = "10"
					                    $Table.Cell($xRow,2).Range.Text = $Program.ProgramName
                                        $Table.Cell($xRow,3).Range.Font.Size = "10"
					                    $Table.Cell($xRow,3).Range.Text = $Program.CommandLine   
                                    }				
				                $Table.Rows.SetLeftIndent(50,1) | Out-Null
				                $table.AutoFitBehavior(1) | Out-Null
				                #return focus back to document
				                write-verbose "return focus back to document"
				                $doc.ActiveWindow.ActivePane.view.SeekView=$wdSeekMainDocument
                                #move to the end of the current document
			                    write-verbose "move to the end of the current document"
			                    $selection.EndKey($wdStory,$wdMove) | Out-Null
			                    WriteWordLine 0 0 ""
                                
                            }
                        else
                            {
                                WriteWordLine 0 4 "The Package has no Programs configured."
                            }                       
                    }
                    }
                else
                    {
                        WriteWordLine 0 1 "There are no Packages configured in this site."
                    }
            }
        elseif ($Packages)
            {
                WriteWordLine 0 1 "There are $($Packages.count) packages configured."
            }
            else
                {
                    WriteWordLine 0 1 "There are no packages configured."
                }

##### Driver Packages

    WriteWordLine 2 0 "Driver Packages"
    WriteWordLine 0 0 ""
    $DriverPackages = Get-CMDriverPackage
    if ($ListAllInformation)
        {
            if (-not [string]::IsNullOrEmpty($DriverPackages))
                    {
                        WriteWordLine 0 1 "The following Driver Packages are configured in your site:"
                        foreach ($DriverPackage in $DriverPackages)
                            {
                                WriteWordLine 0 0 ""
                                WriteWordLine 0 2 "Name: $($DriverPackage.Name)" -bold
                                if ($DriverPackage.Description)
                                    {
                                        WriteWordLine 0 2 "Description: $($DriverPackage.Description)"
                                    }
                                WriteWordLine 0 2 "PackageID: $($DriverPackage.PackageID)"
                                WriteWordLine 0 2 "Source path: $($DriverPackage.PkgSourcePath)"
                                WriteWordLine 0 2 "This package consists of the following Drivers:"
                                $Drivers = Get-CMDriver -DriverPackageId "$($DriverPackage.PackageID)"
                                foreach ($Driver in $Drivers)
                                    {
                                        WriteWordLine 0 0 ""
                                        WriteWordLine 0 3 "Driver Name: $($Driver.LocalizedDisplayName)" -bold
                                        WriteWordLine 0 3 "Manufacturer: $($Driver.DriverProvider)"
                                        WriteWordLine 0 3 "Source path: $($Driver.ContentSourcePath)"
                                        WriteWordLine 0 3 "INF File: $($Driver.DriverINFFile)"
                                    }
                                WriteWordLine 0 3 ""
                            }
                    }
                else
                    {
                        WriteWordLine 0 1 "There are no Driver Packages configured in this site."
                    }
        }
    else
        {
            if (-not [string]::IsNullOrEmpty($DriverPackages))
                {
                    WriteWordLine 0 1 "There are $($DriverPackages.count) Driver Packages configured."                    
                }
            else
                {
                    WriteWordLine 0 1 "There are no Driver Packages configured in this site."
                }
        }
 
 ##### Operating System Images

    WriteWordLine 2 0 "Operating System Images"
    WriteWordLine 0 0 ""
    $OSImages = Get-CMOperatingSystemImage
    if (-not [string]::IsNullOrEmpty($OSImages))
        {
            WriteWordLine 0 1 "The following OS Images are imported into your site:"
            foreach ($OSImage in $OSImages)
                {
                    WriteWordLine 0 0 ""
                    WriteWordLine 0 2 "Name: $($OSImage.Name)" -bold
                    if ($OSImage.Description)
                            {
                                WriteWordLine 0 2 "Description: $($OSImage.Description)"
                            }
                    WriteWordLine 0 2 "Package ID: $($OSImage.PackageID)"
                    WriteWordLine 0 2 "Source Path: $($OSImage.PkgSourcePath)"
                }
        }
    else
        {
            WriteWordLine 0 1 "There are no OS Images imported into this environment."
        }


##### Operating System Installers

    WriteWordLine 2 0 "Operating System Installers"
    WriteWordLine 0 0 ""
    $OSInstallers = Get-CMOperatingSystemInstaller
    if (-not [string]::IsNullOrEmpty($OSImages))
        {
            WriteWordLine 0 1 "The following OS Installers are imported into this environment:"
            foreach ($OSInstaller in $OSInstallers)
                {
                    WriteWordLine 0 2 "Name: $($OSInstaller.Name)" -bold
                    if ($OSInstaller.Description)
                            {
                                WriteWordLine 0 2 "Description: $($OSInstaller.Description)"
                            }
                    WriteWordLine 0 2 "Package ID: $($OSInstaller.PackageID)"
                    WriteWordLine 0 2 "Source Path: $($OSInstaller.PkgSourcePath)"
                }
        }
    else
        {
            WriteWordLine 0 1 "There are no OS Installers imported into this environment."
        }
        
####
####
#### Boot Images
    
WriteWordLine 2 0 "Boot Images"
WriteWordLine 0 0 ""
$BootImages = Get-CMBootImage
if (-not [string]::IsNullOrEmpty($BootImages))
    {
        WriteWordLine 0 1 "The following Boot Images are imported into this environment:"
        WriteWordLine 0 0 ""
        foreach ($BootImage in $BootImages)
            {
                WriteWordLine 0 2 "$($BootImage.Name)" -bold
                if ($BootImage.Description)
                    {
                        WriteWordLine 0 2 "Description: $($BootImage.Description)"
                    }
                WriteWordLine 0 2 "Source Path: $($BootImage.PkgSourcePath)"
                WriteWordLine 0 2 "Package ID: $($BootImage.PackageID)"
                WriteWordLine 0 2 "Architecture: " -nonewline
                switch ($BootImage.Architecture)
                    {
                        0 { WriteWordLine 0 0 "x86" }
                        9 { WriteWordLine 0 0 "x64" }
                    }
                if ($BootImage.BackgroundBitmapPath)
                    {
                        WriteWordLine 0 2 "Custom Background: $($BootImage.BackgroundBitmapPath)"
                    }
                Switch ($BootImage.EnableLabShell)
                    {
                        True { WriteWordLine 0 2 "Command line support is enabled" }
                        False { WriteWordLine 0 2 "Command line support is not enabled" }
                    }
                WriteWordLine 0 2 "The following drivers are imported into this WinPE"
                if (-not [string]::IsNullOrEmpty($BootImage.ReferencedDrivers))
                    {
                        $ImportedDriverIDs = ($BootImage.ReferencedDrivers).ID | Out-Null
                        foreach ($ImportedDriverID in $ImportedDriverIDs)
                            {
                                $ImportedDriver = Get-CMDriver -ID $ImportedDriverID
                                WriteWordLine 0 3 "Name: $($ImportedDriver.LocalizedDisplayName)" -bold
                                WriteWordLine 0 3 "Inf File: $($ImportedDriver.DriverINFFile)"
                                WriteWordLine 0 3 "Driver Class: $($ImportedDriver.DriverClass)"
                                WriteWordLine 0 0 ""
                            }
                    }
                else
                    {
                        WriteWordLine 0 3 "There are no drivers imported into the Boot Image."
                    }
            if (-not [string]::IsNullOrEmpty($BootImage.OptionalComponents))
                {
                    $Component = $Null
                    WriteWordLine 0 3 "The following Optional Components are added to this Boot Image:"
                    foreach ($Component in $BootImage.OptionalComponents)
                        {
                            switch ($Component)
                                {
                                    {($_ -eq "1") -or ($_ -eq "27")} { WriteWordLine 0 4 "WinPE-DismCmdlets" }                                    {($_ -eq "2") -or ($_ -eq "28")} { WriteWordLine 0 4 "WinPE-Dot3Svc" }                                    {($_ -eq "3") -or ($_ -eq "29")} { WriteWordLine 0 4 "WinPE-EnhancedStorage" }                                    {($_ -eq "4") -or ($_ -eq "30")} { WriteWordLine 0 4 "WinPE-FMAPI" }                                    {($_ -eq "5") -or ($_ -eq "31")} { WriteWordLine 0 4 "WinPE-FontSupport-JA-JP" }                                    {($_ -eq "6") -or ($_ -eq "32")} { WriteWordLine 0 4 "WinPE-FontSupport-KO-KR" }                                    {($_ -eq "7") -or ($_ -eq "33")} { WriteWordLine 0 4 "WinPE-FontSupport-ZH-CN" }                                    {($_ -eq "8") -or ($_ -eq "34")} { WriteWordLine 0 4 "WinPE-FontSupport-ZH-HK" }                                    {($_ -eq "9") -or ($_ -eq "35")} { WriteWordLine 0 4 "WinPE-FontSupport-ZH-TW" }                                    {($_ -eq "10") -or ($_ -eq "36")} { WriteWordLine 0 4 "WinPE-HTA" }                                    {($_ -eq "11") -or ($_ -eq "37")} { WriteWordLine 0 4 "WinPE-StorageWMI" }                                    {($_ -eq "12") -or ($_ -eq "38")} { WriteWordLine 0 4 "WinPE-LegacySetup" }                                    {($_ -eq "13") -or ($_ -eq "39")} { WriteWordLine 0 4 "WinPE-MDAC" }                                    {($_ -eq "14") -or ($_ -eq "40")} { WriteWordLine 0 4 "WinPE-NetFx4" }                                    {($_ -eq "15") -or ($_ -eq "41")} { WriteWordLine 0 4 "WinPE-PowerShell3" }                                    {($_ -eq "16") -or ($_ -eq "42")} { WriteWordLine 0 4 "WinPE-PPPoE" }                                    {($_ -eq "17") -or ($_ -eq "43")} { WriteWordLine 0 4 "WinPE-RNDIS" }                                    {($_ -eq "18") -or ($_ -eq "44")} { WriteWordLine 0 4 "WinPE-Scripting" }                                    {($_ -eq "19") -or ($_ -eq "45")} { WriteWordLine 0 4 "WinPE-SecureStartup" }                                    {($_ -eq "20") -or ($_ -eq "46")} { WriteWordLine 0 4 "WinPE-Setup" }                                    {($_ -eq "21") -or ($_ -eq "47")} { WriteWordLine 0 4 "WinPE-Setup-Client" }                                    {($_ -eq "22") -or ($_ -eq "48")} { WriteWordLine 0 4 "WinPE-Setup-Server" }                                    #{($_ -eq "23") -or ($_ -eq "49")} { WriteWordLine 0 4 "Not applicable" }                                    {($_ -eq "24") -or ($_ -eq "50")} { WriteWordLine 0 4 "WinPE-WDS-Tools" }                                    {($_ -eq "25") -or ($_ -eq "51")} { WriteWordLine 0 4 "WinPE-WinReCfg" }                                    {($_ -eq "26") -or ($_ -eq "52")} { WriteWordLine 0 4 "WinPE-WMI" }
                                } 
                            $Component = $Null    
                        }
                    }
                WriteWordLine 0 0 ""

            }
    }
else
    {
        WriteWordLine 0 1 "There are no Boot Images present in this environment."
    }

####
####
#### Task Sequences
Write-Verbose "Enumerating Task Sequences"
WriteWordLine 2 0 "Task Sequences"
WriteWordLine 0 0 ""

$TaskSequences = Get-CMTaskSequence
Write-Verbose "working on $($TaskSequences.count) Task Sequences"
if ($ListAllInformation)
    {
        if (-not [string]::IsNullOrEmpty($TaskSequences))
            {
                foreach ($TaskSequence in $TaskSequences)
                    {
                        WriteWordLine 0 1 "Task Sequence name: $($TaskSequence.Name)" -bold
                        WriteWordLine 0 1 "Package ID: $($TaskSequence.PackageID)"
                        if ($TaskSequence.BootImageID)
                            {
                                WriteWordLine 0 2 "Boot Image referenced in this Task Sequence: $((Get-CMBootImage -Id $TaskSequence.BootImageID -ErrorAction SilentlyContinue ).Name)"
                            }
        
                        $Sequence = $Null
                        [xml]$Sequence = $TaskSequence.Sequence
                        try
                            {
                                foreach ($Group in $Sequence.sequence.group)
                                    {
                                        WriteWordLine 0 1 "Group name: $($Group.Name)" -bold
                                        if (-not [string]::IsNullOrEmpty($Group.Description))
                                            {
                                                WriteWordLine 0 1 "Description: $($Group.Description)"
                                            }
                                        WriteWordLine 0 1 "This Group has the following steps configured."
                                        foreach ($Step in $Group.Step)
                                            {
                                                WriteWordLine 0 3 "$($Step.Name)" -bold
                                                if (-not [string]::IsNullOrEmpty($Step.Description))
                                                    {
                                                        WriteWordLine 0 4 "$($Step.Description)"
                                                    }
                                                WriteWordLine 0 4 "$($Step.Action)"
                                                try 
                                                    {
                                                        if (-not [string]::IsNullOrEmpty($Step.disable))
                                                                {
                                                                    WriteWordLine 0 4 "This step is disabled."
                                                                }
                                                    }   
                                                catch [System.Management.Automation.PropertyNotFoundException] 
                                                    {
                                                        WriteWordLine 0 4 "This step is enabled"
                                                    }
                                                WriteWordLine 0 0 ""
                                            }

                                    }
                            }
                        catch [System.Management.Automation.PropertyNotFoundException]
                            {
                                WriteWordLine 0 0 ""
                            }
                        try 
                            {
                                foreach ($Step in $Sequence.sequence.step)
                                    {
                                        WriteWordLine 0 3 "$($Step.Name)" -bold
                                        if (-not [string]::IsNullOrEmpty($Step.Description))
                                            {
                                                WriteWordLine 0 4 "$($Step.Description)"
                                            }
                                        WriteWordLine 0 4 "$($Step.Action)"
                                        try 
                                            {
                                                if (-not [string]::IsNullOrEmpty($Step.disable))
                                                        {
                                                            WriteWordLine 0 4 "This step is disabled."
                                                        }
                                            }   
                                        catch [System.Management.Automation.PropertyNotFoundException] 
                                            {
                                                WriteWordLine 0 4 "This step is enabled"
                                            }
                                        WriteWordLine 0 0 ""
                                    }
                            }
                        catch [System.Management.Automation.PropertyNotFoundException]
                            {
                                WriteWordLine 0 0 ""
                            }
                        #>
                        WriteWordLine 0 0 ""
                        WriteWordLine 0 0 "----------------------------------------------"
                    }
            }
        else
            {
                WriteWordLine 0 1 "There are no Task Sequences present in this environment."
            }
    }
else
    {
        if (-not [string]::IsNullOrEmpty($TaskSequences))
            {
                WriteWordLine 0 1 "The following Task Sequences are configured:"
                foreach ($TaskSequence in $TaskSequences)
                    {
                        WriteWordLine 0 2 "$($TaskSequence.Name)"
                    }
            }
        else
            {
                WriteWordLine 0 1 "There are no Task Sequences present in this environment."
            }
    }

######################## END OF MAIN SCRIPT ######################
Set-Location $LocationBeforeExecution
write-verbose "Finishing up Word document"
#end of document processing
#Update document properties

If($CoverPagesExist)
{
	write-verbose "Set Cover Page Properties"
	_SetDocumentProperty $doc.BuiltInDocumentProperties "Company" $CompanyName
	_SetDocumentProperty $doc.BuiltInDocumentProperties "Title" $title
	_SetDocumentProperty $doc.BuiltInDocumentProperties "Subject" "Microsoft System Center 2012 Configuration Manager Site Inventory"
	_SetDocumentProperty $doc.BuiltInDocumentProperties "Author" $username

	#Get the Coverpage XML part
	$cp=$doc.CustomXMLParts | where {$_.NamespaceURI -match "coverPageProps$"}

	#get the abstract XML part
	$ab=$cp.documentelement.ChildNodes | Where {$_.basename -eq "Abstract"}
	#set the text
	[string]$abstract="Microsoft System Center 2012 Configuration Manager Site Inventory for $CompanyName"
	$ab.Text=$abstract

	$ab=$cp.documentelement.ChildNodes | Where {$_.basename -eq "PublishDate"}
	#set the text
	[string]$abstract=( Get-Date -Format d ).ToString()
	$ab.Text=$abstract

	write-verbose "Update the Table of Contents"
	#update the Table of Contents
	$doc.TablesOfContents.item(1).Update()
}

write-verbose "Save and Close document and Shutdown Word"
If ($WordVersion -eq 12)
{
	#Word 2007
	$SaveFormat = "microsoft.office.interop.word.WdSaveFormat" -as [type] 
	$doc.SaveAs($filename, $SaveFormat)
}
Else
{
	#the $saveFormat below passes StrictMode 2
	#I found this at the following two links
	#http://blogs.technet.com/b/bshukla/archive/2011/09/27/3347395.aspx
	#http://msdn.microsoft.com/en-us/library/microsoft.office.interop.word.wdsaveformat(v=office.14).aspx
	$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatDocumentDefault")
	$doc.SaveAs([REF]$filename, [ref]$SaveFormat)
}

$doc.Close()
$Word.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Word) | out-null
Remove-Variable -Name word
[gc]::collect() 
[gc]::WaitForPendingFinalizers()
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUR11d2d/r7a/CPk4fXaSItLGi
# UrSgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFaWTYLqTtY5nPv4
# DJk7icuyg/r8MA0GCSqGSIb3DQEBAQUABIIBAKUckPuOvGBXr9pRp19MhwOU/3XZ
# wSudhIPBLmvaUMx3RuGrrvji7j68I46jIa5HXacjE7DtT1IEh07A1FsgvyC+2ljW
# 5yXmG6ACpo+FO6A9uKZ05SRYazKv75P7Um9UEz6/hHf7kB6zZYKzJLhkfgWssjpI
# 4gnoepEUFVysIrc5k14Xf1Z9YEnZW3I6PRdDY8s+cbZwbjjsqAiDV+7ndYsovCvv
# So72WX/U2ZF/jWcnIaRloJgDxhta8jt7FyuYAZA7lvmLD9xUC9awZcH674HGrB+w
# rl/T1SU+/Rh8ba+cWicMmyzVMqZLFvIvRSkLaMSQPlhyU+85vWAwO79W0/M=
# SIG # End signature block
