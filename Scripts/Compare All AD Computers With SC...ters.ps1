## ==================================================================================
## Title       : Find All Domain Computers Not In SCCM
## Description : Finds all computers in a domain AD that have an entry in the DNS, but
##				 are not found in SCCM.  
##				 Allows selection of the correct domain in a  multi-domain environment.
##				 
## Author      : C.Perry
## Date        : 21/2/2012
## Input       : 	
## Output      : A text file of server names not found in SCCM.
##				 Found server names with IP addressare written to the console along with error messages
## Usage	   : PS> .\CompareAllComputersInADwithSCCM.ps1
## Notes	   : Not tested with multi-site SCCM instances
## Tag		   : .NET Framework, AD, DNS, SQL Query
## Change log  :
## ==================================================================================
cls 
Function Select-Item 
{	<# 
    .Synopsis        Allows the user to select simple items, returns a number to indicate the selected item. 
    .Description 
        Produces a list on the screen with a caption followed by a message, the options are then
		displayed one after the other, and the user can one. 
        Note that help text is not supported in this version. 
    .Example 
        PS> select-item -Caption "Configuring RemoteDesktop" -Message "Do you want to: " -choice "&Disable Remote Desktop",           "&Enable Remote Desktop","&Cancel"  -default 1       Will display the following 
          Configuring RemoteDesktop           Do you want to:           [D] Disable Remote Desktop  [E] Enable Remote Desktop  [C] Cancel  [?] Help (default is "E"): 
    .Parameter Choicelist 
        An array of strings, each one is possible choice. The hot key in each choice must be prefixed with an & sign 
    .Parameter Default 
        The zero based item in the array which will be the default choice if the user hits enter. 
    .Parameter Caption 
        The First line of text displayed 
    .Parameter Message 
        The Second line of text displayed     #> 
	Param( [String[]]$choiceList, 
		[String]$Caption, 
		[String]$Message, 
		[int]$default = 0 
	) 
	$choicedesc = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription] 
	$choiceList | foreach { $choicedesc.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $_))} 
	$Host.ui.PromptForChoice($caption, $message, $choicedesc, $default) 
} 
cls
#Get Domain info
$domain = select-item -Caption "Domain Selection" -Message "Please select a domain: " `
-choice "&1 Application Domain", "&2 Construction Domain", "&3 Development Domain", "&4 Production Domain", "&5 Porting Domain", "&6 Pre-Production Domain", "&7 Cancel" -default 6
switch ($domain) 
{
	0 {$domain = "application.domain";$ServerInstance = "appserver";$Database = "SMS_APP"} 
	1 {$domain = "construction.domain";$ServerInstance = "constructserver";$Database = "SMS_CON"}
	2 {$domain = "development.domain";$ServerInstance = "devserver";$Database = "SMS_DEV"} 
	3 {$domain = "production.domain";$ServerInstance = "prodserver";$Database = "SMS_PRD"} 
	4 {$domain = "porting.domain";$ServerInstance = "portserver";$Database = "SMS_POR"} 
	5 {$domain = "preproduction.domain";$ServerInstance = "preprodserver";$Database = "SMS_PPD"} 
	6 {$domain = "Cancel"} 
	default {$domain = "Cancel"}
}

If ($domain -eq "Cancel")
{
	echo "Cancel selected"
	exit
}

#get all computer objects in selected SCCM 

$ConnectionTimeout = 30
# SQL Query to return the names of all computer objects in the respective SCCM system
$Query = "select Name0 from v_R_System order by Name0"
$QueryTimeout = 120

$conn = new-object System.Data.SqlClient.SQLConnection
$ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout
$conn.ConnectionString = $ConnectionString
$conn.Open()
$cmd = new-object system.Data.SqlClient.SqlCommand($Query,$conn)
$cmd.CommandTimeout=$QueryTimeout
$ds = New-Object system.Data.DataSet
$da = New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
[void]$da.fill($ds)
$conn.Close()
#create the domain context object
$context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$domain)
#get the domain object
$dom = [system.directoryservices.activedirectory.domain]::GetDomain($context)
#$dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 

$outfile = "C:\TEMP\" + $domain + ".ADComputers_NotIn_SCCM.txt" 
$Header = "Computer objects from the " + $domain + " AD not in SCCM" 
$Header | Out-File $outfile
#$dom # Debug line
#go to the root of the Domain
$root = $dom.GetDirectoryEntry()
#$root = [ADSI]''
#create the AD Directory Searcher object
$searcher = new-object System.DirectoryServices.DirectorySearcher($root)
#get all computer objects that have an operating system listed
$filter = "(&(objectClass=Computer)(operatingSystem=*))"
$searcher.filter = $filter
$searcher.pageSize=1000
$colProplist = "name"
foreach ($j in $colPropList){$searcher.PropertiesToLoad.Add($j)}
#get all matching computers
$colResults = $searcher.FindAll()
#interate through results
foreach ($objResult in $colResults)
{	$objItem = $objResult.Properties
	[string]$nm = $objItem.name
	#query DNS using the hostname to get the IP Address
	Try
	{
		$ip = ([System.Net.Dns]::GetHostaddresses($nm.split('.')[0]))[0].ipaddresstostring
		$op = $nm + ", " + $ip 
		$Item = $ds.Tables[0].rows | where-Object {$_.Name0 -eq $nm}
		If ($Item)
		{			#If found
			echo $op
		}#endIf found
		Else
		{			#If not  found
			$Wha = $nm + ", - Computer not found in SCCM " + $_.Exception.Message
			$nm | Out-File $outfile -Append
			write-host -backgroundcolor Red -foregroundcolor Black $Wha 
		}#endIf not found
	}
	Catch
	{
		$exceptionType = $_.Exception.GetType()
		if ($exceptionType -match 'System.Management.Automation.MethodInvocation')
		{			#IfExc
			#Attempt to access an non existant computer
			$Wha = $nm + ", - Computer not found in DNS " + $_.Exception.Message
			write-host -backgroundcolor Yellow -foregroundcolor Black $Wha 
		}#endIfExc
		Else 
		{
			$Wha = $nm + " " + $_.Exception.Message
			write-host -backgroundcolor DarkCyan -foregroundcolor White $Wha 
		}
	}

}
#number of matching computers
$objResult.count
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6oe5v/nOxx2MtEo4NpdyDqVT
# DNKgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDWAv7kx4JoDDkNg
# Lmn35MhOy8wIMA0GCSqGSIb3DQEBAQUABIIBAGsJvEcMOjnWnXXFOgTn+dIbo7LG
# XYdBePsZvVCn+HFgo0KdwaLroO3rjDryGc082W1uj7au45zx0vfl6bDiSrNYU8mo
# JK/5Z7TGUh0mPa/09aO6X8lsEaxlwvV8eluI/3bwVn7uzaicf0txgTH2jm/Gf6cA
# nOxz8EsK93dT2JGZrWXZ9UqFwnCkkNNzWxzeFnSTaCMVqt8GqLVMQ1nzhB0kLnqD
# lMt1rBO98w+SPX9oovD+lxOLDR6uhHxnjKh9By32qxSWELOieyHABKfj7dg48jDk
# ufy1LkUalCUFmlkwvxpXYi2NJXy57oV7LU+NIX7zjxSecHyp3fEE9RGnxJs=
# SIG # End signature block
