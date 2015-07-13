# Copyright (c) Microsoft Corporation. All rights reserved.
#
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

# Synopsis: Installs and enables default transport agents on Edge and Hub roles.
#
# Usage:
#
#    .\ReinstallDefaultTransportAgents.ps1
#

$forceConfirm = $true
# Exchange install path
$serverPath = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup).MSiInstallPath

# transport agent install path
$agentPath = $serverPath + "TransportRoles\agents\"

# transport agent configuration path
$agentConfigPath = $serverPath + "TransportRoles\Shared\"

# transport agent configuration file
$agentConfigFile = "agents.config"

# transport agent configuration file with full path
$agentConfigFilePath = $agentConfigPath + $agentConfigFile

# old transport agent configuration
$agentOldConfigFile = $agentConfigFile + ".old"

# old transport agent configuration file with full path
$agentOldConfigFilePath = $agentConfigPath + $agentOldConfigFile

# show warning before changing anything
$originalPreference = $WarningPreference
if ($forceConfirm)
{
    $WarningPreference = "Inquire"
}
Write-Warning ("This script will restore the default Exchange Transport Agent configuration. The current configuration will be backed up to '" + $agentOldConfigFilePath + "'.")
$WarningPreference = $originalPreference

# local server's name
$localservername = hostname

$exchangeServer = Get-ExchangeServer -Identity $localservername

# server object associated with the local server
if ($exchangeServer -eq $null)
{
    # log an error if exchange server not found
    Write-Host ("Failed to find the Exchange server: " + $localservername)
    return
}

# if server has Edge role
$isEdge = $exchangeServer.IsEdgeServer

#if server has Hub role
$isHub = $exchangeServer.IsHubTransportServer

# create the folder if it does not exist
if (!(Test-Path -PathType Container $agentConfigPath))
{
    New-Item $agentConfigPath -Type directory > $null
}

# rename the original config file if it already exists
if (Test-Path -PathType Leaf $agentConfigFilePath)
{
    if (Test-Path -PathType Leaf $agentOldConfigFilePath)
    {
        Remove-Item $agentOldConfigFilePath
    }
    Rename-Item $agentConfigFilePath $agentOldConfigFile
}

$ConnectionFilteringAgent =
    @("Connection Filtering Agent",
      "Microsoft.Exchange.Transport.Agent.ConnectionFiltering.ConnectionFilteringAgentFactory",
      "Hygiene\Microsoft.Exchange.Transport.Agent.Hygiene.dll",
      $true)
$ContentFilterAgent =
    @("Content Filter Agent",
      "Microsoft.Exchange.Transport.Agent.ContentFilter.ContentFilterAgentFactory",
      "Hygiene\Microsoft.Exchange.Transport.Agent.Hygiene.dll",
      $true)
$SenderIdAgent =
    @("Sender Id Agent",
      "Microsoft.Exchange.Transport.Agent.SenderId.SenderIdAgentFactory",
      "Hygiene\Microsoft.Exchange.Transport.Agent.Hygiene.dll",
      $true)
$SenderFilterAgent =
    @("Sender Filter Agent",
      "Microsoft.Exchange.Transport.Agent.ProtocolFilter.SenderFilterAgentFactory",
      "Hygiene\Microsoft.Exchange.Transport.Agent.Hygiene.dll",
      $true)
$RecipientFilterAgent =
    @("Recipient Filter Agent",
      "Microsoft.Exchange.Transport.Agent.ProtocolFilter.RecipientFilterAgentFactory",
      "Hygiene\Microsoft.Exchange.Transport.Agent.Hygiene.dll",
      $true)
$ProtocolAnalysisAgent =
    @("Protocol Analysis Agent",
      "Microsoft.Exchange.Transport.Agent.ProtocolAnalysis.ProtocolAnalysisAgentFactory",
      "Hygiene\Microsoft.Exchange.Transport.Agent.Hygiene.dll",
      $true)
$AddressRewritingInboundAgent =
    @("Address Rewriting Inbound Agent",
      "Microsoft.Exchange.MessagingPolicies.AddressRewrite.FactoryInbound",
      "EdgeMessagingPolicies\Microsoft.Exchange.MessagingPolicies.EdgeAgents.dll",
      $true)
$EdgeRuleAgent =
    @("Edge Rule Agent",
      "Microsoft.Exchange.MessagingPolicies.EdgeRuleAgent.EdgeRuleAgentFactory",
      "EdgeMessagingPolicies\Microsoft.Exchange.MessagingPolicies.EdgeAgents.dll",
      $true)
$AttachmentFilteringAgent =
    @("Attachment Filtering Agent",
      "Microsoft.Exchange.MessagingPolicies.AttachFilter.Factory",
      "EdgeMessagingPolicies\Microsoft.Exchange.MessagingPolicies.EdgeAgents.dll",
      $true)
$AddressRewritingOutboundAgent =
    @("Address Rewriting Outbound Agent",
      "Microsoft.Exchange.MessagingPolicies.AddressRewrite.FactoryOutbound",
      "EdgeMessagingPolicies\Microsoft.Exchange.MessagingPolicies.EdgeAgents.dll",
      $true)
$TransportRuleAgent =
    @("Transport Rule Agent",
      "Microsoft.Exchange.MessagingPolicies.TransportRuleAgent.TransportRuleAgentFactory",
      "Rule\Microsoft.Exchange.MessagingPolicies.TransportRuleAgent.dll",
      $true)
$MalwareAgent =
    @("Malware Agent",
      "Microsoft.Exchange.Transport.Agent.Malware.MalwareAgentFactory",
      "Antimalware\Microsoft.Exchange.Transport.Agent.Malware.dll",
      $true)
$UnJournalAgent =
    @("UnJournal Agent",
      "Microsoft.Exchange.MessagingPolicies.UnJournalAgent.UnwrapJournalAgentFactory",
      "Journaling\Microsoft.Exchange.MessagingPolicies.UnJournalAgent.dll",
      $true)
$JournalingAgent =
    @("Journaling Agent",
      "Microsoft.Exchange.MessagingPolicies.Journaling.JournalAgentFactory",
      "Journaling\Microsoft.Exchange.MessagingPolicies.JournalAgent.dll",
      $true)
$PrelicensingAgent =
    @("Prelicensing Agent",
      "Microsoft.Exchange.MessagingPolicies.RmSvcAgent.PrelicenseAgentFactory",
      "RmSvc\Microsoft.Exchange.MessagingPolicies.RmSvcAgent.dll",
      $true)
$InterceptorRoutingAgent =
    @("Interceptor Routing Agent",
      "Microsoft.Exchange.Transport.Agent.InterceptorRoutingAgentFactory",
      "InterceptorAgent\Microsoft.Exchange.Transport.Agent.InterceptorAgent.dll",
      $true)
$InterceptorSmtpReceiveAgent =
    @("Interceptor Smtp Receive Agent",
      "Microsoft.Exchange.Transport.Agent.InterceptorSmtpAgentFactory",
      "InterceptorAgent\Microsoft.Exchange.Transport.Agent.InterceptorAgent.dll",
      $true)

$EdgeAgents =
    @($ConnectionFilteringAgent,
      $AddressRewritingInboundAgent,
      $EdgeRuleAgent,
      $ContentFilterAgent,
      $SenderIdAgent,
      $SenderFilterAgent,
      $RecipientFilterAgent,
      $ProtocolAnalysisAgent,
      $AttachmentFilteringAgent,
      $AddressRewritingOutboundAgent)

$HubAgents =
    @($TransportRuleAgent,
      $MalwareAgent)

# generate agent list
$agents = @()
if ($isEdge)
{
    $agents += $EdgeAgents
}
if ($isHub)
{
    $agents += $HubAgents
}

# install agents
$originalPreference = $WarningPreference
$WarningPreference = "SilentlyContinue"
foreach ($agent in $agents)
{
    $name = $agent[0]
    $factory = $agent[1]
    $agentAssembly = $agentPath + $agent[2]
    $enabled = $agent[3]
    Install-TransportAgent -Name:$name -TransportAgentFactory:$factory -AssemblyPath:$agentAssembly > $null
    if ($enabled)
    {
        Enable-TransportAgent -Identity:$name
    }
}
$WarningPreference = $originalPreference

# display the current agent status
Get-TransportAgent
Write-Host ""
Write-Warning "The Transport Agents shown above have been re-installed. Please exit Powershell and restart the MS Exchange Transport service for the change to take effect."

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU50at236qoaa0B7P1qjIy+/p+
# DrygggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFBgOuTEYon71cReo
# eCZwxcX/X2PgMA0GCSqGSIb3DQEBAQUABIIBABfX5XMyPmHbynp6Et75EzQUACuw
# /1qpl+qmrHHYGUgRYSvzBrNlKipaKOk/RNCzvTZzbSLMkn2dLLgMXBmL+wINwALa
# wtr+mbBfb4Vo5qwN/8MdSXVvOjeobzhJJnu/JSnX8UIY3kvzweuGEfa5+HuxqjRM
# AWpStRiAf4wF/4T4UrYV7yJbhERcPkcXW4gWiLKJzRAPA/11ssZlojizAP1MvEwy
# nCRG51JIWcSD8MODm61lDCGRygbCqZqp2jqeWnAmYelgjYmbzUOZafaFejHfYV9/
# /EPe0bpNv4enNY0If1R+YF25vduuU0plsjBgAPN8c/jH3dCnLvM7wxhqwxU=
# SIG # End signature block
