#question from http://www.experts-exchange.com/OS/Microsoft_Operating_Systems/Q_28133759.html

$filename = Read-Host "What is the input filename?" 
if ((Test-Path -Path $filename) -eq $true) { get-input($filename) }
else {
    Write-Host("File not found")
    }

function get-input($filename) {
    $BuildingCode = Read-Host  -Prompt "Building Code To Find"
    $BuildingCode = $BuildingCode.ToLower()
    $myobjects = Import-Csv -Path $filename
    $found = $false
    foreach ($object in $myobjects) {
        $test = $object.Building_Code.tolower()
        if ($test -eq $BuildingCode) {
            $found = $true
            $object
            #
            # here is the start for the batch file or executable that requires the output from the CSV using the Building_code
            #

c:\test\output.bat "$object.Building_Name" "$object.Street_Address" "$object.City" "$object.Number" "$object.Building_Code"
            }
        else { }
    }
 if ( $found -eq $false) { Write-Output("Building Code Not Found")}
    else { Write-Output ("Code Found") }
 }



