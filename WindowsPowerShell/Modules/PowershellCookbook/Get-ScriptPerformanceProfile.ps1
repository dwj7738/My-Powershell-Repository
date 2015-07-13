#############################################################################
##
## Get-ScriptPerformanceProfile
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Computes the performance characteristics of a script, based on the transcript
of it running at trace level 1.

.DESCRIPTION

To profile a script:

   1) Turn on script tracing in the window that will run the script:
      Set-PsDebug -trace 1
   2) Turn on the transcript for the window that will run the script:
      Start-Transcript
      (Note the filename that PowerShell provides as the logging destination.)
   3) Type in the script name, but don't actually start it.
   4) Open another PowerShell window, and navigate to the directory holding
      this script.  Type in '.\Get-ScriptPerformanceProfile <transcript>',
      replacing <transcript> with the path given in step 2.  Don't
      press <Enter> yet.
   5) Switch to the profiled script window, and start the script.
      Switch to the window containing this script, and press <Enter>
   6) Wait until your profiled script exits, or has run long enough to be
      representative of its work.  To be statistically accurate, your script
      should run for at least ten seconds.
   7) Switch to the window running this script, and press a key.
   8) Switch to the window holding your profiled script, and type:
      Stop-Transcript
   9) Delete the transcript.

.NOTES

You can profile regions of code (ie: functions) rather than just lines
by placing the following call at the start of the region:
      Write-Debug "ENTER <region_name>"
and the following call and the end of the region:
      Write-Debug "EXIT"
This is implemented to account exclusively for the time spent in that
region, and does not include time spent in regions contained within the
region.  For example, if FunctionA calls FunctionB, and you've surrounded
each by region markers, the statistics for FunctionA will not include the
statistics for FunctionB.

#>

param(
    ## The path of the transcript log file
    [Parameter(Mandatory = $true)]
    $Path
)

Set-StrictMode -Version Latest

function Main
{
    ## Run the actual profiling of the script.  $uniqueLines gets
    ## the mapping of line number to actual script content.
    ## $samples gets a hashtable mapping line number to the number of times
    ## we observed the script running that line.
    $uniqueLines = @{}
    $samples = GetSamples $uniqueLines

    "Breakdown by line:"
    "----------------------------"

    ## Create a new hash table that flips the $samples hashtable --
    ## one that maps the number of times sampled to the line sampled.
    ## Also, figure out how many samples we got altogether.
    $counts = @{}
    $totalSamples = 0;
    foreach($item in $samples.Keys)
    {
        $counts[$samples[$item]] = $item
        $totalSamples += $samples[$item]
    }

    ## Go through the flipped hashtable, in descending order of number of
    ## samples.  As we do so, output the number of samples as a percentage of
    ## the total samples.  This gives us the percentage of the time our
    ## script spent executing that line.
    foreach($count in ($counts.Keys | Sort-Object -Descending))
    {
        $line = $counts[$count]
        $percentage = "{0:#0}" -f ($count * 100 / $totalSamples)
        "{0,3}%: Line {1,4} -{2}" -f $percentage,$line,
            $uniqueLines[$line]
    }

    ## Go through the transcript log to figure out which lines are part of
    ## any marked regions.  This returns a hashtable that maps region names
    ## to the lines they contain.
    ""
    "Breakdown by marked regions:"
    "----------------------------"
    $functionMembers = GenerateFunctionMembers

    ## For each region name, cycle through the lines in the region.  As we
    ## cycle through the lines, sum up the time spent on those lines and
    ## output the total.
    foreach($key in $functionMembers.Keys)
    {
        $totalTime = 0
        foreach($line in $functionMembers[$key])
        {
            $totalTime += ($samples[$line] * 100 / $totalSamples)
        }

        $percentage = "{0:#0}" -f $totalTime
        "{0,3}%: {1}" -f $percentage,$key
    }
}

## Run the actual profiling of the script.  $uniqueLines gets
## the mapping of line number to actual script content.
## Return a hashtable mapping line number to the number of times
## we observed the script running that line.
function GetSamples($uniqueLines)
{
    ## Open the log file.  We use the .Net file I/O, so that we keep
    ## monitoring just the end of the file.  Otherwise, we would make our
    ## timing inaccurate as we scan the entire length of the file every time.
    $logStream = [System.IO.File]::Open($Path, "Open", "Read", "ReadWrite")
    $logReader = New-Object System.IO.StreamReader $logStream

    $random = New-Object Random
    $samples = @{}

    $lastCounted = $null

    ## Gather statistics until the user presses a key.
    while(-not $host.UI.RawUI.KeyAvailable)
    {
        ## We sleep a slightly random amount of time.  If we sleep a constant
        ## amount of time, we run the very real risk of improperly sampling
        ## scripts that exhibit periodic behaviour.
        $sleepTime = [int] ($random.NextDouble() * 100.0)
        Start-Sleep -Milliseconds $sleepTime

        ## Get any content produced by the transcript since our last poll.
        ## From that poll, extract the last DEBUG statement (which is the last
        ## line executed.)
        $rest = $logReader.ReadToEnd()
        $lastEntryIndex = $rest.LastIndexOf("DEBUG: ")

        ## If we didn't get a new line, then the script is still working on
        ## the last line that we captured.
        if($lastEntryIndex -lt 0)
        {
            if($lastCounted) { $samples[$lastCounted] ++ }
            continue;
        }

        ## Extract the debug line.
        $lastEntryFinish = $rest.IndexOf("\n", $lastEntryIndex)
        if($lastEntryFinish -eq -1) { $lastEntryFinish = $rest.length }

        $scriptLine = $rest.Substring(
            $lastEntryIndex, ($lastEntryFinish - $lastEntryIndex)).Trim()
        if($scriptLine -match 'DEBUG:[ \t]*([0-9]*)\+(.*)')
        {
            ## Pull out the line number from the line
            $last = $matches[1]

            $lastCounted = $last
            $samples[$last] ++

            ## Pull out the actual script line that matches the line number
            $uniqueLines[$last] = $matches[2]
        }

        ## Discard anything that's buffered during this poll, and start
        ## waiting again
        $logReader.DiscardBufferedData()
    }

    ## Clean up
    $logStream.Close()
    $logReader.Close()

    $samples
}

## Go through the transcript log to figure out which lines are part of any
## marked regions.  This returns a hashtable that maps region names to
## the lines they contain.
function GenerateFunctionMembers
{
    ## Create a stack that represents the callstack.  That way, if a marked
    ## region contains another marked region, we attribute the statistics
    ## appropriately.
    $callstack = New-Object System.Collections.Stack
    $currentFunction = "Unmarked"
    $callstack.Push($currentFunction)

    $functionMembers = @{}

    ## Go through each line in the transcript file, from the beginning
    foreach($line in (Get-Content $Path))
    {
        ## Check if we're entering a monitor block
        ## If so, store that we're in that function, and push it onto
        ## the callstack.
        if($line -match 'write-debug "ENTER (.*)"')
        {
            $currentFunction = $matches[1]
            $callstack.Push($currentFunction)
        }
        ## Check if we're exiting a monitor block
        ## If so, clear the "current function" from the callstack,
        ## and store the new "current function" onto the callstack.
        elseif($line -match 'write-debug "EXIT"')
        {
            [void] $callstack.Pop()
            $currentFunction = $callstack.Peek()
        }
        ## Otherwise, this is just a line with some code.
        ## Add the line number as a member of the "current function"
        else
        {
            if($line -match 'DEBUG:[ \t]*([0-9]*)\+')
            {
                ## Create the arraylist if it's not initialized
                if(-not $functionMembers[$currentFunction])
                {
                    $functionMembers[$currentFunction] =
                        New-Object System.Collections.ArrayList
                }

                ## Add the current line to the ArrayList
                $hitLines = $functionMembers[$currentFunction]
                if(-not $hitLines.Contains($matches[1]))
                {
                    [void] $hitLines.Add($matches[1])
                }
            }
        }
    }

    $functionMembers
}

. Main

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUIWbJTS4vCjhvQ3VdzvA7HSpW
# iNGgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
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
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLdih4ddKOvCBvwc
# w8XtuNURB3FSMA0GCSqGSIb3DQEBAQUABIIBAExhtAmZRYzVKTxXjLOy6JOLB0eF
# G1ZRhCnaeKOuuB9xeypmJRDDAPkkC06wndX7v5w7OyrP2+cJ8oO060yNWUDlZwEZ
# cDBNNAmPGPXuUh2PEGF7gKtokKdNlAf0TCeUC5CyLi9+jTXYN9eLI7kf07lkRY2J
# l2uDUhyJLqlXPRHIccy9LU8zasF8ZD0/HrHmOfW8fx2VNXMWJPU0v+zzlGVqITx3
# dTuf/bGOEkKq5zLu06/TUmCbzBSRz4KD1KDbMELAE271j+w9zC8PKRCWemMwMPD9
# ob52tZw4r4QD69m1rc4D6mVP6+L9L2O8pGZ5g/SX+oogjXXSrEnwatOoTaM=
# SIG # End signature block
