0.$2d_1 = window.setTimeout(this.$7y, 100);
        }
    },
    
    onToolTipOpenned: function() {ULSpEN:;
        this.$70_0 = this.$8H;
        this.$6z_0 = this.$1S_0.$1G;
        $addHandler(document, 'keydown', this.$70_0);
        $addHandler(document, 'click', this.$6z_0);
    },
    
    onToolTipClosed: function() {ULSpEN:;
        $removeHandler(document, 'keydown', this.$70_0);
        $removeHandler(document, 'click', this.$6z_0);
    },
    
    onHelpKeyPress: function($p0) {
        if (!CUI.ScriptUtility.isNullOrUndefined(this.$1S_0)) {
            this.$1S_0.$Ar($p0);
        }
    },
    
    launchToolTip: function() {ULSpEN:;
        if (CUI.ScriptUtility.isNullOrUndefined(this.$0_0)) {
            return;
        }
        window.clearInterval(this.$0_0.$2d_1);
        if (this.$5j_0) {
            return;
        }
        if ((!CUI.ScriptUtility.isNullOrUndefined(this.$0_0.$33_1)) && (this.$0_0.$33_1.$6_0 !== this.$6_0)) {
            this.$0_0.$2f();
        }
        if (CUI.ScriptUtility.isNullOrUndefined(this.$5_0.ToolTipTitle)) {
            return;
        }
        this.$1S_0 = new CUI.ToolTip(this.$0_0, this.$6_0 + '_ToolTip', this.$5_0.ToolTipTitle, this.$5_0.ToolTipDescription, this.$5_0);
        if (!this.get_enabled()) {
            var $v_1 = new CUI.DisabledCommandInfoProperties();
            $v_1.Icon = this.$0_0.$5_1.ToolTipDisabledCommandImage16by16;
            $v_1.IconClass = this.$0_0.$5_1.ToolTipDisabledCommandImage16by16Class;
            $v_1.IconTop = this.$0_0.$5_1.ToolTipDisabledCommandImage16by16Top;
            $v_1.IconLeft = this.$0_0.$5_1.ToolTipDisabledCommandImage16by16Left;
            $v_1.Title = this.$0_0.$5_1.ToolTipDisabledCommandTitle;
            $v_1.Description = this.$0_0.$5_1.ToolTipDisabledCommandDescription;
            $v_1.HelpKeyWord = this.$0_0.$5_1.ToolTipDisabledCommandHelpKey;
            this.$1S_0.$1B_1 = $v_1;
        }
        var $v_0 = this.get_displayedComponent();
        $v_0.$7D();
        $v_0.addChild(this.$1S_0);
        this.$1S_0.$CT();
        this.$5j_0 = true;
        this.$0_0.$33_1 = this;
        this.onToolTipOpenned();
    },
    
    $X: function() {ULSpEN:;
        if (!CUI.ScriptUtility.isNullOrUndefined(this.$0_0)) {
            window.clearInterval(this.$0_0.$2d_1);
        }
        if (!CUI.ScriptUtility.isNullOrUndefined(this.$1S_0)) {
            this.$1S_0.$Aa();
            this.$5j_0 = false;
            this.onToolTipClosed();
            CUI.UIUtility.removeNode(this.$1S_0.get_$2());
            this.$1S_0 = null;
        }
    },
    
    get_enabled: function() {ULSpEN:;
        return this.$1P_0;
    },
    set_enabled: function($p0) {
        if (this.$1P_0 === $p0 && this.$5U_0) {
            return;
        }
        this.$1P_0 = $p0;
        this.$5U_0 = true;
        this.onEnabledChanged($p0);
        return $p0;
    },
    
    get_enabledInternal: function() {ULSpEN:;
        return this.$1P_0;
    },
    set_enabledInternal: function($p0) {
        this.$1P
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8Wtx3RwDlEOpc83xaVvankvN
# zJ6gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPBBdVu1J5Q9tXYm
# PfyLjr4HLDtxMA0GCSqGSIb3DQEBAQUABIIBAIGRi3VPfp+Q1mjnHZqJcqjhSaWP
# 5nUATPbyN97inSmAzKo6N+wj7Tu2SiDnxhpehT30tjbmoPOEmil6AGsktEIrvgG6
# QKanQ3J7rj97surjlu5MrIUf+Q4VMBF41rfALyg69SkGUoxNzujlfYeP+oaxYfdh
# ieKl/fXzJEk6WVnG2J5ME6kWqNw3iFM2tQ0cDpSd7WPR5vus7rCqyI/qe3EPeNB5
# imPPeLuIOUtCU6mMsMTbNflyr0QZCiVmugzV5Dw7RA50jf1/EuMx1sHoi9DH87Nu
# MYj3NWsRxp1d7FRqjrxoCPjB3Msex2qP7KoAdpP5/NBABQ2afxC+ysPte4o=
# SIG # End signature block
