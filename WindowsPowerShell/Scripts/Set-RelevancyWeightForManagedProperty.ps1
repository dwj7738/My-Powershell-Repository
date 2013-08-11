<#
.SYNOPSIS
       The purpose of this script is to check the managed property weight for a rank profile and update it
.DESCRIPTION
       The purpose of this script is to check the managed property weight for a rank profile and update it.
	   You must specify the managed property name, rank profile name, and expected weight. if the rank profile
	   name is not specified then the script uses the default rank profile name. This script can be used in conjunction
	   with Get-RelevancyWeightForManagedProperty.
	   
.EXAMPLE
.\Set-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1 -ManagedPropertyName urldepthrank -ExpectedWeight 300 

Output:
Rank profile URLboost1 has weight set to 200 for urldepthrank. We were expecting it to be set to 300
Updated URLboost1 urldepthrank weight to 300.

.LINK
This Script - http://gallery.technet.microsoft.com/scriptcenter/858ff2e3-c391-40f8-a5b7-29da74f54d41
.NOTES
  File Name : Set-RankProfileWeight.ps1
  Author    : Ben Lin, Brent Groom 
#>

# TODO - implement uninstall, drive from a config file

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
	$ExpectedWeight = 0
    
    )

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

function SetRelevancyWeightForManagedProperty()
{
	if ( $RankProfileName.Length -eq 0)
	{
		write-host ("Rank profile not specified. Using default rank profile.") -Foregroundcolor Yellow
		$RankProfileName = "default"
	}

	if ( $ManagedPropertyName.Length -eq 0)
	{
		write-host ("Managed property must be set to a valid name.") -Foregroundcolor Red
		write-host ("We will now exit the script.") -Foregroundcolor Red
		return
	}
	
	$defaultRP = Get-FASTSearchMetadataRankProfile -Name default
	$customRP = Get-FASTSearchMetadataRankProfile -Name $RankProfileName -erroraction SilentlyContinue
	if($customRP -eq $null)
	{
		write-host ("Creating new rank profile $RankProfileName") -Foregroundcolor Yellow
		$global:customRP = New-FASTSearchMetadataRankProfile -Name $RankProfileName -Template $defaultRP
		write-host ("Created new rank profile $RankProfileName") -Foregroundcolor Green
	}

	#$customRP = Get-FASTSearchMetadataRankProfile -Name $RankProfileName -erroraction SilentlyContinue
	
	if($customRP -ne $null)
	{
		$customQCEnum = $customRP.GetQualityComponents()

		
		#######################
		$foundMP = $false
		foreach($qc in $customQCEnum)
		{
			if($qc.ManagedPropertyReference.Name -eq $ManagedPropertyName ) 
			{
				$foundMP = $true
				"1"
				$ExpectedWeight
				if($ExpectedWeight -eq $qc.Weight)
				{
					write-host ("Rank profile $rankprofilename has weight set to "+$qc.Weight+" for " + $qc.ManagedPropertyReference.Name ) -Foregroundcolor Green 								
				}
				else
				{
				    write-host ("Updating Rank profile $rankprofilename Managed property:" + $qc.ManagedPropertyReference.Name +" from weight:"+$qc.Weight+" to:$ExpectedWeight") -Foregroundcolor Red 			
					$qc.Weight = $ExpectedWeight
					$upd1 = $qc.Update()
					$upd1
				}
			}
		}
		if($foundMP -eq $false)
		{
		    write-host ("Could not find specified managed property:$ManagedPropertyName in rank profile:$RankProfileName ") -Foregroundcolor Red 						
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

SetRelevancyWeightForManagedProperty



