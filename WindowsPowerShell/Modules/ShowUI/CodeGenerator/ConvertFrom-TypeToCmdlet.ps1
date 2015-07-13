function ConvertFrom-TypeToScriptCmdlet
{
    <#
    .Synopsis
        Converts .NET Types into Windows PowerShell Script Cmdlets
        according to a number of rules. that have been added with Add-CodeGeneration rule
    .Description
        Converts .NET Types into Windows PowerShell Script Cmdlets
        according to a number of rules.
        
        Rules are added with Add-CodeGenerationRule                  
    #>
    param(
    [Parameter(ValueFromPipeline=$true)]
    [Type[]]$Type,
       
    [Switch]$AsScript,
        
    [Switch]$AsCSharp,
    
    [ref]$ConstructorCmdletNames
    )        
    
    begin {
        $LinkedListType = "Collections.Generic.LinkedList"
        Set-StrictMode -Off
        # Default as Script
        if(!$AsScript) {
            $AsCSharp = $true
        }
    }
    
    process {
        foreach ($t in $type) {
            $Parameters = 
                New-Object "$LinkedListType[Management.Automation.ParameterMetaData]"
            $BeginBlocks = 
                New-Object "$LinkedListType[ScriptBlock]"
            $ProcessBlocks = 
                New-Object "$LinkedListType[ScriptBlock]"
            $EndBlocks = 
                New-Object "$LinkedListType[ScriptBlock]"
            if ($PSVersionTable.BuildVersion.Build -lt 7100) {
                $CmdletBinding = "[CmdletBinding()]"
            } else {
                $CmdletBinding = ""
            }
            try {
                $Help = @{
                    Parameter = @{}
                }
                $Verb = ""
                $Noun = ""
                
                $BaseType = $t            

                foreach ($rule in $CodeGenerationRuleOrder) {
                    if (-not $rule) { continue } 
                    if ($rule -is [Type] -and 
                        (($t -eq $rule) -or ($t.IsSubclassOf($rule)))) {
                        $nsb = $ExecutionContext.InvokeCommand.NewScriptBlock($codeGenerationCustomizations[$rule])
                        $null = . $nsb 
                    } else {
                        if ($rule -is [ScriptBlock] -and
                            ($t | Where-Object -FilterScript $rule)) {
                            $nsb = $ExecutionContext.InvokeCommand.NewScriptBlock($codeGenerationCustomizations[$rule])
                            $null = . $nsb 
                        }
                    }
                }
            } catch {
                Write-Error "Problem building $t"
                Write-Error $_
            }
            
            if ((-not $Noun) -or (-not $Verb)) {
                continue
            }
            
            ## A hack to get a list of constructor cmdlets
            if($Verb -eq "New" -and (Test-Path Variable:ConstructorCmdletNames)) {
               $ConstructorCmdletNames.Value.Add( $Noun )
            }
            
            $cmd = New-Object Management.Automation.CommandMetaData ([PSObject])
            foreach ($p in $parameters) {
                $null = $cmd.Parameters.Add($p.Name, $p)
            }
            
            if ($AsScript) {
                #region Generate the Script Parameter Block
                $parameterBlock = [Management.Automation.ProxyCommand]::GetParamBlock($cmd)

                #endregion
                
                #region Generate the Help                                
                $oldOfs = $ofs
                $ofs = ""
                $helpBlock = New-Object Text.StringBuilder
                $parameterNames = "Parameter", 
                    "ForwardHelpTargetName",
                    "ForwardHelpCategory",
                    "RemoteHelpRunspace",
                    "ExternalHelp",
                    "Synopsis",
                    "Description",
                    "Notes",
                    "Link",
                    "Example",
                    "Inputs",
                    "Outputs",
                    "Component",
                    "Role",
                    "Functionality"
                if ($help.Synopsis -and $help.Description) {
                    foreach ($key in $help.Keys) {
                        if ($parameterNames -notcontains $key) {
                            Write-Error "Could not generate help for $t.  The Help dictionary contained a key ($key) that is not a valid help section"
                            break
                        }                
                    }                
                    foreach ($kv in $help.GetEnumerator()) {
                        switch ($kv.Key) {
                            Parameter {
                                foreach ($p in $kv.Value.GetEnumerator()) {
                                    if (-not $p) { continue } 
                                        $null = $helpBlock.Append(
        "
        .Parameter $($p.Key)
            $($p.Value)")
                                }                        
                            }
                            Example {
                                foreach ($ex in $kv.Value) {
                                    $null = $helpBlock.Append(
        "
        .Example
            $ex")                        
                                
                                }
                            }
                            default {
                                $null = $helpBlock.Append(
        "
        .$($kv.Key)
            $($kv.Value)")                        
                            }
                        }
                    }
                }
                $helpBlock = "$helpBlock"
                if ($helpBlock) {
                    $helpBlock = "
        <#
        $HelpBlock
        #>
    "
                }
                
                #endregion

                #region Generate Final Script Code
@"
    function $Verb-$Noun {
        $HelpBlock
        
        $CmdletBinding
        param(
            $parameterBlock
        )
        begin {
            $BeginBlocks
        }
        process {
            $ProcessBlocks
        }
        end {
            $EndBlocks
        }
    }
"@            
                #endregion 
            } elseif ($AsCSharp) {
                
                #region Generate the C# Parameter Block
                $usingBlock = New-Object Text.StringBuilder
                $null = $usingBlock.Append("
using System;
using System.Collections;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
// using ShowUI;

")                
                $propertyBlock = New-Object Text.StringBuilder
                $fieldBlock = New-Object Text.StringBuilder
                
                $null = $fieldBlock.Append(@"
        /// <summary>
        /// A Field to store the pipeline used to invoke the commands
        /// </summary>
        private Pipeline pipeline;    
"@)
                
                $defaultParameterPosition =0 
                $namespaces = "$usingBlock" -split ([Environment]::NewLine) | 
                    Where-Object { $_ } | 
                    ForEach-Object { $_.Trim().Replace("using ", "").Replace(";","") 
                } 
                
                $parameterNames = $parameters | Select-Object -ExpandProperty Name

                foreach ($p in $parameters) {
                    if (-not $p) { continue } 
                    # declare the field
                    $parameterName = $fieldName = $p.Name
                    
                    $fieldName = $fieldName.ToCharArray()[0].ToString().ToLower() + 
                        $fieldName.Substring(1)
                    $PropertyName = $fieldName.ToCharArray()[0].ToString().ToUpper() + 
                        $fieldName.Substring(1)
                                                            
                    $parameterType = $p.ParameterType
                    if (-not $parameterType) { $parameterType = [PSObject] } 
                    $parameterTypeFullName = $parameterType.Fullname
                    $parameterNamespace = $parameterType.Namespace    
                    
                    if ($namespaces -notcontains $parameterNamespace) {
                        $null = $usingBlock.AppendLine("using $parameterNamespace;")
                        $namespaces = "$usingBlock" -split ([Environment]::NewLine) | 
                            Where-Object { $_ } | 
                            ForEach-Object { $_.Trim().Replace("using ", "").Replace(";","") 
                        } 
                    }                     
                    $fieldType = $p.Property
                    
                    $parameterAttributes = $p.Attributes | 
                        Where-Object { 
                            $_ -is [Management.Automation.ParameterAttribute] 
                        } |
                        ForEach-Object {
                            $attributeParts = @()
                            $item = $_
                            if ($item.Position -ge 0) { 
                                $attributeParts+="Position=$($item.Position)"
                            }
                            if ($item.ParameterSetName -ne '__AllParameterSets') {
                                $attributeParts+="ParameterSetName=$($item.ParameterSetName)"
                            }
                            if ($item.Mandatory) {
                                $attributeParts+="Mandatory=true"                            
                            }
                            if ($item.ValueFromPipeline) {
                                $attributeParts+="ValueFromPipeline=true"                            
                            }
                            if ($item.ValueFromPipelineByPropertyName) {
                                $attributeParts+="ValueFromPipelineByPropertyName=true"
                            }
                            if ($item.ValueFromRemainingArguments) {
                                $attributeParts+="ValueFromRemainingArguments=true"
                            }
                            if ($item.HelpMessage) {
                                $attributeParts+="HelpMessage=@`"$($item.HelpMessage)`""
                            }
                            if ($item.HelpMessageBaseName) {
                                $attributeParts+="HelpMessageBaseName=@`"$($item.HelpMessageBaseName)`""
                            }
                            if ($item.HelpMessageResourceId) {
                                $attributeParts+="HelpMessageResourceId=@`"$($item.HelpMessageResourceId)`""
                            }
                            $ofs = ","
                            "[Parameter($attributeParts)]"
                        }
                    
                    if (-not $parameterAttributes) {
                        # In this case, the parameter is not mandatory, 
                        # and will be marked ValueFromPipelineByPropertyName and will assume the first default position                        
                        $parameterAttributes += "[Parameter(Position=$defaultParameterPosition)]"
                        $defaultParameterPosition++
                    }
                    $ofs = [Environment]::NewLine
                    $ParameterDeclaration = "$parameterAttributes"            

                    $null = $propertyBlock.Append("
        /// <summary>
        /// Gets or sets the $PropertyName property, which holds the value for the $ParameterName
        /// </summary>
        $ParameterDeclaration
        public $parameterTypeFullName $PropertyName { get; set; }
")     
                }

                
                #endregion   
                
                #region Create the Begin/Process/End code chunks
                
                # The trick here is InvokeScript.  
                # Each of the Begin/Process/End effectively becomes an InvokeScript, 
                # with all of the values passed in as positional arguments                 
                
                
                $pNames=  @("BoundParameters") + $parameterNames
                $ofs = ',$'
                $parameterDeclaration = "param(`$$pNames)"
                                
                $beginBlocks = @($beginBlocks)
                $processBlocks = @($processBlocks)
                $endBlocks = @($endBlocks)
                $beginProcessingCode = ""
                
                if ($beginBlocks)  {
                    $ofs = [Environment]::NewLine                
                    $fullBeginBlock = "
$parameterDeclaration
$beginBlocks".Replace('"','""')

                    $ofs =','
                
                    $beginProcessingCode = @"
                    System.Collections.Generic.Dictionary<string,Object> BoundParameters = this.MyInvocation.BoundParameters;
this.InvokeCommand.InvokeScript(@"
$fullBeginBlock
", new Object[] { $pNames } );
"@                

                }
                
                $endProcessingCode = ""
                if ($endBlocks) {
                    $ofs = [Environment]::NewLine                
                    $fullEndBlock = "
$parameterDeclaration
$endBlocks".Replace('"','""')

                    $ofs =','
                
                    $EndProcessingCode = New-Object Text.StringBuilder
                    $null = $EndProcessingCode.Append(@"
System.Collections.Generic.Dictionary<string,Object> BoundParameters = this.MyInvocation.BoundParameters;
                    PSLanguageMode languageMode = this.SessionState.LanguageMode;
                    if (languageMode != PSLanguageMode.Full) {
                        this.SessionState.LanguageMode=PSLanguageMode.FullLanguage;
                    }
                    pipeline.Commands.AddScript(@"
$fullEndBlock
", true);

                    foreach (System.Collections.Generic.KeyValuePair<string,Object> param in this.MyInvocation.BoundParameters) {
                        pipeline.Commands[0].Parameters.Add(param.Key, param.Value);                    
                    }
                    
                    try {
                        this.WriteObject(
                            pipeline.Invoke(),
                            true);

                    } catch (Exception ex) {
                        ErrorRecord errorRec; 
                        if (ex is ActionPreferenceStopException) {
                            ActionPreferenceStopException aex = ex as ActionPreferenceStopException;
                            errorRec = aex.ErrorRecord;
                        } else {
                            errorRec = new ErrorRecord(ex, "EmbeddedProcessRecordError", ErrorCategory.NotSpecified, null);                        
                        }                       
                        if (errorRec != null) {
                            this.WriteError(errorRec);                                                
                        }
                    }
                    
                    if (languageMode != PSLanguageMode.FullLanguage) {
                        this.SessionState.LanguageMode=languageMode;
                    }
"@)                    
                    foreach ($param in $parameterNames) {
                        $null = $EndProcessingCode.Append(@"
this.SessionState..PSVariable.Remove("$param");
"@)                     
                    }
                }
                
                $ProcessRecordCode=""
                if ($processBlocks) {
                    $ofs = [Environment]::NewLine                
                    $fullProcessBlock = "
$parameterDeclaration
$processBlocks".Replace('"','""')

                    $ofs =','
   
                    $ProcessRecordCode = @"
                    System.Collections.Generic.Dictionary<string,Object> BoundParameters = this.MyInvocation.BoundParameters;
                    PSLanguageMode languageMode = this.SessionState.LanguageMode;
                    if (languageMode != PSLanguageMode.FullLanguage) {
                        this.SessionState.LanguageMode=PSLanguageMode.FullLanguage;
                    }
                    
                    pipeline.Commands.AddScript(@"
$fullProcessBlock
", true);

                    foreach (System.Collections.Generic.KeyValuePair<string,Object> param in this.MyInvocation.BoundParameters) {
                        pipeline.Commands[0].Parameters.Add(param.Key, param.Value);                    
                    }
                    
                    try {
                        this.WriteObject(
                            pipeline.Invoke(),
                            true);

                    } catch (Exception ex) {
                        ErrorRecord errorRec; 
                        if (ex is ActionPreferenceStopException) {
                            ActionPreferenceStopException aex = ex as ActionPreferenceStopException;
                            errorRec = aex.ErrorRecord;
                        } else {
                            errorRec = new ErrorRecord(ex, "EmbeddedProcessRecordError", ErrorCategory.NotSpecified, null);                        
                        }                       
                        if (errorRec != null) {
                            this.WriteError(errorRec);                                                
                        }
                    }
                    if (languageMode != PSLanguageMode.FullLanguage) {
                        this.SessionState.LanguageMode=languageMode;
                    }


"@                

                }
                #endregion
                
                #region Generate the final cmdlet                                                                             
$namespaceID = Get-Random
@"
namespace AutoGenerateCmdlets$namespaceID
{
    $usingBlock

    [Cmdlet("$Verb", "$Noun")]
    [OutputType(typeof($($BaseType.FullName)))]
    public class ${Verb}${Noun}Command : PSCmdlet 
    {
        $fieldBlock
        $propertyBlock
        
        protected override void BeginProcessing()
        {
            pipeline = Runspace.DefaultRunspace.CreateNestedPipeline();
                
            $BeginProcessingCode
        }    

        protected override void ProcessRecord() 
        {
            pipeline.Commands.Clear();            
            $ProcessRecordCode
        }

        protected override void EndProcessing() 
        {
            $EndProcessingCode
            pipeline.Dispose();
        }
    }           
}
"@
                #endregion
            }
        }        
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUIFpFFzYQpQ1EyCK71PeLlIEt
# thSgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFISJmjSdye/wFsvY
# K/GJvTzL2qunMA0GCSqGSIb3DQEBAQUABIIBAKaTZYW35dP7ziucLJr+/vwd0Y3z
# jhjhK0kZH4bPX4hsT9zERr6DIG8NeiQEHzC4pLMCWjBcRVxRplJvzOf0swt5DESC
# +ifIAQKbYuLq5g/TgWe0QZOo7J76CCy0jWfAImyvtIDKJcMxL5PXG6mRpy5QWBYU
# ShX/yIMVfx5b2FYKydUAzl12n7+zXWFDEcaxq6VmAbQMWrXK0DKGqmdqT80TTIBX
# CXGsF4VPXa76iECuhfyBTiKu1n92ZfTU0tipOOagdGXsN6IVRSovRe3XIHHGezn1
# 7xyyVYT0VODsJVcwV07g0+kSW0ACaqqvINBOmh7pKcXeVcxbZefPkuyA3b0=
# SIG # End signature block
