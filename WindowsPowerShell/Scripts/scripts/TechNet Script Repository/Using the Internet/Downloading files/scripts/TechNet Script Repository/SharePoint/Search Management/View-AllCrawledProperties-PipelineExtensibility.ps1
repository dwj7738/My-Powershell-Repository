#Contributors: Brent Groom, Aaron Grant
#New-FASTSearchMetadataCrawledProperty -Name cpproperty1 -Propset e80ee0e8-71c0-4d8d-b918-360ad2fd7aa2 -VariantType 31

param([string]$inputfile, [string]$outputfile, [switch]$getFASTCrawledProperties, [switch]$deploy, [switch]$enabledebuglogging)

#TODO: implement an undeploy step
#TODO: create a copy of the pipelineextensibility.xml file before overwriting it
#TODO: Add help output to script for display on the command line

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

$thispsfile = $myinvocation.mycommand.name

#TODO: make these variables setable via command line parameters
$propertySet = "e80ee0e8-71c0-4d8d-b918-360ad2fd7aa2"
$varType = "31"
$propertyName = "cpproperty1"

$fastdir = $env:fastsearch
if($fastdir.EndsWith('\')) { $fastdir = $fastdir.substring(0,$fastdir.length-1) }
$psfile = "$fastdir\bin\View-AllCrawledProperties-PipelineExtensibility.ps1"

Function mainwork([string]$inputfile, [string]$outputfile)
{
    $locallowdir = "c:\Users\sp_admin\AppData\LocalLow\pipeline"
    $logfile = "$locallowdir\pipelineextensibility.log"
    
    $ext = Get-Date -format 'yyMMddhhmmss'  
    
    # Debug line to write output to a log file in the locallow directory
    if($enabledebuglogging){    Add-Content  $logfile "inputfile $outputfile $ext" }

    $copyofinputfile = "$locallowdir\$ext.input.xml"
    
    
    # Debug line to make a copy of the input file and place it in the locallow directory
    if($enabledebuglogging){    copy-item $inputfile $copyofinputfile }
    
    $pipelineextensibilityxmlfile = "$fastdir\etc\pipelineextensibility.xml";
    
    processDocument $inputfile $outputfile
    
}

Function processDocument([string]$infile, [string]$outfile)
{
    $xmldata = [xml](Get-Content $infile)

    $cps = $xmldata.SelectNodes("Document/CrawledProperty")
    $shortoutput = "<ul>"
    $detailedoutput = "<ul>"
        
	foreach ($cp in $cps)
	{      
      $cpvalue = $cp.get_InnerText()
      if($cpvalue.length -gt 0)
      {
        $cppropset = $cp.propertySet
        $cpname = $cp.propertyName
        $cptype = $cp.varType
        $cpid = $cp.propertyId
        if($cpname.length -gt 0) 
        { 
            $shortoutput += $("<li>" + $cpname +"=" + $cpvalue + "</li> ")
            $detailedoutput += $("<li>propertyName=" + $cpname +" propertyValue=" + $cpvalue + " propertySet=" + $cppropset + " varType=" + $cptype + "</li> " )
        }
        if($cpid.length -gt 0) 
        { 
            $shortoutput += $("<li>" + $cpid +"=" + $cpvalue + "</li> ")
            $detailedoutput += $("<li>propertyId=" + $cpid +" propertyValue=" + $cpvalue + " propertySet=" + $cppropset + " varType=" + $cptype + "</li> " )
        }
        
      }
    }
    $shortoutput += "</ul>"
    $detailedoutput += "</ul>"

    $outputxml = @" 
<Document>
  <CrawledProperty propertySet="$propertySet" varType="$varType" propertyName="$propertyName"><![CDATA[$shortoutput $detailedoutput]]></CrawledProperty>
  </Document>
"@ | Out-File "$outfile"

   $copyofoutputfile = "$locallowdir\$ext.output.xml"
   
   # debugging line to place a copy of the output file in locallow directory
   if($enabledebuglogging){ copy-item $outfile $outdestfile }
   
   # debug line to write output to a log file in the locallow directory
   if($enabledebuglogging){ Add-Content  $logfile "$ext $outdestfile $shortoutput $detailedoutput" }

}

Function get-FASTCrawledProperties()
{
    $cps = Get-FASTSearchMetadataCrawledProperty

    $outstr="<PipelineExtensibility>`n"
    $outstr+="<Run command=""viewcps.bat %(input)s %(output)s "">`n"
    $outstr+="<Input>`n"

    # List of variant types: http://msdn.microsoft.com/en-us/library/cc237865(PROT.13).aspx
    # Another low level reference: http://msdn.microsoft.com/en-us/library/aa380072(VS.85).aspx
    
    # Official list of supported variant type mappings of FAST Search Server 2010 for SharePoint http://technet.microsoft.com/en-us/library/ff191231.aspx
    $arrPropertys = "2", "3", "4", "5", "6", "7", "11", "14", "16", "17", "18", "19", "20", "21", "22", "23", "64", "8", "30", "31", "72"
    $arrInvalidPropertyIds = "-2147483646"
    foreach ($cp in $cps)
    {
            #TODO: write out all variant types
            $thename=$cp.Name
            $isnum = $thename.ToLower().equals($thename.ToUpper())
            $attrPropertyStr = "propertyName"
            if($isnum)
            {
                $attrPropertyStr = "propertyId"            
            }
            
            # these variant types a known to fail during FAST document processing. Not sure what they do in SP search
            if ( $arrPropertys -contains $cp.VariantType -AND $arrInvalidPropertyIds -notcontains $cp.Name)
            {
                $outstr+="<CrawledProperty propertySet="""+$cp.Propset + """ varType=""" + $cp.VariantType + """ " + $attrPropertyStr + "="""+$cp.Name+"""/>`n"            
            }
            else
            {
                $outstr+="<!-- Unknown Variant type -->`n <!--<CrawledProperty propertySet="""+$cp.Propset + """ varType=""" + $cp.VariantType + """ propertyName="""+$cp.Name+"""/>-->`n"            
            }
    }
    
    $outstr+="<!-- special crawled properties for pipeline extensibility -->"
    $outstr+="<CrawledProperty propertySet=""11280615-f653-448f-8ed8-2915008789f2"" varType=""31"" propertyName=""url""/>"
    #$outstr+="<CrawledProperty propertySet=""11280615-f653-448f-8ed8-2915008789f2"" varType=""31"" propertyName=""body""/>"
    #$outstr+="<CrawledProperty propertySet=""11280615-f653-448f-8ed8-2915008789f2"" varType=""31"" propertyName=""data""/>"

    $outstr+="    </Input>`n"
    $outstr+="    <Output>`n"
    $outstr+="      <CrawledProperty propertySet=""$propertySet"" varType=""$varType"" propertyName=""$propertyName""/>`n"
    $outstr+="    </Output>`n"
    $outstr+="  </Run>`n"
    $outstr+="</PipelineExtensibility>`n"

    $outstr | Out-File pipelineextensibility.xml

    $viewcpsBatFile = 'powershell "' + $psfile + ' -inputfile %1 -outputfile %2 -enabledebuglogging $true"'
    $viewcpsBatFile | Out-File "viewcps.bat" -encoding ASCII
    
}

Function install-debugPipelineExtensibility ()
{
    #TODO: create a debug crawled property / managed property mapping

    
    $mc = Get-FASTSearchMetadataCategory -Name FASTDebug
    if($mc -eq $NULL){New-FASTSearchMetadataCategory -Name FASTDebug -Propset $propertySet }
    $cp = Get-FASTSearchMetadataCrawledProperty -Name cpproperty1 
    if($cp -eq $NULL){New-FASTSearchMetadataCrawledProperty -Name cpproperty1 -Propset $propertySet -VariantType 31}
    $mp = Get-FASTSearchMetadataManagedProperty -Name mpproperty1 
    if($mp -eq $NULL)
    {
      New-FASTSearchMetadataManagedProperty -Name mpproperty1 -Type 1
      $mp = Get-FASTSearchMetadataManagedProperty -Name mpproperty1
      $cp = Get-FASTSearchMetadataCrawledProperty -name $propertyName
      New-FASTSearchMetadataCrawledPropertyMapping -ManagedProperty $mp -CrawledProperty $cp
    }
    

    $pipelineextensibilityfile = "$fastdir\etc\pipelineextensibility.xml"
    
    copy-item ".\pipelineextensibility.xml" $pipelineextensibilityfile
    copy-item "viewcps.bat" "$fastdir\bin\viewcps.bat"
    copy-item $thispsfile $psfile -force
    psctrl reset 
    #TODO: uncheck core results web part "Use Location Visualization" checkbox
    
    #TODO: update the core results web part XSL Editor section automatically and insert the following:
    #            <xsl:value-of disable-output-escaping="yes" select="mpproperty1"/>
    # after this section
    #<xsl:call-template name="DisplaySize">
    #                <xsl:with-param name="size" select="size" />
    #            </xsl:call-template>
    # update the core results web part Fetched Properties section to include <Column Name="mpproperty1"/>
                
}

if($inputfile.length -gt 0 -and $outputfile.length -gt 0) 
{
    mainwork -inputfile $inputfile -outputfile $outputfile
}

if($getFASTcrawledproperties)
{
    get-FASTCrawledProperties
}

if($deploy)
{
    install-debugPipelineExtensibility
}


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYH8qIu0aTsXmxDsWgK8wj9Oe
# d4qgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFOZIcje8yQ/RDi3r
# x0M0unCgAHTMMA0GCSqGSIb3DQEBAQUABIIBAEsLjEYtbZ7KVSXscrkI4Fph5oow
# 5Me1lIbEaA1YZQrYPLKmwx/DKozvatRPNbmknkOXlm9Ghh214X3BBtVVTs1ynoO2
# UrZCgDnNdP6Ko2W9OZmCYO2LD8VySlu+EAIhneetuTvKkAMjgT262umlGesS6G8p
# Ik8a95XuNnN/25fJ5tn28P9atet6jjrXmFLgINmhPg4KF712I2Y2wfemSae+cHb+
# D18N4mCMrEe2b5i0Af/8zAg4FFDY85oymAKUSfULvtNQjiaqCCj/vZJ+KsIk/1I5
# QcupdaFDyU9uie5uIpHvFvKAwtnrhffgV+rrgvl4xpo/7s/bM4gvs94MMcs=
# SIG # End signature block
