#Name column is located in CSV1
#The gn and sn columns are located in CSV2. 
#While the displayName and userName columns are located in CSV3.
#Import-Module activedirectory
$csv1 = "C:\Test1.csv"
$csv2 = "c:\test2.csv"
$csv3 = "c:\test3.csv"
if ((test-path -Path $csv1) -eq $false) 
  {
  write-host ("Can't Find:",$csv1)
  break
  }
$name = Import-Csv $csv1
if ((test-path -Path $csv2) -eq $false) { 
  write-host ("Can't Find:",$csv2)
  break
  }
$sn = import-csv "c:\test2.csv"
if ((test-path -Path $csv3) -eq $false) {  
    write-host ("Can't Find:",$csv3)
    break
    }
$dn = import-csv $csv3
#
# ensure that there are the same # of records
#
if ( ($name.count -ne $sn.count) -or ($name.count -ne $dn.count))
    {
    write-output ("Not all input files have the same # of records")
    }
else
    {
    for($counter=0; $counter -le $r1;$counter++){
        $Name[$counter].Name
        $sn[$counter].gn
        $sn[$counter].sn
        $dn[$counter].displayName
        $dn[$counter].userName

        New-ADUser -Name $Name[$counter].Name -GivenName $sn[$counter].gn -Surname $sn[$counter].sn `
         -DisplayName $dn[$counter].displayName -SamAccountName $dn[$counter].username `
         -Path "OU=Domain Users,DC=source,DC=local" -UserPrincipalName ("{0}@{1}" -f $dn[$counter].username,"source.local") `
         -PasswordNotRequired $true -Enabled $true -ChangePasswordAtLogon $false
    }
}
