# Prompted PS1 Script:

$strIpAddress = Read-Host “Enter IP Address”
Clear


$ResultsSet = Test-Connection $strIpAddress -Quiet -Count 1

If ($ResultsSet -Eq "True" )
    {
    Write-Host -Fore Green “The Router Is On Line”
    }
Else {
    Write-Host -Fore Red “The Router Is Off Line”
    }

# Specified PS1 Script:

#Clear
# Router IP Address
$strIpAddress =”192.168.0.1"
$ResultsSet = Test-Connection $strIpAddress -Quiet -Count 1

If ($ResultsSet -Eq "True" )
     {
    Write-Host -Fore Green “The Router Is On Line”
    }
Else 
    {
    Write-Host -Fore Red “The Router Is Off Line”
    }

