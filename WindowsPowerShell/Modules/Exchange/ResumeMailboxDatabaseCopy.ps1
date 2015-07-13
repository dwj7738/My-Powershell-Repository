<#
.EXTERNALHELP ResumeMailboxDatabaseCopy-help.xml
#>

# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Mailbox Database Resume
#
#
param(
	[string]	$MailboxServer,
	[string]	$Database,
	[switch]	$Datacenter=$false,
	[switch]	$Verbose=$false)

#
# Helper function
#

Import-LocalizedData -BindingVariable ResumeMailboxDatabaseCopy_LocalizedStrings -FileName ResumeMailboxDatabaseCopy.strings.psd1
Set-StrictMode -Version 2.0

$CopyStatusType = [Microsoft.Exchange.Management.SystemConfigurationTasks.CopyStatus]
$ServiceInitiatorType = [Microsoft.Exchange.Rpc.Cluster.ActionInitiatorType]

$SleepBeforeStatusRecheck = 120
$CaLockTimeout = 300

function Execute-Resume
{
	Log-Verbose ($ResumeMailboxDatabaseCopy_LocalizedStrings.res_0000 -f $MailboxServer,$Database,$Datacenter,$Verbose)

	if ( ! ($MailboxServer -and $Database) )
	{
		Log-Error $ResumeMailboxDatabaseCopy_LocalizedStrings.res_0001
		Return
	}

	$server = Get-ExchangeServer | where {$_.Name -ieq $MailboxServer}
	$problemdb = Get-MailboxDatabase -Status | where {$_.Name -ieq $Database}

	if ( (!$server) -or (!$problemdb) )
	{
        	Log-Error ($ResumeMailboxDatabaseCopy_LocalizedStrings.res_0002 -f $Database,$MailboxServer)
        	Return
	}

	$copy = "$Database\$MailboxServer"
	$locked = $false

	if ( $Datacenter )
	{
		try
		{
			Log-Verbose ($ResumeMailboxDatabaseCopy_LocalizedStrings.res_0003 -f $copy,$CaLockTimeout)
			$lock = New-CentralAdminLock -Object $copy -Timeout $CaLockTimeout -ErrorAction Stop
			$locked = $true
		}
		catch
		{
			Log-Error ($ResumeMailboxDatabaseCopy_LocalizedStrings.res_0004 -f $copy)
			Return
		}
	}

	$copyStatus = Get-MailboxDatabaseCopyStatus $copy

	$copyOK = $false;

	if (($copyStatus.Status -eq $CopyStatusType::Suspended) `
		-or ($copyStatus.Status -eq $CopyStatusType::FailedAndSuspended))
	{

		if ($copyStatus.ActionInitiator -eq $ServiceInitiatorType::Service)
		{
			Resume-MailboxDatabaseCopy $copy -Confirm:$false

			for ($i = 1 ; $i -lt 9; $i++)
			{
				Log-Verbose ($ResumeMailboxDatabaseCopy_LocalizedStrings.res_0005 -f $copy,$i,$SleepBeforeStatusRecheck)

    				$CheckCmd = { $newStatus = Get-MailboxDatabaseCopyStatus $copy;
					return $newStatus.Status -eq $CopyStatusType::Healthy }

				if (WaitForCondition $CheckCmd $SleepBeforeStatusRecheck)
				{
					$copyOK = $true;
					break;
				}
			}
		}
		else
		{
			Log-Verbose ($ResumeMailboxDatabaseCopy_LocalizedStrings.res_0006 -f $copy)
			$copyOK = $true;
		}
	}
	else
	{
		Log-Verbose ($ResumeMailboxDatabaseCopy_LocalizedStrings.res_0007 -f $copy)
		$copyOK = $true;
	}

	if ($locked)
	{
		$lockIdentity = $lock.Id
		if ($lockIdentity)
		{
			Remove-CentralAdminLock -Identity $lockidentity -Confirm:$false
		}
	}	
	
	if ($copyOK)
	{
		Log-Verbose ($ResumeMailboxDatabaseCopy_LocalizedStrings.res_0008 -f $copy)	
		Return
	}
	else
	{
		Log-Error ($ResumeMailboxDatabaseCopy_LocalizedStrings.res_0009 -f $copy)	
		Return
	}
	
}


function WaitForCondition {
    param ([ScriptBlock] $condition, [int] $seconds)
     
    $endTime = [DateTime]::Now.addseconds($seconds)
    while ([DateTime]::Now -lt $endTime)
    {
	   if ( &$condition )
	   {
	       return $true
	   }
	   sleep -seconds 2
    }
     
    # Check one last time
    if ( &$condition )
    {
        return $true
    }
    return $false
}

# Common function to retrieve the current UTC time string
function Get-CurrentTimeString
{
	return [DateTime]::UtcNow.ToString("[HH:mm:ss.fff UTC]")
}

# Common function for verbose logging
function Log-Verbose ( [string]$msg )
{
	if ($Verbose)
	{
		$timeStamp = Get-CurrentTimeString
		Write-Verbose "$timeStamp $msg"
	}
}

# Common function for warning logging
function Log-Warning ( [string]$msg )
{
	$timeStamp = Get-CurrentTimeString
	Write-Warning "$timeStamp $msg"
}

# Common function for error logging
function Log-Error ( [string]$msg, [switch]$Stop)
{
	$timeStamp = Get-CurrentTimeString
	if (!$Stop)
	{
		Write-Error "$timeStamp $msg"
	}
	else
	{
		Write-Error "$timeStamp $msg" -ErrorAction:Stop
	}
}

Execute-Resume

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2wEq7BEKW+I9m2zuCIsnxUcc
# PyKgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAN0ZOWCIOEyhtxA/koB0azqKK40Pw3fa8GLif/ZM0cXJWGawkVgxOMbejeJW
# YCqXgEHF2MX/cJY8svCmLlX8M7AdjXYgtAS+C+cEHxrGAMMzj3/9EOu6DjzxIcwL
# l1GKoUwy8X3/GRGk3sBWT5CwKYRJdh9goWy74ltZN+sTKKeDHqpfuvxye6c++PC7
# 86wzm4MwfOIuPE9StFeo/0nKheEukfK9cpthlE5dUHpW0OjmJdX/g0mEdIjm2/Q2
# 50fzQyLQXOuMVIJ4Qk2comMDNRvZZvSPOBwWZ6fAR4tXfZwlpUcLv3wBbIjslhT7
# XasCm73TdBj+ZFDx2tUtpWguP/0CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBS+FASXsrRle2tLXdkVyoT1Dbw7
# QDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAbhjcmv+WCZwWCIYQwiEsH94SesBr0cPqWjEtJrBefqU9zFdB
# u5oc/WytxdCkEj5bxkoN9aJmuDAZnHNHBwIYeUz0vNByZRz6HsPzNPxLxThajJTe
# YOHlSTMI/XzBhJ7VzCb3YFhkD5f9gcJ5n+Z94ebd/1SoIvc9iwC3tTf5x2O7aHPN
# iyoWLTV4+PgDntCy/YDj11+uviI9sUUjAajYPEDvoiWinyT+7RlbStlcEuBwqvqT
# nLaiRsK17rjawW87Nkq/jB8rymUR/fzluIpHmPA4P0NazH4v5f62mpMFqdk0osMU
# QJ/qqACQ+2+/eAw7Gr6igNvlsxQpPfxsPNtUkTCCBTAwggQYoAMCAQICEAQJGBtf
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
# Q0ECEAYOIt5euYhxb7GIcjK8VwEwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPj6FCt4URJhQTFJ
# TSxtWaSfBwBXMA0GCSqGSIb3DQEBAQUABIIBABiC4+0+20E+58B6ks9NS1BMMAxL
# Kzwru/aG2IvBGp7eGgpTTWPtY+6V0lDDzRVwZDDjeExzCK4KQlBnswauEsQWDM6V
# xFvmCOWVhsbuiUV0LUj8XSf/s/vVdFkDJb+dpNv6yCnzqQVIB4XkFu+Cf84kF2Ug
# Mvr4ddjsECZFWKaicxMqs8vYHvxDs7Rpvly7Z2cG5s9fS8YcVrkMt313tucqjPtt
# 48FRdZrUKiQR3U3Wb93epYvZDhFVhw3rZMleEeBK5uUJ4BKKDOiuizCoce037Lzq
# lxzYLvbKAsAA5q4wQ838aNhSkzYnTTCj4ov14Mu/D/h8Chb0H0mefgsoN18=
# SIG # End signature block
