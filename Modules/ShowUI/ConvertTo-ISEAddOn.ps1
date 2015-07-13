function ConvertTo-ISEAddOn
{
    [CmdletBinding(DefaultParameterSetName="CreateOnly")]
    param(
    [Parameter(Mandatory=$true,
        ParameterSetName="DisplayNow")]
    [string]$DisplayName,

    [Parameter(Mandatory=$true,
        ParameterSetName="CreateOnly")]
    [Parameter(Mandatory=$true,
        ParameterSetName="DisplayNow")]
    [ScriptBlock]
    $ScriptBlock,

    [Parameter(ParameterSetName="DisplayNow")]
    [switch]
    $AddVertically,

    [Parameter(ParameterSetName="DisplayNow")]
    [switch]
    $AddHorizontally,

    [Parameter(Mandatory=$true,
        ParameterSetName="DisplayNow")]
    [switch]
    $Visible,

    [Switch]
    $Force
    )

    begin {
        if ($psVersionTable.PSVersion -lt "3.0") {
            Write-Warning "Ise Window Add ons were not added until version 3.0."
            return
        }
    }

    process {
$addOnNumber = Get-Random
$addOnType =@"
namespace ShowISEAddOns
{
    using System;
    using System.Windows;
    using System.Windows.Controls;
    using System.Windows.Media;
    using System.Windows.Data;
    using System.Management.Automation;
    using System.Management.Automation.Runspaces;
    using System.Threading;
    using System.Windows.Threading;
    using System.ComponentModel;
    using System.Collections.Generic;
    using System.Collections;
    using System.Collections.ObjectModel;
    using System.Collections.Generic;
    using Microsoft.PowerShell.Host.ISE;
    using System.Windows.Input;
    using System.Text;
    using System.Threading;
    using System.Windows.Threading;



    public class ShowUIIseAddOn${addOnNumber} : UserControl, IAddOnToolHostObject
    {

        ObjectModelRoot hostObject;
            
        #region IAddOnToolHostObject Members

        public ObjectModelRoot HostObject
        {
            get
            {
                return this.hostObject;
            }
            set
            {
                this.hostObject = value;
                this.hostObject.CurrentPowerShellTab.PropertyChanged += new PropertyChangedEventHandler(CurrentPowerShellTab_PropertyChanged);
            }
        }

        private void CurrentPowerShellTab_PropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            if (this.hostObject.CurrentPowerShellTab.CanInvoke) {
                if (this.Content != null && this.Content is UIElement ) {                     
                    (this.Content as UIElement).IsEnabled = true; 
                }
            }
        }

    
        public ShowUIIseAddOn${addOnNumber}() {
            if (Runspace.DefaultRunspace == null ||
                Runspace.DefaultRunspace.ApartmentState != System.Threading.ApartmentState.STA ||
                Runspace.DefaultRunspace.ThreadOptions != PSThreadOptions.UseCurrentThread) {
                InitialSessionState iss = InitialSessionState.CreateDefault();
                iss.ImportPSModule(new string[] { "ShowUI" });
                Runspace rs  = RunspaceFactory.CreateRunspace(iss);
                rs.ApartmentState = System.Threading.ApartmentState.STA;
                rs.ThreadOptions = PSThreadOptions.UseCurrentThread;
                rs.Open();
                Runspace.DefaultRunspace = rs;
                rs.SessionStateProxy.SetVariable("psIse", this.HostObject);
            }
            
            PowerShell psCmd = PowerShell.Create().AddScript(@"
$($ScriptBlock.ToString().Replace('"','""'))
");
            psCmd.Runspace = Runspace.DefaultRunspace;
            try { 
                FrameworkElement ui = psCmd.Invoke<FrameworkElement>()[0];
                this.Content = ui;
                if (ui.GetValue(Control.WidthProperty) != null) {
                    this.Width = ui.Width;
                }
                if (ui.GetValue(Control.HeightProperty) != null) {
                    this.Height = ui.Height;
                }
                if (ui.GetValue(Control.MinWidthProperty) != null) {
                    this.MinWidth = ui.MinWidth;
                }
                if (ui.GetValue(Control.MinHeightProperty) != null) {
                    this.MinHeight = ui.MinHeight;
                }
                if (ui.GetValue(Control.MaxWidthProperty) != null) {
                    this.MaxWidth = ui.MaxWidth;
                }
                if (ui.GetValue(Control.MaxHeightProperty) != null) {
                    this.MaxHeight = ui.MaxHeight;
                }                 
            } catch { 
            } 
            
        }        


        public PSObject[] InvokeScript(string script, object parameters)
        {
            return (PSObject[])RunOnUIThread(
            new DispatcherOperationCallback(
            delegate
            {
                PowerShell psCmd = PowerShell.Create();
                Runspace.DefaultRunspace.SessionStateProxy.SetVariable("this", this);
                psCmd.Runspace = Runspace.DefaultRunspace;
                psCmd.AddScript(script);
                if (parameters is IDictionary)
                {
                    psCmd.AddParameters(parameters as IDictionary);
                }
                else
                {
                    if (parameters is IList)
                    {
                        psCmd.AddParameters(parameters as IList);
                    }
                }
                Collection<PSObject> results = psCmd.Invoke();
                if (psCmd.InvocationStateInfo.Reason != null)
                {
                    throw psCmd.InvocationStateInfo.Reason;
                }
                PSObject[] resultArray = new PSObject[results.Count + psCmd.Streams.Error.Count];
                int count = 0;
                if (psCmd.Streams.Error.Count > 0)
                {
                    foreach (ErrorRecord err in psCmd.Streams.Error)
                    {
                        resultArray[count++] = new PSObject(err);
                    }
                }
                foreach (PSObject r in results)
                {
                    resultArray[count++] = r;
                }
                return resultArray;
            }),
            false);
            
        }

        object RunOnUIThread(DispatcherOperationCallback dispatcherMethod, bool async)
        {
            if (Application.Current != null)
            {
                if (Application.Current.Dispatcher.Thread == Thread.CurrentThread)
                {
                    // This avoids dispatching to the UI thread if we are already in the UI thread.
                    // Without this runing a command like 1/0 was throwing due to nested dispatches.
                    return dispatcherMethod.Invoke(null);
                }
            }

            Exception e = null;
            object returnValue = null;
            SynchronizationContext sync = new DispatcherSynchronizationContext(this.Dispatcher);
            if (async) {
                sync.Post(
                    new SendOrPostCallback(delegate(object obj)
                    {
                        try
                        {
                            returnValue = dispatcherMethod.Invoke(obj);
                        }
                        catch (Exception uiException)
                        {
                            e = uiException;
                        }
                    }),
                    null);

            } else {
                sync.Send(
                    new SendOrPostCallback(delegate(object obj)
                    {
                        try
                        {
                            returnValue = dispatcherMethod.Invoke(obj);
                        }
                        catch (Exception uiException)
                        {
                            e = uiException;
                        }
                    }),
                    null);

            }

            if (e != null)
            {
                throw new System.Reflection.TargetInvocationException(e.Message, e);
            }
            return returnValue;
        }        
        #endregion
    }
        
}
"@

$presentationFramework = [System.Windows.Window].Assembly.FullName
$presentationCore = [System.Windows.UIElement].Assembly.FullName
$windowsBase=[System.Windows.DependencyObject].Assembly.FullName
$gPowerShell=[Microsoft.PowerShell.Host.ISE.PowerShellTab].Assembly.FullName
$systemXaml=[system.xaml.xamlreader].Assembly.FullName
$systemManagementAutomation=[psobject].Assembly.FullName
$t = add-type -TypeDefinition $addOnType -ReferencedAssemblies $systemManagementAutomation,$presentationFramework,$presentationCore,$windowsBase,$gPowerShell,$systemXaml -ignorewarnings -PassThru |
    Select-Object -First 1 
if ($addHorizontally) {
    $exists=  $psISE.CurrentPowerShellTab.HorizontalAddOnTools | Where-Object { $_.Name -eq "$displayName" } 
    if ($Exists -and $Force) {
        $null = $psISE.CurrentPowerShellTab.HorizontalAddOnTools.Remove($exists)
    }
    $psISE.CurrentPowerShellTab.HorizontalAddOnTools.Add("$displayName",$t,$true)
} elseif ($addVertically) {
    $exists=  $psISE.CurrentPowerShellTab.VerticalAddOnTools | Where-Object { $_.Name -eq "$displayName" } 
    if ($Exists -and $Force) {
        $null = $psISE.CurrentPowerShellTab.VerticalAddOnTools.Remove($exists)
    }

    $psISE.CurrentPowerShellTab.VerticalAddOnTools.Add("$displayName",$t,$true)
} else {
    $t
}

            
    }
}



# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQzbUb5crIxSd7jnVxj4QU+ay
# AlSgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMf5tVCLT4UTrZBo
# /5Mv2dmMdaiuMA0GCSqGSIb3DQEBAQUABIIBAGZYRIbgngeDR2HVJRZVd7DeMLSo
# rWofYbb0UClaSs9wibnfwD+t0cTRZg24k3RobHKhvVW/Ep/WoUqsUBQOdNpwx/yO
# AgAPYjl1DMgSc8eCZCcAf214vs3YYlAjtVDp60eQuxW4vZk961FuY5485bYA/7cZ
# 3Gll6MS8H1XsXxBQ7au43lJFPhVDB83eqWPjCLh8l28lICyvgXBUOGt8FP7zSjy9
# L2bxQEy+Jo9lvQAgnTDuuw7GlKS2OqQ0v9OJT6Y3+/fgvshr/vtvrDZkntYVEZ7m
# PMT0sGrXAFXMyI2l+g0Av42fmUcU8o7gIgAiMbB4pG49k9kpKAwCE34dJZE=
# SIG # End signature block
