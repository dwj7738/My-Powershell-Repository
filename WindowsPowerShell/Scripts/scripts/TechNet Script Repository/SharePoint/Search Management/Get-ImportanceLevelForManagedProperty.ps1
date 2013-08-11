<#
.SYNOPSIS
       The purpose of this script is to check the importance level for a FAST Managed Property
.DESCRIPTION
       The purpose of this script is to check the importance level for a FAST Managed Property. 
	   You may specify a managed property name and the importance level. The importance level
	   needs to be a number between 1 and 7. The full text index name is optional and will default
	   to content if you do not specify one. This script can be used in conjunction with 
	   Set-ImportanceLevelForManagedProperty.
	   
.EXAMPLE
.\Get-ImportanceLevelForManagedProperty.ps1 -DebugMode -fullTextIndexName content -managedPropertyName Keywords -importanceLevel 7

Output:
Importance level for Managed Property:Keywords in Full Text Index:content to:7

.LINK
This Script - http://gallery.technet.microsoft.com/scriptcenter/7661f21b-d9cb-4fab-963a-8d49acbc5e95
.NOTES
  File Name : Get-ImportanceLevelForManagedProperty.ps1
  Author    : Ben Lin, Brent Groom 
#>

# TODO - implement uninstall, drive from config file 

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
    # Allows you to specify the importance level
	$importanceLevel = -1
    
    )

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

function getImportanceLevelForMP ( )
{
	$global:importanceLevelSet = $true
	if($importanceLevel -eq -1)
	{
		$global:importanceLevelSet = $false
	}
	if($managedPropertyName.Length -eq 0)
	{
		write-host ("You must specify a managed property valid name") -Foregroundcolor Red 
		write-host ("Exiting script") -Foregroundcolor Red 
		return		
	}
	if($fullTextIndexName.Length -eq 0)
	{
	    $fullTextIndexName = "content"
		write-host ("Using default full text index name:$fullTextIndexName") -Foregroundcolor Red 
	}
    
	# Check the importance level
	$mp = Get-FASTSearchMetadataManagedProperty -Name $managedPropertyName
	$fullTextIndexesEnum  = $mp.GetFullTextIndexMappings()
	$hasmappings = $false
	foreach($index in $fullTextIndexesEnum)
	{
		$hasmappings = $true
		if($index.FullTextIndex.Name -ne $fullTextIndexName)
		{
			write-host ("Importance level for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName is set to:"+$index.ImportanceLevel) 
		}
		if($global:importanceLevelSet -eq $false)
		{
			write-host ("Importance level for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName is set to:"+$index.ImportanceLevel) 
		}
		else
		{
			if($index.ImportanceLevel -ne $importanceLevel)
			{
				write-host ("Importance level for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName is set to:"+$index.ImportanceLevel+" Expected:$importanceLevel") -Foregroundcolor Red 
			}
			elseif($index.ImportanceLevel -eq $importanceLevel)
			{
				write-host ("Importance level set for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName to:$importanceLevel") -Foregroundcolor Green 				
			}
		}
	}
	if($hasmappings -eq $false)
	{
		write-host ("Could not find a mapping for this managed property") -Foregroundcolor Yellow 				
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

getImportanceLevelForMP 



