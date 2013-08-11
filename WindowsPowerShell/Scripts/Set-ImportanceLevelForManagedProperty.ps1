<#
.SYNOPSIS
       The purpose of this script is to set the importance level for a FAST Managed Property
.DESCRIPTION
       The purpose of this script is to set the importance level for a FAST Managed Property. 
	   You must specify a managed property name and the importance level. The importance level
	   needs to be a number between 1 and 7. The full text index name is optional and will default
	   to content if you do not specify one. This script can be used in conjunction with Get-ImportanceLevelForManagedProperty.
	   
.EXAMPLE
.\Set-ImportanceLevelForManagedProperty.ps1 -DebugMode -fullTextIndexName content -managedPropertyName Keywords -importanceLevel 7

Output:
Importance level correctly set for Managed Property:Keywords in Full Text Index:content to:7

.EXAMPLE
.\Set-ImportanceLevelForManagedProperty.ps1 -managedPropertyName Keywords -importanceLevel 7

Output:
Using default full text index name:content
Importance level for Managed Property:Keywords in Full Text Index:content is set to:4 Expected:7
Updated Importance level for Managed Property:Keywords in Full Text Index:content to:7

.LINK
This Script - http://gallery.technet.microsoft.com/scriptcenter/6c246f1e-75e7-478c-a514-a33a37f353c6
.NOTES
  File Name : Set-ImportanceLevelForManagedProperty.ps1
  Author    : Ben Lin, Brent Groom 
#>

# TODO - implement uninstall, drive from config file, use return codes

param
  (
	
 	[switch]
    # Signifies that the script should output debug statements
    $DebugMode, 
   
 	[string]
    # Allows you to specify the name of the rank profile
	$fullTextIndexName = "",
    
	[string]
    # name of the managed property
	$managedPropertyName = "",
    
	[int]
    # Allows you to specify the expected weight 
	$importanceLevel = 100
    
    )

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

function setImportanceLevelForMP ( )
{
	if($managedPropertyName.Length -eq 0)
	{
		write-host ("You must specify a valid managed property name") -Foregroundcolor Red 		
		return
	}
	
	# Check the importance level
	$mp = Get-FASTSearchMetadataManagedProperty -Name $managedPropertyName
	if($mp -eq $null)
	{
		write-host ("You must specify a valid managed property name") -Foregroundcolor Red 		
		return
	}
	
	$fullTextIndexesEnum  = $mp.GetFullTextIndexMappings()
	
	if($fullTextIndexName.Length -eq 0)
	{
	    $fullTextIndexName = "content"
		write-host ("Using default full text index name:$fullTextIndexName") -Foregroundcolor Red 
	}
	if($importanceLevel -lt 1 -or $importanceLevel -gt 7)
	{
		write-host ("You must specify a valid importance level. Please choose a number between 1 and 7.") -Foregroundcolor Red 
		return
	}
    
	
	$hasmappings = $false
	foreach($index in $fullTextIndexesEnum)
	{
		
		if($index.FullTextIndex.Name -ne $fullTextIndexName)
		{
			continue
		}
		$hasmappings = $true
		
		if($index.ImportanceLevel -ne $importanceLevel)
		{
			write-host ("Importance level for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName is set to:"+$index.ImportanceLevel+" Expected:$importanceLevel") -Foregroundcolor Red 
			$fuu = Get-FASTSearchMetadataFullTextIndexMapping|Where-Object {$_.ManagedProperty.Name -eq $managedPropertyName}
			Remove-FASTSearchMetadataFullTextIndexMapping -Mapping $fuu
			$newMapping = New-FASTSearchMetadataFullTextIndexMapping –ManagedProperty (Get-FASTSearchMetadataManagedProperty $managedPropertyName) –FullTextIndex (Get-FASTSearchMetadataFullTextIndex $fullTextIndexName) –Level $importanceLevel
			write-host ("Updated Importance level for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName to:$importanceLevel") -Foregroundcolor Yellow 				
			
		}
		elseif($index.ImportanceLevel -eq $importanceLevel)
		{
			write-host ("Importance level correctly set for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName to:$importanceLevel") -Foregroundcolor Green 				
		
		}
	}
	if($hasmappings -eq $false)
	{
		write-host ("Could not find Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName") -Foregroundcolor Yellow 				
		$newMapping = New-FASTSearchMetadataFullTextIndexMapping –ManagedProperty (Get-FASTSearchMetadataManagedProperty $managedPropertyName) –FullTextIndex (Get-FASTSearchMetadataFullTextIndex $fullTextIndexName) –Level $importanceLevel
		write-host ("Updated Importance level for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName to:$importanceLevel") -Foregroundcolor Yellow 				
	
	}

}

if($DebugMode)
{
	"Using following values:"
	"  DebugMode:$DebugMode"
	"  fullTextIndexName:$fullTextIndexName"
	"  ManagedPropertyName:$ManagedPropertyName"
	"  importanceLevel:$importanceLevel"

}

setImportanceLevelForMP 



