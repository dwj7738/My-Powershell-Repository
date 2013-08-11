<#
.Synopsis
   helper function used by Get-HardwareType
.EXAMPLE
   Example of how to use this cmdlet
#>
 
function Is-Laptop {
 
[CmdletBinding()]
[OutputType([boolean])]
 
    param
    (
    [Parameter(Mandatory=$true)]
    [string]
    $strHostName
    )
 
    $blnResult = $false
  
        $objWMI = Get-WmiObject -ComputerName $strHostName -Query $query -ErrorAction Stop
 
          switch ($objWMI.ChassisTypes) {
       
            9  {$blnResult = $true} # Laptop
            10 {$blnResult = $true} # Notebook
            12 {$blnResult = $true} # Docking Station
            14 {$blnResult = $true} # Sub Notebook
            default {}
          }
          return $blnResult
     } # end function
    
<#
.Synopsis
  function to determine chassis type using a WMI query
.DESCRIPTION
   function to determine chassis type using a WMI query
.EXAMPLE
   "pc01","pc02","pc03" | Get-HardwareType
#>
 
function Get-HardwareType {
 
[CmdletBinding()]
[OutputType([psobject])]
 
Param
(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
$strHostName
)
 
process {  
 
    try {
 
        $objHostName = [system.net.dns]::GetHostByName($strHostName)
 
        $query = "select __SERVER,ChassisTypes from Win32_SystemEnclosure"
 
            if (Test-Connection -ComputerName $objHostName.HostName -count 1 -erroraction silentlycontinue) {
 
            try {        
                $objResult = New-Object -TypeName psobject -Property @{HostName=$objHostName.HostName;IsLaptop=(Is-Laptop -strHostName $objHostName.HostName)}
                return $objResult
                }
           
          catch {
                "Error trying to query $($objHostName.HostName)"
                }
            }
       else {
            write-host "error connecting to $($objHostName.HostName)"
            }
    }
    catch {
    write-host "Unable to resolve DNS address for $strHostName"
    }
  }
} # end function
 
###################################################
# Main script execution
###################################################
 
$laptopCount = 0
$desktopCount = 0
 
$searcher = new-object directoryservices.directorysearcher([ADSI]"","(&(objectcategory=computer)(!operatingsystem=*server*))")
[void]$searcher.PropertiesToLoad.Add("cn")
$arrMachineName = $searcher.findall() | %{$_.properties.cn}
 
$result = $arrMachineName | Get-HardwareType
$result
$result | ForEach-Object {if ($_.islaptop) {$laptopCount++} else {$desktopCount++}}
 
"Laptop Total: $laptopCount"
"Desktop Total: $desktopCount"
