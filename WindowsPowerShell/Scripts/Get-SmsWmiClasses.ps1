<# 
    .SYNOPSIS 
        Script to scan SMS WMI Classes 
    .DESCRIPTION 
        This is a re-write of a script I came across in the Technet libraries 
        for enumerating all the classes from the various SMS namespaces to a file. 
    .PARAMETER SiteCode 
        This is your SCCM SiteCode, it is used as part of the CCM namespace. 
    .PARAMETER ComputerName 
        The name of your SCCM server, if blank defaults to localhost. 
    .PARAMETER LogFolder 
        The folder to store the output in, this folder will be created if 
        it doesn't exist. 
         
        The default is C:\WMIScan 
    .PARAMETER LogFile 
        This is the output file, and will be created. 
         
        The default is WMIScan.txt 
    .EXAMPLE 
        .\Get-SmsWmiClasses.ps1 -SiteCode 'mysite' -ComputerName 'sccm' 
         
        Description 
        ----------- 
        This example shows the default usage of this script. 
    .NOTES 
        ScriptName : Get-SmsWmiClasses 
        Created By : jspatton 
        Date Coded : 05/21/2012 13:39:01 
        ScriptName is used to register events for this script 
  
        ErrorCodes 
            100 = Success 
            101 = Error 
            102 = Warning 
            104 = Information 
    .LINK 
        https://code.google.com/p/mod-posh/wiki/Production/Get-SmsWmiClasses 
    .LINK 
        http://technet.microsoft.com/en-us/library/cc179784.aspx 
#> 
[CmdletBinding()] 
Param 
(
	$SiteCode = '', 
	$ComputerName = "(& hostname)", 
	$LogFolder = 'c:\WMIScan', 
	$LogFile = 'WMIScan.txt' 
) 
Begin 
{
	$ScriptName = $MyInvocation.MyCommand.ToString() 
	$ScriptPath = $MyInvocation.MyCommand.Path 
	$Username = $env:USERDOMAIN + "\" + $env:USERNAME 

	New-EventLog -Source $ScriptName -LogName 'Windows Powershell' -ErrorAction SilentlyContinue 

	$Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nStarted: " + (Get-Date).toString() 
	Write-EventLog -LogName 'Windows Powershell' -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message 

	#    Dotsource in the functions you need. 
	. .\includes\ComputerManagement.ps1 

	$FullPath = "$($LogFolder)\$($LogFile)" 
} 
Process 
{
	Write-Verbose 'list of SMS namespaces are put into an array.' 
	$SMSNamespaces = @("root\ccm","root\ccm\events","root\ccm\vulnerabilityassessment","root\ccm\invagt","root\ccm\softmgmtagent","root\ccm\locationservices","root\ccm\datatransferservice","root\ccm\messaging","root\ccm\policy","root\ccm\softwaremeteringagent","root\ccm\contenttransfermanager","root\ccm\scheduler","root\cimv2\sms","root\smsdm","root\sms","root\sms\inv_schema","root\sms\site_$($SiteCode)") 

	Write-Verbose "Does $($LogFolder) Folder exist?  If not, it`'s created" 
	if ((Test-Path -Path $LogFolder) -ne $true) 
	{
		New-Item $LogFolder -ItemType Directory -Force |Out-Null 
	} 
	if ((Test-Path -Path $FullPath) -ne $true) 
	{
		New-Item $FullPath -ItemType File -Force |Out-Null 
	} 

	"********************************************" |Out-File -FilePath $FullPath 
	" WMIScan Tool Executed - $(Get-date)" |Out-File -FilePath $FullPath -Append 
	"********************************************" |Out-File -FilePath $FullPath -Append 
	"--------------------------------------------" |Out-File -FilePath $FullPath -Append 

	$Computer = $ComputerName 
	if ($ComputerName -eq (& hostname)) 
	{
		$Computer = 'Local System' 
	} 

	" Scanning WMI Namespaces On $($Computer)" |Out-File -FilePath $FullPath -Append 
	"--------------------------------------------" |Out-File -FilePath $FullPath -Append 
	Write-Host "Starting WMI scan on $($ComputerName)" 
	foreach ($Namespace in $SMSNamespaces) 
	{
		" Scanning for Classes in $($NameSpace) ..." |Out-File -FilePath $FullPath -Append 
		"" |Out-File -FilePath $FullPath -Append 
		"\\$($ComputerName)\$($Namespace)" |Out-File -FilePath $FullPath -Append 
		$WbemClasses = Enum-NameSpaces -Namespace $Namespace -ComputerName $ComputerName 
		$WbemClasses |Out-File -FilePath $FullPath -Append 
	} 
} 
End 
{
	$Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString() 
	Write-EventLog -LogName 'Windows Powershell' -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message 
}</pre>
</div>
</div>
</div>
<div class="endscriptcode"> Here is the function that was created in support of this script.</div>
<div class="endscriptcode">
<div class="scriptcode">
<div class="pluginEditHolder" pluginCommand="mceScriptCode">
<div class="title"><span>PowerShell</div>
<div class="pluginLinkHolder">Edit|Remove</div>
powershell
Function Enum-NameSpaces
{
 <#
        .SYNOPSIS
            Return a collection of classes from a namespace
        .DESCRIPTION
            This function will return a collection of classes from the provided namespace.
            This method uses SWbemLocator to connect to a computer, the resulting
            SWbemServices object is used to return the SubclassesOf() the given namespace.
        .PARAMETER NameSpace
            The WMI namespace to enumerate
        .PARAMETER ComputerName
            The computer to connect to
        .EXAMPLE
            Enum-NameSpaces -Namespace 'root\ccm' -ComputerName 'sccm'

            Path            : \\SCCM\ROOT\ccm:__NAMESPACE
            RelPath         : __NAMESPACE
            Server          : SCCM
            Namespace       : ROOT\ccm
            ParentNamespace : ROOT
            DisplayName     : WINMGMTS:{authenticationLevel=pkt,impersonationLevel=impersonate}!\\SCCM\ROOT\ccm:__NAMESPACE
            Class           : __NAMESPACE
            IsClass         : True
            IsSingleton     : False
            Keys            : System.__ComObject
            Security_       : System.__ComObject
            Locale          :
            Authority       :

            Description
            -----------
            A simple example showing usage and output of the command.
        .EXAMPLE
            Enum-NameSpaces -Namespace $NameSpace -ComputerName $ComputerName |Select-Object -Property Class

            Class
            -----
            __SystemClass
            __thisNAMESPACE
            __NAMESPACE
            __Provider
            __Win32Provider
            __ProviderRegistration
            __EventProviderRegistration
            __EventConsumerProviderRegistration
            
            Description
            -----------
            This example shows piping the output of the Enum-Namespaces function to Select-Object to return 
            one of the properties of a class.
        .NOTES
            FunctionName : Enum-NameSpaces
            Created by   : jspatton
            Date Coded   : 05/21/2012 12:50:50
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Enum-NameSpaces
    #>
[CmdletBinding()]
Param
(
	[parameter(Mandatory=$true,ValueFromPipeline=$true)]
	[string]$Namespace,
	[parameter(Mandatory=$true)]
	[string]$ComputerName
)
Begin
{
	Write-Verbose 'Create an SWbemLocator object to connect to the computer'
	$WbemLocator = New-Object -ComObject "WbemScripting.SWbemLocator"
	Write-Verbose "Make a connection to $($ComputerName) and access $($Namespace)"
	$WbemServices = $WbemLocator.ConnectServer($ComputerName, $Namespace)
	Write-Verbose "Use the SubClassesOf() method of the SWbemServices object to return an SWbemObjectSet"
	$WbemObjectSet = $WbemServices.SubclassesOf()
}
Process
{
}
End
{
	Write-Verbose 'Return the Path_ property of the ObjectSet as this seems to contain useful information'
	Return $WbemObjectSet |Select-Object -Property Path_ -ExpandProperty Path_
}
}</pre>
<div class="preview">
Function Enum-NameSpaces 
{
	<# 
        .SYNOPSIS 
            Return a collection of classes from a namespace 
        .DESCRIPTION 
            This function will return a collection of classes from the provided namespace. 
            This method uses SWbemLocator to connect to a computer, the resulting 
            SWbemServices object is used to return the SubclassesOf() the given namespace. 
        .PARAMETER NameSpace 
            The WMI namespace to enumerate 
        .PARAMETER ComputerName 
            The computer to connect to 
        .EXAMPLE 
            Enum-NameSpaces -Namespace 'root\ccm' -ComputerName 'sccm' 
 
            Path            : \\SCCM\ROOT\ccm:__NAMESPACE 
            RelPath         : __NAMESPACE 
            Server          : SCCM 
            Namespace       : ROOT\ccm 
            ParentNamespace : ROOT 
            DisplayName     : WINMGMTS:{authenticationLevel=pkt,impersonationLevel=impersonate}!\\SCCM\ROOT\ccm:__NAMESPACE 
            Class           : __NAMESPACE 
            IsClass         : True 
            IsSingleton     : False 
            Keys            : System.__ComObject 
            Security_       : System.__ComObject 
            Locale          : 
            Authority       : 
 
            Description 
            ----------- 
            A simple example showing usage and output of the command. 
        .EXAMPLE 
            Enum-NameSpaces -Namespace $NameSpace -ComputerName $ComputerName |Select-Object -Property Class 
 
            Class 
            ----- 
            __SystemClass 
            __thisNAMESPACE 
            __NAMESPACE 
            __Provider 
            __Win32Provider 
            __ProviderRegistration 
            __EventProviderRegistration 
            __EventConsumerProviderRegistration 
             
            Description 
            ----------- 
            This example shows piping the output of the Enum-Namespaces function to Select-Object to return  
            one of the properties of a class. 
        .NOTES 
            FunctionName : Enum-NameSpaces 
            Created by   : jspatton 
            Date Coded   : 05/21/2012 12:50:50 
        .LINK 
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Enum-NameSpaces 
    #> 
	[CmdletBinding()] 
	Param 
	(
		[parameter(Mandatory=$true,ValueFromPipeline=$true)] 
		[string]$Namespace, 
		[parameter(Mandatory=$true)] 
		[string]$ComputerName 
	) 
	Begin 
	{
		Write-Verbose 'Create an SWbemLocator object to connect to the computer' 
		$WbemLocator = New-Object -ComObject "WbemScripting.SWbemLocator" 
		Write-Verbose "Make a connection to $($ComputerName) and access $($Namespace)" 
		$WbemServices = $WbemLocator.ConnectServer($ComputerName, $Namespace) 
		Write-Verbose "Use the SubClassesOf() method of the SWbemServices object to return an SWbemObjectSet" 
		$WbemObjectSet = $WbemServices.SubclassesOf() 
	} 
	Process 
	{
	} 
	End 
	{
		Write-Verbose 'Return the Path_ property of the ObjectSet as this seems to contain useful information' 
		Return $WbemObjectSet |Select-Object -Property Path_ -ExpandProperty Path_ 
	} 
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUEFY/Qt3icVlTm+/V7ULcE/KA
# oVGgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFL+yxkmmFLy5+dXX
# TI7Fh0ZSykNgMA0GCSqGSIb3DQEBAQUABIIBAANBL/JFhilr2K+lnU4lVE493H3r
# +1dBsot60MY1RZ98HszME0tSZ2zsR9BrHxWAs7FmnnPBWjc8d/fDeQW895j2MErY
# JBNCpLJ9mMkC/o8RJyz2pB/fGSXcGlTW7l7lD6b/cFsXZRRTYUGnKsyBkezpcJkn
# /0YY6GMaLRpELuyAtyJfRjbYNvr2FgUiikWYpdBgw8tS2AiVmNG+ieHFGzH4l0xO
# k3VF+w1nlCdcQhs6ry/swvGvPJ6wtLTydb6omgxtnEQJZbKhe7mZDnEUWLXeecjw
# igSLuPV9Z6E0uyjpAqSet/nVM+zG/MmZIb3wwr8tfXt/ee72M5+wLwwRRZA=
# SIG # End signature block
