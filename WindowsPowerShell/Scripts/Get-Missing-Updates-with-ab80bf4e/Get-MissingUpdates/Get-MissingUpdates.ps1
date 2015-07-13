function Get-MissingUpdates {
	[CmdletBinding()]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(Mandatory,
				   ValueFromPipeline,
				   ValueFromPipelineByPropertyName)]
		[string]$ComputerName
	)
	begin {
		function Get-32BitProgramFilesPath {
			if ((Get-Architecture) -eq 'x64') {
				${ env:ProgramFiles(x86) }
			} else {
				$env:ProgramFiles
			}
		}
		
		function Get-Architecture {
			if ([System.Environment]::Is64BitOperatingSystem) {
				'x64'
			} else {
				'x86'
			}
		}
		
		$Output = @{ }
	}
	process {
		try {
			
			$ExeFilePath = "$(Get-32BitProgramFilesPath)\Microsoft Baseline Security Analyzer 2\mbsacli.exe"
			if (!(Test-Path $ExeFilePath)) {
				throw "$ExeFilePath not found"	
			}
			$CheckResult = & $ExeFilePath /target $ComputerName /n IIS+OS+Password+SQL /wi /nvc >2 nul
			$UpdateRegex = '\| (.+) \| Missing \| (.+) \| (.+)? \|'
			$CheckResult | where { $_ -match $UpdateRegex } | foreach { [pscustomobject]@{ 'KBNumber' = $matches[1]; 'Severity' = $matches[3]; 'Title' = $matches[2] } }
			
			[pscustomobject]$Output
		} catch {
			Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
		}
	}
}
