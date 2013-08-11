# ==============================================================================================
# NAME:			Check-FileExists
# AUTHOR:		Brian Hagerty , Austin Community College
# DATE:			06/01/2009
# COMMENT:		
# MODIFIED:		
# ==============================================================================================

function Check-FileExists ([string]$Path, [switch]$Output) {
	BEGIN { 
		# Display help content, if -? is specified at command line
		if ($args -contains '-?') {
			Write-Host -ForegroundColor Yellow "`nPURPOSE:`nPipeline function!  Accepts computer names from pipeline & checks to see whether the provided path exists on the machine. If the Output switch is provided then it outputs the computers that the file exists on to the pipeline."
			Write-Host -ForegroundColor Green "`nSYNTAX:`n`$computername_array | Check-FileExists [[-Path] <String>] [-Output]`n"
			break
		}

		$Computers_FileExists = @()
	}
	PROCESS {
		Test-Pipeline
		$Computer = $_

		Write-Host "Checking $Computer for: $Path"
		if (!($Path -like "HK*")) {
			# Test that the file/folder/registry key exists at the specified path/location
			if (Test-Path -Path $Path) {
				Write-Host -ForegroundColor Green "File/folder exists on $Computer!`n"
				$Computers_FileExists += $Computer
			} else { Write-Warning "File/folder does not exist on $Computer!!`n" }
		} else {
			[string]$RegistryBaseKey = $Path.Split(':')[0]
			[string]$SubKey = $Path.Split(':')[1].SubString(1)

			switch ($RegistryBaseKey) {
				"HKLM" { $HKey = 'LocalMachine' }
				"HKCU" { $HKey = 'CurrentUser' }
				Default { Write-Warning "Registry path must start with 'HKLM:\' or 'HKCU:\'" }
			}

			# Test to see if the supplied registry key exist on the current machine
			$RegistryPath = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($HKey,$Computer).OpenSubKey($SubKey)
			if ($RegistryPath -ne $null) {
				Write-Host -ForegroundColor Green "Registry key exists on $Computer!`n"
				$Computers_FileExists += $Computer
			} else { Write-Warning "Registry key does not exist on $Computer!!`n" }
		}
	}
	END { if ($Output.IsPresent) { Write-Output $Computers_FileExists } }
}