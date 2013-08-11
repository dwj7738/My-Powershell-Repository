[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$datetime = get-date
$message = "A Disk Error has occurred and a retried: " + $datetime
$message >> c:\test\diskerror.txt

[System.Windows.Forms.MessageBox]::Show($message , "Disk Error" , 0)