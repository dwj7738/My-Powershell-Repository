function GetSidFromAcctName () {

$myacct = Get-WmiObject Win32_UserAccount -filter "Name = '$env:USERNAME' " 
write-host Name: $myacct.name
Write-Host SID : $myacct.sid
}

