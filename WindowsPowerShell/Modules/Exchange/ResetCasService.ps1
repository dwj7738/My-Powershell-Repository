
###########################################################################################################################################################
# <summary>
# Verifies if the full path to the log file name we want to use already exists. If it doesn't, this method returns this full path +".txt" extension.
# If the filename already exists, it appends an index to the filename and returns it.
# </summary>
# <param name="Filename">A candidate name for the log file</param>
# <returns>A full path to the file name</returns>
###########################################################################################################################################################
function GetFileName
{param([string]$Filename)

    $result = ""
	
    $fileExtension = [System.IO.Path]::GetExtension($Filename)
    
    $filenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($Filename)
    
    $directoryName = [System.IO.Path]::GetDirectoryName($Filename)
    
    $filePathWithoutExtension = [System.IO.Path]::Combine($directoryName, $filenameWithoutExtension)
    
    for($i=1;;$i+=1)
    {
        if( -not (Test-Path ($filePathWithoutExtension+"$i"+$fileExtension) ) )
        {
            $result = $filePathWithoutExtension+"$i"+$fileExtension
            break
        }
    }
    
    return $result

}
###########################################################################################################################################################

###########################################################################################################################################################
# <summary>
# Gets a string of type "string A (string B)" and returns string B.
# This method is used to get the name of the website where the virtual directory we want to reset is running
# </summary>
# <param name="VdirIdentity">The full virtual directory name, which should be of type "name (website)"</param>
# <returns>The Website name</returns>
###########################################################################################################################################################
function GetWebsiteName
{param([string]$VdirIdentity)

    [void]($VdirIdentity -match '\(.*\)')
    
    return $matches[0].Replace("(","").Replace(")","")            #removing parenthesis

}
###########################################################################################################################################################

###########################################################################################################################################################
# <summary>
# Gets a string of type "string A (string B)" and returns string A.
# This method is used to get the name of the Vdir that will be reset
# </summary>
# <param name="VdirIdentity">The full virtual directory name, which should be of type "name (website)"</param>
# <returns>The Vdir Name</returns>
###########################################################################################################################################################
function GetVdirName
{param([string]$VdirIdentity)

    [void]($VdirIdentity -match '\(.*\)')
    return $VdirIdentity.Replace($matches[0],"").Trim()

}
###########################################################################################################################################################


#Verifying the proper arguments were provided
if($args.length -lt 2 -or $args.length -gt 3)  #If the amount of arguments is lesser than 2 or greater than 3, we throw an exception, since at least the service name and the
{                                              #vdir name should be provided
    Throw (new-object system.Exception -argumentlist ('Invalid Parameters. Usage: resetcasservice [service name] [virtual directory] [backup log file](optional)'+"`n"+'Example: resetcasservice owavirtualDirectory "owa (Default Web Site)"') )  
}


$global:FormatEnumerationLimit = -1 #This will allow all properties from the VDir to be fully enumerated

###########################################################################################################################################################
#########################################################################Variables########################################################################
###########################################################################################################################################################
$LogFilenameCandidate=$env:ExchangeInstallPath #This is the variable where we store the log file name candidate
$ServiceName=$args[0]                          #This variable stores the name of the service
$LogCommandLine=""                             #commandlet used to log the settings of the vdir being recreated
$DeleteCommandLine = ""                        #commandlet used to delete the vdir
$RecreateCommandLine = ""                      #commandlet used to recreate the vdir
$logfilename = ""                              #Full path to the log file name where the vdir settings will be logged
$VdirIdentity = $args[1]                               #Virtual Directory that will be reset
$WebSiteName = GetWebSiteName($VdirIdentity)
$VdirName = GetVdirName($VdirIdentity)
$RoleFqdnOrName = [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName
###########################################################################################################################################################
   

if($args[2]) #if a third parameter is provided, use it as the log file name candidate                        
{
    $LogFilenameCandidate=$args[2]
}
else         #if the log file name is not provided, use servicename_vdirname_log as the candidate
{
    $LogFilenameCandidate=[System.IO.Path]::Combine($LogFilenameCandidate, $ServiceName+"_"+$VdirIdentity+"_"+"log.txt")
}

$fileAlreadyExists = Invoke-Expression "Test-Path `"$LogFilenameCandidate`""

if(-not $fileAlreadyExists ) #if file doesn't exist, create it
{
    
    $logfilename = $LogFilenameCandidate

}
else
{
	$logfilename = GetFileName($LogFilenameCandidate) #This will return a path to the log file name and append an index to the log file name if a log with that
    	                                              #name already exists
}

write-verbose "Creating File"
$fileCreationResult = Invoke-Expression "New-Item -ItemType file -Path `"$logfilename`" "
	
if(-not $fileCreationResult) #Creation failed. Throw Exception
{
    Throw (new-object system.Exception -argumentlist ("Invalid File Name: $LogFilenameCandidate") )   
}

$service = Invoke-Expression "Get-$ServiceName -identity `"$VdirIdentity`"" #This will return the object with the VDir properties

if(-not $service) #Coudln't retrieve VDir. Throw Exception
{
    Throw (new-object system.Exception -argumentlist ("Invalid Virtual Directory: $ServiceName $VdirIdentity") )   
}

write-verbose "Logging VDir properties"
Invoke-Expression ('$service |fl > ' + "`"$logfilename`"")

$DeleteCommandLine = "Remove-$ServiceName -identity "+'"'+"$VdirIdentity"+'"'+' -Confirm:$false'  #commandlet used to delete the vdir


if([string]::Compare($ServiceName, "owavirtualdirectory", $True) -eq 0 ) #Only OWA allows specifying the vdir name
{                                                                        #Also need to set the internal URL
    $InternalOwaUrl = "https://" + $RoleFqdnOrName + "/owa"

    $RecreateCommandLine = "New-$ServiceName -name "+'"'+"$VdirName"+'"'+"  -websitename "+'"'+"$WebSiteName"+'"'+" -DomainController "+'"'+"$RoleFqdnOrName"+'"'+" -InternalUrl "+'"'+"$InternalOwaUrl"+'"'
    
}
elseif([string]::Compare($ServiceName, "ecpvirtualdirectory", $True) -eq 0) #need to set internal URL for the ECP virtual directory
{
    $InternalECPUrl = "https://" + $RoleFqdnOrName + "/ecp"

    $RecreateCommandLine = "New-$ServiceName -websitename "+'"'+"$WebSiteName"+'"'+" -InternalUrl "+'"'+"$InternalECPUrl"+'"'
}
else
{
    $RecreateCommandLine = "New-$ServiceName -websitename "+'"'+"$WebSiteName"+'"'
}

write-verbose "ServiceName: $ServiceName"
write-verbose "VirtualDirName: $VDirName"
write-verbose "VirtualDirWebSite: $WebSiteName"
write-verbose "Log: $logfilename"

write-verbose "Deleting Virtual Directory..."
Invoke-Expression $DeleteCommandLine       #Deleting the vdir

write-verbose ""

write-verbose "Recreating Virtual Directory: $VdirIdentity"
Invoke-Expression $RecreateCommandLine     #recreating the vdir
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUh7Utv9DfbqmGQvzCVuPTqjnM
# laigggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLkkJvxigCvDJCsj
# q3jawSip5hdMMA0GCSqGSIb3DQEBAQUABIIBAIY/oVtIqWNJwEzJARjvceAMy0/o
# 1UuZ8nqKN3OXCI+Z14er9IVBp/h6/0FdTknwZzSWrhjMBzvk4ECyOHBgHA8gqYPm
# 4Vdbrp6zkagP9GZ4xuXzPnulDRWp3a2CQiMFwUK3BPXecGPDboX9GF/nIoBo/awR
# WIW1iDMHHIndPosD7lHTKP1RzJps7cNofo11Z34E2tO37couzCKKrWQY30Kh89nE
# 808p6uxVvLU6/xYbP54QRyoXuK8rFHiasjCMCRdgz2POpO2ymgZU+AmW2YtoYlCa
# +NkGGtGU2UXllg4oYa6J8fuxk/bmAiGMsWQeTXL3gL8wwt5+miIlf1euYV0=
# SIG # End signature block
