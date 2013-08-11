function Get-TheVillageChurchPodCast {
	<#
	.SYNOPSIS
		Gets The Village Church sermon podcasts.

	.DESCRIPTION
		The Get-TheVillageChurchPodcast function returns objects of all the available sermon podcasts from The Village Church.
		The objects can be filtered by speaker, series, title, or date and optionally downloaded to a specified folder.

	.PARAMETER Speaker
		Specifies the name of the podcast speaker. The wildcard '*' is allowed.

	.PARAMETER Series
		Specifies the series of the podcast. The wildcard '*' is allowed.

	.PARAMETER Title
		Specifies the title of the podcast. The wildcard '*' is allowed.

	.PARAMETER Date
		Specifies the date or date range of the podcast(s).

	.PARAMETER DownloadPath
		Specifies the download folder path to save the podcast files.

	.EXAMPLE
		Get-TheVillageChurchPodcast
		Gets all the available sermon podcasts from The Village Church.

	.EXAMPLE
		Get-TheVillageChurchPodcast -Speaker MattChandler -Series Habakkuk
		Gets all the sermon podcasts where Matt Chandler is the speaker and the series is Habakkuk.
		
	.EXAMPLE
		Get-TheVillageChurchPodcast -Speaker MattChandler -Date 1/1/2003,3/31/2003
		Gets all the sermon podcasts where Matt Chandler is the speaker and the podcasts are in the date ranage 1/1/2003 - 3/31/2003.
		
	.EXAMPLE
		Get-TheVillageChurchPodcast -Speaker MattChandler -Date 1/1/2003,3/31/2003 -DownloadPath C:\temp\TheVillage
		Gets all the sermon podcasts where Matt Chandler is the speaker and the podcasts are in the date ranage 1/1/2003 - 3/31/2003 and
		downloads the podcast files to the folder path C:\temp\TheVillage.

	.INPUTS
		System.String

	.OUTPUTS
		PSObject

	.NOTES
		Name: Get-TheVillageChurchPodCast
		Author: Rich Kusak
		Created: 2011-06-14
		LastEdit: 2011-09-12 11:07
		Version: 1.2.0.0

	.LINK
		http://fm.thevillagechurch.net/sermons

	.LINK
		about_regular_expressions

#>

	[CmdletBinding()]
	param (
		[Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Speaker = '*',

		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Series = '*',

		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Title = '*',

		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateCount(1,2)]
		[datetime[]]$Date = ([datetime]::MinValue,[datetime]::MaxValue),

		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateScript({
				if ($_) {
					if (Test-Path $_ -IsValid) {$true} else {
						throw "The download path '$_' is not valid."
					}
				} else {$true}
			})]
		[string]$DownloadPath
	)

	begin {

		$sermonsUri = 'http://fm.thevillagechurch.net/sermons'
		$studiesSeminarsUri = 'http://fm.thevillagechurch.net/studies-seminars'
		$resourceFilesAudioUri = 'http://fm.thevillagechurch.net/resource_files/audio/'

		$partRegex = "href='/resource_files/audio/(?<file>(?<date>\d{8}).*_(?<speaker>\w+)_(?<series>\w+)Pt(?<part>\d+)-(?<title>\w+)\.mp3)'"
		$noPartRegex = "href='/resource_files/audio/(?<file>(?<date>\d{8}).*_(?<speaker>\w+)_(?<series>\w+)-(?<title>\w+)\.mp3)'"

		$webClient = New-Object System.Net.WebClient
		if ([System.Net.WebProxy]::GetDefaultProxy().Address) {
			$webClient.UseDefaultCredentials = $true
			$webClient.Proxy.Credentials = $webClient.Credentials
		}

	} # begin

	process {

		try {
			Write-Debug "Performing operation 'DownloadString' on target '$sermonsUri'."
			$reference = $webClient.DownloadString($sermonsUri)

			$pages = [regex]::Matches($reference, 'page=(\d+)&') | ForEach {$_.Groups[1].Value} | Sort -Unique
			$pages | ForEach -Begin {$sermons = @()} -Process {
				$sermonsPageUri = "http://fm.thevillagechurch.net/sermons?type=sermons&page=$_&match=any&kw=&topic=&sb=date&sd=desc"
				Write-Debug "Performing operation 'DownloadString' on target '$sermonsPageUri'."
				$sermons += $webClient.DownloadString($sermonsPageUri)
			}
		} catch {
			return Write-Error $_
		}

		$obj = foreach ($line in $sermons -split '(?m)\s*$') {
			if ($line -match $partRegex) {
				New-Object PSObject -Property @{
					'File' = $matches['file']
					'Date' = "{0:####-##-##}" -f [int]$matches['date']
					'Speaker' = $matches['speaker']
					'Series' = $matches['series']
					'Part' = "{0:d2}" -f [int]$matches['part']
					'Title' = $matches['title']
				}

			} elseif ($line -match $noPartRegex) {
				New-Object PSObject -Property @{
					'File' = $matches['file']
					'Date' = "{0:####-##-##}" -f [int]$matches['date']
					'Speaker' = $matches['speaker']
					'Series' = $matches['series']
					'Part' = '00'
					'Title' = $matches['title']
				}
			}
		} # foreach ($line in $sermons -split '(?m)\s*$')

		if ($PSBoundParameters['Date']) {
			switch ($Date.Length) {
				1 {$Date += $Date ; break}
				2 {
					if ($Date[0] -gt $Date[1]) {
						[array]::Reverse($Date)
					}
				}
			} # switch
		} # if ($PSBoundParameters['Date'])

		if ($DownloadPath) {
			try {
				if (-not (Test-Path $DownloadPath -PathType Container)) {
					New-Item $DownloadPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
				}
			} catch {
				return Write-Error $_
			}

			[PSObject[]]$filter = $obj | Where {
				$_.Speaker -like $Speaker -and
				$_.Series -like $Series -and
				(					[datetime]$_.Date -ge $Date[0]) -and ([datetime]$_.Date -le $Date[1])
			}

			$count = $filter.Length
			$i = 0

			foreach ($podcast in $filter) {
				$fullPath = Join-Path $DownloadPath $podcast.File
				if (Test-Path $fullPath) {
					Write-Warning "File '$fullPath' already exists."
					continue
				}

				try {
					Write-Debug "Performing operation 'DownloadFile' on target '$($podcast.File)'."
					Write-Progress -Activity 'Downloading PodCast' -Status $podcast.File -PercentComplete $(($i / $count)*100 ; $i++) -CurrentOperation "$i of $count"
					$webClient.DownloadFile($resourceFilesAudioUri + $podcast.File, $fullPath)
				} catch {
					Write-Error $_
					continue
				}
			} # foreach ($podcast in $filter)

			Write-Progress -Activity 'Downloading PodCast' -Status 'Complete' -PercentComplete 100
			Sleep -Seconds 1

		} else {
			$obj | Where {
				$_.Speaker -like $Speaker -and
				$_.Series -like $Series -and
				$_.Title -like $Title -and
				(					[datetime]$_.Date -ge $Date[0]) -and ([datetime]$_.Date -le $Date[1])
			} | Select Date, Speaker, Series, Part, Title | Sort Date
		}
	} # process
} # function Get-TheVillageChurchPodCast {