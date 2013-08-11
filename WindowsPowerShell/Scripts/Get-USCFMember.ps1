#Requires -Version 2.0
<#
	.SYNOPSIS
		Get-USCFMember connects to USCF website and returns search results using specified Name or USCF ID.

	.DESCRIPTION
		Get-USCFMember requires connection to internet. If connected to internet, the function returns search results using specified Name of USCF ID of a USCF member. The script is able to search based on Lastname or USCF ID of members. It can also search using Firstname of wildcard if Lastname is specified.

	.PARAMETER  Lastname
		Lastname of USCF member to search.

	.PARAMETER  Firstname
		Firstname of USCF member to search.
	
	.PARAMETER Wildcard
		Perform a wildcard search when Lastname is specified.
	
	.PARAMETER USCFID
		Perform a search using USCF ID of a member.

	.PARAMETER OutFile
		Write search results to a csv file. When this parameter is specified, output to console is suppressed.
		
	.EXAMPLE
		PS C:\> Get-USCFMember -Lastname Shukla -Firstname Bhargav
		
		LastName       : SHUKLA
		Firstname      : BHARGAV L
		USCF ID        : 12837106
		State          : PA
		Regular Rating : 572P
		Quick Rating   : 580P

		This example shows how to call the Get-USCFMember function with named parameters.

	.EXAMPLE
		PS C:\> Get-USCFMember Shukla Bhargav
		
		LastName       : SHUKLA
		Firstname      : BHARGAV L
		USCF ID        : 12837106
		State          : PA
		Regular Rating : 572P
		Quick Rating   : 580P

		This example shows how to call the Get-USCFMember function with positional parameters.

.EXAMPLE
		PS C:\> Get-USCFMember -Lastname Shukla -OutFile c:\temp\shukla.csv

		This example shows how to write resulting data to csv file.
		
	.INPUTS
		System.String,System.Int32,System.Boolean

	.OUTPUTS
		System.String

	.NOTES
		For more information about advanced functions, call Get-Help with any
		of the topics in the links listed below.

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

	.LINK
		about_functions_advanced_parameters

	.LINK
		about_functions_advanced_methods
#>
function Get-USCFMember 
{
	[CmdletBinding()]
	param(
		[Parameter(Position=0)]
		[String]
		$Lastname,
		[Parameter(Position=1)]
		[String]
		$Firstname,
		[Parameter(Position=2)]
		[Switch]
		$Wildcard,
		[Int]
		$USCFID,
		[String]
		$OutFile
	)
	
	# Check if internet is accessible. Return error and exit if not connected
	[bool] $HasInternetAccess = ([Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}')).IsConnectedToInternet)
	If (-not ($HasInternetAccess))
	{
		Write-Error "Get-USCFMember requires connection to internet. Please ensure you are connected to internet before calling Get-USCFMember."
		return
	}

	# Validate parameters
	If ($USCFID)
	{
		If ($Lastname -or $Firstname -or $Wildcard)
		{
			Write-Error "USCFID is an exclusive parameter. It cannot be used with other parameters."
			return
		}
		If (-not ($USCFID -match [regex]"^\d{8}$"))
		{
			Write-Error "USCFID must be an 8 digit number."
			return
		}
	
		$Search = "$($USCFID.toString())"
	}
	Else
	{
		If (-not $Lastname)
		{
			Write-Error "Lastname or USCFID must be specified"
			return
		}
		Else
		{
			If ($Firstname -and $Wildcard)
			{
				$Search = "$Lastname, $Firstname*"
			}
			ElseIf ($Firstname)
			{
				$Search = "$Lastname, $Firstname"
			}
			ElseIf ($Wildcard)
			{
				$Search = "$Lastname*"
			}
			Else
			{
				$Search = "$Lastname"
			}
		}
	}
	If ($OutFile)
	{
		If (-not (Test-Path (Split-Path $OutFile)))
		{
			Write-Error "Specified path for outfile is incorrect or doesn't exist. Please provide correct path."
			return
		}
		If (Test-Path $OutFile)
		{
			Write-Error "Specified file exists. Please provide name of a new file to create."
			return
		}
		
		Out-File -FilePath $OutFile -InputObject 'Lastname,Firstname,USCF ID,State,Regular Rating,Quick Rating' -Encoding ascii
	}
	
	# Define regex and query USCF website with specified parameters
	$regex = [regex]"(?<USCFID>\d{8})\s*?\((?<State>.{2})\)\s*\d{4}-\d{2}-\d{2}\s*(?<Reg>.{3,5}\S)\s*(?<Quick>.{3,5}\S)\s*.*?>(?<Name>.*?)<"
	$HTTP = new-object -com Microsoft.XMLHTTP
	$HTTP.open( "POST", 'http://main.uschess.org/assets/msa_joomla/MbrLst.php', $False )
	$HTTP.setRequestHeader( 'Content-Type', 'application/x-www-form-urlencoded')
	$HTTP.send( "eMbrKey=$Search" )
	
	# Create object with search results
	$HTTPARR = $HTTP.responseText.Split("`n")
	ForEach ($line in $HTTPARR)
	{
		if ($line -match $Search -and -not($line -match "value")) {[array]$match += $line}
	}
	
	# Create Collection of member objects and output to file if requested
	$Members = ForEach ($Member in $match)
	{
		if ($Member -match "$regex")
		{
			$Member = New-Object PSObject
				add-member -InputObject $Member -MemberType Noteproperty -Name LastName -Value $((($($Matches['Name'])).split(","))[0].Trim())                 
            	add-member -InputObject $Member -MemberType Noteproperty -Name Firstname -Value $((($($Matches['Name'])).split(","))[1].Trim())             
            	add-member -InputObject $Member -MemberType Noteproperty -Name "USCF ID" -Value $($Matches['USCFID'])
            	add-member -InputObject $Member -MemberType Noteproperty -Name State -Value $($Matches['State'])
            	add-member -InputObject $Member -MemberType Noteproperty -Name "Regular Rating" -Value $($Matches['Reg'].trim())
				add-member -InputObject $Member -MemberType Noteproperty -Name "Quick Rating" -Value $($Matches['Quick'].trim())
			$Member
			
			If ($OutFile)
			{
			Out-File -FilePath $OutFile -InputObject "$($member.Lastname),$($member.Firstname),$($member.""USCF ID""),$($member.State),$($member.""Regular Rating""),$($member.""Quick Rating"")" -Append -Encoding ascii
			}
		}
	}

	# Write Output to console only if outfile is not specified
	If (-not ($OutFile))
	{
		Write-Output $Members
	}
}
