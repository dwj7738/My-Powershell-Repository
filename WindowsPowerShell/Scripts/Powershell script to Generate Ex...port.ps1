$wid = "1200"
$bord = "2"
$colour ="BLUE"
$Fcolour = "White"


"<table width=$wid border=$bord>" | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<tr> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<td BGCOLOR=$colour><font color=$Fcolour> <b>Server</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<td BGCOLOR=$colour><font color=$Fcolour> <b>StorageGroupName</b> </td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<td BGCOLOR=$colour><font color=$Fcolour><b>LastFullBackup</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<td BGCOLOR=$colour><font color=$Fcolour><b>LastIncrementalBackup</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<td BGCOLOR=$colour><font color=$Fcolour><b>BackupInProgess</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"</tr> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append


Get-MailboxDatabase | where {$_.Recovery -eq $False } | Select-Object -Property Server, StorageGroupName, Name , LastFullBackup, LastIncrementalBackup, BackupInProgess | Export-csv Backuptatus.csv


foreach($line in $csv)
{
	$MailboxStats = Get-MailboxStatistics $Line.Alias | Select TotalItemSize,Itemcount,LastLogoffTime,LastLogonTime
	$L = "{0:N0}" -f $mailboxstats.totalitemsize.value.toMB()
	$Size = ""
	$Len = $L.Split(',')
	for ($i = 0; $i -lt $Len.length; $i++)
	{
		$Size = $Size +$Len[$i] 
	}
	$temp = $Line.PrimarysmtpAddress
	$adobjroot = [adsi]''
	$objdisabsearcher = New-Object System.DirectoryServices.DirectorySearcher($adobjroot)
	$objdisabsearcher.filter = "(&(objectCategory=Person)(objectClass=user)(mail= $Temp)(userAccountControl:1.2.840.113556.1.4.803:=2))"
	$resultdisabaccn = $objdisabsearcher.findone() | select path


	"<tr> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour> <b> $Line.Server </b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour><b>$Line.StorageGroupName</b> </td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour><b>$Line.Name</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour><b>$line.LastFullBackup</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour><b>$Line.LastIncrementalBackup</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour><b>$Line.BackupInProgess</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"</tr> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
}


$smtpServer = ?hutserver? 
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer) 
$msg.From = ?FromAddress?
$msg.To.Add(?ToAddress?)
$sub = Date
$msg.Subject = "Exchange Database Backup Status Report  " + $sub

$msg.IsBodyHTML = $true





$UserList = Get-Content "C:\Powershell\BackupDetails.txt"

$body = ""

foreach($user in $UserList) 
{
	$body = $body + $user + "`n"

}

$msg.Body = $body

$smtp.Send($msg)
Exit