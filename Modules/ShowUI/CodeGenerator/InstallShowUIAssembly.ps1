param(
$outputPathBase = "$psScriptRoot\GeneratedAssemblies\",
$CommandPath    = "$outputPathBase\ShowUI.CLR$($psVersionTable.clrVersion).dll",
$CoreOutputPath = "$outputPathBase\ShowUICore.CLR$($psVersionTable.clrVersion).dll",
$Assemblies,
$Force,
$FileRoot = "$psScriptRoot"
)




# If the expected output already exists, then we've nothing to do here :)
if((Test-Path $CommandPath, $CoreOutputPath) -notcontains $False) { return }

# But otherwise, we need to start regenerating the code ...
. $fileRoot\CodeGenerator\Rules\WpfCodeGenerationRules.ps1
# Regenerate the code
$progressId = Get-Random
$childId = Get-Random    

Write-Progress "Preparing Show-UI for First Time Use" "Please Wait" -Id $progressId 

if (-not (Test-Path $outputPathBase)) {
    New-Item $outputPathBase -ItemType "Directory" -Force | Out-Null
}
$SourcePathBase = ($outputPathBase -replace "GeneratedAssemblies","GeneratedCode")

if (-not (Test-Path $SourcePathBase)) {
    New-Item $SourcePathBase -ItemType "Directory" -Force | Out-Null
}

Write-Progress "Compiling Core Features" " " -ParentId $progressId -Id $childId

if(!$Assemblies) {
    try {
        $Assemblies = 
        [Reflection.Assembly]::Load("WindowsBase, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
        [Reflection.Assembly]::Load("PresentationFramework, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
        [Reflection.Assembly]::Load("PresentationCore, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
        [Reflection.Assembly]::Load("WindowsFormsIntegration, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")

        if ($PSVersionTable.ClrVersion.Major -ge 4) {
            $Assemblies += [Reflection.Assembly]::Load("System.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
        }
    } catch {
        throw $_
    }
}
$generatedCode = ""

<#
$specificTypeNameWhiteList =
    'System.Windows.Input.ApplicationCommands',
    'System.Windows.Input.ComponentCommands',
    'System.Windows.Input.NavigationCommands',
    'System.Windows.Input.MediaCommands',
    'System.Windows.Documents.EditingCommands',
    'System.Windows.Input.CommandBinding'

$specificTypeNameBlackList =
    'System.Windows.Threading.DispatcherFrame', 
    'System.Windows.DispatcherObject',
    'System.Windows.Interop.DocObjHost',
    'System.Windows.Ink.GestureRecognizer',
    'System.Windows.Data.XmlNamespaceMappingCollection',
    'System.Windows.Annotations.ContentLocator',
    'System.Windows.Annotations.ContentLocatorGroup'

$allTypes = foreach ($assembly in $assemblies) {
    $Name = $assembly.GetName().Name
    
    Write-Progress "Filtering Types from Assembly" $Name -Id $ChildId -ParentId $progressId
    $Assembly.GetTypes() | Where-Object {
        $specificTypeNameWhiteList -contains $_.FullName -or
        (
            $_.IsPublic -and 
            (-not $_.IsGenericType) -and 
            (-not $_.IsAbstract) -and
            (-not $_.IsEnum) -and
            ($_.FullName -notlike "*Internal*") -and
            (-not $_.IsSubclassOf([EventArgs])) -and
            (-not $_.IsSubclassOf([Exception])) -and
            (-not $_.IsSubclassOf([Attribute])) -and
            (-not $_.IsSubclassOf([Windows.Markup.ValueSerializer])) -and
            (-not $_.IsSubclassOf([MulticastDelegate])) -and
            (-not $_.IsSubclassOf([ComponentModel.TypeConverter])) -and
            (-not $_.GetInterface([Collections.ICollection])) -and
            (-not $_.IsSubClassOf([Windows.SetterBase])) -and
            (-not $_.IsSubclassOf([Security.CodeAccessPermission])) -and
            (-not $_.IsSubclassOf([Windows.Media.ImageSource])) -and
#               (-not $_.IsSubclassOf([Windows.Input.InputGesture])) -and
#               (-not $_.IsSubclassOf([Windows.Input.InputBinding])) -and
            (-not $_.IsSubclassOf([Windows.TemplateKey])) -and
            (-not $_.IsSubclassOf([Windows.Media.Imaging.BitmapEncoder])) -and
            ($_.BaseType -ne [Object]) -and
            ($_.BaseType -ne [ValueType]) -and
            $_.Name -notlike '*KeyFrame' -and
            $specificTypeNameBlackList -notcontains $_.FullName
        )
    }
}

$generatedCode = New-Object Collections.arraylist 
$typeCounter =0
$count= @($allTypes).Count


foreach ($type in $allTypes) 
{
    if (-not $type) { continue }
    $typeCounter++
    $perc = $typeCounter * 100/ $count 
    Write-Progress "Generating Code" $type.Fullname -PercentComplete $perc -ParentId $progressID -Id $childId     
    $typeCode = ConvertFrom-TypeToScriptCmdlet -Type $type -ErrorAction SilentlyContinue -AsCSharp    
    $null = $generatedCode.Add("$typeCode")
}

$ofs = [Environment]::NewLine

$generatedCode = $generatedCode | Where-Object { $_ } 
#>
$controlNameDependencyObject = [IO.File]::ReadAllText("$fileRoot\CSharp\ShowUIDependencyObjects.cs")
$cmdCode = [IO.File]::ReadAllText("$fileRoot\CSharp\ShowUICommand.cs")
$ValueConverter = [IO.File]::ReadAllText("$fileRoot\CSharp\LanguagePrimitivesValueConverter.cs")
$wpfJob = [IO.File]::ReadAllText("$fileRoot\CSharp\WPFJob.cs")
$PowerShellDataSource = [IO.File]::ReadAllText("$fileRoot\CSharp\PowerShellDataSource.cs")
$OutXamlCmdlet = [IO.File]::ReadAllText("$fileRoot\CSharp\OutXaml.cs")
#$ScriptDataSource = [IO.File]::ReadAllText("$fileRoot\CSharp\ScriptDataSource.cs")

$generatedCode = "
$controlNameDependencyObject
$cmdCode
$ValueConverter
$wpfJob 
$PowerShellDataSource
$OutXamlCmdlet

"

$CoreSourceCodePath  =   "$SourcePathBase\ShowUICore.CLR$($psVersionTable.clrVersion).cs"
try {
    # For debugging purposes, try to put the code in the module.  
    # The module could be run from CD or a filesystem without write access, 
    # so redirect errors into the Debug channel.
    [IO.File]::WriteAllText($CoreSourceCodePath, $generatedCode)
} catch {
    $_ | Out-String | Write-Debug
}

$RequiredAssemblies = $Assemblies + @("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
                                      
if ($PSVersionTable.ClrVersion.Major -ge 4) {
    $RequiredAssemblies += "System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
}

$global:addTypeParameters = @{
    TypeDefinition=$generatedCode
    IgnoreWarnings=$true
    ReferencedAssemblies=Get-AssemblyName -RequiredAssemblies $RequiredAssemblies -ExcludedAssemblies "MSCorLib","System"
    Language='CSharpVersion3'
}
# If we're running in .Net 4, we shouldn't specify the Language, because it'll use CSharp4
if ($PSVersionTable.ClrVersion.Major -ge 4) {
    $AddTypeParameters.Remove("Language")
}
# Check to see if the outputpath can be written to: we don't *have* to save it as a dll
if (Set-Content "$outputPathBase\test.write" -Value "1" -ErrorAction SilentlyContinue -PassThru) {
    Remove-Item "$outputPathBase\test.write" -ErrorAction SilentlyContinue
    $AddTypeParameters.OutputAssembly = $CoreOutputPath
}

Write-Debug "Type Parameters:`n$($addTypeParameters | Out-String)"

Add-Type @addTypeParameters

if((Test-Path $CommandPath) -and !$Force) { return }
$SourceCodePath = $CommandPath -replace "GeneratedAssemblies", "GeneratedCode" -replace '.dll$','.cs'

Write-Debug "Generating Commands From Assemblies:`n$($Assemblies | Format-Table @{name="Version";expr={$_.ImageRuntimeVersion}}, FullName -auto | Out-String)"
Add-UIModule -AssemblyName $Assemblies -RequiredAssemblies $RequiredAssemblies -Name $CommandPath -SourceCodePath $SourceCodePath -AsCmdlet -AssemblyOnly -ProgressParentId $progressId -ProgressId $ChildId

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGfX+kqBv7/eJcBnELZeixhke
# MaegggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFF2UGRm3YpbKSB41
# b+ycEutdHoUvMA0GCSqGSIb3DQEBAQUABIIBAI8jnzLyr0tyS5yrI3vXQAN00vj+
# 3HOYB7Rey+0Fjjcebsfb+pxcRbfpzf4SBoKQdB1JNc9Ta/mvvKmbfWUa0JtirJ1X
# ujHmxsjgQAWX8EUERaXp5OZ/PwZy7YKUNJDBJBQom4fugW41XMiB2AqXhrwXhYzA
# 3m0h5d8cRJYs+rjjpL4dUu4GYAqh0Fg5xk2vQzTXdaVxdslJGPZZYyYg2Ka4GcoA
# z11yjnJNg7UF/LeVZ4VWQzMiJWIgHO6psfU7cbC0Rz4/tHbhU5snGJnRejn9YvKT
# uxoe7HT/nIo20AZJ0axjUFR2d0VqiSVbmYBtdjbCy7g47MWHhvLcwH6YLlo=
# SIG # End signature block
