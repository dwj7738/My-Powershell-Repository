param([string]$sitenameinput="http://localhost/sites/fast/", [string]$configfileinput,[switch]$outputconfig)

Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 

# filename: Set-WebPartProperties.ps1


# TODO: read xml/xsl from cdata section
# TODO: implement debug output
# TODO: implement <webpart name="Refinement Panel" showallproperties="True"/>
# TODO: fix the publish

<# Description:
This script allows you to set any available webpart property. You specify the property name and property value in the config xml file and the 
script iterates through all your properties. 


$web = Get-SPWeb $urlWeb  
$webpartmanager=$web.GetLimitedWebPartManager($urlWebWP,  [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)  
[System.Reflection.Assembly]::Load("rossri.NavigationControl, Version=1.0.0.0, Culture=neutral, PublicKeyToken=a60d1a662835ad70") 
$webpart = New-Object rossri.NavigationControl.UserListViewPart.UserListViewPart 
$webpart.Title = "NewPart from Powershell" 
$webpartmanager.AddWebPart($webpart, "Left", "0") 

#>

<# Usage steps
1) Modiy the file SPDeploymentConfig.xml and insert xml of the following format

2) For testing you can create a file called XSLPassthrough.xsl this will return the xml directly to the browser. Here are the contents of that file:

3) Configure the properties you need to set on each web part
4) run the script
5) Verify the results on your SharePoint site

#>

<#
 filename:Write-HelloWorld.ps1
#>

$configurationname = $myinvocation.mycommand.name.Substring(0, $myinvocation.mycommand.name.IndexOf('.'))
$debug = $false
$runmode = "install"  
$online = $true

Function devmodeSetup()
{
"Writing file $configurationname.xml"
$selfdocumentingxml = @" 
<Configuration>
  <executionSection>
    <execute configurationName="$configurationname" />
  </executionSection>
  <configurationSection>
    <configuration name="$configurationname" filePath="$configurationname.ps1">
      <webpartconfig>
        <pages>
			<page name="results.aspx" pageUrlRel="Pages/Results.aspx" >
			<!-- XML file to configure the refiners on the Refinement panel -->
    
			<!-- How many times have you forgotten to set this? :) Use this setting to check/uncheck the use the default config checkbox -->
			<webpart name="Refinement Panel" >
				<modifyProperty name="UseDefaultConfiguration">True</modifyProperty>
				<modifyProperty name="InitialAsyncDataFetch">False</modifyProperty>
				<modifyProperty name="Xsl">
				<![CDATA[<?xml version="1.0" encoding="UTF-8"?>
	<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/">
	<xmp><xsl:copy-of select="*"/></xmp>
	</xsl:template>
	</xsl:stylesheet>]]>
				</modifyProperty>
			</webpart>
			<webpart name="Search Core Results">
				<!--<modifyProperty name="Xsl">XSLPassthrough.xsl</modifyProperty>-->
				<modifyProperty name="Xsl"></modifyProperty>
				<!--<modifyProperty name="AppendedQuery">sitename:file://gr06/xmlcontent2</modifyProperty>-->
			</webpart>
			</page>
        </pages>
       </webpartconfig>
    </configuration>
  </configurationSection>
</Configuration>

"@ | Out-File "$configurationname.xml"


$XSLPassthrough = @" 
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:template match="/">
    <xmp><xsl:copy-of select="*"/></xmp>
    </xsl:template>
</xsl:stylesheet>
"@ | Out-File "$XSLPassthrough.xml"

}

Function mainwork([string]$configfile,[string]$sitename)
{
	$xmldata = [xml](Get-Content $configfile)
    
    $file = Get-ChildItem $configfile
    $configDir = $file.DirectoryName

	#$sites = $xmldata.SelectNodes("Configuration/configurationSection/configuration[@name='$configurationname']/webpartconfig/sites/site")
	#foreach ($site in $sites)
	#{
		#$siteName = "http://gr03-fs4sprtm/fast/";
		#http://gr03-fs4sprtm/fast/Pages/default.aspx
		#$pageUrlRel = "Pages/Results.aspx";

			
		$pages = $xmldata.SelectNodes("Configuration/configurationSection/configuration[@name='$configurationname']/webpartconfig/pages/page")
        
		foreach ($page in $pages)
		{
		    $pageName = $page.getAttribute("name")
			$pageUrlRel = $page.getAttribute("pageUrlRel")			
		    $pageUrl = $siteName + $pageUrlRel;
			$webparts = $xmldata.SelectNodes("Configuration/configurationSection/configuration[@name='$configurationname']/webpartconfig/pages/page[@name='$pageName']/webpart")
            # if there are no webparts on this page then continue to the next page
            $firstitem = $webparts.get_ItemOf(0)
            if($firstitem -eq $null)
            {
               continue
            }
            
			#
			# Find the page and check out
			#            
            if ($online)
            {
              # Get a SPWeb object: http://msdn.microsoft.com/en-us/library/ms473942(v=office.12).aspx
              $pubweb = get-spweb "$siteName" -erroraction SilentlyContinue
               if($pubweb -eq $null)
			  {
			     "There was an error getting the spweb at:$siteName"
				 exit
			  }
              # Get a SPFile object: http://msdn.microsoft.com/en-us/library/ms461145(v=office.12).aspx
              $resultPage = $pubweb.GetFile($pageUrl)
			  if($resultPage -eq $null)
			  {
			     "There was an error getting the resultPage at:$pageUrl"
				 exit
			  }
              "Checkout page:" + $pageName
			  $resultPage.CheckOut();
            }
            


            # <webpart name="Refinement Panel" >
            #   <modifyProperty name="UseDefaultConfiguration">True</modifyProperty>
            #   <modifyProperty name="InitialAsyncDataFetch">False</modifyProperty>
            #   <modifyProperty name="Xsl"></modifyProperty>
            # </webpart>
			foreach ($webpart in $webparts)
			{
                #$webpart
				$webpartName = $webpart.getAttribute("name")
                # loop through each property of the web part
                foreach ( $property in $webpart.modifyProperty )
                {
                    $propertyName = $property.name
                    $propertyValue = $property.get_InnerText()
                    # if the propertyValue is a file name then read in the contents of the file into the variable
                    
                    if($debug){    "propertyValue = Get-Content $configDir\$propertyValue"}
                    if (($propertyValue.length -gt 0) -and ($propertyValue.length -lt 150) -and (test-path "$configDir\$propertyValue"))
                    {
                        $propertyValue = Get-Content "$configDir\$propertyValue"
                        if($debug){"read $propertyName value from a file: $propertyValue"}
                    }
                    else
                    {
                       if($debug){"Using literal value for property $propertyName value: $propertyValue"}
                    
                    }
                    if ( $debug )
                    {
                      "pagename = <$pageName> webpartName = <$webpartName> propertyName = <$propertyName> propertyValue = <$propertyValue> "
                    }
    				
    				$comment = "Auto setup of webpart properties";
    				
                    if ( $online )
                    {
        				#
        				# Find the webpart and change the XSL
        				#
                        $webpartmanager=$pubweb.GetLimitedWebPartManager("$pageUrl", [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
                        
        				foreach ($webpart in $webpartmanager.WebParts)
        				{
        					$effectiveTitle = $webpart.EffectiveTitle

        					if ($webpart.EffectiveTitle -eq $webpartName)
        					{
                                #$webpart
                                # To find out all the possible parameters, type $webpart at the command line and list them out.

        						Write-Output "  Setting $webpartName - $propertyName";
        						if($debug){Write-Output "Setting $webpartName . $propertyName to $propertyValue ";}
                                $oldvalue = $webpart.$propertyName
                                if($oldvalue -is [bool])
                                {
                                    if($propertyvalue -eq "True")
                                    {
                                        $webpart.$propertyName = $true;
                                    }
                                    elseif($propertyvalue -eq "False")   
                                    {
                                        $webpart.$propertyName = $false;                            
                                    }
                                    else
                                    {
                                        $intpropertyvalue = [int]$propertyvalue
                                        $boolvalue = [bool]$intpropertyvalue;                        
                                        $webpart.$propertyName = $boolvalue;             
                                    }
                                }
                                else
                                { 
								    #$webpart
            						$webpart.$propertyName = $propertyValue;
                                    #"Setting: "+$propertyName +"="+ $propertyValue;
                                }
                                #"Saving webpart $webpartName changes"
        						$webpartmanager.SaveChanges($webpart);
        					}
        				}
                    } # end online check
                } 
			} # end foreach of webparts
			
			if ( $online )
            {
                #
    			# Check in and Publish
    			#
                "Checkin page:" + $pageName + " with comment: " + $comment
    			$resultPage.CheckIn($comment);
                
                # the publish method seems to break the site. There must be another way to do this. It may be fixed in a more recent build. This was tested on sp build 4730 and fs4sp 4759
    			#$resultPage.Publish($comment);
    			$pubweb.Close();
            }
        } # end foreach check
    #}
}

Function displayhelp()
{
  "Usage: [xml configuration file] [install|uninstall|reinstall] [devmode] [debugon] [outputconfig] [help|-h|/h]"
  "       The xml config file is required as the first parameter. Order does not matter for other parameters. default run mode is install. "
  "       Use devmode to run from the sample xml files in this file"
  exit
}

function main()
{
  if($outputconfig)
  {
    devmodeSetup
  }
  
  if($configfileinput)
  {  
    mainwork $configfileinput $sitenameinput
  }
}

<#$a = $args.length
if ($a -eq 0) {  displayhelp }
else 
{ 
  $configfile = $args[0] 
}

foreach ($arg in $args)
{
  if ($arg -eq "/h" -or $arg -eq "-h" -or $arg -eq "help") {    displayhelp  }
  if ($arg -eq "outputconfig"){ devmodeSetup; exit         }
  if ($arg -eq "devmode")     { $configfile = "$configurationname.xml"; devmodeSetup  }
  if ($arg -eq "debugon")     { $debug      = $true        }
  if ($arg -eq "offline")     { $online     = $false       }
  if ($arg -eq "install")     { $runmode    = "install"    }
  if ($arg -eq "uninstall")   { $runmode    = "uninstall"  }
  if ($arg -eq "reinstall")   { $runmode    = "reinstall"  }  
}

#>

main


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUiImnFRb62TQNpeAidEL/o7ep
# cyGgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFO1p9eJrwZBnUf7S
# /witLh7XrQ/SMA0GCSqGSIb3DQEBAQUABIIBAEknEIgryOUnLFmjqiaz5aSajBgu
# 9Mgc3VAzcrotg9Zm9xfVrR2DGWA/0BSTTD3WEEigFr8Dur2mZGfc2X+i06Rbv3Eh
# uXXLAxT0SD+qQdoqeKclJHkA07r+zWk4hdbvqM6+gUv0GGXgBfBZ9qO84T60Vc+J
# f0L3MSVpjWVS05zGguvPOcfdaOpts9s0Z+eF8aH9Vbqct2y+JkP5NIeNnazXL8C/
# cJm+2/bpGvX5ux3ZR4YvebEcqGGr+zfR5x1E+svpiO4xYOQK1++9YCPw4EUiGzto
# 4dkiaiBI6jhScrQ5AdE9dsQo0WOwI0jsLAFN2ag5WFW8mhtYL8utB625OOQ=
# SIG # End signature block
