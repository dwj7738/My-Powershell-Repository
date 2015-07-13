#--------------------------------------------------------------------------------- #The sample scripts are not supported under any Microsoft standard support #program or service. The sample scripts are provided AS IS without warranty  #of any kind. Microsoft further disclaims all implied warranties including,  #without limitation, any implied warranties of merchantability or of fitness for #a particular purpose. The entire risk arising out of the use or performance of  #the sample scripts and documentation remains with you. In no event shall #Microsoft, its authors, or anyone else involved in the creation, production, or #delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, #loss of business information, or other pecuniary loss) arising out of the use #of or inability to use the sample scripts or documentation, even if Microsoft #has been advised of the possibility of such damages #--------------------------------------------------------------------------------- 

Configuration SetPowerShellExecutionPolicy
{
    Param
    (
        #Target nodes to apply the configuration  
        [String[]]$NodeName = $env:COMPUTERNAME,
        
        #Changes the user preference for the Windows PowerShell execution policy.
        [Parameter(Mandatory)]
        [ValidateSet("Bypass","Restricted","AllSigned","RemoteSigned","Unrestricted")]
        [String]$SetExecutionPolicy
    )
    Import-DSCResource -ModuleName xPowerShellExecutionPolicy

    Node $NodeName
    {
        xPowerShellExecutionPolicy ExecutionPolicy
        {
            ExecutionPolicy = $SetExecutionPolicy
        }
    }
}

SetPowerShellExecutionPolicy -NodeName "localhost" -SetExecutionPolicy "bypass"
Start-DscConfiguration -Path .\SetPowerShellExecutionPolicy  -Wait -Force -Verbose