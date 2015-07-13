ermission class="System.Diagnostics.PerformanceCounterPermission, System, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
      </PermissionSet>
    </member>
    <member name="M:System.Messaging.MessageQueue.ReceiveById(System.String,System.TimeSpan,System.Messaging.MessageQueueTransaction)">
      <summary>
                    Receives the message that matches the given identifier (from a transactional queue) and waits until either a message with the specified identifier is available in the queue or the time-out expires.
                </summary>
      <returns>
                    The <see cref="T:System.Messaging.Message" /> whose <see cref="P:System.Messaging.Message.Id" /> property matches the <paramref name="id" /> parameter passed in.
                </returns>
      <param name="id">
                    The <see cref="P:System.Messaging.Message.Id" /> of the message to receive. 
                </param>
      <param name="timeout">
                    A <see cref="T:System.TimeSpan" /> that indicates the time to wait until a new message is available for inspection. 
                </param>
      <param name="transaction">
                    The <see cref="T:System.Messaging.MessageQueueTransaction" /> object. 
                </param>
      <exception cref="T:System.ArgumentNullException">
                    The <paramref name="id" /> parameter is null.
                
                    -or- 
                
                    The <paramref name="transaction" /> parameter is null. 
                </exception>
      <exception cref="T:System.ArgumentException">
                    The value specified for the <paramref name="timeout" /> parameter is not valid, possibly <paramref name="timeout" /> is less than <see cref="F:System.TimeSpan.Zero" /> or greater than <see cref="F:System.Messaging.MessageQueue.InfiniteTimeout" />. 
                </exception>
      <exception cref="T:System.Messaging.MessageQueueException">
                    A message with the specified <paramref name="id" /> did not arrive in the queue before the time-out expired.
                
                    -or- 
                
                    The queue is non-transactional.
                
                    -or- 
                
                    An error occurred when accessing a Message Queuing method. 
                </exception>
      <PermissionSet>
        <IPermission class="System.Security.Permissions.EnvironmentPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
        <IPermission class="System.Security.Permissions.FileIOPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
        <IPermission class="System.Security.Permissions.SecurityPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Flags="UnmanagedCode, ControlEvidence" />
        <IPermission class="System.Messaging.MessageQueuePermission, System.Messaging, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" version="1" Unrestricted="true" />
        <IPermission class="System.Diagnostics.PerformanceCounterPermission, System, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
      </PermissionSet>
    </member>
    <member name="M:System.Messaging.MessageQueue.ReceiveById(System.String,System.TimeSpan,System.Messaging.MessageQueueTransactionType)">
      <summary>
                    Receives the message that matches the given identifier and waits until either a message with the specified identifier is available in the queue or the time-out expires.
                </summary>
      <returns>
                    The <see cref="T:System.Messaging.Message" /> whose <see cref="P:System.Messaging.Message.Id" /> property matches the <paramref name="id" /> parameter passed in.
                </returns>
      <param name="id">
                    The <see cref="P:System.Messaging.Message.Id" /> of the message to receive. 
                </param>
      <param name="timeout">
                    A <see cref="T:System.TimeSpan" /> that indicates the time to wait until a new message is available for inspection. 
                </param>
      <param name="transactionType">
                    One of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> values, describing the type of transaction context to associate with the message. 
                </param>
      <exception cref="T:System.ArgumentNullException">
                    The <paramref name="id" /> parameter is null. 
                </exception>
      <exception cref="T:System.ArgumentException">
                    The value specified for the <paramref name="timeout" /> parameter is not valid, possibly <paramref name="timeout" /> is less than <see cref="F:System.TimeSpan.Zero" /> or greater than <see cref="F:System.Messaging.MessageQueue.InfiniteTimeout" />. 
                </exception>
      <exception cref="T:System.Messaging.MessageQueueException">
                    A message with the specified <paramref name="id" /> did not arrive in the queue before the time-out expired.
                
                    -or- 
                
                    An error occurred when accessing a Message Queuing method. 
                </exception>
      <exception cref="T:System.ComponentModel.InvalidEnumArgumentException">
                    The <paramref name="transactionType" /> parameter is not one of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> members. 
                </exception>
      <PermissionSet>
        <IPermission class="System.Security.Permissions.EnvironmentPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
        <IPermission class="System.Security.Permissions.FileIOPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
        <IPermission class="System.Security.Permissions.SecurityPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Flags="UnmanagedCode, ControlEvidence" />
        <IPermission class="System.Messaging.MessageQueuePermission, System.Messaging, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" version="1" Unrestricted="true" />
        <IPermission class="System.Diagnostics.PerformanceCounterPermission, System, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true" />
      </PermissionSet>
    </member>
    <member name="M:System.Messaging.MessageQueue.ReceiveByLookupId(System.Int64)">
      <summary>
                    Introduced in MSMQ 3.0. Receives the message that matches the given lookup identifier from a non-transactional queue.
                </summary>
      <returns>
                    The <see cref="T:System.Messaging.Message" /> whose <see cref="P:System.Messaging.Message.LookupId" /> property matches the <paramref name="lookupId" /> parameter passed in.
                </returns>
      <param name="lookupId">
                    The <see cref="P:System.Messaging.Message.LookupId" /> of the message to receive. 
                </param>
      <exception cref="T:System.PlatformNotSupportedException">
                    MSMQ 3.0 is not installed.
                </exception>
      <exception cref="T:System.InvalidOperationException">
                    The message with the specified <paramref name="lookupId" /> could not be found. 
                </exception>
      <exception cref="T:System.Messaging.MessageQueueException">
                    An error occurred when accessing a Message Queuing method. 
                </exception>
    </member>
    <member name="M:System.Messaging.MessageQueue.ReceiveByLookupId(System.Messaging.MessageLookupAction,System.Int64,System.Messaging.MessageQueueTransaction)">
      <summary>
                    Introduced in MSMQ 3.0. Receives a specific message from a transactional queue. The message can be specified by a lookup identifier or by its position at the front or end of the queue.
                </summary>
      <returns>
                    The <see cref="T:System.Messaging.Message" /> specified by the <paramref name="lookupId" /> and <paramref name="action" /> parameters passed in.
                </returns>
      <param name="action">
                    One of the <see cref="T:System.Messaging.MessageLookupAction" /> values, specifying how the message is read in the queue. Specify one of the following:
                MessageLookupAction.Current: Receives the message specified by <paramref name="lookupId" /> and removes it from the queue.
                MessageLookupAction.Next: Receives the message following the message specified by <paramref name="look
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOglRwTVYwfZCYv43mLNQ6yrI
# pAOgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFH81EOT/GA8Um1k3
# JFXCre0567DhMA0GCSqGSIb3DQEBAQUABIIBALLZ2+axcJwLuSoSEBibD6Wvm7kw
# y5jg80OR0e7cT5Hk4ig+GIR1RhP3uMUC6NHIMJRxWLlRypabMg9TmOvcIMl9NPAd
# oae0iV5pAU0yzFL8tvk0TFGglgrIxgX6H84zmqyoHrToCoc2quhwnZIb9TmpGQf8
# 6kRlFtcYgpbvXEsvgc0jIsO6+KJ5AfgcbPELHz75x2OyCo+AU/5dcxRJBdTD0eIu
# SVKGlIQGh3a7x7mCFnXXBrOLA6BbJLBfjlwyW6c8Gqk9zuzZAr2IL8cY3/CdHhPP
# Q6tlRSUmLgdtnAUPyO8SWCYe8RYsGSKZoPE+HTV6P3LKHIP6UI5/S5xwrnE=
# SIG # End signature block
