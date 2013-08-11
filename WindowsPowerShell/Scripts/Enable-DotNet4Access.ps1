Function Enable-DotNet4Access {
    <#
    .SYNOPSIS  
        Enables PowerShell access to the .NET 4.0 framework by creating a configuration file.

    .DESCRIPTION
        Enables PowerShell access to the .NET 4.0 framework by creating a configuration file. You will need to 
        restart PowerShell in order for this to take effect. In a default installation of PowerShell V2, these
        files do not exist.
    
    .PARAMETER Computername
        Name of computer to enable .NET 4 for PowerShell against.
         
    .PARAMETER Console
        Apply configuration change for console only

    .PARAMETER ISE
        Apply configuration change to ISE only

    .NOTES  
        Name: Enable-DotNet4Access
        Author: Boe Prox
        DateCreated: 10JAN2012 
               
    .LINK  

https://learn-powershell.net

    .EXAMPLE
    Enable-DotNet4Access -Console -ISE
    
    Description
    -----------
    Enables .NET 4.0 access for PowerShell on console and ISE
    #>
    
    [cmdletbinding(
        SupportsShouldProcess = $True
    )]
    Param (
        [parameter(Position='0',ValueFromPipeLine = $True,ValueFromPipelineByPropertyName=$True)]
        [Alias('__Server','Computer','Server','CN')]
        [string[]]$Computername,
        [parameter(Position='1')]
        [switch]$Console,
        [parameter(Position='2')]
        [switch]$ISE
    )
    Begin {
    Write-Verbose ("Creating file data")
$file = @'
<?xml version="1.0"?>
<configuration>
    <startup useLegacyV2RuntimeActivationPolicy="true">
        <supportedRuntime version="v4.0.30319"/>
        <supportedRuntime version="v2.0.50727"/>
    </startup>
</configuration>
'@ 
    }
    Process {
        If (-Not $PSBoundParameters['Computername']) {
            Write-Warning ("No computername given! Using {0} as computername." -f $Env:Computername)
            $Computername = $Env:Computername
        }
        ForEach ($Computer in $computername) {
            If ($PSBoundParameters['Console']) {
                If ($pscmdlet.ShouldProcess("Console","Enable .NET 4.0 Access")) {
                    Try {
                        $file | Out-file "\\$computer\C$\Windows\System32\WindowsPowerShell\v1.0\PowerShell.Exe.Config" -Force
                        Write-Host ("{0}: Console must be restarted before changes will take effect!" -f $Computer) -fore Green -Back Black
                    } Catch {
                        Write-Warning ("{0}: {1}" -f $computer,$_.Exception.Message)
                    }
                }
            }
            If ($PSBoundParameters['ISE']) {
                If ($pscmdlet.ShouldProcess("ISE","Enable .NET 4.0 Access")) {
                    Try {
                        $file | Out-file "\\$computer\C$\Windows\System32\WindowsPowerShell\v1.0\PowerShellISE.Exe.Config" -Force
                        Write-Host ("{0}: ISE must be restarted before changes will take effect!" -f $Computer) -fore Green -Back Black
                    } Catch {
                        Write-Warning ("{0}: {1}" -f $computer,$_.Exception.Message)
                    }
                }
            }
        }
    }
}