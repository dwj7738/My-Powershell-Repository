$licenseStatus=@{0="Unlicensed"; 1="Licensed"; 2="OOBGrace"; 3="OOTGrace"; 
                 4="NonGenuineGrace"; 5="Notification"; 6="ExtendedGrace"} 
Function Get-Registration 

{ Param ($server="."get ) 
  get-wmiObject -query  "SELECT * FROM SoftwareLicensingProduct WHERE PartialProductKey <> null
                        AND ApplicationId='55c92734-d682-4d71-983e-d6ec3f16059f'
                        AND LicenseIsAddon=False" -Computername $server | 
       foreach {"Product: {0} --- Licence status: {1}" -f $_.name , $licenseStatus[[int]$_.LicenseStatus] } 
}

 