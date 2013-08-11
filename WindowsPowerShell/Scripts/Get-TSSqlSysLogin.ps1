function Get-TSSqlSysLogin {
  <#
    .SYNOPSIS
    Gets SQL Server Login Accounts

    .DESCRIPTION
    Displays SQL Server Login Accounts from the syslogin table.

    .PARAMETER ComputerName
    Enter CopmuterName or IP Address.

    .PARAMETER UserName
    Enter a UserName. If blank, trusted connection will be used.

    .PARAMETER Password
    Enter a Password.

    .EXAMPLE
    Get-TSSqlSysLogin -ComputerName SRV01 -UserName sa -Password sa

    .EXAMPLE
    "SQL01","SQL02","SQL03" | Get-TSSqlSysLogin -UserName sa -Password sa

    .LINK
    http://www.truesec.com

    .NOTES
    Goude 2012, TreuSec
  #>
  Param(
    [Parameter(Mandatory = $true,
      Position = 0,
      ValueFromPipeLine= $true)]
    [Alias("PSComputerName","CN","MachineName","IP","IPAddress")]
    [string]$ComputerName,
    [parameter(Position = 1)]
    [string]$UserName,
    [parameter(Position = 2)]
    [string]$Password
  )
  Process {
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    if($userName) {
      $Connection.ConnectionString = "Data Source=$ComputerName;Initial Catalog=Master;User Id=$userName;Password=$password;"
    } else {
      $Connection.ConnectionString = "server=$computerName;Initial Catalog=Master;trusted_connection=true;"
    }
    Try {
      $Connection.Open()
      $Command = New-Object System.Data.SQLClient.SQLCommand
      $Command.Connection = $Connection
      $Command.CommandText = "SELECT * FROM master.SYS.syslogins"
      $Reader = $Command.ExecuteReader()
      $Counter = $Reader.FieldCount
      while ($Reader.Read()) {
        $SQLObject = @{}
        for ($i = 0; $i -lt $Counter; $i++) {
          $SQLObject.Add(
            $Reader.GetName($i),
            $Reader.GetValue($i)
          );
        }
        # Get Login Type
        $type = 
          if($sqlObject.isntname -eq 1) {
            if($sqlObject.isntgroup -eq 1) {
              "NT Group"
            } else {
              "NT User"
            }
            } else { 
              "SQL Server"
            }

        New-Object PSObject -Property @{
          Name = $sqlObject.loginname;
          Created = $sqlObject.createdate;
          DenyLogin = [bool]$sqlObject.denylogin;
          HasAccess =  [bool]$sqlObject.hasaccess;
          Type = $type;
          SysAdmin = [bool]$sqlObject.sysadmin;
          SecurityAdmin = [bool]$sqlObject.securityadmin;
          ServerAdmin = [bool][bool]$sqlObject.serveradmin;
          SetupAdmin = [bool]$sqlObject.setupadmin;
          ProcessAdmin = [bool]$sqlObject.processadmin;
          DiskAdmin = [bool]$sqlObject.diskadmin;
          DBCreator = [bool]$sqlObject.dbcreator;
          NTUser = [bool]$sqlObject.isNTUser;
          ComputerName = $ComputerName
        } | Select-Object Name, Created, Type, DenyLogin, HasAccess, SysAdmin, SecurityAdmin, ServerAdmin, SetupAdmin, ProcessAdmin, DiskAdmin, DBCreator, NTUser, ComputerName
      }
      $Connection.Close()
    }
    Catch {
      $error[0]
    }
  }
}
