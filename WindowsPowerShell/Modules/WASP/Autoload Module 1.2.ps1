#Requires -Version 2.0
## Automatically load functions from scripts on-demand, instead of having to dot-source them ahead of time, or reparse them from the script every time.
## Provides significant memory benefits over pre-loading all your functions, and significant performance benefits over using plain scripts.  Can also *inject* functions into Modules so they inherit the module scope instead of the current local scope.
## Please see the use example in the script below

## Version History
## v 1.2  - 2011.05.02
##        - Exposed the LoadNow alias and the Resolve-Autoloaded function
## v 1.1  - 2011.02.09
##          Added support for autoloading scripts (files that don't have a "function" in them)
## v 1.0  - 2010.10.20
##          Officially out of beta -- this is working for me without problems on a daily basis.
##          Renamed functions to respect the Verb-Noun expectations, and added Export-ModuleMember
## beta 8 - 2010.09.20
##          Finally fixed the problem with aliases that point at Invoke-Autoloaded functions!
## beta 7 - 2010.06.03
##          Added some help, and a function to force loading "now"
##          Added a function to load AND show the help...
## beta 6 - 2010.05.18
##          Fixed a bug in output when multiple outputs happen in the END block
## beta 5 - 2010.05.10
##          Fixed non-pipeline use using $MyInvocation.ExpectingInput
## beta 4 - 2010.05.10
##          I made a few tweaks and bug fixes while testing it's use with PowerBoots.
## beta 3 - 2010.05.10
##          fix for signed scripts (strip signature)
## beta 2 - 2010.05.09
##          implement module support
## beta 1 - 2010.04.14
##          Initial Release


## To use:
## 1) Create a function. To be 100% compatible, it should specify pipeline arguments
## For example:
<#
function Skip-Object {
param( 
   [int]$First = 0, [int]$Last = 0, [int]$Every = 0, [int]$UpTo = 0,  
   [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
   $InputObject
)
begin {
   if($Last) {
      $Queue = new-object System.Collections.Queue $Last
   }
   $e = $every; $UpTo++; $u = 0
}
process {
   $InputObject | where { --$First -lt 0 } | 
   foreach {
      if($Last) {
         $Queue.EnQueue($_)
         if($Queue.Count -gt $Last) { $Queue.DeQueue() }
      } else { $_ }
   } |
   foreach { 
      if(!$UpTo) { $_ } elseif( --$u -le 0) {  $_; $U = $UpTo }
   } |
   foreach { 
      if($every -and (--$e -le 0)) {  $e = $every  } else { $_ } 
   }
}
}
#>

## 2) Put the function into a script (for our example: C:\Users\${Env:UserName}\Documents\WindowsPowerShell\Scripts\SkipObject.ps1 )
## 3) Import the Autoload Module
## 5) Run this command (or add it to your profile):
<#
New-Autoload C:\Users\${Env:UserName}\Documents\WindowsPowerShell\Scripts\SkipObject.ps1 Skip-Object
#>

## This tells us that you want to have that function loaded for you out of the script file if you ever try to use it.
## Now, you can just use the function:
## 1..10 | Skip-Object -first 2 -upto 2

function Invoke-Autoloaded {
#.Synopsis
#	This function was autoloaded, but it has not been parsed yet.
#  Use Get-AutoloadHelp to force parsing and get the correct help (or just invoke the function once).
#.Description
#   You are seeing this help because the command you typed was imported via the New-Autoload command from the Autoload module.  The script file containing the function has not been loaded nor parsed yet. In order to see the correct help for your function we will need to parse the full script file, to force that at this time you may use the Get-AutoloadHelp function.
#
#   For example, if your command was Get-PerformanceHistory, you can force loading the help for it by running the command: Get-AutoloadHelp Get-PerformanceHistory
   [CmdletBinding()]Param()
   DYNAMICPARAM {
      $CommandName = $MyInvocation.InvocationName
	   return Resolve-Autoloaded $CommandName
   }#DynamicParam

   begin {
      Write-Verbose "Command: $CommandName"
      if(!$Script:AutoloadHash[$CommandName]) {
         do {
            $Alias = $CommandName
            $CommandName = Get-Alias $CommandName -ErrorAction SilentlyContinue | Select -Expand Definition
            Write-Verbose "Invoke-Autoloaded Begin: $Alias -> $CommandName"
         } while(!$Script:AutoloadHash[$CommandName] -and (Get-Alias $CommandName -ErrorAction SilentlyContinue))
      } else {
         Write-Verbose "CommandHash: $($Script:AutoloadHash[$CommandName])"
      }
      if(!$Script:AutoloadHash[$CommandName]) { throw "Unable to determine command!" }

      $ScriptName, $ModuleName, $FunctionName = $Script:AutoloadHash[$CommandName]
      Write-Verbose "Invoke-Autoloaded Begin: $Alias -> $CommandName -> $FunctionName"
      
      
      #Write-Host "Parameters: $($PSBoundParameters | ft | out-string)" -Fore Magenta
   
      $global:command = $ExecutionContext.InvokeCommand.GetCommand( $FunctionName, [System.Management.Automation.CommandTypes]::Function )
      Write-Verbose "Autoloaded Command: $($Command|Out-String)"
      $scriptCmd = {& $command @PSBoundParameters | Write-Output }
      $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
      $steppablePipeline.Begin($myInvocation.ExpectingInput)
   }
   process
   {
      Write-Verbose "Invoke-Autoloaded Process: $CommandName ($_)"
      try {
         if($_) {
            $steppablePipeline.Process($_)
         } else {
            $steppablePipeline.Process()
         }
      } catch {
         throw
      }
   }

   end
   {
      try {
         $steppablePipeline.End()
      } catch {
         throw
      }
      Write-Verbose "Invoke-Autoloaded End: $CommandName"
   }
}#Invoke-Autoloaded


function Get-AutoloadHelp {
	[CmdletBinding()]
	Param([Parameter(Mandatory=$true)][String]$CommandName)
	$null = Resolve-Autoloaded $CommandName
	Get-Help $CommandName
}

function Resolve-Autoloaded {
[CmdletBinding()]
param(
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
[Alias("Name")]
[String]$CommandName
)
      $OriginalCommandName = "($CommandName)"
      Write-Verbose "Command: $CommandName"
      if(!$Script:AutoloadHash[$CommandName]) {
         do {
            $Alias = $CommandName
            $CommandName = Get-Alias $CommandName -ErrorAction SilentlyContinue | Select -Expand Definition
            $OriginalCommandName += "($CommandName)"
            Write-Verbose "Resolve-Autoloaded Begin: $Alias -> $CommandName"
         } while(!$Script:AutoloadHash[$CommandName] -and (Get-Alias $CommandName -ErrorAction SilentlyContinue))
      } else {
         Write-Verbose "CommandHash: $($Script:AutoloadHash[$CommandName])"
      }
      if(!$Script:AutoloadHash[$CommandName]) { throw "Unable to determine command $OriginalCommandName!" }
      
      Write-Verbose "Resolve-Autoloaded DynamicParam: $CommandName from $($Script:AutoloadHash[$CommandName])"
      $ScriptName, $ModuleName, $FunctionName = $Script:AutoloadHash[$CommandName]
      Write-Verbose "Autoloading:`nScriptName: $ScriptName `nModuleName: $ModuleName `nFunctionName: $FunctionName"
      
      if(!$ScriptName){ $ScriptName = $CommandName }
      if(!$FunctionName){ $FunctionName = $CommandName }
      if($ModuleName) {
         $Module = Get-Module $ModuleName
      } else { $Module = $null }
      
      
      ## Determine the command name based on the alias used to invoke us
      ## Store the parameter set for use in the function later...
      $paramDictionary = new-object System.Management.Automation.RuntimeDefinedParameterDictionary
      
      #$externalScript = $ExecutionContext.InvokeCommand.GetCommand( $CommandName, [System.Management.Automation.CommandTypes]::ExternalScript )
      $externalScript = Get-Command $ScriptName -Type ExternalScript | Select -First 1
      Write-Verbose "Processing Script: $($externalScript |Out-String)"
      $parserrors = $null
      $prev = $null
      $script = $externalScript.ScriptContents
      [System.Management.Automation.PSToken[]]$tokens = [PSParser]::Tokenize( $script, [ref]$parserrors )
      [Array]::Reverse($tokens)
      
      $function = $false
      ForEach($token in $tokens) {
         if($prev -and $token.Content -eq "# SIG # Begin signature block") {
            $script = $script.SubString(0, $token.Start )
         }
         if($prev -and $token.Type -eq "Keyword" -and $token.Content -ieq "function" -and $prev.Content -ieq $FunctionName ) {
            $script = $script.Insert( $prev.Start, "global:" )
            $function = $true
            Write-Verbose "Globalized: $($script[(($prev.Start+7)..($prev.Start + 7 +$prev.Content.Length))] -join '')"
         }
         $prev = $token
      }
      
      if(!$function) {
         $script = "function global:$Functionname { $script }"
      }
      
      if($Module) {
         $script = Invoke-Expression "{ $Script }"
         Write-Verbose "Importing Function into $($Module) module."
         &$Module $Script | Out-Null
         $command = Get-Command $FunctionName -Type Function
         Write-Verbose "Loaded Module Function: $($command | ft CommandType, Name, ModuleName, Visibility|Out-String)"
      } else {
         Write-Verbose "Importing Function without module."
         Invoke-Expression $script | out-null
         $command = Get-Command $FunctionName -Type Function
         Write-Verbose "Loaded Local Function: $($command | ft CommandType, Name, ModuleName, Visibility|Out-String)"
      }
      if(!$command) {
         throw "Something went wrong autoloading the $($FunctionName) function. Function definition doesn't exist in script: $($externalScript.Path)"
      }
      
      if($CommandName -eq $FunctionName) {
         Remove-Item Alias::$($CommandName)
         Write-Verbose "Defined the function $($FunctionName) and removed the alias $($CommandName)"
      } else {
         Set-Alias $CommandName $FunctionName -Scope Global
         Write-Verbose "Defined the function $($FunctionName) and redefined the alias $($CommandName)"
      }
      foreach( $pkv in $command.Parameters.GetEnumerator() ){
         $parameter = $pkv.Value
         if( $parameter.Aliases -match "vb|db|ea|wa|ev|wv|ov|ob" ) { continue } 
         $param = new-object System.Management.Automation.RuntimeDefinedParameter( $parameter.Name, $parameter.ParameterType, $parameter.Attributes)
         $paramdictionary.Add($pkv.Key, $param)
      } 
      return $paramdictionary
}

function New-Autoload {
[CmdletBinding()]
param(
   [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   [string[]]$Name
,
   [Parameter(Position=1,Mandatory=$False,ValueFromPipelineByPropertyName=$true)]
   [Alias("BaseName")]
   $Alias = $Name
,
   [Parameter(Position=2,Mandatory=$False,ValueFromPipelineByPropertyName=$true)]
   $Function = $Alias
,
   [Parameter(Position=3,Mandatory=$false)]
   [String]$Module
,
   [Parameter(Mandatory=$false)]
   [String]$Scope = '2'
  
)
begin {
   $xlr8r = [psobject].assembly.gettype("System.Management.Automation.TypeAccelerators")
   if(!$xlr8r::Get["PSParser"]) {
      if($xlr8r::AddReplace) { 
         $xlr8r::AddReplace( "PSParser", "System.Management.Automation.PSParser, System.Management.Automation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" )
      } else {
         $null = $xlr8r::Remove( "PSParser" )
         $xlr8r::Add( "PSParser", "System.Management.Automation.PSParser, System.Management.Automation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" )
      }

   
   }   
}
process {
   for($i=0;$i -lt $Name.Count;$i++){
      if($Alias -is [Scriptblock]) {
         $a = $Name[$i] | &$Alias
      } elseif($Alias -is [Array]) {
         $a = $Alias[$i]
      } else {
         $a = $Alias
      }
      
      if($Function -is [Scriptblock]) {
         $f = $Name[$i] | &$Function
      } elseif($Function -is [Array]) {
         $f = $Function[$i]
      } else {
         $f = $Function
      }
      
      Write-Verbose "Set-Alias $Module\$a Invoke-Autoloaded -Scope $Scope"
      Set-Alias $a Invoke-Autoloaded -Scope $Scope
      $Script:AutoloadHash[$a] = $Name[$i],$Module,$f
      Write-Verbose "$($Script:AutoloadHash.Count)  `$AutoloadHash[$a] = $($Script:AutoloadHash[$a])"
   }
}
}

Set-Alias Autoload New-Autoload
Set-Alias LoadNow  Resolve-Autoloaded

New-Variable -Name AutoloadHash -Value @{} -Scope Script -Description "The Autoload alias-to-script cache" -Option ReadOnly -ErrorAction SilentlyContinue

Export-ModuleMember -Function New-Autoload, Invoke-Autoloaded, Get-AutoloadHelp, Resolve-Autoloaded -Alias *
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyRBnpEvPgyp+DB2CjfuPIo+W
# +XmgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFE5BKakiD2A5c6Pg
# g5p2fs0ypz6fMA0GCSqGSIb3DQEBAQUABIIBAI+0HSpcPDlj1EcCS0KxYYE1MJk6
# F2Y4BfGfg/wMxGzHjp09hc1fTS/iYvvoY2QhLp/wuxPL3KXbFN6nninaJ8nHMB4l
# Xn+jfMiqn/duvKwyabquxDUZut6XogenPWa2i4vsQbO8BvJMgAbur7zidOiyz1b8
# vQc7YV65DsMjoBPUsaCmEIcRITGXf7mOnqOvfn02+Wo5zNjYiSi1PC1VXJAkvgHm
# j1cdRNnQg/m97t9Pm5sgvUheOlldlSymMzz1qMKyh0tlOLIJBRWgkTb1sa0GpZ+s
# 26+sS+Xpsa9+QVIvZY0RMuDjFkpaj8oCl1mlZiRRC9CLi4s3d37baeD1V+4=
# SIG # End signature block
