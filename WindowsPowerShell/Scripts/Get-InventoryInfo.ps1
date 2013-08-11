function Get-InventoryInfo {
BEGIN{}
PROCESS{
    # Create New Object and attach Computer Name as a Property
    $obj = New-Object psobject
    $obj | Add-Member noteproperty ComputerName ($_)


# Get the Computer system info, attach to properties to our object
    $compsystem = gwmi win32_computerSystem -ComputerName $_
    $obj | Add-Member noteproperty Processors ($compsystem.numberoflogicalprocessors)
    $obj | Add-Member noteproperty Architecture ($compsystem.systemtype)
    # Get the Computer System OS Info, and attach to properties of our object
    $os = gwmi win32_operatingsystem -Computername $_
    $obj | Add-Member noteproperty SPVer ($os.servicepackmajorversion)
    $obj | Add-Member noteproperty Build ($os.buildnumber)
    Write-Output $obj
    }
    END {}
    
    }
    
     Get-Content c:\demo\computers.txt | Get-InventoryInfo | Format-Table -AutoSize
    #"localhost" | Get-InventoryInfo | convertto-html | Out-File