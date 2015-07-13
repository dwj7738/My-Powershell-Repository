$scriptFolder = Split-Path $script:MyInvocation.MyCommand.Path 

Configuration VMMetaConfig
{
    Node localhost
    {
       LocalConfigurationManager
       {
            RebootNodeIfNeeded = "true"
            CertificateID = "497258FCCFFFA0F38268BBD970B337D25C871D6D"
       }
    }
}

VMMetaConfig -OutputPath $scriptFolder\VMMetaConfig 

# Setup DSC metaconfiguration
Set-DscLocalConfigurationManager -Path $scriptFolder\VMMetaConfig -Verbose -ComputerName localhost

# Starts a consistency check
[system.uint32]$flag = 1
Invoke-CimMethod -Namespace root/microsoft/windows/desiredstateconfiguration -class MSFT_DSCLocalConfigurationManager -name PerformRequiredConfigurationChecks -arguments @{Flags = $flag} -verbose