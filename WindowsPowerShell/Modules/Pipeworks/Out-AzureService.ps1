function Out-AzureService
{
    <#
    .Synopsis
        Creates a an Azure Service Deployment pack, definition, and configuration file
    .Description
        Uses the Azure SDK tool CSPack to create a deployment package (cspkg) and associated deployment files.               
    .Link 
        New-AzureServiceDefinition
    .Link 
        Publish-AzureService
    #>
    [OutputType([IO.FileInfo])]
    param(    
    # The Service DefinitionXML
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
    [ValidateScript({
        $isServiceDefinition = $_.NameTable.Get("http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceDefinition")
        if (-not $IsServiceDefinition) {
            throw "Input must be a ServiceDefinition XML"
        }
        return $true
    })]    
    [Xml]
    $ServiceDefinition,

    # The output directory for the azure service.
    [Parameter(Mandatory=$true)]
    [string]
    $OutputPath,
       
    # If set, will look for a specific Azure SDK Version
    [Version]
    $SdkVersion,
    
    [Uint32]
    $InstanceCount = 2
    )
    
    begin {
        #region Find CSPack
        $azureSdkDir = Get-ChildItem "$env:ProgramFiles\Windows Azure SDK", "$env:ProgramFiles\Microsoft SDKs\Windows Azure\.NET SDK" -Force -ErrorAction SilentlyContinue 
        if ($azureSdkDir) {
            $latestcsPack = $azureSdkDir | 
                Sort-Object { $_.Name.Replace('v', '') -as [Version] }  |
                Where-Object {
                    if ($sdkVersion) {
                        $_.Name.Replace('v', '') -eq $SdkVersion
                    } else {
                        return $true
                    }                    
                } |
                Select-Object -Last 1 |
                Get-ChildItem -Filter 'bin' |
                Get-ChildItem -Filter 'cspack*'
                
            if ($latestCsPack) {
                $csPack  = Get-Command $latestCsPack.fullname
            }
        } else {
            $latestCSPack = $csPack = Get-Command $psScriptRoot\Tools\cspack.exe
        }        
        #endregion Find CSPAck
    }
    
    process {
        if (-not $latestCSPack) { 
            Write-Error "Azure SDK tool CSPack not found"
            return 
        } 
        $temporaryServiceDirectory = New-Item -ItemType Directory -Path "$env:Temp\$(Get-Random).azureService" 
        
        $serviceName = $ServiceDefinition.ServiceDefinition.name
        try { $null = $ServiceDefinition.CreateXmlDeclaration("1.0", "utf8", $null) } catch  {} 
        $serviceDefinitionFile = Join-Path $temporaryServiceDirectory "$serviceName.csdef"
        $ServiceDefinition.Save($serviceDefinitionFile)
                    
        $serverShellDirectory = $psScriptRoot
        
        $workingDirectory = Split-Path $serviceDefinitionFile
        $leaf = Split-Path $serviceDefinitionFile -Leaf
        $configurationFile = "$serviceName.cscfg"
        
        $arguments = @("$leaf")
        
        
                
        
        $roles = @($ServiceDefinition.ServiceDefinition.WebRole), @($ServiceDefinition.ServiceDefinition.WorkerRole) +  @($ServiceDefinition.ServiceDefinition.VirtualMachineRole)
        $xmlNamespace = @{'ServiceDefinition'='http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceDefinition'}        
        $selectXmlParams = @{
            XPath = '//ServiceDefinition:WebRole|//ServiceDefinition:WorkerRole|//ServiceDefinition:VirtualMachineRole'
            Namespace = $xmlNamespace
        }        
        $roles = @(Select-Xml -Xml $ServiceDefinition @selectXmlParams | 
            Select-Object -ExpandProperty Node)
        
        #$roles[0]
        $startupBin = "$temporaryServiceDirectory\Startup\bin"
        New-Item $startupBin  -ErrorAction SilentlyContinue -Force -ItemType Directory | Out-Null
                      
        
        #$arguments += "/role:$roleArgs"
        $firstSitePhysicalDirectory = $null
        foreach ($role in $roles) {
            $roleDir = Join-Path $temporaryServiceDirectory $role.Name
            $null = New-Item -ItemType Directory -Path $roleDir
            $roleBinDir = Join-Path $temporaryServiceDirectory "$($role.Name)_bin"            
            $null = New-Item -ItemType Directory -Path $roleBinDir
            $roleBin = Join-Path $roleBinDir "bin"
            $null = New-Item -ItemType Directory -Path $roleBin
            # The azure sdk requires a binary, so give them a binary
            Add-Type -OutputAssembly "$roleBin\Placeholder.dll" -TypeDefinition @"
namespace Namespace$(Get-Random) {
    public class Stuff 
    {
        public int StuffCount;
    }
}
"@            
            $configSettingsChunk = "<ConfigurationSettings />"
            $arguments+= "/role:$($role.Name);$($role.Name)_bin"
            if ($role.ConfigurationSettings) {
                $configSettingsChunk = "<ConfigurationSettings>"
                foreach ($configSetting in $role.ConfigurationSettings.Setting) {
                    $configSettingsChunk += $configSetting.innerXml
                    $null = $configSetting.RemoveAttribute('value')
                }
                $configSettingsChunk += "</ConfigurationSettings>"                
                $ServiceDefinition.Save($serviceDefinitionFile)
            }
            
            if ($role.Startup) {
                $c = 0
                foreach ($task in $role.Startup.Task) {
                    $c++
                    if ($task.ScriptBlock) {
                        $null = $task.SetAttribute('commandLine', "startupScript${c}.cmd")
                        # Create the cmd file
                        $cmdFile = "powershell.exe -executionpolicy bypass -file startupScript${c}.ps1"
                        $scriptFile = "`$scriptBlockParameters = @{}
`$serviceName = '$($serviceDefinition.Name)'
"
                        
                        if ($task.Parameters) {
                            foreach ($parameter in $task.Parameters) {
                                $scriptFile += "

`$scriptBlockParameters.'$($Parameter.Name)' = '$($parameter.Value)'
                                
                                "
                            }
                        }
                        $scriptFile += "
                        
& {
    $($task.ScriptBlock.'#text')
} @scriptBlockParameters 
                        " 
                        $cmdFile > "$roleBin\startupScript${c}.cmd"
                        $scriptFile > "$roleBin\startupScript${c}.ps1"
                    }
                    foreach ($i in @($task.GetEnumerator())) { 
                        $null = try { $task.RemoveChild($i)  } catch { }
                    } 
                }
                $ServiceDefinition.Save($serviceDefinitionFile)
            }
            $roleConfigChunk += "<Role name='$($role.Name)'>
    $configSettingsChunk
    <Instances count='$InstanceCount' />
  </Role>"            
            $sites = $roles = @(Select-Xml -Xml $ServiceDefinition -Namespace $xmlNamespace -XPath //ServiceDefinition:Site | 
                Select-Object -ExpandProperty Node)
            if ($sites) {            
                foreach ($site in $sites ) {
                    if (-not $firstSitePhysicalDirectory) { $firstSitePhysicalDirectory= $site.PhysicalDirectory}                    
                    $webConfigFile = Join-Path $site.PhysicalDirectory "Web.Config"
                    if (-not (Test-Path $webConfigFile)) {
                        '
<configuration>
    <system.web>
        <customErrors mode="Off"/>
    </system.web>
</configuration>                        
                        ' | Set-Content -path $webConfigFile                                                
                    }
                    
                }
            }
            $startupTasks = @(Select-Xml -Xml $ServiceDefinition -Namespace $xmlNamespace -XPath //ServiceDefinition:Task | 
                Select-Object -ExpandProperty Node)
        }
        
        
        $cscfgXml = [xml]@"
<ServiceConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" serviceName="$serviceName" xmlns="http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceConfiguration" osFamily='2' osVersion='*'>
  $RoleConfigChunk
</ServiceConfiguration>        
"@             
        
        
        $tempOutFile = Join-Path $env:Temp (Get-Random)

        Push-Location $workingDirectory
        $results = & $csPack $arguments 
        Pop-Location

        $errs =$results -like "*Error*:*"
        if ($errs) {
            foreach ($err in $errs) {
                Write-Error $err.Substring($err.IndexOf(":") + 1)
            }
            return
        }
        
        
        $csdef = $serviceDefinitionFile
        $cspkg = Join-Path $workingDirectory "$serviceName.cspkg"
        
        if (-not $outputPath) {        
            $serviceDeploymentRoot = "$psScriptRoot\AzureServices"
            if (-not (Test-Path $serviceDeploymentRoot)) {
                $null = New-Item -ItemType Directory -Path $serviceDeploymentRoot
            }
            
            $serviceDropDirectory = "$serviceDeploymentRoot\$serviceName"
            if (-not (Test-Path $serviceDropDirectory)) {
                $null = New-Item -ItemType Directory -Path $serviceDropDirectory
            }        

            $nowString = (Get-Date | Out-String).Trim().Replace(":", "-")
            $thisDropDirectory  =Join-Path $serviceDropDirectory $nowString 
            if (-not (Test-Path $thisDropDirectory)) {
                $null = New-Item -ItemType Directory -Path $thisDropDirectory
            }           
        } else {
            $unResolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputPath)
            if (-not (Test-Path $unResolvedPath)) {
                $newPath = New-Item -ItemType Directory $unResolvedPath
                if ($newPath) { 
                    $thisDropDirectory = "$newPath"
                }
            } else {
                $thisDropDirectory = "$unResolvedPath"
            }
            
        }
        
        
        #Move-Item -LiteralPath $cscfg -Destination "$thisDropDirectory"
        $cscfg = Join-Path $thisDropDirectory $configurationFile
        if (Test-Path $cscfg) { Remove-Item -Force $cscfg }
        $cscfgXml.Save("$cscfg")
        Move-Item -LiteralPath $csdef -Destination "$thisDropDirectory" -Force
        Move-Item -LiteralPath $cspkg -Destination "$thisDropDirectory" -Force                
        
        Remove-Item -Recurse -Force $workingDirectory
        Get-ChildItem $thisDropDirectory -Force               
    }
} 
