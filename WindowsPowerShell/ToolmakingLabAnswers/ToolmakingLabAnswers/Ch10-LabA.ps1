Function Get-ComputerData {

<#
.SYNOPSIS
Get computer related data

.DESCRIPTION
This command will query a remote computer and return a custom object
with system information pulled from WMI. Depending on the computer
some information may not be available.

.PARAMETER Computername
The name of a computer to query. The account you use to run this function
should have admin rights on that computer.

.PARAMETER ErrorLog
Specify a path to a file to log errors. The default is C:\Errors.txt

.EXAMPLE
PS C:\> Get-ComputerData Server01

Run the command and query Server01.

.EXAMPLE
PS C:\> get-content c:\work\computers.txt | Get-ComputerData -Errorlog c:\logs\errors.txt

This expression will go through a list of computernames and pipe each name
to the command. Computernames that can't be accessed will be written to
the log file.

#>

[cmdletbinding()]

 param(
 [Parameter(Position=0,ValueFromPipeline=$True)]
 [ValidateNotNullorEmpty()]
 [string[]]$ComputerName,
 [string]$ErrorLog="C:\Errors.txt"
 )

 Begin {
    Write-Verbose "Starting Get-Computerdata"
 }

Process {
    foreach ($computer in $computerName) {
        Write-Verbose "Getting data from $computer"
        Try {
            Write-Verbose "Win32_Computersystem"
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

        } #Try

        Catch {

            #create an error message 
            $msg="Failed getting system information from $computer. $($_.Exception.Message)"
            Write-Error $msg 

            Write-Verbose "Logging errors to $errorlog"
            $computer | Out-File -FilePath $Errorlog -append
            
			} #Catch

        #if there were no errors then $hash will exist and we can continue and assume
        #all other WMI queries will work without error
        If ($hash) {
            Write-Verbose "Win32_Bios"
            $bios = Get-WmiObject -Class Win32_Bios -ComputerName $Computer 
            $hash.Add("SerialNumber",$bios.SerialNumber)

            Write-Verbose "Win32_OperatingSystem"
            $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer
            $hash.Add("Version",$os.Version)
            $hash.Add("ServicePackMajorVersion",$os.ServicePackMajorVersion)

            #create a custom object from the hash table
            New-Object -TypeName PSObject -Property $hash
        
            #remove $hash so it isn't accidentally re-used by a computer that causes
            #an error
            Remove-Variable -name hash
        } #if $hash
    } #foreach
} #process

 End {
    Write-Verbose "Ending Get-Computerdata"
 }
}

'localhost','notonline','localhost' |  Get-Computerdata  -verbose