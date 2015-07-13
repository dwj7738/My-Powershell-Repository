function Get-RebootPending 
{
    [CmdletBinding()]
    param(
    [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias("CN","Computer")]
    [String[]]$ComputerName="$env:COMPUTERNAME"
    )
    $PendFileRename,$Pending,$SCCM = $false,$false,$false
    $CBSRebootPend = $null
    $WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $ComputerName
    $RegCon = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine",$ComputerName)
    If ($WMI_OS.BuildNumber -ge 6001) {
    $CBSRebootPend = $RegSubKeysCBS -contains "RebootPending"        
    }
    ## End If ($WMI_OS.BuildNumber -ge 6001)
    $RegWUAU = $RegCon.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
    $RegWUAURebootReq = $RegWUAU.GetSubKeyNames()
    $WUAURebootReq = $RegWUAURebootReq -contains "RebootRequired"
    $RegSubKeySM = $RegCon.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\")
    $RegValuePFRO = $RegSubKeySM.GetValue("PendingFileRenameOperations",$null)
    $RegCon.Close()
    If ($RegValuePFRO)
    {
    $PendFileRename = $true
    }#End If ($RegValuePFRO)
    $CCMClientSDK = $null
    $CCMSplat = @{
    NameSpace='ROOT\ccm\ClientSDK'
    Class='CCM_ClientUtilities'
    Name='DetermineIfRebootPending'
    ComputerName=$Computer
    ErrorAction='SilentlyContinue'
    }
    $CCMClientSDK = Invoke-WmiMethod @CCMSplat
    If ($CCMClientSDK)
    {
    If ($CCMClientSDK.ReturnValue -ne 0)
    {
    Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"
    }## End If ($CCMClientSDK -and $CCMClientSDK.ReturnValue -ne 0)
    If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending)
        {
        $SCCM = $true
        }## End If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending)
        }## End If ($CCMClientSDK)
            Else
            {
            $SCCM = $null
            }
        If ($CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
    {
        $Pending = $true
    }## End If ($CBS -or $WUAU -or $PendFileRename)
    $SelectSplat = @{
        Property=('Computer','CBServicing','WindowsUpdate','CCMClientSDK','PendFileRename','PendFileRenVal','RebootPending')
        }
    New-Object -TypeName PSObject -Property @{
    Computer=$WMI_OS.CSName
    CBServicing=$CBSRebootPend
    WindowsUpdate=$WUAURebootReq
    CCMClientSDK=$SCCM
    PendFileRename=$PendFileRename
    PendFileRenVal=$RegValuePFRO
    RebootPending=$Pending
    } | Select-Object @SelectSplat
}
$cred = Get-Credential iammred\administrator
$servers = Invoke-Command -cn dc3 -cred $cred -script {import-module ActiveDirectory;
Get-ADComputer -LDAPFilter "(&(objectcategory=computer)(OperatingSystem=*server*))"}
$servers.count
$servers | foreach {$_.name} # one way powershell 2.0
# foreach ($server in $servers.name) # Powershell 3.0
foreach($server in $servers) {
Get-PendingReboot -computername $servers
}

