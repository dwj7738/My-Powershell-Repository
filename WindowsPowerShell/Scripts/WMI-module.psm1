Function New-WMIClass {
<#
 .SYNOPSIS
 This function help to create a new WMI class.
 
 .DESCRIPTION
 The function allows to create a WMI class in the CimV2 namespace.
 Accepts a single string, or an array of strings.
 
 .PARAMETER ClassName
 Specify the name of the class that you would like to create. (Can be a single string, or a array of strings).
 
 .PARAMETER NameSpace
 Specify the namespace where class the class should be created.
 If not specified, the class will automatically be created in "Root\cimv2"
 
 .EXAMPLE
 New-WMIClass -ClassName "PowerShellDistrict"
 Creates a new class called "PowerShellDistrict"
 .EXAMPLE
 New-WMIClass -ClassName "aaaa","bbbb"
 Creates two classes called "aaaa" and "bbbb" in the Root\cimv2
 
 .NOTES
 Version: 1.0
 Author: Stephane van Gulick
 Creation date:16.07.2014
 Last modification date: 16.07.2014
 
 .LINK
 www.powershellDistrict.com
 
 .LINK
 
http://social.technet.microsoft.com/profile/st%C3%A9phane%20vg/
 
#>
[CmdletBinding()]
 Param(
 [Parameter(Mandatory=$true,valueFromPipeLine=$true)][string[]]$ClassName,
 [Parameter(Mandatory=$false)][string]$NameSpace = "root\cimv2"
  
 )
 
 
  
  
 
 foreach ($NewClass in $ClassName){
 if (!(Get-WMIClass -ClassName $NewClass -NameSpace $NameSpace)){
 write-verbose "Attempting to create class $($NewClass)"
 $WMI_Class = ""
 $WMI_Class = New-Object System.Management.ManagementClass($NameSpace, $null, $null)
 $WMI_Class.name = $NewClass
 $WMI_Class.Put() | out-null
  
 write-host "Class $($NewClass) created."
 
 }else{
 write-host "Class $($NewClass) is already present. Skiping.."
 }
 }
 
}
  
Function New-WMIProperty {
<#
 .SYNOPSIS
 This function help to create new WMI properties.
 
 .DESCRIPTION
 The function allows to create new properties and set their values into a newly created WMI Class.
 Event though it is possible, it is not recommended to create WMI properties in existing WMI classes !
 
 .PARAMETER ClassName
 Specify the name of the class where you would like to create the new properties.
 
 .PARAMETER PropertyName
 The name of the property.
 
 .PARAMETER PropertyValue
 The value of the property.
 
 .EXAMPLE
 New-WMIProperty -ClassName "PowerShellDistrict" -PropertyName "WebSite" -PropertyValue "www.PowerShellDistrict.com"
 
 .NOTES
 Version: 1.0
 Author: Stephane van Gulick
 Creation date:16.07.2014
 Last modification date: 16.07.2014
 
 .LINK
 www.powershellDistrict.com
 
 .LINK
 
http://social.technet.microsoft.com/profile/st%C3%A9phane%20vg/
 
#>
 
 
[CmdletBinding()]
 Param(
 [Parameter(Mandatory=$true)]
 [ValidateScript({
 $_ -ne ""
 })]
 [string]$ClassName,
 
 [Parameter(Mandatory=$false)]
 [string]$NameSpace="Root\cimv2",
 
 [Parameter(Mandatory=$true)][string]$PropertyName,
 [Parameter(Mandatory=$false)][string]$PropertyValue=""
 
  
 )
 begin{
 [wmiclass]$WMI_Class = Get-WmiObject -Class $ClassName -Namespace $NameSpace -list
 }
 Process{
 write-verbose "Attempting to create property $($PropertyName) with value: $($PropertyValue) in class: $($ClassName)"
 $WMI_Class.Properties.add($PropertyName,$PropertyValue)
 Write-Output "Added $($PropertyName)."
 }
 end{
 $WMI_Class.Put() | Out-Null
 [wmiclass]$WMI_Class = Get-WmiObject -Class $ClassName -list
 return $WMI_Class
 }
 
  
  
  
  
 
 
}
 
Function Set-WMIPropertyValue {
 
<#
 .SYNOPSIS
 This function set a WMI property value.
 
 .DESCRIPTION
 The function allows to set a new value in an existing WMI property.
 
 .PARAMETER ClassName
 Specify the name of the class where the property resides.
 
 .PARAMETER PropertyName
 The name of the property.
 
 .PARAMETER PropertyValue
 The value of the property.
 
 .EXAMPLE
 New-WMIProperty -ClassName "PowerShellDistrict" -PropertyName "WebSite" -PropertyValue "www.PowerShellDistrict.com"
 Sets the property "WebSite" to "www.PowerShellDistrict.com"
 .EXAMPLE
 New-WMIProperty -ClassName "PowerShellDistrict" -PropertyName "MainTopic" -PropertyValue "PowerShellDistrict"
 Sets the property "MainTopic" to "PowerShell"
 
 
 .NOTES
 Version: 1.0
 Author: Stephane van Gulick
 Creation date:16.07.2014
 Last modification date: 16.07.2014
 
 .LINK
 www.powershellDistrict.com
 
 .LINK
 
http://social.technet.microsoft.com/profile/st%C3%A9phane%20vg/
 
#>
 
 
[CmdletBinding()]
 Param(
 [Parameter(Mandatory=$true)]
 [ValidateScript({
 $_ -ne ""
 })]
 [string]$ClassName,
 
 [Parameter(Mandatory=$false)]
 [string]$NameSpace="Root\cimv2",
 
 [Parameter(Mandatory=$true)]
 [ValidateScript({
 $_ -ne ""
 })]
 [string]$PropertyName,
 
 [Parameter(Mandatory=$true)]
 [string]$PropertyValue
 
  
 )
 begin{
 write-verbose "Setting new value : $($PropertyValue) on property: $($PropertyName):"
 [wmiclass]$WMI_Class = Get-WmiObject -Class $ClassName -list
  
 
 }
 Process{
 $WMI_Class.SetPropertyValue($PropertyName,$PropertyValue)
  
 }
 End{
 $WMI_Class.Put() | Out-Null
 return Get-WmiObject -Class $ClassName -list
 }
 
 
}
 
Function Remove-WMIProperty{
<#
 .SYNOPSIS
 This function removes a WMI property.
 
 .DESCRIPTION
 The function allows to remove a specefic WMI property from a specefic WMI class.
 /!\Be aware that any wrongly deleted WMI properties could make your system unstable./!\
 
 .PARAMETER ClassName
 Specify the name of the class name.
 
 .PARAMETER PropertyName
 The name of the property.
 
 .EXAMPLE
 Remove-WMIProperty -ClassName "PowerShellDistrict" -PropertyName "MainTopic"
 Removes the WMI property "MainTopic".
 
 .NOTES
 Version: 1.0
 Author: Stephane van Gulick
 Creation date:21.07.2014
 Last modification date: 24.07.2014
 
 .LINK
 www.powershellDistrict.com
 
 .LINK
 
http://social.technet.microsoft.com/profile/st%C3%A9phane%20vg/
 
#>
 
 
[CmdletBinding()]
 Param(
 [Parameter(Mandatory=$true)][string]$ClassName,
 [Parameter(Mandatory=$true)][string]$PropertyName,
 [Parameter(Mandatory=$false)][string]$NameSpace = "Root\Cimv2",
 [Parameter(Mandatory=$false)][string]$Force
 
  
 )
 if ($PSBoundParameters['NameSpace']){
 
 [wmiclass]$WMI_Class = Get-WmiObject -Class $ClassName -Namespace $NameSpace -list
 }
 else{
 write-verbose "Gaterhing data of $($ClassName)"
 [wmiclass]$WMI_Class = Get-WmiObject -Class $ClassName -list
 }
 if (!($force)){
  
 $Answer = Read-Host "Deleting $($PropertyName) can make your system unreliable. Press 'Y' to continue"
 if ($Answer -eq"Y"){
 $WMI_Class.Properties.remove($PropertyName)
 write-ouput "Property $($propertyName) removed."
  
 }else{
 write-ouput "Uknowned answer. Class '$($PropertyName)' has not been deleted."
 }
 }#End force
 elseif ($force){
 $WMI_Class.Properties.remove($PropertyName)
 write-ouput "Property $($propertyName) removed."
 }
 
  
  
 
}
 
Function Remove-WMIClass {
 
<#
 .SYNOPSIS
 This function removes a WMI class from the WMI repository.
 /!\ Removing a wrong WMI class could make your system unreliable. Use wisely and at your own risk /!\
 
 .DESCRIPTION
 The function deletes a WMI class from the WMI repository. Use this function wiseley as this could make your system unstable if wrongly used.
 
 .PARAMETER ClassName
 Specify the name of the class that you would like to delete.
 
 .PARAMETER NameSpace
 Specify the name of the namespace where the WMI class resides (default is Root\cimv2).
 .PARAMETER Force
 Will delete the class without asking for confirmation.
 
 .EXAMPLE
 Remove-WMIClass -ClassName "PowerShellDistrict"
 This will launch an attempt to remove the WMI class PowerShellDistrict from the repository. The user will be asked for confirmation before deleting the class.
 
 .EXAMPLE
 Remove-WMIClass -ClassName "PowerShellDistrict" -force
 This will remove the WMI PowerShellDistrict class from the repository. The user will NOT be asked for confirmation before deleting the class.
 
 .NOTES
 Version: 1.0
 Author: Stephane van Gulick
 Creation date:18.07.2014
 Last modification date: 24.07.2014
 
 .LINK
 www.powershellDistrict.com
 
 .LINK
 
http://social.technet.microsoft.com/profile/st%C3%A9phane%20vg/
 
#>
 
 
[CmdletBinding()]
 Param(
 [parameter(mandatory=$true,valuefrompipeline=$true)]
 [ValidateScript({
 $_ -ne ""
 })]
 [string[]]$ClassName,
 
 [Parameter(Mandatory=$false)]
 [string]$NameSpace = "Root\CimV2",
 
 [Parameter(Mandatory=$false)]
 [Switch]$Force
)
 
  
 write-verbose "Attempting to delete classes"
 foreach ($Class in $ClassName){
 if(!($Class)){
 write-verbose "Class name is empty. Skipping..."
 }else{
 [wmiclass]$WMI_Class = Get-WmiObject -Namespace $NameSpace -Class $Class -list
 if ($WMI_Class){
  
  
 if (!($force)){
 write-host
 $Answer = Read-Host "Deleting $($Class) can make your system unreliable. Press 'Y' to continue"
 if ($Answer -eq"Y"){
 $WMI_Class.Delete()
 write-output "$($Class) deleted."
  
 }else{
 write-output "Uknowned answer. Class '$($class)' has not been deleted."
 }
 }
 elseif ($force){
 $WMI_Class.Delete()
 write-output "$($Class) deleted."
 }
 }Else{
 write-output "Class $($Class) not present"
 }#End if WMI_CLASS
 }#EndIfclass emtpy
 }#End foreach
  
  
}
 
Function Compile-MofFile{
  
 <#
 .SYNOPSIS
 This function will compile a mof file.
 
 .DESCRIPTION
 The function allows to create new WMI Namespaces, classes and properties by compiling a MOF file.
 Important: Using the Compile-MofFile cmdlet, assures that the newly created WMI classes and Namespaces also will be recreated in case of WMI rebuild.
 
 .PARAMETER MofFile
 Specify the complete path to the MOF file.
 
 .EXAMPLE
 Compile-MofFile -MofFile C:\tatoo.mof
 
 .NOTES
 Version: 1.0
 Author: Stéphane van Gulick
 Creation date:18.07.2014
 Last modification date: 18.07.2014
 History : Creation : 18.07.2014 --> SVG
 
 .LINK
 www.powershellDistrict.com
 
 .LINK
 
http://social.technet.microsoft.com/profile/st%C3%A9phane%20vg/
 
#>
 
[CmdletBinding()]
 Param(
 [Parameter(Mandatory=$true)]
 [ValidateScript({
  
 test-path $_
  
 })][string]$MofFile
 
  
 )
  
 begin{
  
 if (test-path "C:\Windows\System32\wbem\mofcomp.exe"){
 $MofComp = get-item "C:\Windows\System32\wbem\mofcomp.exe"
 }
 
 }
 Process{
 Invoke-expression "& $MofComp $MofFile"
 Write-Output "Mof file compilation actions finished."
 }
 End{
  
 }
 
}
 
Function Export-MofFile {
  
 <#
 .SYNOPSIS
 This function export a specefic class to a MOF file.
 
 .DESCRIPTION
 The function allows export specefic WMI Namespaces, classes and properties by exporting the data to a MOF file format.
 Use the Generated MOF file in whit the cmdlet "Compile-MofFile" in order to import, or re-import the existing class.
 
 .PARAMETER MofFile
 Specify the complete path to the MOF file.(Must contain ".mof" as extension.
 
 .EXAMPLE
 Export-MofFile -ClassName "PowerShellDistrict" -Path "C:\temp\PowerShellDistrict_Class.mof"
 
 .NOTES
 Version: 1.0
 Author: Stéphane van Gulick
 Creation date:18.07.2014
 Last modification date: 18.07.2014
 History : Creation : 18.07.2014 --> SVG
 
 .LINK
 www.powershellDistrict.com
 
 .LINK
 
http://social.technet.microsoft.com/profile/st%C3%A9phane%20vg/
 
#>
 
 [CmdletBinding()]
 Param(
 [parameter(mandatory=$true)]
 [ValidateScript({
 $_.endsWith(".mof")
 })]
 [string]$Path,
 
 
 [parameter(mandatory=$true)]
 [string]$ClassName,
 
 [Parameter(Mandatory=$false)]
 [string]$NameSpace = "Root\CimV2"
  
 )
 
 begin{}
 Process{
 
 if ($PSBoundParameters['ClassName']){
 write-verbose "Checking for Namespace: $($Namespace) and Class $($Classname)"
 
 [wmiclass]$WMI_Info = Get-WmiObject -Namespace $NameSpace -Class $ClassName -list
 
 }
 else{
 [wmi]$WMI_Info = Get-WmiObject -Namespace $NameSpace -list
 
 }
 
 [system.management.textformat]$mof = "mof"
 $MofText = $WMI_Info.GetText($mof)
 Write-Output "Exporting infos to $($path)"
 "#PRAGMA AUTORECOVER" | out-file -FilePath $Path
 $MofText | out-file -FilePath $Path -Append
  
  
 
 }
 End{
 
 return Get-Item $Path
 }
 
}
 
Function Get-WMIClass{
 <#
 .SYNOPSIS
 get information about a specefic WMI class.
 
 .DESCRIPTION
 returns the listing of a WMI class.
 
 .PARAMETER ClassName
 Specify the name of the class that needs to be queried.
 
 .PARAMETER NameSpace
 Specify the name of the namespace where the class resides in (default is "Root\cimv2").
 
 .EXAMPLE
 get-wmiclass
 List all the Classes located in the root\cimv2 namespace (default location).
 
 .EXAMPLE
 get-wmiclass -classname win32_bios
 Returns the Win32_Bios class.
 
 .EXAMPLE
 get-wmiclass -classname MyCustomClass
 Returns information from MyCustomClass class located in the default namespace (Root\cimv2).
 
 .EXAMPLE
 Get-WMIClass -NameSpace root\ccm -ClassName *
 List all the Classes located in the root\ccm namespace
 
 .EXAMPLE
 Get-WMIClass -NameSpace root\ccm -ClassName ccm_client
 Returns information from the cm_client class located in the root\ccm namespace.
 
 .NOTES
 Version: 1.0
 Author: Stephane van Gulick
 Creation date:23.07.2014
 Last modification date: 23.07.2014
 
 .LINK
 www.powershellDistrict.com
 
 .LINK
 
http://social.technet.microsoft.com/profile/st%C3%A9phane%20vg/
 
#>
[CmdletBinding()]
 Param(
 [Parameter(Mandatory=$false,valueFromPipeLine=$true)][string]$ClassName,
 [Parameter(Mandatory=$false)][string]$NameSpace = "root\cimv2"
  
 )
 begin{
 write-verbose "Getting WMI class $($Classname)"
 }
 Process{
 if (!($ClassName)){
 $return = Get-WmiObject -Namespace $NameSpace -Class * -list
 }else{
 $return = Get-WmiObject -Namespace $NameSpace -Class $ClassName -list
 }
 }
 end{
 
 return $return
 }
 
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU55Fmiv0m7Tri0k2dS64uJULt
# sFKgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLgm3cpLhxgvXDAk
# lEN24pUwcYzVMA0GCSqGSIb3DQEBAQUABIIBADe00RVgAG1CgNe1LnHEORCjbCt7
# R/BgRpFCs0XnE+4lNoyZSy2K36BD39/AucBvnyp+85tbBrSOP+9WUGMjlzP+9O7s
# 8Ecvcm4J7x29ZR87wwKCpYuPIz1Wl5VIOCzXAnT1HN3UVrzrIPdT8LV6amgPsPap
# TWAOtFMNRr0XE2o9YydjRamdCsnjnrC/L8QClP10rdb2MGg8T3IcWycQEijTjibG
# ps3j9DkAI9+ime4qOFEqfS8tI4GNmfBeajWCP0pwNia3Q+iBMpbnvA5Sz2YKGnHR
# WPozgT4IjtADuKEXW/tUv2FrlGFZ2rW6wWWVHAeepOCo8PpHFUv2sXxoE/U=
# SIG # End signature block
