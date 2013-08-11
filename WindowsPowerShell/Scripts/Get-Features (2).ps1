# ------------------------------------------------------------------
# Title: Get-Features
# Author: Fredrik Wall
# Description: Will show features
# Date Published: 27-Dec-2009 3:00:26 AM
# Source: http://gallery.technet.microsoft.com/scriptcenter/b388dacd-c7da-4593-b882-d297c51c0e79
# Tags: Windows 7;Features
# Rating: 5 rated by 1
# ------------------------------------------------------------------

function Get-Features {
<#
	.Synopsis
		Will get features on your computer
	.Description
		Will get features on your computer.
		Works on Windows 7 and Windows Server 2008 R2
	.Example
		Get-Features
	Will list all installed and all avaiable features
	.Example
		(Get-Features).count
	Will show how many features you have on your computer
	.Example
		Get-Features installed
	Will list all installed features
	.Example
		(Get-Features installed).count	
	Will show how many installed features you have on your computer
	.Example
		Get-Features available
	Will list all avaiable features
	.Example
		(Get-Features available).count
	Will show how many avaiable features you have on your computer
	.Notes
	 NAME:      Get-Features
	 AUTHOR:    Fredrik Wall, fredrik@poweradmin.se
	 BLOG:		poweradmin.se/blog
	 LASTEDIT:  12/27/2009
#>
param ($state)
	$feature = Get-WmiObject -Class Win32_OptionalFeature

	# Show installed features
	if ($state -match "installed") {
		foreach ($optional in $feature) {
		if ($optional.InstallState -eq "1") {
			$optional.caption + " (" + $optional.Name + ")"
		}
		}
	}
	
	# Show features available for installation
	if ($state -match "available") {
	foreach ($optional in $feature) {
		if ($optional.InstallState -eq "2") {
			$optional.caption + " (" + $optional.Name + ")"
		}
		}
	}

	# Show all features
	if ($state -eq $null) {
	foreach ($optional in $feature) {
		$optional.caption + " (" + $optional.Name + ")"
		}
	}
	# Cleanup
	$state = $null
	$feature = $null
	$optional = $null
}