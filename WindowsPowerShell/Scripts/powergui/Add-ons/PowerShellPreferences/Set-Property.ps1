that is currently active.</param>
      <param name="newTemplate">A <see cref="T:System.Windows.Controls.ControlTemplate" /> object that specifies a new control template to use.</param>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.OnTextChanged(System.Windows.Controls.TextChangedEventArgs)">
      <summary>Is called when content in this editing control changes.</summary>
      <param name="e">The arguments that are associated with the <see cref="E:System.Windows.Controls.Primitives.TextBoxBase.TextChanged" /> event.</param>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.OnTextInput(System.Windows.Input.TextCompositionEventArgs)">
      <summary>Invoked whenever an unhandled <see cref="E:System.Windows.Input.TextCompositionManager.TextInput" /> attached routed event reaches an element derived from this class in its route. Implement this method to add class handling for this event.</summary>
      <param name="e">Provides data about the event.</param>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.PageDown">
      <summary>Scrolls the contents of the control down by one page.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.PageLeft">
      <summary>Scrolls the contents of the control to the left by one page.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.PageRight">
      <summary>Scrolls the contents of the control to the right by one page.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.PageUp">
      <summary>Scrolls the contents of the control up by one page.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.Paste">
      <summary>Pastes the contents of the Clipboard over the current selection in the text editing control.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.Redo">
      <summary>Undoes the most recent undo command. In other words, redoes the most recent undo unit on the undo stack.</summary>
      <returns>true if the redo operation was successful; otherwise, false. This method returns false if there is no undo command available (the undo stack is empty).</returns>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.ScrollToEnd">
      <summary>Scrolls the view of the editing control to the end of the content.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.ScrollToHome">
      <summary>Scrolls the view of the editing control to the beginning of the viewport.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.ScrollToHorizontalOffset(System.Double)">
      <summary>Scrolls the contents of the editing control to the specified horizontal offset.</summary>
      <param name="offset">A double value that specifies the horizontal offset to scroll to.</param>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.ScrollToVerticalOffset(System.Double)">
      <summary>Scrolls the contents of the editing control to the specified vertical offset.</summary>
      <param name="offset">A double value that specifies the vertical offset to scroll to.</param>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.SelectAll">
      <summary>Selects all the contents of the text editing control.</summary>
    </member>
    <member name="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionBrush">
      <summary>Gets or sets the brush that highlights selected text.</summary>
      <returns>The brush that highlights selected text.</returns>
    </member>
    <member name="F:System.Windows.Controls.Primitives.TextBoxBase.SelectionBrushProperty">
      <summary>Identifies the <see cref="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionBrush" /> dependency property.</summary>
    </member>
    <member name="E:System.Windows.Controls.Primitives.TextBoxBase.SelectionChanged">
      <summary>Occurs when the text selection has changed.</summary>
    </member>
    <member name="F:System.Windows.Controls.Primitives.TextBoxBase.SelectionChangedEvent">
      <summary>Identifies the <see cref="E:System.Windows.Controls.Primitives.TextBoxBase.SelectionChanged" /> routed event. </summary>
      <returns>The identifier for the <see cref="E:System.Windows.Controls.Primitives.TextBoxBase.SelectionChanged" /> routed event.</returns>
    </member>
    <member name="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionOpacity">
      <summary>Gets or sets the opacity of the <see cref="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionBrush" />.</summary>
      <returns>The opacity of the <see cref="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionBrush" />. The default is 0.4.</returns>
    </member>
    <member name="F:System.Windows.Controls.Primitives.TextBoxBase.SelectionOpacityProperty">
      <summary>Identifies the <see cref="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionOpacity" /> dependency property.</summary>
    </member>
    <member name="P:System.Windows.Controls.Primitives.TextBoxBase.SpellCheck">
      <summary>Gets a <see cref="T:System.Windows.Controls.SpellCheck" /> object that provides access to spelling errors in the text contents of a <see cref="T:System.Windows.Controls.Primitives.TextBoxBase" /> or <see cref="T:System.Windows.Controls.RichTextBox" />.</summary>
      <returns>A <see cref="T:System.Windows.Controls.SpellCheck" /> object that provides access to spelling errors in the text contents of a <see cref="T:System.Windows.Controls.Primitives.TextBoxBase" /> or <see cref="T:System.Windows.Controls.RichTextBox" />.This property has no default value.</returns>
    </member>
    <member name="E:System.Windows.Controls.Primitives.TextBoxBase.TextChanged">
      <summary>Occurs when content changes in the text element.</summary>
    </member>
    <member name="F:System.Windows.Controls.Primitives.TextBoxBase.TextChangedEvent">
      <summary> Identifies the <see cref="E:System.Windows.Controls.Primitives.TextBoxBase.TextChanged" /> routed event. </summary>
      <returns>The identifier for the <see cref="E:System.Windows.Controls.Primitives.TextBoxBase.TextChanged" /> routed event.</returns>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.Undo">
      <summary>Undoes the most recent undo command. In other words, undoes the most recent undo unit on the undo stack.</summary>
      <returns>true if the undo operation was successful; otherwise, false. This method returns false if the undo stack is empty.</returns>
    </member>
    <member name="P:System.Windows.Controls.Primitives.TextBoxBase.UndoLimit">
      <summary>Gets or sets the number of actions stored in the undo queue.</summary>
      <returns>The number of actions stored in the undo queue. The default is –1, which means the undo queue is limited to the memory that is available.</returns>
      <exception cref="T:System.InvalidOperationException">
        <see cref="P:System.Windows.Controls.Primitives.TextBoxBase.UndoLimit" /> is set after calling <see cref="M:System.Windows.Controls.Primitives.TextBoxBase.BeginChange" /> and before calling <see cref="M:System.Windows.Controls.Primitives.TextBoxBase.EndChange" />.</exception>
    </member>
    <member name="F:System.Windows.Controls.Primitives.TextBoxBase.U
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3bqgnWTwdkr+hGOKrQ/wvvs+
# YXGgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFsVHVm3xNZ6MRGE
# DMTCtwNNWDmxMA0GCSqGSIb3DQEBAQUABIIBAIeHAgSJT5xCw+h0JH+qM5QaAC4q
# 5V7GJ31pnzrSjgDiMEgBj8Viezerdrmy4EIcfkA13rilvbhPncp5NypGMJwPxHLr
# ILQL0VbNg3soKNqRepYPqbPgKLA9pjSb6fxrDKAX7Cb4Uj5JivLnwi9UOEF3IbQX
# LoY1KrDxFRFFmk0HK9eUxVjm6WE6x4JFFzkMdRqRl1FCtyu44mP6Hs0TyBuAkMgg
# mrSH5M4BbbOB6WTfoOnScwPruj6ZMtgmNxlmjdFTA3fsJOYa3ENHK2/8+htaLp42
# 6E4MDFIqBYNVjsGKvjZU2JzFIbVfxtPrx0bC716XV2QC9OfwXif3UkYnWs8=
# SIG # End signature block
