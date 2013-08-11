
Function Get-ComputerData {

[cmdletbinding()]

param( [string[]]$ComputerName )

foreach ($computer in $computerName) {
    Write-Verbose "Getting data from $computer"
    Write-Verbose "Win32_Computersystem"
        $cs = Get-WmiObject -Class Win32_Computersystem -ComputerName $Computer 

        #decode the admin password status
        Switch ($cs.AdminPasswordStatus) {
            1 { $aps="Disabled" }
            2 { $aps="Enabled" }
            3 { $aps="NA" }
            4 { $aps="Unknown" }
        }

        #Define a hashtable to be used for property names and values
        $hash=@{
            Computername=$cs.Name
            Workgroup=$cs.WorkGroup
            AdminPassword=$aps
            Model=$cs.Model
            Manufacturer=$cs.Manufacturer
        }

        Write-Verbose "Win32_Bios"
        $bios = Get-WmiObject -Class Win32_Bios -ComputerName $Computer 

        $hash.Add("SerialNumber",$bios.SerialNumber)
                
        Write-Verbose "Win32_OperatingSystem"
        $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer
        $hash.Add("Version",$os.Version)
        $hash.Add("ServicePackMajorVersion",$os.ServicePackMajorVersion)
           
        #create a custom object from the hash table
        New-Object -TypeName PSObject -Property $hash
           
} #foreach

}

Get-Computerdata -computername localhost