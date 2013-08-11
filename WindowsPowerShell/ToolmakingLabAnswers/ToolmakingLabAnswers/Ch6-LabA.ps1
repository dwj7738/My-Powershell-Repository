Function Get-ComputerData {

 param(
 [string[]]$ComputerName,
 [string]$ErrorLog="C:\Errors.txt"
 )

foreach ($computer in $computerName) {
    Try {
        $cs = Get-WmiObject -Class Win32_Computersystem -ComputerName $Computer -ErrorAction Stop

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

    }

    Catch {
        #create an error message and log it
        $msg="$(Get-Date) Error getting data from Win32_Computersystem on $computer. $($_.Exception.Message)"
        $msg | Out-File -FilePath $Errorlog -append
    }

    <# 
        only proceed if there is data from all 3 wmi classes. If there is an 
        error with one class it will most likely apply to all classes so there
        is no reason to keep trying.
    #>

    If ($cs) {
        Try {
            $bios = Get-WmiObject -Class Win32_Bios -ComputerName $Computer -ErrorAction Stop

            $hash.Add("BIOSSerial",$bios.SerialNumber)
                   
        }
        Catch {
            $msg=" $(Get-Date) Error getting data from Win32_Bios on $computer. $($_.Exception.Message)"
            $msg | Out-File -FilePath $Errorlog -append
        }
    } #if cs

    If ($bios) {
        Try {
            $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer -ErrorAction Stop
            $hash.Add("OSVersion",$os.Version)
            $hash.Add("SPVersion",$os.ServicePackMajorVersion)
                    
        }
        Catch {
            $msg=" $(Get-Date) Error getting data from Win32_OperatingSystem on $computer. $($_.Exception.Message)"
            $msg | Out-File -FilePath $Errorlog -append
        }
    } #if bios
           
    if ($Hash) {
        #create a custom object from the hash table
        New-Object -TypeName PSObject -Property $hash

    } #if hash        
            
    #remove variables for next computer. Some might not exist to turn off any error messages.
    Remove-Variable -Name "os","bios","cs" -ErrorAction SilentlyContinue
} #foreach
}

