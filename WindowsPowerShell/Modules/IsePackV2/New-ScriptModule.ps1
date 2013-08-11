function New-ScriptModule
{
    
	<#
    .Synopsis
        Creates a new module and manifest
    .Description
        Creates a new module and manifest
    .Example
        New-ScriptModule 'MyModule'
    #>
	
    [CmdletBinding(DefaultParameterSetName='NotRequired')]
    param(
    [Parameter(Mandatory=$true,Position=0)]    
    [ValidateScript({
    if ($_ -like "*\*" -or $_ -like "*/*") { throw "Module name cannot contain slashes" }     
    return $true
    })]
    [string]
    $ModuleName,
    
    [Parameter(ParameterSetName='Required',Mandatory=$true)]
    [string[]]
    $NestedModule,

    [Parameter(ParameterSetName='Nested',Mandatory=$true)]    
    [string[]]
    $RequiredModule,

    [string[]]
    $FileList,

    [ScriptBlock]
    $OnRemove
    )
    
    process {
        $moduleRoot = "$home\Documents\WindowsPowerShell\Modules"
        if (-not (Test-Path $moduleRoot)) {
            New-Item -Path $moduleRoot -ItemType Directory  | 
                Out-Null
        }
        $modulePath = Join-Path $moduleRoot $moduleName 
        if (-not (Test-Path $modulePath)) {
            New-Item -Path $modulePath -ItemType Directory  | 
                Out-Null
        }
        
        $fullModuleManifestPath = Join-Path $modulePath "${moduleName}.psd1"
        $fullModulePath = Join-Path $modulePath "${moduleName}.psm1"

        if ($psCmdlet.ParameterSetName -eq 'Nested') {
@"
@{
    ModuleVersion='1.0'
    ModuleToProcess='${moduleName}.psm1'
    NestedModules='$($moduleList -Join "','")'
}
"@ | 
            Set-Content $fullModuleManifestPath  
            
''  | Set-Content $fullModulePath

        } elseif ($psCmdlet.ParameterSetName -eq 'Required') {
@"
@{
    ModuleVersion='1.0'
    ModuleToProcess='${moduleName}.psm1'
    RequiredModules='$($moduleList -Join "','")'
}
"@ | 
            Set-Content $fullModuleManifestPath  
            
''  | Set-Content $fullModulePath

        }  elseif ($psCmdlet.ParameterSetName -eq 'NotRequired') {
        
@"
@{
    ModuleVersion='1.0'
    ModuleToProcess='${moduleName}.psm1'
}
"@ | 
            Set-Content $fullModuleManifestPath  

$fileInclude = foreach ($file in $fileList) {
    if (-not $file) {continue }
    if ($file -notlike "*.ps1") {
        $file = "$file.ps1"
    }
    ". `$psScriptRoot\$file"
}            
'
# Start-Scripting
'  | Set-Content $fullModulePath
        
        }
        
        Get-Item -LiteralPath $fullModuleManifestPath -ErrorAction SilentlyContinue
        Get-Item -LiteralPath $fullModulePath -ErrorAction SilentlyContinue
    }
} 
