# Type definition for interop 
 
$WTSTypes = @" 
using System; 
using System.Text; 
using System.Runtime.InteropServices; 
 
namespace RDSManager.PowerShell 
{ 
    [StructLayout(LayoutKind.Sequential)] 
    public struct WTSSessionInfo 
    { 
        public Int32 SessionID; 
        [MarshalAs(UnmanagedType.LPStr)] 
        public String WinStationName; 
        public WTSConnectState State; 
    } 
	
    [StructLayout(LayoutKind.Sequential)]
    public struct WTSClientAddress
    {
        public uint AddressFamily;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 20)]
        public byte[] Address;	
    } 

    public enum WTSConnectState 
    { 
        WTSActive, 
        WTSConnected, 
        WTSConnectQuery, 
        WTSShadow, 
        WTSDisconnected, 
        WTSIdle, 
        WTSListen, 
        WTSReset, 
        WTSDown, 
        WTSInit 
    } 
 
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] 
    public struct WTSSessionStatus 
    { 
        public WTSConnectState State; 
        public Int32 SessionId; 
        public Int32 IncomingBytes; 
        public Int32 OutgoingBytes; 
        public Int32 IncomingFrames; 
        public Int32 OutgoingFrames; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public String WinStationName; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 17)] 
        public String Domain; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 21)] 
        public String User; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 56)] 
        public String ConnectTime; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 56)] 
        public String DisconnectTime; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 56)] 
        public String LastInputTime; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 56)] 
        public String LogonTime; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 56)] 
        public String CurrentTime; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 56)] 
        public String IdleTime; 
    } 
 
    public enum WTSInfoType 
    { 
        WTSInitialProgram = 0, 
        WTSApplicationName = 1, 
        WTSWorkingDirectory = 2, 
        WTSOEMId = 3, 
        WTSSessionId = 4, 
        WTSUserName = 5, 
        WTSWinStationName = 6, 
        WTSDomainName = 7, 
        WTSConnectState = 8, 
        WTSClientBuildNumber = 9, 
        WTSClientName = 10, 
        WTSClientDirectory = 11, 
        WTSClientProductId = 12, 
        WTSClientHardwareId = 13, 
        WTSClientAddress = 14, 
        WTSClientDisplay = 15, 
        WTSClientProtocolType = 16, 
        WTSIdleTime = 17, 
        WTSLogonTime = 18, 
        WTSIncomingBytes = 19, 
        WTSOutgoingBytes = 20, 
        WTSIncomingFrames = 21, 
        WTSOutgoingFrames = 22, 
        WTSClientInfo = 23, 
        WTSSessionInfo = 24 
    } 
 
    public class RDSession 
    { 
        public string Server; 
        public string Session; 
        public string User; 
        public int SessionID; 
        public WTSConnectState State; 
        public string ProtocolType; 
        public string Client; 
        public string ClientAddress; 
    } 
 
    public class RDSManager 
    { 
        [DllImport("wtsapi32.dll")] 
        public static extern IntPtr WTSOpenServer( 
            [MarshalAs(UnmanagedType.LPStr)] String pServerName 
        ); 
 
        [DllImport("wtsapi32.dll")] 
        public static extern IntPtr WTSOpenServerEx( 
            [MarshalAs(UnmanagedType.LPStr)] String pServerName 
        ); 
 
        [DllImport("wtsapi32.dll")] 
        public static extern void WTSCloseServer( 
            IntPtr hServer 
        ); 
 
        [DllImport("wtsapi32.dll")] 
        public static extern Int32 WTSEnumerateSessions( 
            IntPtr hServer, 
            [MarshalAs(UnmanagedType.U4)] Int32 Reserved, 
            [MarshalAs(UnmanagedType.U4)] Int32 Version, 
            ref IntPtr ppSessionInfo, 
            [MarshalAs(UnmanagedType.U4)] ref Int32 pCount 
        ); 
 
        [DllImport("wtsapi32.dll")] 
        public static extern Int32 WTSEnumerateSessionsEx( 
            IntPtr hServer, 
            [MarshalAs(UnmanagedType.U4)] ref Int32 pLevel, 
            [MarshalAs(UnmanagedType.U4)] Int32 Filter, 
            ref IntPtr ppSessionInfo, 
            [MarshalAs(UnmanagedType.U4)] ref Int32 pCount 
        ); 
 
        [DllImport("wtsapi32.dll")] 
        public static extern void WTSFreeMemory( 
            IntPtr pMemory 
        ); 
 
        [DllImport("wtsapi32.dll")] 
        public static extern Int32 WTSQuerySessionInformation( 
            IntPtr hServer, 
            [MarshalAs(UnmanagedType.U4)] Int32 SessionId, 
            [MarshalAs(UnmanagedType.U4)] Int32 WTSInfoClass, 
            ref IntPtr ppBuffer, 
            [MarshalAs(UnmanagedType.U4)] ref Int32 BytesReturned 
        ); 
 
 
        [DllImport("kernel32.dll", SetLastError = false, CharSet = CharSet.Auto)] 
        public static extern int WTSGetActiveConsoleSessionId(); 
 
        [DllImport("kernel32.dll")] 
        public static extern int GetCurrentProcessId(); 
 
        [DllImport("kernel32.dll", SetLastError = false, CharSet = CharSet.Auto)] 
        public static extern bool ProcessIdToSessionId( 
            Int32 ProcessId, 
            ref Int32 SessionId 
        ); 
 
        [DllImport("wtsapi32.dll", SetLastError = true, CharSet = CharSet.Auto)] 
        public static extern bool WTSConnectSession( 
            UInt32 LogonId, 
            UInt32 TargetLogonId, 
            string Password, 
            bool Wait 
        ); 
    } 
} 
"@ 
 
# Create new types as per the definition above. 
Add-Type -TypeDefinition $WTSTypes 
 
# Valid states(values) for various operations(keys). Valid states are represented by the values of the Keys. 
$StateOperations = @{ 
    "Send-Message" = @( "WTSActive" ) 
    "Get-RDSessionStatus" = @( "WTSActive" ) 
    "Connect-RDSession" = @( "WTSActive", "WTSDisconnected" ) 
    "Disconnect-RDSession" = @( "WTSActive" ) 
    "Start-RDRemoteControlSession" = @( "WTSActive" ) 
} 
 
function Ping-Computer 
{ 
 
param(     
    [Parameter(Mandatory=$TRUE, Position=0, ValueFromPipeline=$TRUE)] 
    [string] 
    $ComputerName 
) 
 
    Get-WmiObject -ComputerName $ComputerName Win32_ComputerSystem -ErrorVariable exp -ErrorAction SilentlyContinue | Out-Null 
    return ((-not $exp) -OR ($exp[0].Exception.ErrorCode -ne -2147023174)) 
 
} 
 
function IsConsoleSession 
{ 
 
param(     
    [Parameter(Mandatory=$FALSE, Position=0, ValueFromPipeline=$TRUE, ValueFromPipelineByPropertyName=$TRUE)] 
    [int] 
    $SessionID = -1 
) 
 
    if ($SessionID -eq -1) 
    { 
        [RDSManager.PowerShell.RDSManager]::ProcessIdToSessionId([RDSManager.PowerShell.RDSManager]::GetCurrentProcessId(), [ref] $SessionID) | Out-Null 
    } 
 
    return ([RDSManager.PowerShell.RDSManager]::WTSGetActiveConsoleSessionId() -eq $SessionID) 
} 
 
function IsCurrentSession 
{ 
 
param(     
    [Parameter(Mandatory=$TRUE, Position=0, ValueFromPipeline=$TRUE, ValueFromPipelineByPropertyName=$TRUE)] 
    [int] 
    $SessionID 
) 
 
    $CurrentSessionID = -1 
    [RDSManager.PowerShell.RDSManager]::ProcessIdToSessionId([RDSManager.PowerShell.RDSManager]::GetCurrentProcessId(), [ref] $CurrentSessionID) | Out-Null 
 
    return ($CurrentSessionID -eq $SessionID) 
} 
 
function Handle-Error 
{ 
 
param( 
    [Parameter(Mandatory=$TRUE, Position=0, ValueFromPipelineByPropertyName=$TRUE)] 
    [int] 
    $ErrorID, 
     
    [Parameter(Mandatory=$TRUE, Position=1)] 
    [string] 
    $Message 
) 
 
Write-Warning ">>> $ErrorID : $Message" 
 
    switch ($ErrorID) 
    { 
        5   {Write-Error "$Message : Access is denied.";break} 
    } 
} 
 
function Get-RDSessionInfoEntry 
{ 
 
param(     
    [Parameter(Mandatory=$TRUE, Position=0)] 
    [System.IntPtr] 
    $ServerPtr, 
 
    [Parameter(Mandatory=$TRUE, Position=1)] 
    [int] 
    $SessionID, 
     
    [Parameter(Mandatory=$TRUE, Position=2)] 
    [RDSManager.PowerShell.WTSInfoType] 
    $Entry 
) 
 
    if ($ServerPtr -eq [System.IntPtr]::Zero) 
    { 
        return 
    } 
     
    $entryInfo = [System.IntPtr]::Zero 
    $bytes = 0 
     
    $retval = [RDSManager.PowerShell.RDSManager]::WTSQuerySessionInformation($ServerPtr, $SessionID, $Entry, [ref] $entryInfo, [ref] $bytes) 
    $returnObj = $NULL 
     
    if($retval -ne 0) 
    { 
        switch ($Entry) 
        { 
            "WTSClientName"             {$returnObj = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($entryInfo, $bytes); break} 
            "WTSUserName"             	{$returnObj = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($entryInfo, $bytes); break} 
            "WTSClientProtocolType"     {$returnObj = [System.Runtime.InteropServices.Marshal]::ReadInt16($entryInfo); break} 
            "WTSIdleTime"               {$returnObj = [System.Runtime.InteropServices.Marshal]::ReadInt32($entryInfo); break} 
            "WTSLogonTime"              {$returnObj = [System.Runtime.InteropServices.Marshal]::ReadInt32($entryInfo); break} 
            "WTSClientDirectory"        {$returnObj = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($entryInfo, $bytes); break} 
            "WTSClientAddress"             {$returnObj = [RDSManager.PowerShell.WTSClientAddress][System.Runtime.InteropServices.Marshal]::PtrToStructure($entryInfo, [RDSManager.PowerShell.WTSClientAddress]); break} 
            "WTSSessionInfo"            {$returnObj = [RDSManager.PowerShell.WTSSessionStatus][System.Runtime.InteropServices.Marshal]::PtrToStructure($entryInfo, [RDSManager.PowerShell.WTSSessionStatus]); break} 
        } 
         
        [RDSManager.PowerShell.RDSManager]::WTSFreeMemory($entryInfo); 
        $entryInfo = [System.IntPtr]::Zero 
    } 
     
    return $returnObj 
} 
 
function Get-ProtocolName 
{ 
 
param(     
    [Parameter(Mandatory=$TRUE, Position=0)] 
    [int] 
    $ProtocolID 
) 
 
    $protocolType = "Unknown" 
 
    switch ($ProtocolID) 
    { 
        0   {$protocolType = "Console"; break} 
        1   {$protocolType = "Citrix ICA"; break} 
        2   {$protocolType = "Microsoft RDP"; break} 
    } 
     
    return $protocolType 
} 
 
function Get-ClientAddress 
{ 
 
param(     
    [Parameter(Mandatory=$TRUE, Position=0)] 
    [System.UInt32] 
    $ClientAddressFamily, 
     
    [Parameter(Mandatory=$TRUE, Position=1)] 
    [System.UInt16[]] 
    $ClientAddress 
) 
    $address = "Unknown" 
 
    switch ($ClientAddressFamily) 
    { 
        23  { 
                if (($ClientAddress[6] -eq 0) -AND ($ClientAddress[7] -eq 0)) 
                { 
                    $address = [string]::Join(":", ($ClientAddress[0..5] | %{$_.ToString("X")}))                     
                } 
                else 
                { 
                    $address = [string]::Join(":", ($ClientAddress[0..7] | %{$_.ToString("X")}))                     
                }                 
                break 
            } 
        2   { 
                $address = [string]::Join(".", $ClientAddress[0..3]) 
                break 
            } 
    } 
 
    return $address 
} 
 
function Get-ColorDepth 
{ 
 
param(     
    [Parameter(Mandatory=$TRUE, Position=0)] 
    [int] 
    $ColorDepth 
) 
 
    $colorDepthString = "Unknown" 
 
    switch ($ColorDepth) 
    { 
        2   {$colorDepthString = "8 bit"; break} 
        16  {$colorDepthString = "15 bit"; break} 
        4   {$colorDepthString = "16 bit"; break} 
        8   {$colorDepthString = "24 bit"; break} 
        32  {$colorDepthString = "32 bit"; break} 
    } 
     
    return $colorDepthString 
} 
 
function Get-EncryptionLevel 
{ 
 
param(     
    [Parameter(Mandatory=$TRUE, Position=0)] 
    [int] 
    $EncryptionLevel 
) 
 
    $encryptionLevelString = "" 
 
    switch ($EncryptionLevel) 
    { 
        1   {$encryptionLevelString = "Low"; break} 
        2   {$encryptionLevelString = "Client Compatible"; break} 
        3   {$encryptionLevelString = "High"; break} 
        4   {$encryptionLevelString = "FIPS Compliant"; break} 
    } 
     
    return $colorDepthString 
} 
 
function Get-RDSHSession 
{ 
 
param(     
    [Parameter(Mandatory=$FALSE, Position=0, ValueFromPipeline=$TRUE, ValueFromPipelineByPropertyName=$TRUE)] 
    [string] 
    $Server = "localhost", 
     
    [Parameter(Mandatory=$FALSE, HelpMessage="List all sessions, including services, listener etc")] 
    [Switch] 
    $ListAll 
) 
 
    if (($Server -ne "localhost") -AND (!(Ping-Computer $Server))) { 
        Write-Error ("'{0}' is not reachable." -f $Server) 
        return 
    } 
 
    $ServerPtr = [RDSManager.PowerShell.RDSManager]::WTSOpenServer($Server) 
 
    if ($ServerPtr -eq [System.IntPtr]::Zero) { 
        Write-Error ("Failed to connect to {0}" -f $Server) 
        return 
    } 
     
    $sessInfo = [System.IntPtr]::Zero  
    $count = 0 
 
    $result = [RDSManager.PowerShell.RDSManager]::WTSEnumerateSessions($ServerPtr, 0, 1, [ref] $sessInfo, [ref] $count) 
     
    if (($result -eq 0) -and ($count -eq 0)) 
    { 
        Write-Warning "You might not have permissions to enumerate sessions on server $Server" 
        return 
    } 
     
    if(($result -ne 0) -AND ($sessInfo -ne [System.IntPtr]::Zero)) 
    { 
        $structSize = [System.Runtime.InteropServices.Marshal]::sizeof([RDSManager.PowerShell.WTSSessionInfo]) 
 
        for ($ind = 0; $ind -lt $count; $ind++) 
        { 
            $sessionInfo = ([RDSManager.PowerShell.WTSSessionInfo]([System.Runtime.InteropServices.Marshal]::PtrToStructure([int]$sessInfo + $ind * $structSize, [RDSManager.PowerShell.WTSSessionInfo]))) 

            $UserName = ((Get-RDSessionInfoEntry $ServerPtr $sessionInfo.SessionId WTSUserName).Replace("`0",'')).Trim()
			
            if ((!$ListAll) -AND ([string]::IsNullOrEmpty($UserName))) 
            { 
                continue; 
            } 
             
            $sessionObj = New-Object RDSManager.PowerShell.RDSession # Can use with -Set 

			$clientAddress = Get-RDSessionInfoEntry $ServerPtr $sessionInfo.SessionId WTSClientAddress 
			
            $sessionObj.Session = $sessionInfo.WinStationName 
            $sessionObj.User = $UserName
            $sessionObj.SessionID = $sessionInfo.SessionId 
            $sessionObj.State = $sessionInfo.State 
            $sessionObj.ProtocolType = (Get-ProtocolName (Get-RDSessionInfoEntry $ServerPtr $sessionInfo.SessionId WTSClientProtocolType)) 
            $sessionObj.Client = (Get-RDSessionInfoEntry $ServerPtr $sessionInfo.SessionId WTSClientName).Replace("`0",'') 
            $sessionObj.Server = $Server 
			$sessionObj.ClientAddress = ([string]::Join(".", $clientAddress.Address[2..5])).Replace("`0",'')
             
            $sessionObj 
        } 
 
        [RDSManager.PowerShell.RDSManager]::WTSFreeMemory($sessInfo); 
        $sessInfo = [System.IntPtr]::Zero 
    } 
     
    [RDSManager.PowerShell.RDSManager]::WTSCloseServer($ServerPtr) 
} 
 
 function Get-RDSession 
{ 
<#  
.Synopsis  
    Gets the sessions for the specified Remote Desktop resource. The Remote Desktop resource can be the RD Session Host server.
     
.Description  
    This function gets sessions for the specified Remote Desktop resource. The Remote Desktop resource can be the RD Session Host server, RD Virtualization Host Server, RD Farm or VM Pool. 
     
    By default, it returns only user sessions. Use the parameter ListAll to list all sessions. Non-users sessions include: 
    1. Services : The session that contains various system processes on the Remote Desktop server. 
    2. Listener : The session that listens for and accepts new Remote Desktop Protocol (RDP) client connections, thereby creating new sessions on the Remote Desktop server. 
    3. Console  : The session that you connect to if you log on to the physical console of the computer, instead of connecting remotely. 
 
    Considerations :  
        1. To query sessions other than the logged on, execute the script with "query information" special access permission. 
         
    Note : Using Force parameter will return objects with values set only for following properties : Server, Session, User, SessionID and State. 
 
.Parameter RDSHost 
    Name of the RD Session Host Server whose sessions are to be listed. 
 
.Parameter Force 
    Enumerates sessions from RD Virtualization host, as reported by the VMHostAgent service. By default, sessions are queried from VMs. This is helpful when the script is beinge executed with permissions that are not adquate to enumerate sessions on the Virtual Machiness. 
 
.Parameter ListAll 
    Lists all sessions. 
 
.Example  
    PS C:\> Get-RDSession 
     
    Gets the user sessions on local machine. 
     
.Example  
    PS C:\> Get-RDSession -RDSHost RDServer01 
     
    Gets the user sessions on server named RDServer01. 
     
.Example  
    PS C:\> Get-RDSession -RDVHost RDVServer01 
     
    Gets the user sessions on server named RDVServer01 and user sessions on all Virtual Machines hosted by the server. 
 
.Example  
    PS C:\> Get-RDSession -RDVHost RDVServer01 -Force 
     
    Gets the user sessions on Remote Desktop server named RDVServer01 and user sessions on all Virtual Machines hosted by the server, as reported by the VMHostAgent service. This is helpful when the script is beinge executed with permissions that are not adquate to enumerate sessions on the Virtual Machiness. 
 
.Example  
    PS C:\> Get-RDSession -Farm RDFarm -ConnectionBroker CB01 
     
    Gets the user sessions on all servers belonging to farm RDFarm, managed by the RD Connection Broker Server CB01. 
 
.Example  
    PS C:\> Get-RDSession -Pool RDPool -ConnectionBroker CB01 
     
    Gets the user sessions on all Virtual Machines belonging to VM Pool RDPool, managed by the RD Connection Broker Server CB01. 
 
.Example  
    PS C:\> Get-RDSession -Pool RDPool -ConnectionBroker CB01 -ListAll 
     
    Gets all sessions(user and non-user) on all Virtual Machines belonging to VM Pool RDPool, managed by the RD Connection Broker Server CB01. 
 
.Inputs 
    Remote Desktop resource name. Defaults to local machine if not specified. 
     
.Outputs  
    Session Object(s). 
    RDSManager.PowerShell.RDSession objects are returned. Returns the following information of a session: 
     
    Property        Description  
    ----------------------------------------------------------------- 
    Server          The Remote Desktop server with which the session is associated. 
    Session         The session running on the Remote Desktop server. 
    User            The user account that is associated with the session. 
    SessionID       The numeric ID that identifies the session to the Remote Desktop server. 
    State           The status of a session. For more information, see Session States. 
    ProtocolType    The type of remote desktop client using the session. 
    Client          The name of the client computer using the session, if applicable. 
    IdleTime        The number of minutes that have elapsed since the last keyboard or mouse input to a session. 
    LogOnTime       The date and time at which the user logged on, if applicable. 
    Host            The name of the remote desktop virtualization host server on which the VM is running. 
     
.Link  
    Get-RDSessionStatus 
    Send-RDMessage 
    Connect-RDSession 
    Disconnect-RDSession 
    Start-RDRemoteControlSession 
#> 
 
[CmdletBinding(DefaultParametersetName="RDSHost")] 
param( 
     
    [Parameter(Mandatory=$FALSE,  
        ParameterSetName="RDSHost",  
        ValueFromPipeline=$TRUE, 
        HelpMessage="Remote Desktop Session Host server or client name")] 
    [ValidateNotNullOrEmpty()] 
    [System.String] 
    $RDSHost = "localhost", 
 
    [Parameter(Mandatory=$FALSE, 
        HelpMessage="List all sessions, including services, listener etc")] 
    [Switch] 
    $ListAll 
) 
 
	Get-RDSHSession $RDSHost -ListAll:$ListALL

} 

 
Export-ModuleMember -Function Get-RDSession, Get-RDProcess, Get-RDSessionStatus, Stop-RDProcess, Send-RDMessage, Connect-RDSession, Disconnect-RDSession, Start-RDRemoteControlSession
                                          
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsTm/UEfzWIqtEQEfEo2k6w28
# FKGgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLBVXfns+48ELQfA
# I+kpKNnPKDfUMA0GCSqGSIb3DQEBAQUABIIBAKWl8kFVLgHzr8n9EJSy99YomZ2U
# b9Ys6tjlv5pvR3MbwnNpPmNM1GTJefFQRQvi8PE0yEiVS3ku2A6XYbCb+nEWEXN3
# /qaNMYGe2zYY/DGpYtuPTUbY85Tx64SS+/6/zsRLYqQb3/ERtipwG0y3Q7dyaLtM
# hLls8im/Q+ghwxJNHAum1cYES0CymRlEeAjNSs2lj2VLqMhtwdQHgH7WMqpS5iqg
# nlkIZ5rlUjha3wam1Huu4leY/3WCmLyZmIESeP8xjSI9JsZ8VEvaBUHkC1nMzFLf
# QzOs6DbGDjo2qOiyqxnqI0Q0GAcRC2RHRDGNGT2jOiYRPB6lUD9fauLPRyY=
# SIG # End signature block
