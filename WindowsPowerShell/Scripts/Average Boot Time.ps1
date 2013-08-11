<#The following gets the average boot time of the last 10 system boots
#>get
$eventsBoot = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnostics-Performance/Operational'; ID=100} -MaxEvents 10 

$avgBootTime = 0
foreach($event in $eventsBoot){
	$avgBootTime += (([System.Diagnostics.Eventing.Reader.EventLogRecord]$event).Properties.Item(5).Value) / $eventsBoot.Count
}
Write-Host $avgBootTime
# SIG # Begin signature block
# MIIEIQYJKoZIhvcNAQcCoIIEEjCCBA4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzuo4osoObfijea26H4vBTeh8
# TIagggI2MIICMjCCAZugAwIBAgIQ9+G66SljopNGkRiE4wb7wjANBgkqhkiG9w0B
# AQUFADAhMR8wHQYDVQQDExZEYXZpZCBKb2huc29uIC0gT2ZmaWNlMB4XDTEzMDEw
# MTA0MDAwMFoXDTE5MDEwMTA0MDAwMFowITEfMB0GA1UEAxMWRGF2aWQgSm9obnNv
# biAtIE9mZmljZTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAhz7lYQ48+nPI
# qgLXhjDowDhLfEQIBl+D6b7ZsqKoTuIOfiZKZB7+BhS7fKQQBce7UbHuM+XJbpdg
# TytQN4w+vNRbl0KzS+Hdf8Ua0fByE4d36D1Fkc/Voc2b0l5ZvtEkNj8P82Gpug7y
# NxK4VnurjN8Pqch34ckuV6lsXGzMFv0CAwEAAaNrMGkwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwUgYDVR0BBEswSYAQWnGatD+K3j5D75gJl4jA5qEjMCExHzAdBgNVBAMT
# FkRhdmlkIEpvaG5zb24gLSBPZmZpY2WCEPfhuukpY6KTRpEYhOMG+8IwDQYJKoZI
# hvcNAQEFBQADgYEALTyvZ8GBIFBE+vJAeblQwrE/M+VZpH/Bna4/5OQ6YzcAKWP8
# FbihnczVo1VAqgRHqgkqKVpYPF2I9P6k+61fG/5WOb5Ka8h4C+3oq8JU66YsZBJW
# wyIaV8oJudmGXanJ5YfE9Yp2FhSV0t9gCeUfchZD8UmdaUdQgxhzhSLjRAExggFV
# MIIBUQIBATA1MCExHzAdBgNVBAMTFkRhdmlkIEpvaG5zb24gLSBPZmZpY2UCEPfh
# uukpY6KTRpEYhOMG+8IwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHprse0CsdjAYtfXV1EzIGps
# MvCAMA0GCSqGSIb3DQEBAQUABIGAYcPQl8kaAEadrHoOd+tDexRRyVen7VlhtKqa
# VwRJRUne/HlKMcWqbVqaDD8zeVEWv4QeNVmW7mVy5Qs85DcuDU1/bcHTqPTEANmX
# UWAa1mlT4qXitv8Mi11FHgiFBb/1+MMQFlLNqbmB3fi06RqcJmxhahcuno5qAWaw
# IHvB414=
# SIG # End signature block
