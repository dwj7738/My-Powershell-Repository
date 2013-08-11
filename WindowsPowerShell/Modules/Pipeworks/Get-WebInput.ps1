function Get-WebInput
{
    <#
    .Synopsis
        Get the Web Request parameters for a PowerShell command
    .Description
        Get the Web Request parameters for a PowerShell command.  
        
        Script Blocks parameters will automatically be run, and text values will be converted
        to their native types.
    .Example
        Get-WebInput -CommandMetaData (Get-Command Get-Command) -DenyParameter ArgumentList
    .Link
        Request-CommandInput
    #>
    [OutputType([Hashtable])]
    param(
    # The metadata of the command that is being wrapped
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [Management.Automation.CommandMetaData]
    $CommandMetaData,
    
    # The parameter set within the command
    [string]
    $ParameterSet,    
    
    # Explicitly allowed parameters (by default, all are allowed unless they are explictly denied)
    [string[]]
    $AllowedParameter,
    
    # Explicitly denied parameters.
    [string[]]
    $DenyParameter,
    
    # Any aliases for parameter names.
    [Hashtable]$ParameterAlias,
    
    # A UI element containing that will contain all of the values.  If this option is used, the module ShowUI should also be loaded.
    $Control        
    )
    
    process {
        $webParameters = @{}
        $safecommandName = $commandMetaData.Name.Replace("-", "")
        $webParameterNames = $commandMetaData.Parameters.Keys
        $webParameterNames = $webParameterNames  |
            Where-Object { $DenyParameter -notcontains $_ } | 
            ForEach-Object -Begin {
                if ($ParameterAlias) { 
                    foreach ($k in $ParameterAlias.Keys) { $k }  
                } 
            } -Process { 
                if ($_ -ne "URL") {
                } else {
                }
                "$($CommandMetaData.Name)_$_" 
            }
        
        
        if ($request.Params -is [Hashtable]) {
            
            $paramNames = $request.Params.Keys
            $global:ParameterList = $paramNAmes
        } else {
            $paramNames = @($request.Params) + ($request.Files)
            $global:ParameterList = $paramNAmes
            
        }
        
        
        if ($Control) {
            
            if (-not $ExecutionContext.SessionState.InvokeCommand.GetCommand("Get-ChildControl", "All")) {
                
                return
            }
            
            $uiValue = @{}
            $uivalue = Get-ChildControl -Control $control -OutputNamedControl
            
            foreach ($kv in @($uivalue.GetEnumerator())) {
                if (($kv.Key -notlike "${SafeCommandName}_*")) {
                    $uiValue.Remove($kv.Key)
                }
            }

            
            
            foreach ($kv in @($uiValue.GetEnumerator())) {
                if ($kv.Value.Text) {
                    $uiValue[$kv.Key] = $kv.Value.Text
                } elseif ($kv.Value.SelectedItems) {
                    $uiValue[$kv.Key] = $kv.Value.SelectedItems
                } elseif ($kv.Value -is [Windows.Controls.Checkbox] -and $kv.Value.IsChecked) {
                    $uiValue[$kv.Key] = $kv.Value.IsChecked
                } else {
                    $uiValue.Remove($kv.Key)
                }
            }
            $webParameterNames = $webParameterNames |
                ForEach-Object {
                    $_.Replace("-","")
                }
            $paramNames = $uiValue.Keys |
                ForEach-Object { $_.Trim() }                         
            
        }
        
        
        
        
        foreach ($param in $paramNames) {            
            
            if ($webParameterNames -notcontains $param) { 
                continue 
            } 
            
            if ($request.Params -is [Hashtable]) {                
                $value = $request.Params[$param]
            } elseif ($request) {                
                $value = $request[$param]
                if (-not $value -and $request.Files) {
                    $value =  $request.Files[$param]
                }
            } elseif ($uiValue) {                
                $value = $uiValue[$param]                               
            }
            
            if (-not $value) { 
                if ([string]::IsNullOrEmpty($value)) {
                    continue
                }
                if ($value -ne 0){ 
                    # Do not skip the the value is really 0
                    continue 
                }
                
            }            
            
            if ($value.Trim()[-1] -eq '=') {
                # Make everything handle base64 input (as long as it's not to short to be an accident)
                $valueFromBase64 = try { 
                    [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($value))
                } catch {
                
                }
            }
            
            # If the value was passed in base64, convert it
            if ($valueFromBase64) { 
                $value = $valueFromBase64 
            } 
            
            # If there was no value, quit
            if (-not $value) { continue }                         
                

            if ($parameterAlias -and $parameterAlias[$param]) {
                $realParamName = $parameterAlias[$param]
                
            } else {
                $realParamName= $param -iReplace 
                    "$($CommandMetaData.Name)_", "" -ireplace 
                    "$($commandMetaData.Name.Replace('-',''))_", ""
                
            }   
            
            #region Coerce Type
                         
            $expectedparameterType = $commandMetaData.Parameters[$realParamName].ParameterType                        
            if ($expectedParameterType -eq [ScriptBlock]) {
                # Script Blocks are converted after being trimmed.                
                $valueAsType = [ScriptBlock]::Create($value.Trim())                
                
                if ($valueAsType -and ($valueAsType.ToString().Length -gt 1)) {
                    $webParameters[$realParamName] = $valueAsType
                }
                
            } elseif ($expectedParameterType -eq [Security.SecureString]) {
                $trimmedValue = $value.Trim()

                if ($trimmedValue) {
                    $webParameters[$realParamName]  = ConvertTo-SecureString -AsPlainText -Force $trimmedValue
                }
            } elseif ([switch], [bool] -contains $expectedParameterType) {
                # Switches and bools do a check for false, otherwise true
                if ($value -ilike "false") {
                    $webParameters[$realParamName]  = $false
                } else {
                    $webParameters[$realParamName] = $true
                }
            } elseif ($ExpectedParameterType.IsArray) {
                # If it's an array, split each line and coerce the line into the correct type
                if ($expectedparameterType -eq [string[]] -or                    
                    $expectedparameterType -eq [ScriptBlock[]]) {
                    # String arrays are split on | or newlines
                    $valueAsType = @($value -split "[$([Environment]::NewLine)|]" -ne '' | ForEach-Object { $_.Trim() }) -as $expectedParameterType
                } elseif ($expectedParameterType -eq [Byte[]]) {
                    
                    

                    $is = $value.InputStream
                    $buffer = New-Object Byte[] $is.Length
                    $read = $is.Read($buffer, 0, $is.Length) 
        

                    $buffer
                } else {
                    # Everything else is split on |, newlines, or commas

                    $valueAsType = @($value -split "[$([Environment]::NewLine)|,]" | ForEach-Object { $_.Trim() }) -as $expectedParameterType
                }
                
                if ($valueAsType) {
                    $webParameters[$realParamName] = $valueAsType
                }
            } elseif ($ExpectedParameterType -eq [Hashtable] -or 
                $expectedparameterType -eq [Hashtable[]]) {
            
                $trimmedValue = $value.Trim()
                if ($trimmedValue -like "*@{*") {
                    $asScriptBlock = try { [ScriptBlock]::Create($trimmedValue) } catch { } 
                    if (-not $asScriptBlock) { continue } 
                        
                    # If it's a script block, make a data language block around it, and catch 
                    $asDataLanguage= try { [ScriptBlock]::Create("data { 
                        $asScriptBlock 
                    }") } catch { }
                    if  (-not $asDataLanguage) { continue } 
                        
                    # Run the data language block
                    $webParameters[$realParamName] =  & $asDataLanguage 
                } elseif ($trimmedValue) {
                    $fromStringData = ConvertFrom-StringData -StringData $value 
                    $webParameters[$realParamName] = $fromStringData
                }
                
            } else {
                if ($expectedParameterType) {
                    $valueAsType = $value -as $expectedparameterType
                    if ($valueAsType) {
                        $webParameters[$realParamName] = $valueAsType
                    }
                } else {
                    $webParameters[$realParamName] = $value
                }
                
            }        
            
            #endregion Coerce Type
            	
        }
        
        $finalParams = @{}

        foreach ($wp in $webParameters.GetEnumerator()) {
            if (-not $wp) {continue } 
            if (-not $wp.Value) { continue } 
            $finalParams[$wp.Key] = $wp.Value
        }
        
        $finalParams
    }
}
