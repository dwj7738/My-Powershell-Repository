# Trigger LCM pull using the CIM Method.
function TriggerLCMByCallingCimMethod
{
	param([ValidateSet(1,2,3)]
	[system.uint32]$flag = 1)
    
	Invoke-CimMethod -Namespace root/microsoft/windows/desiredstateconfiguration -class MSFT_DSCLocalConfigurationManager -name PerformRequiredConfigurationChecks -arguments @{Flags = $flag} -verbose
}
TriggerLCMByCallingCimMethod
