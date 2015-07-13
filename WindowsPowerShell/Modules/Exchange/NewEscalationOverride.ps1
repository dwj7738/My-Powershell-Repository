<#
    .SYNOPSIS
    SCM runs this script after a request for a new override gets approved.
    Test as follows:
        New-CentralAdminOperation -name foo -workflow executescript -arguments @{Target="exhb-99999"; Script="Scripts\NewEscalationOverride.ps1"; ScriptParameters=@{Machine="foo"; Urgent=$false; Expiration="12/1/2099"} }

    .PARAMETER Id
    GUID of the request.
    Should come from SCM; right now, it doesn't.

    .PARAMETER Reason
    Mandatory explanation of why you are requesting the override.
    Should come from SCM; right now, it doesn't.

    .PARAMETER Expiration
    Mandatory date/time when the override will expire.

    .PARAMETER Machine
    If overriding alerts from a specific machine, the exact name of the machine to which the override applies.

    .PARAMETER Monitor
    If overriding a specific monitor, the exact AlertTypeId of the monitor to which the override applies.

    .PARAMETER Site
    If overriding alerts from a specific site, the exact site to which the override applies.

    .PARAMETER Forest
    If overriding alerts from a specific forest, the exact forest to which the override applies.

    .PARAMETER MachineVersion
    If the override described by the previous parameters only applies to specific versions,
    the exact version string to which the override applies. Note that the version string is more than just the
    Exchange build. Look up the ActualVersion property using Get-CentralAdminMachine to see examples.

    .PARAMETER Suppressed
    Suppress the alert entirely (no page, no email).

    .PARAMETER Team
    Redirect the alert to a specific team. The value must match a known escalation team in the on-call rotation.

    .PARAMETER Urgent
    Make the alert non-paging. (Or make it paging if it isn't already, but why would you want to do that?)
 #>

[CmdletBinding()]
param
(
    # Won't get passed for right now.
    [Parameter(Mandatory = $false)]
    [System.Guid] $Id,

    # Won't get passed for right now.
    # [Parameter(Mandatory = $true)]
    # [string] $Reason,

    [Parameter(Mandatory = $true)]
    [System.DateTime] $Expiration,

    [Parameter(Mandatory = $false)]
    [string] $Machine,

    [Parameter(Mandatory = $false)]
    [string] $Monitor,

    [Parameter(Mandatory = $false)]
    [string] $Site,

    [Parameter(Mandatory = $false)]
    [string] $Forest,

    [Parameter(Mandatory = $false)]
    [string] $MachineVersion,

    [Parameter(Mandatory = $false)]
    [switch] $Suppressed,

    [Parameter(Mandatory = $false)]
    [string] $Team,

    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [bool] $Urgent
)

# Add the Service Health snap-in.
Add-PSSnapin Microsoft.Exchange.Monitoring.ServiceHealth -ErrorAction SilentlyContinue

# Build the command line.
[string] $command = "New-EscalationOverride"

if ($Id -ne $null) { $command += " -Id '$Id'" }

# Reason won't get passed for right now.
# After SCM starts passing Reason, should be --->  if (-not [String]::IsNullOrEmpty($Reason)) { $command += " -Reason '$Reason'" }
if (-not [String]::IsNullOrEmpty($Reason))
{
    $command += " -Reason '$Reason'"
}
else
{
    $command += " -Reason 'Get reason from change request'"
}

if (-not [String]::IsNullOrEmpty($Expiration)) { $command += " -Expiration '$Expiration'" }

if (-not [String]::IsNullOrEmpty($Machine)) { $command += " -Machine '$Machine'" }

if (-not [String]::IsNullOrEmpty($Monitor)) { $command += " -Monitor '$Monitor'" }

if (-not [String]::IsNullOrEmpty($Site)) { $command += " -Site '$Site'" }

if (-not [String]::IsNullOrEmpty($Forest)) { $command += " -Forest '$Forest'" }

# Be careful here - SCM passes us a "$Version" argument that is completely different and means nothing to us.
if (-not [String]::IsNullOrEmpty($MachineVersion)) { $command += " -Version '$MachineVersion'" }

if ($Suppressed -ne $false) { $command += " -Suppressed" }

if (-not [String]::IsNullOrEmpty($Team)) { $command += " -Team '$Team'" }

if ($PSBoundParameters.ContainsKey("Urgent"))
{
    if ($Urgent -ne $false)
    {
        $command += ' -Urgent:$true'
    }
    else
    {
        $command += ' -Urgent:$false'
    }
}

# For now, just write the command to the operation trace instead of executing it.
# Should be --->      & $command
Write-Host $command


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNgXUxaaQYoJgyzRhvsiA/rE8
# 1FOgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFN5TvxhKKjpeOtWk
# f1nNdIXwiujYMA0GCSqGSIb3DQEBAQUABIIBACw6eY1M41Yf8d83im6a0aEN/QCV
# 7rgVIIhvRfQ/MeN+uZrKb47eNUAzV5rT9tfCkdcD++SnhIAXwvgOuQ1cBA/c9BNU
# orFr1+4yKYZbJaVTrNng0a5hR6wdjK4jHqh/kMqgfZm5EU99jxHJBj575ISo40zW
# gIwgkytrwIy/4ACydw53a0FkeccNM1zyDgW1i4OVv2h4gGyGW6txA3e6AemsQ18F
# kh+Y2rig/dmp435bSuEfT8n9bT4vKy4qJHpT4HbCcb2keGrJIYn/laHZSXSDmkcp
# Co2xs5pQAHdLSav4Kfv6mM3v2zIJPl/44vO7NG9hiEIP/MkedStZ7SbUq0I=
# SIG # End signature block
