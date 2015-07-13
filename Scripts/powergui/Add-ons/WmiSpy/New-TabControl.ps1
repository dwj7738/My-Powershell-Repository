 specified by <paramref name="lookupId" /> and removes it from the queue.
                MessageLookupAction.First: Receives the first message in the queue and removes it from the queue. The <paramref name="lookupId" /> parameter must be set to 0.
                MessageLookupAction.Last: Receives the last message in the queue and removes it from the queue. The <paramref name="lookupId" /> parameter must be set to 0.
                </param>
      <param name="lookupId">
                    The <see cref="P:System.Messaging.Message.LookupId" /> of the message to receive, or 0. 0 is used when accessing the first or last message in the queue. 
                </param>
      <param name="transactionType">
                    One of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> values, describing the type of transaction context to associate with the message.
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
      <exception cref="T:System.ComponentModel.InvalidEnumArgumentException">
                    The <paramref name="action" /> parameter is not one of the <see cref="T:System.Messaging.MessageLookupAction" /> members.
                
                    -or- 
                
                    The <paramref name="transactionType" /> parameter is not one of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> members.
                </exception>
    </member>
    <member name="E:System.Messaging.MessageQueue.ReceiveCompleted">
      <summary>
                    Occurs when a message has been removed from the queue. This event is raised by the asynchronous operation, <see cref="M:System.Messaging.MessageQueue.BeginReceive" />.
                </summary>
    </member>
    <member name="M:System.Messaging.MessageQueue.Refresh">
      <summary>
                    Refreshes the properties presented by the <see cref="T:System.Messaging.MessageQueue" /> to reflect the current state of the resource.
                </summary>
    </member>
    <member name="M:System.Messaging.MessageQueue.ResetPermissions">
      <summary>
                    Resets the permission list to the operating system's default values. Removes any queue permissions you have appended to the default list.
                </summary>
      <exception cref="T:System.Messaging.MessageQueueException">
                    An error occurred when accessing a Message Queuing method. 
                </exception>
      <PermissionSet>
        <IPermission class="System.Messaging.MessageQueuePermission, System.Messaging, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" version="1" Unrestricted="true" />
      </PermissionSet>
    </member>
    <member name="M:System.Messaging.MessageQueue.Send(System.Object)">
      <summary>
                    Sends an object to non-transactional queue referenced by this <see cref="T:System.Messaging.MessageQueue" />.
                </summary>
      <param name="obj">
                    The object to send to the queue. 
                </param>
      <exception cref="T:System.Messaging.MessageQueueException">
                    The <see cref="P:System.Messaging.MessageQueue.Path" /> property has not been set.
                
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
    <member name="M:System.Messaging.MessageQueue.Send(System.Object,System.Messaging.MessageQueueTransaction)">
      <summary>
                    Sends an object to the transactional queue referenced by this <see cref="T:System.Messaging.MessageQueue" />.
                </summary>
      <param name="obj">
                    The object to send to the queue. 
                </param>
      <param name="transaction">
                    The <see cref="T:System.Messaging.MessageQueueTransaction" /> object. 
                </param>
      <exception cref="T:System.ArgumentNullException">
                    The <paramref name="transaction" /> parameter is null. 
                </exception>
      <exception cref="T:System.Messaging.MessageQueueException">
                    The <see cref="P:System.Messaging.MessageQueue.Path" /> property has not been set.
                
                    -or- 
                
                    The Message Queuing application indicated an incorrect transaction use.
                
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
    <member name="M:System.Messaging.MessageQueue.Send(System.Object,System.Messaging.MessageQueueTransactionType)">
      <summary>
                    Sends an object to the queue referenced by this <see cref="T:System.Messaging.MessageQueue" />.
                </summary>
      <param name="obj">
                    The object to send to the queue. 
                </param>
      <param name="transactionType">
                    One of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> values, describing the type of transaction context to associate with the message. 
                </param>
      <exception cref="T:System.ComponentModel.InvalidEnumArgumentException">
                    The <paramref name="transactionType" /> parameter is not one of the <see cref="T:System.Messaging.MessageQueueTransactionType" /> members. 
                </exception>
      <exception cref="T:System.Messaging.MessageQueueException">
                    The <see cref="P:System.Messaging.MessageQueue.Path" /> property has not been set.
                
                    -or- 
                
                    An error occurred when accessing a Message Queuing method. 
                </exception>
      <PermissionSet>
        <IPermission class="System.Security.Permissions.EnvironmentPermission, mscorlib, Version=2.0.3600.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" version="1" Unrestricted="true"
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzBNB36GWGcSuTOlbHmx8bBvq
# 1FmgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFOabnRYBeqnw4I7O
# pIkslCvRYWxLMA0GCSqGSIb3DQEBAQUABIIBAIVbbFULn+IbQJBYg9KPBu4NznJl
# Wq9KEBVk464QQo+iEeWxDwKQRW7XRSEghZSQeTuY0R5GQICKTT8hybkY4YHKAgXf
# kJR+eyGKIuPgxK9feT1PAEFG3hmgvRyJ0XqLQ2JD/5F81Pe+8WAOfO5/7jGDgDJ4
# P+6qc2V7ih9o8RY1vhZp/FZ3G6Be8LFptIBgt/ZKsU7NaaSdLgqq9+9thErIvI7X
# RNj5D9EPxHrFsOSDE9Kg/D9WvkWNiOgi9/mSUiasbGXqRQcHU6o7lFkFPMIxIE5t
# 2uHIAXJ3x8R22OIezPsAu9CHy8hinRqPWnsY8bZt+rNn3f5vfJs14ASg8/E=
# SIG # End signature block
