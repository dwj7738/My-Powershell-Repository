<#
.SYNOPSIS
       The purpose of this script is to check the managed property weight for a rank profile 
.DESCRIPTION
       The purpose of this script is to check the managed property weight for a rank profile. 
	   You may specify a rank profile name, managed property name, and expected weight. 
	   This script can be used for validating an installation. It can be used see what the 
	   current relevancy settings are and to find out if they need to be changed or if they 
	   are already set correctly.
	   
.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1 -ManagedPropertyName urldepthrank -ExpectedWeight 300

Output:
Rank profile URLboost1 has weight set to 200 for urldepthrank.

.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1

This example shows running the script with no parameters. The script will display all rank profiles along with all managed properties and their weights

Output:
Rank profile default has weight set to 300 for hwboost
Rank profile default has weight set to 300 for docrank
Rank profile default has weight set to 300 for siterank
Rank profile default has weight set to 300 for urldepthrank
Rank profile URLboost has weight set to 300 for hwboost
Rank profile URLboost has weight set to 300 for docrank
Rank profile URLboost has weight set to 300 for siterank
Rank profile URLboost has weight set to 300 for urldepthrank
Rank profile URLboost1 has weight set to 300 for hwboost
Rank profile URLboost1 has weight set to 300 for docrank
Rank profile URLboost1 has weight set to 300 for siterank
Rank profile URLboost1 has weight set to 300 for urldepthrank

.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1 -ManagedPropertyName urldepthrank -ExpectedWeight 300

This checks given a rank profile name, a managed property name and an expected weight. If everything matches up the output displays in green otherwise it is red

Output:
Rank profile URLboost1 has weight set to 300 for urldepthrank

.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1 -ManagedPropertyName urldepthrank

This example shows specifying the rank profile name as well as a property name

Output:
Rank profile URLboost1 has weight set to 300 for urldepthrank

.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1

This example shows output of all managed properties with their weight for a given rank profile

Output:
Rank profile URLboost1 has weight set to 300 for hwboost
Rank profile URLboost1 has weight set to 300 for docrank
Rank profile URLboost1 has weight set to 300 for siterank
Rank profile URLboost1 has weight set to 300 for urldepthrank

.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1ss

This example shows the output for an invalid rank profile name

Output:
Rank profile not found: URLboost1ss

.LINK
This Script - http://gallery.technet.microsoft.com/scriptcenter/a30df851-a439-4441-9c0f-e9f8cf08b070
.NOTES
  File Name : Get-RelevancyWeightForManagedProperty.ps1
  Author    : Ben Lin, Brent Groom 
#>

# TODO - implement uninstall, drive from a config file, use return codes

param
  (
	
	[switch]
    # Signifies that the script should output debug statements
    $DebugMode, 
    
    [string]
    # Specifies name of the rank profile to update or create 
    $RankProfileName="", 
	
    [string]
    # Allows you to specify the From: email address from the command line 
	$ManagedPropertyName = "",
    
	[int]
    # Allows you to specify the To: email address from the command line 
	$ExpectedWeight = -1
    
    )

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

$global:foundMP = $false

function GetRelevancyWeightForManagedProperty($rankprofilename)
{
	
	$customRP = Get-FASTSearchMetadataRankProfile -Name $rankprofilename -erroraction SilentlyContinue
	
	if($customRP -ne $null)
	{
		$customQCEnum = $customRP.GetQualityComponents()

		foreach($qc in $customQCEnum)
		{
			if($ManagedPropertyName.Length -eq 0)
			{
				write-host ("Rank profile $rankprofilename has weight set to "+$qc.Weight+" for " + $qc.ManagedPropertyReference.Name ) -Foregroundcolor Red 
				#$qc.ManagedPropertyReference.Name
			}
			elseif($qc.ManagedPropertyReference.Name -eq $ManagedPropertyName ) 
			{
			    $global:foundMP = $true
				if($ExpectedWeight -eq $qc.Weight)
				{
					write-host ("Rank profile $rankprofilename has weight set to "+$qc.Weight+" for " + $qc.ManagedPropertyReference.Name ) -Foregroundcolor Green 			
					
				}
				else
				{
				    write-host ("Rank profile $rankprofilename has weight set to "+$qc.Weight+" for " + $qc.ManagedPropertyReference.Name ) -Foregroundcolor Red 			
				}
			}
		}
		
	}
	else
	{
        write-host ("Rank profile not found: $rankprofilename ") -Foregroundcolor Red
	
	}
	
}


function GetRelevancyWeightForManagedProperties()
{
	
	if($RankProfileName.length -eq 0)
	{
	    $rpEnum = Get-FASTSearchMetadataRankProfile
		foreach($rp in $rpEnum)
		{
			GetRelevancyWeightForManagedProperty($rp.Name)
		}
	}
	else
	{
        GetRelevancyWeightForManagedProperty($RankProfileName)
		if($ManagedPropertyName.Length -gt 0 -and $global:foundMP -eq $false)
		{
            write-host ("Managed property not found: $ManagedPropertyName ") -Foregroundcolor Red			
		}
	}
		
	# Map a managed property to a full-text index at a specific importance level by using Windows PowerShell (FAST Search Server 2010 for SharePoint)
	# http://msdn.microsoft.com/en-us/library/ff191254.aspx
	
}

if($DebugMode)
{
	"Using following values:"
	"  DebugMode:$DebugMode"
	"  RankProfileName:$RankProfileName"
	"  ManagedPropertyName:$ManagedPropertyName"
	"  ExpectedWeight:$ExpectedWeight"
}

GetRelevancyWeightForManagedProperties



