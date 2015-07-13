function Write-AspDotNetScriptPage
{
    <#
    .Synopsis
        Writes an ASP.NET page that executes PowerShell script
    .Description
        Runs a PowerShell script inside of an ASP.net page.  
        
        The runspace used in the ASP.NET script page will be reused for as long as the session is active.
        
        Variables set while running your script will be available throughout the session.                       
        
        PowerShellV2 must be installed on the server, but no other special binaries are required.
    .Example
        Write-AspDotNetScriptPage -PrependBootstrapper -ScriptBlock {
            $response.Write("<pre>
$(Get-Help Get-Command -full | Out-String -width 1024)
</pre>")            
        } | 
            Set-Content
    .Link
        about_ServerSidePowerShell
    #>
    [CmdletBinding(DefaultParameterSetName='BootStrapper')]
    [OutputType([string])]
    param(
    # The script block to embed in the page.  This will use the runScript function declared in the bootstrapper.
    [Parameter(Mandatory=$true,ParameterSetName='ScriptBlock',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ScriptBlock]$ScriptBlock,
    
    # The direct ASP.NET text to embed in the page.  To run scripts inside of this text, use <% runScript(); %>
    [Parameter(Mandatory=$true,ParameterSetName='Text',ValueFromPipelineByPropertyName=$true)]
    [string]$Text,
    
    # If set, prepends the bootstrapper code to the ASP.NET page.  
    # This is required the first time you want to run PowerShell inside of your ASP.NET page.
    # It declares a function, runScript, which you can use to run PowerShell
    [Parameter(ParameterSetName='ScriptBlock',ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='Text',ValueFromPipelineByPropertyName=$true)]
    [switch]$NoBootstrapper,
    
    # If set, the page generated will include this page as the ASP.NET master page
    [string]$MasterPage,

    # If set, the page generated will be a master page
    [Switch]$IsMasterPage,

    # If set, uses a codefile page
    [string]$CodeFile,

    # If set, inherits from another codefile page
    [string]$Inherit
    )
    
    begin {
        function issEmbed($cmd) {
        
        if ($cmd.Definition -like "*<script*") {
@"
        string $($cmd.Name.Replace('-',''))Base64 = "$([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd.Definition)))";
        string $($cmd.Name.Replace('-',''))Definition = System.Text.Encoding.Unicode.GetString(System.Convert.FromBase64String($($cmd.Name.Replace('-',''))Base64));
        SessionStateFunctionEntry $($cmd.Name.Replace('-',''))Command = new SessionStateFunctionEntry(
            "$($cmd.Name)", $($cmd.Name.Replace('-',''))Definition
        );
        iss.Commands.Add($($cmd.Name.Replace('-',''))Command);
"@        
        } else {
@"
        SessionStateFunctionEntry $($cmd.Name.Replace('-',''))Command = new SessionStateFunctionEntry(
            "$($cmd.Name)", @"
            $($cmd.Definition.ToString().Replace('"','""'))
            "
        );
        iss.Commands.Add($($cmd.Name.Replace('-',''))Command);
"@
        }
        }
        $functionBlackList = 65..90 | ForEach-Object -Begin {
            "ImportSystemModules", "Disable-PSRemoting", "Restart-Computer", "Clear-Host", "cd..", "cd\\", "more"
        } -Process { 
            [string][char]$_ + ":" 
        }
                
                
        $masterPageDirective = if ($MasterPage) {
            "MasterPageFile='$MasterPage'"
        } else {
            ""
        }
        
        
        # These core functions must exist in all runspaces
        if (-not $script:FunctionsInEveryRunspace) {
            $script:FunctionsInEveryRunspace = 'ConvertFrom-Markdown', 'Get-Web', 'Get-WebConfigurationSetting', 'Get-FunctionFromScript', 'Get-Walkthru', 
                'Get-WebInput', 'Request-CommandInput', 'New-Region', 'New-RssItem', 'New-WebPage', 'Out-Html', 'Out-RssFeed', 'Send-Email',
                'Write-Ajax', 'Write-Css', 'Write-Host', 'Write-Link', 'Write-ScriptHTML', 'Write-WalkthruHTML', 
                'Write-PowerShellHashtable', 'Compress-Data', 'Expand-Data', 'Import-PSData', 'Export-PSData', 'ConvertTo-ServiceUrl'



        }
 
        # The embed section contains them
        $embedSection = foreach ($func in Get-Command -Module Pipeworks -Name $FunctionsInEveryRunspace -CommandType Function) {
            issEmbed $func
        }


        $bootStrapperServerSideCode = @"
<%@ Assembly Name="System.Management.Automation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" %>

<%@ Import Namespace="System.Collections.ObjectModel" %>
<%@ Import Namespace="System.Management.Automation" %>
<%@ Import namespace="System.Management.Automation.Runspaces" %>
<script language="C#" runat="server">        
    public void runScript(string script) {
        PowerShell powerShellCommand = PowerShell.Create();
        bool justLoaded = false;
        Runspace runspace;
        if (Session["UserRunspace"] == null) {
            InitialSessionState iss = InitialSessionState.CreateDefault();
            $embedSection
            string[] commandsToRemove = new String[] { "$($functionBlacklist -join '","')"};
            foreach (string cmdName in commandsToRemove) {
                iss.Commands.Remove(cmdName, null);
            }
            
            Runspace rs = RunspaceFactory.CreateRunspace(iss);
            rs.ApartmentState = System.Threading.ApartmentState.STA;            
            rs.ThreadOptions = PSThreadOptions.ReuseThread;
            rs.Open();
            Session.Add("UserRunspace",rs);
            justLoaded = true;
        }

        runspace = Session["UserRunspace"] as Runspace;

        if (Application["Runspaces"] == null) {
            Application["Runspaces"] = new Hashtable();
        }
        if (Application["RunspaceAccessTimes"] == null) {
            Application["RunspaceAccessTimes"] = new Hashtable();
        }
        if (Application["RunspaceAccessCount"] == null) {
            Application["RunspaceAccessCount"] = new Hashtable();
        }

        Hashtable runspaceTable = Application["Runspaces"] as Hashtable;
        Hashtable runspaceAccesses = Application["RunspaceAccessTimes"] as Hashtable;
        Hashtable runspaceAccessCounter = Application["RunspaceAccessCount"] as Hashtable;
                
        if (! runspaceTable.Contains(runspace.InstanceId.ToString())) {
            runspaceTable[runspace.InstanceId.ToString()] = runspace;
        }

        if (! runspaceAccessCounter.Contains(runspace.InstanceId.ToString())) {
            runspaceAccessCounter[runspace.InstanceId.ToString()] = 0;
        }
        runspaceAccessCounter[runspace.InstanceId.ToString()] = ((int)runspaceAccessCounter[runspace.InstanceId.ToString()]) + 1;
        runspaceAccesses[runspace.InstanceId.ToString()] = DateTime.Now;

        
        runspace.SessionStateProxy.SetVariable("Request", Request);
        runspace.SessionStateProxy.SetVariable("Response", Response);
        runspace.SessionStateProxy.SetVariable("Session", Session);
        runspace.SessionStateProxy.SetVariable("Server", Server);
        runspace.SessionStateProxy.SetVariable("Cache", Cache);
        runspace.SessionStateProxy.SetVariable("Context", Context);
        runspace.SessionStateProxy.SetVariable("Application", Application);
        runspace.SessionStateProxy.SetVariable("JustLoaded", justLoaded);
        powerShellCommand.Runspace = runspace;

        PSInvocationSettings invokeWithHistory = new PSInvocationSettings();
        invokeWithHistory.AddToHistory = true;
        PSInvocationSettings invokeWithoutHistory = new PSInvocationSettings();
        invokeWithHistory.AddToHistory = false;



        if (justLoaded) {        
            powerShellCommand.AddCommand("Set-ExecutionPolicy", false).AddParameter("Scope", "Process").AddParameter("ExecutionPolicy", "Bypass").AddParameter("Force", true).Invoke(null, invokeWithoutHistory);
            powerShellCommand.Commands.Clear();
        }
        
        powerShellCommand.AddScript(@"
`$timeout = (Get-Date).AddMinutes(-20)
`$oneTimeTimeout = (Get-Date).AddMinutes(-1)
foreach (`$key in @(`$application['Runspaces'].Keys)) {
    if ('Closed', 'Broken' -contains `$application['Runspaces'][`$key].RunspaceStateInfo.State) {
        `$application['Runspaces'][`$key].Dispose()
        `$application['Runspaces'].Remove(`$key)
        continue
    }
    
    if (`$application['RunspaceAccessTimes'][`$key] -lt `$Timeout) {
        
        `$application['Runspaces'][`$key].CloseAsync()
        continue
    }    
}
").Invoke();

        powerShellCommand.Commands.Clear();

        powerShellCommand.AddCommand("Split-Path", false).AddParameter("Path", Request.ServerVariables["PATH_TRANSLATED"]).AddCommand("Set-Location").Invoke(null, invokeWithoutHistory);
        powerShellCommand.Commands.Clear();        


        try {
            Collection<PSObject> results = powerShellCommand.AddScript(script, false).Invoke();        
            foreach (Object obj in results) {
                if (obj != null) {
                    if (obj is IEnumerable and obj isnot String) {
                        foreach (Object innerObject in results) {
                            Response.Write(innerObject);
                        }
                    } else {
                        Response.Write(obj);
                    }
                    
                }
            }
            foreach (ErrorRecord err in powerShellCommand.Streams.Error) {
                Response.Write("<span class='ErrorStyle' style='color:red'>" + err + "<br/>" + err.InvocationInfo.PositionMessage + "</span>");
            }

        } catch (Exception exception) {
            Response.Write("<span class='ErrorStyle' style='color:red'>" + exception.Message + "</span>");
        } finally {
            powerShellCommand.Dispose();
        }
    }
</script>
"@        
    }
    
    process {
        if ($psCmdlet.ParameterSetName -eq 'BootStrapper') {
            $bootStrapperServerSideCode
        } elseif ($psCmdlet.ParameterSetName -eq 'ScriptBlock') {
                        
            if (-not $NoBootstrapper) {
            @"
<%@ $(if ($IsMasterPage) {'Master'} else {'Page'}) Language="C#" AutoEventWireup="True" $masterPageDirective $(if ($CodeFile) { "CodeFile='$CodeFile'" } $(if ($inherit) { "Inherits='$Inherit'" }))%>
$bootStrapperServerSideCode 
$(if ($MasterPage) { '<asp:Content runat="server">' } else {'<%' })
runScript(@"$($scriptBlock.ToString().Replace('"','""'))"); 
$(if ($MasterPage) { '</asp:Content>' } else {'%>'})

"@            
            } else {
                        @"
<%@ $(if ($IsMasterPage) {'Master'} else {'Page'}) Language="C#" AutoEventWireup="True" $masterPageDirective $(if ($CodeFile) { "CodeFile='$CodeFile'" } $(if ($inherit) { "Inherits='$Inherit'" }))%>
<% runScript(@"$($scriptBlock.ToString().Replace('"','""'))"); %>
"@            

            }
            
        } elseif ($psCmdlet.ParameterSetName -eq 'Text') {
            if (-not $NoBootstrapper) {
            @"
<%@ $(if ($IsMasterPage) {'Master'} else {'Page AutoEventWireup="True" '}) Language="C#" $masterPageDirective $(if ($CodeFile) { "CodeFile='$CodeFile'" } $(if ($inherit) { "Inherits='$Inherit'" }))%>

$bootStrapperServerSideCode 
$Text
"@            
            } else {
                        @"
<%@ $(if ($IsMasterPage) {'Master'} else {'Page AutoEventWireup="True"'}) Language="C#" $masterPageDirective $(if ($CodeFile) { "CodeFile='$CodeFile'" } $(if ($inherit) { "Inherits='$Inherit'" }))%>
<%@ Assembly Name="System.Management.Automation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" %>

$Text
"@            

            }
            
        }
    }
}




# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUB26o7fVC/O0eDZPb/CZLQGaq
# NTqgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCbY75//8vBAwDko
# 6/9mtfeW6SJ0MA0GCSqGSIb3DQEBAQUABIIBAJsu1sgoTVZGMD+JY3vgqqLr0wGP
# 7FHZp/mpi63KVlO/cCymKL8KwXZY7ELNLug0oDBj0Dr3aVvONCzv2MHlMrzMyAKB
# qaMfSzZR0m/ZaIkBPRNosM2pbd8XcXtNGfmALkV12dPhW+qaqxIjrqkCDGCgcXCF
# BXWzbaXab1kS+TTA9IA93wgG2Bqu2BivLNubnyQP2yPJzW1CW9EOxBhdB2T2PAeb
# 4Ea2lEBN5zr6TUnEZa7DQ8CHYZX3A7ttV+Pt116Wf6rHPYOwhv7NZUj7GLHWt0w5
# rohMNlpWBtgQDYgaZSFBncZFhM2VOosym4sRXM8farw0ZznWdeY2DhF2DxA=
# SIG # End signature block
