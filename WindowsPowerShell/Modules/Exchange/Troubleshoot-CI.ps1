# Copyright (c) 2009 Microsoft Corporation. All rights reserved.
#
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

# Requires -Version 2

<#
   .SYNOPSIS 
   Performs troubleshooting on Content Index (CI) catalogs. 

   .DESCRIPTION
   The Troubleshoot-CI.ps1 script detects problems with content index
   catalogs and optionally attempts resolutions to the problems.

   .PARAMETER Server
   The simple NETBIOS name of mailbox server on which troubleshooting
   should be atempted for CI catalogs. If this optional parameter is
   not specified, local server is assumed. 

   .PARAMETER Database
   The name of database to troubleshoot. If this optional parameter is
   not specified, catalogs for all databases on the server specified
   by the Server parameter are troubleshooted.
   
   .PARAMETER Symptom
   Specifies the symptom to detect. Possible values are:
   'Deadlock', 'Corruption', 'Stall', 'Backlog' and 'All'.
   When 'All' is specified, all the first four symptoms in
   the list are checked.
   
   If this optional parameter is not specified, 'All' is assumed.
   
    .PARAMETER Action
   Specifies the action to be performed to resolve a symptom. The
   possible values are 'Detect', 'DetectAndResolve', 'Resolve'.
   The default value is 'Detect'
     
    .PARAMETER MonitoringContext
   Specifies if the command is being run in a monitoring context.
   The possible values are $true and $false. Default is $false.
   If the value is $true, warning/failure events are logged to the
   application event log. Otherwise, they are not logged.
   
   .PARAMETER FailureCountBeforeAlert
   Specifies the number of failures the troubleshooter will allow
   before raising an Error in the event log, leading to a SCOM alert.
   The allowed range for this parameter is [1,100], both inclusive.
   No alerts are rasised if MonitoringContext is $false.
   
   .PARAMETER FailureTimeSpanMinutes
   Specifies the number of minutes in the time span during which
   the troubleshooter will check the history of failures to count
   the failures and alert. If the failure count during this time
   span exceeds the value for FailureCountBeforeAlert, an alert
   is raised. No alerts are rasised if MonitoringContext is $false.
   The default value for this parameter is 600, which is equivalent
   to 10 hours.

   .INPUTS
   None. You cannot pipe objects to Troubleshoot-CI.ps1.

   .OUTPUTS
   Returns status information about each catalog, problems detected
   and resolution actions performed, if any

   .EXAMPLE
   C:\PS> .\Troubleshoot-CI.ps1 –database DB01
   Detects and reports if there’s any problem with catalog for 
   database DB01. Does not attempt any Resolution. 

   .EXAMPLE
   C:\PS> .\Troubleshoot-CI.ps1 –database DB01 –symptom IndexingStall	
   Detects if indexing on catalog for database DB01 is stalled. Does not attempt any Resolution.
   
   .EXAMPLE
   C:\PS> .\Troubleshoot-CI.ps1 –Server <S001>	
   Detects and reports problems with all catalogs on server S001, if any. Does not attempt any Resolution.
   
   .EXAMPLE
   C:\PS> .\Troubleshoot-CI.ps1 –database DB01 –Action DetectAndResolve	
   Detects and reports if there’s any problem with catalog for database DB01. 
   Attempts a Resolution of the problem.
   
   .EXAMPLE
   C:\PS> .\Troubleshoot-CI.ps1 –database DB01 –Symptom Corruption –Action Resolve	
   Attempts a Resolution action for catalog corruption for database DB01. 
#>

[CmdletBinding()]
PARAM(
    [parameter( 
        Mandatory=$false, 
# $Research$ For some reason, we can not do import-localizeddata before PARAM.
# So, we can not use localized strings in this help message. This help message
# is used only in prompting for mandatory parameters, so, this is not a big 
# issue for now.
        HelpMessage = "The server to troubleshoot." 
       )] 
      [String] 
      [ValidateNotNullOrEmpty()] 
      $Server,
      
    [parameter(
        Mandatory=$false, 
        HelpMessage = "The database of catalog to troubleshoot." 
       )
      ] 
      [ValidateNotNullOrEmpty()] 
      [String] 
      $Database,
      
    [parameter(
        Mandatory=$false, 
        HelpMessage = "The symptom to detect and/or recover from." 
       )
      ] 
      [String] 
      [ValidateSet("Deadlock", "Corruption", "Stall", "All")] 
      $Symptom = "All",
      
    [parameter(
        Mandatory=$false, 
        HelpMessage = "The action to perform for each symptom." 
       )
      ] 
      [String] 
      [ValidateSet("Detect", "DetectAndResolve", "Resolve")] 
      $Action = "Detect",

    [parameter(
        Mandatory=$false, 
        HelpMessage = "Indicates if command is being run in a monitoring context. This flag is used to determine if we need to log warnings/failures to the application event log." 
       )
      ] 
      [Switch] 
      $MonitoringContext = $false,
      
    [parameter(
        Mandatory=$false, 
        HelpMessage = "Number of failures allowed before raising an error in the event log, leading to a SCOM alert, if applicable." 
       )
      ] 
      [Int32]
      [ValidateRange(1,100)]
      $FailureCountBeforeAlert = 3,
      
    [parameter(
        Mandatory=$false, 
        HelpMessage = "The number of minutes back in time during which we will check the history of failures to count total failures. This is related to the argument 'FailureCountBeforeAlert'." 
       )
      ] 
      [Int32]
      # between 10 minutes and 7 days
      [ValidateRange(10, 10080)]
      # default is 10 hours
      $FailureTimeSpanMinutes = 600
 )

$scriptDir = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)

. $scriptDir\CITSLibrary.ps1

# PS 303295
. $scriptDir\DiagnosticScriptCommonLibrary.ps1

try
{
    if ($Verbose)
    {
        $VerbosePreference = "Continue"
    }

    # Load Exchange Snapin. This is needed when
    # we want to run troubleshooter from a raw
    # powershell session or as a scheduled task.
    # Note: This function will only load it
    # if the snapin is not already loaded.
    #
    Load-ExchangeSnapin    
        
    write-verbose `
        ("Server=" + $Server + `
         " Database=" + $Database + `
         " Symptom=" + $Symptom + `
         " Action=" + $Action + `
         " MonitoringContext=" + $MonitoringContext + `
         " FailureCountBeforeAlert=" + $FailureCountBeforeAlert + `
         " FailureTimeSpanMinutes=" + $FailureTimeSpanMinutes)
         
    # Validate arguments
    #
    if ($MonitoringContext)
    {
        $Arguments = Validate-Arguments `
            -Server $Server `
            -Database $Database `
            -Symptom $Symptom `
            -Action $Action `
            -MonitoringContext `
            -FailureCountBeforeAlert $FailureCountBeforeAlert `
            -FailureTimeSpanMinutes $FailureTimeSpanMinutes
    }
    else
    {
        $Arguments = Validate-Arguments `
            -Server $Server `
            -Database $Database `
            -Symptom $Symptom `
            -Action $Action `
            -FailureCountBeforeAlert $FailureCountBeforeAlert `
            -FailureTimeSpanMinutes $FailureTimeSpanMinutes
    }
    
    
    # Log 'Troubleshooter Started' event
    #
    Log-Event -Arguments $Arguments -EventInfo $LogEntries.TSStarted
       
    if ($Arguments.Action -ieq "Resolve")
    {
        # build server status object to reflect
        # the given sysmptom
        #
        $serverStatus = Build-ServerStatus `
            -Server $Arguments.Server `
            -Database $Arguments.Database `
            -Symptom $Symptom
    }
    else
    {
        # Detect any problems of all catalogs 
        # on the specified server
        #
        $serverStatus = Detect-Problems $Arguments.Server $Arguments.Database
        
        # output the detection status
        #
        $serverStatus
        
        # Log the detection results. This will turn
        # on/off specific alerts based on the issues.
        #
        Log-DetectionResults $Arguments $ServerStatus
    }
        
    # If Action=='DetectAndResolve' proceed to resolution
    # of all symptoms detected.
    #
    if (($Arguments.Action -ieq "DetectAndResolve") -or
        ($Arguments.Action -ieq "Resolve"))
    {
        Resolve-Problems $Arguments $serverStatus
    }
    
    # If we are here, log that we 
    # have successfully finished troubleshooting
    #
    Log-Event -Arguments $Arguments -EventInfo $LogEntries.TSSuccess
    if ($MonitoringContext)
    {
	#PS 303295 - add a monitoring event to supress SCOM failure alerts.
	#
    	Add-MonitoringEvent -Id $LogEntries.TSSuccess[0] -Type $EVENT_TYPE_INFORMATION -Message $LocStrings.TSStarted
    }
}
catch [System.Exception]
{
    $message = ($LocStrings.TroubleshooterFailed + $error[0].Exception.ToString() + $error[0].InvocationInfo.PositionMessage)
    write-host $message
    Log-Event `
        -Arguments $Arguments `
        -EventInfo $LogEntries.TSFailed `
        -Parameters @($message)
        
    if ($MonitoringContext)
    {
        #PS 303295 - add a monitoring event to supress SCOM failure alerts.
        #
        Add-MonitoringEvent -Id $LogEntries.TsFailed[0] -Type $EVENT_TYPE_ERROR -Message $message
    }        
}

if ($MonitoringContext)
{
    # PS 303295 Output monitoring events.
    #
    Write-MonitoringEvents
}
      

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+k15WALkaPP7IxJEVXQ8J72E
# O/CgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMaSdu86w3aH+sT6
# OUST86CEDKNNMA0GCSqGSIb3DQEBAQUABIIBABv4SI3yjj5nC2x3epQnXiKnoZVb
# hgTTkIcycZ36OkSP9YWpFL0Fov8LLEJa5NZkYqwC/R+Mq3pwyeyvwyU0fStVkUFb
# VCuI7t99o70yTVBgY7hK2RsJFPlEKwHkkJfJMbFjHJfpU8ItRExxgGygwNb24CkY
# deloxwQQfTkMOrlH4mmCj1gaUVGxGL1rE9IhI/oFsloPOnLavxal8TXMd5Em/wcG
# hCs15szmvHRI49pMpyH3iHEp87e5ZTBmJSIMQvSFmwXH8z4f+gN6OzYcPoRFKSx4
# 4x8NVBnfxIV57TUPKul3c1QprZMgY+5rPAOT6+fr5QF4IlcEFUEYJ6SzavI=
# SIG # End signature block
