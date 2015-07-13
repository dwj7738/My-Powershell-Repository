<#
   DSC resource designed to create an instance of MySQL, using the supplied parameters as per resource schema.

   Copyright (c) Microsoft Corporation, 2014
#>

# NOTE: LocalizedData isn't used in this resource as there are no interactive/user visible strings

$mySqlVersion = "5.6"
$Debug = $true

################################################################################################################################
# Trace-Message (write verbose if Debug flag is on)
################################################################################################################################

Function Trace-Message
{
    param([string] $Message)

    if($Debug)
    {
        Write-Verbose $Message
    }
}


#region MySql Helpers
################################################################################################################################
# Get-MySqlInstallerFolder (helper to get localtion of MySql installer folder on local machine)
################################################################################################################################

function Get-MySqlInstallerFolder
{
    if($env:PROCESSOR_ARCHITECTURE -eq "AMD64")
    {
        return "$(${env:ProgramFiles(x86)})\MySQL\MySQL Installer"
    }
    else
    {
        return "$(${env:ProgramFiles})\MySQL\MySQL Installer"
    }
}

$mySqlInstallerConsole = Join-path (Get-MySqlInstallerFolder) -ChildPath "MySQLInstallerConsole.exe"

################################################################################################################################
# Get-MySqlInstalledComponents (helper to get SQL installed components)
################################################################################################################################

function Get-MySqlInstalledComponents
{
    # we don't want to throw an exception here for the case where Ensure=Absent during Test/Get-DscConfiguration. Instead of failing
    # with an exception it should return false. Removing exception handling and throwing.
    if ((Test-Path -Path $mySqlInstallerConsole))
    {
        $statusResults = &$mySqlInstallerConsole --nowait --type=server --action=Status

        $statusResults | % {
        
            # split each line on the status delimiter
            $statusPair = $_ -split ":"

            # if the line contains a status, check the status
            if($statusPair.count -gt 1) {

                # if the status is installed return the product name
                if($statusPair[1].Trim() -ieq "installed.")
                {
                    Write-Output $statusPair[0].Trim()
                }
            }
        }
    }
    else
    {
        $null
    }
}

################################################################################################################################
# Get-MySqlArchitectureName (helper to get SQL architecture string in expected format)
################################################################################################################################

function Get-MySqlArchitectureName
{
    if($env:PROCESSOR_ARCHITECTURE -eq "AMD64")
    {
        return "winx64"
    }
    else
    {
        return "win32"
    }
}

################################################################################################################################
# Get-MySqlProductName (helper to get product name of MySQL)
################################################################################################################################

function Get-MySqlProductName
{
    return "mysql-server-$mySqlVersion-$(Get-MySqlArchitectureName)"
}

################################################################################################################################
# Get-MySqlCatalogName (helper to get the MySQL catalog name)
################################################################################################################################

function Get-MySqlCatalogName
{
    return "mysql-$mySqlVersion-$(Get-MySqlArchitectureName)"
}

#endregion

#region *-TargetResource implementation

################################################################################################################################
# Get-TargetResource (params: ServiceName, Ensure, RootPassword)
################################################################################################################################

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [string] $ServiceName,
        
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [pscredential] $RootPassword
    )
    
    $Ensure = "Absent"
    $MySqlInstalled = $false 

    # get installed products
    $products = @(Get-MySqlInstalledComponents)

    if ($products -ne $null)
    {
        foreach($product in $products)
        {
            Trace-Message  "'$product' is currently installed"
        }
    
        Trace-Message "Checking to see if installed products contains '$((Get-MySqlProductName))'"

        if($products -contains (Get-MySqlProductName))
        {
            $MySqlInstalled  = $true 
        }

        if($MySqlInstalled )
        {
            Trace-Message "Present"
            $Ensure = "Present"
        }
    }

    return @{
        Ensure = $Ensure
        ServiceName = $ServiceName
    }
}

################################################################################################################################
# Test-TargetResource (params: ServiceName, Ensure, RootPassword)
################################################################################################################################

function Test-TargetResource 
{
    [OutputType([Boolean])]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [string] $ServiceName,
        
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",
        
        [parameter(Mandatory = $true)]
        [pscredential] $RootPassword
    )
    
    Trace-Message "Ensure is $Ensure"

    $status = Get-TargetResource @psboundparameters

    if($status.Ensure -eq $Ensure)
    {
        return $true
    }
    else
    {
        return $false
    }
}

################################################################################################################################
# Set-TargetResource (params: ServiceName, Ensure, RootPassword)
################################################################################################################################

function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [string] $ServiceName,

        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [pscredential] $RootPassword
        
    )
    
    if((Test-TargetResource @psboundparameters))
    {
        return
    }
    
    $status = Get-TargetResource @psboundparameters 

   <# config parameters:
      servertype     - Config type [developer|server|dedicated] Default developer.
      enabletcpip    - Use TCP/IP. Possible values [true | false] Default true.
      port           - Port MySQL Server will use for communication. Default 3306
      openfirewall   - Create a rule in the Windows firewall for the specified port.
      passwd         - The default root password. Required.
      existingpasswd - Existing instances require the current password.
      servicename    - The Service Name. Default MySQL56
      sauser         - A valid username.
      sapass         - The password for sauser.
      autostart      - Autmatically start the service at system startup? Default true.
      generallog     - Enable General Log [true|false]. Default false
      generallogname - General Log path/filename. Default MGMT-9737-3172.log
      slowlog        - Enable Slow Query Log [true|false] Default false
      slowlogname    - Slow Query Log path/filename. Default MGMT-9737-3172-slow.log
      slowtime       - Time threshold for slow query log in seconds. Default 10
      binlog         - Enable Bin Log [true|false] Default false
      binlogname     - Bin Log path/filename base. Default MGMT-9737-3172-bin
      errorlogname   - Error Log path/filename. Default. MGMT-9737-3172.err
      removedatadir  - [true|false]. Default false. Only valid for remove action.
      timeout  - Configuration timeout in seconds. The default is 180.
      #>

    # NOTE: BUGBUG: the reason we need to do this is as follows:
    # The first time a node gets configured with the sql instance, there is no trace of it 
    # on the machine, which changes the way in which we construct the config parameter. If it is
    # the first time, the 'existingpasswd' argument cannot be given or it will fail. Once installed
    # the installation creates a datadir that does not get remove during uninstall. After that, every
    # time we try to install with the config, we have to provide the existingpasswd parameter, or installation/removal
    # will fail. This is an issue with the usage of removedatadir parameter, and this is the work-around

    $InstanceFlagpath = "$($env:ProgramFiles)\WindowsPowerShell\Modules\xMySQL\MySQLInstanceFlag.txt"
    Trace-Message "SQL instance flag path is $InstanceFlagpath"

    if (!(Test-Path -Path $InstanceFlagpath))
    {
        # this is the first time this is installed the machine (if Ensure=Present) and we cannot specify the existing pwd or it will fail
        Trace-Message "Instance flag not found. Omitting existing password parameter"
        $config = "--config=$(Get-MySqlProductName):passwd=$($RootPassword.GetNetworkCredential().Password);servicename=$ServiceName;autostartservice=true;servertype=server"
    }
    else
    {
        # in this case, we found the instance flag marker so we know that we need to specify the existingpwd argument.
        Trace-Message "Instance flag was found. Using optional parameter existingpasswd"
        $config = "--config=$(Get-MySqlProductName):passwd=$($RootPassword.GetNetworkCredential().Password);servicename=$ServiceName;existingpasswd=$($RootPassword.GetNetworkCredential().Password);autostartservice=true;servertype=server"
    }
    
    Trace-Message "mySqlInstallerConsole is $mySqlInstallerConsole"

    if($Ensure -eq "Present")
    {
        if(-not $status.MySqlInstalled)
        {
            Trace-Message "Installing MySQL"
            &$mySqlInstallerConsole --nowait --action=Install "--catalog=$(Get-MySqlCatalogName)" "--product=$(Get-MySqlProductName)" $config

            # don't stamp the machine until after the installation has completed, successfully!
            Trace-Message "Creating instance flag"
            New-Item -ItemType File -Path $InstanceFlagpath -Force
            Trace-Message "Instance flag has been created"
        }
    }
    else
    {
        Trace-Message "Removing MySQL"
        &$mySqlInstallerConsole --nowait --type=server --action=Remove $config
    }

}
#endregion

Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
