<#

.SYNOPSIS
   Identifies services with nonstandard accounts
.DESCRIPTION
   Retrieves services that use accounts other than LocalSystem, LocalService or NetworkService
.PARAMETER computername
   one or more computernames or IP addresses
   you will need local administrator privileges, and the firewall needs to allow access
   to enable firewall access, run this command on target machines:
   netsh firewall set service type = remoteadmin mode = enable
.EXAMPLE
   Get-NonstandardService
   lists services with nonstandard accounts on local machine
.EXAMPLE
   Get-NonstandardService -computername 10.10.10.33
   lists services with nonstandard accounts on remote machine with IP 10.10.10.33
.EXAMPLE
   Get-NonstandardService -computername 10.10.10.33, 127.0.0.1, serv12-1, client3
   lists services with nonstandard accounts on four machines (including local system)
.LINK
   http://www.powershell.com
#>
 
function Get-NonstandardService {
  param(
  [String[]]
  $computername = '127.0.0.1'
  )
 
  # server-side WMI query to minimize network traffic and maximize performance
  $wql = 'Select Name, DisplayName, StartName, __Server From Win32_Service WHERE ((StartName != "NT Authority\\LocalService") and (StartName != "NT Authority\\NetworkService"))'
 
  # examine all computers submitted:
  $computername |
  ForEach-Object {
    Write-Progress 'examining computer:' $_

    # create new object to return information

    $rv = New-Object PSObject | Select-Object Computer, Result, Name, DisplayName
    $rv.computer = $_
    # search for nonstandard services
    try {
      # always return result as array
      $result = @(Get-WmiObject -Query $wql -ComputerName $rv.computer -ErrorAction Stop | Sort-Object DisplayName)
      # no results?
      if ($result.Count -eq 0) {
        # then all services use standard accounts, good:
        $rv.Result = 'OK'
        $rv
      } else {
        # return a result set for each nonstandard service
        $result | ForEach-Object {
          $rv.Computer = $_.__Server
          $rv.Name = $_.Name
          $rv.DisplayName = $_.DisplayName
          $rv.Result = $_.StartName
          $rv
        }
      }
    }
    catch {
      # WMI was unable to retrieve the information
      switch ($_) {
        # sort out most common errors and return qualified information
        {          $_.Exception.ErrorCode -eq 0x800706ba} { $rv.Result = 'WARN: Unavailable (offline, firewall)' }
        {          $_.CategoryInfo.Reason -eq 'UnauthorizedAccessException' } { $rv.Result = 'WARN: Access denied' }
        # return all other non-common errors
        default { $rv.Result = 'WARN: ' + $_.Exception.Message }
      }
      # return error information
      $rv
    }
  }
}