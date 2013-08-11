function Add-SidHistory {
  Param($sourceDC,$sourceDomain,$sourceUsername,$targetDC,$targetDomain,$TargetUsername)
  $clonePrincipal = New-Object -COMObject DSUtils.ClonePrincipal
  $clonePrincipal.Connect($sourceDC,$sourceDomain,$targetDC,$targetDomain)
  $clonePrincipal.AddSidHistory($sourceUsername,$targetUsername,0)
  }

  $users = Import-Csv -Path C:\Test\ldapout.csv -Header
  foreach ($user in $users) {
  Add-SidHistory($user.DC,$user.Domain,$user.Username,$user.Domain,$user.Username)
  }

function Remove-SidHistory {
$Users = import-csv -Path c:\test\sidhistorydelete.csv
foreach ($user in $users) {
Set-ADUser -samaccountname $user.samaccountname -remove @{sidhistory=$_.sidhistory.value}
}                  
}                