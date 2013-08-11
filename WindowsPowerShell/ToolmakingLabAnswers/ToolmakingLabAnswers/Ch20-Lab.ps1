Function Get-ComputerVolumeInfo {

[cmdletbinding()]

Param(
[parameter(Position=0,mandatory=$True,
HelpMessage="Please enter a computername")]#
[ValidateNotNullorEmpty()]
[string[]]$Computername
)

Process {

    Foreach ($computer in $Computername) {
      Write-Verbose "Processing $computer"
      $params=@{Computername=$Computer;class="Win32_OperatingSystem"}

      Write-Verbose "Getting data from $($params.class)"
      #splat the parameters to the cmdlet
      $os = Get-WmiObject @params

      $params.Class="Win32_Service"
      Write-Verbose "Getting data from $($params.class)"
      $services = Get-WmiObject @params

      $params.Class="Win32_Process"
      Write-Verbose "Getting data from $($params.class)"
      $procs = Get-WmiObject @params
      
      $params.Class="Win32_LogicalDisk"
      Write-Verbose "Getting data from $($params.class)"
      $params.Add("filter","drivetype=3")
      $disks = Get-WmiObject @params

      New-Object -TypeName PSObject -property @{
        Computername=$os.CSName
        Version=$os.version
        SPVersion=$os.servicepackMajorVersion
        Services=$services
        Processes=$procs
        Disks=$disks
      }

    } #foreach computer
}
}

Get-ComputerVolumeInfo localhost