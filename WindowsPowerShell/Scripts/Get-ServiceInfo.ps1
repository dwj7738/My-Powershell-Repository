<#

            .SYNOPSIS

            Script to retrieve information about services.

      .EXAMPLE

            .\Get-ServiceInfo.ps1

            Retrieve all services running on the local computer that can be Paused.

      .EXAMPLE

            .\Get-ServiceInfo.ps1 -CurrentState All -GridView

            Retrieve all services running on the local computer and display in a GridView.     

      .EXAMPLE

            .\Script.ps1 -Services S* -ComputerName <computername> -CurrentState stopped -startmode auto -Sort DisplayName

            Retrieve all services starting with S, on a remote computer, that can be stopped, and sort by the DisplayName.

      .NOTES

            NAME: Get-ServiceInfo.ps1

            AUTHOR: Shane Hoey, powershelldownunder.com

            DATE: 3rd April 2011

#Requires -Version 2.0

#>

 

param(

 [string]$Name = '*',

 [string]$ComputerName = $env:computername,

 [ValidateSet('All','CanPause','CanContinue','CanPauseAndContinue','CanStop','CanShutdown','Stopped')]

 [string]$CurrentState = 'CanPause',

 [ValidateSet('Status','Name','DisplayName')]

 [string]$Sort = 'Name',

 [switch]$GridView

)
If (Test-connection -ComputerName $ComputerName -count 1 -quiet)
{
 $svc = get-service $Name -computername $ComputerName
 switch($CurrentState)
 {
  'All' { }
  'CanPause' { $svc = $svc | Where-Object {$_.status -eq 'running' -and $_.CanPauseAndContinue} }
  'CanContinue' { $svc = $svc | Where-Object {$_.status -eq 'paused' -and $_.CanPauseAndContinue} }
  'CanPauseAndContinue' { $svc = $svc | Where-Object {$_.CanPauseAndContinue} }
  'CanStop'{ $svc = $svc | Where-Object {$_.CanStop} }
  'CanShutdown'{ $svc = $svc | Where-Object {$_.CanShutdown} }
  'IsStopped'{$svc = $svc | Where-Object {$_.Stopped}}
 }
 if ($GridView)
 {    $svc | Select-Object -Property Status,Name,DisplayName | Sort-Object -Property $Sort | Out-GridView -Title 'Services - $CurrentState' }
 else
 { $svc | Select-Object -Property Status,Name,DisplayName | Sort-Object -Property $Sort | Format-Table -Autosize}
}
else
{
 "$ComputerName is Unreachable"
}
# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsdKSfKFUULAfpB3zyct+uNig
# 2gWgggI9MIICOTCCAaagAwIBAgIQiDf4l7KfgJdCCCaJOuGruDAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2Vyc2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xMjA2MTYwNjIyMDdaFw0zOTEyMzEyMzU5NTlaMBoxGDAWBgNVBAMTD1Bvd2Vy
# c2hlbGwgVXNlcjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA2AQ5hTYXFzN9
# 62GIrE8tV+e3cYxFMYN5sG6TRa8ZBGAc2IEQ9uYrz7YXUstjYq6AkVpPjF/h4mlh
# WTFCjBSlhRQj8B6MOSy5pnKFM+cLM/5UcE7ZKcwXpvrbxntu4DiT8iBxKrSYjkqA
# BbMZCyrQ8BAIrFgqy/t97FyGaFFoDP0CAwEAAaN2MHQwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwXQYDVR0BBFYwVIAQe3Eaz1UlVI4+TqpVWMaLyKEuMCwxKjAoBgNVBAMT
# IVBvd2Vyc2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdIIQrIslSDNpf4tLn3Ai
# OEZ3MTAJBgUrDgMCHQUAA4GBAHdn+q07uKxlU/ELAluEVTsKBDxoIHtNa9GDtUhE
# Hrl10nwwgmTtC6XO2UmwJVw/1J+LqebKe7mWpha5Uzyc8GgeNc+m8zdbGuvqzpQe
# vOZ9UZSYBKrXvNXhCqw46WqEVpQP9DM+fJzc6O1trbHQ9HAFPgTktEIz5fg8gz2V
# GoJxMYIBYDCCAVwCAQEwQDAsMSowKAYDVQQDEyFQb3dlcnNoZWxsIExvY2FsIENl
# cnRpZmljYXRlIFJvb3QCEIg3+Jeyn4CXQggmiTrhq7gwCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FOySUEkTR3NPOlZjCQJy+m2U0z94MA0GCSqGSIb3DQEBAQUABIGAYtdneTWaZxzR
# pIVqp/9w2qQjo3r2BjycQlKOCYxM6V5TLmzvDD/kWyL3C2noWEWZPUUyeURBdXDA
# ZAf+KEUXnJpzkac+9uB8HV1TWE2wJPtjsISBlXwupqlcn4CJ6eKLj8b30709naTa
# zjmPlFkUiGkcV508ZCQKOlNBxrY6HM0=
# SIG # End signature block
