<#
.SYNOPSIS
	Gets the FAST Fixml encoding for a document
.DESCRIPTION
	This script does the following:
	Find the FIXML file containing the target document
	Expand (unzip) the FIXML file
	Pull out the <document> fragment and save that to a file by itself
	(Optionally) Calls Get-FASTSearchSecurityDecodedSid for all acls
.PARAMETER InternalId
	FAST internal id of the document you want to retrieve
.PARAMETER OutputFile
	Output file to write to.  If not specified a file will be created in $FASTSEARCH\var and named INTERNALID.xml.  If specified, it should be a full path name.
.PARAMETER ConvertAcls
	If specified, the associated ACLS will be pulled and decoded
.EXAMPLE 
Get-FASTFixml.ps1 8ae5e43c3639bb9b4fd1fec8f27a53d6_sp -OutputFile $env:TEMP\foo.xml
Expanding D:\FASTSEARCH\data\data_fixml\Set_000009\Elem_c7.xml.gz into D:\FASTSEARCH\Var\Fixml.xml
Writing document to C:\Users\esadmin\AppData\Local\Temp\6\foo.xml
.NOTES
	File Name : Get-FASTFixml.ps1
	Author    : Brent Groom <brent.groom@microsoft.com>, Matthew King <matthew.king@microsoft.com>

#>

param(
	[Parameter(Mandatory=$True)]
	[string]$InternalId,
	[string]$OutputFile = $null,
	[switch]$ConvertAcls = $false
)

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

#Given a ssic, get the internalid from qrserver, get the fixml, get the acl info from fixml, decode the sid list, perform a query as a specific user, get the sid list of a user
# given the internalid: get the fixml
$FASTSEARCH = [environment]::GetEnvironmentVariable("FASTSEARCH","Machine").toUpper()
if (-not $FASTSEARCH -or (-not (Test-Path $FASTSEARCH))) {
	Write-Error "FAST not found $FASTSEARCH"
	return
}
$selp1 = "." + $InternalId
$selp2 = Join-Path $FASTSEARCH "data\data_index\[0-9]\*[0-9]\index_data\urlmap_sorted.txt"
$fixmlfile = Select-string $selp1 $selp2

#$fixmlfile
#get the fixml gz file from the string: 
#C:\FASTSEARCH\data\data_index\0\index_1273910473294360000\index_data\urlmap_sorted.txt:22:.6938082d1772acf381d76dd8508a9b56_sp,Set_000106\Elem_63.xml.gz 1
$strval = [String]$fixmlfile
$splitstrval = $strval.split(",")
$rightside = $splitstrval[1]
$splitrightside = $rightside.split(" ")
$leftside = $splitrightside[0]

$inputfile = Join-Path $FASTSEARCH "data\data_fixml\$leftside"
$fixmlfile = Join-Path $FASTSEARCH "Var\Fixml.xml"

Write-Host "Expanding $inputfile into $fixmlfile"

@"
import gzip
import sys
i = gzip.open(sys.argv[1])
o = open(sys.argv[2],"w")
o.writelines(i.readlines())
i.close()
o.close()
"@ | Out-File -encoding ascii "$FASTSEARCH\bin\unpackfixml.py"
$fixmlpy = Join-Path $FASTSEARCH "bin\unpackfixml.py"

if (Test-Path $fixmlfile) { rm $fixmlfile }

$cobra = Join-Path $FASTSEARCH "bin\cobra"
& $cobra $fixmlpy $inputfile $fixmlfile

if (-not (Test-Path $fixmlfile)) {
	Write-Error "Cannot find output file '$fixmlfile'"
	return
}

[xml]$xmldata = Get-Content $fixmlfile
$node = $xmldata.SelectNodes("/fixmlDocumentCollection/document/summary/sField[@name='internalid'][.='$InternalId']")
if (-not $node) {
	Write-Error "Failed to find document in fixml"
	return 1
}
$node = $node.Item(0)
$doc = $node.ParentNode.ParentNode

if (-not $OutputFile) {
	$OutputFile = Join-Path $FASTSEARCH "var\$InternalId.xml"
}
Write-Host "Writing document to $OutputFile"
$writerSettings = New-Object System.Xml.XmlWriterSettings
$writerSettings.Indent = $true
$writer = [System.Xml.XmlWriter]::Create($OutputFile, $writerSettings)
$doc.WriteTo($writer)
$writer.Flush()
$writer.Close()

if ($ConvertAcls) {
	$docacl = $doc.SelectNodes("//context[@name='bcondocacl']")
	if (-not $docacl) { 
		Write-Error "Failed to find the document in the fixml file"
		return
	}
	$aclstr = $docacl.get_ItemOf(0).get_InnerText()
	#$aclstr 
	# split on ' ' and iterate the list
	$acls = $aclstr.split(" ")
	#$acls
	"List of permit Acls on the doc"
	foreach($acl in $acls)
	{
	  if($acl.StartsWith('win'))
	  {
		$encodedsid=$acl.Substring(3)
		#$encodedsid
		Get-FASTSearchSecurityDecodedSid -EncodedSID $encodedsid
	  }
	}

	"List of deny Acls on the doc"
	foreach($acl in $acls)
	{
	  if($acl.StartsWith('9win'))
	  {
		$encodedsid=$acl.Substring(4)
		#$encodedsid
		Get-FASTSearchSecurityDecodedSid -EncodedSID $encodedsid
	  }
	}
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQtF7GUsOTyDRYMm2hbhjvRad
# QwGgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKmYFqI/VAn/mVka
# BikNaWnydiHbMA0GCSqGSIb3DQEBAQUABIIBAFMXl+xLnBJMyPH5+TzzEMJFZYVB
# Cdgej98eOsokOorpEgvZFvindfs0CzthvVZ3RrnKFMnk9pAP8uDeZ2wCJM3lPXmW
# OaFuIEZvxwreVe3lmEE3pUzirVIdcGbWQNL+gXuWon+b9Yu+hjs/ScJDkAJbOCMV
# Pj4XNbcrx9o1xC2z+giF6ZpiJ+dFdzwALpxJ8LaXSi8H3xhsWrlkBU/N4sIWWWEB
# /2JSZksSi3jh4vdVHxzZ2ILVrgsekKji3IIYjRL794L8AIj/QImzLInnz1d6pIKq
# arGeIn9bXKMt3SAAMtkzxx9++oCjerHF3kh2ydxXYk+2n5c+EPwipKBoFks=
# SIG # End signature block
